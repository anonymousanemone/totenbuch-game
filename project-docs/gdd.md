# Totenbuch: Game Design Document

**Status: Initial (G1).** Version 0.1, 2026-11-17. Owner: Sophia (Design Lead, with Creative Director approval). Gate Approver: instructor.

Tags: **[Built]** exists in the repo, **[Proposed]** intended but not built, **[Open]** undecided, see Section 16. Nothing here is marked *verified* yet: the existing test suites (`python3 godot/tests/run_tests.py`) cover rule integrity, not whether players enjoy or understand the game.

## 1. The X

Our game is a point-and-click walk along Lepsius's *Todtenbuch* papyrus (1842), where the player restores each scene of the scroll by looking closely at its drawn figures and putting right what is wrong. **[Built, partly]**

## 2. Player and intended experience

- **Player:** a curious adult or student who likes learning about history but wants a more engaging method; no knowledge of Egyptology assumed. Playtesters: classmates and friends.
- **Intended experience:** the quiet pleasure of noticing. Figures are drawn wrongly or incompletely (a man holds a loaf instead of his goose), and the player works out what is wrong from the drawing alone.
- **Motivation (Maslow / SDT):** esteem and self-actualization (mastery and understanding of an unfamiliar artefact). Competence: a puzzle solved by spotting. Autonomy: free walking and choice of order within a level. 
- **Hypothesis to test:** players who look at figures before acting (clicking to read, then fixing) will solve levels without the hint. Observable: first click goes to a figure, not to a piece.

## 3. Genre, platform, tools

- Genre: point-and-click puzzle / exploration, with short skill minigames (rhythm, fighting, catching). **[Built]**
- Platform: desktop, Godot 4.7+ (GDScript), 1280 × 720 viewport. **[Built]** Web or packaged build for playtesters: **[Open]** (Section 16).
- Source art: Lepsius plate scans, 300 dpi, spliced and cut, never redrawn (`.claude/skills/splice-plates`, `.claude/skills/make-artwork`). UI art matches the Old Fax pixel font.

## 4. Core loop **[Built]**

The player walks the scroll (right to left) and clicks a figure or caption; the game glows it, records it in the journal and shows a description or translation; the player notices what is wrong or what a figure asks for and acts (drag a piece, time a pull, fight, match); the scene reacts and shows progress in the picture; the next scene opens.

## 5. Pillars

1. **Nothing is redrawn.** Every figure comes from the plates; puzzles reuse what is drawn.
2. **Learn once, recall later.** What a level teaches comes back in a later level (`ideas.md`, "What each level teaches").
3. **The end is the Weighing of the Heart (125).** Earlier scenes give evidence used at the scale.

## 6. Mechanics and controls **[Built]**

| Input | Effect |
|---|---|
| Click papyrus / ← → | Walk the avatar along the scroll |
| Click figure or caption | Glow, journal entry, description or translation |
| Press-drag-release | Move a piece; only valid placements stay, others return (`moveable_object.gd`) |
| Space / Shift / click | Beat actions (haul, pull) |
| `j` | Journal |
| Hint | Repeatable; says more each press **[Proposed]** (currently one full solution) |
| Esc | Leave a scene or minigame |
| Enter / Space | Advance intro or outro |

Dialogue: 32 px, never paged, three lines at most (~180 characters), in the bottom strip. Minigame view fixes the camera until the minigame ends (`AGENTS.md`).

## 7. Levels and content scope

Twenty-one level cards on the map, grouped by act (`godot/scenes/scroll.tscn`). **[Built]** with puzzles: Procession (1–15), Dangers (31–42), Survival and Sustenance (43–63), Gates (144–146). **[Built]** to walk and read: Night Journey (cosmos), Field of Offerings (110), Mouth and Heart, Weighing of the Heart; the Fourteen Mounds (149) has a scene and assets (its play status to confirm). **[Proposed]**: puzzles for the walk-and-read levels, plus the seven cows (148) and amulets (155–160). The strange creatures (163–165) are not a level; they are the guides of the optional agent module (Q2). What each built level plays: `.claude/skills/suggest-games/levels.md`. Catalogue of ideas: `ideas.md`.

**Scope for G1 (to be locked at G3):** the five built levels stay; the plan's G2 investigation picks one unbuilt level or one rework (Section 16, Q1).

## 8. Dynamics, progression, balance

- Levels open in scroll order on the map; viewing a restored level (View mode) is read-only. **[Built]**
- Difficulty is set per level on a skill/creativity ratio (Procession 25/75, Dangers 80/20, Survival 50/50, Gates 90/10). **[Built]** Tuning constants live in code (`BEAT`, `WINDOW`, `PULLS`).
- Hints: graded (where, what, how). **[Proposed]**

## 9. Win, failure, scoring

- A level is won when its puzzles are restored; the figures and strip show it (no counter, except beetle pips in 36). **[Built]**
- Failure is soft: wrong placements return; fights and rhythm have retry. **[Built]**
- No score. Evidence collected is meant to count at the Weighing (125). **[Open]** how.

## 10. Feedback and aesthetics

Papyrus palette, Old Fax font, glow on clickable things, faint green success flash, reactive figures. Journal notes say what is wrong, never how to fix it. **[Built]** Audio: none yet. **[Open]**

## 11. Edge cases and rules

Reload mid-level, Esc during a minigame, dragging a locked piece, window resize (camera must not refit in minigame view), View mode with puzzles off. Covered by regression suites in `godot/tests/`. **[Built]** Edge cases of any new level are listed in its plan task.

## 12. References and attribution

- Lepsius, *Das Todtenbuch der Ägypter* (1842): plates, the Turin papyrus of Iufankh. Source scan in `tools/lepsius_todtenbuch.pdf`.
- C. H. S. Davis, *The Egyptian Book of the Dead* (1894): translations of captions.
- Citation rules: `.claude/skills/cite-references`. Unsourced details are tracked in `TODO.md`. **[Open]** reuse terms of the scan source (Section 16, Q5).

## 13. Systems and boundaries

Data (`registry.json`, `puzzles.json`, `messages.json`) holds all shown text; scripts decide when it appears; scenes hold the art. Tests may compare text only against the JSON. No network access in the release build. **[Built]** The prototype build with the guide module reaches only the module's Cloud Run proxy (Configuration Document Section 4). **[Proposed]**

## 14. Not in scope

New artwork drawn from scratch; procedural levels; multiplayer.

## 15. Playtest plan (Initial)

Question: do players look before acting? Method: observe one external player per build on a level they have not seen, think-aloud, no coaching. Record in the Playtest Log. **[Proposed]**

## 16. Open questions

1. **Which level or rework is the G2 first playable?** (Candidates: seven cows 148, amulets 155–160, Fourteen Mounds 149, or deepening a built level.)
2. **In-game agent.** Proposed: an optional, removable guide module in which the player picks one companion (or none) at the start of each level, who follows them and speaks when clicked. The three companions each know only one tense and are each partly wrong: Min (165) knows the future and fusses over the Negative Confession, the legged snake (163) knows the present and is snarky and often wrong, and the Ptah-dwarfs (164) know the past (Configuration Document Section 4). The rest of this document describes the game without it. The G2 prototype carries Min only.
3. **Relatedness.** Does the game need anything that delivers it?
4. **Delivery:** packaged desktop build or web export for playtesters and release?
5. **Reuse terms** for the Lepsius scan and Davis text (public domain status to confirm and cite).
6. **Audio:** planned: background music the player can turn off, and sound effects. How to make and add sound will be written as a skill once the first sounds are in the game. **[Proposed]**
7. **Weighing of the Heart:** how earlier evidence is counted. Its puzzles are in `archive/`.
