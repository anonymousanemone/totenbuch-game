---
name: splice-plates
description: How to make a new level .mdp in art/ from the Lepsius plates, by rotating and splicing the 300-dpi plates into the fixed strip frame (guides, caption band, vignette band) without rescaling, keeping every cut-away piece in a hidden discarded folder. Use before creating or re-splicing any art/<level>.mdp.
---

# Splicing plates into a new .mdp

The goal is a strip the user can then cut into figures by hand. You only **rotate and splice** the plates.
Don't rescale, stretch, warp, redraw, clean or erase anything. A plate is placed 1:1 at 300 dpi.

**Be cautious.** The source plates are read only, and other levels' `.mdp` files are never touched.
Ask the user (AskUserQuestion) before deciding anything this skill doesn't settle. Ask especially about:
- which spells and plates belong to the level. Show the per-plate keep/discard list and get it
  confirmed before cutting;
- file names, and what happens to an existing file of that name;
- what to do with layers left over from the template (another level's text, figures or guides);
- a junction or cut where the plates don't line up the way described below;
- vignettes that don't fit the 340 px band (stacked boxes, a tall side column);
- changing the canvas size of an existing file, or anything in it other than the guides.

## The frame (fixed for every strip level)

Measured from survival43-63, dangers31-42, gates144-145 and gates146-147. All lines are **6 px** wide. A
**double line** is two 6 px lines with an **8 px gap** between them (20 px in all, e.g. 30–35 and 44–49).
The guide colour is RGB 181,91,60, in the `guidelines` folder, in layers `horizont` and `vertical`.

| Rows | What |
|---|---|
| 30–35, 44–49 | top frame, double line: always 30 px from the top |
| 50–179 | caption header band (130 px) |
| 180–185 | caption line, single |
| 186–525 | vignette band (340 px) |
| 526–531, 540–545 | ground line, double; figures stand on row 526 |
| 546 → | text below, which runs past the canvas bottom (canvas height is usually 1500) |

- **Left and right frame:** double lines 30 px in from each edge, e.g. 30–35/44–49 on the left, and on a
  9094 px canvas 9044–9049/9058–9063 on the right. Canvas width = frame width + 60. For a new file this
  means the pieces' total width + 80, with the outer rules' centres at 39.5 and width − 40.5.
- **Vertical guides, double:** at every box separator, from row 45 down to the canvas bottom.
- **Vertical guides, single:** for a rule that only reaches the caption line (a tall text column rising
  into the vignette band), from row 182 down.
- **No guide:** for the thin rules between text columns that start at the ground line.
- **Horizontal guides:** the top double line and the caption line run the full width. The ground line
  runs only under picture boxes and breaks where tall text columns cross the vignette band. You may
  lengthen or shorten horizontal guides, but they must stay on the rows above and be 6 px thick. Never
  move them to fit a plate.

Fields110 and judgement125 are full-page layouts with their own numbers. This skill is for the strip
format only.

## What goes in

- **Only spells with vignettes.** A spell that has a vignette keeps all its columns, including the ones
  that continue onto a neighbouring plate (e.g. spell 92 cols 5–8 on plate 34, spell 109 cols 7–12 on
  plate 40).
- **A spell with no vignette** on a plate that is used goes into the discarded folder, even when it sits
  between two kept spells (e.g. 118 on plate 44).
- **A plate with no vignettes at all** is left out entirely, with no layer of any kind (e.g. plates 36
  and 58).
- **Spells outside the level's range** on a used plate go into the discarded folder (e.g. 88 on plate 33,
  150 on plate 73).

## Where things are

- **Python:** `/Users/sophial/miniconda3/envs/general/bin/python`. It has numpy, cv2, PIL and scipy; the
  other Pythons don't.
- **Plates:** `art/og_300dpi/page_NNNN.png` is plate N at 300 dpi, read only. Use these, not the
  binarized `300dpi_2/` copies. Most plates are 2955×3073, but not all (plate 59 is 4067×3156).
- **Which plates a level uses:**
  - `SCENES` in `godot/scripts/scroll.gd` gives each level's spells and plates in Roman numerals.
  - The neighbouring levels' plate layers show where they stopped.
  - The header above each plate gives its spell range (e.g. "92–96").
  - The labels under the columns give each column's spell (e.g. "4 3 2 1 / 94").
  - A spell can continue across plates, and a plate can hold the end of one level and the start of the
    next.
- **The tool:** `tools/mdp300/splice_plates.py` does steps 2–8 below from a piece spec.
  `tools/mdp300/splice_specs.json` holds the specs for boats89-109, souls112-124, lake126-143 and
  mounds149; use them as examples.
- **Readers and writers:** `tools/mdp300/mdp.py` (`read_mdp`, `decode_layer`) and
  `tools/mdp300/write_mdp.py` (`parse_raw`, `encode_layer`, `pac`, `rename_chunk`).
- **Deskew and rule detection:** `tools/strips/build_strips.py` (`skew_angle`) and `tools/strips/detect.py`
  (`runs_mask`).
- **Template:** any existing strip `.mdp`. The tool takes only the file header and layer-entry format
  from it and writes every layer anew. When the user hands you a template copy with layers in it, list
  them and ask what to keep.

## Steps

1. **Inspect and decide.**
   - Render each candidate plate's top band and bottom labels small, and read off its spells and which
     ones have a vignette.
   - Write the keep/discard list per plate and get it confirmed.
   - Ask about file names, and before replacing an existing file, move it to `archive/art/`.
2. **Rotate.** Use `skew_angle`: the median tilt of the plate's long vertical rules.
   - Rotate the greyscale page about its centre, cubic, with a white border. Rotate an all-255 mask the
     same way (nearest) to find the valid pixels.
   - Horizontal rules are bowed (±0.4°), and a ground line can lean up to ~0.8°. Vertical rules decide
     the angle; don't try to level the horizontals too.
3. **Measure the rules** on each rotated plate:
   - horizontal runs of 300 px or more give the top rule, caption line, ground lines and bottom rule;
   - vertical runs of 300 px or more give the box separators and frame rules.
4. **Write the piece spec.** List the pieces right to left. Each piece is one stretch of kept spells on
   one plate, bounded by rules (`L`, `R` approximate x on the plate). A plate with a discarded spell in
   the middle gives two pieces. Name each piece by plate and spells, e.g. `pl44 115-117`.
   - **Snapping:** the tool snaps each edge to the centre of the rule found in the text rows.
   - **Open edges:** where a box runs open across the plate edge (plates 14/15, 51/52), there is no
     frame rule in the vignette band. Snap to the text-column rule instead.
   - **Slanted or broken edges:** an edge rule that slants (plates 51/52 lean ~1.2°) or is broken can't
     be snapped. Measure its centre at mid-height and give it as `Lx`/`Rx`. Both plates' rules lean the
     same way, so joining them at mid-height makes one line.
5. **Place, 1:1.** The strip reads right to left.
   - **Horizontally:** the first piece's right rule goes on the right-end guide centre, and each next
     piece's right rule goes exactly on the previous piece's left rule.
   - **Vertically:** the bottom of the piece's lower ground line goes on row 545, so the upper line lands
     on 526. A plate's ground can step by ~20 px between boxes; the tool takes the median and reports
     where the top rule and caption land. Expect them up to ~30 px off rows 30/180. That's fine; never
     rescale.
   - **No ground in the piece:** use the ground found elsewhere on the same plate. If the plate has none,
     set the piece's top rule level with the neighbouring piece's.
   - **Odd vignettes:** for a vignette that doesn't fit the band, ask which line goes on row 526 and pass
     it as `ground` (e.g. spell 143's stacked side column: the first box's bottom line, plate row 858).
6. **Split, don't delete.** The tool writes, for each piece:
   - the kept rectangle in `plates`: from 6 px above the top frame rule to just below the bottom rule,
     so the numbers under the frame are discarded;
   - `<name> discarded` in the hidden folder `discarded (cut from plates, for splicing)`: the whole
     rotated plate minus that piece, at the *same* offset. A piece plus its discarded layer always
     equals the rotated plate. When one plate gives two pieces, each has its own discarded layer, and a
     sandwiched spell appears in both.
   - **Pixel format:** opaque greyscale (paper stays white, alpha 255), transparent outside the rotated
     page.
   - **Layer size and offset:** layers may have negative `ofsx`/`ofsy` and reach past the canvas.
7. **Guides.** The tool draws them from the frame rules above.
   - **Vertical:** from the pieces' rules that reach the caption band. Single or double is decided by
     counting the solid lines in the rule's ink profile, not by blob width. There's one guide where two
     pieces meet, and the frame doubles at both ends.
   - **Ground:** each segment is snapped to the nearest vertical guide within 60 px. Segments less than
     90 px apart are merged, because a short stub of plate ground line is too small to detect.
   - **Tall boxes with no caption** (the mounds plates): separators start at the plate's caption line, so
     their guides start at row 182.
8. **Build and check.**
   - Run `python tools/mdp300/splice_plates.py <spec.json> <level> <template.mdp> <scratch/out.mdp>
     <scratch/preview_dir>` with the output in the scratchpad.
   - The tool reads the file back and asserts that every piece plus its discarded layer reproduces the
     rotated plate pixel for pixel.
   - Look at the preview in rows. Every picture box should have a ground guide, no black plate rule
     should show beside a vertical guide, and the joins should line up. Zoom into anything doubtful.
   - Only then copy the file into `art/`.
9. **Report:**
   - what was kept and discarded, and which plates were skipped;
   - pieces placed without their own ground, or with an odd `ground`;
   - joins made on open or slanted rules;
   - how far top and caption rules land from rows 30/180;
   - anything archived or left in a template;
   - that the file's thumbnail is stale until it is saved in MediBang.

Store previews and scratch scripts outside the repository (the scratchpad), never in `mockups/` or
`art/`. To change an existing file's canvas, `tools/mdp300/resize_canvas.py <in> <out> 30 1500` moves
every layer, so only on a yes.
