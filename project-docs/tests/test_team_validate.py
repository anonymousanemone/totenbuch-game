import subprocess
import tempfile
import unittest
from datetime import date
from pathlib import Path

from team import validate, workspace

FIXTURES = Path(__file__).resolve().parent / "fixtures" / "team"
LINKS = "See [one](https://a.example/1) and [two](https://a.example/2).\n"


def make_team(add=()):
    tmp = tempfile.TemporaryDirectory()
    root = Path(tmp.name).resolve()
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    team = workspace.init(root)
    notes = {}
    for role in add:
        notes[role] = workspace.add(root, role, date(2026, 11, 24))
    return tmp, team, notes


def fill_other(team, ids=()):
    other = team / "other-roles.md"
    lines = [ln.rstrip() + " student" if ln.startswith("- ") and ln.rstrip().endswith(":") else ln
             for ln in other.read_text(encoding="utf-8").splitlines()]
    other.write_text("\n".join(lines) + "\n", encoding="utf-8")


def with_links(note, text=LINKS):
    s = note.read_text(encoding="utf-8")
    note.write_text(s.replace("## Why this agent\n", "## Why this agent\n" + text, 1), encoding="utf-8")


class ValidateTest(unittest.TestCase):
    def setUp(self):
        self.tmp, self.team, self.notes = make_team()
        self.addCleanup(self.tmp.cleanup)

    def run_v(self, today=date(2026, 11, 24)):
        return validate.validate(self.team, today)

    def only(self, rep, kind, fragment):
        msgs = getattr(rep, kind)
        hits = [m for m in msgs if fragment in m]
        self.assertEqual(len(hits), 1, msgs)
        return hits[0]

    def edit(self, rel, old, new):
        p = self.team / rel
        s = p.read_text(encoding="utf-8")
        self.assertIn(old, s)
        p.write_text(s.replace(old, new, 1), encoding="utf-8")

    def test_defaults_after_init_clean_before_nov30(self):
        rep = self.run_v()
        self.assertEqual(rep.errors, [])
        floor = [w for w in rep.warnings if w.startswith("floor:")]
        empty = [w for w in rep.warnings if w.startswith("other-roles.md:")]
        self.assertEqual(floor, ["floor: 2 agents and 0 origin notes; G4 needs 3 and 1"])
        self.assertEqual(len(empty), 6)
        self.assertEqual(len(rep.warnings), 7, rep.warnings)
        self.assertEqual((rep.agents, rep.origin_notes), (2, 0))

    def test_default_warning_from_nov30(self):
        fill_other(self.team)
        self.assertEqual([w for w in self.run_v(date(2026, 11, 29)).warnings if "shipped default" in w], [])
        rep = self.run_v(date(2026, 11, 30))
        self.only(rep, "warnings", "roles/tech.md: still the shipped default")
        self.only(rep, "warnings", "roles/qa.md: still the shipped default")
        self.assertEqual(rep.errors, [])

    def test_unknown_from(self):
        fill_other(self.team)
        self.edit("roles/qa.md", "      - from: design\n        what: \"core loop\"",
                  "      - from: wizard\n        what: \"core loop\"")
        rep = self.run_v()
        self.only(rep, "errors", "roles/qa.md: G1 expects names 'wizard'")
        self.assertEqual(len(rep.errors), 1)

    def test_missing_boundary(self):
        self.edit("roles/tech.md", validate.BOUNDARY, "Do what you like.")
        rep = self.run_v()
        self.only(rep, "errors", "roles/tech.md: the approval-boundary sentence is missing")
        self.assertEqual(len(rep.errors), 1)

    def test_parse_error_reported_not_raised(self):
        self.edit("roles/tech.md", 'title: "Tech Lead"', "title: Tech: lead")
        rep = self.run_v()
        msg = self.only(rep, "errors", "roles/tech.md:")
        self.assertRegex(msg, r"^roles/tech\.md:\d+: ")
        self.assertEqual(len(rep.errors), 1)

    def test_static_bad_yaml_fixture(self):
        rep = validate.validate(FIXTURES / "bad-yaml", date(2026, 11, 24))
        self.only(rep, "errors", "roles/tech.md:3:")

    def test_unparsable_handoff_names_file(self):
        (self.team / "handoffs" / "notes.md").write_text("just text\n", encoding="utf-8")
        rep = self.run_v()
        self.only(rep, "errors", "handoffs/notes.md:1:")

    def test_id_must_match_filename(self):
        self.edit("roles/tech.md", "id: tech", "id: art")
        self.only(self.run_v(), "errors", "roles/tech.md: id 'art' must match the file name")

    def test_non_string_ids_are_errors_not_tracebacks(self):
        fill_other(self.team)
        note = self.team / "handoffs" / "a.md"
        note.write_text("---\nfrom: [a]\nto: tech\ncolumn: G1\ndate: 2026-11-24\n---\nx\n", encoding="utf-8")
        rep = self.run_v()
        self.only(rep, "errors", "handoffs/a.md: from must be a single role or person id")
        note.write_text("---\nfrom: student\nto: [b]\nkind: origin\ncolumn: G1\ndate: 2026-11-24\n---\nx\n",
                        encoding="utf-8")
        rep = self.run_v()
        self.only(rep, "errors", "handoffs/a.md: to must be a single role or person id")
        note.unlink()
        self.edit("roles/qa.md", "      - from: design\n        what: \"core loop\"",
                  "      - from: [a]\n        what: \"core loop\"")
        rep = self.run_v()
        self.only(rep, "errors", "roles/qa.md: G1 expects must name a single role or person id")

    def test_missing_column_and_slot_value(self):
        self.edit("roles/qa.md", "    value: \"Blocker, major, minor, cosmetic\"", "    value: \"\"")
        rep = self.run_v()
        self.only(rep, "errors", "roles/qa.md: slot 'severity' has no value")

    def test_slot_key_rule(self):
        for bad in ("max players", "max.players"):
            self.edit("roles/qa.md", "  severity:", f"  {bad}:")
            rep = self.run_v()
            self.assertTrue(any(bad in m for m in rep.errors), rep.errors)
            self.edit("roles/qa.md", f"  {bad}:", "  severity:")
        for good in ("max-players", "Max_2"):
            self.edit("roles/qa.md", "  severity:", f"  {good}:")
            rep = self.run_v()
            self.assertEqual([m for m in rep.errors if "slot key" in m], [])
            self.edit("roles/qa.md", f"  {good}:", "  severity:")

    def test_reference_to_role_not_added_is_student(self):
        fill_other(self.team)
        rep = self.run_v()
        for w in rep.warnings:
            self.assertNotIn("expects", w)
            self.assertNotIn("delivers", w)

    def test_unmatched_expectation_between_added_roles(self):
        fill_other(self.team)
        self.edit("roles/tech.md", "      - to: qa\n        what: \"fixes to verify\"\n", "")
        rep = self.run_v()
        self.only(rep, "warnings", "roles/qa.md: production expects 'fixes to verify' from tech")
        self.assertEqual(rep.errors, [])

    def test_origin_note_one_link_warns_then_errors(self):
        tmp, team, notes = make_team(add=["art"])
        self.addCleanup(tmp.cleanup)
        fill_other(team)
        with_links(notes["art"], "Only [one](https://a.example/1).\n")
        rep = validate.validate(team, date(2026, 12, 4))
        self.assertEqual(rep.errors, [])
        w = [m for m in rep.warnings if "Why this agent" in m]
        self.assertEqual(len(w), 1, rep.warnings)
        rep = validate.validate(team, date(2026, 12, 5))
        e = [m for m in rep.errors if "Why this agent" in m]
        self.assertEqual(len(e), 1, rep.errors)
        self.assertEqual([m for m in rep.warnings if "Why this agent" in m], [])

    def test_bare_urls_count_as_links(self):
        tmp, team, notes = make_team(add=["art"])
        self.addCleanup(tmp.cleanup)
        fill_other(team)
        with_links(notes["art"], "http://a.example/1 and https://a.example/2\n")
        rep = validate.validate(team, date(2026, 12, 5))
        self.assertEqual([m for m in rep.errors if "Why this agent" in m], [])

    def test_agent_without_origin_note(self):
        tmp, team, notes = make_team(add=["art"])
        self.addCleanup(tmp.cleanup)
        fill_other(team)
        notes["art"].unlink()
        rep = validate.validate(team, date(2026, 11, 24))
        msg = [m for m in rep.warnings if "no origin note" in m]
        self.assertEqual(msg, ["roles/art.md: art has no origin note in handoffs/"])
        rep = validate.validate(team, date(2026, 12, 5))
        self.assertEqual(len([m for m in rep.errors if "no origin note" in m]), 1)

    def test_note_for_role_not_added(self):
        tmp, team, notes = make_team(add=["art"])
        self.addCleanup(tmp.cleanup)
        fill_other(team)
        (team / "roles" / "art.md").unlink()
        rep = validate.validate(team, date(2026, 11, 24))
        w = [m for m in rep.warnings if "not an added role" in m]
        self.assertEqual(len(w), 1)
        self.assertTrue(w[0].startswith("handoffs/2026-11-24-student-to-art.md:"))

    def test_two_origin_notes_latest_counts(self):
        tmp, team, notes = make_team(add=["art"])
        self.addCleanup(tmp.cleanup)
        fill_other(team)
        with_links(notes["art"])
        older = team / "handoffs" / "2026-11-20-student-to-art.md"
        older.write_text(notes["art"].read_text(encoding="utf-8").replace("2026-11-24", "2026-11-20")
                         .replace(LINKS, ""), encoding="utf-8")
        rep = validate.validate(team, date(2026, 12, 5))
        self.assertEqual([m for m in rep.errors if "Why this agent" in m], [])
        self.assertEqual(rep.origin_notes, 1)

    def test_external_agent_counts(self):
        fill_other(self.team)
        self.edit("other-roles.md", "- art: student", "- art: agent .claude/agents/my-art.md")
        agent = self.team.parent / ".claude" / "agents" / "my-art.md"
        agent.parent.mkdir(parents=True)
        agent.write_text("x\n", encoding="utf-8")
        rep = self.run_v()
        self.assertEqual(rep.agents, 3)
        self.assertEqual([m for m in rep.warnings if "does not exist" in m], [])
        agent.unlink()
        self.only(self.run_v(), "warnings", "other-roles.md: art names .claude/agents/my-art.md")

    def test_other_roles_invalid_value(self):
        self.edit("other-roles.md", "- art: ", "- art: maybe")
        self.only(self.run_v(), "errors", "other-roles.md: art must be")
        self.edit("other-roles.md", "- art: maybe", "- art: not needed,")
        self.only(self.run_v(), "errors", "other-roles.md: art must be")

    def test_floor_error_at_g4(self):
        fill_other(self.team)
        rep = self.run_v(date(2026, 12, 5))
        self.only(rep, "errors", "floor: 2 agents and 0 origin notes; G4 needs 3 and 1")
        self.assertEqual([m for m in rep.warnings if m.startswith("floor")], [])


    def test_role_without_line_warns_then_errors(self):
        self.edit("other-roles.md", "- art: \n", "")
        msg = "other-roles.md: art is not added and has no line here"
        self.only(self.run_v(), "warnings", msg)
        rep = self.run_v(date(2026, 12, 5))
        self.only(rep, "errors", msg)
        self.assertEqual([m for m in rep.warnings if msg in m], [])

    def test_unknown_id_in_other_roles_warns(self):
        fill_other(self.team)
        with open(self.team / "other-roles.md", "a", encoding="utf-8") as f:
            f.write("- wizard: student\n")
        for today in (date(2026, 11, 24), date(2026, 12, 5)):
            rep = self.run_v(today)
            self.only(rep, "warnings", "other-roles.md: 'wizard' is not a role id")
            self.assertEqual([m for m in rep.errors if "wizard" in m], [])

    def test_not_used_role_does_not_count_toward_floor(self):
        tmp, team, notes = make_team(add=["design"])
        self.addCleanup(tmp.cleanup)
        fill_other(team)
        with_links(notes["design"])
        self.assertEqual(validate.validate(team, date(2026, 12, 5)).agents, 3)
        role = team / "roles" / "design.md"
        role.write_text(role.read_text(encoding="utf-8").replace('not_used: ""', 'not_used: "rules fit in tech"', 1),
                        encoding="utf-8")
        rep = validate.validate(team, date(2026, 12, 5))
        self.assertEqual(rep.agents, 2)
        self.only(rep, "errors", "floor: 2 agents and 1 origin notes; G4 needs 3 and 1")

class CliTest(unittest.TestCase):
    def test_cli_exit_codes_and_summary(self):
        import os
        import sys
        tmp, team, _ = make_team()
        self.addCleanup(tmp.cleanup)
        cmd = [sys.executable, "-m", "team", "validate", "--today", "2026-11-24"]
        env = dict(os.environ, PYTHONPATH=str(Path(__file__).resolve().parent.parent))
        done = subprocess.run(cmd, cwd=str(team.parent), capture_output=True, text=True, env=env)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)
        self.assertEqual(done.stdout.splitlines()[-1], "agents=2 origin_notes=0")
        cmd[-1] = "2026-12-05"
        done = subprocess.run(cmd, cwd=str(team.parent), capture_output=True, text=True, env=env)
        self.assertEqual(done.returncode, 1)
        self.assertIn("floor:", done.stdout)


if __name__ == "__main__":
    unittest.main()


class ToolsRequiredTest(unittest.TestCase):
    def test_missing_or_empty_tools_is_error(self):
        tmp, team, _ = make_team()
        self.addCleanup(tmp.cleanup)
        role = team / "roles" / "tech.md"
        text = role.read_text(encoding="utf-8")
        for bad in ("  tools: []\n", ""):
            role.write_text(text.replace("  tools: [read, search, edit, write, shell]\n", bad), encoding="utf-8")
            rep = validate.validate(team, date(2026, 11, 24))
            self.assertTrue(any("roles/tech.md" in e and "permissions.tools" in e for e in rep.errors), rep.errors)
        role.write_text(text.replace("permissions:\n", "").replace("  tools: [read, search, edit, write, shell]\n", "")
                        .replace('  writes: "game code and tests, handoff notes"\n', ""), encoding="utf-8")
        rep = validate.validate(team, date(2026, 11, 24))
        self.assertTrue(any("permissions.tools" in e for e in rep.errors), rep.errors)

    def test_shipped_defaults_have_tools(self):
        tmp, team, _ = make_team()
        self.addCleanup(tmp.cleanup)
        rep = validate.validate(team, date(2026, 11, 24))
        self.assertFalse([e for e in rep.errors if "permissions.tools" in e])
