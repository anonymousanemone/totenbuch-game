import re
import unittest
from pathlib import Path

WORKFLOW = Path(__file__).resolve().parents[2] / ".github" / "workflows" / "final.yml"


class WorkflowTests(unittest.TestCase):
    """Safety properties of final.yml that hold whatever else you change in it."""

    def setUp(self):
        self.text = WORKFLOW.read_text(encoding="utf-8")

    def test_token_is_read_only(self):
        self.assertRegex(self.text, r"(?m)^permissions:\s*\n\s+contents: read\s*$")

    def test_checkout_keeps_no_credentials(self):
        self.assertIn("persist-credentials: false", self.text)

    def test_no_pull_request_target(self):
        self.assertNotIn("pull_request_target", self.text)

    def test_no_secrets(self):
        self.assertNotIn("secrets.", self.text)


if __name__ == "__main__":
    unittest.main()
