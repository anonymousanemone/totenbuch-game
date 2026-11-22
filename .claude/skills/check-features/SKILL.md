---
name: check-features
description: How to check that a feature, mechanic or fix in the Book of the Dead game behaves as intended before the author plays it, by sorting every detail into stated, precedent or assumed, testing every clickable thing in every player state, checking text coverage, looking at rendered frames, matching sibling mechanics, and reporting the result. Use before building any gameplay change, and again before handing it back.
---

# Checking features

Most bugs in this game are not crashes. They are small behaviours that don't match what was meant, either because an unstated detail was guessed, or because only the main path was tried. Check the whole surface of a change before the author plays it, so that they review a report instead of finding the bugs by playing.

## Before building

### 1. Sort every detail

Write the change as a list of behaviours: what the player does, what they see and hear, and what text appears. Mark each one:

- **Stated**: the author said it (the request, the GDD, a design spec, `TODO.md`).
- **Precedent**: copied from a named existing mechanic ("snaps while dragging, like the offering table").
- **Assumed**: neither.

When a detail is unstated, copy the nearest sibling mechanic. Don't invent one. Name the sibling.

List any assumption the player would notice for the author **before** building. That covers what can be clicked, where things sit and which way they face, what is interchangeable, whether a target is a point or an area, what an animation does at the end, and what a rule applies to. Build only what you listed, and don't make an exception to the shared behaviours in AGENTS.md without asking.

### 2. Draw the interaction grid

Rows are every clickable thing in the area the change touches: figures, captions, props, the empty strip, and the band's own controls. Columns are each state the player can reach:

- before the puzzle, and inside it;
- holding each item that can be carried, and mid-drag;
- after a wrong move, and after solving;
- after leaving and coming back, and after a restart;
- View mode.

Leave out columns that can't happen, and say so. Each cell gives the expected:

- highlight on hover, or none;
- walk, or none;
- text, by its JSON key, and what the band shows afterwards;
- action: picks up, drops, starts which game, refuses, or nothing.

Write the grid before the code. Every cell becomes a test. A hover cell is tested by hosting the level in a 1280 × 720 `SubViewport` and sending the motion with `push_input`: in the main window the levels read the real cursor, so the step driver and `root.push_input` cannot aim.

## While building

### 3. Text coverage

Check the JSON against the scripts:

- Every registry entry stays readable in every state, including after its puzzle is solved and in View mode.
- Every puzzle has a success line, and it fires.
- Every `feedback` key and description state is shown by some script in a state the game can reach (`write-game-text`).
- No prompt to help or to go somewhere can appear once its puzzle is done.
- A line that depends on where the player is, or on what has been done (in view or far away, in order or not), is tested in each case.
- A line that depends on time or order (delayed lines, lines that expire, lines that queue) is tested for what shows at each moment and what shows once it ends. Test it again after a newer interaction, after leaving and after a restart. No stale line may come back.

Compare shown text only against the JSON (AGENTS.md).

### 4. Look at the result

Numbers don't show a wrong facing or layer. Capture frames at the key states of the grid (`--screenshot=`, `--record=`, `--ui-images=`; see README.md), and read them yourself. Compare them with the plate, or with the frame from before the change. Also test the geometry directly:

- size on screen is unchanged through pick-up, carrying, dragging, placing, cancelling and reset (movable objects in AGENTS.md);
- facing and mirroring are kept;
- each drawing's layer is right against the avatar, props and frame;
- a placed piece lands at its intended pose;
- a target's hit area is the area meant, not a point;
- nothing is clipped at 1280×720, 800×600 or 640×480.

### 5. Match the sibling

For each detail marked precedent, test the shared parameters against the original: snapping while dragging, timings, the ending animation, the green success flash, locking in place, and whether hands-full applies. If the sibling is the same shared code, use it instead of matching it.

### 6. Tuning

Speeds, delays, snap distances and difficulty can't be tested for feel. Put each one in a named constant, and list it in the report with its value. The author tunes it.

## When the author reports a bug

1. Reproduce it with a failing test or an added grid cell before fixing it.
2. If the cause was a general assumption ("hands full applies to everything"), write the rule into this skill or AGENTS.md, so it isn't assumed again.
3. Fix it, rerun the grid for that area, and check the bug's neighbours: the same object in other states, and the same state for other objects.

## Report

Hand back:

- the assumptions you made, and which ones the author answered;
- the grid, with pass or fail for each cell;
- the frames, named by state;
- the tuning constants and their values;
- the commands you ran and their results;
- what is not checked, and why.

## Checking

1. Every behaviour is marked stated, precedent or assumed, and the visible assumptions were shown to the author before building.
2. Every grid cell has a test, and it passes.
3. The text coverage list holds for every id the change touches.
4. The frames for the key states were captured and looked at.
5. Every precedent was compared with its sibling.
6. The suites for the levels touched pass, and every level that uses a changed shared script (`godot/tests/run_tests.py`; only the edited levels otherwise). `walk.gd` serves cosmos, mouth, mounds, hall, prologue and doors; `survival.gd` serves survival and gates; `scroll_camera.gd`, `ui.gd` and `avatar.gd` serve every level.
7. The change was played once in the running game, not only headless.
