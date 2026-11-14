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

### Skeleton and naming

Every level scene uses the same skeleton, in draw order (a scene has the ones it needs):
`Papyrus`, `Strip`, `Figures`, `Pieces`, `Overlay`, `Avatar`, `Foreground`, `Camera`, `HUD`,
`Hitboxes`.

- `Papyrus` is the backdrop `ColorRect`. Lock it in the editor (`metadata/_edit_lock_ = true`) so
  it is never picked or dragged by accident; a build tool writing a scene writes the lock too.
- `Strip` is the plate artwork, a `Sprite2D`. A level of several panels makes it a `Node2D` holding
  one `Sprite2D` per panel, named by the spells it covers (Gates: `Strip146_147`, `Strip144_145`).
- `Figures` is the artwork that stays put; `Pieces` is what scripts move or animate (actors,
  puzzle pieces, pivots). Text that covers the avatar is `Foreground/<Name>/{Papyrus, Ink}`.
- Structural nodes are `PascalCase`, with no spaces or underscores: groups (`Spell146`, `Plate65`,
  `Panel1`, `AdorationScene`), parts (`Sprite`, `Shape`) and markers (`CarryAdze`, `FrondPlace`).
  Numbers are Arabic (`Plate41`, never `PlateXLI`). The picture of a pivot is always `Sprite`.
  Group by spell (`Figures/Spell<N>`), then by plate (`Plate<N>`) or panel (`Panel<N>`) where the
  level needs it; use a descriptive group (`AdorationScene`) only where there is no spell to name.
- Content nodes are `snake_case` and named by their ID: a figure sprite and its `Hitboxes` box both
  carry its registry ID. IDs read `[spell<N>_]<thing>[_<role>][_<n>]`: `spell146_p65_1_gate`,
  `canal_god_3`; the ordinal is `_<n>`, and a letter only where the source uses one.
- Never put a source layer number, or a layer name with spaces, in a node name: the layer id goes in
  `metadata/source_layer_id`. When an exporter names nodes, it names them from the registry key
  (or, with none, the layer name without its number), never straight from the `.mdp` layer name.
- Where several nodes share one registry entry, `registry_id` metadata links them. Where a script
  keys a node by a data ID that is not its name (`actor_id` in Dangers, `piece_id` in Procession and
  Survival), the name says the role (`spear_bearer`, `ox`) and the metadata is the ID: keep it when
  renaming. Do not add a second ID field that just repeats the name.

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

## Hitboxes

A click on a figure hits its drawing filled in (the outline and everything it encloses)
plus a few px of air: `descriptions.gd` `hit()`, the same in every level. Never pick by
thin ink alone or by a rectangle.

Every level scene has one `Hitboxes` node (a `Node2D` at the scene root) holding one
light-blue box per figure, an `Area2D` named after its registry ID with a `Shape`
child, so all of them can be shown or hidden with one click in the editor. These boxes
are a reference for looking at only: no code reads them. The exceptions carry
`metadata/hit_by_box = true` and are hit by their box instead of their drawing: every
caption (except the dragged words in Procession), and figures that share one drawing
(Procession's eight poles, and the bier and censer priest in the sledge drawing).
Each level passes its node to `_descriptions.use_boxes($Hitboxes)` in `_ready`.

After adding figures to a scene, draw their boxes (it only adds boxes that are missing,
marks captions `hit_by_box`, and leaves existing and hand-edited boxes alone):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot -s ../tools/hitboxes.gd -- <level>
```

In tests, click a point on a figure's drawing, not the middle of its bounds, which may
be empty paper.

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
