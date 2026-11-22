"""Parser and writer for the restricted YAML frontmatter subset used by role files.

Grammar: two-space indentation, maps, lists of maps, ``[]`` and flow lists of
bare words, and scalars that are bare words or double-quoted JSON strings.
"""

import json
import re

BARE = re.compile(r"^[A-Za-z0-9_./+-]+$")
KEY = re.compile(r"^([A-Za-z0-9_-]+):(?: (.*))?$")
RESERVED = {"true", "false", "null"}


class FrontmatterError(ValueError):
    def __init__(self, source, line, reason):
        super().__init__(f"{source}:{line}: {reason}")
        self.source = source
        self.line = line


def parse(text, source="<text>"):
    text = text.replace("\r\n", "\n")
    if not text.startswith("---\n"):
        raise FrontmatterError(source, 1, "file must start with ---")
    raw = text.split("\n")
    end = next((i for i in range(1, len(raw)) if raw[i] == "---"), None)
    if end is None:
        raise FrontmatterError(source, 1, "no closing --- line")
    lines = []
    for i in range(1, end):
        line = raw[i]
        if "\t" in line:
            raise FrontmatterError(source, i + 1, "tab in frontmatter; use two spaces")
        stripped = line.lstrip(" ")
        if not stripped.strip() or stripped.startswith("#"):
            continue
        lines.append((len(line) - len(stripped), stripped.rstrip(), i + 1))
    body = "\n".join(raw[end + 1:])
    if body.startswith("\n"):
        body = body[1:]
    if not lines:
        return {}, body
    if lines[0][0] != 0:
        raise FrontmatterError(source, lines[0][2], "frontmatter must start at column 0")
    value, pos = _block(lines, 0, 0, source)
    if pos < len(lines):
        raise FrontmatterError(source, lines[pos][2], "unexpected indentation")
    if not isinstance(value, dict):
        raise FrontmatterError(source, lines[0][2], "frontmatter must be a map")
    return value, body


def _scalar(s, lineno, source):
    if s.startswith('"'):
        try:
            value = json.loads(s)
        except ValueError:
            raise FrontmatterError(source, lineno, f"bad quoted string: {s}") from None
        if not isinstance(value, str):
            raise FrontmatterError(source, lineno, f"bad quoted string: {s}")
        return value
    if BARE.match(s):
        return s
    raise FrontmatterError(source, lineno, f"value must be a bare word or a double-quoted string: {s}")


def _value(s, lineno, source):
    if s.startswith("["):
        if not s.endswith("]"):
            raise FrontmatterError(source, lineno, "unterminated flow list")
        inner = s[1:-1].strip()
        if not inner:
            return []
        items = []
        for part in inner.split(","):
            part = part.strip()
            if not BARE.match(part):
                raise FrontmatterError(source, lineno, f"flow list items must be bare words: {part!r}")
            items.append(part)
        return items
    return _scalar(s, lineno, source)


def _block(lines, i, indent, source):
    if indent % 2:
        raise FrontmatterError(source, lines[i][2], "indentation must be two spaces per level")
    if lines[i][1].startswith("- ") or lines[i][1] == "-":
        return _list(lines, i, indent, source)
    return _map(lines, i, indent, source)


def _map(lines, i, indent, source):
    result = {}
    while i < len(lines) and lines[i][0] == indent:
        _, text, lineno = lines[i]
        m = KEY.match(text)
        if not m:
            raise FrontmatterError(source, lineno, f"expected 'key: value', got: {text}")
        key, rest = m.group(1), m.group(2)
        if key in result:
            raise FrontmatterError(source, lineno, f"duplicate key: {key}")
        i += 1
        if rest is None or rest == "":
            if i >= len(lines) or lines[i][0] <= indent:
                raise FrontmatterError(source, lineno, f"key {key!r} has no value or nested block")
            if lines[i][0] != indent + 2:
                raise FrontmatterError(source, lines[i][2], "indentation must be two spaces per level")
            result[key], i = _block(lines, i, indent + 2, source)
        else:
            result[key] = _value(rest, lineno, source)
    if i < len(lines) and lines[i][0] > indent:
        raise FrontmatterError(source, lines[i][2], "unexpected indentation")
    return result, i


def _list(lines, i, indent, source):
    result = []
    while i < len(lines) and lines[i][0] == indent and (lines[i][1].startswith("- ") or lines[i][1] == "-"):
        _, text, lineno = lines[i]
        rest = text[2:].strip()
        if not rest:
            raise FrontmatterError(source, lineno, "empty list item")
        if KEY.match(rest):
            lines[i] = (indent + 2, rest, lineno)
            item, i = _map(lines, i, indent + 2, source)
        else:
            item = _value(rest, lineno, source)
            i += 1
        result.append(item)
    if i < len(lines) and lines[i][0] > indent:
        raise FrontmatterError(source, lines[i][2], "unexpected indentation")
    return result, i


def _fmt(s):
    if isinstance(s, str) and BARE.match(s) and s not in RESERVED:
        return s
    if not isinstance(s, str):
        raise TypeError(f"frontmatter scalars must be strings, got {type(s).__name__}")
    return json.dumps(s, ensure_ascii=False)


def _is_bare(s):
    return isinstance(s, str) and BARE.match(s) is not None and s not in RESERVED


def _emit(value, indent, out):
    pad = "  " * indent
    for key, v in value.items():
        if isinstance(v, dict):
            if not v:
                raise ValueError(f"empty map for key {key!r} cannot be written")
            out.append(f"{pad}{key}:")
            _emit(v, indent + 1, out)
        elif isinstance(v, list):
            if not v:
                out.append(f"{pad}{key}: []")
            elif all(_is_bare(x) for x in v):
                out.append(f"{pad}{key}: [{', '.join(v)}]")
            else:
                out.append(f"{pad}{key}:")
                _emit_list(v, indent + 1, out)
        else:
            out.append(f"{pad}{key}: {_fmt(v)}")


def _emit_list(items, indent, out):
    pad = "  " * indent
    for item in items:
        if isinstance(item, dict):
            if not item:
                raise ValueError("empty map in list cannot be written")
            sub = []
            _emit(item, indent + 1, sub)
            out.append(f"{pad}- {sub[0].lstrip(' ')}")
            out.extend(sub[1:])
        elif isinstance(item, list):
            raise TypeError("nested lists are not supported")
        else:
            out.append(f"{pad}- {_fmt(item)}")


def dump(meta, body):
    out = []
    _emit(meta, 0, out)
    head = "---\n" + "".join(line + "\n" for line in out) + "---\n"
    return head + ("\n" + body if body else "")
