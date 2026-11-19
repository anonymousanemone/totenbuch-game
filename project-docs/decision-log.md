# Decision log

Who decided what, session by session: the author's decisions, what was made from them, and what agents did. Kept by the `log-decisions` skill; newest at the bottom.

*Entries from 2026-10-15 to 2026-11-18 were backfilled on 2026-11-18 from transcripts (Oct entries per day). Only files a transcript shows are listed, so commits with no transcript (e.g. prologue, thoth level) are not here.*

## 2026-10-13 · Script cleanup and source artwork
- **Decided:** Refactor without changing gameplay. Recut Cosmos, Field and Judgment into one sprites folder each and preserve the full-size artwork with separate cleaned backgrounds.
- **Decided:** Add 6-pixel outer guidelines with 8-pixel gaps over the existing Field and Judgment borders.
- **Made:** Commit `0441ab6` and `art/cosmo17-21.mdp`, `art/bod110.mdp` and `art/bod125.mdp`.
- **Agent did:** Extracted shared camera and mask helpers and separated encounter definitions and snake state.
- **Corrected:** The agent cut pixels from original layers. The manually rotated originals had to be restored pixel-for-pixel alongside the separate cutouts.

## 2026-10-14 · Minigame entrances and HUD audit
- **Decided:** The bier directs players to the ox driver, who introduces hauling. The avatar takes the original hauler’s pose during play.
- **Decided:** Highlight all eight standards together and frame sorting from the nearer end. Arrow keys leave hauling or sorting. Dangers waits for Space.
- **Decided:** Apply gravity to offerings on both registers and use smaller, closer flesh signs. Approved trimming repeated feedback while retaining controls and failure cues.
- **Made:** `godot/TODO.md`, `godot/scripts/` and `godot/tests/ui_regressions.gd`.
- **Agent did:** Used paged dialogue and responsive menus and Journal, with gameplay paused during overlays.

## 2026-10-15 · Editable Procession and Dangers scenes
- **Decided:** Save major visuals in scene nodes and maintain metadata. Show Dangers in papyrus order in the editor, with runtime hiding and readable spell groups.
- **Decided:** Show Procession’s starting layout and restored water in the editor. Keep the loaf in the bearer’s arms and put the goose on the floor.
- **Decided:** Remove extra parents around single Dangers sprites. Keep the supplied avatar PNG and regenerate Procession artwork with the bier as one piece.
- **Made:** `godot/scenes/dangers.tscn`, `godot/scenes/procession.tscn`, `godot/assets/procession/` and `godot/README.md`.
- **Agent did:** Kept parent nodes for multipart creatures and fixed the donkey encounter’s invalid foe lookup.
- **Corrected:** The agent treated the shared papyrus shader as proof the Dangers avatar rendered correctly. Creature draw order was covering it during play.

## 2026-10-15 · Procession sprite sheets, dangers fight frames, ideas trim
- **Decided:** water-jar man gets extra swivel frames, driver the default count; sheets are hand-edited and never remade; cutter works partially, cutting only what is necessary.
- **Decided:** fight panels share one render (double lines at screen edge, fixed text size, tag names the danger, not "scribe"); beetles 5; keep `FRAME_FROM_TOP`.
- **Decided:** unresolved TODO notes to top, boring/redesign notes copied to `ideas.md`; trimmed councils, mouth and heart, coming forth by day, adoring figure, four floors, sacred towns, guarding the body, amulets, adorning baboons; transformations and ba/body tentative.
- **Decided:** three items attach to the avatar then go on the stand; clicking the ox driver walks to the hauler then fades into his pose; build the cow game and the plumes level from the updated .mdp; don't do "my call" items.
- **Made:** `tools/arm_sheets.py`, `tools/cut_procession300.py`, `godot/scripts/bulls.gd`, `godot/TODO.md`; memory notes `sprite-sheets-hand-edited.md`, `partial-cuts.md`.

## 2026-10-15 · Shared glow palette
- **Decided:** Keep named Procession and Dangers colors in the shader with a default. Use the same lighter yellow for Procession and the default.
- **Made:** `godot/scripts/glow.gdshader` and per-level palette selection.

## 2026-10-16 · Dissected layers and Opening of the Mouth
- **Decided:** Move sprites only within each `dissected` folder. Group by proximity, then theme, and omit plate numbers. Update the Cosmos cutter to match.
- **Decided:** Build Opening of the Mouth with existing logic and keep finished tasks below open tasks.
- **Made:** `art/cosmos17-21.mdp`, `art/fields110.mdp`, `art/judgement125.mdp`, `archive/tools/cut_cosmos300.py`, `godot/scripts/opening_mouth.gd` and `godot/TODO.md`.
- **Agent did:** Allowed the eye, mouth and beard to be carved in any order. Three misses reset the face.

## 2026-10-17 · Hint and description systems
- **Decided:** Refresh Procession and Dangers exports from existing MDPs and make Cosmos navigable. Reserve hints for the button and give it an unfinished-puzzle prompt.
- **Decided:** Use registry descriptions with state variants. Order puzzle text as instructions, success, feedback, hints, with instructions and success as plain strings.
- **Decided:** Show instructions on every minigame entry. Use red tags by default, green for minigames and yellow for hints.
- **Decided:** Preserve authored hitboxes and report JSON mismatches. Play and map progress follow the first unfinished level while implemented levels stay unlocked.
- **Decided:** Group level-specific scripts. Remove fading lower scroll text. Put Survival and Sustenance in Act II and Thoth immediately before Weighing of the Heart.
- **Made:** `godot/assets/`, `godot/scenes/`, `godot/scripts/descriptions.gd`, `godot/scripts/puzzles.gd`, `godot/scripts/scroll.gd` and `godot/TODO.md`.

## 2026-10-17 · Cosmos figure export, procession todo
- **Decided:** export cosmos `figures` from `art/cosmos.mdp` to PNGs with a `level.json` entry per layer, identified by looking ("layer names are usually wrong"); do the Procession TODO items.
- **Made:** `tools/cut_cosmos_figures.py`.

## 2026-10-19 · Dangers encounter split and carried items
- **Decided:** Use per-level puzzle JSON. Split Dangers by encounter, keep crocodiles together, remove beetle dots and slightly slow the twin snakes.
- **Decided:** Carry the adze and the chosen ankh or breath using authored poses. Keep the words’ behavior. Breath is easy and ankh is hard.
- **Decided:** Rename only generic layer PNGs, then group PNGs in figures and sheets in animation. Enlarge the coiled snake’s target under its outline.
- **Made:** `godot/scripts/dangers/`, Procession adze integration, per-level `puzzles.json` files and `godot/assets/` figure and animation folders.
- **Agent did:** Lengthened twin-snake timing by 5% and shifted the coiled snake’s target up three image pixels.
- **Corrected:** The agent initially missed the separate upper-right beetle counter. The removal had to cover the on-screen overlay too.

## 2026-10-20 · Spell 41 sheaf strike, spell 35 snakes, dangers text tone
- **Decided:** cosmos figures researched and cited first; Nut label and descriptions approved, .mdp untouched.
- **Decided:** spell 41 is striking the wiggling band, not binding: wrong band bites, five strikes with the last at the top, hard mode bites for not striking; spearer leans and moves up/down; lean sheets first, wired in after.
- **Decided:** spell 35 snakes come from both sides, no red snakes, at most five on screen, tail shake is the tell, faster than crocodiles; dangers avatar reprocessed transparent with correct ground.
- **Decided:** dangers instructions get a snarky/slightly funny tone, edited line by line.
- **Made:** `godot/scripts/dangers/` (`sheaf.gd`, `creeping_snake.gd`, `crocodiles.gd`, `danger_encounters.gd`, `snake_tail.gdshader`), `tools/spearer_lean.py`, `godot/assets/dangers/puzzles.json`.
- **Corrected:** agent assumed crocodiles are hit only at the snout in instructions and code comments; they are not snout-only.

## 2026-10-21 · Shared moveable objects
- **Decided:** Use shared drag and recovery rules. Only carriable objects attach on click, descriptions persist during dragging, and correctly placed objects lock.
- **Decided:** Keep object scale, with the carving adze at 50%. Keep the words’ approved click-follow, and require a drop onto the mummy to enter carving.
- **Decided:** Rejected offerings land before the bearer, the lector blocks loose offerings, and pickup text appears only when a scene object attaches to the avatar.
- **Made:** `godot/scripts/moveable_object.gd`, Procession and Dangers integrations, `AGENTS.md` and `godot/TODO.md`.

## 2026-10-22 · Offering table and bearer interactions
- **Decided:** Bread has its own click target, only the goose locks to the bearer, and only clicking the completed table reports completion.
- **Decided:** Restore the original offering placements except for the large frond and goose/bread swap. Give the second table its own description.
- **Decided:** Update the priests’ descriptions and retire the offering priest’s help prompt after completion.
- **Made:** `godot/assets/procession/`, `godot/scripts/procession/` and `godot/TODO.md`.
- **Agent did:** Reduced the offering snap radius from 45 to 35 pixels.

## 2026-10-22 · Sheaf timing and Procession visual feedback
- **Decided:** Let the ankh and breath swap in hand and pass behind the text column. Give every sheaf band the same strike window.
- **Decided:** Share damage shake. Use a slow, light-green success glow and heka-red visual cues above the two priests.
- **Decided:** Spawn loose offerings on the table. Center the bulls and stand at the nearer end. Let either head or rump gestures flip the calf.
- **Made:** `godot/scripts/dangers/` and `godot/scripts/procession/`.
- **Agent did:** Set the sheaf window to 1.2 seconds and the final glow to a 20-pixel radius over four seconds.

## 2026-10-22 · Survival, scroll map and editable menus
- **Decided:** Align the built map icons to the top double line, remove the Night Journey fade, and omit plate numbers, Three-Tier Sun and Amulets.
- **Decided:** Rename generic Survival plate layers by spell. Document level building, then build Survival and Sustenance for navigation with the avatar passing behind tall text.
- **Decided:** Save the title menu and full scroll map as editable scenes, with the header and footer visible and locked.
- **Made:** `art/survival43-63.mdp`, `SKILL.md`, `godot/assets/menu/`, `godot/scenes/survival.tscn`, `godot/scenes/menus.tscn` and `godot/scenes/scroll.tscn`.

## 2026-10-22 · First Gates build and creeping snakes
- **Decided:** Build Gates from spell 146 first. Speed the speared snake’s death and keep the sparse swarm upright, apart from the player and within playable bounds.
- **Decided:** Win at 10 speared snakes, cap active snakes at four excluding dodged ones, keep others moving during strikes and color the selected sheaf band dark red.
- **Made:** `godot/scenes/gates.tscn`, `godot/assets/gates/` and `godot/scripts/dangers/`.
- **Agent did:** Varied the swarm’s stop distance and allowed tilt up to 65 degrees.

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
- **Decided:** buttons read Hint 1/2/3, locked ones dashed with no word and no "Choose a hint" line; picking one replaces the buttons with its text; Hint button returns to the buttons; settings bar not sticky; band has no Close or open/close (bottom text, a newer line replaces it); the modal's close button reads just "[esc]"; every option, Find included, is named Hint 1 to n.
- **Agent did:** captured Procession and Dangers screenshots from a patched copy of `godot/` outside the repo; added switches for band and modal text size, choice label size and what the modal covers; band text defaults to 24 px; Hint on the modal's buttons closes it.

## 2026-11-18 · playtest step driver
- **Decided:** make the step driver for the `playtest` skill.
- **Made:** `godot/tests/step_driver.gd`, `godot/tests/step.py`; README "Playtest step driver"; `playtest` skill and `configuration.md` QA row now point to it.
- **Agent did:** clicks settle 0.3 s, drags 0.6 s; coordinates are frame pixels; game time stands still between commands; real `scroll.cfg` restored after every command; replies never name the level or ids; line reading time 4 words/s + 1 s.

## 2026-11-18 · bottom-band message timer
- **Decided:** ordinary messages fade after five seconds of active play, with per-message overrides and an option to stay until replaced.
- **Decided:** descriptions stay during active dragging unless feedback replaces them. A quiet release gives three seconds to read.
- **Decided:** active instructions stay visible, and temporary minigame feedback fades back to the current instructions. Hint changes are separate.
- **Made:** `godot/scripts/hud.gd`, level integrations, and regression coverage in commit `03af5b6`.
- **Agent did:** paused the countdown while the Journal is open and kept the speaker tag and text on the same fade.

## 2026-11-18 · level build playtest and Notion workflow
- **Decided:** build the level before its debug controls, always report the shortcuts, and update the level's Notion Documentation and Plan pages.
- **Made:** `.claude/skills/build-levels/SKILL.md` now carries the playtest and Notion workflow independently of the Turbo plan.
- **Decided:** preserve the existing Procession and Dangers shortcut behavior while sharing the key handling.
- **Made:** `godot/scripts/debug_menu.gd` now handles the shortcut for `procession.gd` and `dangers.gd`.

## 2026-11-18 · Codex decision-log backfill
- **Decided:** Backfill missing Codex sessions. Keep the standalone school crocodile excerpt and global Turbo setup outside the game’s log.
- **Made:** Twelve historical entries in `project-docs/decision-log.md` covering 2026-10-13 through 2026-10-22.
- **Agent did:** Used local session start dates and separate entries for each Codex session. Omitted read-only sessions and unimplemented plans.
