"""Command line: python -m team {init,add,validate,render,serve}."""

import argparse
import json
import sys
from datetime import date
from pathlib import Path

from team import render, validate, workspace
from team.workspace import WorkspaceError


def build_parser():
    p = argparse.ArgumentParser(prog="python -m team", description="Set up and check your agent team.")
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--today", default=argparse.SUPPRESS, help="YYYY-MM-DD (default: today)")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("init", parents=[common], help="create agent-team/ with the tech and qa starter roles")
    a = sub.add_parser("add", parents=[common], help="add one more role")
    a.add_argument("role")
    sub.add_parser("validate", parents=[common], help="check your team files")
    sub.add_parser("render", parents=[common], help="generate assistant files")
    s = sub.add_parser("serve", parents=[common], help="open the board on this computer and save role edits")
    s.add_argument("--port", type=int, default=8765)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    args.today = getattr(args, "today", None)
    from_json = args.today == "from-team-json"
    if from_json and args.command != "render":
        print("--today from-team-json works only with render.")
        return 1
    try:
        today = date.today() if from_json or not args.today else date.fromisoformat(args.today)
    except ValueError:
        print(f"--today must look like 2026-11-24, not '{args.today}'.")
        return 1
    try:
        root = workspace.repo_root(Path.cwd())
        if args.command == "validate":
            team = workspace.team_dir(root)
            if not team.is_dir():
                print("no agent-team/ yet; run python -m team init")
                return 0
            rep = validate.validate(team, today)
            for line in rep.errors + rep.warnings:
                print(line)
            print(f"agents={rep.agents} origin_notes={rep.origin_notes}")
            return 1 if rep.errors else 0
        if args.command == "render":
            team = workspace.team_dir(root)
            if not team.is_dir():
                print("no agent-team/ yet; run python -m team init")
                return 0
            if from_json:
                try:
                    today = date.fromisoformat(
                        json.loads((team / "team.json").read_text(encoding="utf-8"))["rendered_on"])
                except (OSError, ValueError, KeyError, TypeError):
                    print(f"{team / 'team.json'} is missing or has no rendered_on; run render once with --today.")
                    return 1
            try:
                paths = render.render(root, today)
            except render.RenderRefused as e:
                for line in e.errors:
                    print(line)
                print("Nothing was generated. Fix the errors above and run render again.")
                return 1
            for p in paths:
                print(p.relative_to(root).as_posix())
            return 0
        if args.command == "serve":
            if not (workspace.team_dir(root) / "roles").is_dir():
                print("no agent-team/ yet; run python -m team init")
                return 1
            from team import serve as server
            return server.serve(root, args.port, today)
        if args.command == "init":
            team = workspace.init(root)
            print(f"Created {team} with the tech and qa roles.")
            try:
                for p in render.render(root, today):
                    print(p.relative_to(root).as_posix())
            except render.RenderRefused as e:
                for line in e.errors:
                    print(line)
                print("Fix the errors above, then run python -m team render.")
                return 1
            print("After each edit, run python -m team render and commit everything it writes.")
            print("Add another role with: python -m team add <role>")
        else:
            note = workspace.add(root, args.role, today)
            print(note)
            print("Fill in Why this agent before you route it.")
    except WorkspaceError as e:
        print(e)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
