# Decision log

Who decided what, session by session: the author's decisions, what was made from them, and what agents did. Kept by the `log-decisions` skill; newest at the bottom.

*Entries from 2026-10-15 to 2026-11-18 were backfilled on 2026-11-18 from transcripts (Oct entries per day). Only files a transcript shows are listed, so commits with no transcript (e.g. prologue, thoth level) are not here.*

## 2026-10-15 · Procession sprite sheets, dangers fight frames, ideas trim
- **Decided:** water-jar man gets extra swivel frames, driver the default count; sheets are hand-edited and never remade; cutter works partially, cutting only what is necessary.
- **Decided:** fight panels share one render (double lines at screen edge, fixed text size, tag names the danger, not "scribe"); beetles 5; keep `FRAME_FROM_TOP`.
- **Decided:** unresolved TODO notes to top, boring/redesign notes copied to `ideas.md`; trimmed councils, mouth and heart, coming forth by day, adoring figure, four floors, sacred towns, guarding the body, amulets, adorning baboons; transformations and ba/body tentative.
- **Decided:** three items attach to the avatar then go on the stand; clicking the ox driver walks to the hauler then fades into his pose; build the cow game and the plumes level from the updated .mdp; don't do "my call" items.
- **Made:** `tools/arm_sheets.py`, `tools/cut_procession300.py`, `godot/scripts/bulls.gd`, `godot/TODO.md`; memory notes `sprite-sheets-hand-edited.md`, `partial-cuts.md`.

## 2026-10-17 · Cosmos figure export, procession todo
- **Decided:** export cosmos `figures` from `art/cosmos.mdp` to PNGs with a `level.json` entry per layer, identified by looking ("layer names are usually wrong"); do the Procession TODO items.
- **Made:** `tools/cut_cosmos_figures.py`.

## 2026-10-20 · Spell 41 sheaf strike, spell 35 snakes, dangers text tone
- **Decided:** cosmos figures researched and cited first; Nut label and descriptions approved, .mdp untouched.
- **Decided:** spell 41 is striking the wiggling band, not binding: wrong band bites, five strikes with the last at the top, hard mode bites for not striking; spearer leans and moves up/down; lean sheets first, wired in after.
- **Decided:** spell 35 snakes come from both sides, no red snakes, at most five on screen, tail shake is the tell, faster than crocodiles; dangers avatar reprocessed transparent with correct ground.
- **Decided:** dangers instructions get a snarky/slightly funny tone, edited line by line.
- **Made:** `godot/scripts/dangers/` (`sheaf.gd`, `creeping_snake.gd`, `crocodiles.gd`, `danger_encounters.gd`, `snake_tail.gdshader`), `tools/spearer_lean.py`, `godot/assets/dangers/puzzles.json`.
- **Corrected:** agent assumed crocodiles are hit only at the snout in instructions and code comments; they are not snout-only.

## 2026-10-22 · Gates cuts and registry, descriptions check
- **Decided:** survival/sustenance and cosmos descriptions checked against research, captions from Davis, no "Spell N:" prefix, unsure ones flagged; gates 144–146 registry: each adoring figure, standing god, gate alone, god-in-gate as one entity.
- **Decided:** `gates146.mdp` and `gates144-145.mdp` cut into layers per scene, nothing deleted (flattened pixels identical); 145 structure top on its own layer; chose items 1 and 4 of the animation suggestions.
- **Decided:** gates avatar is a duplicate of the first adoring figure in 145, adorers hidden until each god is named; survival avatar is the first figure in the scroll; "specialtext" layer added to gate 144.
- **Made:** `godot/scripts/gates/gates.gd`, `plumes.gd`, `plumes.gdshader`, `tools/build_gates_scene.py`, `ideas.md`.

## 2026-10-25 · Dangers feedback trim and TODO triage
- **Decided:** trim mid-fight feedback; permanent losses stay and every attempt is treated as a first time; remove "N more hits" (flag missing counts); retries become "You back out of the fight. %s awaits your next visit."; movement lesson removed; kept `next_wave` removal and the first-strike lines.
- **Decided:** two long-scene snakes flash and give a vague click hint that doesn't reveal which snake strikes; blocking moves before the man; after dangers the breath sign grows and wipes into the next level; missing messages and open issues go to the author as choice boxes.
- **Made:** `godot/assets/dangers/puzzles.json`, `godot/scripts/dangers/crocodiles.gd`, `dangers.gd`, `godot/TODO.md`.

## 2026-11-05 · Strip layouts mockup
- **Decided:** `mockups/docked-strip.html` deleted as redundant; inset box render improved; options a–d removed, in-game option tagged a; journal and hint icons use the game's current ones, smaller on the top bar; mockup only, no Godot edits unless asked.
- **Made:** `mockups/strip-layouts.html`.
- **Corrected:** agent redrew the journal and hint icons in the mockup; mockups must use the game's current icon art, and mockup sessions never touch Godot.

## 2026-11-05 · Pixel boxes mockup
- **Decided:** no second tag or feedback section; three tag colours (red, ochre, green) above the standalone box on plain papyrus, with the in-game top bar and restart/menu icons; boxes at game scale; unselected items get a faint shadow, not lightened.
- **Made:** `mockups/pixel-boxes.html`.

## 2026-11-05 · Scribe box border mockups
- **Decided:** several border styles drawn pixel-exact to the papyrus art; stars toned down, yellow bands 2 px yellow/1 px brown with no shading and narrower; extra muted band; icon and vertical bar removed from boxes; borders 1–11 reordered and trimmed (3, 8 removed).
- **Decided:** minimum-unit border tiles in one transparent sheet; the lotus and 3–8 top borders added to it; journal and hint top-bar icons sized to match restart/menu (interrupted).
- **Made:** `mockups/pixel-boxes.html`, `mockups/border-tiles.png`; `mockups/papyrus-borders.html` deleted.

## 2026-11-13 · Node naming across scenes
- **Decided:** one naming scheme across scenes (README Naming section), Arabic numerals, `Strip/Strip146_147` and `Strip/Strip144_145`; papyrus locked in every scene; conventions and lock added to `build-levels`.
- **Made:** renamed nodes in `godot/scenes/` (cosmos, field, gates, dangers, procession), `tools/build_scene.py`, `README.md`, `godot/assets/field/level.json`, `skills/build-levels/SKILL.md`.

## 2026-11-17 · In-game guide agent design and GDF docs
- **Decided:** agent playtester scrapped for an in-game guide/hint module on the strange creatures, with personalities, removable and export-excludable, on cheap Vertex Gemini Flash-Lite; no strong model.
- **Decided:** hallucination rules written out; no "I don't know" for the trickster; risk profile/register written; first prototype is one agent, later the fretter only; latency "unknown" with a timeout; agent hypothesis added; risk 6 removed.
- **Decided:** agents replaced by Min (future, fusses over the Negative Confession, random unfinished item, never calms, fretting rises as items finish), the snake and the Ptah-dwarfs; guides don't use hint text (interaction TBD); creatures aren't a level; `deck.md` added.
- **Made:** `project-docs/configuration.md`, `risk.md`, `gdd.md`, `deck.md`, `assets/systems-diagram.svg`.

## 2026-11-17 · Guide companions: three agents
- **Decided:** discard the accurate/trickster/recaller roles; each companion is faulty with pros and cons, defined by what it knows; Min knows the future and frets over the Negative Confession, the snake only the present (irritable, snarky, often wrong), the Ptah-dwarfs only the past; no eyes; "look, don't read" removed where it refers to player experience.
- **Decided:** at the start of each level the player picks a companion (or none), who follows them and speaks when clicked.
- **Made:** `project-docs/configuration.md`, `gdd.md`, `plan.md`, `risk.md`.


## 2026-11-18 · Art, narrative and tools into skills
- **Decided:** `splice-plates` also cuts figures into layers (nothing deleted, per spell, captions included, bottom text folder), only on the author's command; `draft-ui` skill with HTML drafts straight into `mockups/`; exceptions only with explicit approval; guide companions' look approved; release as web export; `text_below.py` deleted.
- **Decided:** tools used by one skill move into it (builders, `extract_*`, `build_scroll_map.py` to `build-levels`; `sheets.py` to `make-artwork`); `mdp.py` and `write_mdp.py` stay; `tools/` tracked.
- **Decided:** generated animations are never rebuilt without explicit request; Procession exporter stops rewriting haul_driver/water_priest body/arm, Dangers export stops rebuilding bundle 41.
- **Decided:** `write-game-text` skill (voice "you / he", 3-line limit with flags, every line reachable); no audio skill until audio exists; GDD, configuration, style guide, asset list and AGENTS.md updated; art-review left for later.
- **Made:** `.claude/skills/draft-ui/`, `write-game-text/`, `splice-plates/`, `make-artwork/`, `build-levels/` (moved scripts, commit `e3e3788`), `project-docs/style-guide.md`, `asset-list.md`, `AGENTS.md`.
- **Corrected:** agent treated `spearers.py` as part of the Dangers build; it only generates sheets, which are hand-edited afterwards.
- **Corrected:** agent called the four Procession images done and missed Dangers bundle 41; they are stable, not done, and neither is rebuilt automatically.
- **Corrected:** agent wrote an `add-sound` skill before any audio exists; audio skills wait until there are patterns to learn from.

## 2026-11-18 · Tech Lead skills: check-features, playtest, log-decisions
- **Decided:** playtest tester comes in completely cold; a step driver is allowed if needed; name "playtest".
- **Decided:** the author is asked about important decisions and told about the rest, without reading logs; this log replaces transcripts and records only decisions and built work, not suggestions, open items or questions.
- **Made:** `.claude/skills/check-features/`, `.claude/skills/playtest/`, `.claude/skills/log-decisions/`, `project-docs/decision-log.md`; `AGENTS.md` rule to run log-decisions every session, and the three skills listed in `AGENTS.md` and `project-docs/configuration.md`. Not committed.
- **Agent did:** sorted TODO.md bug history into the check-features steps; chose the five playtest player types and the asked/told split.
- **Corrected:** agent planned the Tech Lead as a subagent with a work queue; it is skills like Art and Narrative, with no queue yet.
- **Corrected:** agent leaned on existing docs and code as authority; they are unreliable, and only the GDF info document is.

## 2026-11-18 · decision-log backfill
- **Decided:** backfill sessions from Oct 15, per day for Oct and per session from Nov 5; insert above the 2026-11-18 Tech Lead entry; skip the image-tools, Codex-review and plan-only sessions; list only files transcripts show.
- **Made:** backfilled entries in `project-docs/decision-log.md` (2026-10-15 to 2026-11-18).
- **Agent did:** logged by local time (EDT/EST); Oct entries use the start date of sessions that ran past midnight; commits with no transcript left out.
- **Decided:** **Corrected** lines hold only wrong assumptions or decisions, stated as what was wrong and what is true; no quotes, redo requests or tweaks; log entries fixed and `log-decisions` updated.
- **Made:** `.claude/skills/log-decisions/SKILL.md` (Corrected rule and check 5); **Corrected** lines in the backfilled and Tech Lead entries rewritten or dropped.
- **Corrected:** agent logged redo requests and quoted the author under Corrected; those lines said nothing about what was wrong.
- **Note:** the 2026-11-18 Tech Lead entry says "Not committed"; it was committed in `cfdbd5b`.

## 2026-11-18 · hint level selector draft
- **Decided:** make a `/draft-ui` mockup comparing the plan's two layouts, bottom band and modal (`.turbo/plans/hint-level-selector.md`).
- **Made:** `mockups/hint-level-selector.html` (A today, B bottom band, C modal; five real-text cases; 1280 × 720 and 640 × 480).
- **Agent did:** captured Procession and Dangers screenshots from a patched copy of `godot/` outside the repo; added switches for band and modal text size, choice label size and what the modal covers; Hint icon closes an open selector; band text defaults to 24 px.
