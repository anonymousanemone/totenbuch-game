# Totenbuch (Godot 4)

Levels of the Book of the Dead as a point-and-click game, built from Lepsius's
*Das Todtenbuch der Ägypter* (1842). Every figure is cut from the plate scans; nothing is redrawn.

Open `project.godot` in Godot 4.7+ and press **Play** (F5). A level menu opens first.

The scroll reads right to left. Click the papyrus (or use ← →) to walk.

The captions in the top register are the spells' titles. Click one (it glows under the pointer) and
the strip shows its translation, from C. H. S. Davis, *The Egyptian Book of the Dead* (1894), which
translates this same papyrus: `CAPTIONS` in `scripts/procession/procession.gd`, and each danger's `caption` and
`title` in `scripts/dangers/danger_encounters.gd`.

The procession, Night Journey, dangers, and Survival and Sustenance are playable from the map.
The Field of Offerings and Weighing of the Heart remain in `../archive/` (see its README).

## Survival and Sustenance (spells 43–63, pl. XX–XXIII)

The full scroll is open for navigation and inspection, without puzzles or barriers.
Walk right to left with the arrows or by clicking the papyrus. Click a glowing figure
to approach it, read its description, and record it in the Journal. Captions can be
inspected without adding journal entries. Tall text columns have papyrus-backed
foreground nodes, so the avatar passes behind them; each repeats everything drawn within it,
rules and frame lines included. The avatar is a copy of the scroll's first man, the spell-43 worshipper.

`scenes/survival.tscn` holds the artwork in spell groups, the avatar, camera, and five
foreground text sections. `assets/survival/level.json` records source-layer IDs and bounds;
saved scene positions remain authoritative. The source is `../art/survival43-63.mdp`.
`../tools/build_survival_scene.py` exports the source and initially authors the scene;
rerunning it replaces the generated scene, so preserve deliberate editor changes first.
Use `-- --level=survival --at=5000 --screenshot=/tmp/survival.png` for a rendered preview.

## Visual scene workflow

The title page is authored in `scenes/menus.tscn`, including its frame, frontispiece,
text, and four buttons. `scenes/menu.tscn` instances it for existing menu links.
`scenes/scroll.tscn` contains the complete map at 1280 × 1686 pixels for editing:
all 21 level cards, grouped by act, with the locked header and footer at its ends.
In play it fits the viewport and clips the scrolling level list between the fixed bars.
Edit the saved nodes directly; scripts connect actions and update selection and progress.
Keep map cards' `key` metadata in sync with `Scroll.SCENES` when adding or removing entries.

The project is moving toward visual editing in Godot. Major visual elements are being moved
from runtime construction into saved scene nodes so levels can be inspected and maintained
in the editor. Position data and metadata are still kept and updated; `level.json` and other
level data remain useful for descriptions, stable IDs, source-art coordinates and gameplay rules.

For every new scene:

- Place all major visual elements in the saved scene tree: backgrounds, figures, props,
  puzzle pieces, persistent overlays, and the starting avatar and camera.
- Organize nodes by spell or puzzle, use readable names, and preserve stable IDs linking
  nodes to their data. Use a single `Sprite2D` for a single picture; add parents when separate
  parts, pivots or behavior need them.
- Make the intended editor arrangement visible before running the game. Scripts should reuse
  those nodes and apply gameplay startup visibility and state, rather than reconstruct the level.
- Keep stored positions and metadata maintained alongside scene edits. Update dependent
  hotspots, placement targets, camera ranges and animation geometry when their visuals move.
  Scene placement is authoritative for visually edited elements; source-art coordinates remain
  separately identified, and runtime setup must not silently overwrite scene edits.

Runtime creation remains appropriate for temporary effects, spawned copies and loose physics
bodies. The remaining code-built visuals, including the HUD, are part of this ongoing migration.

## The Funeral Procession (spells 1–15, pl. I–VI)
Whatever can be clicked glows under the pointer (`scripts/glow.gdshader`; all eight standard-bearers glow together). Click figures to record them in the journal; click a movable piece to pick it up and click
where it belongs to set it down (clicking a filled place swaps the two). Click where you took it to put it back.
The whole scroll can be walked from the start.

1. **Haul the bier** (plate II): click the ox-driver or the empty rope (it shudders now and then, like the calf, until it is taken up) and you walk to the hauler's place on the rope and fade into his pose (`INTO_POSE` in `procession.gd`); the driver asks for your help. Space starts the count-in; on the count the whip only flicks, and its first full fall is the first beat to pull on. While you haul, the camera holds still on the train and the road ahead of the ox (`HAUL_AHEAD`), so you see the train come up. The vignette opens over plate I and the train stands back from its place. Pull with Space, Shift, or click as the whip falls; the drum and whip provide the beat. An early or late pull lets the rope slacken and the bier slip back; a missed beat stops it. The hauler leans and the train moves on accepted pulls. After a miss or a slip, the next good pull has the driver answer it ("That's it. Keep the beat."), so the miss is not left standing. Twelve pulls without setbacks bring it home; afterwards the hauler, clicked, says you've helped the procession advance. Esc or arrow keys let go and restore the walking avatar. Tuned in `scripts/procession/haul.gd` (`BEAT`, `WINDOW`, `BACK`, `PULLS`, `SLIP`).
2. **Return the standards**: click the eight standard-bearers to stand at their nearer end and frame the group. Drag a standard at its original size, keeping the grabbed point under the pointer, onto a bearer to set it there (it swaps with the one there); let go anywhere else and it goes back. Esc or arrows leave the scene and return any carried standard. The bearers (four in plate III, four in plate II) carry the wrong gods; the two falcons are interchangeable. The lector with two plumes on his head (plate V, past the offering table) reads out the order when clicked: you stand in front of him, facing him, and the eight signs appear one at a time, centred over the top of his sheet, jackal first, each replacing the one before (`RECITE_*` in `procession.gd`; the place is `recital` in `level.json`).
3. **Rebuild the offering table** (`scripts/procession/offering_table.gd`): the heap in plate IV has collapsed. Click the table, a piece or the lector and you step up to it: you stand just behind the lector and the camera holds on the table, from the man with the jar to the goose-bearer (`view`, `stand` in `level.json` `table`). Esc, or walking off with the arrow keys, steps away; nothing is lost, and what you held goes back. The loose pieces lie on the floor between the two pairs of bouquets as physics bodies, at any angle, each with a faint papyrus fill (50%) inside its outline; the palm frond lies flat on the upper register line, towards the right. At first everything else falls through that line to the floor. Press on a piece to take it up (it comes to the front and follows the pointer; the lector beside the table can show its destination); let go after dragging, or click again, to set it down. Near its place it snaps in even before release, but only once everything it rests on is there (`rests_on`, worked out by the cutter); otherwise it topples back down. Every loose piece has gravity. Set down above the upper-register platform, a piece falls onto it; only a piece being actively dragged can cross it. The frond goes on last. Clicking the lector repeats the existing instructions and shows, in front of him, a piece that can go on now (again for the next one). A faint imprint of the same piece at its destination fades in and out with that clue.
4. **Give the goose back**: the man beside the lector holds a loaf from the heap instead of his goose, which lies among the fallen offerings. Take the loaf from him, then give him the goose. While nothing is in his arms, the clothes the goose and loaf cover show.
5. **Pour the water** (`scripts/procession/pour_water.gd`, plate V): a priest raises a round jar over a kneeling woman, and the wavy line from it, arching over Anubis holding the mummy upright and down to their base, is the stream. At the start his arm is raised further, the jar upright, and no water runs: only a faint dotted ghost of the line (`scripts/procession/water.gdshader`). Click the jar priest or his jar to step up behind him; the woman and Anubis with the mummy remain inspectable. The camera holds on the scene (`view`, `stand` in `level.json` `water`). His tired arm is pulled down, tipping the jar, harder or softer at random every so often (`DROOP`, `DROOP_EVERY`; a fresh random seed each time you step up); hold Space to push it up (`LIFT`). The arm has weight: it keeps swinging after each push or pull, dying away slowly (`DAMP`), so it is never still by itself. Within `WINDOW` of the tilt as drawn the water runs along the line and the line draws itself in; too high and it only drips, drooped too far and it gushes out and splashes on the woman's raised hands. Not pouring along the line, the drawn part dries back, never below `KEEP` of the furthest it reached. Once the whole line is drawn the jar settles where it is drawn. Esc, or walking off, steps away.
6. **Open the mummy's mouth** (`scripts/procession/opening_mouth.gd`, plates V–VI): the eye and mouth are faint drafts; the beard stays as drawn, and the caption band is empty. Take the adze from the low table and click the mummy: the player walks into the gap between the mummy and the kneeling woman, faces the mummy, and only then does the camera close in on its face. The handle follows the pointer, and each click swings the blade slightly about it. Click with the blade tip anywhere within either feature's bounds to gradually ink its original lines (3 strip px per click), in either order. There is no timer or loss state; misses do nothing. Esc or an arrow steps away. Once both features are inked, the adze returns to the stand and the words rise and unroll above the mummy. Carry them to their imprint over Ra as before. `mouth.strokes` describes the reveal paths; hit bounds come from the exported feature pixels. `mouth.face_view` in `level.json` describes the close view.
6b. **The three bulls** (`scripts/procession/bulls.gd`, plates III–IV): click the calf, the plumed ox or the sacrifice and you step up to the right of the plumed ox; the camera holds all three. One line: "Fix what is wrong!" (Hint gives graded clues). The calf faces the sacrifice and shies now and then: drag it sideways and it turns about its own middle; let go past halfway and it faces the plumed ox, as drawn. The disc and plumes sit on the bull at the block and the plumed ox walks bare: drag them onto his head (no outline shows where; let go anywhere else and they go back). Both right, he lowers his head to the calf. The plumed ox and the plumes are the sprites `plumed_ox` and `plumes` (`--bulls` in the cutter, from the `.mdp` folder `bulls`: `plumes` on his head, `plumes_wrong` the same on the sacrifice); `bulls` in `level.json` holds both places, and the scene's `plumes_place` marks the right one. The editor shows the bulls as you find them.
7. **Set up the offering stand before Ra** (`scripts/procession/ending.gd`, plate VI): the stand, the sun disc on it and the lotus over it are gone from before Ra, and so is the adorer kneeling to him. Once rites 1–6 and the three bulls are done, the stela beside the tomb shows a faint imprint of the three as they stand; until then its face is blank, and the pieces can't be taken (clicking one says it might come in handy later). They lie hidden along the scroll, and glow under the pointer: the stand inside the canopy frame behind the women mourners (pl. I), the sun disc between the legs of the creature on the mummy's bier (pl. II; it rides with the sledge), the lotus on top of the second offering pile (pl. V). Once the stela shows them, click one to take it: it goes onto you, posed as in `WORN` in `ending.gd` (the stand held before you, the sun disc on your head, the lotus over your shoulder), mirrored as you turn. Drag one off you, or click it and click again, and it follows the pointer (one at a time); let go on the place before Ra and you walk there and set it on, anywhere else (or Esc) and it goes back onto you. Click the empty place before Ra to set them up: each goes on only once what it rests on is there (stand, sun, lotus). Where they hide is `ending.hide` in `level.json`.

With all eight done you walk to the adorer's place and kneel there (the drawn adorer, cut as `kneeler`, takes your place), light spreads from Ra's disc and the new sun (`scripts/procession/light.gdshader`) and floods the screen, and the level goes back to the menu (for now; later, on to the next level).

## Dangers on the Road (spells 31–42, pl. XVI–XIX)
You can walk through every vignette. Click a creature (it glows under the pointer) to walk into
its vignette, become its spear-bearer and start the fight; in the fights that open out, Space
thrusts and holding Shift lends the thrust heka. Walking into a vignette says its danger's line (each time, until it is overcome). Clicking the creature opens the fight, and it starts at once: no Space to begin (spell 31 opens with its lesson, one thrust before the first crocodile comes; spell 32's first crocodile comes 1.2 s in). Walking from spell 40 to 41 he passes behind the column of signs between them (`Column` in `scenes/dangers.tscn`: the papyrus and the strip's ink there, drawn over him; hidden while a fight is open). Once a fight starts, every spear-bearer rests
with the spear drawn back, and a thrust only runs it out and draws it back again; once it is overcome the vignette is put back as drawn.
You can walk into spell 38 (the breath of life) and take it at any time, but not on past it until the earlier dangers (31–37) are all done (an invisible barrier at its far edge; the scribe says what is still to do), and spell 42
at the end waits until every danger before it is overcome.

Every fight opens the same way (`_arena_setup`, `_frame_now`, `_place_frame` in `dangers.gd`): over `CROC_OPEN` its frame moves from the vignette's drawn double lines out to the edges of the screen, the bottom double line stopping just above the speaker's tag. The lines keep the thickness they have while walking; the band's top line stays where it is. The caption moves to the middle of the band (centred by its ink) at the size and height it has while walking. Only the wide fights (the crocodiles, 31–32, and the beetles, 36) zoom out to the whole height of the scroll, and their caption shrinks with them. The picture fills the frame below the band. During a fight, what the scribe would say is said under the danger's name (`tag` in `danger_encounters.gd`: Crocodiles, Snake, Beetles, Snakes, Apep, Eater of the Ass).

| Spell | Rule |
|---|---|
| 31 | The vignette opens out (see above). You are the spear-bearer: ↑ ↓ / W S move you, Space thrusts; only the spear point strikes, anywhere on a crocodile (or right by its snout) before it reaches you. Crocodiles never come with their front halves on top of each other, nor one right after another at the same spot. The last crocodile of each wave is always one of the drawn ones squatting on screen. Wave 1 is the lesson (a thrust, a move, one slow crocodile, two more). Then a break: the heka word in the banner starts flashing red (click it for the hold-Shift hint). Wave 2 has red crocodiles (`red_order`), turned back only by a thrust while holding Shift. Bites redden the body; heka on an ordinary crocodile, or one slipping past you once the word glows, loses, with one animation for both: the crocodile laughs (squashes up and down) and turns round, the word spins down into its jaws, he crumbles the moment it lands, and it carries the word off. You are back on the scroll; click a crocodile to fight again, always from wave 1. Each crocodile of a wave is `ramp` faster than the one before. The last crocodile of the fight is the last one on screen: every drawn one has come before it, and it sets off only once the others are gone. Tuned in `ENCOUNTERS` (`waves`, `break`, `ramp`) |
| 32 | The same, faster, two at a time and from both sides: you stand in the middle, ← → turn you, ↑ ↓ move you. When spacing them, one from the other side counts as if it came from the same side. Some crocodiles come red (`red` chance): hold Shift (heka; the spear turns red) as you thrust to turn those back. A plain thrust does nothing to a red one; heka on an ordinary one loses: it takes the heka word as in spell 31, and you are back on the scroll. Bites redden the body, heka reddens the spear |
| 33 | Close up (caption to ground). He stays where he is drawn, spear raised; Space thrusts. The snake coils just out of reach, breathing; its tail waves (the warning, `snake_tail.gdshader` bends the drawing), it squashes, and snaps to his front leg (its body passes behind his skirt, its head in front). Thrust as it springs: the point must come down on the red mark, at the spot where it is drawn. The mark shrinks with each strike (`marks`: radius 14, 11, 8 plate px, a window of about 200 ms down to 145 ms); no count is shown. Too early, the spear is already rising again. Three strikes (`need`; for five, give `marks` five sizes); three bites and he crumbles. Tuned in its `ENCOUNTERS` entry |
| 35 | Like spell 32, without red ones: the vignette opens out, you stand in the middle, ← → turn you, ↑ ↓ move you, Space thrusts. The drawn snake moves off to rest `rest` from you; more slither in from the edges and stop (never more than `at_once`, 5, resting). One at a time, `next` s (0–1.5) after the last attack ended, a resting snake shakes its tail (the only warning; `snake_tail.gdshader` bends it along `tail_base`→`tail_tip`) and darts at you along its row at `speed`. The snakes creep with their heads raised (the first frame of `snake35_turn_over.png`). The spear point anywhere on it spears it: everything waits while its head is pinned under the point and, frame for frame, it flips its head back and crosses down to lie as drawn while the bearer presses his spear on down (`spear35_strike.png`); it lies so a moment, then fades. Touching any part of you, it bites and slinks back to rest elsewhere; missing you, it slips past, turns and rests on the far side (and no longer counts toward `at_once`). 14 speared (`need`) wins; three bites and snakes come in from everywhere (no steeper than 15°), bite him all down both sides, and he crumbles. `--croc-bot` with `BOT_REACT` checks it can be won (above `shake`, 0.8: a player who ignores the tails) |
| 36 | The vignette opens out; you stand still in the middle: ← → turn you, Space thrusts. Five beetles (`count`: the drawn one and four copies) dart about very fast; every couple of darts each stops by the point of your spear on your left or right for 0.35–0.75 s (some stops just out of reach). Only the spear point at the full thrust pins one on its body; a catch holds everything for 0.5 s and that beetle is gone. Pin all three to win. A beetle that stops within reach and gets away has passed the point: it reddens a step each time, and once it has passed `passes` (3) times, the next time it gets away they multiply until they fill the vignette, the bearer crumbles, and you are back on the scroll. Set `passes` to 5 for an easier fight |
| 37 | Close up; he stands in the middle as drawn, ← → turn him, Space thrusts. The drawn snake on his left and a mirrored copy on his right wait coiled `rest` (90) plate px out from where they are drawn, facing him, breathing. One of the two snake signs in the caption flashes red (left sign, left snake); that snake squashes down and springs at his foot, passing the spot where it is drawn. Thrust facing it as it passes (`reach` 12 → 7 plate px; a window of about 110 ms down to 90 ms); a thrust at a coiled snake makes it spring at once. Each struck twice falls where it is drawn; three bites and he crumbles. `warn`, `crouch`, `snap` and `reach` tighten with each strike |
| 38 | Take one sign from the giver's hand, the sail (breath) or the ankh (life): one is carried at a time; clicking the other returns the carried sign to his hand and takes its place. The sail gives the later fights their easy rules; the ankh gives endless life. Taking neither sign is allowed once the earlier dangers are overcome. |
| 39 | Close up, the whole vignette across. He stays where he is drawn, the barb resting a little way up its line from Apep's neck (where the body folds back); Space thrusts. Now and then the tail lashes and a wave runs the length of Apep to the fold (`apep_wave.gdshader` lifts the drawing column by column); his head strains up as it comes. Thrust as the crest reaches the point: the wave is pressed flat, Apep flushes red, and the barb rests a step further in (`need` 6 steps; at the last the spear is as drawn). A wave that gets past rears his head out from under the barb, round to bite the bearer's foot. After the first two (`teach`), a share of waves (`feint`) are smaller and die out in the drawn hump; a thrust on a still neck works the barb loose a step. The waves come faster (`speed` 220 → 380 plate px/s), closer together (`gap`, never two at the point within `min_gap`), and the crest must be nearer the point (`reach` 10 → 5 plate px: a window of about 155 ms down to 135 ms). No count is shown; three bites and he crumbles. Tuned in its `ENCOUNTERS` entry |
| 40 | Close up. The snake's head is down in the donkey's back: a thrust then goes into the donkey and he crumbles at once. Now and then the donkey swishes its tail (`tail40`, cut from the donkey, turns about its root) and the snake lifts its front up the spear's line to snap at it (`lift_end.gdshader`), for `up` s (0.6 → 0.38, ±25%): Space then strikes it. After the first strike some swishes are only flicks (`flick` 45%), and it does not look up. Left alone, its coils tighten and it bites the donkey every `bite_every` s (4.5 → 3.6); the flesh signs count the donkey's health, and the third bite and the donkey is eaten. It always looks up at least once before each bite, and a strike sets the bite back. Three strikes win. `DONKEY_CURVE=1` with `--autotest` prints how often a stand-in player wins at each reaction time |
| 41 | Use ↑ ↓ to aim at the shivering band and Space to spear the snake. Five hits, the last on top, win in mortal play. Without breath, missing the opening also causes a bite. |
| 42 | End of the level. Spell 42 is text only (each body part given to a god) and is not a puzzle yet |

Spell 38's choice affects only spells 39–41:

| Choice | Rules | Health and ending |
|---|---|---|
| Breath sail | Easy | Three flesh signs; encounters can be completed |
| Ankh | Hard where implemented | One ankh flashes red on a damaging mistake; no death, snakes return, no level ending |
| Neither | Same hard rules as the ankh | Three flesh signs; normal deaths and victories |

Only the sheaf currently has hard rules. Apep and the Eater of the Ass keep their existing
(easy) tuning in all three routes; their `hard_ready: false` entries are the scaffolding for
future tuning. The ankh's immortality and repeating encounters already apply to all three.
Earlier encounters keep their original rules regardless of which sign is carried.

With the ankh, the Journal silently counts each successful wave pressed back (39) or snake
speared (40–41), in a separate entry per spell. Scores survive leaving and re-entering fights.
After 60 active seconds in one encounter, or 120 active seconds combined, whichever comes first,
the scribe says: “you are living but never free. perhaps that wasn't what you needed.”
Time accumulates across visits; opening/closing animations, walking, and the paused Journal do
not count. The clue appears once per run and stays clear of routine feedback for six seconds.
Restart clears the scores, journal, choice, and clue timers; these are session records, not a disk save.

The adze sits in the player's hand while walking to the mummy, mirroring and bobbing with
him. Entering the face view puts it on the pointer for carving; leaving returns it to his hand.
The words still follow the pointer. Final offering pieces keep their existing worn/drag behavior.
Attachment transforms are shared through `avatar.gd`'s `carrying_transform()`.

In Dangers, the chosen ankh or breath sail stays on the walking player. Its pose comes from
`Avatar/CarryAnkh` or `Avatar/CarryBreath` in `scenes/dangers.tscn`, preserving the former
avatar-copy arrangement: ankh anchor `(-38, -233)`, sail anchor `(-35, -236)` relative to the
player's feet facing left. Their image offsets remain `(-16, -67)` and `(-30.5, -49)`.
The sign mirrors and bobs with the player, hides during combat, and returns to the giver on restart.
The unchosen sign stays in the giver's hand. The reference copies have been removed.

## Layout

Scene-specific scripts and shaders are grouped under `scripts/procession/`, `scripts/dangers/`,
`scripts/cosmos/`, and `scripts/menu/`. Scripts and shaders shared across scenes stay directly in `scripts/`.

| Path | What |
|---|---|
| `scenes/menu.tscn`, `scripts/menu/menu.gd` | The title page (Play, The scroll, Settings, Quit), the map of the scroll (every scene act by act, reading right to left), Settings (sound, fullscreen, controls, beginning again) |
| `scripts/scroll.gd` | Autoload `Scroll`: the scenes in playing order (Lepsius's spell order, the weighing of the heart last), which are restored, and the settings, kept in `user://scroll.cfg`. A scene counts as built once `scenes/<key>.tscn` exists; finishing one opens the next built scene |
| `scripts/ui.gd` | The shared look (`UI`): palette, Old Fax, square panels, the frame band, pixel icon buttons |
| `scenes/procession.tscn`, `scripts/procession/procession.gd` | Spells 1–15 |
| `scenes/dangers.tscn`, `scripts/dangers/dangers.gd` | Spells 31–42: shared arena, walking, gates, breath-of-life choice, and encounter dispatch |
| `scripts/avatar.gd` | Walking (click target or keyboard), facing, bobbing |
| `scripts/hud.gd` | Title bar (Restart, Menu), the scribe's strip under the scene (the line said with its speaker's tag, Journal and Hint; nothing shows what you carry: it follows the pointer), the Journal page ([j]), intro/outro; each level passes its own texts |
| `assets/menu/` | A picture per scene for the map (frames of the built levels, crops of the plates for the rest) and the title page's frontispiece, made by `../tools/menu_images.py` |
| `assets/ui/`, `assets/fonts/OldFax.ttf` | The scroll's frame band as tiles (`band_top`, and `band_bottom`/`band_left`/`band_right` for the screen's edges), icons (Journal is 𓏞, the scribe's kit; Hint is 𓂜; Restart and Levels are placeholders), and the pixel font (16 px is one font pixel, 32 px two) |
| `scripts/papyrus.gdshader` | Procedural papyrus fibres behind the ink |
| `assets/<level>/` | Stitched plate strips, one PNG per piece, `level.json` with positions |

The procession is `../art/procession1-15.mdp` whole and as drawn (the `bod_300dpi` plates I–VI, the
frame lines, which the .mdp shows black through clipping layers, and the `text_below` folder), cut by
`../tools/cut_procession300.py`, which reads the .mdp directly. The offering table's loose pieces are the layers of its `table` folder (the layer `table` itself, the table and what stays standing, stays in the picture; the widest piece is the frond; the first `t line` (a long loaf with a line along it) is the loaf the goose-bearer holds, or any layer named with "held"). In `bod_300dpi`, `goose man` is part of the picture, while `avatar` (the player), `goose` and `clothes` are cut as sprites (`LAYER_SPRITES`). Every figure that glows under the pointer, and the ox, the calf and the kneeling adorer, is cut out of its plate's layer onto a layer of its own in `bod_300dpi` (`mourner 1`, `standard-bearer 5`, `stela`, …; `FIGURE_LAYERS` in the cutter lists them by plate). They stay part of the picture: a plate's drawing is its layer and its figures together. The `sprites` folder holds the ending's `stand`, `sun` and `lotus`, copied out of p6: each is cut as the sprite of its name and comes out of the picture, as does the kneeling adorer before Ra (`KNEELER`, cut from p6 as `kneeler`). `../tools/cut_procession300.py --patch art/procession1-15.mdp godot/assets/procession` cuts only these into the strip already there, without the plate scans. The `haul` folder holds the figures of the hauling, copied out of p2 (`sledge` with its rope and the censer priest, `hauler`, `driver`, and `whip`, his forearm and whip, which swings about the elbow): each is cut as a sprite `haul_<layer>` and comes out of the picture. The driver and the water priest of plate V are each a body and an arm in play (`haul_driver_body.png` and `haul_driver_arm.png`, `water_priest_body.png` and `water_priest_arm.png`, from `../tools/arm_sheets.py --parts`): the arm is a child Sprite2D of the body, placed at the elbow drawn on both layers, and the game turns it about there (the whip's angle on the beat; the jar's tilt). Their hand-drawn sheets (`haul_driver_sheet.png`, `water_sheet.png`, each frame the whole man with the arm turned about the elbow) now only give their Journal pictures (the frame as drawn). The water also has the stream (`water_stream`), with `water_path.png` beside it: how far along the stream each pixel lies from the spout, which the shader reveals by. The sheets were made once by `../tools/arm_sheets.py` and are touched up by hand: they are never made again (the tool leaves a sheet already there alone). The stream, and `water_arm` (the forearm cut alone, no longer used in play), are the layers `stream` and `arms` of the `water` folder; `man` (the priest) comes out of the picture while his sheet is there (copied out of p5 and p6; without the folder the cutter falls back on the stand-in in `WATER`: the arm inside a polygon, the stream as the stroke through a seed). `../tools/cut_procession300.py --water art/procession1-15.mdp godot/assets/procession` cuts only the water into the strip already there, and can be run again. The Opening of the Mouth's adze (`mouth_adze`), words (`mouth_words`, the caption over Ra), and face lines (`mouth_features`) are the layers `adze`, `words`, and `features` of the `mouth` folder. The face lines are cut out of `dissected/anubis and the mummy`; the game also lifts that figure out as `mouth_mummy` as the saved figure behind the separate eye and mouth features. `--mouth` refreshes only these pieces and their metadata, restoring previous cuts first so it can run again. The drawing layers p5 and p6 still hold everything these folders copy: the cutter takes out of the picture whatever a folder's layer covers. The `standards` folder (it may stay hidden) holds each god's standard at its drawn place, one layer per standard (`wepwawet`, `thoth`, `falcon1`, `bull`, `vulture`, `placenta`, `plumes`, `falcon2`): each is cut as the sprite `emb_e1`..`emb_e8` (`STANDARD_LAYERS`), and the plates keep the tops of the poles under them; world units are strip pixels and `level.json` carries `"scale": 1.5`
so distances written for the 200-dpi plates still work. The dangers level is exported from the
hand-made 300-dpi strip bod31-42.mdp (one layer per character, text below added) by
`../tools/cut_dangers300.py`; the old 200-dpi cutter `../tools/cut_dangers.py` is kept for reference. Pieces cut apart for a fight have their own layers in the .mdp: the folder `sheaf41` (`stalks`, `band1`..`band4`, the sheaf of spell 41, drawn only there, now inside `snake41`; together they are `bundle41`), the layer `snakeass40/tail` (the donkey's tail in spell 40, drawn only there; its pivot is `tail_root` in `danger_encounters.gd`), and spell 38's two signs, `breath38/ankh` (life, the sprite `ankh38`) and `breath38/t3` (breath, the sail, `sail38`). The cutter is partial: name what changed and only that is cut, into the level already there (`cut_dangers300.py art/dangers31-42.mdp godot/assets/dangers ankh38 sail38`; `tail40` and `sheaf41` cut those pieces); the strip and everything else stay as they are. A whole new cut (`--all`) only when asked for. The cutter keeps the spear-bearers' sprites as they are: if a vignette's figures move in the .mdp, move its spear-bearer's rect in `level.json` and its `tip` in `spearers.json` with them, and the nodes in `scenes/dangers.tscn`. See `../tools/strips/NOTES.md` for the strips.

Procession art exports use the `general` conda environment. The exporter accepts either
`water/arm` or `water/arms` as the existing `water_arm` sprite. The additional mouth layers
`aa column` and `spoon??` export as `mouth_column` and `mouth_spoon`, visible scene props without
new interactions. After exporting, compare IDs and crop bounds and adjust saved scene offsets
for changed crop origins; do not replace deliberate editor placements with source coordinates.

Puzzle writing lives in each level's `assets/<level>/puzzles.json`. Each puzzle lists
`instructions` and `success` as plain strings, then named `feedback` events and Hint-button
`hints`. Alternate instruction or outcome messages are named feedback entries. Level responses
live in top-level `messages`; shared interaction messages live in `assets/messages.json`.
Scripts choose when to display each line and whether it repeats; the catalog holds the wording.

### Editing the Procession pieces

`scenes/procession.tscn` contains saved figures under `pieces/standards`, `hauling`,
`offering_table`, `water`, `opening_mouth`, and `ending`. Each piece has a stable `piece_id`
in Inspector > Metadata; keep these IDs intact when renaming nodes. The avatar and camera
are positioned at the beginning of the scroll, and the background strip is locked.

The editor deliberately shows a mixed arrangement: standards correctly seated, offerings on
the table, the loaf in the bearer's arms, the goose on the floor, and the frond above the table.
The stand, sun and lotus are at their hidden starting locations; the sun is a child of the
sledge artwork so it travels with it. Water is drawn in full; the water priest (`pieces/water/priest`)
and the ox-driver have their arms on them as drawn (the child `arm`, turned in play). The stela imprint, kneeler
and words above Ra are visible. Runtime reset applies the existing puzzle start: shuffled
standards, loose offerings, the raised jar, and the appropriate hidden figures.

Scripts reuse these saved sprites and pivots. Table layout sprites provide restoration targets;
`frond_place` marks the frond's restored top-left position, while its sprite marks its start.
The stela imprint's children retain the stand/sun/lotus restoration coordinates before the
imprint parent's scale and translation. Loose physics bodies, collision geometry and temporary
effects are still created during play. Move a hauling pivot rather than its `sprite` child.

JSON and code still define hotspots, camera ranges, water paths, and several animation targets.
Moving an entire puzzle group, changing pivots or scaling figures needs corresponding updates
to that geometry. Exporting artwork does not overwrite saved scene placement.

### Editing the Dangers figures

`scenes/dangers.tscn` contains the authored figures under `actors`, organized into named spell
folders such as `spell31_crocs`, with readable names such as `croc31a` and
`spear_bearer`. These folders are plain `Node` organizers so they do not introduce transforms. The editor shows the
papyrus arrangement, including the nine spear-bearers and the held breath/ankh. Separate
spear tint overlays and the dismantled sheaf parts are hidden alternatives. Gameplay reset
hides the spear-bearers and sheaf parts according to the existing rules.

Each actor has a stable `actor_id` in Inspector > Metadata, matching its data key. Move the
named actor: startup derives its home and interaction bounds from its position. Single-picture
actors are `Sprite2D` nodes with drawing offsets that preserve their foot pivots. The lunging
snake, creeping snake, Apep and sheaf snake retain a parent and `sprite` child for independently
animated heads or partial drawings. Their children are grouped for selection; the background
strip is locked. `size` metadata describes the original drawing bounds, independently of
sprite-sheet padding. Keep IDs and sprite offsets intact when changing placement.

JSON still holds source-art coordinates, encounter boundaries, and other level data; startup
does not overwrite authored actor positions with its sprite coordinates. Encounter boundaries,
caption regions, and several animation targets still use JSON or code coordinates, so moving
an entire vignette or changing pivots/scale requires corresponding gameplay adjustments.
Temporary fight effects and spawned copies remain generated at runtime. Art exports do not
automatically replace the saved scene layout.

Both crocodile fights: three bites and the bearer crumbles and you are back on the scroll (never an automatic restart); the flesh
sign (your picture at `assets/dangers/figures/flesh.png`, cropped to the sign; native image size, `FLESH_GAP` apart; red dots until it is there) counts his health in red at the
top left. Spell 32 speeds up with every crocodile (`ramp`) but keeps arrivals `min_gap` apart so it
can always be won. `-- --croc-bot` lets a stand-in player (0.35 s reaction, `BOT_REACT=0.7` for a
slower one) fight the next crocodile vignette and prints how many tries it needed.

### Heka signs (red crocodiles)
In `bod31-42.mdp`, move the caption hieroglyphs you choose onto their own layers inside a folder
named `heka`, and run `../tools/cut_dangers300.py` again. Each layer in that folder is lifted out of
the strip as its own sprite: it flashes red on the scroll as you walk by (and in
a crocodile fight once red crocodiles can come); in a fight it also glows under the pointer. Clicking it tells the
player to hold Shift against the red crocodiles.

## Command-line checks
Run both gameplay suites and the camera, figure-mask, hover and UI regressions from the
repository root:
```bash
python3 godot/tests/run_tests.py
```
The runner finds `godot`, `godot4`, or the macOS Godot app; pass `--godot=/path/to/godot`
to choose an executable. It checks exit codes, suite completion and unexpected script or
engine errors. It reports the existing headless glow-shader diagnostic, macOS certificate
diagnostic and exit-time object leak warning separately.

The HUD uses the shared palette in `scripts/ui.gd`: ink, papyrus, the red UI accent,
terracotta danger ink, gold success flashes, and faint placement previews. When a task is done (a fight won, the table rebuilt, the standards in order, ...), everything it set right glows a very slight, unsaturated green and fades (`UI.success_flash`; the colour is `success` in `scripts/glow.gdshader`, with the hover glows). Sprite ink tint
multipliers are distinct from display colors.

Dialogue is always 32 px (two font pixels to a screen pixel) and never paged, centred in the
strip; keep lines to three (about 180 characters). Only the beetles (spell 36) show their progress, as pips above the
vignette; the crocodiles show no count. The bottom strip is 130 px; cameras reserve its height. Intro/outro bodies
use the dialogue size (32 px), up to `OVERLAY_W` wide; panels and the Journal adapt to
window size. Journal entries and intro/outro bodies can scroll when needed.

The Journal ([j]), intros, and outros pause movement, physics, timers, and active fights.
Closing them resumes play; going to another scene clears pause. Arrow keys retain their
gameplay role; a menu button chosen with the keyboard turns red. Enter/Space advances an intro
or outro. Gameplay feedback favors visible actions, first-occurrence failure explanations,
and short phase-change cues over repeated success narration. Explicit Hint remains
repeatable and describes the active task, including fights played out of order.

Click the ox-driver or the empty rope to become the original hauler. Space starts the count-in; pull as
his whip falls. Click the standards to stand at the nearer end of their group and sort
them. Esc or arrow keys leave these scenes.
At the offering table, all loose pieces have gravity, including pieces on the upper
register. The register is a platform; dragging a piece lets it cross. The obsolete task
panel and hidden minimap have been removed. The spell-38 gate opens after the earlier
dangers are overcome and the breath of life is taken.

`-- --journal` opens the Journal for a screenshot. Menu screenshots use `--screen=map`
(or `settings`, `controls`) with `--screenshot=path.png`. The UI regression scene checks
1280×720, 800×600, and 640×480, pagination, carried-item layout, modal pause, active hints,
muted feedback, and start/exit/retry controls. Run it with `--script res://tests/ui_regressions.gd`;
add `-- --ui-images=/tmp/totenbuch-ui` with a rendering backend to capture representative screens.

Shared camera arithmetic lives in `scripts/scroll_camera.gd`; figure ink/interior masks
live in `scripts/figure_mask.gd`. Dangers encounter descriptions and tuning live in
`scripts/dangers/danger_encounters.gd`. Combat behavior, development bots, and encounter-specific
autotests live in `crocodiles.gd` (31–32), `lunging_snake.gd` (33), `creeping_snake.gd` (35),
`beetles.gd` (36), `two_snakes.gd` (37), `apep.gd` (39), `donkey.gd` (40), and `sheaf.gd` (41),
all under `scripts/dangers/`. Each receives the level as its shared scene/state context.
Taking the breath of life (38), walking, progression, arena presentation, and the test runner
remain in `dangers.gd`. Hauling phases use `HaulSledge.Phase`.

```bash
godot --headless --path . -- --level=dangers --autotest
```
Plays the level through the same click handlers the player uses and prints PASS/FAIL per
step. `--level=procession --autotest` does the same for the procession.

```bash
godot --path . -- --level=dangers --skip=8 --at=2950 --wait --screenshot=/tmp/apep.png
```
Marks the first 8 encounters solved, starts the avatar at x=2950 (inside Apep's vignette),
saves a frame and quits. The procession takes `--at=` and `--take=slot` instead of `--skip=`, `--recite` shows the plumed lector's third sign, `--speak` has the lector beside the table show a piece, `--wait` lets the fallen offerings settle first, `--show-hits` outlines every click region, `--ending` puts the stand's three pieces in your hands before Ra, `--finale` also sets them up and kneels (the light, then the menu), `--mouth` opens the face-carving view with the adze in hand and `--open-mouth` finishes the face and releases its words, `--water` stands you at the purifying water and `--pour=rad` also holds the jar at that tilt from as drawn (0 pours along the line), `--haul` takes up the sledge rope at once and `--haul-bot` also pulls on the beats (one off it), and `--record=dir --seconds=N` saves every third frame.

### Editing the Gates level

`scenes/gates.tscn` joins two sources. `art/gates146.mdp` (plates LXV–LXVII) fills x 0–5500:
15 gateways and 15 guardians under `Figures/Spell146`. `art/gates144-145.mdp` (plates LX–LXIV)
follows to its right from x 5500, where the level starts (the scroll reads right to left): the
seven rooms of spell 144 under `Figures/Spell144` (each room's gate, the keeper kneeling inside
and the two gods before it) and the twenty-one pylons of spell 145 under `Figures/Spell145`
(pylon, keeper and adorer). Sprites are named by source plate and carry stable inspection and
source-layer IDs; positions in the scene are authoritative. Each source keeps its own strip
(`Strip`, `Strip144_145`) with its frame, headings and inscriptions. No tall inscription crosses
the walking band, so no foreground column is needed. The level shares Survival's navigation,
inspection, hover and journal script, extended by `scripts/gates/gates.gd`.

The avatar is a copy of the first pylon's adorer. Every adorer starts hidden (in the saved scene
too, and again on restart); `name_given(pylon, accepted)` in `gates.gd`, for the spell-145 naming
puzzle to call, makes that pylon's plumes answer and, for a right name, fades its adorer in.

A pylon's sprite is its structure with the plumes on top (the cut's `structure top` layer).
`scripts/gates/plumes.gdshader` sways everything above the plumes' foot like reeds, each plume a
little out of step with the next; each pylon's material holds that foot (`base`) and the row's
middle and half width, exported as `plumes` in `level.json`. `PylonPlumes.react(pylon, accepted)`
(`scripts/gates/plumes.gd`) makes the plumes stand taller and fan out for a right answer, or sag and
lean apart for a wrong one, then settle; the spell-145 naming puzzle will call it.

Run `python3 tools/build_gates_scene.py` to refresh the exported artwork and metadata.
The exporter preserves the MDPs and existing descriptions; to an already saved scene it only
adds sprites that are missing from it.
Use `-- --level=gates --at=2750` to jump into spell 146, or add
`--screenshot=/tmp/gates.png` for a temporary rendered preview.
