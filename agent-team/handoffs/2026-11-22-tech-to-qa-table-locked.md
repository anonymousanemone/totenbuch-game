---
from: tech
to: qa
column: prototype
date: 2026-11-22
---
## Use
Build: the working tree (uncommitted). Play the Procession offering table (plate IV), then view it restored.

## Produce
- In the minigame, hover a loose piece: it glows alone. Hover a piece locked in place: nothing glows (the unfinished table glows nothing in the minigame). Clicking a locked piece does nothing there.
- Walking, before the table is rebuilt: a locked piece glows what the table glows; clicking it enters the table.
- Rebuilt: a locked piece glows the whole table with everything on it, and a click reads the table's line.
- Goose set in the bearer's arms (before or after the rebuild): hovering it glows the whole goose-man; clicking it gives his carrying line.

## Accepted when
`procession_interaction_regressions.gd` (`_locked_belong_to_whole`) passes, with the moveable-object, script, description, hint, view-mode and Procession autotest suites.

## Evidence
Frames of the minigame, the locked goose and the rebuilt table from a 1280 × 720 SubViewport. `goose_refuses` in `puzzles.json` is now shown nowhere (Narrative and Audio row open). Not checked: the second offering table and Cosmos, Walk, Dangers suites, which this does not touch.

## Student decision
