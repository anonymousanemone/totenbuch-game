"""Classify a role file as default, tailored, revised, or not used."""

import subprocess
import time
from pathlib import Path

from team import fm


def _meta(path):
    try:
        return fm.parse(Path(path).read_text(encoding="utf-8"), str(path))[0]
    except (OSError, UnicodeDecodeError, fm.FrontmatterError):
        return {}


def _times(root, args, path):
    try:
        done = subprocess.run(["git", "log", "--format=%ct", *args, "--", str(path)],
                              cwd=str(root), capture_output=True, text=True)
    except OSError:
        return []
    if done.returncode != 0:
        return []
    return [int(x) for x in done.stdout.split() if x.isdigit()]


def _changed_since_commit(root, path):
    """True when the file differs from HEAD, is staged, or is untracked."""
    try:
        done = subprocess.run(["git", "status", "--porcelain", "--untracked-files=all", "--", str(path)],
                              cwd=str(root), capture_output=True, text=True)
    except OSError:
        return False
    return done.returncode == 0 and bool(done.stdout.strip())


def status(role_path, default_path, root):
    role_path, root = Path(role_path), Path(root)
    meta, default = _meta(role_path), _meta(default_path)
    if str(meta.get("not_used", "")).strip():
        return "not used"
    if (meta.get("lanes"), meta.get("slots", {})) == (default.get("lanes"), default.get("slots", {})):
        return "default"
    rid = meta.get("id", role_path.stem)
    added = []
    for note in sorted((role_path.parent.parent / "handoffs").glob("*.md")):
        if _meta(note).get("from") == rid:
            added += _times(root, ["--diff-filter=A"], note)
    edits = _times(root, [], role_path)
    # An edit not yet committed counts as made now, so the status shown before the commit
    # matches what CI computes from history after it.
    if _changed_since_commit(root, role_path):
        edits.append(int(time.time()))
    if added and edits and max(edits) > min(added):
        return "revised"
    return "tailored"
