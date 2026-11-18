# Totenbuch: Asset List

**Status: Initial (G1).** Version 0.1, 2026-11-18. Owner: Sophia (Art Lead). Inventory of `art/*.mdp` and `godot/assets/` on 2026-11-18. Locked at G3 with the style guide (`style-guide.md`).

**Stages.** *Spliced*: plates placed in the strip frame (`splice-plates` steps 1–9). *Cut*: figures, captions and bottom text in their own layers (`splice-plates`, Cutting figures). *Exported*: PNGs in `godot/assets/<level>/`. *Scene*: `godot/scenes/<level>.tscn` exists.

## Levels on the map

In map order (`SCENES` in `godot/scripts/scroll.gd`).

| Level | Spells | Source | Spliced | Cut | Exported | Scene | Art still to do |
|---|---|---|---|---|---|---|---|
| Guarding the Body (prologue) | 151–154 | `guardingbody151-154.mdp` | Yes | **No**: one drawing layer per stage | 15 PNG | Yes | Cut each stage's figures and texts (b), (d) (TODO.md) |
| The Funeral Procession | 1–15 | `procession1-15.mdp` | Yes | Yes, grouped by scene part | 93 PNG | Yes | — |
| The Night Journey | 17 | `cosmos17-21.mdp` | Yes | Yes (`dissected`) | 62 PNG | Yes | — |
| The Councils | 18 | `councils18.mdp` | Yes | Yes, by vignette (18a–18j) | No | No | Export, build |
| Mouth and Heart | 21–30 | `heart21-30.mdp` | Yes | Yes, by spell | 35 PNG | Yes | — |
| Dangers on the Road | 31–42 | `dangers31-42.mdp` | Yes | Yes, by spell | 57 PNG | Yes | — |
| Survival and Sustenance | 43–63 | `survival43-63.mdp` | Yes | Yes, by spell | 117 PNG | Yes | — |
| Coming Forth by Day | 64–75 | `forth64-75.mdp` | Yes | No | No | No | Cut, export, build |
| Transformations | 76–88 | `transformations76-88.mdp` | Yes | No; no bottom-text folder | No | No | Cut, export, build |
| Ba and Tomb | 89–92 | `boats89-109.mdp` | Yes | No | No | No | Cut, export, build |
| Thoth and the Boats | 93–109 | `boats89-109.mdp` | Yes | No | No | No | Cut, export, build |
| The Field of Offerings | 110 | `fields110.mdp` (full page) | Yes | Yes (`dissected`) | 98 PNG | Yes | Say whether the hidden "Solar crossing" folder is finished (TODO.md) |
| The Souls of the Towns | 112–124 | `souls112-124.mdp` | Yes | No; no bottom-text folder | No | No | Cut, export, build |
| The Lake of Fire | 126–143 | `lake126-143.mdp` | Yes | No | No | No | Cut, export, build |
| The Gates | 144–147 | `gates144-145.mdp`, `gates146-147.mdp` | Yes | Yes: 144–145 by plate, 146–147 by spell | 150 PNG | Yes | — |
| The Fourteen Mounds | 149 | `mounds149.mdp` | Yes | Yes, by mound | 47 PNG | Yes | Confirm play status (GDD §7) |
| Thoth Opens the Sky | 161 | `thoth161.mdp` (layers `og`, `edited`) | Yes | No folders | 19 PNG | Yes | — |
| The Weighing of the Heart | 125 | `judgement125.mdp` (full page) | Yes | Yes, by scene part, with a hidden `captions` folder | 84 PNG | Yes | — |

## Not on the map

| Item | Spells | Source | State | Art still to do |
|---|---|---|---|---|
| Spell 16: the sun, the standards and the baboons | 16 | `bod16.mdp` (four panels) | Not cut; plan in TODO.md | Cut the panels; cut each baboon's raised arms as their own layer and turn them down for the dropped pose |
| Guide companions (in-game agent) | 163–165 | `creatures.mdp` (13 layers, mostly unnamed) | `godot/assets/creatures/` holds only `registry.json` | Min's sprite and follow animation for G2; the snake and the dwarfs after G2 (Configuration Document §4) |
| The seven cows | 148 | None | Proposed (GDD §7) | Splice |
| Amulets | 155–160 | None | Proposed (GDD §7) | Splice |

## Shared assets

| Asset | Where | Made by | State |
|---|---|---|---|
| Scene pictures for the map (one per scene, with the title page's frontispiece). These also serve as release screenshots and key art. | `godot/assets/menu/` (25 PNG) | `.claude/skills/make-artwork/menu_images.py`, from 1280 × 720 screenshots of built levels and plate crops for the rest | Built |
| Top-bar and strip icons, frame bands | `godot/assets/ui/` (12 PNG) | `.claude/skills/make-artwork/menu_images.py` (`ICONS`, `SIGNS`) | Built |
| Old Fax font, with added arrows and middle dot | `godot/assets/fonts/OldFax.ttf` | `.claude/skills/make-artwork/oldfax_glyphs.py` | Built |
| Shaders: glow, papyrus, figure | `godot/scripts/*.gdshader` | By hand | Built |
| Audio | — | — | None yet (GDD §10) |
