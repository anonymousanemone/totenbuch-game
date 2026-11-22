import os
import subprocess
import tempfile
import unittest
from datetime import date
from pathlib import Path

from team import fm, workspace
from team.workspace import WorkspaceError


def make_repo():
    tmp = tempfile.TemporaryDirectory()
    root = Path(tmp.name).resolve()
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    game = root / "game" / "main.py"
    game.parent.mkdir(parents=True)
    game.write_bytes(b"print('game')\n")
    os.utime(game, (1_000_000_000, 1_000_000_000))
    (root / "midterm").mkdir()
    (root / "midterm" / "README.md").write_bytes(b"# Midterm\n")
    return tmp, root, game


class WorkspaceTest(unittest.TestCase):
    def setUp(self):
        self.tmp, self.root, self.game = make_repo()
        self.addCleanup(self.tmp.cleanup)
        self.team = workspace.team_dir(self.root)

    def test_init_creates_two_roles_only(self):
        workspace.init(self.root)
        self.assertEqual(sorted(p.name for p in (self.team / "roles").iterdir()),
                         ["qa.md", "tech.md"])
        self.assertTrue((self.team / "handoffs").is_dir())
        other = (self.team / "other-roles.md").read_text(encoding="utf-8")
        for rid in ["producer", "design", "art", "narrative", "bi", "release"]:
            self.assertIn(f"- {rid}: \n", other)
        self.assertNotIn("- tech:", other)
        self.assertNotIn("- qa:", other)

    def test_init_leaves_game_untouched(self):
        before = (self.game.read_bytes(), self.game.stat().st_mtime)
        workspace.init(self.root)
        self.assertEqual((self.game.read_bytes(), self.game.stat().st_mtime), before)
        entries = sorted(p.name for p in self.root.iterdir() if p.name != ".git")
        self.assertEqual(entries, ["agent-team", "game", "midterm"])

    def test_init_twice_refuses(self):
        workspace.init(self.root)
        with self.assertRaises(WorkspaceError):
            workspace.init(self.root)

    def test_add_writes_role_and_note(self):
        workspace.init(self.root)
        note = workspace.add(self.root, "design", date(2026, 11, 24))
        self.assertEqual(note, self.team / "handoffs" / "2026-11-24-student-to-design.md")
        meta, _ = fm.parse(note.read_text(encoding="utf-8"), str(note))
        self.assertEqual(meta["column"], "prototype")
        self.assertEqual(meta["kind"], "origin")
        self.assertEqual(meta["to"], "design")
        self.assertEqual(meta["date"], "2026-11-24")
        self.assertTrue((self.team / "roles" / "design.md").is_file())

    def test_add_updates_other_roles(self):
        workspace.init(self.root)
        workspace.add(self.root, "design", date(2026, 11, 24))
        other = (self.team / "other-roles.md").read_text(encoding="utf-8")
        self.assertNotIn("- design:", other)
        self.assertIn("- art: \n", other)

    def test_add_again_keeps_existing_origin_note(self):
        workspace.init(self.root)
        first = workspace.add(self.root, "design", date(2026, 11, 24))
        first.write_text(first.read_text(encoding="utf-8") + "my notes\n", encoding="utf-8")
        kept = first.read_bytes()
        (self.team / "roles" / "design.md").unlink()
        second = workspace.add(self.root, "design", date(2026, 11, 24))
        self.assertEqual(second.name, "2026-11-24-student-to-design-2.md")
        self.assertEqual(first.read_bytes(), kept)
        (self.team / "roles" / "design.md").unlink()
        third = workspace.add(self.root, "design", date(2026, 11, 24))
        self.assertEqual(third.name, "2026-11-24-student-to-design-3.md")

    def test_add_existing_refuses(self):
        workspace.init(self.root)
        with self.assertRaises(WorkspaceError):
            workspace.add(self.root, "tech", date(2026, 11, 24))

    def test_add_unknown_refuses(self):
        workspace.init(self.root)
        with self.assertRaises(WorkspaceError):
            workspace.add(self.root, "wizard", date(2026, 11, 24))

    def test_team_dir_is_agent_team(self):
        self.assertEqual(workspace.team_dir(self.root), self.root / "agent-team")
        self.assertFalse(hasattr(workspace, "resolve_login"))

    def test_init_in_repo_with_game_touches_only_agent_team(self):
        mid = self.root / "midterm" / "README.md"
        before = (self.game.read_bytes(), mid.read_bytes())
        workspace.init(self.root)
        self.assertEqual((self.game.read_bytes(), mid.read_bytes()), before)
        self.assertEqual(self.team, self.root / "agent-team")
        self.assertTrue((self.team / "roles" / "tech.md").is_file())

    def test_cli_has_no_login_flag(self):
        from team.__main__ import build_parser
        with self.assertRaises(SystemExit) as cm:
            build_parser().parse_args(["init", "--" + "login", "x"])
        self.assertEqual(cm.exception.code, 2)

    def test_outside_git_refuses(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(WorkspaceError):
                workspace.repo_root(Path(d).resolve())

    def test_repo_root_from_subfolder(self):
        self.assertEqual(workspace.repo_root(self.game.parent), self.root)

    def test_column_for_boundaries(self):
        self.assertEqual(workspace.column_for(date(2026, 11, 28)), "G2")
        self.assertEqual(workspace.column_for(date(2026, 11, 27)), "prototype")
        self.assertEqual(workspace.column_for(date(2026, 12, 14)), "G5")
        self.assertEqual(workspace.column_for(date(2026, 10, 1)), "ideation")


if __name__ == "__main__":
    unittest.main()
