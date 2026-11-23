# Project instructions

- Project skills live in `.claude/skills/<name>/SKILL.md`: `build-levels` (building a level from an `.mdp`), `suggest-games` (proposing puzzles and minigames), `cite-references` (citing sources in registries and the Scene Atlas), `splice-plates` (rotating and splicing plates into a new `.mdp`), `make-artwork` (scroll art that keeps the original drawing, UI art that matches the Old Fax font), `draft-ui` (HTML drafts with several tunable versions before any UI is built), `write-game-text` (instructions, feedback, hints, descriptions and messages the player sees), `write-hints-instructions` (each puzzle's instructions and graded Hint-button ladder in `puzzles.json`, and judging existing ones), `check-features` (checking a feature or fix behaves as intended before the author plays it), `playtest` (playing a level as a cold first-time player and bringing back only the decisions that need the author), `log-decisions` (the brief per-session record in `project-docs/decision-log.md`), `write-notion` (rules for writing to the Totenbuch Tasks, Weekly PPP and Risk Register databases on the Final project tracker page in Notion) and `small-fixes` (carrying a list of small fixes from the author through Notion, existing behaviour, shared code, tests and the running game). Read the matching one before starting that kind of work.
- Every session that decides, makes or changes anything ends by updating its entry in `project-docs/decision-log.md` with the `log-decisions` skill, before the closing message.
- Art follows `project-docs/style-guide.md` and the art skills, with no exceptions unless the user explicitly approves one. The user may approve an exception at any time; record it in the style guide's Approved exceptions table.
- Only create or save files in `mockups/` when the user explicitly requests it, or for a new UI draft made with the `draft-ui` skill. Put temporary screenshots, previews, and verification artifacts in a temporary directory outside the repository instead.
- Leave existing files in `mockups/` untouched unless the user requests changes or cleanup.

## Rebuilding assets

- Never rebuild, re-cut or regenerate assets under `godot/assets/` (or the scenes they feed) unless the user explicitly asks. Fixing, merging or refactoring a tool does not mean running it on the real repository.
- The tools are used in a targeted way: something specific changed in the art, so rebuild only that item (for example `extract_dangers300.py ... ankh38`, `build_scene.py gates`, one `extract_procession300.py --water`), never the whole level or every level. Name what will be rebuilt and wait for the request.
- Built artwork is stable: once a level's art is fully built it is rarely, if ever, rebuilt, and when it is, the user says so explicitly. Dangers, Procession, Survival and Gates are stable. Build and export tools never regenerate a derived image as a side effect (a body/arm split, a sheet, a figure merged from its pieces): what another tool made, or a hand made, is left as it is.
- To check a tool, run it on a copy in a temporary directory outside the repository and compare. Never write into `art/`.
- Animation sheets are generated once (e.g. by `spearers.py`, `snakes.py`, `sheets.py`, `thoth_doors.py` in the `make-artwork` skill), then hand-edited and approved. Once approved, an animation is never regenerated unless the user explicitly asks. Animation generators are never wired into a build or export tool; they run only on their own, by request.

## Tests

- A test may compare shown text only against the JSON (`registry.json`, `puzzles.json`, `messages.json`, read through `descriptions.gd` or `puzzles.gd`) or against text the test sets up itself. Never compare against a hard-coded copy of the game's text, and don't write a test whose only purpose is to pin the wording of an entry.

## Movable objects

- Reuse `godot/scripts/moveable_object.gd` and existing puzzle validation/recovery code; do not duplicate movement logic.
- Default to press-drag-release, never click-follow. Only carriable objects attach to the avatar on a world click; clicking an attached object reads its description, which remains visible during dragging unless game-state feedback replaces it.
- Accept only valid placements; otherwise restore the valid attachment/location using the puzzle's recovery rules. Preserve object size and lock final placements against further dragging.
- Ask before adding exceptions. Existing approved exceptions are the words' click-follow/appearance animation, adze tool controls at 50% scale during carving, and offering-table automatic snapping/physics. Carving starts by dragging the adze onto the mummy, or by clicking the mummy with the adze in hand. Calf/jar gestures transform in place and are outside this system.

## Shared level code

- A walk-and-read level is a scene on `godot/scripts/walk/walk.gd` with its exports set; do not copy the script. Survival and Gates extend `walk.gd` and enable its chapter titles, scene-only journal totals, foreground blocking and development flags.
- Use `ScrollCamera` (`godot/scripts/scroll_camera.gd`: `follow`, `view_height`, `VIEW_TOP`) for the camera's zoom, clamp and rows; do not re-derive them in a level.
- Hover glows are `UI.hover_glow`; a glow's strength is tweened only through `UI.glow_step`, timed by `UI.HOVER_FADE`.
- Notion's Game-wide Documentation pages describe these (*Explore levels: shared base classes*, *Shared camera*, *Avatar movement*, *Glow helpers*, *Figure masks*); update the matching one when you change shared code.

## Grouped and locked parts

- Drawings the scene keeps together in a plain `Node` (a spell's crocodiles, the donkey and its snake, a figure and its hauler) are one thing: they glow together under the pointer and share one registry entry. A node that is only a folder (`Pieces`, a spell's) groups nothing.
- A part locked into place (an offering on the table, the goose in the bearer's arms) belongs to the whole it sits in: it glows, and answers a click, exactly as that whole does in the same state, including glowing nothing where the whole does. Only parts that can still be moved glow and answer on their own.

## Minigame view

- Starting a minigame enters minigame view: the camera moves once to the minigame's framing and then stays fixed until the minigame is exited (won, lost or left). Examples are the procession games, where the camera zooms in on the scene, the Dangers fights, where the vignette expands across the screen, and the Survival altars (52, 53).
- While in minigame view the camera must not follow the avatar or objects, refit to HUD or message size changes, or drift and wobble. Normal camera behaviour resumes only on exit.
- Esc leaves take-the-place games. Left, Right or Esc leaves drag-and-drop games. Procession and Survival use `minigame_view.is_exit` for these keys.
- Each level holds the camera from its active minigame state.
- Walking into a location keeps the current text. Changes in game state can be announced. Survival 59 plays its sequence on walk-in.


## Course agent team

This is the student's own repository for their final game in AI in Practice: Game Design and Development (Columbia, Fall 2026).

- You recommend; the student decides; the instructor approves gates. You never approve a gate, merge a pull request, or change a deadline.
- `agent-team/` holds the student's role files, handoffs, and origin notes. The generated files (`agent-team/team.json`, `agent-team/coverage-map.md`, `agent-team/board.html`, `.claude/agents/team-<id>.md`, and `.agents/skills/team-<id>/SKILL.md`) are written by `python -m team render`, never by hand. Change a role file, then run `PYTHONPATH=project-docs python -m team render`. The tool is in `project-docs/team/`, its tests in `project-docs/tests/`. The guide is `project-docs/team/README.md`.
- QA writes tests, never game code.
- The student keeps every decision: they act as Executive Producer and Creative Director, and the instructor approves gates.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
