---
from: tech
to: qa
column: prototype
date: 2026-11-22
---
## Use
Build: the working tree (uncommitted). Walk Dangers and the Procession and hover the drawings below.

## Produce
- Dangers, walking: the pointer over any crocodile of spell 31 or 32 glows all four; over the donkey or its snake glows both; over the sheaf or its snake (spell 41) glows the sheaf, stalks, bands and snake. One click gives the same line whichever you click.
- Procession plate I: the canopy frame and its hauler glow together and give one line; so do Anubis's chest and its hauler. The journal holds one entry for each, showing both drawings.
- Fights, hover during a fight and the spear-bearers behave as before. Spell 40's tail does not glow with the donkey and snake (it is outside their node).

## Accepted when
`script_regressions.gd` passes (`_test_grouped_hover`, `_test_grouped_figures`), along with the Procession, Dangers, description, hint, life-mode, menu-scene, moveable-object, UI and view-mode suites.

## Evidence
Frames of each hover in a 1280 × 720 SubViewport. The Procession journal now counts two fewer entries. Not run: Cosmos, Walk, Field, Gates, Survival and Mouth suites, which these changes do not touch.

## Student decision
