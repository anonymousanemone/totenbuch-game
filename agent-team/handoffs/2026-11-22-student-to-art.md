---
from: student
to: art
kind: origin
column: prototype
date: 2026-11-22
---
## Why this agent
The same art corrections kept coming back: agents cutting or rebuilding art that was already made or approved, and art that did not match the game's own look.
- 2026-10-13: the agent cut pixels from the original layers; the rotated originals had to be restored pixel for pixel beside the separate cutouts ([decision log, 2026-10-13](../../project-docs/decision-log.md), commit 0441ab6).
- 2026-11-05: the agent redrew the journal and hint icons in a mockup; mockups must use the game's current icon art ([decision log, 2026-11-05](../../project-docs/decision-log.md)).
- 2026-11-18: the agent treated `spearers.py` as part of the Dangers build and called the Procession images done; generators only make sheets that are then hand-edited, and stable art is never rebuilt automatically ([decision log, 2026-11-18](../../project-docs/decision-log.md)).
## Use
`splice-plates`, `make-artwork`, `draft-ui`, `project-docs/style-guide.md`, `project-docs/asset-list.md`, the Lepsius plates in `references/`, and Notion rows with Role Art Lead.
## Produce
Min's sprite and guide look for the Procession test (blue, transparent body, translucent outline, from plate 165), with file names and sizes for tech; UI drafts made with `draft-ui`; updates to the style guide and asset list.
## Accepted when
Every piece is cut 1:1 from a plate with nothing redrawn, UI art matches Old Fax and the style guide's colours, nothing under `art/` or `godot/assets/` was written without the student naming it, and the student approves how it looks.
## Evidence
The temporary-directory output beside the plate piece it came from, a screenshot of the piece in the scene, and the Notion rows with their agent log lines.
## Student decision
