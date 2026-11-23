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
- **Made:** `mockups/hint-level-selector.html`, `LEVEL_EYES` rows in `.claude/skills/make-artwork/menu_images.py` (not run; no PNGs yet) (A today, B bottom band, C modal; five real-text cases; 1280 × 720 and 640 × 480).
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

## 2026-11-18 · Min for G2 and G3
- **Decided:** One agent, Min, for Procession across G2 and G3. Click Min for a short line. Keep Hint available for now, with its future availability TBD.

## 2026-11-19 · GDD refresh
- **Decided:** check the GDD for how much is unfilled and update what is stale.
- **Made:** `project-docs/gdd.md` v0.2: level table (18 cards, 11 built), G2 scope is Procession with Min, built hint ladder, audio, delivery and source-scan path corrected.
- **Agent did:** recorded the 2026-11-18 decisions (Min only, web release) as settled in Sections 7 and 16; left Hint's availability undecided as the author did.

## 2026-11-19 · TODO.md archived after Notion sync check
- **Decided:** lotus position is fixed; the trashed prologue ghost-pointer TBD is dropped; Strange Creatures is settled; prologue lessons, cues and Procession instruction review stay plan-only.
- **Made:** `archive/TODO.md` (header: do not update, all items migrated to Notion); dropped the trashed row's mention from the Prologue 151-154 plan.
- **Agent did:** treated the Moveable objects doc as covering the four numbered migration steps; did not compare the long design prose.

## 2026-11-21 · hint selector modal borders
- **Decided:** the Hint modal (C) opens showing by default and can be clicked off; try the star border and the colour band around hint boxes; a sandbox at the bottom with border art plus three formats (vertical only, horizontal only, full box); A, B and C above it stay locked; the top selectors (case, window, zoom, text sizes, covers) move into the sandbox too; horizontal-only and vertical-only borders get a 4 px ink line on their open sides, like the full box; sandbox options to remove the header (HINT, [esc], rule) and to centre the three hint buttons; a stars-all-around border with every star upright; four hint icons from Gardiner D4 to D7 (hiero2 font), reusing the D9 eye, shown below each Hint button; save the icons in the icon sheet, renamed `icons.png`. Frame E before D: upright stars all round with stars in the corners, no header, each Hint box wrapping its eye, centred, box slightly narrower at the same height. E's buttons: 20 px gap, vertically centred, 9 px top padding in the box that wraps the eye (author's own values); E's hint text centred, also vertically.
- **Made:** `mockups/hint-level-selector.html`, `LEVEL_EYES` rows in `.claude/skills/make-artwork/menu_images.py` (not run, so no PNGs yet), `mockups/icons.png` (renamed from `topbar-icons.png`, the four eyes added after the top bar icons; references in the make-artwork skill, `style-guide.md` and `strip-layouts.html` updated) (modal open by default; sandbox frame D with art and format selectors; star and band border pieces).
- **Agent did:** mapped D4 to D7 to notice, interpret, act, find in that order; drew the eyes 41 × 24 at 3 px strokes from D9's own eye, lashes (D5), eyebrow (D6), lower lid (D7); E fixed like A to C (offering table, 1280 × 720), 72 px narrower, height kept by measuring the same box with its header, its text centred too; corner stars also on the sandbox's all-upright stars, whose icon option gained "inside the button box"; icons only in the sandbox otherwise, default below, locked ones dimmed; locked C on today's plain ink line; star border drawn at 4 screen px per art pixel with box size snapped to whole tiles; band sides are the game band turned 90°; sandbox art also offers the ink line; A, B and C fixed at the offering table, 1280 × 720, ×1, 24/32/24 px text; read "a header to center" as an option to centre the buttons; starting-screen card not added (it is in `menus.html`).

## 2026-11-21 · godot dead code and shared code
- **Decided:** survival's special hover glows fade in and clear when moving between targets; unify cosmos into walk and the explore cameras; move `_view_height`; share glow tween code; delete the archived scripts; survival's differences from walk go to Notion as a TBD; document five shared scripts in Notion.
- **Made:** `UI.hover_glow`, `UI.glow_step`, `UI.HOVER_FADE` in `godot/scripts/ui.gd`; `ScrollCamera.follow`, `view_height`, `VIEW_TOP` in `scroll_camera.gd`; cosmos scene on `walk.gd` (new exports `hint_key`, `journal_hint`); `godot/scripts/cosmos/` and `archive/godot/scripts/` deleted; seven unused functions removed; tests in `script_regressions.gd`, `survival_rites_regressions.gd`; skills `build-levels`, `check-features`, `playtest` and `AGENTS.md` (Shared level code) updated for the shared code.
- **Agent did:** counted a function dead only with no reference in scripts, scenes or tests; also removed Dangers' unused `_visible_rect`; kept the camera holds and eases of procession and dangers, and survival's base, as they were; updated `archive/README.md`, `build_scene.py` and the README row for the deleted scripts; left `archive/TODO.md` untouched. Nothing committed.

## 2026-11-21 · procession stela pattern in ink
- **Decided:** the offering stand's pattern that appears in procession is plain ink, no longer a faint imprint; no other behaviour changes; the faint stand clue at Ra's place stays, since faint ink marks where a piece is to be dragged; the game's colours (ink, papyrus, dark papyrus, red, dark red, faint ink), band colours and tag colours are listed in the style guide; the tag red `#963e28` is not an in-game colour; dark red is `#751c18`; red `#b55b3c` is the one red, always at 100%, and "make it red" means it; faint ink is its own colour (today's reddish tint at 25%), always the same colour and opacity; the Survival 47 seat-sign pulse and the 52–53 filth use the usual red; the Dangers' partial reds (beetles, warning pulses) are fine; the hover glow gold is an in-game colour (`UI.GLOW`) and the Dangers use it too, no special colour (Notion TBD: whether the Dangers get their own glow); the success glow (`UI.SUCCESS_GLOW`, `#a0aa72` at 40%) is an in-game colour too, hover and success glows each keep one colour, opacity (in the colour) and reach (`UI.GLOW_REACH` 9, `UI.SUCCESS_GLOW_REACH` 17) everywhere; the strip's success green (`UI.SUCCESS_INK`) is an in-game colour; every colour in use is listed in the style guide, the uncategorized ones in their own table.
- **Corrected:** a faint imprint on the stela was meant as a clue; in playtests faint ink read as "something must go here" and confused players, so the stela's pattern is plain ink.
- **Made:** `STELA_INK` in `godot/scripts/procession/ending.gd`; `StelaImprint` tint dropped in `godot/scenes/procession.tscn`; `ideas.md` stela line reworded; `UI.FAINT_INK` in `godot/scripts/ui.gd` replacing `UI.PREVIEW` (procession, tests, survival 47 sceptre imprints); `FILTH_TINT` removed from `offering_tables.gd`, seat pulse on the red in `survival_play.gd`; `UI.GLOW` in `godot/scripts/ui.gd` (Dangers' orange glow and the `danger` uniform removed from `glow.gdshader`, `UI.Glow.DANGER` gone); palette named `UI.INK`, `PAPYRUS`, `DARK_PAPYRUS`, `RED`, `DARK_RED`, `FAINT_INK` (`DEEP`, `DANGER`, `INK_TINT`, `AIM_INK` removed; `UI.inked()` tints ink drawings); "In-game colours", tag and band colours in `project-docs/style-guide.md`.
- **Agent did:** read "the pattern" as the stela's pattern (appears once the other rites are done), not the faint stand clue shown at Ra's place, which stays faint; left the "stela glows faintly" message in `godot/assets/procession/registry.json` as is; read band colours off `band_*.png`; also moved Survival 47's sceptre imprints (plain ink at 30%) onto faint ink; faint ink's `#bfa37f` is computed over papyrus.

## 2026-11-22 · Claude session backfill
- **Decided:** Cut figures and rename the horizontal and vertical guide layers only in numbered spell folders. Approved copying the cut plate into `art/`.
- **Made:** `art/guardingbody151-154.mdp` (151ab, 151c, 151de, 152, 154).
- **Agent did:** Split touching figures at their contact points, added a separate bowl layer in 152, and kept Isis's ball in her layer.
- **Made:** The glow decision in the 2026-11-21 Procession entry reached `godot/scripts/ui.gd`, `godot/scripts/glow.gdshader`, and `project-docs/style-guide.md`.
- **Agent did:** Applied the shared glow settings per glow type, retaining 9 texture pixels for hover and 17 for success.

## 2026-11-22 · Retaining substantial Done tasks
- **Decided:** Sweep short tasks into History and ask whether to retain substantial completed pages, including those with full plans, at Done.
- **Made:** `.claude/skills/write-notion/SKILL.md`.
- **Agent did:** Keep flagged pages at Done while awaiting a decision and record retention decisions on the task pages.

## 2026-11-22 · Minigame entry and exit
- **Decided:** Click people for instructions and implements to take their place. Esc leaves those games. Left and Right also leave drag-and-drop games, which retain progress.
- **Decided:** Keep the camera fixed during play. Location alone stays quiet except for Survival 59. Survival and Gates use `walk.gd`.
- **Made:** `minigame_view.gd`, Dangers and Procession entry and exit, `survival/survival.gd`, Gates and Survival scene settings, puzzle text, and regression coverage.
- **Agent did:** Used the other side of the man in Survival 57 when standing on the approach side would clip the avatar at the vignette seam.

## 2026-11-22 · citation to-dos, frozen Dangers registry, sliding text columns
- **Decided:** new citations always get a search for a source; citations the author marks done or deletes on purpose are no longer to-do; the Dangers registry is frozen.
- **Decided:** commit to main and delete `minigame-entry-exit`; when a minigame's double lines push outward, vertical text inside them slides down to ground level, Survival included.
- **Made:** `.claude/skills/cite-references/SKILL.md`, `godot/assets/dangers/registry.json` (a3a108e); `.claude/skills/build-levels/SKILL.md`; `godot/scripts/survival/widen.gd` (`WALLS` 52, 57); `godot/tests/survival_rites_regressions.gd`.
- **Agent did:** rule only in `cite-references`; a missing `reference` field counts as deleted; slide timed with the opening, back on close; carried ground rule fades in.
- **Corrected:** the text wall does not sink into the ground and vanish; the whole column, with its text below the ground, slides down until its top is under the ground rule.

## 2026-11-22 · gitignored files and turbo plans in Notion
- **Decided:** Notion never references gitignored files; a turbo plan becomes its own row with its full content copied in, only when the author says.
- **Made:** `.claude/skills/write-notion/SKILL.md` (Section 5).
- **Agent did:** plan rows start at Status Backlog; row body updated on plan change only when asked; check with `git check-ignore -v`.

## 2026-11-22 · reference file server for Notion source links
- **Decided:** Notion source links open local reference files through a server the author starts by double-clicking a command (Control-C stops it); the server serves only the repo and the BookoftheDead readings folder.
- **Made:** `tools/open-local/serve.py`; `Start reference server.command` (author moved it from the repo root).
- **Agent did:** port 8765, read-only, 127.0.0.1 only, refuses other Host headers, no folder listings, Range support; command calls `serve.py` by absolute path so it works after moving.
- **Corrected:** agent assumed Notion follows `totenbuch://` links through a macOS URL-handler app; Notion ignores custom-scheme links, so the app and its scripts were removed.

## 2026-11-22 · Archive cleanup
- **Decided** Remove the retired Godot assets and Hall scene. Remove the map generator's dependency on the archived scroll scene.
- **Made** Removed `archive/godot/assets/` and `archive/godot/scenes/hall.tscn`. Updated `.claude/skills/build-levels/build_scroll_map.py`.

## 2026-11-22 · Notion History sweeps
- **Decided:** Sweep Done tasks into History only on explicit request and confirm the exact batch first.
- **Made:** `.claude/skills/write-notion/SKILL.md`.

## 2026-11-22 · Totenbuch task fields
- **Decided:** Use known due dates only, leave acceptance criteria blank for TBD, and record outcomes once tasks are Done.
- **Decided:** Keep any otherwise unrecorded TODO.md line and section references in task bodies. Preserve the existing Notion views.

## 2026-11-22 · shared playtest menu and Procession bread
- **Decided:** Give all levels one hidden T menu and a level integration guide. Add mechanics QA coverage.
- **Made:** `godot/scripts/debug_menu.gd`, Scroll and level integrations, `.claude/skills/build-levels/SKILL.md`, and mechanics QA guidance in `README.md`.
- **Agent did:** Fixed the stale bearer sprite reference in `offering_table.gd` and added regressions for the bread and debug menu.

## 2026-11-22 · Notion completion dates
- **Decided:** Fill a blank Done date with the date the task is seen in Done.
- **Made:** `.claude/skills/write-notion/SKILL.md`.


## 2026-11-22 · small-fixes implementation agent
- **Decided:** make an implementation agent for small fixes from the author's lists, built from the Notion history and open tasks, that checks existing behaviour, uses shared code and escalates decisions.
- **Decided:** keep only the skill, no subagent; a skill counts as an agent for the course's team tool.
- **Made:** `.claude/skills/small-fixes/SKILL.md`; `AGENTS.md` and `project-docs/configuration.md` (Tech Lead row) list it.
- **Agent did:** new rows get Role Tech Lead and Status In progress; Done in commit waits for an approved commit; tech-to-qa handoff only once `agent-team/` exists.

## 2026-11-22 · course agent-team files
- **Decided:** copy the course repository's files in; add its rules to `AGENTS.md`; prepend its README sections, filled; use its `CLAUDE.md` (`@AGENTS.md`); merge `.gitignore`; run `team init`; keep the CI "Your tests" placeholder.
- **Made:** `team/`, `tests/`, `.github/workflows/final.yml`; `agent-team/`, `.claude/agents/team-tech.md`, `team-qa.md`, `.agents/skills/` from `python -m team init`; `AGENTS.md`, `README.md`, `CLAUDE.md`, `.gitignore`.
- **Agent did:** README tracker link is the Totenbuch Tasks database; gate documents named as `project-docs/`; added a "Playing" heading over the old intro; starter roles left untailored and `other-roles.md` lines empty.
- **Decided:** move `team/` and `tests/` into `project-docs/`; `agent-team/` stays at the root, where the course tool writes it.
- **Made:** `project-docs/team/`, `project-docs/tests/` (`test_team_ci.py` workflow path); `.github/workflows/final.yml` (`PYTHONPATH: project-docs`, tests path); handoff-template path in `agent-team/roles/tech.md`, `qa.md`, re-rendered; README and `AGENTS.md` commands.
- **Decided:** restore the course guide; **Made:** `project-docs/team/README.md`, linked from README and `AGENTS.md`.
- **Decided:** tailor `agent-team/roles/tech.md` to the game and point it to the skills.
- **Made:** `agent-team/roles/tech.md` (game, stack, model, test slots; prototype, G2, production lanes; Instructions name `small-fixes`, `check-features`, `build-levels`, `draft-ui`, `write-notion`, `log-decisions`), re-rendered; configuration Tech Lead row.
- **Agent did:** chose those skills (playtest left to QA, art skills to Art); text handed to Narrative as a split-off Notion row with Role Narrative, plus a tech-to-narrative note once that role exists, even for dictated wording; lanes' expects/delivers kept; added no-commit and no-asset-rebuild rules to the Instructions.
- **Corrected:** agent gave the Tech Lead `write-game-text` and `cite-references`; wording and citations belong to Narrative and are handed off (`small-fixes`, `agent-team/roles/tech.md`).
- **Decided:** Narrative and Audio are one role again, as in the course roles.
- **Made:** one Narrative and Audio row in `project-docs/configuration.md`; role name in `write-notion`, `small-fixes`, `agent-team/roles/tech.md` (re-rendered) and `project-docs/risk.md`.
- **Decided:** add the Narrative and Audio role with the right skills.
- **Made:** `agent-team/roles/narrative.md` (skills `write-game-text`, `cite-references`, `write-notion`, `log-decisions`), origin note `agent-team/handoffs/2026-11-22-student-to-narrative.md`, re-rendered; configuration row.
- **Agent did:** gave the role edit rights to JSON wording and references only, no code; slots for Davis text, built haul sounds and Min's voice; drafted the origin note's Why, Use, Produce, Accepted when and Evidence; Student decision left empty.
- **Decided:** Narrative and Audio works under close oversight: validate every claim, never invent facts or story without asking, edit only its own additions, change or delete existing text only on an explicit command or confirmed bounds; reads the List of Sources page and `references/` PDFs; existing references preferred, new ones allowed.
- **Made:** oversight rules in `agent-team/roles/narrative.md`, re-rendered.
- **Agent did:** named the readings folder behind `references/BookoftheDead alias`; asks before adding a source to the List of Sources.
- Corrected (author): `references/` paths belong in Notion; they are the main way sources are cited. Narrative and Audio cites sources in Notion by their `references/` path, and `write-notion` now makes `references/` the one exception to its no-gitignored-paths rule.
- **Decided:** set up the QA agent with relevant skills.
- **Made:** `agent-team/roles/qa.md` tailored (skills `check-features`, `playtest`, `small-fixes` for verifying fixes, `write-notion`, `log-decisions`), re-rendered; QA row in `project-docs/configuration.md`.
- **Agent did:** gave QA edit and write so it can write tests (never game code, JSON text or assets); set blocking bugs to crashes, unfinishable levels, soft locks, lost progress and Min giving away a solution; replaced the example `rules-reviewer` check (no such agent here) with `check-features` step 1 and asking the student.
- **Decided:** a `write-hints` skill: one Find line, then at most three graded hints per phase, fewer when fewer are needed; it also judges existing hints (helpful, not too revealing, graded). No current game hints as examples until the author picks some, since several are not satisfactory.
- **Made:** `.claude/skills/write-hints/SKILL.md`; pointers in `AGENTS.md`, `write-game-text`, the Narrative and Audio and QA roles (re-rendered) and the configuration row.
- **Agent did:** named the hint kinds notice, interpret, act (the existing labels) and added `tip` for skill phases; noted that `hint_regressions.gd` rejects `tip` until the test is extended.
- Corrected (author): the Find line is a `notice`; there is no `tip` kind, technique is an `interpret`; a phase with only an `act` (or act plus tip) needs a very good reason and the author's agreement; a hint may be vague about what to do or tangential, but must point to something visible. `write-hints` and the Hints bullet in `write-game-text` updated; `hint_regressions.gd` needs no change.

## 2026-11-22 · goose snap, plumed lector signs, Eater of the Ass speed
- **Decided:** keep both priests' speech red (they already match); raise the double-plumed lector's signs a few pixels; the fake-out change is a faster snake crawl; goose only snaps now, the other drag-and-drop items become one audit task.
- **Made:** `godot/scripts/procession/offering_table.gd` (`goose_in_reach`), `procession.gd` (`_snap_offering`, `RECITE_RAISE`), `godot/scripts/dangers/danger_encounters.gd` (e40 `crawl`), tests in `godot/tests/moveable_object_regressions.gd` and `procession_interaction_regressions.gd`, `agent-team/handoffs/2026-11-22-tech-to-qa.md`.
- **Agent did:** goose snaps within the table pieces' 35 px radius of the bearer's arms, release over him still works; signs raised 6 plate px; crawl raised about 40% (39-59, hard 56-84), hard kept above normal; no test pins the speed.
