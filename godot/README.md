# Totenbuch (Godot 4)

Levels of the Book of the Dead as a point-and-click game, built from Lepsius's
*Das Todtenbuch der Ägypter* (1842). Every figure is cut from the plate scans.

Open `project.godot` in Godot 4.7+ and press **Play** (F5). A level menu opens first.

The scroll reads right to left. Click the papyrus (or use ← →) to walk.

## The Funeral Procession (spells 1–15, pl. I–VI)
Whatever can be clicked glows under the pointer (`scripts/glow.gdshader`; a standard-bearer glows whole, man and standard). Click figures to record them in the journal; click a movable piece to pick it up and click
where it belongs to set it down (clicking a filled place swaps the two). **Esc** puts it back.
The whole scroll can be walked from the start.

1. **Haul the sledge** (plate II): nobody is on the rope at first; click the ox-driver, the censer priest or the sledge to take it up yourself, standing where the hauler is drawn. The drawn hauler only appears, on his rope, once the sledge is home. The vignette opens out over the start of plate I and the train (ox, driver, hauler, priest, sledge) stands back from its place. The driver's whip is drawn back and comes down on every beat, with a drum: press Space, Shift or click as it comes down and you lean into the rope and the train gains a step; off the beat the rope goes slack and the sledge slips back; a beat let pass and it stops. Twelve good pulls bring it to where it is drawn. Esc lets go. Tuned in `scripts/haul.gd` (`BEAT`, `WINDOW`, `BACK`, `PULLS`, `SLIP`).
2. **Return the standards**: the eight standard-bearers (four in plate III, four in plate II) carry the wrong gods; the two falcons are interchangeable. An empty pole shows a faint outline of its own standard. The lector with two plumes on his head (plate V, past the offering table) reads out the order when clicked: the eight signs appear one after another in the space above his sheet, jackal first at the far end, falcon last in front of his plumes (`RECITE_*` in `procession.gd`; the line's place is `recital` in `level.json`).
3. **Rebuild the offering table** (`scripts/offering_table.gd`): the heap in plate IV has collapsed. Click the table (or a piece, the lector or the goose-bearer) and you step up to it: you stand just behind the lector and the camera holds on the table, from the man with the jar to the goose-bearer (`view`, `stand` in `level.json` `table`). Esc, or walking off with the arrow keys, steps away; nothing is lost, and what you held goes back. The loose pieces lie on the floor between the two pairs of bouquets as physics bodies, at any angle, each with a faint papyrus fill (50%) inside its outline; the palm frond lies in the empty band above, a little to the right. Press on a piece to take it up (it comes to the front, follows the pointer, and its place shows faintly); let go after dragging, or click again, to set it down. Near its place it goes in, but only once everything it rests on is there (`rests_on`, worked out by the cutter); otherwise it topples back down. Set down in the band above the picture, it lies there out of the way until taken up again. The frond goes on last. Clicking the lector shows, in front of him, a piece that can go on now (again for the next one).
4. **Give the goose back**: the man beside the lector holds a loaf from the heap instead of his goose, which lies among the fallen offerings. Take the loaf from him, then give him the goose. While nothing is in his arms, the clothes the goose and loaf cover show.
5. **Pour the water** (`scripts/pour_water.gd`, plate V): a priest raises a round jar over a kneeling woman, and the wavy line from it, arching over Anubis holding the mummy upright and down to their base, is the stream. At the start his arm is raised further, the jar upright, and no water runs: only a faint dotted ghost of the line (`scripts/water.gdshader`). Click the priest, the woman, Anubis and the mummy, or the jar, and you step up behind him; the camera holds on the scene (`view`, `stand` in `level.json` `water`). Press on the jar and drag to turn his forearm about the elbow. Within `WINDOW` of the tilt as drawn the water runs along the line and the line draws itself in, but only while the jar is held steady (`STEADY`); too shallow and it only drips, too steep and it gushes out and splashes on the woman's raised hands. Not pouring along the line, the drawn part dries back, never below `KEEP` of the furthest it reached. Let go and the arm rises back upright. Once the whole line is drawn the jar settles where it is drawn. Esc, or walking off, steps away.
6. **Open the mummy's mouth** (`scripts/opening_mouth.gd`, plates V–VI; no game in the touch yet): the caption over Ra, the lotus stand and the kneeler is gone, only a faint imprint of it showing. Click the adze on the offering stand by the obelisks (the hooked blade, third from the top) and it follows the pointer; click the mummy with it and the adze goes back on the stand, and the words come out of the mummy's mouth as a small ball that rises and unrolls into their line in the empty caption band above the mummy (`mouth.speak_right` in `level.json`). Click the line to take it, and click its imprint over Ra to set it there, as drawn. Esc puts the adze back on the stand, or the words back above the mummy.
7. **Set up the offering stand before Ra** (`scripts/ending.gd`, plate VI): the stand, the sun disc on it and the lotus over it are gone from before Ra, and so is the adorer kneeling to him. Once rites 1–6 are done, the stela beside the tomb shows a faint imprint of the three as they stand; until then its face is blank (a soft lock: the stand can still be set up early, but then clicking it or Ra only says that some things have not been set right yet, and the finale waits for the other rites). They lie hidden along the scroll, and glow under the pointer: the stand inside the canopy frame behind the women mourners (pl. I), the sun disc between the legs of the creature on the mummy's bier (pl. II; it rides with the sledge), the lotus on top of the second offering pile (pl. V). Click one to take it; you carry all you find. Click the empty place before Ra to set them up: each goes on only once what it rests on is there (stand, sun, lotus). Where they hide is `ending.hide` in `level.json`.

With all seven done you walk to the adorer's place and kneel there (the drawn adorer, cut as `kneeler`, takes your place), light spreads from Ra's disc and the new sun (`scripts/light.gdshader`) and floods the screen, and the level goes back to the menu (for now; later, on to the next level).

## The Night Journey (spell 17, pl. VII–XI)
The cleaned 300-dpi strip bod17-21, used as drawn; the movable pieces are lifted out by
`../tools/cut_cosmos300.py`, which also adds the plates' text below the frame (fading out).

1. **Open the horizon**: the two lions face each other and shut the sun in. Click each to turn it; back to back (as drawn) the sun rises.
2. **Return the ba to the body**: the human-headed bird waits at the head of the strip. Carry it to the mummy on the lion bier.
3. **Help the cat at the persea tree**: the snake creeps in and draws back. Click the cat when the head is under its knife (twice).
4. **Give Ra his sun**: carry the risen sun to the god in Ra's boat (pl. X); the baboons adore.
5. **Come before Osiris** (pl. XI).

The horizon, the snake and Ra's boat each bar the way until dealt with. `--skip=N` solves the
first N tasks; `--show-hits` outlines the click regions.

## The Field of Offerings (spell 110, pl. XLI)
The whole page in three bands framed by water; the camera shows one band, and clicking another
band crosses over (the lowest band is entered at its left end).

1. **Work the field** (middle band, right to left): click the ploughman, then the sower; the grain grows; click a reaper, then the ox on the threshing floor. Out of order, the field is not ready. The grain heaps rise.
2. **Feed the gods**: take grain from a heap and give it to the offering table before the three gods (top band).
3. **Cross by the boat**: the rower in the top band now takes you over.
4. **Sail to the landing**: in the lowest band, the boat with stairs has no oars; the one with oars sails to the landing stairs.

`--reg=middle`, `--stage=N` (farming stages done), `--skip=N` (tasks done).

## The Weighing of the Heart (spell 125, pl. L)
1. **Ma'at** lets you into the hall.
2. **Set your heart on the balance** (right pan): the beam tips, Ammit rises.
3. **The 42 judges** in the frieze: click each; every declaration of the negative confession lifts the heart a little. When all have heard you the beam is level and the baboon on the post nods.
4. **Thoth** writes the verdict (before that, Ammit lunges).
5. **Osiris** receives you.

`--declared=N`, `--skip=N`. Both levels are cut from the 300-dpi panel sheets by `../tools/cut_sheets300.py`.

## Dangers on the Road (spells 31–42, pl. XVI–XIX)
You can walk through every vignette. Click a creature (it glows under the pointer) to walk into
its vignette, become its spear-bearer and start the fight; in the fights that open out, Space
thrusts and holding Shift lends the thrust heka. Once a fight starts, every spear-bearer rests
with the spear drawn back, and a thrust only runs it out and draws it back again; once it is overcome the vignette is put back as drawn.
You can walk into spell 38 (the breath of life) and take it at any time, but not on past it until spells 31–38 are all done (an invisible barrier at its far edge; the scribe says what is still to do), and spell 42
at the end waits until every danger before it is overcome.

| Spell | Rule |
|---|---|
| 31 | The vignette opens out to the left (the double line behind you stays; the caption banner stays; the text below drops away). You are the spear-bearer: ↑ ↓ / W S move you, Space thrusts; only the spear point strikes, anywhere on a crocodile (or right by its snout) before it reaches you. Crocodiles never come with their front halves on top of each other, nor one right after another at the same spot. The last crocodile of each wave is always one of the drawn ones squatting on screen. Wave 1 is the lesson (a thrust, a move, one slow crocodile, two more). Then a break: the heka word in the banner starts flashing red (click it for the hold-Shift hint). Wave 2 has red crocodiles (`red_order`), turned back only by a thrust while holding Shift. Bites redden the body; heka on an ordinary crocodile, or one slipping past you once the word glows, loses, with one animation for both: the crocodile laughs (squashes up and down) and turns round, the word spins down into its jaws, he crumbles the moment it lands, and it carries the word off. You are back on the scroll; click a crocodile to fight again, always from wave 1. Each crocodile of a wave is `ramp` faster than the one before. The last crocodile of the fight is the last one on screen: every drawn one has come before it, and it sets off only once the others are gone. Tuned in `ENCOUNTERS` (`waves`, `break`, `ramp`) |
| 32 | The same, faster, two at a time and from both sides: you stand in the middle, ← → turn you, ↑ ↓ move you. When spacing them, one from the other side counts as if it came from the same side. Some crocodiles come red (`red` chance): hold Shift (heka; the spear turns red) as you thrust to turn those back. A plain thrust does nothing to a red one; heka on an ordinary one loses: it takes the heka word as in spell 31, and you are back on the scroll. Bites redden the body, heka reddens the spear |
| 33 | Close up (caption to ground). He stays where he is drawn, spear raised; Space thrusts. The snake coils just out of reach, breathing; its tail waves (the warning, `snake_tail.gdshader` bends the drawing), it squashes, and snaps to his front leg (its body passes behind his skirt, its head in front). Thrust as it springs: the point must come down on the red mark, at the spot where it is drawn. The mark shrinks with each strike (`marks`: radius 11, 8, 5 plate px, a window of about 170 ms down to 85 ms); no count is shown. Too early, the spear is already rising again. Three strikes (`need`; for five, give `marks` five sizes); three bites and he crumbles. Tuned in its `ENCOUNTERS` entry |
| 35 | A snake slides in and out of reach; strike when it reaches the spear tip (twice) |
| 36 | The vignette opens out; you stand still in the middle: ← → turn you, Space thrusts. Three beetles (`count`: the drawn one and two copies) dart about very fast; every couple of darts each stops by the point of your spear on your left or right for 0.35–0.75 s (some stops just out of reach). Only the spear point at the full thrust pins one (its body, or with `dot` only a red dot on its back); a catch holds everything for 0.5 s and that beetle is gone. Pin all three to win. A beetle that stops within reach and gets away has passed the point: it reddens a step each time, and once it has passed `passes` (3) times, the next time it gets away they multiply until they fill the vignette, the bearer crumbles, and you are back on the scroll. Set `passes` to 5 for an easier fight |
| 37 | Two coiled snakes rear; strike twice at full height |
| 38 | Take the ankh and sail, the breath of life |
| 39 | Apep's coils rise one at a time; strike only the risen coil (a wrong strike frees a pinned one) |
| 40 | Strike the snake on the donkey's back three times; hitting the donkey costs a hit |
| 41 | Heads rise from the reeds; strike them while they show (three times) |
| 42 | End of the level. Spell 42 is text only (each body part given to a god) and is not a puzzle yet |

## Layout
| Path | What |
|---|---|
| `scenes/menu.tscn`, `scripts/menu.gd` | Level select |
| `scenes/procession.tscn`, `scripts/procession.gd` | Spells 1–15 |
| `scenes/cosmos.tscn`, `scripts/cosmos.gd` | Spell 17 |
| `scenes/field.tscn`, `scripts/field.gd` | Spell 110 |
| `scenes/hall.tscn`, `scripts/hall.gd` | Spell 125 |
| `scenes/dangers.tscn`, `scripts/dangers.gd` | Spells 31–42: encounter list, gates, one rule set per creature |
| `scripts/avatar.gd` | Walking (click target or keyboard), facing, bobbing |
| `scripts/hud.gd` | Title bar (Restart, Levels), the scribe's strip under the scene (the line said with its speaker's tag, what you carry, Journal and Hint), the Journal page ([j]), intro/outro; each level passes its own texts |
| `assets/ui/`, `assets/fonts/OldFax.ttf` | The scroll's frame band as tiles (`band_top`, and `band_bottom`/`band_left`/`band_right` for the screen's edges), icons (Journal is 𓏞, the scribe's kit; Hint is 𓂜; Restart and Levels are placeholders), and the pixel font (16 px is one font pixel, 32 px two) |
| `scripts/papyrus.gdshader` | Procedural papyrus fibres behind the ink |
| `assets/<level>/` | Stitched plate strips, one PNG per piece, `level.json` with positions |

The procession is `../art/procession1-15.mdp` whole and as drawn (the `bod_300dpi` plates I–VI, the
frame lines, which the .mdp shows black through clipping layers, and the `text_below` folder), cut by
`../tools/cut_procession300.py`, which reads the .mdp directly. The offering table's loose pieces are the layers of its `table` folder (the layer `table` itself, the table and what stays standing, stays in the picture; the widest piece is the frond; the first `t line` (a long loaf with a line along it) is the loaf the goose-bearer holds, or any layer named with "held"). In `bod_300dpi`, `goose man` is part of the picture, while `avatar` (the player), `goose` and `clothes` are cut as sprites (`LAYER_SPRITES`). The `sprites` folder holds the ending's `stand`, `sun` and `lotus`, copied out of p6: each is cut as the sprite of its name and comes out of the picture, as does the kneeling adorer before Ra (`KNEELER`, cut from p6 as `kneeler`). `../tools/cut_procession300.py --patch art/procession1-15.mdp godot/assets/procession` cuts only these into the strip already there, without the plate scans. The `haul` folder holds the figures of the hauling, copied out of p2 (`sledge` with its rope and the censer priest, `hauler`, `driver`, and `whip`, his forearm and whip, which swings about the elbow): each is cut as a sprite `haul_<layer>` and comes out of the picture. The water of plate V is the priest's forearm with his hand and the jar (`water_arm`, turning about the elbow) and the stream (`water_stream`), with `water_path.png` beside it: how far along the stream each pixel lies from the spout, which the shader reveals by. They are the layers `arm` and `stream` of the `water` folder (copied out of p5 and p6; without the folder the cutter falls back on the stand-in in `WATER`: the arm inside a polygon, the stream as the stroke through a seed). `../tools/cut_procession300.py --water art/procession1-15.mdp godot/assets/procession` cuts only the water into the strip already there, and can be run again. The Opening of the Mouth's adze (`mouth_adze`) and words (`mouth_words`, the caption over Ra) are the layers `adze` and `words` of the `mouth` folder (copied out of p5 and p6; the stand-in is in `MOUTH`), and `--mouth` cuts only them. The drawing layers p5 and p6 still hold everything these folders copy: the cutter takes out of the picture whatever a folder's layer covers. The `standards` folder (it may stay hidden) holds each god's standard at its drawn place, one layer per standard (`wepwawet`, `thoth`, `falcon1`, `bull`, `vulture`, `placenta`, `plumes`, `falcon2`): each is cut as the sprite `emb_e1`..`emb_e8` (`STANDARD_LAYERS`), and the plates keep the tops of the poles under them; world units are strip pixels and `level.json` carries `"scale": 1.5`
so distances written for the 200-dpi plates still work. The dangers level is exported from the
hand-made 300-dpi strip bod31-42.mdp (one layer per character, text below added) by
`../tools/cut_dangers300.py`; the old 200-dpi cutter `../tools/cut_dangers.py` is kept for reference. See `../tools/strips/NOTES.md` for the strips.

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
Run all five gameplay suites and the camera, figure-mask and hover regressions from the
repository root:
```bash
python3 godot/tests/run_tests.py
```
The runner finds `godot`, `godot4`, or the macOS Godot app; pass `--godot=/path/to/godot`
to choose an executable. It checks exit codes, suite completion and unexpected script or
engine errors. It reports the existing headless glow-shader diagnostic, macOS certificate
diagnostic and exit-time object leak warning separately.

The HUD is a deep-papyrus title bar and a 120 px strip, each set off from the scene by the band
(`BOXED` in `hud.gd` also runs it round the strip). The scroll levels (procession, dangers, cosmos)
start their view just under the top register's upper rule (`VIEW_TOP`), so the title bar's band
takes that rule's place above the lower one; field and hall keep their own framing under the band. There is no list of rites on
screen: the scene shows what is still wrong (the levels still report the rites to `update_tasks`).
Keys in player text are written in brackets (`[space]`, `[shift]`, `[esc]`, `[←] [→]`); the HUD
shows them as written. A scribe line that won't fit the strip at 32 px drops to 16 px.
`-- --journal` opens the Journal for a screenshot.

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
