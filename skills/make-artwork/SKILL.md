---
name: make-artwork
description: How to make artwork for the Book of the Dead game, in two kinds. Scroll art (animating, posing or changing a figure from the Lepsius plates) must keep the original drawing. UI art (icons, buttons, glyphs, bands, lettering) must look like the Old Fax pixel font. Use for any new or changed image, sprite sheet, icon or mockup graphic.
---

# Making artwork

There are two kinds of art in the game. Each has its own rule:

1. **Scroll art**: anything on the scroll. These are figures, objects and scenes cut from the Lepsius plates, and their animations and poses. **Keep the original drawing.**
2. **UI art**: the chrome around the scroll. This covers top-bar and strip icons, buttons, signs, arrows, frames and lettering. **Make it look like Old Fax.**

Decide which kind you are making before you start. A hieroglyph used as a button (the hint's 𓁿) is UI art, even though it comes from the script.

## Make it to scale

Make every asset at the size it will be shown next to the artwork it belongs with. At scale 1 (a node's `scale`, a sprite's size in a mockup) it should be exactly the right size: a sprite at the plate's resolution, an icon at its on-screen pixel size. Don't make an asset bigger or smaller and fix it with a scale factor afterwards. If you think there is a very good reason for a scale other than 1, ask the user before you do it.

## Scroll art: keep the original

Most of this already works. Keep doing it the same way.

- **Move the drawing, never redraw it.** Bend, warp, split and carry the drawn ink. Don't paint new lines in a different hand. Look at how existing tools do it: `tools/spearer_lean.py` (a rigid moving-least-squares warp of the drawn ink), `tools/snake35_turn.py` (the body bent along the drawing's own centre line, the head carried whole) and `tools/spearer_sheet.py` (a prop split off the figure and the gaps bridged).
- When new ink can't be avoided (bridging a gap left by a split, a part hidden in the drawing), copy the nearby line. Use the same thickness, the same ink colour and the same edge softness, so the seam can't be found.
- The last frame of an animation, or the resting pose, must be the drawing itself, pixel for pixel, in the same place. The sprite should line up with the plate.
- Joints bend the way they are drawn. Planted feet and hems stay planted. Props keep their own line. Write these rules in the tool's docstring, as the existing tools do.
- Keep the plate's scale. Don't resample a figure just to fit a cell: give the cell a different size.
- Check by putting frames next to the original crop at 1:1 and at 2x. Nothing should look smoother, thicker or cleaner than the plate.

## UI art: look like Old Fax

UI art should look like it came out of the same pixel font as the text next to it. It does not have to be pixel-perfect, and it can carry more detail than a blown-up 4x4 grid. But when you squint, the line weight and the silhouette must belong with Old Fax.

### The font's grid

`godot/assets/fonts/OldFax.ttf` has 1024 units per em and 64 units per font pixel (one "dot"), so an em is 16 dots. Cap height is 12 dots. Main strokes are **2 dots** wide, and horizontals and serifs are 1 to 2 dots.

| Font size | 1 dot | Main stroke | Cap height | Used for |
| --- | --- | --- | --- | --- |
| `UI.SMALL` 16 px | 1 px | 2 px | 12 px | body text, labels |
| `UI.BIG` 32 px | 2 px | **4 px** | 24 px | titles, top bar, strip text |

To see the actual shapes, render some text with PIL (`ImageFont.truetype(..., 16)`) and print it as `#`/`.`.

### Rules

- **Line weight matches the text next to the icon.** Next to 32 px text (the top bar and the strip), the main strokes are 4 px. Next to 16 px text, they are 2 px. Don't let the weight wander. One stroke weight carries the silhouette, and a half-weight line (2 px at 32 px) is allowed only for small detail inside it.
- **Size matches the existing icons.** The reference set is `mockups/topbar-icons.png`, the top bar's Journal, Hint, Restart and Levels at scale 1. They are about 28 px tall (22 to 28 px), drawn on 2 px cells with 4 px main strokes. A wide sign can be wider (Hint is 41 px), but not taller. The top bar's Journal and Hint are drawn apart from the strip's, so the two sets don't have to look alike.
- **Hard pixels only.** Use axis-aligned blocks with no anti-aliasing, no soft alpha, no gradients and no curves. Draw curves and slants as stair-steps. For a slant to read the same weight as a straight line, make its steps a little thicker, because a 1-dot stair looks thinner than a 1-dot straight line. That is why `SIGNS` in `tools/menu_images.py` draw straight lines one dot wide and slants two dots wide.
- **Scale by whole numbers with nearest-neighbour**, and use `image-rendering: pixelated` in mockups. Never shrink a pixel icon by a fraction. Halving a 2 px-dot icon into a 1 px one makes thin strokes that don't match anything. If an icon is needed at another size, draw it again on that size's grid.
- **Two colours.** Ink is `(46, 29, 16)` `#2e1d10` on papyrus `(226, 208, 166)` `#e2d0a6`. Draw the icon in ink on a transparent background, and let the UI tint it (mockups use it as a CSS mask on `currentColor`). Accent colours come from the theme, not from the PNG.
- **Silhouette first.** The icon should be recognisable from its outer shape at 1x. Prefer the Egyptian sign for the idea when there is a fitting one, such as 𓁿 for the hint, simplified to the grid. A plain object works too, as the journal's scroll does. Draw a sign from its New Gardiner form (Gardiner's sign-list drawing), not from Noto Sans Egyptian Hieroglyphs or another default font. Drop detail that only works when zoomed in.
- **Keep a set the same.** Icons that sit side by side, such as Journal, Hint, Restart and Levels, share stroke weight, box height and optical weight. One icon must not look darker or busier than its neighbours.

### Where it lives

- Icons are drawn as `#`/`.` rows in `tools/menu_images.py`. `ICONS` are written at scale 4 (1 dot = 4 px) and `SIGNS` at scale 2. The script writes them to `godot/assets/ui/icon_<name>.png`. Add new icons there as rows, not as hand-edited PNGs, so they stay on the grid and can be redrawn.
- Glyphs added to the font itself (arrows, the middle dot) are in `tools/oldfax_glyphs.py`, on the font's own grid.
- Mockups embed icons as base64 PNGs, for example `A.nav` in `mockups/strip-layouts.html`. Follow AGENTS.md: only touch `mockups/` when the user asks.

### Checking it

1. Put the icon next to real Old Fax text at the size it will be used, along with its neighbouring icons, at 1x and at 3 to 4x zoom with `image-rendering: pixelated`. Keep these previews in a scratch directory, not the repo.
2. **Squint test:** blur or downscale the row a little. The icon's stroke should blend with the letters and the other icons, neither heavier nor thinner.
3. Count the strokes in the zoomed view. The main lines should be one weight throughout (4 px at 32 px), and any thinner lines should be details only.
