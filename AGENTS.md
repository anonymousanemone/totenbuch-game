# Project instructions

- Project skills live in `skills/<name>/SKILL.md`: `build-levels` (building a level from an `.mdp`), `suggest-games` (proposing puzzles and minigames), `cite-references` (citing sources in registries and the Scene Atlas) and `make-artwork` (scroll art that keeps the original drawing, UI art that matches the Old Fax font). Read the matching one before starting that kind of work.
- Only create or save files in `mockups/` when the user explicitly requests it. Put temporary screenshots, previews, and verification artifacts in a temporary directory outside the repository instead.
- Leave existing files in `mockups/` untouched unless the user requests changes or cleanup.

## Rebuilding assets

- Never rebuild, re-cut or regenerate assets under `godot/assets/` (or the scenes they feed) unless the user explicitly asks. Fixing, merging or refactoring a tool does not mean running it on the real repository.
- The tools are used in a targeted way: something specific changed in the art, so rebuild only that item (for example `cut_dangers300.py ... ankh38`, `build_scene.py gates`, one `cut_procession300.py --water`), never the whole level or every level. Name what will be rebuilt and wait for the request.
- To check a tool, run it on a copy in a temporary directory outside the repository and compare. Never write into `art/`.

## Tests

- A test may compare shown text only against the JSON (`registry.json`, `puzzles.json`, `messages.json`, read through `descriptions.gd` or `puzzles.gd`) or against text the test sets up itself. Never compare against a hard-coded copy of the game's text, and don't write a test whose only purpose is to pin the wording of an entry.

## Movable objects

- Reuse `godot/scripts/moveable_object.gd` and existing puzzle validation/recovery code; do not duplicate movement logic.
- Default to press-drag-release, never click-follow. Only carriable objects attach to the avatar on a world click; clicking an attached object reads its description, which remains visible during dragging unless game-state feedback replaces it.
- Accept only valid placements; otherwise restore the valid attachment/location using the puzzle's recovery rules. Preserve object size and lock final placements against further dragging.
- Ask before adding exceptions. Existing approved exceptions are the words' click-follow/appearance animation, adze tool controls at 50% scale during carving, and offering-table automatic snapping/physics. Starting carving requires dragging the adze onto the mummy. Calf/jar gestures transform in place and are outside this system.


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
