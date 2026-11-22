import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from team import render, serve, workspace
from tests.test_team_validate import fill_other, make_team

HOST = "127.0.0.1:8765"
H = {"Host": HOST}
REPO = Path(__file__).resolve().parent.parent


class ServeTests(unittest.TestCase):
    def setUp(self):
        self.tmp, self.team, _ = make_team()
        self.root = self.team.parent
        self.addCleanup(self.tmp.cleanup)
        fill_other(self.team)
        self.role = self.team / "roles" / "tech.md"
        self.handle = serve.make_handler(self.root)

    def put(self, path, body):
        return self.handle("PUT", path, body, {"Host": HOST, "Content-Length": str(len(body))})

    def test_put_valid_writes(self):
        text = self.role.read_text(encoding="utf-8").replace("Flag the technical risk in each concept.", "Flag risk early.", 1)
        status, _, out = self.put("/api/roles/tech", text.encode("utf-8"))
        self.assertEqual(status, 200, out)
        self.assertEqual(self.role.read_text(encoding="utf-8"), text)
        self.assertIn("tech", json.loads(out)["roles"])
        self.assertIn("Flag risk early.", (self.root / ".claude" / "agents" / "team-tech.md").read_text(encoding="utf-8"))

    def test_put_merges_lanes_and_slots_only(self):
        from team import fm
        old = self.role.read_text(encoding="utf-8")
        meta, body = fm.parse(old)
        sent = {"id": "tech", "title": meta["title"], "game": "New Game", "slots": meta["slots"],
                "lanes": json.loads(json.dumps(meta["lanes"]))}
        sent["lanes"]["ideation"]["does"] = "Changed in the board."
        sent["lanes"]["ideation"]["delivers"][0]["to"] = "producer"
        text = fm.dump(sent, "# Generic\n\nA different body.\n")
        status, _, out = self.put("/api/roles/tech", text.encode("utf-8"))
        self.assertEqual(status, 200, out)
        new = self.role.read_text(encoding="utf-8")
        nmeta, nbody = fm.parse(new)
        self.assertEqual(nbody, body)
        self.assertEqual(nmeta["permissions"], meta["permissions"])
        self.assertEqual(nmeta["subtitle"], meta["subtitle"])
        self.assertEqual(nmeta["not_used"], meta["not_used"])
        self.assertEqual(nmeta["lanes"]["ideation"]["does"], "Changed in the board.")
        self.assertEqual(nmeta["game"], "New Game")
        self.assertEqual(nmeta["lanes"]["G1"], meta["lanes"]["G1"])
        tools = (self.root / ".claude" / "agents" / "team-tech.md").read_text(encoding="utf-8")
        self.assertIn("tools: ", tools)
        self.assertNotIn('tools: ""', tools)
        # lines outside the replaced blocks are untouched
        for line in old.split("\n"):
            if line.startswith(("subtitle:", "gdf_role:", "not_used:", "  tools:", "  writes:")):
                self.assertIn(line, new.split("\n"))

    def test_put_wrong_id_422(self):
        before = self.role.read_bytes()
        text = self.role.read_text(encoding="utf-8").replace("id: tech", "id: qa", 1)
        self.assertEqual(self.put("/api/roles/tech", text.encode("utf-8"))[0], 422)
        self.assertEqual(self.role.read_bytes(), before)

    def test_put_invalid_leaves_file(self):
        before = self.role.read_bytes()
        status, _, out = self.put("/api/roles/tech", b"not a role file\n")
        self.assertEqual(status, 422)
        self.assertTrue(json.loads(out)["errors"])
        self.assertEqual(self.role.read_bytes(), before)

    def test_put_role_not_added_404(self):
        status, _, _ = self.put("/api/roles/design", self.role.read_bytes())
        self.assertEqual(status, 404)
        self.assertFalse((self.team / "roles" / "design.md").exists())

    def test_path_escape_404(self):
        for path in ["/api/roles/../x", "/../.git/config", "/api/roles/%2e%2e",
                     "/api/roles/%2e%2e%2ftech", "/api/roles/tech/../qa", "/api/roles/%252e%252e"]:
            self.assertEqual(self.put(path, b"x")[0], 404, path)
        self.assertEqual(self.handle("GET", "/../.git/config", b"", H)[0], 404)

    def test_non_put_rejected(self):
        for method in ["POST", "DELETE", "PATCH", "GET"]:
            self.assertEqual(self.handle(method, "/api/roles/tech", b"x", H)[0], 405, method)
        self.assertEqual(self.handle("POST", "/", b"", H)[0], 405)

    def test_oversize_413(self):
        before = self.role.read_bytes()
        status, _, _ = self.handle("PUT", "/api/roles/tech", b"", {"Host": HOST, "Content-Length": str(300 * 1024)})
        self.assertEqual(status, 413)
        status, _, _ = self.put("/api/roles/tech", b"x" * (256 * 1024 + 1))
        self.assertEqual(status, 413)
        self.assertEqual(self.role.read_bytes(), before)

    def test_foreign_origin_refused(self):
        status, _, _ = self.handle("PUT", "/api/roles/tech", self.role.read_bytes(),
                                   {"Host": HOST, "Origin": "https://evil.example"})
        self.assertEqual(status, 403)

    def test_foreign_host_403_everywhere(self):
        body = self.role.read_bytes()
        for host in ["evil.example", "evil.example:8765", "127.0.0.1", "127.0.0.1:9999", "localhost:1", None]:
            hdr = {} if host is None else {"Host": host}
            for method, path in [("GET", "/"), ("PUT", "/api/roles/tech"), ("GET", "/nope")]:
                self.assertEqual(self.handle(method, path, body, hdr)[0], 403, (host, path))
        self.assertEqual(self.handle("GET", "/nope", b"", {"Host": "localhost:8765"})[0], 404)

    def test_wrong_port_origin_403(self):
        body = self.role.read_bytes()
        for origin in ["http://127.0.0.1:9999", "http://localhost", "https://127.0.0.1:8765", "null"]:
            status, _, _ = self.handle("PUT", "/api/roles/tech", body, {"Host": HOST, "Origin": origin})
            self.assertEqual(status, 403, origin)
        status, _, _ = self.handle("PUT", "/api/roles/tech", body, {"Host": HOST, "Origin": "http://localhost:8765"})
        self.assertEqual(status, 200)

    def test_symlinked_role_refused(self):
        other = self.root / "elsewhere.md"
        other.write_bytes(b"keep")
        self.role.unlink()
        self.role.symlink_to(other)
        status, _, _ = self.put("/api/roles/tech", b"x")
        self.assertIn(status, (404, 422))
        self.assertEqual(other.read_bytes(), b"keep")

    def test_get_board(self):
        self.assertEqual(self.handle("GET", "/", b"", H)[0], 404)
        render.render(self.root, __import__("datetime").date(2026, 11, 24))
        status, ctype, body = self.handle("GET", "/", b"", H)
        self.assertEqual(status, 200)
        self.assertIn("text/html", ctype)

    def test_binds_loopback(self):
        self.assertEqual(serve.HOST, "127.0.0.1")


class ServeStartTests(unittest.TestCase):
    def setUp(self):
        self.tmp, self.team, _ = make_team()
        self.root = self.team.parent
        self.addCleanup(self.tmp.cleanup)
        fill_other(self.team)

    def test_request_timeout(self):
        cls = serve.handler_class(serve.make_handler(self.root))
        self.assertEqual(cls.timeout, 15)

    def test_busy_port_one_line_and_renders_first(self):
        import io
        from contextlib import redirect_stdout
        from unittest import mock
        self.assertFalse((self.team / "team.json").exists())
        out = io.StringIO()
        with mock.patch("team.serve.HTTPServer", side_effect=OSError(48, "Address already in use")), \
                redirect_stdout(out):
            code = serve.serve(self.root, 8765)
        self.assertEqual(code, 1)
        self.assertTrue((self.team / "team.json").is_file())
        lines = [ln for ln in out.getvalue().splitlines() if "8765" in ln]
        self.assertEqual(len(lines), 1, out.getvalue())
        self.assertIn("--port", lines[0])

class NoTeamTests(unittest.TestCase):
    def test_no_agent_team_exits_zero(self):
        with tempfile.TemporaryDirectory() as d:
            subprocess.run(["git", "init", "-q", d], check=True)
            for cmd in (["validate"], ["render"], ["render", "--today", "from-team-json"]):
                done = subprocess.run([sys.executable, "-m", "team", *cmd], cwd=d, capture_output=True,
                                      text=True, env={"PYTHONPATH": str(REPO), "PATH": "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"})
                self.assertEqual(done.returncode, 0, done.stdout + done.stderr)
                self.assertIn("no agent-team/ yet; run python -m team init", done.stdout)
