"""One-time generator: read the design master's crew.json and write the shipped defaults.

Usage: python team/tools/import_master.py path/to/crew.json

Writes team/defaults/columns.json, people.json, and roles/<id>.md for the eight
agent roles. Kept for audit; tests and CI never run it. If a role file already
exists, its hand-written Instructions section is preserved.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT.parent))

from team import fm  # noqa: E402

DEFAULTS = ROOT / "defaults"
TOOLS = {
    "producer": (["read", "search", "write"], "plan and PPP documents, handoff notes"),
    "design": (["read", "search", "write"], "GDD, playtest questions, handoff notes"),
    "tech": (["read", "search", "edit", "write", "shell"], "game code and tests, handoff notes"),
    "art": (["read", "search", "write"], "style guide, asset list, handoff notes"),
    "narrative": (["read", "search", "write"], "text inventory, voice guide, handoff notes"),
    "qa": (["read", "search", "shell"], "tests and handoff notes"),
    "bi": (["read", "search", "write"], "Playtest Log, evaluation summary, handoff notes"),
    "release": (["read", "search", "write", "shell"], "README release section, handoff notes"),
}
STARTS = {
    "ideation": "2026-11-09", "G1": "2026-11-15", "prototype": "2026-11-17",
    "G2": "2026-11-28", "planning": "2026-11-29", "G3": "2026-11-30",
    "production": "2026-12-01", "G4": "2026-12-05", "release": "2026-12-08",
    "G5": "2026-12-14",
}
PLACEHOLDER = "## Instructions\nWrite this role's instructions here.\n"


def clean(text):
    return text.replace("your crew", "your agent team").replace("crew coverage", "agent team coverage")


def clean_deep(x):
    if isinstance(x, str):
        return clean(x)
    if isinstance(x, list):
        return [clean_deep(i) for i in x]
    if isinstance(x, dict):
        return {k: clean_deep(v) for k, v in x.items()}
    return x


def lanes_of(role, columns):
    out = {}
    for c in columns:
        L = role["lanes"][c]
        out[c] = {
            "does": L["does"],
            "expects": [{"from": f, "what": w} for f, w in L["expects"]],
            "delivers": [{"to": t, "what": w} for t, w in L["delivers"]],
            "recommends": L["recommends"],
        }
    return out


def main(path):
    master = clean_deep(json.load(open(path, encoding="utf-8")))
    columns = master["columns"]
    ids = [c["id"] for c in columns]
    (DEFAULTS / "roles").mkdir(parents=True, exist_ok=True)

    cols = {"columns": columns, "starts": STARTS,
            "dates": {"default_warning": "2026-11-30", "strict": "2026-12-05"}}
    (DEFAULTS / "columns.json").write_text(json.dumps(cols, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    people = {k: master["roles"][k] for k in ("student", "instructor")}
    (DEFAULTS / "people.json").write_text(json.dumps(people, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    for rid, (tools, writes) in TOOLS.items():
        r = master["roles"][rid]
        meta = {
            "id": rid, "title": r["title"], "subtitle": r["subtitle"], "gdf_role": r["title"],
            "game": master["game"],
            "permissions": {"tools": tools, "writes": writes},
            "not_used": "",
            "slots": {k: {"label": s["label"], "value": s["value"]} for k, s in r["slots"].items()},
            "lanes": lanes_of(r, ids),
        }
        target = DEFAULTS / "roles" / f"{rid}.md"
        instructions = PLACEHOLDER
        if target.exists():
            _, old = fm.parse(target.read_text(encoding="utf-8"), str(target))
            if "## Instructions" in old:
                instructions = "## Instructions" + old.split("## Instructions", 1)[1]
        docs = "\n".join(f"- {d}" for d in r["docs"])
        body = (f"# {r['title']}\n\n## What this role does on a team\n{r['primer']}\n\n"
                f"## Documents this role is known for\n{docs}\n\n{instructions.rstrip()}\n")
        target.write_text(fm.dump(meta, body), encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1])
