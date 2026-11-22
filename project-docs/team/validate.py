"""Check a student's team folder and report errors and warnings."""

import json
import re
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

from team import fm
from team.workspace import DEFAULTS, ROLE_IDS, STARTER_ROLES

BOUNDARY = ("You recommend; the student decides; the instructor approves gates. "
            "You never approve a gate, merge a pull request, or change a deadline.")
PEOPLE_IDS = ("student", "instructor")
LINK = re.compile(r"\]\(|(?<![(\w])https?://")


@dataclass
class Report:
    errors: list = field(default_factory=list)
    warnings: list = field(default_factory=list)
    agents: int = 0
    origin_notes: int = 0


def pairs(lane, key, side):
    """Return (other, what) pairs from a lane's expects or delivers list."""
    return [(x[side], x["what"]) if isinstance(x, dict) else tuple(x) for x in lane[key]]


def handoff_problems(lanes, kinds, cols, added):
    """Match expectations with deliveries, as the design master's check.py does.

    lanes maps every id (roles and people) to {column: lane}. kinds maps each id
    to "agent" or "person". Only roles in `added` are checked; a reference to a
    role that is not added is skipped because the student reads everything.
    Returns (kind, column, role, what, other) tuples, kind MISSING or UNCLAIMED.
    """
    def live(i):
        return i in kinds and (kinds[i] != "agent" or i in added)

    def delivers(src, dst, i):
        return any(i2 >= 0 and any(t == dst for t, _ in pairs(lanes[src][cols[i2]], "delivers", "to"))
                   for i2 in (i, i - 1))

    def expects(dst, src, i):
        return any(i2 < len(cols) and any(f == src for f, _ in pairs(lanes[dst][cols[i2]], "expects", "from"))
                   for i2 in (i, i + 1))

    probs = []
    for rid in lanes:
        if rid not in added:
            continue
        for i, c in enumerate(cols):
            lane = lanes[rid][c]
            for f, w in pairs(lane, "expects", "from"):
                if live(f) and not delivers(f, rid, i):
                    probs.append(("MISSING", c, rid, w, f))
            for t, w in pairs(lane, "delivers", "to"):
                if live(t) and kinds[t] == "agent" and not expects(t, rid, i):
                    probs.append(("UNCLAIMED", c, rid, w, t))
    return probs


def _lane_shape_errors(meta, cols, ids, rel):
    errs = []
    lanes = meta.get("lanes")
    if not isinstance(lanes, dict):
        return [f"{rel}: lanes must be a map of columns"], False
    ok = True
    for c in cols:
        lane = lanes.get(c)
        if not isinstance(lane, dict):
            errs.append(f"{rel}: lanes is missing column {c}")
            ok = False
            continue
        for key, side in (("expects", "from"), ("delivers", "to")):
            items = lane.get(key, [])
            if not isinstance(items, list):
                errs.append(f"{rel}: {c} {key} must be a list")
                ok = False
                continue
            for item in items:
                if not isinstance(item, dict) or side not in item or "what" not in item:
                    errs.append(f"{rel}: {c} {key} entries need {side} and what")
                    ok = False
                elif not isinstance(item[side], str):
                    errs.append(f"{rel}: {c} {key} must name a single role or person id")
                    ok = False
                elif item[side] not in ids:
                    errs.append(f"{rel}: {c} {key} names '{item[side]}', which is not a role or person")
                    ok = False
        lane.setdefault("expects", [])
        lane.setdefault("delivers", [])
    return errs, ok


def _read(path, rel, errors):
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as e:
        errors.append(f"{rel}: cannot read file ({e.__class__.__name__})")
        return None
    try:
        return fm.parse(text, rel) + (text,)
    except fm.FrontmatterError as e:
        errors.append(str(e))
        return None


def validate(team_path, today):
    team = Path(team_path)
    rep = Report()
    cdata = json.loads((DEFAULTS / "columns.json").read_text(encoding="utf-8"))
    cols = [c["id"] for c in cdata["columns"]]
    warn_on = date.fromisoformat(cdata["dates"]["default_warning"])
    strict = today >= date.fromisoformat(cdata["dates"]["strict"])
    people = json.loads((DEFAULTS / "people.json").read_text(encoding="utf-8"))
    ids = set(ROLE_IDS) | set(PEOPLE_IDS)
    # Warnings that become errors at the strict date.
    later = rep.errors if strict else rep.warnings

    roles, unused = {}, set()
    for path in sorted((team / "roles").glob("*.md")):
        rel = f"roles/{path.name}"
        got = _read(path, rel, rep.errors)
        if got is None:
            continue
        meta, body, text = got
        if str(meta.get("not_used", "")).strip():
            unused.add(path.stem)
        ok = True
        rid = meta.get("id")
        if rid is None:
            rep.errors.append(f"{rel}: id is missing")
            ok = False
        elif rid not in ROLE_IDS:
            rep.errors.append(f"{rel}: id '{rid}' is not a role id")
            ok = False
        elif rid != path.stem:
            rep.errors.append(f"{rel}: id '{rid}' must match the file name")
            ok = False
        slots = meta.get("slots", {})
        if isinstance(slots, dict):
            for name, slot in slots.items():
                if not re.fullmatch(r"[A-Za-z0-9_-]+", str(name)):
                    rep.errors.append(f"{rel}: slot key '{name}' may use only letters, digits, hyphens, and underscores")
                if not isinstance(slot, dict) or not str(slot.get("value", "")).strip():
                    rep.errors.append(f"{rel}: slot '{name}' has no value")
        perms = meta.get("permissions")
        tools = perms.get("tools") if isinstance(perms, dict) else None
        if not isinstance(tools, list) or not tools:
            rep.errors.append(f"{rel}: permissions.tools is missing or empty; list the tools this agent may use")
        if BOUNDARY not in body:
            rep.errors.append(f"{rel}: the approval-boundary sentence is missing from Instructions")
        errs, lanes_ok = _lane_shape_errors(meta, cols, ids, rel)
        rep.errors.extend(errs)
        default = DEFAULTS / "roles" / f"{path.stem}.md"
        if (today >= warn_on and default.is_file()
                and text.replace("\r\n", "\n") == default.read_text(encoding="utf-8")):
            rep.warnings.append(f"{rel}: still the shipped default; edit it for your game")
        if ok and lanes_ok:
            roles[rid] = meta
    added_files = {p.stem for p in (team / "roles").glob("*.md")}

    external, listed = {}, set()
    other = team / "other-roles.md"
    if other.is_file():
        for line in other.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^- ([\w-]+):[ \t]*(.*?)\s*$", line)
            if not m:
                continue
            rid, val = m.groups()
            if rid not in ROLE_IDS:
                rep.warnings.append(f"other-roles.md: '{rid}' is not a role id; use one of {', '.join(ROLE_IDS)}")
                continue
            listed.add(rid)
            if not val:
                rep.warnings.append(f"other-roles.md: {rid} is empty; write student, not needed, <reason>, or agent <path>")
            elif val == "student":
                pass
            elif val.startswith("not needed,") and val[len("not needed,"):].strip():
                pass
            elif val.startswith("agent ") and val[6:].strip():
                path = val[6:].strip()
                external[rid] = path
                if not (team.parent / path).is_file():
                    rep.warnings.append(f"other-roles.md: {rid} names {path}, which does not exist")
            else:
                rep.errors.append(f"other-roles.md: {rid} must be student, not needed, <reason>, or agent <path>")
    for rid in ROLE_IDS:
        if rid not in added_files and rid not in listed:
            later.append(f"other-roles.md: {rid} is not added and has no line here; "
                         f"add - {rid}: student, not needed, <reason>, or agent <path>")
    # A role marked not_used is accounted for but does not count toward the floor.
    rep.agents = len(added_files - unused) + len(external)
    known = added_files | set(external)

    notes = {}
    count_origin = 0
    for path in sorted((team / "handoffs").glob("*.md")):
        rel = f"handoffs/{path.name}"
        got = _read(path, rel, rep.errors)
        if got is None:
            continue
        meta, body, _ = got
        for key in ("from", "to"):
            if meta.get(key) is None:
                rep.errors.append(f"{rel}: {key} is missing")
            elif not isinstance(meta[key], str):
                rep.errors.append(f"{rel}: {key} must be a single role or person id")
            elif meta[key] not in ids:
                rep.errors.append(f"{rel}: {key} '{meta[key]}' is not a role or person")
        if meta.get("column") not in cols:
            rep.errors.append(f"{rel}: column '{meta.get('column')}' is not a column id")
        if meta.get("kind") != "origin":
            continue
        to = meta.get("to")
        if not isinstance(to, str) or to not in known:
            rep.warnings.append(f"{rel}: origin note for '{to}', which is not an added role")
            continue
        key = (str(meta.get("date", "")), path.name)
        if to not in notes or key > notes[to][0]:
            notes[to] = (key, rel, body)
    rep.origin_notes = len(notes)

    for rid in sorted(known - set(STARTER_ROLES)):
        where = f"roles/{rid}.md" if rid in added_files else "other-roles.md"
        if rid not in notes:
            later.append(f"{where}: {rid} has no origin note in handoffs/")
    for rid, (_, rel, body) in sorted(notes.items()):
        section = re.search(r"(?ms)^## Why this agent\s*$(.*?)(?=^## |\Z)", body)
        if len(LINK.findall(section.group(1) if section else "")) < 2:
            later.append(f"{rel}: Why this agent needs at least two links")

    kinds = {pid: "person" for pid in people}
    lanes = {pid: p["lanes"] for pid, p in people.items()}
    for rid, meta in roles.items():
        kinds[rid] = "agent"
        lanes[rid] = meta["lanes"]
    for kind, c, rid, what, other_id in handoff_problems(lanes, kinds, cols, set(roles)):
        if kind == "MISSING":
            msg = f"roles/{rid}.md: {c} expects '{what}' from {other_id}, who does not deliver it by then"
        else:
            msg = f"roles/{rid}.md: {c} delivers '{what}' to {other_id}, who does not expect it"
        rep.warnings.append(msg)

    if rep.agents < 3 or rep.origin_notes < 1:
        msg = f"floor: {rep.agents} agents and {rep.origin_notes} origin notes; G4 needs 3 and 1"
        (rep.errors if strict else rep.warnings).append(msg)
    return rep
