# Totenbuch (Godot 4)

Levels of the Book of the Dead as a point-and-click game, built from Lepsius's
*Das Todtenbuch der Ägypter* (1842). Every figure is cut from the plate scans; nothing is redrawn.

Open `project.godot` in Godot 4.7+ and press **Play** (F5). A level menu opens first.

The scroll reads right to left. Click the papyrus (or use ← →) to walk.

The captions in the top register are the spells' titles. Click one (it glows under the pointer) and
the strip shows its translation, from C. H. S. Davis, *The Egyptian Book of the Dead* (1894), which
translates this same papyrus: `CAPTIONS` in `scripts/procession.gd`, and each danger's `caption` and
`title` in `scripts/danger_encounters.gd`.

Only the procession and the dangers are in play; the Night Journey, the Field of Offerings and the
Weighing of the Heart are set aside in `../archive/` (see its README), left out of the game and the tests.

## The Funeral Procession (spells 1–15, pl. I–VI)
Whatever can be clicked glows under the pointer (`scripts/glow.gdshader`; all eight standard-bearers glow together). Click figures to record them in the journal; click a movable piece to pick it up and click
where it belongs to set it down (clicking a filled place swaps the two). Click where you took it to put it back.
The whole scroll can be walked from the start.

1. **Haul the bier** (plate II): click the ox-driver for instructions and become the original hauler. Clicking the bier or censer priest directs you to him. Space starts the count-in. The vignette opens over plate I and the train stands back from its place. Pull with Space, Shift, or click as the whip falls; the drum and whip provide the beat. An early or late pull lets the rope slacken and the bier slip back; a missed beat stops it. The hauler leans and the train moves on accepted pulls. Twelve pulls without setbacks bring it home. Esc or arrow keys let go and restore the walking avatar. Tuned in `scripts/haul.gd` (`BEAT`, `WINDOW`, `BACK`, `PULLS`, `SLIP`).
2. **Return the standards**: click the eight standard-bearers to stand at their nearer end and frame the group. Esc or arrows leave the scene and return any carried standard. The bearers (four in plate III, four in plate II) carry the wrong gods; the two falcons are interchangeable. The lector with two plumes on his head (plate V, past the offering table) reads out the order when clicked: the eight signs appear one after another in the space above his sheet, jackal first at the far end, falcon last in front of his plumes (`RECITE_*` in `procession.gd`; the line's place is `recital` in `level.json`).
3. **Rebuild the offering table** (`scripts/offering_table.gd`): the heap in plate IV has collapsed. Click the table (or a piece, the lector or the goose-bearer) and you step up to it: you stand just behind the lector and the camera holds on the table, from the man with the jar to the goose-bearer (`view`, `stand` in `level.json` `table`). Esc, or walking off with the arrow keys, steps away; nothing is lost, and what you held goes back. The loose pieces lie on the floor between the two pairs of bouquets as physics bodies, at any angle, each with a faint papyrus fill (50%) inside its outline; the palm frond lies flat on the upper register line, towards the right. At first everything else falls through that line to the floor. Press on a piece to take it up (it comes to the front, follows the pointer, and its place shows faintly); let go after dragging, or click again, to set it down. Near its place it goes in, but only once everything it rests on is there (`rests_on`, worked out by the cutter); otherwise it topples back down. Every loose piece has gravity. Set down above the upper-register platform, a piece falls onto it; only a piece being actively dragged can cross it. The frond goes on last. Clicking the lector shows, in front of him, a piece that can go on now (again for the next one).
4. **Give the goose back**: the man beside the lector holds a loaf from the heap instead of his goose, which lies among the fallen offerings. Take the loaf from him, then give him the goose. While nothing is in his arms, the clothes the goose and loaf cover show.
5. **Pour the water** (`scripts/pour_water.gd`, plate V): a priest raises a round jar over a kneeling woman, and the wavy line from it, arching over Anubis holding the mummy upright and down to their base, is the stream. At the start his arm is raised further, the jar upright, and no water runs: only a faint dotted ghost of the line (`scripts/water.gdshader`). Click the priest, the woman, Anubis and the mummy, or the jar, and you step up behind him; the camera holds on the scene (`view`, `stand` in `level.json` `water`). Press on the jar and drag to turn his forearm about the elbow. Within `WINDOW` of the tilt as drawn the water runs along the line and the line draws itself in, but only while the jar is held steady (`STEADY`); too shallow and it only drips, too steep and it gushes out and splashes on the woman's raised hands. Not pouring along the line, the drawn part dries back, never below `KEEP` of the furthest it reached. Let go and the arm rises back upright. Once the whole line is drawn the jar settles where it is drawn. Esc, or walking off, steps away.
6. **Open the mummy's mouth** (`scripts/opening_mouth.gd`, plates V–VI; no game in the touch yet): the caption over Ra, the lotus stand and the kneeler is gone, only a faint imprint of it showing. Click the adze on the offering stand by the obelisks (the hooked blade, third from the top) and it follows the pointer; click the mummy with it and the adze goes back on the stand, and the words come out of the mummy's mouth as a small ball that rises and unrolls into their line in the empty caption band above the mummy (`mouth.speak_right` in `level.json`). Click the line to take it, and click its imprint over Ra to set it there, as drawn. To put the adze back, click its place on the stand; the words, their place above the mummy.
7. **Set up the offering stand before Ra** (`scripts/ending.gd`, plate VI): the stand, the sun disc on it and the lotus over it are gone from before Ra, and so is the adorer kneeling to him. Once rites 1–6 are done, the stela beside the tomb shows a faint imprint of the three as they stand; until then its face is blank (a soft lock: the stand can still be set up early, but then clicking it or Ra only says that some things have not been set right yet, and the finale waits for the other rites). They lie hidden along the scroll, and glow under the pointer: the stand inside the canopy frame behind the women mourners (pl. I), the sun disc between the legs of the creature on the mummy's bier (pl. II; it rides with the sledge), the lotus on top of the second offering pile (pl. V). Click one to take it; you carry all you find. Click the empty place before Ra to set them up: each goes on only once what it rests on is there (stand, sun, lotus). Where they hide is `ending.hide` in `level.json`.

With all seven done you walk to the adorer's place and kneel there (the drawn adorer, cut as `kneeler`, takes your place), light spreads from Ra's disc and the new sun (`scripts/light.gdshader`) and floods the screen, and the level goes back to the menu (for now; later, on to the next level).

## Dangers on the Road (spells 31–42, pl. XVI–XIX)
You can walk through every vignette. Click a creature (it glows under the pointer) to walk into
its vignette, become its spear-bearer and start the fight; in the fights that open out, Space
thrusts and holding Shift lends the thrust heka. Walking into a vignette says its danger's line (each time, until it is overcome). Clicking the creature opens the fight, which waits for Space: that first press starts it with a thrust that does not count (it strikes nothing, ties no band). Once a fight starts, every spear-bearer rests
with the spear drawn back, and a thrust only runs it out and draws it back again; once it is overcome the vignette is put back as drawn.
You can walk into spell 38 (the breath of life) and take it at any time, but not on past it until spells 31–38 are all done (an invisible barrier at its far edge; the scribe says what is still to do), and spell 42
at the end waits until every danger before it is overcome.

| Spell | Rule |
|---|---|
| 31 | The vignette opens out to the left (the double line behind you stays; the caption banner stays; the text below drops away). You are the spear-bearer: ↑ ↓ / W S move you, Space thrusts; only the spear point strikes, anywhere on a crocodile (or right by its snout) before it reaches you. Crocodiles never come with their front halves on top of each other, nor one right after another at the same spot. The last crocodile of each wave is always one of the drawn ones squatting on screen. Wave 1 is the lesson (a thrust, a move, one slow crocodile, two more). Then a break: the heka word in the banner starts flashing red (click it for the hold-Shift hint). Wave 2 has red crocodiles (`red_order`), turned back only by a thrust while holding Shift. Bites redden the body; heka on an ordinary crocodile, or one slipping past you once the word glows, loses, with one animation for both: the crocodile laughs (squashes up and down) and turns round, the word spins down into its jaws, he crumbles the moment it lands, and it carries the word off. You are back on the scroll; click a crocodile to fight again, always from wave 1. Each crocodile of a wave is `ramp` faster than the one before. The last crocodile of the fight is the last one on screen: every drawn one has come before it, and it sets off only once the others are gone. Tuned in `ENCOUNTERS` (`waves`, `break`, `ramp`) |
| 32 | The same, faster, two at a time and from both sides: you stand in the middle, ← → turn you, ↑ ↓ move you. When spacing them, one from the other side counts as if it came from the same side. Some crocodiles come red (`red` chance): hold Shift (heka; the spear turns red) as you thrust to turn those back. A plain thrust does nothing to a red one; heka on an ordinary one loses: it takes the heka word as in spell 31, and you are back on the scroll. Bites redden the body, heka reddens the spear |
| 33 | Close up (caption to ground). He stays where he is drawn, spear raised; Space thrusts. The snake coils just out of reach, breathing; its tail waves (the warning, `snake_tail.gdshader` bends the drawing), it squashes, and snaps to his front leg (its body passes behind his skirt, its head in front). Thrust as it springs: the point must come down on the red mark, at the spot where it is drawn. The mark shrinks with each strike (`marks`: radius 11, 8, 5 plate px, a window of about 170 ms down to 85 ms); no count is shown. Too early, the spear is already rising again. Three strikes (`need`; for five, give `marks` five sizes); three bites and he crumbles. Tuned in its `ENCOUNTERS` entry |
| 35 | Red light, green light: creep up (←) on the snake from behind and freeze whenever it lifts its head and looks. A small red dot shows where the spear point will land; thrust when it is on its eye (`eye`; the rest of the head does not count, and the scribe says so). Struck, it slides on; three strikes; three bites and he crumbles |
| 36 | The vignette opens out; you stand still in the middle: ← → turn you, Space thrusts. Three beetles (`count`: the drawn one and two copies) dart about very fast; every couple of darts each stops by the point of your spear on your left or right for 0.35–0.75 s (some stops just out of reach). Only the spear point at the full thrust pins one (its body, or with `dot` only a red dot on its back); a catch holds everything for 0.5 s and that beetle is gone. Pin all three to win. A beetle that stops within reach and gets away has passed the point: it reddens a step each time, and once it has passed `passes` (3) times, the next time it gets away they multiply until they fill the vignette, the bearer crumbles, and you are back on the scroll. Set `passes` to 5 for an easier fight |
| 37 | Close up; he stands in the middle as drawn, ← → turn him, Space thrusts. The drawn snake on his left and a mirrored copy on his right wait coiled `rest` (90) plate px out from where they are drawn, facing him, breathing. One of the two snake signs in the caption flashes red (left sign, left snake); that snake squashes down and springs at his foot, passing the spot where it is drawn. Thrust facing it as it passes (`reach` 12 → 7 plate px; a window of about 110 ms down to 90 ms); a thrust at a coiled snake makes it spring at once. Each struck twice falls where it is drawn; three bites and he crumbles. `warn`, `crouch`, `snap` and `reach` tighten with each strike |
| 38 | Take the ankh and sail, the breath of life |
| 39 | Close up, the whole vignette across. He stays where he is drawn, the barb resting a little way up its line from Apep's neck (where the body folds back); Space thrusts. Now and then the tail lashes and a wave runs the length of Apep to the fold (`apep_wave.gdshader` lifts the drawing column by column); his head strains up as it comes. Thrust as the crest reaches the point: the wave is pressed flat, Apep flushes red, and the barb rests a step further in (`need` 6 steps; at the last the spear is as drawn). A wave that gets past rears his head out from under the barb, round to bite the bearer's foot. After the first two (`teach`), a share of waves (`feint`) are smaller and die out in the drawn hump; a thrust on a still neck works the barb loose a step. The waves come faster (`speed` 220 → 380 plate px/s), closer together (`gap`, never two at the point within `min_gap`), and the crest must be nearer the point (`reach` 10 → 5 plate px: a window of about 155 ms down to 135 ms). No count is shown; three bites and he crumbles. Tuned in its `ENCOUNTERS` entry |
| 40 | Close up. The snake's head is down in the donkey's back: a thrust then goes into the donkey and he crumbles at once. Now and then the donkey swishes its tail (`tail40`, cut from the donkey, turns about its root) and the snake lifts its front up the spear's line to snap at it (`lift_end.gdshader`), for `up` s (0.6 → 0.38, ±25%): Space then strikes it. After the first strike some swishes are only flicks (`flick` 45%), and it does not look up. Left alone, its coils tighten and it bites the donkey every `bite_every` s (4.5 → 3.6); the flesh signs count the donkey's health, and the third bite and the donkey is eaten. It always looks up at least once before each bite, and a strike sets the bite back. Three strikes win. `DONKEY_CURVE=1` with `--autotest` prints how often a stand-in player wins at each reaction time |
| 41 | Tie the sheaf’s four bands while the stirring is above the next band, then spear the snake as its head emerges |
| 42 | End of the level. Spell 42 is text only (each body part given to a god) and is not a puzzle yet |

## Layout
| Path | What |
|---|---|
| `scenes/menu.tscn`, `scripts/menu.gd` | The title page (Play, The scroll, Settings, Quit), the map of the scroll (every scene act by act, reading right to left), Settings (sound, fullscreen, controls, beginning again) |
| `scripts/scroll.gd` | Autoload `Scroll`: the scenes in playing order (Lepsius's spell order, the weighing of the heart last), which are restored, and the settings, kept in `user://scroll.cfg`. A scene counts as built once `scenes/<key>.tscn` exists; finishing one opens the next built scene |
| `scripts/ui.gd` | The shared look (`UI`): palette, Old Fax, square panels, the frame band, pixel icon buttons |
| `scenes/procession.tscn`, `scripts/procession.gd` | Spells 1–15 |
| `scenes/dangers.tscn`, `scripts/dangers.gd` | Spells 31–42: encounter list, gates, one rule set per creature |
| `scripts/avatar.gd` | Walking (click target or keyboard), facing, bobbing |
| `scripts/hud.gd` | Title bar (Restart, Menu), the scribe's strip under the scene (the line said with its speaker's tag, what you carry, Journal and Hint), the Journal page ([j]), intro/outro; each level passes its own texts |
| `assets/menu/` | A picture per scene for the map (frames of the built levels, crops of the plates for the rest) and the title page's frontispiece, made by `../tools/menu_images.py` |
| `assets/ui/`, `assets/fonts/OldFax.ttf` | The scroll's frame band as tiles (`band_top`, and `band_bottom`/`band_left`/`band_right` for the screen's edges), icons (Journal is 𓏞, the scribe's kit; Hint is 𓂜; Restart and Levels are placeholders), and the pixel font (16 px is one font pixel, 32 px two) |
| `scripts/papyrus.gdshader` | Procedural papyrus fibres behind the ink |
| `assets/<level>/` | Stitched plate strips, one PNG per piece, `level.json` with positions |

The procession is `../art/procession1-15.mdp` whole and as drawn (the `bod_300dpi` plates I–VI, the
frame lines, which the .mdp shows black through clipping layers, and the `text_below` folder), cut by
`../tools/cut_procession300.py`, which reads the .mdp directly. The offering table's loose pieces are the layers of its `table` folder (the layer `table` itself, the table and what stays standing, stays in the picture; the widest piece is the frond; the first `t line` (a long loaf with a line along it) is the loaf the goose-bearer holds, or any layer named with "held"). In `bod_300dpi`, `goose man` is part of the picture, while `avatar` (the player), `goose` and `clothes` are cut as sprites (`LAYER_SPRITES`). The `sprites` folder holds the ending's `stand`, `sun` and `lotus`, copied out of p6: each is cut as the sprite of its name and comes out of the picture, as does the kneeling adorer before Ra (`KNEELER`, cut from p6 as `kneeler`). `../tools/cut_procession300.py --patch art/procession1-15.mdp godot/assets/procession` cuts only these into the strip already there, without the plate scans. The `haul` folder holds the figures of the hauling, copied out of p2 (`sledge` with its rope and the censer priest, `hauler`, `driver`, and `whip`, his forearm and whip, which swings about the elbow): each is cut as a sprite `haul_<layer>` and comes out of the picture. The water of plate V is the priest's forearm with his hand and the jar (`water_arm`, turning about the elbow) and the stream (`water_stream`), with `water_path.png` beside it: how far along the stream each pixel lies from the spout, which the shader reveals by. They are the layers `arm` and `stream` of the `water` folder (copied out of p5 and p6; without the folder the cutter falls back on the stand-in in `WATER`: the arm inside a polygon, the stream as the stroke through a seed). `../tools/cut_procession300.py --water art/procession1-15.mdp godot/assets/procession` cuts only the water into the strip already there, and can be run again. The Opening of the Mouth's adze (`mouth_adze`) and words (`mouth_words`, the caption over Ra) are the layers `adze` and `words` of the `mouth` folder (copied out of p5 and p6; the stand-in is in `MOUTH`), and `--mouth` cuts only them. The drawing layers p5 and p6 still hold everything these folders copy: the cutter takes out of the picture whatever a folder's layer covers. The `standards` folder (it may stay hidden) holds each god's standard at its drawn place, one layer per standard (`wepwawet`, `thoth`, `falcon1`, `bull`, `vulture`, `placenta`, `plumes`, `falcon2`): each is cut as the sprite `emb_e1`..`emb_e8` (`STANDARD_LAYERS`), and the plates keep the tops of the poles under them; world units are strip pixels and `level.json` carries `"scale": 1.5`
so distances written for the 200-dpi plates still work. The dangers level is exported from the
hand-made 300-dpi strip bod31-42.mdp (one layer per character, text below added) by
`../tools/cut_dangers300.py`; the old 200-dpi cutter `../tools/cut_dangers.py` is kept for reference. Pieces cut apart for a fight have their own folders in the .mdp, copies of ink still in the drawing (the cutter keeps them out of the strip): `sheaf41` (`stalks`, `band1`..`band4`, the sheaf of spell 41) and `tail40` (`tail`, the donkey's tail in spell 40). Redraw a piece in its layer and run the cutter again (or only `--sheaf` / `--tail`). See `../tools/strips/NOTES.md` for the strips.

Both crocodile fights: three bites and the bearer crumbles and you are back on the scroll (never an automatic restart); the flesh
sign (your picture at `assets/dangers/flesh.png`; red dots until it is there) counts his health in red at the
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
terracotta danger ink, gold success flashes, and faint placement previews. Sprite ink tint
multipliers are distinct from display colors.

Dialogue is always 32 px (two font pixels to a screen pixel) and never paged, centred in the
strip; keep lines to three (about 180 characters). A fight shows its progress as pips above the
vignette. The bottom strip is 130 px; cameras reserve its height. Intro/outro bodies
use 16 px with additional line and paragraph spacing; panels and the Journal adapt to
window size. Journal entries and intro/outro bodies can scroll when needed.

The Journal ([j]), intros, and outros pause movement, physics, timers, and active fights.
Closing them resumes play; going to another scene clears pause. Arrow keys retain their
gameplay role; a menu button chosen with the keyboard turns red. Enter/Space advances an intro
or outro. Gameplay feedback favors visible actions, first-occurrence failure explanations,
and short phase-change cues over repeated success narration. Explicit Hint remains
repeatable and describes the active task, including fights played out of order.

Click the ox-driver to become the original hauler. Space starts the count-in; pull as
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
`scripts/danger_encounters.gd`, and spell 35 uses `scripts/creeping_snake_state.gd` for its
typed animation state. Hauling phases use `HaulSledge.Phase`.

```bash
godot --headless --path . -- --level=dangers --autotest
```
Plays the level through the same click handlers the player uses and prints PASS/FAIL per
step. `--level=procession --autotest` does the same for the procession.

```bash
godot --path . -- --level=dangers --skip=8 --at=2950 --wait --screenshot=/tmp/apep.png
```
Marks the first 8 encounters solved, starts the avatar at x=2950 (inside Apep's vignette),
saves a frame and quits. The procession takes `--at=` and `--take=slot` instead of `--skip=`, `--recite` shows the plumed lector's whole line at once, `--speak` has the lector beside the table show a piece, `--wait` lets the fallen offerings settle first, `--show-hits` outlines every click region, `--ending` puts the stand's three pieces in your hands before Ra, `--finale` also sets them up and kneels (the light, then the menu), `--mouth` stands you by the mummy with the adze in hand and `--open-mouth` also touches it, `--water` stands you at the purifying water and `--pour=rad` also holds the jar at that tilt from as drawn (0 pours along the line), `--haul` takes up the sledge rope at once and `--haul-bot` also pulls on the beats (one off it), and `--record=dir --seconds=N` saves every third frame.
