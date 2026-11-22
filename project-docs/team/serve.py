"""Serve the board on this computer and save role edits made in it."""

import json
import re
from datetime import date
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

from team import fm, render
from team.workspace import ROLE_IDS, team_dir

HOST = "127.0.0.1"
MAX_BODY = 256 * 1024
ROLE_PATH = re.compile(r"^/api/roles/([^/]*)$")


def _json(status, obj):
    return status, "application/json; charset=utf-8", (json.dumps(obj, indent=1) + "\n").encode("utf-8")


def _local_origin(headers, port):
    origin = headers.get("Origin")
    if origin is None:
        return True
    parts = urlsplit(origin)
    return parts.scheme == "http" and origin in (f"http://127.0.0.1:{port}", f"http://localhost:{port}")


MERGE_KEYS = ("game", "slots", "lanes")


def merge_role(old_text, sent_text, rid):
    """Return old_text with only the game, slots, and lanes blocks taken from sent_text.

    Every other line of the old frontmatter and the whole old body stay as they were.
    Raises ValueError with a student-readable reason when the sent text is unusable.
    """
    try:
        sent, _ = fm.parse(sent_text, "the saved role")
    except fm.FrontmatterError as e:
        raise ValueError(str(e)) from None
    if sent.get("id", rid) != rid:
        raise ValueError(f"the saved role has id '{sent.get('id')}', but you are saving '{rid}'")
    if "game" in sent and not isinstance(sent["game"], str):
        raise ValueError("game must be text")
    for key in ("slots", "lanes"):
        if key in sent and not isinstance(sent[key], dict):
            raise ValueError(f"{key} must be a map")
    take = {k: sent[k] for k in MERGE_KEYS if k in sent and sent[k] != {}}
    text = old_text.replace("\r\n", "\n")
    if not text.startswith("---\n"):
        raise ValueError("the existing role file has no frontmatter")
    lines = text.split("\n")
    end = next((i for i in range(1, len(lines)) if lines[i] == "---"), None)
    if end is None:
        raise ValueError("the existing role file has no closing ---")
    head = lines[1:end]
    for key, value in take.items():
        out = []
        fm._emit({key: value}, 0, out)
        start = next((i for i, ln in enumerate(head) if ln.startswith(f"{key}:")), None)
        if start is None:
            head += out
            continue
        stop = start + 1
        while stop < len(head) and (not head[stop] or head[stop][0] in " -#"):
            stop += 1
        head[start:stop] = out
    return "\n".join(["---"] + head + lines[end:])


def make_handler(root, port=8765):
    """Return handle(method, path, body, headers) -> (status, content type, bytes)."""
    root = Path(root).resolve()
    team = team_dir(root)

    def role_ids():
        roles = team / "roles"
        return {p.stem for p in roles.glob("*.md")} & set(ROLE_IDS) if roles.is_dir() else set()

    def put_role(rid, body):
        target = team / "roles" / f"{rid}.md"
        try:
            render._check_inside(root, target)
        except render.RenderRefused as e:
            return _json(422, {"errors": e.errors})
        try:
            text = body.decode("utf-8")
        except UnicodeDecodeError:
            return _json(400, {"errors": ["The role file must be UTF-8 text."]})
        old = target.read_bytes()
        try:
            merged = merge_role(old.decode("utf-8"), text, rid)
        except (ValueError, TypeError) as e:
            return _json(422, {"errors": [f"roles/{rid}.md: {e}"]})
        target.write_bytes(merged.encode("utf-8"))
        try:
            render.render(root, date.today())
        except render.RenderRefused as e:
            target.write_bytes(old)
            return _json(422, {"errors": e.errors})
        except BaseException:
            target.write_bytes(old)
            raise
        return 200, "application/json; charset=utf-8", (team / "team.json").read_bytes()

    def handle(method, path, body=b"", headers=None):
        headers = headers or {}
        if headers.get("Host") not in (f"127.0.0.1:{port}", f"localhost:{port}"):
            return _json(403, {"errors": ["Requests must use 127.0.0.1 or localhost with this server's port."]})
        raw = path.split("?", 1)[0].split("#", 1)[0]
        m = ROLE_PATH.match(raw)
        if m:
            rid = unquote(m.group(1))
            if rid not in role_ids():
                return _json(404, {"errors": ["No such role."]})
            if method != "PUT":
                return _json(405, {"errors": ["Roles are saved with PUT."]})
            if not _local_origin(headers, port):
                return _json(403, {"errors": ["Requests must come from this computer."]})
            try:
                length = int(headers.get("Content-Length", len(body)))
            except ValueError:
                return _json(400, {"errors": ["Bad Content-Length."]})
            if length > MAX_BODY or len(body) > MAX_BODY:
                return _json(413, {"errors": [f"A role file is at most {MAX_BODY // 1024} KiB."]})
            return put_role(rid, body)
        if raw == "/":
            if method != "GET":
                return _json(405, {"errors": ["Only GET is allowed here."]})
            board = team / "board.html"
            if not board.is_file() or board.is_symlink():
                return _json(404, {"errors": ["No board yet; run python -m team render."]})
            return 200, "text/html; charset=utf-8", board.read_bytes()
        return _json(404, {"errors": ["Not found."]})

    return handle


REQUEST_TIMEOUT = 15


def handler_class(handle):
    """The request handler for serve: one request per connection, 15 seconds to send it."""

    class Handler(BaseHTTPRequestHandler):
        timeout = REQUEST_TIMEOUT

        def _go(self):
            try:
                length = int(self.headers.get("Content-Length") or 0)
            except ValueError:
                length = 0
            body = b""
            if self.command == "PUT" and 0 <= length <= MAX_BODY:
                try:
                    body = self.rfile.read(length)
                except OSError:
                    self.close_connection = True
                    return
            status, ctype, out = handle(self.command, self.path, body, self.headers)
            self.send_response(status)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(out)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(out)

        do_GET = do_PUT = do_POST = do_DELETE = do_PATCH = _go

        def log_message(self, *args):
            pass

    return Handler


def serve(root, port=8765, today=None):
    """Serve the board until Ctrl+C. Returns the exit code."""
    root = Path(root)
    if not (team_dir(root) / "team.json").is_file():
        try:
            render.render(root, today or date.today())
        except render.RenderRefused as e:
            for line in e.errors:
                print(line)
            print("Fix the errors above, then run python -m team serve again.")
            return 1
    handle = make_handler(root, port)
    try:
        server = HTTPServer((HOST, port), handler_class(handle))
    except OSError as e:
        print(f"Cannot listen on {HOST}:{port} ({e.strerror or e}); choose another port with --port, "
              f"for example python -m team serve --port {port + 1}.")
        return 1
    print(f"Board at http://{HOST}:{port}/ (Ctrl+C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0
