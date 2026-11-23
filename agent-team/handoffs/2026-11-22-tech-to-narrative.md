---
from: tech
to: narrative
column: prototype
date: 2026-11-22
---
## Use
Two Procession descriptions in `godot/assets/procession/registry.json` now stand for a figure plus its hauler, because the scene keeps the two drawings in one node and they share one entry.

## Produce
Reword each so it covers both the carried thing and the man hauling it. Keys and current lines:
- `canopy_frame`: "An empty canopy frame carried in the procession." (the removed `man_hauling_the_canopy` read: "A man hauls the canopy frame on its sledge by a rope.")
- `anubis_on_a_chest`: "Anubis as a jackal on a chest, dragged on a sledge. You will meet him again at the judgment." (the removed `man_hauling_anubis` read: "A man hauls Anubis's chest on its sledge by a rope.")

## Accepted when
Each line reads right whichever drawing the player clicks, and the name and reference fields still fit.

## Evidence
Shown on a click on either drawing, plate I, near the right end of the Procession (working tree, uncommitted). Notion row: "Reword the canopy_frame and anubis_on_a_chest descriptions so each also covers the man hauling it".

## Student decision
