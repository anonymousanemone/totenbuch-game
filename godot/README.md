# Totenbuch (Godot 4)

Levels of the Book of the Dead as a point-and-click game, built from Lepsius's
*Das Todtenbuch der Ägypter* (1842). Every figure is cut from the plate scans.

Open `project.godot` in Godot 4.7+ and press **Play** (F5). A level menu opens first.

The scroll reads right to left. Click the papyrus (or use ← →) to walk.

## The Funeral Procession (spells 1–15, pl. I–VI)
Click figures to record them in the journal; click a movable piece to pick it up and click
where it belongs to set it down (clicking a filled place swaps the two). **Esc** puts it back.
The whole scroll can be walked from the start.

1. **Hitch the right beast**: the calf is yoked to the mummy's sledge and the ox stands behind the plumed ox. Swap them.
2. **Return the standards**: the eight standard-bearers (four in plate III, four in plate II) carry the wrong gods; the two falcons are interchangeable. An empty pole shows a faint outline of its own standard. The lector with two plumes on his head (plate V, past the offering table) reads out the order when clicked: the eight signs appear one after another in the space above his sheet, jackal first at the far end, falcon last in front of his plumes (`RECITE_*` in `procession.gd`; the line's place is `recital` in `level.json`).
3. **Rebuild the offering table** (`scripts/offering_table.gd`): the heap in plate IV has collapsed. Its loose pieces lie on the floor between the two pairs of bouquets as physics bodies, at any angle, each with a faint papyrus fill inside its outline; the palm frond lies in the empty band above, a little to the right. Click a piece to pick it up (it comes to the front; its place shows faintly) and click near its place to set it in. It only goes in once everything it rests on is there (`rests_on` in `level.json`, worked out by the cutter); otherwise it topples back down. The frond goes on last. Clicking the lector beside the table shows, in front of him, a piece that can go on now (again for the next one).
4. **Give the goose back**: the man beside the lector holds a loaf from the heap instead of his goose, which lies among the fallen offerings. Take the loaf from him, then give him the goose. With all four done the level ends.

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
thrusts and holding Shift lends the thrust heka; once it is overcome the vignette is put back as drawn.
Spell 38 (the breath of life) cannot be entered until spells 31–37 are overcome, and spell 42
at the end waits until every danger before it is overcome.

| Spell | Rule |
|---|---|
| 31 | The vignette opens out to the left (the double line behind you stays; the caption banner stays; the text below drops away). You are the spear-bearer: ↑ ↓ / W S move you, Space thrusts; only the spear point strikes, anywhere on a crocodile (or right by its snout) before it reaches you. Crocodiles never come with their front halves on top of each other, nor one right after another at the same spot. Wave 1 is the lesson (a thrust, a move, one slow crocodile, two more). Then a break: the heka word in the banner starts flashing red (click it for the hold-Shift hint). Wave 2 has red crocodiles (`red_order`), turned back only by a thrust while holding Shift. Bites redden the body; heka on an ordinary crocodile, or one slipping past you once the word glows, loses: the word is taken or eaten, he crumbles the moment it lands, and the fight starts again from wave 2. Tuned in `ENCOUNTERS` (`waves`, `break`) |
| 32 | The same, faster, two at a time and from both sides: you stand in the middle, ← → turn you, ↑ ↓ move you. Some crocodiles come red (`red` chance): hold Shift (heka; the spear turns red) as you thrust to turn those back. A plain thrust does nothing to a red one; heka on an ordinary one loses: it seizes the heka word from the banner, makes off with it, and the fight starts over. Bites redden the body, heka reddens the spear |
| 33 | Close up (caption to ground). He stays where he is drawn, spear raised; Space thrusts. The snake coils just out of reach, breathing; its tail waves (the warning, `snake_tail.gdshader` bends the drawing), it squashes, and snaps to his front leg (its body passes behind his skirt, its head in front). Thrust as it springs: the point must come down on the red mark, at the spot where it is drawn (about an 80 ms window). Too early, the spear is already rising again. Three strikes; three bites and he crumbles. Tuned in its `ENCOUNTERS` entry |
| 35 | A snake slides in and out of reach; strike when it reaches the spear tip (twice) |
| 36 | The vignette opens out; you stand still in the middle: ← → turn you, Space thrusts. The roach darts about very fast; every couple of darts it stops by the point of your spear for 0.35–0.75 s (some stops just out of reach). Only the spear point at the full thrust pins it (its body, or with `dot` only a red dot on its back); a catch holds everything for 0.5 s. `need` catches (1 for now) |
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
| `scripts/hud.gd` | Title bar, minimap, scribe text, hand, checklist, journal, intro/outro; each level passes its own texts |
| `scripts/papyrus.gdshader` | Procedural papyrus fibres behind the ink |
| `assets/<level>/` | Stitched plate strips, one PNG per piece, `level.json` with positions |

The procession is `../art/procession1-15.mdp` whole and as drawn (the `bod_300dpi` plates I–VI, the
frame lines, which the .mdp shows black through clipping layers, and the `text_below` folder), cut by
`../tools/cut_procession300.py`, which reads the .mdp directly. The offering table's loose pieces are the layers of its `table` folder (the layer `table` itself, the table and what stays standing, stays in the picture; the widest piece is the frond; `t long` is the loaf the goose-bearer holds, or any layer named with "held"); world units are strip pixels and `level.json` carries `"scale": 1.5`
so distances written for the 200-dpi plates still work. The dangers level is exported from the
hand-made 300-dpi strip bod31-42.mdp (one layer per character, text below added) by
`../tools/cut_dangers300.py`; the old 200-dpi cutter `../tools/cut_dangers.py` is kept for reference. See `../tools/strips/NOTES.md` for the strips.

Both crocodile fights: three bites and the bearer crumbles and the fight starts over; the flesh
sign (your picture at `assets/dangers/flesh.png`; red dots until it is there) counts his health in red at the
top left. Spell 32 speeds up with every crocodile (`ramp`) but keeps arrivals `min_gap` apart so it
can always be won. `-- --croc-bot` lets a stand-in player (0.35 s reaction, `BOT_REACT=0.7` for a
slower one) fight the next crocodile vignette and prints how many tries it needed.

### Heka signs (red crocodiles)
In `bod31-42.mdp`, move the caption hieroglyphs you choose onto their own layers inside a folder
named `heka`, and run `../tools/cut_dangers300.py` again. Each layer in that folder is lifted out of
the strip as its own sprite: during a crocodile fight it flashes red, and clicking it tells the
player to hold Shift against the red crocodiles.

## Command-line checks
```bash
godot --headless --path . -- --level=dangers --autotest
```
Plays the level through the same click handlers the player uses and prints PASS/FAIL per
step. `--level=procession --autotest` does the same for the procession.

```bash
godot --path . -- --level=dangers --skip=8 --at=2950 --wait --screenshot=/tmp/apep.png
```
Marks the first 8 encounters solved, starts the avatar at x=2950 (inside Apep's vignette),
saves a frame and quits. The procession takes `--at=` and `--take=slot` instead of `--skip=`, `--recite` shows the plumed lector's whole line at once, `--speak` has the lector beside the table show a piece, `--wait` lets the fallen offerings settle first, and `--show-hits` outlines every click region.
