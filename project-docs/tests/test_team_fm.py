import unittest

from team import fm

QA = '''---
id: qa
title: QA
gdf_role: QA
game: "Signal Station (example)"
permissions:
  tools: [read, search, shell]
  writes: "crew/handoffs/ only"
not_used: ""
slots:
  blocking:
    label: "What counts as a blocking bug"
    value: "A broken ending, leaked hidden state, lost progress, or a crash"
lanes:
  G4:
    does: "Run the release checks on the tagged candidate."
    expects:
      - from: release
        what: "tagged candidate and checklist"
    delivers:
      - to: student
        what: "release check results"
    recommends: "Release or hold, with the evidence."
---

# QA

## What this role does on a team
## Documents this role is known for
## Instructions
'''


class FrontmatterTests(unittest.TestCase):
    def test_round_trip_example(self):
        meta, body = fm.parse(QA)
        self.assertEqual(meta["lanes"]["G4"]["expects"][0]["from"], "release")
        self.assertTrue(body.startswith("# QA\n"))
        self.assertEqual(fm.dump(meta, body), QA)

    def test_crlf_accepted(self):
        meta, body = fm.parse(QA.replace("\n", "\r\n"))
        self.assertEqual(fm.dump(meta, body), QA)

    def test_unicode_quoted_value(self):
        meta, _ = fm.parse('---\ntitle: "Sénéchal"\n---\n\nbody\n')
        self.assertEqual(meta["title"], "Sénéchal")
        self.assertIn('title: "Sénéchal"', fm.dump(meta, "body\n"))

    def test_tab_rejected(self):
        with self.assertRaises(fm.FrontmatterError) as cm:
            fm.parse("---\na: b\n\tc: d\n---\n", source="x.md")
        self.assertEqual(cm.exception.line, 3)
        self.assertEqual(cm.exception.source, "x.md")
        self.assertTrue(str(cm.exception).startswith("x.md:3: "))

    def test_unquoted_colon_rejected(self):
        with self.assertRaises(fm.FrontmatterError) as cm:
            fm.parse("---\nwhat: tagged: candidate\n---\n")
        self.assertEqual(cm.exception.line, 2)

    def test_flow_list(self):
        meta, _ = fm.parse("---\ntools: [read, search]\n---\n")
        self.assertEqual(meta["tools"], ["read", "search"])

    def test_empty_list_and_string(self):
        meta, _ = fm.parse('---\nexpects: []\nnot_used: ""\n---\n')
        self.assertEqual(meta, {"expects": [], "not_used": ""})

    def test_missing_closing_fence(self):
        with self.assertRaises(fm.FrontmatterError):
            fm.parse("---\na: b\n")


if __name__ == "__main__":
    unittest.main()
