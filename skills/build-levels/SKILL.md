---
name: build-levels
description: How to build a new level of the game from a hand-edited .mdp in art/, from exporting assets and metadata to authoring the saved scene, connecting shared behaviour and verifying it.
---

# Building new levels

## Source artwork

Inspect the hand-edited `.mdp` in `art/` and identify its spell groups, figures, captions,
frame guides, lower text, and tall vertical inscriptions. Preserve the source document;
exporting a level must not modify it. Respect existing layer names and authored positions.

## Export assets and metadata

Use the existing MDP reader in `tools/mdp300/mdp.py` and the level exporters as references.
Export named artwork into `godot/assets/<level>/figures/` and keep animation sheets, if
needed, in `animation/`. Record stable IDs, source bounds, dimensions, scale, ground,
and camera view height in `level.json`. Keep descriptions in the level's data catalog,
following the shared `descriptions.gd` format.

Export the complete scroll, including captions, frame lines, and lower inscriptions.
Preserve the original artwork's proportions and alignment. Separate tall vertical text
that needs to cover the walking avatar into foreground artwork; follow the existing
Dangers `Column` overlay for the papyrus backing and ink that hide the avatar.

## Author a saved scene

Create `godot/scenes/<key>.tscn` with the papyrus background, strip, named figures,
foreground inscriptions, starting avatar, camera, and HUD as saved nodes. Organize the
artwork by spell and retain stable IDs in node metadata. Use one `Sprite2D` for one
picture; introduce parents only for meaningful groups, pivots, or behavior.

The intended arrangement must be visible in the Godot editor. Scene positions are
authoritative; runtime setup must reuse the saved nodes rather than rebuild the level
or overwrite editor placement. Keep source coordinates separately in the metadata.

## Connect shared behavior

For navigation-only levels, reuse the shared
avatar, `scroll_camera.gd`, HUD, hover glow, figure picking, descriptions, and journal.
Allow the complete scroll to be explored without puzzles or progression barriers.
Keep foreground inscriptions above the avatar in draw order, with papyrus backing
where needed so the avatar actually disappears behind the text columns.

If a later level requires movable objects, reuse `moveable_object.gd` and the existing
placement validation and recovery rules, as specified in `AGENTS.md`.

## Integrate with the scroll

Use the level's existing key in `godot/scripts/scroll.gd`, or add an entry when needed.
The menu recognizes a built level when `scenes/<key>.tscn` exists. Provide a map picture
at `godot/assets/menu/<key>.png`, with the top of the double rule flush with the image's
top edge and no faded lower text. Keep level titles and spell ranges consistent.

## Verify

Import the project in Godot and check for script and resource errors. Inspect the
saved scene and rendered views at the start, middle, and far end of the scroll.
Verify arrow-key and click navigation, camera bounds, figure hover and inspection,
journal behavior, HUD framing, and the avatar passing behind each foreground text
column. Use checks appropriate to the change and confirm the source MDP is unchanged.
Store temporary screenshots and verification artifacts outside the repository;
do not write to `mockups/` unless explicitly requested.
