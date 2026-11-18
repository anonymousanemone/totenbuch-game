---
name: playtest
description: How to playtest a level of the Book of the Dead game as a first-time player, with a tester that knows only what is on screen, asking at each step whether it knows what to do, how it would know, whether something is done, and whether it is taking too long, then explaining each confusion and bringing the author only the decisions that need them. Use after check-features passes, or when the author asks for a playtest of a level, puzzle or text change.
---

# Playtesting

`check-features` asks whether the game does what was meant. This skill asks whether a player can tell what was meant: what to do, how they would know, whether it worked, and whether it is done. It covers text, guidance, feedback and pacing. It does not judge speed, dexterity or difficulty of execution; those are tuning constants (`check-features` step 6).

## The tester knows only the screen

Whoever has read the code, the JSON or the design docs already knows the answers and can't be confused like a player. So the play is done by a fresh subagent, the tester, which comes in completely cold. It is not told the game's name, subject, levels or puzzles. It gets only:

- the rendered frames;
- the band text as displayed, with the moment it appeared and the moment it cleared;
- the driver's actions: click, drag, hover, wait, and the band's own controls.

Its brief says: you are playing an unknown game for the first time, think aloud, and stop when you would give up or when you believe you are done. Never pass it file contents, ids, JSON keys or hints from earlier runs. You, the main agent, keep the design knowledge and use it only after the run.

## The driver

The launch flags (`--screenshot=`, `--record=`, `--autotest`) can't take one action, return a frame and wait for the next. If no step driver exists yet, build one under `godot/tests/`: it keeps the game running, takes one action at a time, and returns a frame plus the band text with timings. Time passes only when an action or a wait says so, so pacing can be measured. Document it in README.md. Reuse it for every later playtest.

## Players

Run each as its own tester, since each finds different problems:

- **Reader**: reads every line, then does what it says.
- **Skimmer**: ignores the text and acts on the art alone. The game is meant to be played by looking (`suggest-games`), and this tests that.
- **Clicker**: clicks everything in sight before trying anything purposeful.
- **Wrong-first**: does the plausible wrong thing first: the nearest figure, the obvious drag.
- **Returner**: leaves mid-puzzle, does something else, then comes back and works out what is left.

For a small change, the reader and one other are enough. Say which were run.

## What the tester asks at every step

After each action it logs what it sees, what it thinks it should do and why, what it did, what happened, whether that matched what it expected, and any of these questions that came up:

**Orientation.** Where am I? What can I interact with? Does this look clickable or draggable? Is this a puzzle or scenery?

**Goal.** What am I supposed to do now? What is the goal here, and is there one? The instruction is gone; what did it say? Is it about what's in front of me, or somewhere else?

**Knowledge.** How am I supposed to know that? Where did the game tell me? Was it still on screen when I needed it? Did I solve that, or get lucky? Is this word or name explained anywhere I can see? Does the hint tell me something new, or repeat the instruction?

**Feedback.** Did my click do anything? Was that wrong, not allowed, or not yet possible, and can I tell which? Why was it refused, and does the refusal say what to do instead? What changed, and can I see it or only read it?

**Completion.** Is this done or not? Is it partly done, and how much is left? Can I leave, and do I lose progress if I do? Is there anything else here? Did the success moment register?

**Pacing.** This is taking too long. I'm waiting with nothing to do: is it busy or stuck? The text vanished before I finished reading it. Too many lines came at once, or one replaced another. The same line keeps repeating. I walked a long way for something small. An animation is blocking me. Nothing new has happened in a while.

**Memory.** What was I doing? What am I holding? Coming back, do I know what is left? Does the journal or HUD agree with what I remember doing?

**Motivation.** Why would I want to do this? Did solving it feel acknowledged, or did the game just move on?

### Puzzles where figuring it out is the point

Here, not knowing the answer is intended, so the tester asks whether it is fair instead of whether it was told:

- Can the answer be worked out from what is on screen, without outside knowledge?
- Is there a path of reasoning, or only trial and error? If only trial and error, how many combinations are there?
- Did a wrong attempt teach me anything? Can I tell I'm getting closer?
- Is it clear what kind of answer is wanted (an order, a match, a placement), even if the answer itself isn't?
- Do the hints go from a nudge to the answer, or jump straight to it?
- After solving: "of course", or "huh"?

These are judgments for the author, not defects.

## Rescues

If the tester would give up, don't end the run. Give it the smallest nudge that gets it moving ("try the figure on the left"), log it as a rescue, and continue, so one stuck point doesn't hide everything after it. Every rescue is a **stuck** finding.

## Measures

For each run:

- actions before the first one that did something;
- clicks that did nothing, and repeated attempts at the same thing;
- time and actions to solve each puzzle;
- dead time, when no input is possible and nothing new happens;
- for each line, how long it was on screen against its reading time (about 4 words a second, plus a second). This matters most when the band runs on a timer.

## After the run: explain each finding

Now open the design (`puzzles.json`, `messages.json`, the GDD, the scripts). For each question the tester raised, give:

- **severity**: *stuck* (can't go on without outside knowledge, or rescued), *confused* (recovered by guessing), *friction* (knew what to do but it was slow or repetitive), *note*;
- **cause**: missing text, text gone too soon, text that names something not visible, art that doesn't look interactive, a refusal that doesn't explain, no completion signal, pacing;
- **whether it was intended**: a discovery puzzle meant to puzzle, or not;
- **a suggested fix**, which you don't apply.

Group repeated findings into one, with each moment listed.

## The author in the loop

The author should not need to read the logs. Everything they see comes in two lists, and the logs are saved to a file and only linked.

### Asked: decisions only the author can make

Bring these with `AskUserQuestion`, at most four at once, most severe first, each standing on its own: the moment (with its frame), what the tester did and said, the cause, and the choices with your recommendation first.

- Every **stuck** finding: which fix, or whether it is intended.
- Every fairness judgment on a discovery puzzle.
- Any finding where the intent is unclear: confusion that might be the point.
- Any fix that would change design, not only wording or timing: a new hint, a new visual signal, a change to what can be clicked.
- A finding that contradicts something the author stated. Name the statement.

Stop before starting a run only when the scope is unclear (which level, which puzzles). Don't ask whether to build the driver or which players to run; choose and say so.

### Told: decisions you made yourself

Report these in a short list, so the author can overrule any of them:

- which players were run and which were skipped, and why;
- each rescue, and the nudge given;
- each severity you set below stuck;
- findings you merged, or dropped as tester artefacts, with the reason;
- anything the tester may have known that a real player wouldn't, and anything only a human could judge.

### Not done without an answer

Apply no fix from a playtest until the author answers. Then text changes go through `write-game-text`, behaviour changes through `check-features`, and the affected part is played again by a new cold tester, never the one that already knows the answer.

## Checking

1. The tester was a fresh subagent and was never given file contents, ids or design knowledge.
2. The players run, and the ones skipped, are named.
3. Every rescue is logged and counted as stuck.
4. Every question the tester raised has a severity, a cause and a suggested fix.
5. Every stuck finding, fairness judgment, unclear intent and design-level fix was asked; everything else you decided is in the told list.
6. The full logs and frames are saved and linked, not pasted.
7. Nothing was changed without the author's answer, and every fix was replayed by a new cold tester.
