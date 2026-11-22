import html as htmllib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

from team import fm, render, workspace
from team.status import status
from tests.test_team_validate import fill_other, make_team

TODAY = date(2026, 11, 24)
REPO = Path(__file__).resolve().parent.parent
GIT_ENV = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.com",
           "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.com"}


def git(root, *args, when=None):
    env = dict(os.environ, **GIT_ENV)
    if when:
        env["GIT_AUTHOR_DATE"] = env["GIT_COMMITTER_DATE"] = when
    subprocess.run(["git", *args], cwd=str(root), check=True, capture_output=True, env=env)


class RenderTests(unittest.TestCase):
    def setUp(self):
        self.tmp, self.team, self.notes = make_team(add=("design",))
        self.root = self.team.parent
        self.addCleanup(self.tmp.cleanup)

    def test_render_twice_identical(self):
        first = render.render(self.root, TODAY)
        before = {p: p.read_bytes() for p in first}
        second = render.render(self.root, TODAY)
        self.assertEqual(first, second)
        self.assertEqual(first, sorted(first))
        self.assertEqual(before, {p: p.read_bytes() for p in second})
        for b in before.values():
            self.assertNotIn(b"\r", b)
            self.assertTrue(b.endswith(b"\n"))

    def test_coverage_map_lists_all_eight(self):
        render.render(self.root, TODAY)
        text = (self.team / "coverage-map.md").read_text(encoding="utf-8")
        rows = [ln for ln in text.splitlines() if ln.startswith("| ") and not ln.startswith("| Role")]
        self.assertEqual([r.split(" | ")[0][2:] for r in rows], workspace.ROLE_IDS)
        self.assertIn("Agents: 3 of 3 by G4. Origin notes: 1 of 1 by G4.", text)
        self.assertNotIn("—", text)

    def test_others_from_other_roles(self):
        (self.team / "other-roles.md").write_text(
            "# Roles not added\n- producer: student\n- art: not needed, no art\n- narrative: \n"
            "- qa:\n- bi: student\n- release: student\n", encoding="utf-8")
        render.render(self.root, TODAY)
        data = json.loads((self.team / "team.json").read_text(encoding="utf-8"))
        cov = {o["id"]: o["covered_by"] for o in data["others"]}
        self.assertEqual(cov["art"], "not needed, no art")
        self.assertEqual(cov["producer"], "student")
        self.assertEqual(set(data["roles"]), {"student", "instructor", "design", "tech", "qa"})
        self.assertEqual(data["roles"]["qa"]["worked"], True)
        self.assertEqual(data["roles"]["qa"]["lanes"]["G1"]["expects"], [["design", "core loop"]])
        self.assertEqual(data["status"]["qa"], "default")
        self.assertTrue(any(n["kind"] == "origin" and n["to"] == "design" and not n["routed"]
                            for n in data["notes"]))

    def test_claude_tools_mapping(self):
        render.render(self.root, TODAY)
        meta, body = fm.parse((self.team.parent / ".claude/agents/team-qa.md").read_text(encoding="utf-8"))
        self.assertEqual(meta["tools"], "Read, Grep, Glob, Bash")
        self.assertEqual(meta["name"], "team-qa")
        self.assertIn("Current phase: ", meta["description"])
        self.assertIn("## Lanes by column", body)
        skill = (self.team.parent / ".agents/skills/team-qa/SKILL.md").read_text(encoding="utf-8")
        self.assertIn("Use only these tools: Read, Grep, Glob, Bash.", skill)

    def test_skill_name_and_description_limits(self):
        render.render(self.root, TODAY)
        for sk in (self.team.parent / ".agents/skills").glob("team-*/SKILL.md"):
            meta, _ = fm.parse(sk.read_text(encoding="utf-8"))
            self.assertLessEqual(len(meta["name"]), 64)
            self.assertLessEqual(len(meta["description"]), 1024)

    def test_stale_files_removed_and_others_kept(self):
        render.render(self.root, TODAY)
        keep = self.team.parent / ".claude/agents/mine.md"
        keep.write_text("x", encoding="utf-8")
        (self.team / "roles" / "design.md").unlink()
        render.render(self.root, TODAY)
        self.assertFalse((self.team.parent / ".claude/agents/team-design.md").exists())
        self.assertFalse((self.team.parent / ".agents/skills/team-design").exists())
        self.assertTrue(keep.exists())
        self.assertTrue((self.team.parent / ".claude/agents/team-qa.md").exists())

    def test_status_default_tailored_not_used(self):
        qa = self.team / "roles" / "qa.md"
        default = workspace.DEFAULTS / "roles" / "qa.md"
        self.assertEqual(status(qa, default, self.root), "default")
        text = qa.read_text(encoding="utf-8")
        qa.write_text(text.replace("Blocker, major, minor, cosmetic", "Red, amber, green"), encoding="utf-8")
        self.assertEqual(status(qa, default, self.root), "tailored")
        qa.write_text(qa.read_text(encoding="utf-8").replace('not_used: ""', 'not_used: "no tests needed"'),
                      encoding="utf-8")
        self.assertEqual(status(qa, default, self.root), "not used")

    def test_status_revised_from_git(self):
        qa = self.team / "roles" / "qa.md"
        default = workspace.DEFAULTS / "roles" / "qa.md"
        qa.write_text(qa.read_text(encoding="utf-8").replace("Blocker, major, minor, cosmetic", "Red, amber"),
                      encoding="utf-8")
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", "start", when="2026-11-20T10:00:00")
        note = self.team / "handoffs" / "2026-11-22-qa-to-tech.md"
        note.write_text("---\nfrom: qa\nto: tech\ncolumn: prototype\nkind: handoff\ndate: 2026-11-22\n---\n"
                        "## Use\nx\n", encoding="utf-8")
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", "note", when="2026-11-22T10:00:00")
        self.assertEqual(status(qa, default, self.root), "tailored")
        qa.write_text(qa.read_text(encoding="utf-8").replace("Red, amber", "Red, amber, green"), encoding="utf-8")
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", "edit", when="2026-11-23T10:00:00")
        self.assertEqual(status(qa, default, self.root), "revised")

    def test_status_without_commits_does_not_fail(self):
        qa = self.team / "roles" / "qa.md"
        qa.write_text(qa.read_text(encoding="utf-8").replace("Blocker, major, minor, cosmetic", "Red"),
                      encoding="utf-8")
        self.assertEqual(status(qa, workspace.DEFAULTS / "roles" / "qa.md", self.root), "tailored")

    def test_render_refuses_on_error(self):
        qa = self.team / "roles" / "qa.md"
        qa.write_text(qa.read_text(encoding="utf-8").replace("id: qa", "id: tech"), encoding="utf-8")
        with self.assertRaises(render.RenderRefused) as cm:
            render.render(self.root, TODAY)
        self.assertTrue(cm.exception.errors)
        self.assertFalse((self.team / "team.json").exists())

    def _outside(self):
        import tempfile
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        return Path(d.name).resolve()

    def test_symlinked_agents_dir_refused(self):
        out = self._outside()
        base = self.team.parent
        (base / ".claude").mkdir()
        (base / ".claude" / "agents").symlink_to(out, target_is_directory=True)
        with self.assertRaises(render.RenderRefused) as cm:
            render.render(self.root, TODAY)
        self.assertEqual(len(cm.exception.errors), 1)
        self.assertIn(".claude", cm.exception.errors[0])
        self.assertEqual(list(out.iterdir()), [])
        self.assertFalse((self.team / "team.json").exists())

    def test_symlinked_target_file_refused(self):
        out = self._outside()
        victim = out / "victim.txt"
        victim.write_text("keep", encoding="utf-8")
        (self.team / "coverage-map.md").symlink_to(victim)
        with self.assertRaises(render.RenderRefused) as cm:
            render.render(self.root, TODAY)
        self.assertIn("coverage-map.md", cm.exception.errors[0])
        self.assertEqual(victim.read_text(encoding="utf-8"), "keep")
        self.assertFalse((self.team / "team.json").exists())

    def test_stale_cleanup_ignores_symlink(self):
        out = self._outside()
        (out / "precious.txt").write_text("keep", encoding="utf-8")
        agents = self.team.parent / ".claude" / "agents"
        agents.mkdir(parents=True)
        (agents / "team-old.md").symlink_to(out / "precious.txt")
        skills = self.team.parent / ".agents" / "skills"
        skills.mkdir(parents=True)
        (skills / "team-old").symlink_to(out, target_is_directory=True)
        render.render(self.root, TODAY)
        self.assertTrue((out / "precious.txt").exists())
        self.assertTrue((agents / "team-old.md").is_symlink())
        self.assertTrue((skills / "team-old").is_symlink())

    def test_render_writes_root_assistant_files(self):
        paths = render.render(self.root, TODAY)
        rel = {p.relative_to(self.root).as_posix() for p in paths}
        self.assertEqual(rel, {
            "agent-team/team.json", "agent-team/coverage-map.md", "agent-team/board.html",
            ".claude/agents/team-qa.md", ".claude/agents/team-tech.md", ".claude/agents/team-design.md",
            ".agents/skills/team-qa/SKILL.md", ".agents/skills/team-tech/SKILL.md",
            ".agents/skills/team-design/SKILL.md"})
        for p in paths:
            self.assertTrue(p.is_file())

    def _refused_with_symlink(self, link_rel, move=None):
        import shutil
        out = self._outside()
        target = out / "target"
        target.mkdir()
        link = self.root / link_rel
        if move:
            shutil.move(str(link), str(target / "moved"))
            link.parent.mkdir(parents=True, exist_ok=True)
            link.symlink_to(target / "moved", target_is_directory=True)
        else:
            link.parent.mkdir(parents=True, exist_ok=True)
            link.symlink_to(target, target_is_directory=True)
        before = sorted(p.relative_to(out).as_posix() for p in out.rglob("*"))
        with self.assertRaises(render.RenderRefused) as cm:
            render.render(self.root, TODAY)
        self.assertIn(link_rel.split("/")[0], cm.exception.errors[0])
        self.assertEqual(before, sorted(p.relative_to(out).as_posix() for p in out.rglob("*")))

    def test_render_refuses_symlinked_claude_dir(self):
        self._refused_with_symlink(".claude")

    def test_render_refuses_symlinked_agent_team(self):
        self._refused_with_symlink("agent-team", move=True)

    def test_rendered_on_recorded(self):
        render.render(self.root, TODAY)
        data = json.loads((self.team / "team.json").read_text(encoding="utf-8"))
        self.assertEqual(data["rendered_on"], "2026-11-24")

    def test_today_from_team_json_reproduces(self):
        from team.__main__ import main
        paths = render.render(self.root, TODAY)
        before = {p: p.read_bytes() for p in paths}
        cwd = os.getcwd()
        os.chdir(self.root)
        self.addCleanup(os.chdir, cwd)
        self.assertEqual(main(["render", "--today", "from-team-json"]), 0)
        self.assertEqual(before, {p: p.read_bytes() for p in paths})
        (self.team / "team.json").unlink()
        self.assertEqual(main(["render", "--today", "from-team-json"]), 1)

    def _board(self):
        render.render(self.root, TODAY)
        return (self.team / "board.html").read_text(encoding="utf-8")

    def _inlined(self, html):
        start = html.index('id="crew-data">') + len('id="crew-data">')
        raw = html[start:html.index("</script>", start)]
        return json.loads(raw.replace("<\\/", "</"))

    def test_board_inlines_only_added_roles(self):
        data = self._inlined(self._board())
        self.assertEqual(list(data["roles"]), ["student", "instructor", "design", "tech", "qa"])
        self.assertEqual({o["id"] for o in data["others"]}, {"producer", "art", "narrative", "bi", "release"})

    def test_board_has_others_row(self):
        html = self._board()
        self.assertIn("data-others", html)
        self.assertIn("Other roles", html)
        self.assertNotIn("/*CREW_DATA*/", html)

    def test_board_no_script_breakout(self):
        path = self.team / "roles" / "design.md"
        text = path.read_text(encoding="utf-8")
        title = next(ln for ln in text.splitlines() if ln.startswith("title:"))
        path.write_text(text.replace(title, 'title: "Design </script><b>x</b>"', 1), encoding="utf-8")
        html = self._board()
        self.assertEqual(html.count("</script>"), 2)  # the data block and the code block only
        self.assertEqual(self._inlined(html)["roles"]["design"]["title"], "Design </script><b>x</b>")

    def test_board_escapes_slot_keys(self):
        # validate rejects such a key, so build the page from data directly and check the template
        # call sites: slot keys must never reach markup, and imports and exports must validate them.
        evil = '"><img src=x onerror=alert(1)>'
        data = {"game": "g", "columns": [], "roles": {"tech": {"slots": {evil: {"label": "l", "value": "v"}}}},
                "others": []}
        html = render.board_html(data)
        self.assertEqual(self._inlined(html)["roles"]["tech"]["slots"], data["roles"]["tech"]["slots"])
        self.assertNotIn("</" + "script><img", html)
        tpl = (Path(render.__file__).parent / "board" / "template.html").read_text(encoding="utf-8")
        self.assertNotRegex(tpl, r"id=\"s-' \+ k")
        self.assertNotRegex(tpl, r'getElementById\("s-" \+ k')
        self.assertNotRegex(tpl, r"for=\"s-' \+ k")
        self.assertIn("SLOTKEY.test(k)", tpl)
        self.assertIn("var SLOTKEY = /^[A-Za-z0-9_-]+$/;", tpl)
        self.assertIn("slots must be an object", tpl)
        self.assertIn("lanes must be an object", tpl)
        self.assertIn("KNOWN.indexOf", tpl)
        self.assertNotIn("Crew", tpl.replace("CREW_DATA", ""))


def cli(root, *args):
    env = dict(os.environ, PYTHONPATH=str(REPO), **GIT_ENV)
    return subprocess.run([sys.executable, "-m", "team", *args], cwd=str(root), capture_output=True,
                          text=True, env=env)


class CiConsistencyTests(unittest.TestCase):
    """What a student commits locally passes the drift check in final.yml."""

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name).resolve()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)

    def commit(self, msg, when):
        git(self.root, "add", "-A")
        git(self.root, "commit", "-qm", msg, when=when)

    def assert_ci_clean(self):
        done = cli(self.root, "validate", "--today", "2026-11-24")
        self.assertEqual(done.returncode, 0, done.stdout)
        done = cli(self.root, "render", "--today", "from-team-json")
        self.assertEqual(done.returncode, 0, done.stdout)
        git(self.root, "add", "-N", ".")
        diff = subprocess.run(["git", "diff", "--exit-code"], cwd=str(self.root), capture_output=True, text=True)
        self.assertEqual(diff.returncode, 0, diff.stdout)

    def test_commit_right_after_init_passes_ci(self):
        done = cli(self.root, "init", "--today", "2026-11-24")
        self.assertEqual(done.returncode, 0, done.stdout)
        self.assertTrue((self.root / "agent-team" / "team.json").is_file(), done.stdout)
        self.assertIn(".claude/agents/team-tech.md", done.stdout)
        self.commit("init", "2020-01-01T10:00:00")
        self.assert_ci_clean()

    def test_revision_before_commit_matches_ci(self):
        self.assertEqual(cli(self.root, "init", "--today", "2026-11-24").returncode, 0)
        tech = self.root / "agent-team" / "roles" / "tech.md"
        tech.write_text(tech.read_text(encoding="utf-8").replace(
            "Flag the technical risk in each concept.", "Flag the risk early.", 1), encoding="utf-8")
        self.assertEqual(cli(self.root, "render", "--today", "2026-11-24").returncode, 0)
        self.commit("tailor tech", "2020-01-01T10:00:00")
        note = self.root / "agent-team" / "handoffs" / "2026-11-24-tech-to-qa.md"
        note.write_text("---\nfrom: tech\nto: qa\ncolumn: prototype\nkind: handoff\ndate: 2026-11-24\n---\n"
                        "## Use\nbuild 1\n## Student decision\nAccepted.\n", encoding="utf-8")
        self.assertEqual(cli(self.root, "render", "--today", "2026-11-24").returncode, 0)
        self.commit("handoff", "2020-01-02T10:00:00")
        tech.write_text(tech.read_text(encoding="utf-8").replace(
            "Flag the risk early.", "Flag the risk on day one.", 1), encoding="utf-8")
        self.assertEqual(cli(self.root, "render", "--today", "2026-11-24").returncode, 0)
        data = json.loads((self.root / "agent-team" / "team.json").read_text(encoding="utf-8"))
        self.assertEqual(data["status"]["tech"], "revised")
        self.commit("revise tech", "2020-01-03T10:00:00")
        self.assert_ci_clean()


class StaleFileTests(unittest.TestCase):
    def setUp(self):
        self.tmp, self.team, self.notes = make_team(add=("art",))
        self.root = self.team.parent
        self.addCleanup(self.tmp.cleanup)
        agents = self.root / ".claude" / "agents"
        agents.mkdir(parents=True)
        self.mine = agents / "team-reviewer.md"
        self.mine.write_text("my reviewer\n", encoding="utf-8")
        self.skill = self.root / ".agents" / "skills" / "team-pitch" / "SKILL.md"
        self.skill.parent.mkdir(parents=True)
        self.skill.write_text("my pitch skill\n", encoding="utf-8")
        render.render(self.root, TODAY)
        self.assertTrue((agents / "team-art.md").is_file())

    def assert_only_art_removed(self):
        render.render(self.root, TODAY)
        self.assertFalse((self.root / ".claude" / "agents" / "team-art.md").exists())
        self.assertFalse((self.root / ".agents" / "skills" / "team-art").exists())
        self.assertEqual(self.mine.read_text(encoding="utf-8"), "my reviewer\n")
        self.assertEqual(self.skill.read_text(encoding="utf-8"), "my pitch skill\n")

    def test_removed_role(self):
        (self.team / "roles" / "art.md").unlink()
        self.assert_only_art_removed()

    def test_retired_role(self):
        art = self.team / "roles" / "art.md"
        art.write_text(art.read_text(encoding="utf-8").replace('not_used: ""', 'not_used: "text only"', 1),
                       encoding="utf-8")
        self.assert_only_art_removed()
        text = (self.team / "coverage-map.md").read_text(encoding="utf-8")
        row = next(ln for ln in text.splitlines() if ln.startswith("| art |"))
        self.assertIn("not used", row)
        self.assertNotIn("team-art", row)


HARNESS = r"""
const fs = require("fs"), vm = require("vm");
const [page, storeIn, href, action] = process.argv.slice(2);
const html = fs.readFileSync(page, "utf8");
const start = html.indexOf('id="crew-data">') + 'id="crew-data">'.length;
const data = html.slice(start, html.indexOf("</script>", start));
const code = html.slice(html.lastIndexOf("<script>") + 8, html.lastIndexOf("</script>"));
const els = {};
function el(id) {
  if (!els[id]) els[id] = { id: id, value: "", innerHTML: "", hidden: false, dataset: {},
    textContent: id === "crew-data" ? data : "", style: { setProperty() {} },
    classList: { add() {}, toggle() {} }, on: {},
    addEventListener(t, f) { this.on[t] = f; }, querySelector() { return null; }, querySelectorAll() { return []; } };
  return els[id];
}
const store = JSON.parse(storeIn);
const listeners = {};
const u = new URL(href);
const ctx = {
  document: { getElementById: el, querySelectorAll: () => [], addEventListener: (t, f) => { listeners[t] = f; },
    body: { classList: { add() {} }, contains: () => false, appendChild() {} }, activeElement: null,
    createElement: () => ({ remove() {}, style: {} }) },
  localStorage: { getItem: k => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); },
    removeItem: k => { delete store[k]; } },
  location: { protocol: u.protocol, hostname: u.hostname },
  window: { addEventListener() {}, innerWidth: 1000, innerHeight: 800 },
  navigator: {}, setTimeout: () => 0, clearTimeout() {}, fetch: () => new Promise(() => {}), console: console
};
vm.createContext(ctx);
vm.runInContext(code, ctx);
if (action && action.indexOf("rename:") === 0) el("game-name").on.change({ target: { value: action.slice(7) } });
if (action && action.indexOf("md:") === 0) {
  const t = { dataset: { md: action.slice(3) }, id: "" };
  listeners.click({ target: { closest: s => (s === ".abbr" ? null : t) }, preventDefault() {}, stopPropagation() {} });
}
process.stdout.write(JSON.stringify({ game: el("game-name").value, store: store, layer: el("layer").innerHTML }));
"""


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class BoardScriptTests(unittest.TestCase):
    """Run the board's script in node with a stub page."""

    def setUp(self):
        self.tmp, self.team, _ = make_team()
        self.root = self.team.parent
        self.addCleanup(self.tmp.cleanup)
        fill_other(self.team)
        self.harness = self.root / "harness.js"
        self.harness.write_text(HARNESS, encoding="utf-8")
        render.render(self.root, TODAY)

    def page(self, name="board.html"):
        dst = self.root / name
        shutil.copyfile(self.team / "board.html", dst)
        return dst

    def run_board(self, page, store, href, action=""):
        done = subprocess.run(["node", str(self.harness), str(page), json.dumps(store), href, action],
                              capture_output=True, text=True)
        self.assertEqual(done.returncode, 0, done.stderr)
        return json.loads(done.stdout)

    def saved_rename(self, page):
        out = self.run_board(page, {}, "file:///x/board.html", "rename:Edited Game")
        self.assertEqual(out["game"], "Edited Game")
        self.assertEqual(len(out["store"]), 1, out["store"])
        return out["store"]

    def test_file_reload_applies_saved_copy(self):
        page = self.page()
        store = self.saved_rename(page)
        self.assertIn("Signal Station (example)", next(iter(store)))
        self.assertEqual(self.run_board(page, store, "file:///x/board.html")["game"], "Edited Game")

    def test_served_page_ignores_saved_copy(self):
        page = self.page()
        store = self.saved_rename(page)
        for href in ("http://127.0.0.1:8765/", "http://localhost:8765/"):
            out = self.run_board(page, store, href)
            self.assertEqual(out["game"], "Signal Station (example)", href)

    def test_saved_copy_discarded_after_new_render(self):
        page = self.page()
        store = self.saved_rename(page)
        tech = self.team / "roles" / "tech.md"
        tech.write_text(tech.read_text(encoding="utf-8").replace(
            "Flag the technical risk in each concept.", "Flag risk early.", 1), encoding="utf-8")
        render.render(self.root, TODAY)
        out = self.run_board(self.page("board2.html"), store, "file:///x/board.html")
        self.assertEqual(out["game"], "Signal Station (example)")
        self.assertEqual(out["store"], {})

    def test_other_game_does_not_share_edits(self):
        page = self.page()
        store = self.saved_rename(page)
        for rid in ("tech", "qa"):
            role = self.team / "roles" / f"{rid}.md"
            role.write_text(role.read_text(encoding="utf-8").replace(
                'game: "Signal Station (example)"', 'game: "Other Game"', 1), encoding="utf-8")
        render.render(self.root, TODAY)
        out = self.run_board(self.page("board2.html"), store, "file:///x/board.html")
        self.assertEqual(out["game"], "Other Game")

    def exported(self, rid):
        out = self.run_board(self.page(), {}, "file:///x/board.html", f"md:{rid}")
        layer = out["layer"]
        self.assertIn(f"agent-team/roles/{rid}.md", layer)
        m = __import__("re").search(r'<pre class="export" id="export-text" tabindex="0">(.*?)</pre>', layer, 16)
        return layer, htmllib.unescape(m.group(1))

    def test_export_holds_only_board_blocks(self):
        layer, text = self.exported("tech")
        meta, body = fm.parse(text)
        self.assertEqual(set(meta), {"id", "game", "slots", "lanes"})
        self.assertEqual(body.strip(), "")
        self.assertNotIn("#", text)
        self.assertIn("replace the game, slots, and lanes blocks", layer.lower())
        self.assertNotIn("team/roles/tech.md", layer.replace("agent-team/roles/tech.md", ""))

    def test_export_round_trips_through_merge_role(self):
        from team import serve, validate
        role = self.team / "roles" / "tech.md"
        old = role.read_text(encoding="utf-8")
        _, text = self.exported("tech")
        merged = serve.merge_role(old, text, "tech")
        self.assertEqual(fm.parse(merged), fm.parse(old))
        role.write_text(merged, encoding="utf-8")
        self.assertEqual(validate.validate(self.team, TODAY).errors, [])


if __name__ == "__main__":
    unittest.main()
