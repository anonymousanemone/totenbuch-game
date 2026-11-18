# 300-dpi strips: what was detected, what was done, how to change it

This records every step, so text (captions, columns, the hieroglyph blocks under the boxes) can later be added back or taken out without redoing the detection.

## Sources and units
- **Plates:** the 300-dpi pages in `art/og_300dpi` (read only); `page_NNNN.png` is plate N, and PDF page = plate + 23.
  - Detection runs on each page shrunk to 200 dpi (`detect.plate`), so detections and `overrides.json` are in 200-dpi plate px; ink is darker than half.
  - The ink in the strips is taken from the 300-dpi page itself (`detect.page`).
- **Plate px:** a pixel of that scan. All detections below are in plate px **after deskewing**, as a rotation about the page centre by `deskew_deg`.
- **Strip px:** 300 dpi, so 1 plate px = 1.5 strip px.
- **Scroll direction:** the scroll reads right to left, so a later plate sits further left.

## Strip format (copied from the hand-made bod1-15 / bod17-21)
- **Height:** 582 px.
- **Guide colour:** 181,91,60 in the `guidelines` folder (layers `horizont` and `vertical`). Lines are 6 px wide.
- **Horizontal rows:**

| Row | What |
|---|---|
| 28–33 and 42–47 | top double line |
| 178–183 | line between caption and picture, drawn only over boxes that have a caption |
| 524–529 and 538–543 | bottom double line; figures stand on row 524 |

- **Columns:**
  - Left end lines: x 162–167 and 176–181.
  - Right end lines: the same, mirrored 145 px in from the right edge.
  - Box separators: 6 px wide, with 10 px clear on each side.
- **Caption band:** rows 48–177.

## Pipeline (`.claude/skills/splice-plates/strips/`)

### 1. Deskew (`build_strips.skew_angle`)
- **Angle:** the median tilt of the long vertical column rules, using runs of 400 px or more.
- **Rotation:** cubic interpolation, keeping grey values.

### 2. Box detection (`boxes.find_boxes`), per plate
- **Horizontal rules:** straight runs of 90 px or more.
- **`L0`, the frame top:** the first rule wider than half the page, plus any parallel line within 16 px below it.
- **Caption line `l1`:** per column, the first rule between `L0+45` and `L0+170`.
- **Picture bottom `l2`:** per column, the longest rule between `l1+90` and `L0+640`; on a tie it takes the upper one.
- **Separators:** vertical runs of 50 px or more and no wider than 40 px, reaching from the caption line to `l2`. Double lines are merged.
- **Box:** the space between separators where `l2` exists for at least 60% of the width.
- **Caption rows:** `L0+2` to `l1-1` (or `None`, when there's no caption line).
- **Picture rows:** `l1+2` to `l2-1`.
- **Used:** a box is kept only if it holds a figure 75 px or taller. This drops boxes that are only text.
- **Hand corrections** are in `overrides.json`:
  - `add`: x-ranges, optionally with explicit picture rows.
  - `drop`: box indices.
  - `dropall`.
  - `skip`: the reason a plate was skipped.
- **Record:** every box, used or not, is in **`auto_strips/detections.json`**, keyed by plate.
- **Checking by eye:** `python boxes.py review A B out.png [--overrides]` outlines every box on plates A..B; `python boxes.py ruler out.png N ...` draws plates with a ruler in plate px, for reading off coordinates for `overrides.json`.

### 3. Cleaning (`build_strips.clean`)
- **Removed:** inside a box, rule lines that touch the edge (runs of at least half the width or 60% of the height), and edge specks under 120 px.
- **Kept:** all ink inside the picture rows, **including any text written inside the picture**.

### 4. Placement (`build_strips.layout_box`, `draw_box`)
- **Picture:** scale `s = min(1.5, room / picture height)`. The picture bottom goes to row 524 and its left edge to the box's strip x.
- **Caption:** only the caption ink is kept. It is scaled to fit rows 48–177 and the box width (at most 1.5), then centred.
- **Layers:** one layer per box, named `<plate>-<n>`, and right above it a hidden `<plate>-<n> rest`: what the cut left out around the box (rule lines, specks, the rest of its caption and picture rows, 8 px past the box), placed the same way. Merge the two to get the plate back.
- **No PNG exports.**
- **Files:** boxes are grouped into files up to 15 200 px wide, breaking at plate boundaries.
- **Record:** **`auto_strips/manifest.json`** has one record per layer:
  - file and layer
  - plate and PDF page
  - deskew angle and frame top
  - the box's x-range, caption rows and picture rows on the plate
  - the scales used
  - where the box landed in the strip, with the exact plate→strip formula

### 5. Side columns and full pages (`panels.py`)
- **Regions:** fixed regions per plate (`REGIONS`).
- **Cells:** found from rule rows and columns where ink covers at least 60% of the width (rows) or at least 90% of the height (columns).
  - Bands under 70 px join the panel above.
  - `nosplit` disables column splitting.
  - `rows` sets the bands by hand.
- **Placement:** each cell keeps its place on the plate at 1.5×, inside a 60 px margin, with a double guide line round it (6 px lines, 8 px apart); cells that touch share one.
- **Layers:** one per cell, each with a hidden `rest` layer above it, as in the strips.
- **Text:** **whole cells are kept, text included.**
- **Record:** `auto_strips/panels/manifest_panels.json`, with each cell's rectangle on the plate and the plate→sheet formula.

| File | Plate | Content |
|---|---|---|
| bod110a_pl40 | XL | adoring figure (110a) |
| bod110_pl42 | XLII | four panels of the left column |
| bod110a_pl42 | XLII | adoring figure |
| bod142-143_pl59 | LIX | five-panel left column |
| bod148_pl70 | LXX | the grid: figures, rudders, cows and text cells (16 cells) |
| bod148b_pl70 | LXX | offering scene |
| bod149-150_pl73 | LXXIII | the mounds of 150 (15 cells) |
| bod151-153_pl74 | LXXIV | right column a–e: two Anubis scenes, mummy, two text blocks |
| bod157-161_pl76 | LXXVI | panels a/b, with their text columns |

### 6. Plates side by side, text and all (`pages.py`)
- **Sheets:** `SHEETS` names runs of plates kept with their text. `build_strips.py` skips these plates (`skip` in overrides.json); run `pages.py` after it. Run `pages.py <out dir> <sheet>` to rebuild only that sheet.

| File | Plates | What |
|---|---|---|
| bod42-64 | XX–XXIII | spells 42–64, down to half the frame |
| bod144-146 | LXI–LXVI | the gates of 144–146, whole plates |
| bod149 | LXXI–LXXIII | spell 149, down to half the frame. On LXXIII only the part right of x 595; the 150 column is `panels/bod149-150_pl73`. |

- **Cut part way down (`down`):** text is kept from glyphs that start above the cut, kept whole and reaching at most 100 px past it.
- **Spill:** each sheet keeps about 50 px (34 plate px) beyond the frame on either side and below the last kept glyph.
- **Placement:**
  - Each plate is deskewed as in the strips.
  - It is scaled so its frame (from the double rule under the heading to the foot of the columns) is as tall as the median plate's. The scales come out between 1.49× and 1.50×.
  - Its heading rule sits on a common row.
  - Later plates sit further left, and neighbouring frames overlap by their edge's double line.
- **Layers, per plate:**
  - `<plate>-<n>`: each box found by `find_boxes` (caption rows down to the picture bottom). Above it is a hidden `<plate>-<n> rest` with the rest of that box.
  - `<plate> text`: the rest of the frame, with the rule lines taken out.
  - `<plate> rest` (hidden): the rule lines, the plate heading, the column numbers, and on a cut sheet the glyphs just below the cut.
  - Merge all of a plate's layers to get the plate back.
- **Rule lines:** straight runs of at least 230 px (vertical) or 250 px (horizontal), with gaps up to 25 px bridged. They are drawn as guides, 6 px wide; where two lines run within 16 px of each other they become a double line with an 8 px gap. The guides are a best guess and haven't been tuned.
- **Record:** `auto_strips/manifest_pages.json`, with each plate's frame, deskew angle, and plate→sheet formula.

## What text is in and what is out
| Text | Status | How to change it |
|---|---|---|
| Caption above a box | **in**, rescaled and centred | Delete it with `cap=None` in `layout_box`, or keep it at its original position and scale with `caption_center_plate` and `caption_scale` from manifest.json |
| Text inside a picture box | **in** | Mask it out in `clean()`, or erase it in the layer |
| Text columns between or under boxes (most of each plate) | **out** | Not in any box: the rows outside `caption_rows`/`picture_rows` and the x-ranges outside the boxes in detections.json. Add a box with `add` in overrides.json, or cut from the plate with the formula in manifest.json |
| Boxes that are text only (no figure ≥ 75 px) | **out** | They are in detections.json with `"used": false`; force them in with `add` |
| Plates XLVII–XLIX and LXIX (text only) | **out** | `skip` in overrides.json |
| Plates XVI–XIX (spells 30–42) and the full pages XLI (110) and L (125) | **out** | Done by hand in `art/`; `skip` in overrides.json, left out of `REGIONS` |
| Plates XX–XXIII (42–64, top half), LXI–LXVI (144–146) and LXXI–LXXIII (149, top half) | **in** | `pages.py`; text is in `<plate> text`, the heading and column numbers in the hidden `<plate> rest` |
| Text in side columns and full pages | **in** | Cells are kept whole; set `rows` or columns in `REGIONS` to exclude text cells |

## Earlier steps
- **The hand-made bod1-15, bod16 and bod17-21:**
  - Their redraw is in the `bod_300dpi` folders, made by `tools/mdp300/`; originals are in `_backup_before_300dpi/`.
  - Each piece was matched back to its plate by fitting a scale, rotation and shift, so the redraw follows your adjustments.
  - The per-piece fits are in the scratch pickles (`fit_*.pkl`). They are not kept in the repo; re-run `run2.py`/`run3.py` to regenerate them.
- **The Godot procession:** cut from the bod1-15 redraw by `.claude/skills/build-levels/extract_procession300.py`. Its click regions are measured on the strip (`STRIP_HOTSPOTS`, `SLOT_HITS`, `STRIP_SPRITES`).

## Known limits
- The auto layout uses a uniform 1.5× scale and hasn't been hand-aligned.
- Spell ranges in file names come from the `SPELLS` table and should be checked.
- `bod21-24.mdp` was not touched.
- Plates XVI–XIX and the full pages XLI and L are done by hand in `art/` and not made here.
