# Totenbuch: Style Guide

**Status: Initial (G1).** Version 0.1, 2026-11-18. Owner: Sophia (Art Lead). Locked at G3 with the asset list (`asset-list.md`).

The game is a walk along Lepsius's *Todtenbuch* (1842). The scroll is the picture, and everything else stays out of its way. How to make each kind of art is in the skills: `splice-plates` (strips and cutting), `make-artwork` (scroll art and icons), `draft-ui` (screens and layouts), `write-game-text` (writing).

**Exceptions.** No rule here has an exception unless the author explicitly approves it. Approved exceptions are listed at the end.

## 1. Scroll art: the plate as drawn

- **Source.** Lepsius's 300-dpi plates in `art/og_300dpi/`, placed 1:1. Nothing is rescaled, redrawn, cleaned or erased (GDD rule 1).
- **Splicing and cutting.** Plates are rotated and spliced into the strip frame. They are then cut into one layer per figure, object and caption, grouped by spell, with bottom text in its own folder, one layer per plate. Cutting moves pixels and never deletes them, so the flattened file matches the spliced strip pixel for pixel.
- **Motion.** Animation moves the drawn ink (warp, bend, split). It never paints new lines. Joints bend as drawn, and planted feet stay planted. The resting frame is the plate, pixel for pixel.
- **New ink.** Only where it can't be avoided, such as a gap left by a split, and then a copy of the nearby line.
- **Check.** Compare frames with the plate crop at 1:1 and 2×. Nothing may look smoother, thicker or cleaner than the plate.

## 2. UI style: Old Fax on papyrus

The UI is the scroll's own furniture: papyrus bars, its frame band and a pixel font. Values are in `godot/scripts/ui.gd`.

**Layout**
- A **title bar** at the top and the **scribe's strip** at the bottom. Both are deep papyrus, and each is set off from the scene by the scroll's **frame band** (16 px).
- The strip shows the current message, with its speaker as a **tag on the band**, what you carry, and **Journal** and **Hint**. Hint always sits with Journal, never with Restart and Levels.
- The **Journal** opens as a page over the scene, between the bar and the strip.
- **Minigame view** fills the screen under the title bar, framed by the band, and its camera stays fixed (AGENTS.md).

**Shapes**
- Panels are square-cornered, with an ink border.
- Buttons are bare pixel icons, with a small word under them where needed.
- There are no rounded corners, gradients or drop shadows.

**Type**
- Old Fax only (`godot/assets/fonts/OldFax.ttf`): 16 px for body text and labels, 32 px for titles, the top bar, the strip and dialogue. Labels may use 24 px.
- Keys are written in brackets, as in "hold [shift]".

**Colour roles**

| Role | Colour | Used for |
|---|---|---|
| Papyrus | `#e2d0a6` | Pages, the scene's paper |
| Dark papyrus | `#cbb07c` | Bars, the strip, buttons |
| Ink | `#2e1d10` | Text, icons, borders |
| Rule | `#8f7142` | Thin rules |
| Ochre | `#62380e` | Secondary text |
| Tag | `#963e28` | Speakers' tags, headings, the main button |
| Minigame tag | `#456137` | Minigame instructions, clues and feedback |
| Hint tag | `#d2ad46` | Hint-button messages |
| Cream | `#f1e7cd` | Type on dark ink |
| Red | `#b55b3c` | Danger ink, targets, anything red |

A distinction never rests on colour alone: health, targets, warnings and counts also differ in shape or text.

**In-game colours.** The few colours the player sees in the world and on the UI:

| Colour | Value | Meaning |
|---|---|---|
| Ink (`UI.INK`) | `#2e1d10` | Drawings, text, borders |
| Papyrus (`UI.PAPYRUS`) | `#e2d0a6` | The scene's paper, pages |
| Dark papyrus (`UI.DARK_PAPYRUS`) | `#cbb07c` | Bars, the strip, buttons |
| Red (`UI.RED`) | `#b55b3c` | Danger, and anything the author calls "red" |
| Dark red (`UI.DARK_RED`) | `#751c18` | The selected spear band in the Dangers (41) |
| Glow (`UI.GLOW`) | about `#ffc247` at 60% opacity | The hover glow behind what can be clicked, reaching 9 px: in every level, the Dangers too |
| Success glow (`UI.SUCCESS_GLOW`) | `#a0aa72` at 40% opacity | What a task just set right glows this for a moment, reaching 17 px: in every level |
| Faint ink (`UI.FAINT_INK`) | `#571d0a` (ink turned dark red-brown) at 25% opacity, about `#bfa37f` over papyrus | Where something goes: a drawing's place to drag a piece to, and the Survival sceptre imprints. Always this colour and opacity. Never used for a pattern that is only shown |

**Red is always this red, at 100%.** A drawing turned red ends as exactly `UI.RED` (`#b55b3c`). The six in-game colours are the only palette names in `ui.gd`; a sprite drawn in ink is tinted with `UI.inked(UI.RED)`, which turns its ink into that colour exactly. A flash or pulse may pass through other values, but its final form is this red. "Make it red" means this red at 100% unless the author says otherwise.

**Tag colours** (the speaker's tag on the band, with an ink border): tag red `#963e28` (a UI colour, not one of the in-game colours) for everything else (the Scribe, figures, objects), with cream type; green `#456137` for minigame instructions, clues and feedback, with cream type; gold `#d2ad46` for Hint-button messages, with ink type.

**Band colours** (the scroll's frame band, `godot/assets/ui/band_*.png`): ink `#2e1d10`, ochre `#c8a864`, terracotta `#ac6446`, sage green `#74886a`, pale green `#94a280`, grey-blue `#708092`. While only walking and reading a restored scroll the band is tinted warm (`UI.VIEW`).

**Icons.** Ink on transparent, on the font's grid: 4 px main strokes next to 32 px text and 2 px next to 16 px, about 28 px tall, hard pixels only. Signs follow New Gardiner forms. Icons are drawn as rows in `.claude/skills/make-artwork/menu_images.py`, and the full rules are in `make-artwork`.

## 3. Feedback

- **Clickable things glow on hover.** A soft warm glow behind the drawing. The hover glow is `UI.GLOW`, gold in every level.
- **Success.** The drawings just set right glow pale olive (`#a0aa72`) for a moment, and the line in the strip turns green (`#3f7a2a`) and back to ink.
- **Restored scroll.** While only walking and reading, the frame band is tinted warm.
- **Figures react.** For example, the pylon's plumes rise for a right name and sag for a wrong one.
- **Journal notes say what is wrong, never how to fix it.**

## 4. Readability

- **What the player looks at first** is the scene, since the bars and strip are quieter than the plate.
- **Readability rule: what is clickable glows on hover, and nothing else marks it.** Figures and captions are not set apart in the drawing itself, so the player finds them by looking.
- **Instructions** sit in the strip at the bottom. The playtest suggests players look there and rarely look up (TODO.md).

## 5. References and attribution

- Lepsius, *Das Todtenbuch der Ägypter* (1842): the plates, scan in `tools/lepsius_todtenbuch.pdf`. Reuse terms still to confirm (GDD Q5).
- Gardiner's sign list (New Gardiner forms) for hieroglyph icons.
- Earlier UI drafts in `mockups/`: `icons.png` is the icon reference set.

## 6. Approved exceptions

| Exception | Where | Approved |
|---|---|---|
| Adze tool controls at 50% scale during carving | Procession, opening of the mouth | AGENTS.md |
| Guide companions (163–165) drawn from the plates in lapis or faience blue, with transparent bodies and outlines at about 60% opacity | In-game guide module (Configuration Document §4) | Author, 2026-11-18 |
