---
name: write-game-text
description: How to write text the player sees in the Book of the Dead game (instructions, feedback, success lines, Hint-button hints, descriptions, speech, journal notes and shared messages) in messages.json, puzzles.json and registry.json. Use whenever player-visible text is added or changed.
---

# Writing game text

## Where text lives

All shown text lives in JSON. Scripts only decide when a line appears (GDD §13).

| Text | File |
| --- | --- |
| Shared messages (picking up, walking, View mode) | `godot/assets/messages.json` |
| A level's messages, and each puzzle's `instructions`, `success`, named `feedback` and `hints` | `godot/assets/<level>/puzzles.json` |
| Names, `descriptions` (`default` plus named states), speech and journal settings for figures, objects and captions | `godot/assets/<level>/registry.json` |
| The guide companions' scripted lines | the guide module (Configuration Document §4) |

Never put game text in a script or a scene. Tests compare shown text only against the JSON (AGENTS.md).

## Kinds of text

- **Instructions** give controls and what the task is, as soon as it starts. They never cost a hint.
- **Descriptions** say what the player sees. **Speech** is what a figure says. Either may carry a **clue** that helps the player infer the fix ("The young calf shakes at the sight of the sacrifice."), but never the fix itself ("Turn the calf around.").
- **Feedback** says what went wrong, never how to put it right. The same goes for journal notes.
- **Success** says what is now set right.
- **Hints** come only from the Hint button. Each puzzle has one **Find** line, which says where an unfinished puzzle is. Each phase then has up to three lines, about that one phase: **Notice** points to a detail or someone to consult, **Interpret** gives the relationship to understand, and **Act** says what to do. The last line must be something the player can act on. Don't pad a simple action with extra levels, and don't bring in another task in a later line.

## Rules

- **Length.** One line in the strip is at most three rows, about 180 characters, at 32 px. Lines are never paged, so a longer line must be cut, not split. If a line must run longer because it is a translation or a title, keep it, and flag it to the author: give its id, its file and its length.
- **Every line must be reachable.** Each line belongs to a state or event the game can actually reach, and a script shows it there. Don't write lines for cases that never happen, such as a state the puzzle can't get into, a description variant no script selects, or feedback for a move the game doesn't allow. When a change makes a line unreachable, remove the line or say that it is now unreachable.
- **Keys** are written in brackets: [←] [→], [space], [esc], [j], "hold [shift]".
- **Content only.** Names, descriptions, captions, hints and messages hold only what the player should read. Doubts and source notes go in the entry's `reference` or in `TODO.md`, never in the text.
- **Keep doubt where the sources have it.** If an identification is uncertain, the text stays uncertain ("perhaps", "one of the four sons"). Never state a guess as fact. A claim no source supports is listed in `TODO.md` and softened or cut.
- **Sources.** Every description, caption or translation taken from a source is cited by the `cite-references` skill. When Davis and Allen differ in order, Davis's (Turin) order wins.
- **Voice.** Plain and in the present tense. Address the player as "you" ("You pick up the adze."). A figure the player steers is "he", as in Survival ("He goes headlong."). Descriptions are labelled with the subject's name and speech with the speaker's.
- **Direction.** The scroll is walked right to left: say "walk left" to go on and "back" or "right" to return.
- **Names** match the registry `name` everywhere: in hints, feedback and the journal.
- **Don't reword what you were not asked to.** Text the author wrote stays as it is unless the request is to change it. Show the old and new line when you change one.

## The guide companions

Min, the legged snake and the Ptah-dwarfs follow the voices, knowledge limits and prohibited actions in the Configuration Document §4. Their scripted lines follow the rules above, with two additions. The snake's lines are set apart in their own style, and nothing any companion says enters the journal or the registry.

## Checking

1. Read each new line in the running game at the smallest supported window, in the strip, next to the line before and after it.
2. Count it: three rows or fewer, with no line cut off. List any longer translation or title for the author.
3. For each new id or description state, find the script that shows it and the state that triggers it, and reach that state in the game.
4. For a hint ladder, play the phase and press Hint repeatedly. Each line should say more than the one before, and the last should be actionable.
5. Run the level's suite (`godot --headless --path godot -- --level=<level> --autotest`). A test that pinned the old wording is a test to fix, not a reason to keep the wording (AGENTS.md).
