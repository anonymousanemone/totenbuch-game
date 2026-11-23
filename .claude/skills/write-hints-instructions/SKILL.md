---
name: write-hints-instructions
description: How to write the text that starts and helps each puzzle in the Book of the Dead game, in puzzles.json - the instructions shown when a puzzle begins, and the Hint-button ladder (notice, interpret, act: at most three graded hints per phase) - and how to judge existing instructions and hints for whether they help, give away too much, or are badly graded. Use whenever a puzzle or phase is added or changed, when instructions or hints are written or reviewed, or when a playtest shows players unsure what to do, stuck, or hints jumping to the answer.
---

# Writing instructions and hints

Instructions start a puzzle; the Hint button helps the player who is still stuck. Both live in `puzzles.json`, and they work as one system: the instruction is the baseline, and the ladder only says what the instruction did not.

This skill decides **what a puzzle's instruction says, how many hints a phase needs, and what each hint says**. `write-game-text` still governs every line's wording, length, voice and names, and the Narrative and Audio oversight rules apply in full: no invented facts, only edit what you added, and the author approves wording.

Do not quote the game's current hints as examples in this skill or in reports about it without asking the author first. Several current hints are not satisfactory, so they are not models.

Everything below is guidance, not law. A puzzle may call for an exception (a discovery puzzle with nothing to tell, a figure's request that carries no controls). Make the exception only when the author agrees, and say what it is and why. Whenever something is unclear, ask before writing.

## How the text works in the game

- Instructions and hints live in `godot/assets/<level>/puzzles.json`.
  - A puzzle's `instructions` is the line shown as soon as it starts. Some levels keep theirs in `messages` instead (for example a level's `start` line); treat those the same way.
  - `hints.find` holds one line per destination (`default`, and for example `right` when the puzzle is behind the player). It is shown before the player has started the puzzle.
  - `hints.phases` holds one list per phase. Each entry is `{ "level": <kind>, "text": <line> }`.
- `godot/scripts/puzzles.gd` shows the first hint entry on the first press, the next on the next press, and repeats the last one after that. It appends "click hint again" to every line but the last.
- The script decides which phase is current. A new phase needs a script change, so it is the Tech Lead's (hand it off as `small-fixes` describes).
- `godot/tests/hint_regressions.gd` checks each phase's `level` labels: `notice`, `interpret`, `act`, in that order, ending with `act`.

## 1. Instructions

An instruction says **what the task is**, in a sentence or two. The player can infer a lot, so keep it sparse.

- **Controls, in general terms.** Name the keys the puzzle uses ([space], [←] [→], [esc]) so the player knows what to reach for. Don't list every binding or explain what each does when the action makes it plain. Dragging is the default (AGENTS.md) and needs no explanation. The exit keys are the same for each kind of game (AGENTS.md, Minigame view), so mention them only when the player could otherwise feel stuck.
- **The goal as something visible.** When it can be, make it countable or seeable ("all five", "each"), rather than abstract.
- **Not the clue, not the fix.** An instruction says what to do, never where to look or what the clue means; that is the ladder's job. If an instruction already carries a clue, tell the author: either it stays and the ladder skips that rung, or it moves into an `interpret`.
- **Say only what is new.** In a run of puzzles in one level, a later instruction names what changed, not everything again.
- **One verb per action**, the same in the instruction, the feedback and the hints, and matching the control.
- **Voice.** Follow the level: a figure asking for help, or the plain "you". Keep controls readable if a figure speaks them. Ask if it is unclear which fits.
- **Length** is `write-game-text`'s: three rows, about 180 characters. An instruction that cannot fit is a signal the mechanic is too much to explain; report it as a design problem rather than squeezing it.
- **True to the game.** Keys, counts and rules in an instruction must match the code and the registry names; check them there.

Ask the author before writing when it is unclear what the player is meant to do, which controls the puzzle takes, or whether something should be told or left to discover.

## 2. Split the puzzle into phases

A phase is one thing the player has to work out or do before the next becomes possible: for example, choosing the right piece, then placing it, then completing a sequence. For each phase write down:

- **what the player must do** (the move);
- **what the player must know** to choose or perform that move (the relationship, or how the mechanic behaves);
- **what on screen tells them** (the clue: a detail in the art, a description, a figure's speech, a caption);
- **what the instruction already says**, since instructions never cost a hint and a hint must never repeat them.

If the clue is missing, or the move cannot be read from the screen at all, the ladder can't fix that. Report it as a design problem (a missing clue, description or signal) rather than writing a hint that supplies the missing knowledge.

## 3. The three kinds of hint

| Kind (`level`) | The player is stuck because… | The hint… | It must not… |
|---|---|---|---|
| `notice` | they haven't found the puzzle, or haven't seen the clue | points them to something visible: where the puzzle is, a detail, a figure to consult | say what the clue means or what to do |
| `interpret` | they've seen it but don't see what it means, or can't make the move work | gives the relationship the clue shows, or how the mechanic behaves (what to watch, when to press, what to ignore) | name the move or the exact target |
| `act` | they understand but don't know the move | says what to do, with the control if needed | add a task or step from another phase |

The Find line is a `notice`: it points to where the puzzle is. It lives under `find` because the game shows it before any phase has started; write and judge it as the first `notice` of the puzzle. **Exception: Dangers has no Find lines** (the author deleted them); Hint shows nothing outside a fight there. Procession keeps its Find lines.

## 4. Choose the rungs

A phase gets **at most three hints**: `notice` → `interpret` → `act`, always in that order. The normal ladder has all three.

- A phase may leave out `notice` when the Find line already brought the player to the clue, or leave out `interpret` when the meaning is plain once the clue is seen. Say which one you left out and why.
- **A phase with only an `act` should not happen.** If a phase seems to need nothing but the answer, either it is not a real phase (fold it into the one before or after) or a clue is missing (a design problem). Use `act` alone only with a very good reason, and ask the author first.
- For a skill phase, where the player knows the move but can't do it well, the technique (timing, aim, what to watch) is an `interpret`: it explains how the mechanic behaves. The ladder still ends with an `act`.

Order is always from least revealing to most. The last hint must be something the player can act on.

A fight is the exception to the full ladder (see **Fights** in section 5): its phase holds only the strategy or edge-of-screen hints that exist, may be one line or absent, and need not end with an `act`. This needs the Tech Lead to relax the script and `hint_regressions.gd`, which still require every phase to end with an `act`.

## 5. What each hint says

**Notice.** Points the player to something visible: where the puzzle is (the Find line, in the game's directions: "walk left", "back", "right"), one detail to look at, or one figure to consult, named as the registry names it. It may be vague about what to do, or come at the clue sideways; what it must do is point at something the player can see, or a description or speech they can open there.

**Interpret.** The relationship the clue shows, or how the mechanic behaves: which thing belongs with which, what is out of order, what a figure lacks or wants, when the timing is right. The player should be able to work out the move from it, but the move itself is not stated. It may also be indirect, as long as it is tied to something visible. A fact from the sources (an identification, what an object is for) must be supported by the cited source, as for any other line; a claim about the mechanic must be true in the code, so check it there before writing.

**Act.** The move: what to drag, click or press, and where, with the control names in brackets ([←], [space]). Only this phase's move. This is the only hint allowed to give the solution.

**Fights.** In a fight (Dangers and any later action level) the player can see the creature, and what it does is obvious: a tail wiggling, coils tightening, a head lifting, a wave rising. A fight hint never describes these cues or what they mean. It offers only:

- **a strategy idea** the player may not think of (move into a crocodile's path and let it bite you rather than let it steal past; a rule the mechanic has on purpose left unsaid), or
- **something at the edge of the screen they may not have noticed** (the red signs above the crocodiles, the signs above the two Merti snakes), and what it is for.

The first is an `interpret`, the second a `notice`; an `act` is added only when there is a move to name (hold [shift] for a red crocodile). A fight that has no strategy and nothing at the edge has **no hint**: Hint stays silent in it. Never write a hint to restate the controls or to say when to press; the instruction names the keys, and the creature's own movement shows the timing.

All hints:

- point to something visible in that state;
- say something the player hasn't already been told in the instructions, the descriptions or the earlier hints;
- stay inside the current phase and never mention a later task;
- keep the game's wording for names, places and directions (`write-game-text`);
- add no fact the sources or the author don't support;
- stay within three rows, about 180 characters, *including* the " (click hint again if you're still confused)" suffix that every hint but the last gets.

## 6. Judge existing instructions and hints

When asked to review a puzzle, or when a playtest shows a problem, judge its instruction, the Find line and every phase. Report the result; do **not** change the lines, since changing existing text needs the author's explicit command or confirmed bounds.

### Instructions

- **Enough.** Could a first-time player tell what the task is and reach for the right keys, inferring the rest? It fails when the task or a needed control can't be told from the line or the screen, or when it is padded with what the action already shows.
- **Not revealing.** It fails when it carries the clue or the fix that belongs in the ladder.
- **True.** It fails when a key, count or name differs from the code or the registry, or the line is not an instruction at all (a state description, a reaction).

### Hints

**Helpful.** Does each hint move the player on by pointing to something visible? A hint may be vague about what to do, or slightly tangential; that is not a fault. It fails when:
- it points to nothing the player can see or open in that state;
- it repeats the instructions, a description, feedback, or the hint before it;
- in a fight, it describes what the creature visibly does or says when to press, rather than offering a strategy idea or pointing to something at the edge of the screen;
- the last hint can't be acted on;
- it uses a name that differs from the registry, or a direction that is wrong for where the player is.

**Not too revealing.** Does each hint give away only what its kind allows?
- A `notice` (including the Find line) already says what the clue means, names the target, or says how to solve it.
- An `interpret` already names the move.
- The first hint gives the whole solution.
- A hint gives away a later phase or another puzzle.

**Graded.** Does the ladder fit the phase?
- It is `act` alone, or skips a step a real player hits (for example, straight from `notice` to the answer when the meaning is the hard part).
- Two hints say the same thing at the same level of detail.
- The order is wrong (a more revealing hint comes first).
- The `level` label doesn't match what the line actually does.

Report per puzzle, in a table: instruction or phase (or Find), position, `level`, the current line (short), verdicts (Enough / Not revealing / True for the instruction; Helpful / Revealing / Graded for hints) with the reason, and a proposed fix (a new line, a rung to add or remove, or a design problem to raise). Mark which fixes are wording (Narrative and Audio, with the author's approval) and which need a new phase or a script change (Tech Lead).

## 7. Bring it to the author

- For new text: show the instruction, the Find line and each phase with its rungs and why, and each line with its `level`. Say which visible thing each hint points to, with the source for any fact. Name any rung left out and why, and ask before any `act`-only phase. Name any exception you made to section 1.
- For reviews: show the table. Ask the author which fixes to make, naming the exact lines.
- Ask before writing whenever it's unclear what the player is supposed to work out, which clue is the intended one, which controls the puzzle takes, or whether a phase is meant to be a puzzle at all. Those are design decisions, not wording.

## Checking

1. Every puzzle has an instruction, and it says the task and the keys in general terms without the clue or the fix; any exception was agreed with the author.
2. Every key, count and name in an instruction is true in the code and the registry.
3. Every phase the script can reach has a ladder, and every puzzle has a Find line for every destination the script passes (except Dangers, which has none; a fight with no strategy has no ladder).
4. Each phase has at most three hints in the order `notice`, `interpret`, `act`; any rung left out has a stated reason; no phase is `act` alone without the author's agreement. A fight's hints are only strategy ideas or edge-of-screen cues, never the creature's visible behaviour.
5. Every hint points to something visible in that state; none gives away more than its kind allows; the last can be acted on.
6. No hint repeats the instruction, a description, feedback or the hint before it, and none reaches into another phase or puzzle.
7. Each `interpret` is true to the sources and, for technique, to the mechanic in the code.
8. Each line passes `write-game-text`: at most three rows (hints including the suffix), registry names, correct directions.
9. In the running game, the instruction shows when the puzzle starts, and the phase was reached and Hint pressed repeatedly: each line says more than the last, the suffix shows on every line but the last, and the last repeats.
10. The level's suite and the hints suite pass (`godot --headless --path godot -- --level=<level> --autotest`; `godot --headless --path godot --script res://tests/hint_regressions.gd`), and no test pins the wording.
11. Existing instructions and hints were judged, not changed, unless the author named them.
