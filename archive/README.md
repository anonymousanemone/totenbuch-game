# Archive

Levels set aside for later: the Night Journey (cosmos), the Field of Offerings (field) and the
Weighing of the Heart (hall). They are kept as they were, but are left out of the game, the tests
and refactors. The folders mirror the repository (`godot/scenes`, `godot/scripts`, `godot/assets`,
`tools`), so a level comes back by moving its files to the same paths and running the import:

```bash
git mv archive/godot/scenes/cosmos.tscn godot/scenes/
git mv archive/godot/scripts/cosmos.gd archive/godot/scripts/cosmos.gd.uid godot/scripts/
git mv archive/godot/assets/cosmos godot/assets/
```

Outside the Godot project, nothing here is imported or parsed. They were last run against the
code of commit 940992a; the shared HUD, avatar and scroll scripts may have moved on since, so
expect to fix them up when one comes back (and add it back to `godot/tests/run_tests.py`,
`godot/tests/ui_regressions.gd` and `BUILT` in `tools/menu_images.py`). Their source drawings
stay in `art/` (`cosmos17-21.mdp`, `fields110.mdp`, `judgement125.mdp`); `tools/` here is
gitignored, as the main one is, and imports from the main `tools/`.

## The Night Journey (spell 17, pl. VII–XI)
The drawing is `art/cosmos17-21.mdp`. Its `dissected` folder groups nearby scenes into
chunks, with local themes inside each chunk and one layer per figure. Export directly with:

```bash
python archive/tools/cut_cosmos300.py art/cosmos17-21.mdp OUTPUT_DIRECTORY
```

The cutter resolves full chunk/theme/layer paths, so repeated names stay distinct. It writes
the individual figures under `layers/<chunk>/<theme>/`, preserves that hierarchy in
`level.json` (`chunks`, `layers`), and derives positions and journal regions from the drawing.
The archived game's movable pieces keep their existing asset names and are omitted from
`strip.png`; the remaining figures and inscriptions stay in the strip. The sun disc alone is
still cut from the solar boat layer. The frame and existing `text_below` layers are included;
working copies are excluded. The source is read only, and scan pages and intermediate PNG
exports are no longer needed. Coordinates are MDP canvas pixels, without the old left crop.

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

`--declared=N`, `--skip=N`. Both levels are cut from the 300-dpi panel sheets by `tools/cut_sheets300.py`.
