#!/usr/bin/env python3
"""Read-only local file server so Notion links can open the author's reference files in Chrome.

Notion ignores totenbuch:// and file:// links but follows http links, so a link such as
  http://localhost:8765/bod/davis1894_bookofdead.pdf#page=12
opens the PDF in a new browser tab. Two folders are served, nothing else:
  /open/<path>  the repo (the folder two levels above this script)
  /bod/<path>   ~/dcmt_tmp/Readings/BookoftheDead
Listens on 127.0.0.1 only, answers only GET and HEAD, refuses any other Host header
(against DNS rebinding), sends no CORS headers, and never lists a folder.
Usage: python3 serve.py   (stop with Ctrl-C)
"""
import mimetypes
import os
import re
import sys
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8765
REPO = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
BOD = os.path.realpath(os.path.expanduser("~/dcmt_tmp/Readings/BookoftheDead"))
ROOTS = {"open": REPO, "bod": BOD}
HOSTS = {f"localhost:{PORT}", f"127.0.0.1:{PORT}"}
CHUNK = 1 << 20


class Handler(BaseHTTPRequestHandler):
    server_version = "TotenbuchFiles/1"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s\n" % (fmt % args))

    def _resolve(self):
        path = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path)
        parts = path.lstrip("/").split("/", 1)
        if len(parts) != 2 or parts[0] not in ROOTS or not parts[1]:
            return None
        root = ROOTS[parts[0]]
        full = os.path.realpath(os.path.join(root, parts[1]))
        if not full.startswith(root + os.sep) or not os.path.isfile(full):
            return None
        return full

    def _send(self, code, body=b"", ctype="text/plain; charset=utf-8", extra=None, head=False):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        if not head and body:
            self.wfile.write(body)

    def _serve(self, head):
        if self.headers.get("Host", "") not in HOSTS:
            return self._send(403, b"Forbidden", head=head)
        full = self._resolve()
        if full is None:
            return self._send(404, b"Not found", head=head)
        size = os.path.getsize(full)
        ctype = mimetypes.guess_type(full)[0] or "application/octet-stream"
        if ctype.startswith("text/"):
            ctype += "; charset=utf-8"
        start, end, code = 0, size - 1, 200
        rng = self.headers.get("Range", "")
        m = re.fullmatch(r"bytes=(\d*)-(\d*)", rng.strip())
        if m and (m.group(1) or m.group(2)):
            if m.group(1):
                start = int(m.group(1))
                end = int(m.group(2)) if m.group(2) else size - 1
            else:
                start = max(0, size - int(m.group(2)))
            end = min(end, size - 1)
            if start > end or start >= size:
                return self._send(416, b"", extra={"Content-Range": f"bytes */{size}"}, head=head)
            code = 206
        length = end - start + 1
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(length))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Disposition", "inline")
        if code == 206:
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.end_headers()
        if head:
            return
        try:
            with open(full, "rb") as f:
                f.seek(start)
                left = length
                while left > 0:
                    data = f.read(min(CHUNK, left))
                    if not data:
                        break
                    self.wfile.write(data)
                    left -= len(data)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        self._serve(False)

    def do_HEAD(self):
        self._serve(True)

    def _refuse(self):
        self._send(405, b"Read-only", extra={"Allow": "GET, HEAD"})

    do_POST = do_PUT = do_DELETE = do_PATCH = do_OPTIONS = _refuse


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
