# Totenbuch: Game Design Document

**Status: Initial (G1).** Version 0.2, 2026-11-19 (0.1 was 2026-11-17; 0.2 corrects the level list, hints, audio, delivery and agent scope against the repo and the decisions of 2026-11-18). Owner: Sophia (Design Lead, with Creative Director approval). Gate Approver: instructor.

Tags: **[Built]** exists in the repo, **[Proposed]** intended but not built, **[Open]** undecided, see Section 16. Nothing here is marked *verified* yet: the existing test suites (`python3 godot/tests/run_tests.py`) cover rule integrity, not whether players enjoy or understand the game.

## 1. The X

Our game is a point-and-click walk along Lepsius's *Todtenbuch* papyrus (1842), where the player restores each scene of the scroll by looking closely at its drawn figures and putting right what is wrong. **[Built, partly]**

## 2. Player and intended experience

- **Player:** a curious adult or student who likes learning about history but wants a more engaging method; no knowledge of Egyptology assumed. Playtesters: classmates and friends.
- **Intended experience:** the quiet pleasure of noticing. Figures are drawn wrongly or incompletely (a man holds a loaf instead of his goose), and the player works out what is wrong from the drawing alone.
- **Motivation (Maslow / SDT):** esteem and self-actualization (mastery and understanding of an unfamiliar artefact). Competence: a puzzle solved by spotting. Autonomy: free walking and choice of order within a level. 
- **Hypothesis to test:** players who look at figures before acting (clicking to read, then fixing) will solve levels without the hint. Observable: first click goes to a figure, not to a piece.
- **Agent hypothesis (Min against Hint-only):** Configuration Document Section 4.

## 3. Genre, platform, tools

- Genre: point-and-click puzzle / exploration, with short skill minigames (rhythm, fighting, catching). **[Built]**
- Platform: desktop, Godot 4.7+ (GDScript), 1280 × 720 viewport. **[Built]** Release: web export (decided 2026-11-18). Build for playtesters: **[Open]** (Section 16, Q4).
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
| Hint | Repeatable; each press gives the next authored hint for the puzzle's current step (up to notice, interpret, act), or says where to go **[Built]**. A selector to choose the level (Hint 1, 2, 3) is drafted in `mockups/hint-level-selector.html`, not built **[Proposed]** |
| Esc | Leave a scene or minigame |
| Enter / Space | Advance intro or outro |

Dialogue: 32 px, never paged, three lines at most (~180 characters), in the bottom strip. Ordinary messages fade after five seconds of active play; a dragged piece's description holds through the drag, then three seconds; instructions stay until the task changes. Minigame view fixes the camera until the minigame ends (`AGENTS.md`).

## 7. Levels and content scope

Eighteen level cards on the map, in six acts and a prologue (`Scroll.SCENES`, `godot/scenes/scroll.tscn`). Eleven have a scene; seven do not and are skipped when the player moves on.

| Act | Card (spells) | State |
|---|---|---|
| Prologue | Guarding the Body (151–154) | **[Built]** to walk: five stages, each done at its left wall. Lessons not built |
| I | Funeral Procession (1–15) | **[Built]** puzzles: eight rites (haul, standards, offering table, goose, water, bulls, opening of the mouth, offering stand) |
| I | Night Journey (17) | **[Built]** to walk and read |
| I | The Councils (18) | not built |
| I | Mouth and Heart (21–30) | **[Built]** to walk and read |
| II | Dangers on the Road (31–42) | **[Built]** fights for 31–41; 42 is text only |
| II | Survival and Sustenance (43–63) | **[Built]** puzzles and minigames |
| III | Coming Forth by Day (64–75), Transformations (76–88), Ba and Tomb (89–92), Thoth and the Boats (93–109) | not built |
| IV | Field of Offerings (110) | **[Built]** to walk and read |
| IV | Souls of the Towns (112–124) | not built |
| V | Lake of Fire (126–143) | not built |
| V | The Gates (144–146) | **[Built]** to walk and read; the plumes answer a named god; the naming puzzle is not built |
| V | Fourteen Mounds (149) | **[Built]** to walk and read |
| VI | Thoth Opens the Sky (161) | **[Built]** to walk; the door opens as you come to it |
| VI | Weighing of the Heart (125) | **[Built]** to walk and read; its puzzles are in `archive/` |

Three levels carry puzzles or minigames (Procession, Dangers, Survival); eight are walk-and-read or walk-only. **[Proposed]**: puzzles for the walk-and-read levels, the seven cows (148) and the amulets (155–160), which are not on the map. The strange creatures (162–165) are off the map; as guides they belong to the optional agent module (Q2). What each built level plays: `.claude/skills/suggest-games/levels.md`. Catalogue of ideas: `ideas.md`.

**Scope for G2:** the first playable is the existing Procession with one in-game companion, Min (decided 2026-11-18); no new level is built for G2. The snake and the Ptah-dwarfs are outside G2 and G3. Which levels get puzzles and which unbuilt cards stay on the map is locked at G3.

## 8. Dynamics, progression, balance

- Levels open in scroll order on the map: the next unfinished built level, plus every restored one; unbuilt cards are skipped. Viewing a restored level (View mode) is read-only. Debug builds open every built level. **[Built]**
- Difficulty targets are set per level on a skill/creativity ratio, approved in `ideas.md`: Procession 25/75, Dangers 80/20, Survival 50/50, Ba/Thoth/boats 20/80, Gates 90/10 (its naming game is not built). The Prologue, Night Journey and Field of Offerings have none yet. **[Proposed]** The ratios are design intent only; they are not stored in the game data (`TODO.md`). Tuning constants live in code (`BEAT`, `WINDOW`, `PULLS`). **[Built]**
- Hints: an authored ladder per puzzle step (notice, interpret, act; most steps have one or two levels) and a line saying where to go. **[Built]** Choosing the level and Hint's place next to Min are in Section 6 and Q2.

## 9. Win, failure, scoring

- A level is won when its puzzles are restored; the figures and strip show it (no counter, except beetle pips in 36 and the Journal's per-spell counts when the ankh is carried in Dangers). **[Built]**
- Failure is soft: wrong placements return; fights and rhythm have retry. **[Built]**
- No score. Evidence collected is meant to count at the Weighing (125). **[Open]** how.

## 10. Feedback and aesthetics

Papyrus palette, Old Fax font, glow on clickable things, faint green success flash, reactive figures. Journal notes say what is wrong, never how to fix it. **[Built]** Audio: only the haul's drum and pull tones (synthesised in `haul.gd`); a Sound volume setting (0–10) in Settings. No music or other effects yet. **[Open]** (Q6)

## 11. Edge cases and rules

Reload mid-level, Esc during a minigame, dragging a locked piece, window resize (camera must not refit in minigame view), View mode with puzzles off. Covered by regression suites in `godot/tests/`. **[Built]** Edge cases of any new level are listed in its plan task.

## 12. References and attribution

- Lepsius, *Das Todtenbuch der Ägypter* (1842): plates, the Turin papyrus of Iufankh. Source scan in `references/lepsius_todtenbuch.pdf`.
- C. H. S. Davis, *The Egyptian Book of the Dead* (1894): translations of captions.
- Citation rules: `.claude/skills/cite-references`. Unsourced details are tracked in `TODO.md`. **[Open]** reuse terms of the scan source (Section 16, Q5).

## 13. Systems and boundaries

Data (`registry.json`, `puzzles.json`, `messages.json`) holds all shown text; scripts decide when it appears; scenes hold the art. Tests may compare text only against the JSON. No network access in the release build. **[Built]** For G2 only, the study build may reach a live model through the module's Cloud Run proxy (Configuration Document Section 4), under the author's control, with scripted Min lines as the fallback and as the candidate release form. **[Proposed]** The module does not exist in the repo yet (no `godot/guides/`).

## 14. Not in scope

New artwork drawn from scratch; procedural levels; multiplayer.

## 15. Playtest plan (Initial)

Question: do players look before acting? Method: observe one external player per build on a level they have not seen, think-aloud, no coaching. Record in the Playtest Log. **[Proposed]** For G2, compare Procession with Min offered against Hint-only (Configuration Document Section 4). Tools: the `playtest` skill and the step driver for cold-tester runs **[Built]**; gameplay logging for observed sessions is planned, not built (`.turbo/plans/gameplay-logging.md`). No external player has played the current build; the two earlier playtests (2026-10-15, 2026-11-07) were one player each, on difficulty and pace (`risk.md`).

## 16. Open questions

1. ~~Which level or rework is the G2 first playable?~~ **Decided 2026-11-18:** the existing Procession, carrying Min. No new level for G2.
2. **In-game agent.** Decided scope: one companion, Min (165), in Procession only, for G2 and G3; the player picks Min or none, he follows them and speaks a short line when clicked, and the Hint button stays for now. Hint's availability in the release is left undecided by the author. Min knows the future and fusses over the Negative Confession (Configuration Document Section 4). The legged snake (163, the present) and the Ptah-dwarfs (164, the past) are designed but outside G2 and G3, as are typed questions and other levels. The rest of this document describes the game without the module. Not built yet.
3. **Relatedness.** Does the game need anything that delivers it?
4. **Delivery:** release is a web export (decided 2026-11-18). Open: the build playtesters run, and whether a second person can run it (plan task 17).
5. **Reuse terms** for the Lepsius scan and Davis text (public domain status to confirm and cite).
6. **Audio:** only the haul's synthesised tones exist (Section 10). Planned: background music the player can turn off, and sound effects. How to make and add sound will be written as a skill once the first sounds are in the game. **[Proposed]**
7. **Weighing of the Heart:** how earlier evidence is counted. Its puzzles are in `archive/`.
