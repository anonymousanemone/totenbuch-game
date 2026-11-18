"""Export the prologue (Guarding the Body, spells 151–154) from art/guardingbody151-154.mdp and write its one
saved scene. The MDP is only read, and checked unchanged at the end.

    python .claude/skills/build-levels/build_prologue.py [151ab 151c 151de 152 154] [--into DIR]

Each top folder of the MDP is one stage of the prologue, a single vignette played on its own, in the order of
STAGES. In a folder, the layer named like the folder is the drawing; its other layers are that stage's own scroll
lines (drawn in blue, kept as ink). A stage's strip is both, cut from the canvas with a 30 px margin round its
frame; rows keep their canvas numbers. Name folders to export only those; the others' data is kept.

Writes, under godot/ (or DIR/godot with --into, to check the tool without touching the repository):

  assets/prologue/figures/strip<folder>.png   each stage's drawing and scroll lines
  assets/prologue/figures/frame<folder>_left.png, _right.png
                                              the strip from each wall outward: the end double lines, drawn
                                              over the avatar on papyrus so his foot never shows past them
  assets/prologue/level.json                  per stage: the source rectangle, size, ground, camera rows, start
  assets/prologue/registry.json               written only when it does not exist
  assets/menu/prologue.png                    the map picture: stage 151ab from the top of its double rule
                                              down past its ground rule, without the text below (when 151ab is exported)
  scenes/prologue.tscn                        written only when it does not exist (placement edited in Godot survives)

The scene is one walking lane (scripts/prologue/prologue.gd, on walk.gd): the stages lie edge to edge, the first
played on the right as on the plate, each lowered or raised so that all stand on one ground line (GROUND). Each
frame's vertical double lines are walls (`wall_left`, `wall_right`: the inner edges of its rules). The scene's node
positions are where each stage is; level.json holds each stage's own geometry, in its strip's pixels.
The avatar is the procession's (assets/procession/figures/avatar.png), drawn facing left.
"""
import hashlib
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from mdp import read_mdp
from cutlib import canvas_of, save_ink
from build_scene import save_menu_picture

ROOT = Path(__file__).resolve().parents[3]
SOURCE = 'art/guardingbody151-154.mdp'
SCALE = 1.5
MARGIN = 30
GROUND = 907                 # the shared ground line in the scene: the lowest stage's, so no stage is lifted above 0
# The procession's framing (procession.gd VIEW_TOP and level.json view_height): rows 36–701 of a frame whose ground
# is row 526. Every stage shows the same number of rows, so the avatar and camera are the same size as there.
ABOVE_GROUND = 526 - 36
BELOW_GROUND = 701 - 526
AVATAR = 'res://assets/procession/figures/avatar.png'
AVATAR_HEIGHT = 296
START_IN = 130               # the avatar starts this far in from a stage's right edge: inside the frame's double rule
# The map picture, from the stage's strip widened by MENU_PAD of papyrus each side: from the top of its double rule
# down past its ground rule, 814 x 518, the 440 x 280 shape
MENU_STAGE, MENU_PAD, MENU_ROWS, MENU_COLS = '151ab', 20, (30, 548), (0, 814)
# folder: ground row, the top of the double rule the vignette stands on; in playing order
STAGES = {'151ab': 526, '151c': 907, '151de': 810, '152': 526, '154': 526}
TITLE = 'Guarding the Body'
INTRO_TITLE = 'Prologue: Guarding the Body'
INTRO_BODY = ('The body is laid out in its burial chamber, and must be guarded before it is carried to the tomb.\n\n'
              'Walk [b]right to left[/b] with [←] [→] or click the papyrus.')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def export(folder, out, w, h, layers, chunks):
    ground = STAGES[folder]
    top = next(l for l in layers if l['type'] == 'folder' and l['name'] == folder and l['parentId'] == '-1')
    drawing = np.zeros((h, w), np.uint8)
    lines = np.zeros((h, w), np.uint8)
    for layer in layers:
        if layer['parentId'] != top['id'] or layer['type'] != '32bpp' or layer['visible'] == 'false':
            continue
        if layer['name'] == folder:
            drawing = np.maximum(drawing, canvas_of(layer, w, h, chunks, False))
        else:
            lines = np.maximum(lines, canvas_of(layer, w, h, chunks, True))
    assert drawing.any() and lines.any(), f'{folder}: needs its drawing layer and its scroll lines'
    both = np.maximum(drawing, lines)
    ys, xs = np.nonzero(both)
    x0, x1 = max(0, int(xs.min()) - MARGIN), min(w, int(xs.max()) + 1 + MARGIN)
    y1 = min(h, int(ys.max()) + 1 + MARGIN)
    save_ink(both[:y1, x0:x1], out, f'strip{folder}')
    if folder == MENU_STAGE:
        wide = np.pad(both[:y1, x0:x1], ((0, 0), (MENU_PAD, MENU_PAD)))
        save_menu_picture('prologue', wide, MENU_ROWS, MENU_COLS, out.parent / 'menu')
    width, height = x1 - x0, y1
    # the frame's vertical rules: columns inked down nearly all the rows from the top rule to the ground
    inked = (lines[60:ground, x0:x1] > 0).mean(0) > 0.9
    rules = np.nonzero(inked)[0]
    assert len(rules), f'{folder}: no vertical rules'
    middle = width / 2
    wall_left = int(rules[rules < middle].max()) + 1
    wall_right = int(rules[rules > middle].min())
    save_ink(both[:y1, x0:x0 + wall_left], out, f'frame{folder}_left')
    save_ink(both[:y1, x0 + wall_right:x1], out, f'frame{folder}_right')
    print(f'{folder}: strip {width}x{height} from x {x0}; ground {ground}; walls {wall_left}–{wall_right}.')
    return dict(source_rect=dict(x=x0, y=0, w=width, h=height), width=width, height=height, ground=ground,
                wall_left=wall_left, wall_right=wall_right,
                **view(ground, height))


def view(ground, height):
    """The rows the camera shows: as many as in the procession, the ground as far up as there. Where the strip ends
    sooner below the ground (151c, 151de), the view ends with it, its bottom rule just above the bottom bar, and the
    rows it loses below are taken off the top (the top of the text there is cut off)."""
    bottom = min(ground + BELOW_GROUND, height)
    return dict(view_top=bottom - ABOVE_GROUND - BELOW_GROUND, view_height=bottom)


def layout(stages):
    """Each stage's position in the scene: edge to edge, the first played on the right, all on GROUND."""
    places, x = {}, 0
    for folder in reversed(list(STAGES)):
        places[folder] = (x, GROUND - stages[folder]['ground'])
        x += stages[folder]['width']
    return places, x


def write_scene(base, stages):
    scene = base / 'godot/scenes/prologue.tscn'
    if scene.exists():
        print('scenes/prologue.tscn exists and is kept; delete it to write it afresh.')
        return
    places, total = layout(stages)
    height = max(y + s['height'] for (_, y), s in zip(places.values(), (stages[f] for f in places)))
    first = next(iter(STAGES))
    fx, fy = places[first]
    start_x = fx + stages[first]['wall_right'] - START_IN
    body = INTRO_BODY.replace('\n', '\\n')
    parts = ['[gd_scene format=3]\n',
             '[ext_resource type="Script" path="res://scripts/prologue/prologue.gd" id="level"]',
             '[ext_resource type="Script" path="res://scripts/avatar.gd" id="avatar"]',
             '[ext_resource type="Script" path="res://scripts/hud.gd" id="hud"]',
             '[ext_resource type="Shader" path="res://scripts/papyrus.gdshader" id="papyrus"]',
             f'[ext_resource type="Texture2D" path="{AVATAR}" id="avatar_texture"]']
    for f in STAGES:
        parts.append(f'[ext_resource type="Texture2D" path="res://assets/prologue/figures/strip{f}.png" id="strip{f}"]')
        for side in ('left', 'right'):
            parts.append(f'[ext_resource type="Texture2D" path="res://assets/prologue/figures/frame{f}_{side}.png" '
                         f'id="frame{f}_{side}"]')
    parts.append('\n[sub_resource type="ShaderMaterial" id="paper"]\nshader = ExtResource("papyrus")\n')
    nodes = [f'''[node name="Prologue" type="Node2D"]
script = ExtResource("level")
level_key = "prologue"
title = "{TITLE}"
intro_title = "{INTRO_TITLE}"
intro_body = "{body}"''',
             f'''[node name="Papyrus" type="ColorRect" parent="."]
material = SubResource("paper")
offset_left = -1500.0
offset_top = -1000.0
offset_right = {total + 1500}.0
offset_bottom = {height + 1000}.0
mouse_filter = 2
metadata/_edit_lock_ = true''',
             '[node name="Strip" type="Node2D" parent="."]']
    for f in STAGES:
        x, y = places[f]
        nodes.append(f'''[node name="Strip{f}" type="Sprite2D" parent="Strip"]
position = Vector2({x}, {y})
texture = ExtResource("strip{f}")
centered = false
metadata/stage = "{f}"
metadata/source_x = {stages[f]["source_rect"]["x"]}''')
    nodes.append('[node name="Figures" type="Node2D" parent="."]')
    for f in STAGES:
        x, y = places[f]
        nodes.append(f'[node name="Spell{f}" type="Node2D" parent="Figures"]\nposition = Vector2({x}, {y})\n'
                     f'metadata/stage = "{f}"')
    nodes.append(f'''[node name="Avatar" type="Node2D" parent="."]
position = Vector2({start_x}, {GROUND})
script = ExtResource("avatar")''')
    nodes.append(f'''[node name="Sprite" type="Sprite2D" parent="Avatar"]
texture = ExtResource("avatar_texture")
offset = Vector2(0, {-AVATAR_HEIGHT / 2:g})''')
    nodes.append('[node name="Foreground" type="Node2D" parent="."]\nz_index = 6')
    for f in STAGES:
        x, y = places[f]
        s = stages[f]
        nodes.append(f'[node name="Frame{f}" type="Node2D" parent="Foreground"]\nposition = Vector2({x}, {y})\n'
                     f'metadata/stage = "{f}"')
        for side, left, width in (('Left', 0, s['wall_left']), ('Right', s['wall_right'], s['width'] - s['wall_right'])):
            node = f'Foreground/Frame{f}/{side}'
            nodes.append(f'[node name="{side}" type="Node2D" parent="Foreground/Frame{f}"]\nposition = Vector2({left}, 0)')
            nodes.append(f'[node name="Papyrus" type="ColorRect" parent="{node}"]\nmaterial = SubResource("paper")\n'
                         f'offset_right = {width}.0\noffset_bottom = {s["height"]}.0\nmouse_filter = 2')
            nodes.append(f'[node name="Ink" type="Sprite2D" parent="{node}"]\n'
                         f'texture = ExtResource("frame{f}_{side.lower()}")\ncentered = false')
    nodes.append(f'[node name="Camera" type="Camera2D" parent="."]\n'
                 f'position = Vector2({fx + stages[first]["width"] / 2:g}, {GROUND - 108})')
    nodes.append('[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("hud")')
    nodes.append('[node name="Hitboxes" type="Node2D" parent="."]')
    scene.parent.mkdir(parents=True, exist_ok=True)
    scene.write_text('\n'.join(parts) + '\n' + '\n\n'.join(nodes) + '\n')


def main(argv):
    base = ROOT
    if '--into' in argv:
        i = argv.index('--into')
        base = Path(argv[i + 1]).resolve()
        argv = argv[:i] + argv[i + 2:]
    folders = argv or list(STAGES)
    unknown = [f for f in folders if f not in STAGES]
    if unknown:
        raise SystemExit(f'unknown folder(s): {", ".join(unknown)}; one of {", ".join(STAGES)}')
    source = ROOT / SOURCE
    digest = sha(source)
    w, h, layers, chunks, _ = read_mdp(source)
    out = base / 'godot/assets/prologue'
    path = out / 'level.json'
    level = json.loads(path.read_text()) if path.exists() else {}
    stages = level.get('stages', {})
    for folder in folders:
        stages[folder] = export(folder, out, w, h, layers, chunks)
    missing = [f for f in STAGES if f not in stages]
    if missing:
        raise SystemExit(f'not exported yet: {", ".join(missing)}; run without folder names first')
    places, total = layout(stages)
    # the defaults walk.gd reads: the whole lane on the shared ground (the prologue frames one stage at a time)
    level = dict(source=SOURCE, sha256=digest, width=total, height=max(places[f][1] + stages[f]['height'] for f in STAGES),
                 ground=GROUND, view_top=min(places[f][1] + stages[f]['view_top'] for f in STAGES),
                 view_height=max(places[f][1] + stages[f]['view_height'] for f in STAGES), scale=SCALE,
                 avatar='procession/avatar', order=list(STAGES), stages={f: stages[f] for f in STAGES},
                 figures={}, columns={})
    path.write_text(json.dumps(level, indent=1, ensure_ascii=False) + '\n')
    registry = out / 'registry.json'
    if not registry.exists():
        registry.write_text(json.dumps(dict(references={}, entries={}), indent=1) + '\n')
    write_scene(base, level['stages'])
    assert sha(source) == digest
    print('MDP unchanged.')


if __name__ == '__main__':
    main(sys.argv[1:])
