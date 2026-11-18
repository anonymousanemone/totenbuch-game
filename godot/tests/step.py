#!/usr/bin/env python3
"""Client for the playtest step driver (godot/tests/step_driver.gd): one action per call.

  step.py start [--level=KEY] [--view] [--fresh] [--size=WxH] [--port=N] [--out=DIR] [--godot=PATH]
  step.py look | wait SECONDS | move X Y | click X Y [right] | drag X1 Y1 X2 Y2 [SECONDS]
  step.py key NAME [SECONDS]          (enter, space, escape, j, left, right, up, down, shift ...)
  step.py stop

Add --port=N before the command to talk to a driver on another port. Every command but `start` and
`stop` prints the reply as one JSON line: the frame's file, the band's line with when it appeared and
cleared, the clock and what can be clicked. Coordinates are those of the frame (1280 x 720 by default).
Add settle=SECONDS to an action to change how long its effect plays out before the reply.
"""

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

DEFAULT_PORT = 17777
PROJECT = Path(__file__).resolve().parents[1]


def find_godot(explicit):
    for candidate in (explicit, os.environ.get("GODOT"), shutil.which("godot"), shutil.which("godot4"),
                      "/Applications/Godot.app/Contents/MacOS/Godot"):
        if candidate and Path(candidate).exists():
            return candidate
    sys.exit("Godot was not found; pass --godot=PATH or set GODOT")


def send(port, command, timeout=300):
    with socket.create_connection(("127.0.0.1", port), timeout=timeout) as s:
        s.sendall((json.dumps(command) + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                break
            data += chunk
    return json.loads(data.decode())


def start(flags):
    port, out, godot, game_flags = DEFAULT_PORT, None, None, []
    for flag in flags:
        if flag.startswith("--port="):
            port = int(flag.split("=", 1)[1])
        elif flag.startswith("--out="):
            out = flag.split("=", 1)[1]
        elif flag.startswith("--godot="):
            godot = flag.split("=", 1)[1]
        else:
            game_flags.append(flag)
    out = out or str(Path(tempfile.gettempdir()) / f"totenbuch-step-{port}")
    Path(out).mkdir(parents=True, exist_ok=True)
    command = [find_godot(godot), "--path", str(PROJECT), "--fixed-fps", "60",
               "--script", "res://tests/step_driver.gd", "--", f"--port={port}", f"--out={out}", *game_flags]
    log = open(Path(out) / "godot.log", "w")
    process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    for _ in range(240):
        if process.poll() is not None:
            sys.exit(f"the game exited early; see {out}/godot.log")
        try:
            socket.create_connection(("127.0.0.1", port), timeout=10).close()   # sends nothing: only checks it is up
            break
        except OSError:
            time.sleep(0.25)
    else:
        sys.exit(f"the driver did not come up on port {port}; see {out}/godot.log")
    print(json.dumps({"ok": True, "port": port, "out": out}))


def main(argv):
    port = DEFAULT_PORT
    while argv and argv[0].startswith("--port="):
        port = int(argv.pop(0).split("=", 1)[1])
    if not argv:
        sys.exit(__doc__)
    name, rest = argv[0], argv[1:]
    if name == "start":
        return start(rest)
    settle = None
    for item in list(rest):
        if item.startswith("settle="):
            settle = float(item.split("=", 1)[1])
            rest.remove(item)
    if name in ("look", "stop"):
        command = {"cmd": "look" if name == "look" else "quit"}
    elif name == "wait":
        command = {"cmd": "wait", "seconds": float(rest[0])}
    elif name == "move":
        command = {"cmd": "move", "x": float(rest[0]), "y": float(rest[1])}
    elif name == "click":
        command = {"cmd": "click", "x": float(rest[0]), "y": float(rest[1])}
        if len(rest) > 2 and rest[2] == "right":
            command["button"] = "right"
    elif name == "drag":
        command = {"cmd": "drag", "x1": float(rest[0]), "y1": float(rest[1]),
                   "x2": float(rest[2]), "y2": float(rest[3])}
        if len(rest) > 4:
            command["seconds"] = float(rest[4])
    elif name == "key":
        command = {"cmd": "key", "key": rest[0]}
        if len(rest) > 1:
            command["seconds"] = float(rest[1])
    else:
        sys.exit(__doc__)
    if settle is not None:
        command["settle"] = settle
    reply = send(port, command)
    print(json.dumps(reply, ensure_ascii=False))
    return 0 if reply.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
