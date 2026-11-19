---
name: build-levels
description: How to build a level from a hand-edited .mdp in art/, add and verify its debug playtest controls, update the level's Notion pages, and report the shortcuts to the author.
---

# Building new levels

Build and integrate the playable level first. Then add its debug playtest controls,
verify both, update the level's Notion pages, and always tell the author which
playtest shortcuts are available.

## Source artwork

Inspect the hand-edited `.mdp` in `art/` and identify its spell groups, figures, captions,
frame guides, lower text, and tall vertical inscriptions. Preserve the source document;
exporting a level must not modify it. Respect existing layer names and authored positions.

## Export assets and metadata

Use the existing MDP reader in `tools/mdp300/mdp.py` and the level exporters as references: the scene
builders in this skill's folder (`build_scene.py`, `build_field.py`, `build_prologue.py`, `build_walk.py`,
`export_scene_layers.py`) and the per-level extractors (`extract_*.py`, also here), which write the figures
already cut by hand in the `.mdp` as sprites and `level.json` data.
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
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot -s ../.claude/skills/build-levels/hitboxes.gd -- <level>
```

In tests, click a point on a figure's drawing, not the middle of its bounds, which may
be empty paper.

## Integrate with the scroll

Use the level's existing key in `godot/scripts/scroll.gd`, or add an entry when needed.
The map scene `godot/scenes/scroll.tscn` is written by `build_scroll_map.py` (in this folder) from
`Scroll.SCENES`; it overwrites editor changes, so run it only when asked and keep the cards' `key` metadata in sync.
The menu recognizes a built level when `scenes/<key>.tscn` exists. Provide a map picture
at `godot/assets/menu/<key>.png`, with the top of the double rule flush with the image's
top edge and no faded lower text. Keep level titles and spell ranges consistent.

## Add debug playtest controls

The target for new level work is a hidden `T` shortcut that opens or closes the
playtest menu from anywhere in a debug build, including paused in-level overlays.
Keep the shortcut out of player-facing UI and cold playtest instructions.
Gate menu creation and input
with `OS.is_debug_build()`. Handle one press at a time and ignore key repeats.

- Reuse `godot/scripts/debug_menu.gd`. Procession and Dangers currently instantiate
  their own menu and pass unhandled events to `DebugMenu.handle_shortcut()` first.
  That method owns the key check, toggle, and input consumption. When adding
  global access, give the shared menu one debug-only input owner that runs while
  the tree is paused. Resolve actions from the active scene and discard its
  callbacks when it changes.
- Supply level-specific actions as label and `Callable` pairs. Read
  `debug_complete()` in `godot/scripts/procession/procession.gd` and
  `godot/scripts/dangers/dangers.gd` for examples. Offer individual completion
  actions for the level's playable puzzles, encounters, or vignettes. Reuse the
  controller's existing completion and cleanup so visuals, hints, gates, and
  downstream state agree. Respect mutually exclusive outcomes and make repeated
  activation safe. Keep setup shortcuts clearly distinguishable from completions.
- Offer one shared **Complete level** action for the current playable level.
  Use `Scroll.finish(key)` in `godot/scripts/scroll.gd` to save it as restored
  and advance to the next built level, or return to the menu after the last.
  Offer no completion actions on the title screen, map, or in view-only mode.
  While an overlay or transition prevents an action from running safely, keep
  that action unavailable. Opening or closing the menu preserves the pause state.

## Verify

Import the project in Godot and check for script and resource errors. Inspect the
saved scene and rendered views at the start, middle, and far end of the scroll.
Verify arrow-key and click navigation, camera bounds, figure hover and inspection,
journal behavior, HUD framing, and the avatar passing behind each foreground text
column. Use checks appropriate to the change and confirm the source MDP is unchanged.
Store temporary screenshots and verification artifacts outside the repository;
do not write to `mockups/` unless explicitly requested.

In a debug build, press `T` during gameplay and with a paused in-level overlay.
Exercise each completion action and verify the level's ordinary progress indicators,
cleanup, and next available actions. Check that scene changes clear old entries.
Use an isolated save to check that whole-level completion survives relaunch and
advances once. In a release export, verify that `T` exposes no playtest menu.
The keyboard command in `godot/tests/step_driver.gd` can help exercise the shortcut.
The driver restores save bytes after each command, so verify persistence separately.

## Update Notion and report the shortcuts

Read and follow `../write-notion/SKILL.md` before any Notion write. Update both
existing pages for the level's scope in the Totenbuch Tasks database:

- Update the **Documentation** page with the verified level behavior and its
  debug shortcuts, including what each menu action does.
- Update the **Plan** page to show which planned work was built and what is still
  unbuilt. Preserve the existing design text and link to the Documentation or
  History item as appropriate.

Fetch both pages before editing, use the smallest edits, and verify them afterward.
If a page or scope is missing, follow the approval rules in `write-notion` and
report any update still pending.

Always list the verified shortcuts in the handoff to the author. Give the exact key,
where it works, the available action labels and their effects, and whether an action
saves progress or advances the level. Link the two Notion pages after updating them.
