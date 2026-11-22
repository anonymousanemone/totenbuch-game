import json
import re
import unittest
from pathlib import Path

from team import fm, validate

DEFAULTS = Path(__file__).resolve().parent.parent / "team" / "defaults"
IDS = ["producer", "design", "tech", "art", "narrative", "qa", "bi", "release"]
BOUNDARY = ("You recommend; the student decides; the instructor approves gates. "
            "You never approve a gate, merge a pull request, or change a deadline.")


def load_roles():
    roles = {}
    for rid in IDS:
        path = DEFAULTS / "roles" / f"{rid}.md"
        meta, body = fm.parse(path.read_text(encoding="utf-8"), str(path))
        roles[rid] = (meta, body)
    return roles


def load_columns():
    return json.loads((DEFAULTS / "columns.json").read_text(encoding="utf-8"))["columns"]


class DefaultsTest(unittest.TestCase):
    def test_eight_roles_parse(self):
        roles = load_roles()
        self.assertEqual(len(roles), 8)
        for rid, (meta, _) in roles.items():
            self.assertEqual(meta["id"], rid)

    def test_all_columns_present(self):
        cols = [c["id"] for c in load_columns()]
        self.assertEqual(len(cols), 10)
        for rid, (meta, _) in load_roles().items():
            self.assertEqual(list(meta["lanes"]), cols, rid)

    def test_boundary_sentence(self):
        for rid, (_, body) in load_roles().items():
            self.assertIn(BOUNDARY, body, rid)
            self.assertTrue(body.rstrip().endswith(BOUNDARY), rid)

    def test_defaults_clean(self):
        cols = [c["id"] for c in load_columns()]
        people = json.loads((DEFAULTS / "people.json").read_text(encoding="utf-8"))
        kinds = {pid: p["kind"] for pid, p in people.items()}
        lanes = {}
        for rid, (meta, _) in load_roles().items():
            kinds[rid] = "agent"
            lanes[rid] = {c: {k: v for k, v in L.items()} for c, L in meta["lanes"].items()}
        for pid, p in people.items():
            lanes[pid] = p["lanes"]

        for rid, rl in lanes.items():
            self.assertEqual(set(rl), set(cols), rid)
            for c in cols:
                for f, _ in validate.pairs(rl[c], "expects", "from"):
                    self.assertIn(f, kinds, f)
                for t, _ in validate.pairs(rl[c], "delivers", "to"):
                    self.assertIn(t, kinds, t)
        probs = validate.handoff_problems(lanes, kinds, cols, set(IDS))
        self.assertEqual(probs, [])

    def test_columns_dates(self):
        data = json.loads((DEFAULTS / "columns.json").read_text(encoding="utf-8"))
        self.assertEqual(data["starts"], {
            "ideation": "2026-11-09", "G1": "2026-11-15", "prototype": "2026-11-17",
            "G2": "2026-11-28", "planning": "2026-11-29", "G3": "2026-11-30",
            "production": "2026-12-01", "G4": "2026-12-05", "release": "2026-12-08",
            "G5": "2026-12-14"})
        self.assertEqual(data["dates"], {"default_warning": "2026-11-30", "strict": "2026-12-05"})

    def test_qa_permissions(self):
        meta, _ = load_roles()["qa"]
        self.assertEqual(meta["permissions"]["tools"], ["read", "search", "shell"])
        self.assertEqual(meta["permissions"]["writes"], "tests and handoff notes")

    def test_qa_mentions_playwright(self):
        _, body = load_roles()["qa"]
        instructions = body.split("## Instructions", 1)[1]
        self.assertIn("Playwright", instructions)
        self.assertIn("scripted episode runs through the player interface", instructions)

    def test_origin_template_sections(self):
        text = (DEFAULTS / "origin-template.md").read_text(encoding="utf-8")
        meta, body = fm.parse(text)
        self.assertEqual(meta["kind"], "origin")
        heads = re.findall(r"^## (.+)$", body, re.M)
        self.assertEqual(heads, ["Why this agent", "Use", "Produce", "Accepted when",
                                 "Evidence", "Student decision"])

    def test_student_vocabulary(self):
        for rid, (meta, body) in load_roles().items():
            text = body.lower()
            for bad in ("crew", "hire", "—"):
                self.assertNotIn(bad, text, rid)


if __name__ == "__main__":
    unittest.main()
