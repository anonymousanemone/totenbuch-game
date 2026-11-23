---
from: tech
to: qa
column: prototype
date: 2026-11-22
---
## Use
Check the trees of Procession offerings table 1 (plate IV, between the man with the water jar and the lector priest), in the working tree.

## Produce
Confirm the two cypresses and the two plumed trees look as before and no stray ground-line fragment shows to their right; the Procession suite still passes.

## Accepted when
`trees.png` is 1222 × 223 at (4834, 310), matching the `trees` rect in `godot/assets/procession/layers.json`, and `procession_interaction_regressions.gd` passes.

## Evidence
Re-cut from layer 47 of `art/procession1-15.mdp` only. First 1222 columns identical to the old sprite (0 differing pixels); the old right-hand part held only stray fragments. Frame at x=5400, 1280 × 720: both tree pairs drawn. `illustration.png` was not regenerated and still holds the old fragments.

## Student decision
