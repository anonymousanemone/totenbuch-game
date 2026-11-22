"""Generate team.json, the coverage map, and assistant files from a team folder."""

import json
import re
import shutil
from pathlib import Path

from team import fm, validate as validator
from team.status import status
from team.workspace import DEFAULTS, ROLE_IDS, column_for, team_dir

TOOLS = {"read": "Read", "search": "Grep, Glob", "edit": "Edit", "write": "Write", "shell": "Bash"}
COVERAGE_COLUMNS = ["Role", "Covered by", "Artifact", "Purpose", "Tools", "Writes", "Outputs",
                    "Handoffs", "Status", "Approval boundary"]


class RenderRefused(Exception):
    def __init__(self, errors):
        super().__init__("\n".join(errors))
        self.errors = errors


def _section(body, title):
    m = re.search(rf"(?ms)^## {re.escape(title)}[ \t]*$(.*?)(?=^## |\Z)", body)
    return m.group(1).strip() if m else ""


def _first_sentence(text):
    text = " ".join(text.split())
    m = re.search(r"[.!?](?=\s|$)", text)
    return text[:m.end()] if m else text


def _docs(body):
    return [ln[2:].strip() for ln in _section(body, "Documents this role is known for").splitlines()
            if ln.startswith("- ")]


def _cell(text):
    return " ".join(str(text).split()).replace("|", "\\|")


ALLOWED = ("agent-team", ".claude/agents", ".agents/skills")


def _check_inside(root, target):
    """Refuse a target when any part from the repository root down is a symlink."""
    here = root
    for part in target.relative_to(root).parts:
        here = here / part
        if here.is_symlink():
            raise RenderRefused([f"{here}: is a symlink; render writes only real files under "
                                 "agent-team/, .claude/agents/, and .agents/skills/"])
    resolved = target.resolve()
    if not any(resolved.is_relative_to(root.resolve() / a) for a in ALLOWED):
        raise RenderRefused([f"{target}: resolves outside agent-team/, .claude/agents/, and .agents/skills/"])


BOARD_TEMPLATE = Path(__file__).parent / "board" / "template.html"


def board_html(data):
    """The board page: the template with data inlined where it marks CREW_DATA."""
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    return BOARD_TEMPLATE.read_text(encoding="utf-8").replace("/*CREW_DATA*/", blob)


def _pairs(lane, key, side):
    return [[x[side], x["what"]] for x in lane.get(key, [])]


def _other_roles(team):
    out = {}
    path = team / "other-roles.md"
    if path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^- (\w+):[ \t]*(.*?)\s*$", line)
            if m and m.group(1) in ROLE_IDS:
                out[m.group(1)] = m.group(2)
    return out


def _lanes_table(meta, cols):
    rows = ["| Column | Does | Expects | Delivers | Recommends |", "|---|---|---|---|---|"]
    for c in cols:
        lane = meta["lanes"][c["id"]]
        exp = "; ".join(f"{w} (from {f})" for f, w in _pairs(lane, "expects", "from")) or "none"
        dlv = "; ".join(f"{w} (to {t})" for t, w in _pairs(lane, "delivers", "to")) or "none"
        rows.append("| " + " | ".join(_cell(x) for x in
                    (c["title"], lane.get("does", ""), exp, dlv, lane.get("recommends", ""))) + " |")
    return "\n".join(rows)


def _assistant_body(meta, body, cols, tools_line):
    parts = [body.strip(), "## Lanes by column\n\n" + _lanes_table(meta, cols)]
    slots = meta.get("slots") or {}
    if slots:
        parts.append("## Slot values\n\n" + "\n".join(
            f"- {s.get('label', k)}: {s['value']}" for k, s in sorted(slots.items())))
    if tools_line:
        parts.append(tools_line)
    return "\n\n".join(parts) + "\n"


def render(root, today):
    root = Path(root)
    team = team_dir(root)
    rep = validator.validate(team, today)
    if rep.errors:
        raise RenderRefused(rep.errors)
    cdata = json.loads((DEFAULTS / "columns.json").read_text(encoding="utf-8"))
    cols = cdata["columns"]
    cids = [c["id"] for c in cols]
    ctitle = {c["id"]: c["title"] for c in cols}
    people = json.loads((DEFAULTS / "people.json").read_text(encoding="utf-8"))
    others_val = _other_roles(team)

    roles, bodies, stat = {}, {}, {}
    for rid in ROLE_IDS:
        path = team / "roles" / f"{rid}.md"
        if path.is_file():
            meta, body = fm.parse(path.read_text(encoding="utf-8"), str(path))
            roles[rid], bodies[rid] = meta, body
            stat[rid] = status(path, DEFAULTS / "roles" / f"{rid}.md", root)

    notes = []
    for path in sorted((team / "handoffs").glob("*.md")):
        meta, body = fm.parse(path.read_text(encoding="utf-8"), str(path))
        notes.append({"file": f"handoffs/{path.name}", "from": meta.get("from"), "to": meta.get("to"),
                      "kind": meta.get("kind", ""), "column": meta.get("column"),
                      "routed": bool(_section(body, "Student decision"))})

    out_roles = dict(people)
    for rid, meta in roles.items():
        body = bodies[rid]
        out_roles[rid] = {
            "title": meta.get("title", rid), "subtitle": meta.get("subtitle", ""),
            "kind": "agent", "editable": True, "worked": rid == "qa",
            "primer": _section(body, "What this role does on a team"), "docs": _docs(body),
            "slots": meta.get("slots") or {},
            "lanes": {c: {"does": meta["lanes"][c].get("does", ""),
                          "expects": _pairs(meta["lanes"][c], "expects", "from"),
                          "delivers": _pairs(meta["lanes"][c], "delivers", "to"),
                          "recommends": meta["lanes"][c].get("recommends", "")} for c in cids},
        }
    others = []
    for rid in ROLE_IDS:
        if rid in roles:
            continue
        dmeta = fm.parse((DEFAULTS / "roles" / f"{rid}.md").read_text(encoding="utf-8"))[0]
        others.append({"id": rid, "title": dmeta.get("title", rid),
                       "covered_by": others_val.get(rid) or "unset"})
    first = next(iter(roles.values()), {})
    data = {"game": first.get("game", ""), "columns": cols, "roles": out_roles, "others": others,
            "rendered_on": today.isoformat(), "status": stat, "warnings": rep.warnings, "notes": notes}
    pending = []
    written = [team / "team.json"]
    pending.append((written[0], json.dumps(data, indent=1, sort_keys=True, ensure_ascii=False) + "\n"))

    board = team / "board.html"
    pending.append((board, board_html(data)))
    written.append(board)

    # Assistant files.
    agents_dir, skills_dir = root / ".claude" / "agents", root / ".agents" / "skills"
    rows = []
    for rid in ROLE_IDS:
        if rid in roles and stat[rid] == "not used":
            rows.append([rid, "not used", "n/a", str(roles[rid].get("not_used", ""))]
                        + ["n/a"] * 4 + [stat[rid], "n/a"])
        elif rid in roles:
            meta, body = roles[rid], bodies[rid]
            col = cdata["columns"][cids.index(column_for(today))]["title"]
            purpose = _first_sentence(out_roles[rid]["primer"])
            desc = f"{purpose} Current phase: {col}."
            tools = [t for t in (meta.get("permissions") or {}).get("tools", [])]
            tool_names = ", ".join(TOOLS[t] for t in tools if t in TOOLS)
            name = f"team-{rid}"
            apath = agents_dir / f"{name}.md"
            spath = skills_dir / name / "SKILL.md"
            pending.append((apath, fm.dump({"name": name, "description": desc, "tools": tool_names},
                                  _assistant_body(meta, body, cols, ""))))
            pending.append((spath, fm.dump({"name": name, "description": desc},
                                  _assistant_body(meta, body, cols, f"Use only these tools: {tool_names}."))))
            written += [apath, spath]
            outs, hands = [], []
            for c in cids:
                for t, w in _pairs(meta["lanes"][c], "delivers", "to"):
                    if w not in outs:
                        outs.append(w)
                    if t not in hands:
                        hands.append(t)
            rel = lambda p: p.relative_to(root).as_posix()
            rows.append([rid, "agent", f"{rel(apath)}, {rel(spath)}", purpose, tool_names,
                         (meta.get("permissions") or {}).get("writes", ""), "; ".join(outs),
                         ", ".join(hands), stat[rid], validator.BOUNDARY])
        else:
            rows.append([rid, others_val.get(rid) or "unset"] + ["n/a"] * 8)
    # Only team-<id> files for a fixed role id that is not in use are stale; any other
    # team-*.md agent or team-* skill is the student's own and stays.
    gone = [f"team-{r}" for r in ROLE_IDS if r not in roles or stat[r] == "not used"]
    stale = []
    if agents_dir.is_dir() and not agents_dir.is_symlink():
        stale += [p for p in (agents_dir / f"{n}.md" for n in gone) if p.is_file() and not p.is_symlink()]
    if skills_dir.is_dir() and not skills_dir.is_symlink():
        stale += [p for p in (skills_dir / n for n in gone) if p.is_dir() and not p.is_symlink()]

    lines = ["# Coverage map", "", "| " + " | ".join(COVERAGE_COLUMNS) + " |",
             "|" + "---|" * len(COVERAGE_COLUMNS)]
    lines += ["| " + " | ".join(_cell(x) for x in r) + " |" for r in rows]
    if rep.warnings:
        lines += ["", "Warnings:", ""] + [f"- {w}" for w in rep.warnings]
    lines += ["", f"Agents: {rep.agents} of 3 by G4. Origin notes: {rep.origin_notes} of 1 by G4."]
    cov = team / "coverage-map.md"
    pending.append((cov, "\n".join(lines) + "\n"))
    written.append(cov)
    for path, _ in pending:
        _check_inside(root, path)
    for path in stale:
        _check_inside(root, path)
    for path, text in pending:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.replace("\r\n", "\n").encode("utf-8"))
    for path in stale:
        shutil.rmtree(path) if path.is_dir() else path.unlink()
    return sorted(written)
