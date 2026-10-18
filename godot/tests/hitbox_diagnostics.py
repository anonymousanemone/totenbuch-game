"""Read-only evidence for scene/JSON mismatches; never synchronize either source."""

import ast
import json
import subprocess


def _git(project, *arguments):
    result = subprocess.run(
        ["git", "-C", str(project.parent), *arguments],
        capture_output=True, text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def _legacy_export_boxes(project):
    """Read the cutter's constants without importing or running the art exporter."""
    path = project.parent / "tools/cut_procession300.py"
    if not path.exists():
        return {}
    assignments = {
        node.targets[0].id: node.value
        for node in ast.parse(path.read_text()).body
        if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name)
    }
    ground = ast.literal_eval(assignments["GROUND"])

    class ResolveGround(ast.NodeTransformer):
        def visit_Name(self, node):
            return ast.Constant(ground) if node.id == "GROUND" else node

    entries = ast.literal_eval(ResolveGround().visit(assignments["STRIP_HOTSPOTS"]))
    return {
        key: dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0)
        for _, (x0, y0, x1, y1), key in entries
    }


def diagnose_hitbox_mismatches(project, output):
    print("Hitbox investigation (read-only; no automatic fixes):")
    changed = {}
    for name in ("scenes/procession.tscn", "assets/procession/level.json"):
        path = "godot/" + name
        diff = _git(project, "diff", "HEAD", "--numstat", "--", path)
        changed[name] = bool(diff) if diff is not None else None
        state = "changed since HEAD" if diff else "unchanged since HEAD"
        print(f"  {path}: {state if diff is not None else 'Git history unavailable'}.")
    try:
        legacy = _legacy_export_boxes(project)
    except (SyntaxError, ValueError, KeyError):
        legacy = {}
        print("  Could not compare current exporter constants; inspect its hitbox-writing code.")
    for line in output.splitlines():
        if not line.startswith("HITBOX_MISMATCH "):
            continue
        mismatch = json.loads(line.removeprefix("HITBOX_MISMATCH "))
        previous = legacy.get(mismatch["id"], {})
        if previous and all(
            abs(mismatch["json"].get(key, float("inf")) - value) < 0.001
            for key, value in previous.items()
        ):
            print(f"  {mismatch['id']}: JSON matches the legacy cutter's measured box. "
                  "A re-export restoring old JSON is a possible cause, not proof.")
    if changed.get("scenes/procession.tscn") and changed.get("assets/procession/level.json") is False:
        print("  Only the scene changed: inspect manual shape edits and parent transforms first.")
    elif changed.get("assets/procession/level.json") and changed.get("scenes/procession.tscn") is False:
        print("  Only JSON changed: inspect re-export output or manual JSON edits first.")
    else:
        print("  These files alone cannot establish who changed the boxes or which edit caused it.")
    print("  Inspect git diff/history for these files and tools/cut_procession300.py. "
          "Its patch_water(), patch(), and main() paths can replace hotspot JSON with "
          "legacy measurements. Do not run an exporter or recalculate boxes to repair this test.")
