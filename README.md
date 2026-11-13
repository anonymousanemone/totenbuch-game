# Totenbuch (Godot 4)

Levels of the Book of the Dead as a point-and-click game, built from Lepsius's
*Das Todtenbuch der Ägypter* (1842). Every figure is cut from the plate scans; nothing is redrawn.

Open `godot/project.godot` in Godot 4.7+ and press **Play** (F5). A level menu opens first.
The scroll reads right to left; click the papyrus (or use ← →) to walk.

Captions in the top register are the spells' titles. Click one and the strip shows its translation,
from C. H. S. Davis, *The Egyptian Book of the Dead* (1894), which translates this same papyrus
(`CAPTIONS` in `godot/scripts/procession/procession.gd`; each danger's `caption` and `title` in
`godot/scripts/dangers/danger_encounters.gd`).

Playable from the map: the Procession, Night Journey, Dangers, Survival and Sustenance, the Field of
Offerings (to walk and read, without puzzles for now) and Gates. The Weighing of the Heart is in
`archive/` (see its README).

## Levels

What each level plays, rule by rule, is in
[`skills/suggest-games/levels.md`](skills/suggest-games/levels.md).

| Level | Spells | Scene | Scripts |
|---|---|---|---|
| Funeral Procession | 1–15 | `godot/scenes/procession.tscn` | `godot/scripts/procession/` |
| Dangers on the Road | 31–42 | `godot/scenes/dangers.tscn` | `godot/scripts/dangers/` |
| Survival and Sustenance | 43–63 | `godot/scenes/survival.tscn` | `godot/scripts/survival/` |
| Gates | 144–146 | `godot/scenes/gates.tscn` | `godot/scripts/gates/` |
| Night Journey | | `godot/scenes/cosmos.tscn` | `godot/scripts/cosmos/` |

**View mode:** a restored level's map card offers **View** beside Play again. The level opens already
solved (`Scroll.viewing`): clicks only walk up to figures and captions and read them, with no puzzles,
fights or gates, and the frame band is tinted gold (`UI.VIEW`). Each level's restored state is its
puzzle pieces' `restore()` (Procession) or its solved set (Dangers); Survival skips its rites and
Gates shows every adorer. A new level needs its own. Dev: `--view` with `--level=<key>`.

## Layout

Scene-specific scripts and shaders sit in `godot/scripts/<level>/`; shared ones directly in `godot/scripts/`.

| Path | What |
|---|---|
| `godot/scenes/menu.tscn`, `godot/scripts/menu/menu.gd` | Title page, map of the scroll, Settings |
| `godot/scripts/scroll.gd` | Autoload `Scroll`: scenes in playing order, which are restored, `viewing`, settings (`user://scroll.cfg`). A scene counts as built once `scenes/<key>.tscn` exists |
| `godot/scripts/ui.gd` | Shared look (`UI`): palette, Old Fax font, panels, frame band, icon buttons |
| `godot/scripts/avatar.gd` | Walking (click or keyboard), facing, bobbing; `carrying_transform()` for carried items |
| `godot/scripts/hud.gd` | Title bar, the scribe's strip, Journal ([j]), intro/outro |
| `godot/scripts/scroll_camera.gd`, `figure_mask.gd` | Shared camera arithmetic; figure ink/interior masks |
| `godot/scripts/moveable_object.gd` | Drag/drop pieces (see `AGENTS.md`) |
| `godot/assets/<level>/` | Stitched plate strips, one PNG per piece, `level.json` with positions, `puzzles.json` |
| `godot/assets/menu/` | Map pictures and title frontispiece (`tools/menu_images.py`) |
| `art/`, `tools/` | Source `.mdp` files; cutters and scene builders (`tools/strips/NOTES.md` for strips) |

## Scene workflow

Major visual elements live in saved scene nodes so levels can be inspected and edited in Godot; scripts
reuse them and apply startup visibility and state instead of rebuilding the level. For every new scene:

- Put backgrounds, figures, props, puzzle pieces, persistent overlays, and the starting avatar and
  camera in the saved tree.
- Group by spell or puzzle with readable names; keep the stable IDs linking nodes to data. One
  `Sprite2D` per single picture; add parents only for separate parts, pivots or behavior.
- Scene placement is authoritative. Keep `level.json` positions and metadata updated; when visuals
  move, update dependent hotspots, placement targets, camera ranges and animation geometry. Art
  exports and runtime setup must not overwrite scene edits (compare IDs and crop bounds; adjust
  offsets for changed crop origins).

Runtime creation stays for temporary effects, spawned copies, loose physics bodies and the HUD.

**Menus:** `godot/scenes/menus.tscn` is the title page; `godot/scenes/scroll.tscn` is the map (21 level
cards by act, 1280 × 1686). Keep cards' `key` metadata in sync with `Scroll.SCENES`.

**Procession** (`pieces/standards`, `hauling`, `offering_table`, `water`, `opening_mouth`, `ending`):
each piece has a `piece_id` in Inspector > Metadata; keep it when renaming. The editor shows a mixed
arrangement (standards seated, table heaped, goose on the floor, stand/sun/lotus at their hiding
places, water drawn in full); runtime reset applies the puzzle start. `frond_place` marks the frond's
restored position; move a hauling pivot, not its `sprite` child.

**Dangers** (`actors`, spell folders like `spell31_crocs`, plain `Node` organizers): each actor has an
`actor_id` matching its data key. Move the named actor; startup derives its home and bounds from its
position. Keep IDs and sprite offsets (they preserve foot pivots) intact. `size` metadata is the
original drawing bounds.

**Survival:** `godot/scenes/survival.tscn` holds spell groups, the avatar, camera and five foreground
text sections (papyrus-backed, repeating everything drawn within them). `godot/assets/survival/level.json`
records source IDs and bounds. Rerunning `python tools/build_scene.py survival` replaces the generated scene
(dropping added pieces, pivots and splice lines), so preserve editor changes first.
`tools/cut_survival_pieces.py` cuts the rite pieces (partial: name the keys).

**Gates:** `art/gates146.mdp` and `art/gates144-145.mdp` overlap by 280 px so their shared double rule
is one; positions in the scene are authoritative. `python tools/build_scene.py gates` refreshes artwork
and metadata and only adds missing sprites to a saved scene. Pylons sway via `plumes.gdshader`
(`plumes` in `level.json`).

In all of these, JSON and code still define hotspots, camera ranges, paths and many animation targets;
moving a whole group, changing pivots or scaling needs matching updates there.

## Art pipeline

Cutters are partial: name what changed and only that is cut into the level already there.

- **Procession:** `python tools/export_scene_layers.py procession` writes the strip and a sprite for every
  layer of `art/procession1-15.mdp`, by layer id. What it does not work out is cut by
  `tools/cut_procession300.py` (`--water`, `--table`, `--features`, `--bulls`): the water's path and line,
  what each offering rests on, the plumes' places, as `level.json` data beside the sprites. World units are
  strip pixels; `level.json` has `"scale": 1.5` for 200-dpi distances. Hand-drawn sheets
  (`tools/sheets.py procession`) are never regenerated. Needs the `general` conda environment.
- **Dangers:** `tools/cut_dangers300.py art/dangers31-42.mdp godot/assets/dangers <pieces>` (e.g.
  `ankh38 sail38 tail40 sheaf41`); `--all` only when asked. If a vignette's figures move in the `.mdp`,
  move its spear-bearer rect in `level.json`, its `tip` in `spearers.json` and its nodes in
  `dangers.tscn`. Caption signs in the `heka` folder are cut as their own sprites.
- **Survival:** `python tools/build_scene.py survival` from `art/survival43-63.mdp`.
- **Gates:** `python tools/build_scene.py gates`.

## Puzzle text and UI

- Puzzle writing lives in `godot/assets/<level>/puzzles.json` (`instructions`, `success`, named
  `feedback`, Hint `hints`; level `messages` at top level). Shared messages: `godot/assets/messages.json`.
  Scripts choose when to show each line; the catalog holds the wording.
- Dialogue is 32 px, never paged, centred in the 130 px bottom strip (cameras reserve it); keep lines to
  three (~180 characters). Only the beetles (36) show progress pips.
- The Journal ([j]), intros and outros pause movement, physics, timers and fights. Enter/Space advances
  an intro or outro. Hint is repeatable and describes the active task.
- Task completion flashes everything it set right a faint green (`UI.success_flash`; colour `success`
  in `godot/scripts/glow.gdshader`).

## Command-line checks

Run all gameplay suites and camera, mask, hover and UI regressions from the repo root:

```bash
python3 godot/tests/run_tests.py
```

It finds `godot`, `godot4` or the macOS Godot app (`--godot=/path` to choose) and checks exit codes,
suite completion and unexpected errors, reporting the known headless glow-shader, macOS certificate and
exit-time leak diagnostics separately.

```bash
godot --headless --path godot -- --level=dangers --autotest
```

Plays the level through the player's click handlers and prints PASS/FAIL per step; also works with
`--level=procession`.

```bash
godot --path godot -- --level=dangers --skip=8 --at=2950 --wait --screenshot=/tmp/apep.png
```

Marks 8 encounters solved, starts at x=2950, saves a frame and quits.

Other flags: `--view` (with `--level=`, the restored scroll to walk and read); `--level=survival|gates` with `--at=`; Procession `--take=slot`, `--recite`, `--speak`,
`--wait`, `--show-hits`, `--ending`, `--finale`, `--mouth`, `--open-mouth`, `--water`, `--pour=rad`,
`--haul`, `--haul-bot`; `--record=dir --seconds=N`; `--journal`; menu `--screen=map|settings|controls`
with `--screenshot=path.png`. UI regressions: `--script res://tests/ui_regressions.gd`, plus
`-- --ui-images=/tmp/totenbuch-ui` to capture screens.
