"""Create and extend the agent-team/ folder at the root of a student's repository."""

import json
import re
import shutil
import subprocess
from datetime import date
from pathlib import Path

DEFAULTS = Path(__file__).resolve().parent / "defaults"
ROLE_IDS = ["producer", "design", "tech", "art", "narrative", "qa", "bi", "release"]
STARTER_ROLES = ["tech", "qa"]


class WorkspaceError(Exception):
    pass


def _run(args, cwd):
    try:
        done = subprocess.run(args, cwd=str(cwd), capture_output=True, text=True)
    except OSError:
        return None
    return done.stdout.strip() if done.returncode == 0 else None


def repo_root(start):
    out = _run(["git", "rev-parse", "--show-toplevel"], Path(start))
    if not out:
        raise WorkspaceError("Run this inside your repository (no Git repository found here).")
    return Path(out).resolve()


def team_dir(root):
    return Path(root) / "agent-team"


def _columns():
    return json.loads((DEFAULTS / "columns.json").read_text(encoding="utf-8"))


def column_for(today):
    starts = _columns()["starts"]
    chosen = "ideation"
    for cid, iso in starts.items():
        if date.fromisoformat(iso) <= today:
            chosen = cid
    return chosen


def init(root):
    team = team_dir(root)
    if team.exists():
        raise WorkspaceError(f"{team} already exists. Use `python -m team add <role>` to add an agent.")
    (team / "roles").mkdir(parents=True)
    (team / "handoffs").mkdir()
    for rid in STARTER_ROLES:
        shutil.copyfile(DEFAULTS / "roles" / f"{rid}.md", team / "roles" / f"{rid}.md")
    lines = ["# Roles not added"] + [f"- {r}: " for r in ROLE_IDS if r not in STARTER_ROLES]
    (team / "other-roles.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return team


def add(root, role, today):
    if role not in ROLE_IDS:
        raise WorkspaceError(f"Unknown role '{role}'. Choose one of: {', '.join(ROLE_IDS)}.")
    team = team_dir(root)
    if not team.is_dir():
        raise WorkspaceError("No team folder yet. Run `python -m team init` first.")
    target = team / "roles" / f"{role}.md"
    if target.exists():
        raise WorkspaceError(f"{target} already exists; the role is already added.")
    shutil.copyfile(DEFAULTS / "roles" / f"{role}.md", target)
    stem = f"{today.isoformat()}-student-to-{role}"
    note, n = team / "handoffs" / f"{stem}.md", 1
    while note.exists() or note.is_symlink():
        n += 1
        note = team / "handoffs" / f"{stem}-{n}.md"
    text = (DEFAULTS / "origin-template.md").read_text(encoding="utf-8")
    head, sep, rest = text.partition("\n---\n")
    for key, value in (("ROLE", role), ("COLUMN", column_for(today)), ("DATE", today.isoformat())):
        head = re.sub(rf"(?m)^(\w+: ){key}$", rf"\g<1>{value}", head)
    note.write_text(head + sep + rest, encoding="utf-8")
    other = team / "other-roles.md"
    if other.is_file():
        kept = [ln for ln in other.read_text(encoding="utf-8").splitlines()
                if not ln.startswith(f"- {role}:")]
        other.write_text("\n".join(kept) + "\n", encoding="utf-8")
    return note
