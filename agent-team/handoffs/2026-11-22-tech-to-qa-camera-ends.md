---
from: tech
to: qa
column: Done
date: 2026-11-22
---
## Use
Build: the working tree (uncommitted). Walk each scene to both ends of the scroll: Procession, Night Journey (Cosmos), Dangers, Survival, Gates, Mouth and Heart, Mounds, Hall, Doors, the Field. Not the Prologue.

## Produce
At each end the outer line of the double line should sit flush with the edge of the view, with nothing beyond it. Top and bottom rows look as before. Procession holds (table, water, haul, bulls, standards, mouth), Dangers fights and Survival altars keep their framing. Doors and Hall at 1280 × 720 show the whole width, so only the centring moves.

## Accepted when
`camera_ends_regressions.gd` passes at 1280 × 720 and 800 × 600 for the ten scenes, and the Procession, Dangers, Cosmos, Field, Walk, Gates, Survival, Mouth and view-mode suites still pass.

## Evidence
`view_left` and `view_right` in each `level.json` are the first and last inked column of the outer vertical line, measured from `strip.png` by the test. Frames of the Procession and Mounds ends show the line flush with the edge. Not run: the Prologue, the UI, menu and hint suites. Known, not from this change: `script_regressions` fails "actors have readable names and are organized beneath their spell", and the Dangers autotest prints a `material` script error, because `dangers.tscn` has the author's uncommitted `crocs31`, `crocs32` and `snake+ass` organizer nodes.

## Student decision
