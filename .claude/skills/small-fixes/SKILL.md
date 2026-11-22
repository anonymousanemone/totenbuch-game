---
name: small-fixes
description: How the Tech Lead takes a list of small fixes from the author (a bug, a click that does the wrong thing, a missing or wrong line, a snap, a colour, a description) and carries each one through Notion, the existing behaviour, shared code, a regression test, a check in the running game and a report, asking the author whenever a decision is theirs. Use whenever the author hands over fixes to make.
---

# Small fixes

The author gives a list of fixes, usually dictated and short ("goose does not snap into the goosebearer's arms", "lector priest and offering table priest speech colours differ again"). Each one is a small change to something already built. The work is to make exactly what was asked, the same way the game already does it, without breaking an earlier fix, and to leave a record in Notion that the author can read instead of the transcript.

Read these skills before starting. This skill adds the order of work and the escalation rules; it does not repeat theirs:

- `write-notion` for every Notion read and write;
- `check-features` for sorting details, the interaction grid, text coverage, frames and the bug-report steps;
- `write-game-text` (and `cite-references` if the text comes from a source) for any line the player sees;
- `log-decisions` at the end.

## What counts as small

A small fix changes one behaviour, line or value in a mechanic that already exists, plus its siblings if the author asks for them. Examples from the History pages:

- the wrong thing reacts to a click (the water game started from Anubis instead of the jar priest);
- a description or success line is missing, stale or never shown;
- a drag doesn't snap, a piece changes size or facing, hands-full applies where it shouldn't;
- a message appears at the wrong time, or a prompt to help returns after the puzzle is done;
- two things that should match don't (speech colours, glow, exit keys);
- a stale reference loses an object (the bread after the goose returns).

It is **not** small, and goes back to the author as a proposed Notion task instead, when it needs new art, a rebuild under `godot/assets/`, a write to `art/`, a new mechanic or minigame, a change to a shared system that several levels use beyond what was asked, or a level-wide refactor. Say what makes it big, and propose the task title, scope and category for `write-notion`.

## 1. Take in the list

1. Split the author's message into one item per fix. Keep their words. If a line holds two fixes, make two items. If it is unclear which item a sentence belongs to, ask.
2. For dictated text, list every ambiguity or conflict before building: a word that could name two figures, "the priest" when there are several, "should snap like the others" without saying which others.
3. For each item, find it in Notion (Totenbuch Tasks): search To do, Backlog, In progress and Done for the same object or behaviour. Use an existing row if there is one; otherwise create one per `write-notion` sections 4 and 6: the author's words as the title (reworded to an action only if no fact is lost), Scope, one Category (`Bug` when built behaviour differs from what was meant), Status In progress, Role `Tech Lead`, and an agent log line `<date time> · Tech Lead · created from the author's fix list`. A row the author already wrote keeps its wording.
4. Check In progress for unclaimed rows (`write-notion` section 3). List any that are small fixes to the author with the escalations in step 3 below; take them only on a yes.

## 2. Check what exists before changing anything

For each item, before writing code:

1. **Current behaviour.** Reproduce it. Reach the state with the debug T menu or the command-line flags (`README.md`, Command-line checks), and the step driver (`godot/tests/step.py`) to click through it. Save a frame or a step-driver reply outside the repository. If it does not reproduce, say so and ask; do not fix a guess.
2. **Earlier decisions.** Search the scope's History and Done pages, its Documentation page, `project-docs/decision-log.md` and `git log -S` for the same object. Many fixes touch something already fixed once (the goose bearer has six History entries). Note what each earlier fix decided, so this one does not undo it. If the request contradicts one, that is an escalation.
3. **"Again".** If the request says "again", "still" or "differ again", find the earlier fix and its test, and work out why the test didn't catch the regression. The fix includes a test that would have.
4. **Shared code.** Find the code that already does this for a sibling, using the lists in `AGENTS.md` (Shared level code, Movable objects, Minigame view): `moveable_object.gd` for drag, snap and recovery; `walk.gd` for walk-and-read levels; `ScrollCamera`; `UI.hover_glow` / `UI.glow_step`; `UI` colour constants and `project-docs/style-guide.md`; `hud.gd` for the band and its timers; `minigame_view.is_exit` for exit keys; `descriptions.gd` and `puzzles.gd` for text. Fix the behaviour where it is shared, or make the level use the shared code. Never copy it into a level. If the shared code would need an exception, that is an escalation.
5. **Sort the details** as `check-features` step 1: stated, precedent (name the sibling) or assumed. Every assumption the player would notice goes to the author before building.

## 3. Escalate decisions to the author

Ask before building when:

- the request is ambiguous, or dictation could be read two ways;
- a detail the player would notice is unstated and no sibling settles it;
- the fix would need an exception to `AGENTS.md`, a rebuild of an asset, a write to `art/`, or new art;
- the request conflicts with an earlier decision, a History entry or the style guide;
- the fix would change a rule, a control or the player interface beyond the item;
- "most", "all" or "every" is used about siblings: list the exact siblings and ask which are in;
- it turns out not to be small (section "What counts as small");
- a line of game text has to be written that the author did not give, and its wording changes what the player learns.

How to ask:

- Collect every question across the whole list first, then ask them together; work on the unaffected items meanwhile.
- Each question stands alone: the item, what you found (with the file, the History entry or the frame), the options, and your recommendation first. Ask with `AskUserQuestion` when it is available (at most four questions a call).
- Write a blocker log line on the Notion row (`… · Tech Lead · blocked: <question in a few words>`), and leave it In progress.
- Never set TBD yourself. Never decide for the author by picking the option nobody objected to.

Tell the author afterwards, without asking first, about defaults you took from a named sibling and constants you chose for tuning.

## 4. Fix it

1. **Test first.** Write the failing regression in the level's suite under `godot/tests/` (or the shared suite for shared code) that shows the bug, as `check-features` "When the author reports a bug". Compare shown text only against the JSON. Hover cases use a `SubViewport` with `push_input`, never the real cursor.
2. **Smallest change.** Change only what the item needs, in the shared place. Remove only what your change orphaned. Text goes in the JSON, never a script or a scene, and follows `write-game-text`: show the old line and the new.
3. **Neighbours.** Check the same object in its other states, and the same state for the other objects in the area (the interaction grid in `check-features`, only for the area touched). If a neighbour has the same bug, report it; fix it only if the author's item covers it.
4. **General rule.** If the cause was a general assumption ("hands full applies to everything"), propose the rule for `AGENTS.md` or the matching skill; add it after the author agrees.

## 5. Verify

1. Run only the suites for the levels touched, plus every level that uses a changed shared script (`check-features` check 6), one suite at a time: `godot --headless --path godot --script res://tests/<suite>.gd`, or `-- --level=<level> --autotest`. Not the whole sweep unless shared code used by every level changed.
2. Play it once in the running game: the step driver or the T menu to reach the state, then the normal controls. Capture the frame before and after, and read them. Check 1280 × 720 and the smallest size if layout moved.
3. Check the author's words one by one against what now happens. Every word of the request is met, or the report says which one is not and why.

## 6. Record and report

1. **Notion**, per `write-notion`: a log line saying what was done (`… · Tech Lead · done: goose snaps into the bearer's arms on drag, like the offering table`), Status Done, an empty Done date filled with today, and a one- or two-sentence **Outcome** in the History style: what the player now sees, and how it was verified. Leave **Done in commit** empty until the author approves a commit. If the fix changed shared code, update the matching Game-wide Documentation page named in `AGENTS.md`. Do not sweep into History.
2. **Handoff.** If `agent-team/` exists, write `agent-team/handoffs/YYYY-MM-DD-tech-to-qa.md` from its template (Use, Produce, Accepted when, Evidence; Student decision left empty), naming the build as the working tree or a commit.
3. **Report** to the author, per item: done, blocked or proposed as a bigger task; what changed (files); the test added and the suites run with their results; the frames by state; defaults taken from siblings and tuning constants with values; what is not checked and why. Then the questions still open. Keep it short; the details are in Notion and the tests.
4. **Decision log** entry with `log-decisions`.
5. **Never commit or push** without the author's explicit yes for that commit; show the files and message first.

## Checking

1. Every item in the author's list has a Notion row, an outcome or a blocker line, and appears in the report.
2. Each fix was reproduced before it was changed, and earlier History entries and decisions for the same object were read.
3. The fix uses the shared code a sibling uses; nothing was copied into a level, and no `AGENTS.md` exception was made without the author.
4. A regression test fails without the fix and passes with it; only the relevant suites were run, and they pass.
5. The fix was seen working in the running game, with frames.
6. Every question the author had to decide was asked, and nothing was decided by default.
7. No asset was rebuilt, nothing was written to `art/`, nothing was committed.
