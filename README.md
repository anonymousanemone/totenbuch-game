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
Offerings (to walk and read, without puzzles for now), Gates, the Fourteen Mounds, Mouth and Heart,
and the Weighing of the Heart (the last three also to walk and read, cut by `.claude/skills/build-levels/build_walk.py`).
The puzzles of the Weighing of the Heart are in `archive/` (see its README).

## Levels

What each level plays, rule by rule, is in
[`.claude/skills/suggest-games/levels.md`](.claude/skills/suggest-games/levels.md).

| Level | Spells | Scene | Scripts |
|---|---|---|---|
| Funeral Procession | 1–15 | `godot/scenes/procession.tscn` | `godot/scripts/procession/` |
| Dangers on the Road | 31–42 | `godot/scenes/dangers.tscn` | `godot/scripts/dangers/` |
| Survival and Sustenance | 43–63 | `godot/scenes/survival.tscn` | `godot/scripts/survival/` |
| Gates | 144–146 | `godot/scenes/gates.tscn` | `godot/scripts/gates/` |
| Night Journey | | `godot/scenes/cosmos.tscn` | `godot/scripts/walk/` |

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
| `godot/assets/menu/` | Map pictures and title frontispiece (`.claude/skills/make-artwork/menu_images.py`) |
| `art/`, `tools/` | Source `.mdp` files; cutters and scene builders (`.claude/skills/splice-plates/strips/NOTES.md` for strips) |

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

**Naming:** every level scene has the same skeleton and one naming convention.

- Skeleton, in draw order (a scene has the ones it needs): `Papyrus`, `Strip`, `Figures`, `Pieces`,
  `Overlay`, `Avatar`, `Foreground`, `Camera`, `HUD`, `Hitboxes`. `Figures` is the artwork, `Pieces`
  what scripts move, `Foreground/<Name>/{Papyrus, Ink}` text that covers the avatar. In Gates `Strip`
  holds `Strip146_147` and `Strip144_145`.
- Structural nodes are `PascalCase`, without spaces or underscores: groups (`Spell146`, `Plate65`,
  `Panel1`, `AdorationScene`), parts (`Sprite`, `Shape`) and markers (`CarryAdze`, `FrondPlace`).
  Numbers are Arabic (`Plate41`, never `PlateXLI`). A pivot's picture is `Sprite`.
- Content nodes are `snake_case` and named by their ID: a figure sprite and its `Hitboxes` box are both
  its registry ID. Where several nodes share one entry, `registry_id` metadata links them.
- Where a script keys a node by a data ID that is not its name (`actor_id` in Dangers, `piece_id` in
  Procession and Survival), the name says the role (`spear_bearer`, `ox`) and the metadata is the ID: keep
  it when renaming.
- No source layer number or layer name in a name: that is `source_layer_id` metadata.

**Menus:** `godot/scenes/menu.tscn` is the title page; `godot/scenes/scroll.tscn` is the map: every scene
on one register of the scroll, reading right to left between double rules, each act captioned above its cards
(`Scroll.ACTS`). It is saved as long as the whole register (7124 × 720), so the editor shows all of it; in play
it fits the window and scrolls sideways. The chosen scene's name is the tag on the strip's band, with its
description and Play / View. `python .claude/skills/build-levels/build_scroll_map.py` rewrites it from `Scroll.SCENES` (dropping
editor changes); keep cards' `key` metadata in sync. The earlier map, a vertical list of acts, is in `archive/`.

**Procession** (`Pieces/Standards`, `Hauling`, `OfferingTable`, `Water`, `OpeningMouth`, `Ending`):
each piece has a `piece_id` in Inspector > Metadata; keep it when renaming. The editor shows a mixed
arrangement (standards seated, table heaped, goose on the floor, stand/sun/lotus at their hiding
places, water drawn in full); runtime reset applies the puzzle start. `FrondPlace` marks the frond's
restored position; move a hauling pivot, not its `Sprite` child.

**Dangers** (`Pieces`, spell folders like `Spell31`, plain `Node` organizers): each actor has an
`actor_id` matching its data key. Move the named actor; startup derives its home and bounds from its
position. Keep IDs and sprite offsets (they preserve foot pivots) intact. `size` metadata is the
original drawing bounds.

**Survival:** `godot/scenes/survival.tscn` holds spell groups, the avatar, camera and five foreground
text sections (papyrus-backed, repeating everything drawn within them). `godot/assets/survival/level.json`
records source IDs and bounds. Rerunning `python .claude/skills/build-levels/build_scene.py survival` replaces the generated scene
(dropping added pieces, pivots and splice lines), so preserve editor changes first.
`.claude/skills/build-levels/extract_survival_pieces.py` cuts the rite pieces (partial: name the keys).

**Gates:** `art/gates146.mdp` and `art/gates144-145.mdp` overlap by 280 px so their shared double rule
is one; positions in the scene are authoritative. `python .claude/skills/build-levels/build_scene.py gates` refreshes artwork
and metadata and only adds missing sprites to a saved scene. Pylons sway via `plumes.gdshader`
(`plumes` in `level.json`).

In all of these, JSON and code still define hotspots, camera ranges, paths and many animation targets;
moving a whole group, changing pivots or scaling needs matching updates there.

## Art pipeline

Cutters are partial: name what changed and only that is cut into the level already there.

- **Procession:** `python .claude/skills/build-levels/export_scene_layers.py procession` writes the strip and a sprite for every
  layer of `art/procession1-15.mdp`, by layer id. What it does not work out is cut by
  `.claude/skills/build-levels/extract_procession300.py` (`--water`, `--table`, `--features`, `--bulls`): the water's path and line,
  what each offering rests on, the plumes' places, as `level.json` data beside the sprites. World units are
  strip pixels; `level.json` has `"scale": 1.5` for 200-dpi distances. Hand-drawn sheets
  (`.claude/skills/make-artwork/sheets.py procession`) are never regenerated. Needs the `general` conda environment.
- **Dangers:** `.claude/skills/build-levels/extract_dangers300.py art/dangers31-42.mdp godot/assets/dangers <pieces>` (e.g.
  `ankh38 sail38 tail40 sheaf41`); `--all` only when asked. If a vignette's figures move in the `.mdp`,
  move its spear-bearer rect in `level.json`, its `tip` in `spearers.json` and its nodes in
  `dangers.tscn`. Caption signs in the `heka` folder are cut as their own sprites.
- **Survival:** `python .claude/skills/build-levels/build_scene.py survival` from `art/survival43-63.mdp`.
- **Gates:** `python .claude/skills/build-levels/build_scene.py gates`.
- **Prologue (Guarding the Body, 151–154):** `python .claude/skills/build-levels/build_prologue.py [151ab 151c 151de 152 154]`.
  Each top folder of `art/guardingbody151-154.mdp` is one stage of `scenes/prologue.tscn` (script
  `scripts/prologue/prologue.gd`, on `walk.gd`): the layer named like the folder is the drawing, the others are
  that stage's own scroll lines. Stages lie edge to edge on one ground line; only the one being played is shown,
  and its frame's double lines are walls. A stage done fades to the next; after 154 the prologue is restored
  and the procession opens. It is played first, and is the first card on the map (its own Prologue heading). `-- --stage=152` starts at a stage.

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

### Playtest step driver

In a debug build, press **T** to open or close the shared playtest menu. On a
playable level, **Complete level** records it as restored in the local save and
advances. Procession and Dangers also supply puzzle shortcuts. See the
[level integration guide](.claude/skills/build-levels/SKILL.md#add-debug-playtest-controls)
to add shortcuts to another level.

For mechanics QA, use a setup shortcut to reach the state, then do the remaining
actions through the normal gameplay controls. Check what the player sees, the
resulting game state, and what happens on a repeat click or after leaving and
returning. Keep reproducible bugs in the level regression suite. Use the cold
playtest workflow for what a first-time player can infer from the screen.

`godot/tests/step_driver.gd` keeps the game running in a window and takes one action at a time, for the
cold-tester playtests of the `playtest` skill. `godot/tests/step.py` is its client; each call is one
action and prints one JSON line.

```bash
python3 godot/tests/step.py start --level=procession   # opens the game; also --view --fresh --size=800x600 --port=N --out=DIR
python3 godot/tests/step.py look                       # the screen now, no time passes
python3 godot/tests/step.py click 640 300              # also: move X Y, drag X1 Y1 X2 Y2 [SECONDS], key NAME [SECONDS], wait SECONDS
python3 godot/tests/step.py stop
```

- **Time** moves only during an action or a `wait`, 60 frames to the second, and stands still between calls.
  `t` is the game clock; `took` is how long the action ran. A click lets its effect play for 0.3 s; add `settle=SECONDS` to change it.
- **Coordinates** are pixels of the returned frame (1280 × 720 unless `--size=`).
- **Each reply** gives the frame's file, `screen_changed` (any pixel differs from the last reply, so ambient motion
  counts), `overlay` (`intro`, `journal`, `outro` or `none`), the band's line now and `band_events` since the last
  reply (`appeared`, `fading`, `cleared`, each with its time; a cleared line adds `shown_for`, `words`, `reading_time`
  and `cut_short`, measured at 4 words a second plus one), and `controls` (the visible buttons by label and centre).
  It never names the level, a node or an id.
- **Files** go to `$TMPDIR/totenbuch-step-<port>/` (`--out=` to change it): one PNG per reply and `log.jsonl`
  with every command and reply, so a run's log is saved and linked, not pasted. Never point `--out` into the repository.
- **The real save** (`scroll.cfg`) is put back after every command, so a playtest never changes progress;
  `--fresh` starts with nothing restored. Without `--level=` it starts at the title page.
- The window is not redrawn while the driver waits, so it may look frozen between actions.
- One driver per port; start another with `--port=` and give each `step.py` call the same `--port=N` before the command.
