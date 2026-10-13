"""Run all gameplay and script regression suites, rejecting unexpected engine errors."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", help="Path to the Godot executable")
    args = parser.parse_args()
    godot = args.godot or shutil.which("godot") or shutil.which("godot4")
    if not godot:
        macos_binary = Path("/Applications/Godot.app/Contents/MacOS/Godot")
        if macos_binary.exists():
            godot = str(macos_binary)
    if not godot:
        parser.error("Godot was not found; pass its executable with --godot")

    project = Path(__file__).resolve().parents[1]
    suites = [
        (level, ["--", f"--level={level}", "--autotest"], "AUTOTEST OK")
        for level in ("procession", "cosmos", "field", "hall", "dangers")
    ]
    suites.append(("regressions", ["--script", "res://tests/script_regressions.gd"], "REGRESSIONS OK"))
    # These also occur in the committed baseline. The sampler diagnostic is specific
    # to compiling the existing glow shader with Godot's headless dummy renderer.
    baseline_diagnostics = (
        '!actions.custom_samplers.has(function->arguments[j].tex_builtin)',
        'Condition "ret != noErr" is true. Returning: ""',  # macOS certificate access
    )
    failures = []
    total_checks = 0
    with tempfile.TemporaryDirectory(prefix="totenbuch-tests-") as logs:
        for name, arguments, expected in suites:
            command = [godot, "--headless", "--path", str(project),
                       "--log-file", str(Path(logs) / f"{name}.log"), *arguments]
            try:
                result = subprocess.run(command, capture_output=True, text=True, timeout=60)
            except subprocess.TimeoutExpired:
                print(f"FAIL {name}: exceeded 60 seconds")
                failures.append(name)
                continue
            output = result.stdout + result.stderr
            checks = sum(line.startswith("PASS ") for line in output.splitlines())
            errors = [line for line in output.splitlines()
                      if "ERROR:" in line and not any(known in line for known in baseline_diagnostics)]
            passed = result.returncode == 0 and expected in output and not errors and "FAIL " not in output
            total_checks += checks
            print(f"{'PASS' if passed else 'FAIL'} {name}: {checks} checks")
            diagnostics = sum(any(known in line for known in baseline_diagnostics)
                              for line in output.splitlines())
            if diagnostics:
                print(f"  {diagnostics} known baseline engine diagnostic(s)")
            if "ObjectDB instances were leaked" in output:
                print("  Engine reported the existing exit-time object leak warning")
            if not passed:
                failures.append(name)
                print(output)
    print(f"{total_checks} checks across {len(suites)} suites; {len(failures)} failed suites")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
