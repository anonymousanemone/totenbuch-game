# Your agent team

You start with two agents from the midterm: Tech Lead (the implementation agent) and QA (the independent reviewer). You add another when you see a reason for it: a command you keep typing, a correction you keep making, or a step that keeps slowing you down. Every role you do not add gets one line in `other-roles.md`, so the course can see you decided.

**G2/G3 (recording Saturday, November 28):** tailor both starters to your game, and pass one handoff between two agents with your decision recorded on it.

**G4 (recording Saturday, December 5):** direct at least three production agents, at least one of them added with an origin note; run at least one chain of three roles (two handoffs, each with your decision); and revise at least one agent because a handoff exposed a weakness. Your in-game agent is separate.

Missing origin-note details, a role with neither a role file nor a line in `other-roles.md`, and a short floor appear as warnings until 2026-12-05 and as errors from then. Your team lives in `agent-team/` at the root of your repository.

## Commands

Run them from the repository root. Where `python` is missing, `python3` works the same.

```
python -m team init
```

Creates `agent-team/` with `roles/tech.md`, `roles/qa.md`, an empty `handoffs/` folder, and `other-roles.md` listing the six other roles, then runs `render`, so you can commit everything right away.

```
python -m team add design
```

Copies the Design Lead role and writes an origin note, `handoffs/2026-11-24-student-to-design.md`, with its column and date filled in. Role ids: `producer`, `design`, `tech`, `art`, `narrative`, `qa`, `bi`, `release`. The command removes the role from `other-roles.md`. If a note with that name already exists, the new one gets the next free number (`-2`, `-3`) and the old one stays as it is.

```
python -m team validate
```

Checks role files, handoffs, origin notes, and `other-roles.md`, then prints errors, warnings, and a count:

```
handoffs/2026-11-24-student-to-design.md: Why this agent needs at least two links
agents=3 origin_notes=1
```

```
python -m team render
```

Generates the files your assistant reads and the coverage map, and prints each path:

```
.claude/agents/team-design.md
.agents/skills/team-design/SKILL.md
agent-team/board.html
agent-team/coverage-map.md
agent-team/team.json
```

Edit a role in `roles/`, run `render`, and commit everything it writes with your edit. `render` writes only `agent-team/`, `.claude/agents/`, and `.agents/skills/`, and refuses to write through a symlink. It deletes `.claude/agents/team-<id>.md` and `.agents/skills/team-<id>/` only for a role id from the list above that you removed or marked `not_used`; your own agents and skills stay. Never edit the generated files by hand; change a role and run `render` again.

A role shows `revised` in the coverage map when you change it after committing a handoff note from it. A change you have not committed yet counts as made now, so `render` shows `revised` before the commit, as CI does after it.

## The origin note

Open the file `add` wrote and fill in **Why this agent**: link at least two instances of the friction, such as transcript excerpts, commits, or issues, each dated before the agent's first commit. If you re-explained the same guard rule to your coding agent in two sessions, link both; a Design Lead that owns your rules is the next agent. Then fill in Use, Produce, Accepted when, Evidence, and Student decision. `validate` counts the links.

## Roles you handle another way

`other-roles.md` takes one line per role you have not added:

```
- producer: student
- art: not needed, the game uses only text and shapes
- release: agent .claude/agents/release.md
```

An agent you built outside the tool counts, in any assistant or format: point to it with `agent <path>`, relative to the repository root, and write its origin note in `handoffs/` too.

To retire an added role and keep its file, set `not_used:` in its frontmatter to the reason, for example `not_used: "the tech agent covers rules"`. The role then has no assistant files and stops counting toward the three agents.

## A first chain

Design Lead to Tech Lead to QA: `python -m team add design`. If your game runs in a browser, give QA [Playwright](https://playwright.dev/docs/intro) so it plays your build, clicks through the core loop, and saves screenshots as evidence. For other games, QA runs scripted episodes through your player interface. Record your decision on each handoff.

## Tool lists

Claude Code enforces the tool list in each agent file. Other assistants read it as instructions, so check an agent's work there yourself. Every role file tells the agent that it recommends, you decide, and the instructor approves gates.

## The board

`render` also writes `agent-team/board.html`, a page showing your agents and handoffs by gate.

To edit roles in the board and save them to `agent-team/roles/`, run:

```
python -m team serve
```

Then open `http://127.0.0.1:8765/` (or `http://localhost:8765/`). The page is served only to your own computer, and it runs `render` first if `agent-team/team.json` is missing. If another program holds the port, choose another with `--port`, for example `python -m team serve --port 8766`. On that address the page shows your role files as of the last `render`, so run `render` after editing a role file by hand, then reload. Save sends the role to the server, which checks it, updates only the `lanes`, `slots`, and `game` of `agent-team/roles/<id>.md` (permissions, subtitle, and the Instructions stay as you wrote them), and runs `render`; if the check fails, the board shows the errors and your file stays as it was.

If you open `agent-team/board.html` directly as a file, edits stay in your browser until `render` writes a changed version of the page. To keep them, choose **Show role file** and replace the `game`, `slots`, and `lanes` blocks in `agent-team/roles/<id>.md` with the ones it shows.

## CI

`.github/workflows/final.yml` runs the team tests, `validate`, and `render --today from-team-json`, then fails if the generated files differ from what you committed. Run `python -m team render` and commit the result when it does. Replace the `Your tests` step with your game's test command. The team tests check only that the workflow keeps a read-only token, keeps no credentials after checkout, and uses neither secrets nor `pull_request_target`; change the rest to suit your game.
