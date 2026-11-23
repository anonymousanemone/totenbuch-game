"""Export the prologue (Guarding the Body, spells 151–154) from art/guardingbody151-154.mdp and write its one
saved scene. The MDP is only read, and checked unchanged at the end.

    python .claude/skills/build-levels/build_prologue.py [--into DIR]

The drawing is the visible folder `Folder2067`; each folder in it is one stage, laid out as on the plate: 151ab,
151c and 151de stacked in one column (top to bottom), and 152 and 154 to the left of 151de on its ground. In a stage
folder every layer but `text`, `toptext`, `horizont` and `vertical` is a figure (one sprite, one registry entry);
those four, and any folder inside (151de holds a copy of 151ab's text block), are the stage's strip. The hidden
folders (`separated`, `guidelines`) and layers (`pl75`) stay out.

Writes, under godot/ (or DIR/godot with --into, to check the tool without touching the repository):

  assets/prologue/figures/strip<stage>.png    each stage's text and scroll lines, cut with a 30 px margin
  assets/prologue/figures/<id>.png            each figure, cropped to its ink
  assets/prologue/figures/rule<stage>_left.png, _right.png
                                              the ink of each vertical double line (everything drawn there), laid
                                              over the avatar on papyrus so he passes behind the rules
  assets/prologue/level.json                  per stage: the source rectangle, ground, walls, camera rows; figures
  assets/prologue/registry.json               written only when it does not exist
  assets/menu/prologue.png                    the map picture: 151ab from the top of its double rule down past its
                                              ground rule
  scenes/prologue.tscn                        written only when it does not exist (placement edited in Godot survives)

Scene coordinates are canvas pixels less ORIGIN. A stage's strip node sits at its source rectangle; level.json
holds each stage's geometry in its strip's own pixels. The avatar is the procession's, drawn facing left.
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
DRAWING = 'Folder2067'
SCALE = 1.5
MARGIN = 30
ORIGIN = (391, 509)          # canvas pixel at the scene's (0, 0): 30 px up and left of the drawing
STRIP_LAYERS = ('text', 'toptext', 'horizont', 'vertical')
# The procession's framing (procession.gd VIEW_TOP and level.json view_height): the rows from 490 above the ground to
# 175 below it. Every stage shows as many, so the avatar and camera are the same size as there.
ABOVE_GROUND = 490
BELOW_GROUND = 175
AVATAR = 'res://assets/procession/figures/avatar.png'
AVATAR_WIDTH = 140
AVATAR_HEIGHT = 296
# Stages in playing order; the column stages are left by walking out past their left wall, the row is one walk.
ORDER = ['151ab', '151c', '151de', '152', '154']
COLUMN = ['151ab', '151c']
ROW = ['151de', '152', '154']
# Figures: stage, layer name -> (id thing, name, description). Ids read spell<stage>_<thing>.
FIGURES = {
    ('151ab', 'mummy left'): ('mummy_left', 'Mummiform figure',
                              'A figure wrapped like a mummy stands upright at the left of the shrine, its face showing.'),
    ('151ab', 'mummy right'): ('mummy_right', 'Mummiform figure',
                               'A figure wrapped like a mummy stands upright at the right of the shrine, its face showing.'),
    ('151ab', 'anubis'): ('anubis', 'Anubis', 'Anubis, as a jackal, lies on top of a shrine with his tail hanging down.'),
    ('151ab', 'shrine'): ('shrine', 'Shrine', 'A low shrine with a panelled front stands on four legs.'),
    ('151c', 'nepthys'): ('nephthys', 'Nephthys', 'A goddess kneels at one end of the bier, the sign of her name on her head.'),
    ('151c', 'nepthys ball'): ('nephthys_ball', 'Round sign', 'A small round sign rests on the ground in front of Nephthys.'),
    ('151c', 'isis'): ('isis', 'Isis', 'A goddess kneels at one end of the bier, the sign of her name on her head.'),
    ('151c', 'isis ball'): ('isis_ball', 'Round sign', 'A small round sign rests on the ground in front of Isis.'),
    ('151c', 'mummy'): ('mummy', 'Mummy', 'The wrapped body lies on its back on the bier.'),
    ('151c', 'bier'): ('bier', 'Lion bier', 'A bier shaped like a lion, its head at one end and its tail curled up at the other.'),
    ('151de', 'mummy left'): ('mummy_left', 'Mummiform figure',
                              'A figure wrapped like a mummy stands upright at the left of the shrine, its face showing.'),
    ('151de', 'mummy right'): ('mummy_right', 'Mummiform figure',
                               'A figure wrapped like a mummy stands upright at the right of the shrine, its face showing.'),
    ('151de', 'anubis'): ('anubis', 'Anubis', 'Anubis, as a jackal, lies on top of a shrine with his tail hanging down.'),
    ('151de', 'shrine'): ('shrine', 'Shrine', 'A low shrine with a panelled front stands on four legs.'),
    ('152', 'offering'): ('offering', 'Offering', 'An offering is held up between the two figures.'),
    ('152', 'bowl'): ('bowl', 'Bowl', 'A shallow bowl at the kneeling woman\'s knees.'),
    ('152', 'kneeling woman'): ('kneeling_woman', 'Kneeling woman', 'A woman kneels and reaches up toward the seated man.'),
    ('152', 'seated man'): ('seated_man', 'Seated man', 'A man sits on a low seat, facing the kneeling woman.'),
    ('154', 'sun disk'): ('sun_disc', 'Sun disc', 'The sun disc hangs above the body on a short stem.'),
    ('154', 'sky'): ('sky', 'Sky', 'The sign of the sky stretches over the bier.'),
    ('154', 'mummy'): ('mummy', 'Mummy', 'The wrapped body lies on its back on the bier.'),
    ('154', 'bier'): ('bier', 'Lion bier', 'A bier shaped like a lion, its head at one end and its tail curled up at the other.'),
}
TITLE = 'Guarding the Body'
INTRO_TITLE = 'Prologue: Guarding the Body'
INTRO_BODY = ('The body is laid out in its burial chamber, and must be guarded before it is carried to the tomb.\n\n'
              'Walk [b]right to left[/b] with [←] [→] or click the papyrus.')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def runs(indices):
    """Consecutive runs in a sorted index array, as (first, last) pairs."""
    out = []
    for i in indices:
        if out and i == out[-1][1] + 1:
            out[-1][1] = int(i)
        else:
            out.append([int(i), int(i)])
    return out


class Source:
    def __init__(self, path):
        self.w, self.h, self.layers, self.chunks, _ = read_mdp(path)
        self.kids = {}
        for layer in self.layers:
            self.kids.setdefault(layer['parentId'], []).append(layer)
        root = next(l for l in self.layers if l['name'] == DRAWING and l['parentId'] == '-1')
        self.stages = {l['name']: l for l in self.kids[root['id']] if l['type'] == 'folder'}
        assert set(self.stages) == set(ORDER), f'stage folders: {sorted(self.stages)}'

    def ink(self, layer, raw=False):
        return canvas_of(layer, self.w, self.h, self.chunks, raw)

    def visible(self, folder):
        """Every visible pixel layer under `folder`, with whether it sits directly in it."""
        for layer in self.kids.get(folder['id'], []):
            if layer['visible'] == 'false':
                continue
            if layer['type'] == 'folder':
                yield from ((l, False) for l, _ in self.visible(layer))
            else:
                yield layer, True


def bbox(alpha):
    ys, xs = np.nonzero(alpha)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def export(src, out):
    everything = np.zeros((src.h, src.w), np.uint8)
    stages, figures = {}, {}
    for key in ORDER:
        folder = src.stages[key]
        strip = np.zeros_like(everything)
        rules_h = np.zeros_like(everything, bool)
        rules_v = np.zeros_like(everything, bool)
        for layer, direct in src.visible(folder):
            name = layer['name']
            if direct and name not in STRIP_LAYERS:
                assert (key, name) in FIGURES, f'{key}: no figure entry for layer {name!r}'
                thing, title, text = FIGURES[key, name]
                alpha = src.ink(layer)
                x0, y0, x1, y1 = bbox(alpha)
                fid = f'spell{key}_{thing}'
                save_ink(alpha[y0:y1, x0:x1], out, fid)
                figures[fid] = dict(stage=key, name=title, description=text, source_layer_id=layer['id'],
                                    source_rect=dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0))
                everything = np.maximum(everything, alpha)
                continue
            raw = name in ('horizont', 'vertical')
            alpha = src.ink(layer, raw)
            strip = np.maximum(strip, alpha)
            if direct and name == 'horizont':
                rules_h |= alpha > 0
            if direct and name == 'vertical':
                rules_v |= alpha > 0
        everything = np.maximum(everything, strip)
        x0, y0, x1, y1 = bbox(strip)
        x0, y0, x1, y1 = x0 - MARGIN, y0 - MARGIN, x1 + MARGIN, y1 + MARGIN
        save_ink(strip[y0:y1, x0:x1], out, f'strip{key}')
        # The frame: the vertical double lines (two runs each side), and the double rule each vignette stands on.
        cols = runs(np.nonzero(rules_v.mean(0) > 0.1)[0])
        rows = runs(np.nonzero(rules_h.mean(1) > 0.1)[0])
        assert len(cols) == 4, f'{key}: vertical rules {cols}'
        figure_bottom = max(f['source_rect']['y'] + f['source_rect']['h'] for f in figures.values() if f['stage'] == key)
        ground = min(r[0] for r in rows if r[0] >= figure_bottom - 12)
        stages[key] = dict(source_rect=dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0), width=x1 - x0, height=y1 - y0,
                           ground=ground - y0, top=rows[0][0] - y0, bottom=rows[-1][1] + 1 - y0,
                           outer_left=cols[0][0] - x0, wall_left=cols[1][1] + 1 - x0,
                           wall_right=cols[2][0] - x0, outer_right=cols[3][1] + 1 - x0,
                           view_top=ground - ABOVE_GROUND - y0, view_height=ground + BELOW_GROUND - y0)
        print(f'{key}: strip {x1 - x0}x{y1 - y0} at ({x0}, {y0}); ground row {ground}; '
              f'walls {cols[1][1] + 1}–{cols[2][0]}.')
    # menu picture: 151ab from the top of its double rule to a little past its ground rule, papyrus each side
    s = stages['151ab']
    r = s['source_rect']
    pad = 20
    rows = (r['y'] + s['top'], r['y'] + s['ground'] + 22)
    wide = np.pad(everything[:, r['x']:r['x'] + r['w']], ((0, 0), (pad, pad)))
    save_menu_picture('prologue', wide, rows, (0, r['w'] + 2 * pad), out.parent / 'menu')
    for key in ORDER:
        s, r = stages[key], stages[key]['source_rect']
        for side, a, b in (('left', s['outer_left'], s['wall_left']), ('right', s['wall_right'], s['outer_right'])):
            save_ink(everything[r['y'] + s['top']:r['y'] + s['bottom'], r['x'] + a:r['x'] + b], out, f'rule{key}_{side}')
    return stages, figures


def scene_xy(rect):
    return rect['x'] - ORIGIN[0], rect['y'] - ORIGIN[1]


def write_scene(base, level):
    scene = base / 'godot/scenes/prologue.tscn'
    if scene.exists():
        print('scenes/prologue.tscn exists and is kept; delete it to write it afresh.')
        return
    stages, figures = level['stages'], level['figures']
    first = stages[ORDER[0]]
    fx, fy = scene_xy(first['source_rect'])
    body = INTRO_BODY.replace('\n', '\\n')
    parts = ['[gd_scene format=3]\n',
             '[ext_resource type="Script" path="res://scripts/prologue/prologue.gd" id="level"]',
             '[ext_resource type="Script" path="res://scripts/avatar.gd" id="avatar"]',
             '[ext_resource type="Script" path="res://scripts/hud.gd" id="hud"]',
             '[ext_resource type="Shader" path="res://scripts/papyrus.gdshader" id="papyrus"]',
             f'[ext_resource type="Texture2D" path="{AVATAR}" id="avatar_texture"]']
    for k in ORDER:
        parts.append(f'[ext_resource type="Texture2D" path="res://assets/prologue/figures/strip{k}.png" id="strip{k}"]')
        for side in ('left', 'right'):
            parts.append(f'[ext_resource type="Texture2D" path="res://assets/prologue/figures/rule{k}_{side}.png" '
                         f'id="rule{k}_{side}"]')
    for fid in figures:
        parts.append(f'[ext_resource type="Texture2D" path="res://assets/prologue/figures/{fid}.png" id="{fid}"]')
    parts.append('\n[sub_resource type="RectangleShape2D" id="box"]\nsize = Vector2(1, 1)\n')
    parts.append('[sub_resource type="ShaderMaterial" id="paper"]\nshader = ExtResource("papyrus")\n')
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
offset_right = {level["width"] + 1500}.0
offset_bottom = {level["height"] + 1000}.0
mouse_filter = 2
metadata/_edit_lock_ = true''',
             '[node name="Strip" type="Node2D" parent="."]']
    for k in ORDER:
        x, y = scene_xy(stages[k]['source_rect'])
        nodes.append(f'''[node name="Strip{k}" type="Sprite2D" parent="Strip"]
position = Vector2({x}, {y})
texture = ExtResource("strip{k}")
centered = false
metadata/stage = "{k}"''')
    nodes.append('[node name="Figures" type="Node2D" parent="."]')
    for k in ORDER:
        nodes.append(f'[node name="Spell{k}" type="Node2D" parent="Figures"]\nmetadata/stage = "{k}"')
    for fid, f in figures.items():
        r = f['source_rect']
        x, y = scene_xy(r)
        nodes.append(f'''[node name="{fid}" type="Sprite2D" parent="Figures/Spell{f["stage"]}"]
position = Vector2({x + r["w"] / 2:g}, {y + r["h"] / 2:g})
texture = ExtResource("{fid}")
metadata/registry_id = "{fid}"
metadata/source_layer_id = "{f["source_layer_id"]}"''')
    start_x = fx + first['wall_right'] - 130
    nodes.append(f'''[node name="Avatar" type="Node2D" parent="."]
position = Vector2({start_x}, {fy + first["ground"]})
script = ExtResource("avatar")''')
    nodes.append(f'''[node name="Sprite" type="Sprite2D" parent="Avatar"]
texture = ExtResource("avatar_texture")
offset = Vector2(0, {-AVATAR_HEIGHT / 2:g})''')
    nodes.append('[node name="Foreground" type="Node2D" parent="."]\nz_index = 6')
    for k in ORDER:
        s = stages[k]
        x, y = scene_xy(s['source_rect'])
        nodes.append(f'[node name="Frame{k}" type="Node2D" parent="Foreground"]\nposition = Vector2({x}, {y + s["top"]})\n'
                     f'metadata/stage = "{k}"')
        for side, a, b in (('Left', s['outer_left'], s['wall_left']), ('Right', s['wall_right'], s['outer_right'])):
            node = f'Foreground/Frame{k}/{side}'
            # a column stage is left past its left wall: the papyrus there runs an avatar's width further out,
            # so he goes out of sight behind the frame as he leaves
            extra = AVATAR_WIDTH + 10 if side == 'Left' and k in COLUMN else 0
            nodes.append(f'[node name="{side}" type="Node2D" parent="Foreground/Frame{k}"]\nposition = Vector2({a}, 0)')
            nodes.append(f'[node name="Papyrus" type="ColorRect" parent="{node}"]\nmaterial = SubResource("paper")\n'
                         f'offset_left = {-extra}.0\noffset_right = {b - a}.0\n'
                         f'offset_bottom = {s["bottom"] - s["top"]}.0\nmouse_filter = 2')
            nodes.append(f'[node name="Ink" type="Sprite2D" parent="{node}"]\n'
                         f'texture = ExtResource("rule{k}_{side.lower()}")\ncentered = false')
    nodes.append(f'[node name="Camera" type="Camera2D" parent="."]\n'
                 f'position = Vector2({fx + first["width"] / 2:g}, {fy + first["ground"] - 108})')
    nodes.append('[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("hud")')
    nodes.append('[node name="Hitboxes" type="Node2D" parent="."]')
    scene.parent.mkdir(parents=True, exist_ok=True)
    scene.write_text('\n'.join(parts) + '\n' + '\n\n'.join(nodes) + '\n')


def main(argv):
    base = ROOT
    if '--into' in argv:
        base = Path(argv[argv.index('--into') + 1]).resolve()
    source = ROOT / SOURCE
    digest = sha(source)
    src = Source(source)
    out = base / 'godot/assets/prologue'
    stages, figures = export(src, out)
    row = [stages[k] for k in ROW]
    left = min(s['source_rect']['x'] + s['outer_left'] for s in row) - ORIGIN[0]
    right = max(s['source_rect']['x'] + s['outer_right'] for s in row) - ORIGIN[0]
    ground = stages[ROW[0]]['source_rect']['y'] + stages[ROW[0]]['ground'] - ORIGIN[1]
    level = dict(source=SOURCE, sha256=digest, origin=list(ORIGIN),
                 width=max(s['source_rect']['x'] + s['width'] for s in stages.values()) - ORIGIN[0],
                 height=max(s['source_rect']['y'] + s['height'] for s in stages.values()) - ORIGIN[1],
                 ground=ground, view_top=ground - ABOVE_GROUND, view_height=ground + BELOW_GROUND,
                 view_left=left, view_right=right, scale=SCALE, avatar='procession/avatar',
                 order=ORDER, column=COLUMN, row=ROW, stages=stages,
                 figures={fid: dict(stage=f['stage'], source_layer_id=f['source_layer_id'], source_rect=f['source_rect'])
                          for fid, f in figures.items()},
                 columns={})
    (out / 'level.json').write_text(json.dumps(level, indent=1, ensure_ascii=False) + '\n')
    registry = out / 'registry.json'
    if not registry.exists() or not json.loads(registry.read_text()).get('entries'):
        entries = {fid: dict(name=f['name'], descriptions=dict(default=f['description']), journal=True,
                             reference='as drawn') for fid, f in figures.items()}
        old = json.loads(registry.read_text()) if registry.exists() else {}
        registry.write_text(json.dumps(dict(references=old.get('references', {}), entries=entries),
                                       indent=1, ensure_ascii=False) + '\n')
    write_scene(base, level)
    assert sha(source) == digest
    print('MDP unchanged.')


if __name__ == '__main__':
    main(sys.argv[1:])
