"""Export a level's figures from its MDP and write its saved exploration scene, without editing the MDP.

    python .claude/skills/build-levels/build_scene.py gates|survival|cosmos

gates     spells 144–147. Spells 147 and 146 (art/gates146-147.mdp; 146 begins at x GATES_146_X)
          fill x 0–8679; spells 144–145 (art/gates144-145.mdp) follow to their right from x 8399,
          where the scroll begins (it reads right to left). The two strips overlap so that 146's
          right double rule (x 8568–8586) is exactly 144–145's left one: they read as one papyrus.
          A saved scene is only added to.
survival  spells 43–63 (art/survival43-63.mdp). The scene is written afresh; the pieces cut by
          extract_survival_pieces.py are left out of the strip.
cosmos    the night journey (art/cosmos17-21.mdp). Run extract_cosmos_figures.py first: this uses its
          figure manifest (figures.json).

(The Field of Offerings, spell 110, has its own tool: build_field.py.)

Each level also writes its level.json, its registry.json (written descriptions are kept) and, for
gates and survival, its map picture in godot/assets/menu/. The MDP is only read, and checked
unchanged at the end.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from mdp import read_mdp
from cutlib import INK, PAPYRUS as PAPER, canvas_of, save_ink
from extract_survival_pieces import PIECES   # cut into sprites of their own by that tool

ROOT = Path(__file__).resolve().parents[3]


# --- shared: reading the MDP, writing images, the parts every scene has -------------------------

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_menu_picture(name, ink, rows, cols, directory=None):
    """The level's picture for the menus: rows and columns of `ink` on papyrus, 440x280 (in
    `directory`, godot/assets/menu by default)."""
    crop = ink[rows[0]:rows[1], cols[0]:cols[1]].astype(np.float32) / 255
    rgb = np.empty((*crop.shape, 3), np.uint8)
    for channel in range(3):
        rgb[..., channel] = np.rint(INK[channel]*crop + PAPER[channel]*(1-crop))
    Image.fromarray(rgb).resize((440, 280), Image.Resampling.LANCZOS).save(
        (Path(directory) if directory else ROOT / 'godot/assets/menu') / f'{name}.png')


def write_registry(path, entries):
    """`entries` into the registry at `path`; its other keys (the references) stay as they are."""
    data = json.loads(path.read_text()) if path.exists() else {}
    data['entries'] = entries
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + '\n')


def avatar_node(x, y, facing, texture, offset_y):
    return (f'[node name="Avatar" type="Node2D" parent="."]\nposition = Vector2({x}, {y})\n'
            f'script = ExtResource("avatar")\ndrawn_facing = {facing}\n\n'
            f'[node name="Sprite" type="Sprite2D" parent="Avatar"]\ntexture = ExtResource("{texture}")\n'
            f'offset = Vector2(0, {offset_y})')


def camera_and_hud(x):
    return (f'[node name="Camera" type="Camera2D" parent="."]\nposition = Vector2({x}, 418)\n'
            'zoom = Vector2(0.77894735, 0.77894735)\n\n'
            '[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("hud")')


# --- survival -----------------------------------------------------------------------------------

SURVIVAL_SOURCE = ROOT / 'art/survival43-63.mdp'
SURVIVAL_OUT = ROOT / 'godot/assets/survival'
# Layer IDs remain stable when the artist renames or groups layers.
SURVIVAL_FIGURES = {
    1039: (47, 'bird_shrine', 'Bird shrine', 'Two birds stand on either side of a tall shrine.'),
    1037: (46, 'staff_bearer', 'Staff bearer', 'The deceased walks with a long staff and a small object in his other hand.'),
    1034: (45, 'mummy', 'Mummy', 'A wrapped mummy stands upright, its arms held across its body.'),
    1032: (44, 'shrine', 'Shrine', 'A tall shrine stands beside the deceased.'),
    1030: (44, 'staff_bearer', 'Staff bearer', 'The deceased approaches the shrine with a staff in his hand.'),
    1029: (43, 'osiris', 'Osiris', 'Osiris stands in his crown, holding his long insignia.'),
    1028: (43, 'worshipper', 'Worshipper', 'The deceased raises his hands before Osiris.'),
    1050: (52, 'seated_man', 'Seated man', 'The deceased sits on a chair and reaches toward the offerings before him.'),
    1048: (51, 'walking_man', 'Walking man', 'The deceased stands with his arms lowered beside his body.'),
    1045: (50, 'walking_man', 'Walking man', 'The deceased stands beside a rounded mound.'),
    1044: (50, 'mound', 'Mound', 'A rounded mound stands on a low base, with a long sign laid across its top.'),
    1043: (49, 'staff_bearer', 'Staff bearer', 'The deceased walks with his staff, facing along the scroll.'),
    1040: (48, 'walking_man', 'Walking man', 'The deceased stands ready to walk onward.'),
    1007: (53, 'offerings', 'Offerings', 'The deceased sits before a laden offering table, holding a small vessel in his raised hand.'),
    1026: (63, 'water', 'Water', 'The deceased kneels beside a tall curved form, lifting his hands to his mouth.'),
    1055: (59, 'tree', 'Tree goddess', 'A goddess emerges from a leafy tree beside the seated deceased.'),
    1056: (57, 'tree', 'Tree goddess', 'The deceased raises his hands toward a goddess emerging from the tree.'),
    1068: (62, 'breath', 'Breath bearer', 'The deceased carries a sail-shaped sign before his face.'),
    1066: (61, 'breath', 'Breath bearer', 'The deceased holds a sail-shaped sign in his raised hand.'),
    1064: (60, 'breath', 'Breath bearer', 'The deceased raises a sail-shaped sign as he walks.'),
    1062: (56, 'ankh', 'Life bearer', 'The deceased holds an ankh before his face and carries another in his lowered hand.'),
    1060: (55, 'breath', 'Breath bearer', 'The deceased holds a sail-shaped sign before his face.'),
    1058: (54, 'breath', 'Breath bearer', 'The deceased raises the sail-shaped sign associated with breath.'),
    1054: (58, 'drinking', 'Drinking', 'The deceased lifts a small vessel toward his mouth.'),
}
SURVIVAL_CAPTIONS = {1038:47, 1036:46, 1035:46, 1033:45, 1031:44, 1027:43,
                     1049:52, 1047:51, 1046:50, 1042:49, 1041:48, 1071:59,
                     1070:57, 1067:61, 1065:60, 1063:56, 1061:55, 1059:54, 1069:58, 1053:62}
# Tall portions of the lower inscriptions, between the caption and ground rules. Each runs from
# the outer edge of the frame line on its left to that of the one on its right (both strokes of
# a double line), so the avatar passes behind the lines themselves.
SURVIVAL_COLUMNS = [(30, 177), (1849, 2114), (2489, 2761),
                    (3847, 4003), (4793, 5069)]
SURVIVAL_AVATAR = 'spell43_worshipper'    # the avatar is a copy of the scroll's first man, drawn facing left


def survival():
    source, out = SURVIVAL_SOURCE, SURVIVAL_OUT
    digest = sha(source)
    w, h, layers, chunks, _ = read_mdp(source)
    figures, entries = {}, {}
    strip = np.zeros((h, w), np.uint8)
    for layer in layers:
        if layer['type'] != '32bpp' or layer['id'] == '0':
            continue
        raw_alpha = layer['parentId'] == '1001'     # discard the scan's white backing; the scene supplies papyrus
        if raw_alpha and layer['visible'] == 'false':
            continue
        canvas = canvas_of(layer, w, h, chunks, raw_alpha)
        lid = int(layer['id'])
        if lid in SURVIVAL_FIGURES or lid in SURVIVAL_CAPTIONS:
            if lid in SURVIVAL_FIGURES:
                spell, key, name, description = SURVIVAL_FIGURES[lid]
                key = f'spell{spell}_{key}'
                journal = True
            else:
                spell = SURVIVAL_CAPTIONS[lid]
                key, name = f'spell{spell}_caption_{lid}', f'Spell {spell} caption'
                description = f'The hieroglyphic heading above the picture of spell {spell}, preserved as drawn.'
                journal = False
            box = Image.fromarray(canvas).getbbox()
            assert box, layer['name']
            x, y, right, bottom = box
            save_ink(canvas[y:bottom, x:right], out, key)
            figures[key] = dict(x=x, y=y, w=right-x, h=bottom-y, spell=spell, source_layer=lid)
            entries[key] = dict(name=name, descriptions={'default': description}, journal=journal)
        elif lid not in PIECES:
            strip = np.maximum(strip, canvas)
    # A column repeats everything drawn within it, rules and frame lines too, so its papyrus
    # backing hides only what passes behind it.
    for i, (left, right) in enumerate(SURVIVAL_COLUMNS):
        save_ink(strip[180:537, left:right], out, f'column_{i}')
    save_ink(strip, out, 'strip')
    level = dict(source='art/survival43-63.mdp', sha256=digest, width=w, height=h,
                 ground=534, view_height=701, scale=1.5, figures=figures,
                 columns=[dict(x=a, y=180, w=b-a, h=357) for a, b in SURVIVAL_COLUMNS])
    if (out/'level.json').exists():     # what extract_survival_pieces.py saved there stays
        saved = json.loads((out/'level.json').read_text())
        level.update({key: saved[key] for key in ('pieces', 'avatars') if key in saved})
    (out/'level.json').write_text(json.dumps(level, indent=1)+'\n')
    # Everything already in the registry stays, in its order (written descriptions, the pieces' entries);
    # only new IDs get the placeholders above.
    registry = out/'registry.json'
    if registry.exists():
        saved = json.loads(registry.read_text())['entries']
        entries = {**saved, **{key: entry for key, entry in entries.items() if key not in saved}}
    write_registry(registry, entries)
    write_survival_scene(figures)
    # Map art excludes the lower inscriptions and begins at the upper double rule.
    preview = strip.copy()
    for key, item in figures.items():
        a = np.asarray(Image.open(out/'figures'/f'{key}.png'))[..., 3]
        x, y = item['x'], item['y']
        preview[y:y+a.shape[0], x:x+a.shape[1]] = np.maximum(preview[y:y+a.shape[0], x:x+a.shape[1]], a)
    save_menu_picture('survival', preview, (30, 546), (8184, 8995))
    assert sha(source) == digest
    print(f'Survival: {len(SURVIVAL_FIGURES)} figures, {len(figures)-len(SURVIVAL_FIGURES)} captions, '
          f'{len(SURVIVAL_COLUMNS)} foreground columns; MDP unchanged.')


def write_survival_scene(figures):
    resources = ['[gd_scene format=3]',
        '[ext_resource type="Script" path="res://scripts/survival/survival_play.gd" id="level"]',
        '[ext_resource type="Script" path="res://scripts/avatar.gd" id="avatar"]',
        '[ext_resource type="Script" path="res://scripts/hud.gd" id="hud"]',
        '[ext_resource type="Shader" path="res://scripts/papyrus.gdshader" id="papyrus"]']
    for key in ['strip', *figures, *(f'column_{i}' for i in range(len(SURVIVAL_COLUMNS)))]:
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/survival/figures/{key}.png" id="{key}"]')
    nodes = ['''[sub_resource type="ShaderMaterial" id="paper"]
shader = ExtResource("papyrus")

[node name="Survival" type="Node2D"]
script = ExtResource("level")

[node name="Papyrus" type="ColorRect" parent="."]
material = SubResource("paper")
offset_left = -2000.0
offset_top = -1000.0
offset_right = 12000.0
offset_bottom = 2600.0
mouse_filter = 2
metadata/_edit_lock_ = true

[node name="Strip" type="Sprite2D" parent="."]
texture = ExtResource("strip")
centered = false
metadata/_edit_lock_ = true

[node name="Figures" type="Node2D" parent="."]
''']
    for spell in range(43, 64):
        group = f'Spell{spell}'
        nodes.append(f'[node name="{group}" type="Node2D" parent="Figures"]\n')
        for key, item in figures.items():
            if item['spell'] != spell:
                continue
            nodes.append(f'[node name="{key}" type="Sprite2D" parent="Figures/{group}"]\n'
                         f'position = Vector2({item["x"]}, {item["y"]})\n'
                         f'texture = ExtResource("{key}")\ncentered = false\n'
                         f'metadata/registry_id = "{key}"\n')
    nodes.append(avatar_node(9000, 534, -1, SURVIVAL_AVATAR, -125.5) + '''

[node name="Foreground" type="Node2D" parent="."]
z_index = 6
''')
    for i, (left, right) in enumerate(SURVIVAL_COLUMNS):
        group = f'Foreground/Column{i+1}'
        nodes.append(f'[node name="Column{i+1}" type="Node2D" parent="Foreground"]\n'
                     f'position = Vector2({left}, 180)\n'
                     f'[node name="Papyrus" type="ColorRect" parent="{group}"]\n'
                     f'material = SubResource("paper")\noffset_right = {right-left}.0\n'
                     f'offset_bottom = 357.0\nmouse_filter = 2\n'
                     f'[node name="Ink" type="Sprite2D" parent="{group}"]\n'
                     f'texture = ExtResource("column_{i}")\ncentered = false\n')
    nodes.append(camera_and_hud(8314) + '\n')
    (ROOT/'godot/scenes/survival.tscn').write_text('\n\n'.join(resources+nodes))


# --- gates --------------------------------------------------------------------------------------

GATES_SOURCE = ROOT / 'art/gates146-147.mdp'
GATES_146_X = 3179          # where spell 146 begins in that file; what lies left of it is spell 147's
GATES_146_WIDTH = 5500      # 146's part of the strip is this wide (as it was in its own file)
GATES_WIDTH = GATES_146_X + GATES_146_WIDTH     # 147 and 146 together; 144–145 begin over its end
GATES_SOURCE_144_145 = ROOT / 'art/gates144-145.mdp'
GATES_X_144_145 = GATES_146_X + 5220
# Spell 147's scenes, (plate, scene) -> gate; the gates read right to left from p67-5.
GATES_147 = {(67, 5): 1, (67, 4): 2, (68, 5): 3, (68, 4): 4, (68, 3): 5, (68, 2): 6, (68, 1): 7}
# The hieroglyphic titles and labels in the top band, cut out as clickable captions: layer -> (ID, spell, plate).
GATES_CAPTIONS = {'toptext_spell144': ('spell144_caption', 144, 60), 'toptext_spell145': ('spell145_caption', 145, 61),
                  'toptext1': ('spell146_caption', 146, 65), 'toptext2': ('spell146_caption_portal6', 146, 66),
                  'toptext3': ('spell146_caption_portal8', 146, 66), 'toptext': ('spell147_caption', 147, 67)}


def gates_caption(layer, canvas, figures, x_offset=0):
    """Cut the caption layer `layer` out as its own sprite."""
    key, spell, plate = GATES_CAPTIONS[layer['name']]
    x, y, right, bottom = Image.fromarray(canvas).getbbox()
    save_ink(canvas[y:bottom, x:right], GATES_OUT, key)
    figures[key] = dict(x=x_offset + x, y=y, w=right-x, h=bottom-y, spell=spell,
                        source_layer=int(layer['id']), source_name=layer['name'], plate=plate)
# Hidden in the MDP but part of the strip: the lower inscription of spell 144.
GATES_SHOWN_HIDDEN = {'specialtext'}
GATES_OUT = ROOT / 'godot/assets/gates'
# Scenes are numbered left to right within a plate; the rooms and pylons right to left.
GATES_ROOMS = {(60, 4): 1, (60, 3): 2, (60, 2): 3, (60, 1): 4, (61, 5): 5, (61, 4): 6, (61, 3): 7}
GATES_PYLON_AFTER = {61: 3, 62: 9, 63: 16, 64: 22}       # pylon = PYLON_AFTER[plate] - scene
# The two gods standing before each room, left then right (the right one is ram-headed).
GATES_ROOM_GODS = {1: ('hawk', 'man'), 2: ('bull', 'ram'), 3: ('man', 'ram'), 4: ('man', 'ram'),
                   5: ('bull', 'ram'), 6: ('hawk', 'ram'), 7: ('ram_1', 'ram_2')}


def gates():
    digests = {path: sha(path) for path in (GATES_SOURCE, GATES_SOURCE_144_145)}
    out = GATES_OUT
    registry = out / "registry.json"
    catalog = json.loads(registry.read_text())["entries"]
    figures, entries = {}, {}
    preview, w, h = export_146(catalog, figures, entries)
    width = GATES_X_144_145 + export_144_145(catalog, figures, entries)
    level = dict(sources=[dict(path='art/gates146-147.mdp', sha256=digests[GATES_SOURCE], x=0),
                          dict(path='art/gates144-145.mdp', sha256=digests[GATES_SOURCE_144_145], x=GATES_X_144_145)],
                 width=width, height=h,
                 ground=530, view_height=701, scale=1.5, figures=figures, columns=[],
                 intro_body='Explore the gates, pylons and portals of spells 144–147 and their keepers.\n\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Click a gate or one of its gods to inspect it. Open the Journal with [j].')
    (out/'level.json').write_text(json.dumps(level, indent=1) + '\n')
    if registry.exists():
        entries.update(json.loads(registry.read_text())['entries'])
    write_registry(registry, entries)
    write_gates_scene(figures)
    # Upper double rule is flush with the top; omit all lower inscriptions.
    save_menu_picture('gates', preview, (30, 531), (GATES_146_X + 4621, GATES_146_X + 5408))
    for path, digest in digests.items():
        assert sha(path) == digest
    print(f'Gates: {len(figures)} named sprites for spells 144–147; MDPs unchanged.')


def gates_layer_canvases(source, left=0, width=None, edge=0):
    """(layer, ink alpha on `width` columns of the canvas from column `left` on, the first `edge` of them
    blank) for every visible drawing layer of `source` that has ink there."""
    w, h, layers, chunks, _ = read_mdp(source)
    width = width or w - left
    for layer in layers:
        if layer['type'] != '32bpp' or layer['id'] == '0':
            continue
        if layer['visible'] == 'false' and layer['name'] not in GATES_SHOWN_HIDDEN:
            continue
        canvas = canvas_of(layer, w, h, chunks, layer['parentId'] == '1001')[:, left:left + width]
        canvas[:, :edge] = 0
        if canvas.any():
            yield layer, np.pad(canvas, ((0, 0), (0, width - canvas.shape[1])))


def export_146(catalog, figures, entries):
    w, h = read_mdp(GATES_SOURCE)[:2]
    w = GATES_WIDTH
    strip = np.zeros((h, w), np.uint8)
    preview = strip.copy()
    for layer, canvas in gates_layer_canvases(GATES_SOURCE, 0, GATES_WIDTH):
        preview = np.maximum(preview, canvas)
        if layer['name'] in GATES_CAPTIONS:
            gates_caption(layer, canvas, figures)
            continue
        match = re.fullmatch(r'p(\d+)-(\d+) (gate|figure|baboon|stand|praying)', layer['name'])
        if not match:
            strip = np.maximum(strip, canvas)
            continue
        plate, number, kind = match.groups()
        spell = 147 if kind in ('baboon', 'stand', 'praying') else 146
        if spell == 147:
            suffix = {'baboon': '_baboon', 'stand': '_stand', 'praying': '_adorer'}[kind]
            key = f'spell147_gate{GATES_147[int(plate), int(number)]}{suffix}'
        else:
            key = f'spell146_p{plate}_{number}_{kind}'
        x, y, right, bottom = Image.fromarray(canvas).getbbox()
        save_ink(canvas[y:bottom, x:right], GATES_OUT, key)
        figures[key] = dict(x=x, y=y, w=right-x, h=bottom-y, spell=spell,
                            source_layer=int(layer['id']), source_name=layer['name'], plate=int(plate))
        if spell == 147:
            continue
        # The catalog numbers portals right to left across plates 65, 66 and 67.
        portal = {65: 6, 66: 13, 67: 16}[int(plate)] - int(number)
        entry = catalog[f'spell146_portal{portal}']
        name = entry['name'] if kind == 'gate' else entry['name'] + ' guardian'
        entries[key] = dict(name=name, descriptions=entry['descriptions'])
    save_ink(strip, GATES_OUT, 'strip')
    return preview, w, h


def export_144_145(catalog, figures, entries):
    """Rooms of spell 144 and pylons of 145. Their registry IDs name them; a pylon's sprite is its
    structure with the plumes on top, and `plumes` records where they stand for plumes.gdshader."""
    w, h = read_mdp(GATES_SOURCE_144_145)[:2]
    strip = np.zeros((h, w), np.uint8)
    parts = {}    # key -> (canvas, layer, plate, plumes canvas)
    for layer, canvas in gates_layer_canvases(GATES_SOURCE_144_145):
        if layer['name'] in GATES_CAPTIONS:
            gates_caption(layer, canvas, figures, GATES_X_144_145)
            continue
        match = re.fullmatch(r'p(\d+)-(\d+) (.+)', layer['name'])
        if not match:
            strip = np.maximum(strip, canvas)
            continue
        plate, scene, kind = int(match[1]), int(match[2]), match[3]
        if (plate, scene) in GATES_ROOMS:
            room = GATES_ROOMS[plate, scene]
            suffix = {'gate': '', 'figure': '_keeper', 'god left': '_' + GATES_ROOM_GODS[room][0],
                      'god right': '_' + GATES_ROOM_GODS[room][1]}[kind]
            key = f'spell144_room{room}{suffix}'
        else:
            pylon = GATES_PYLON_AFTER[plate] - scene
            suffix = {'structure': '', 'structure top': '', 'god': '_keeper', 'adorer': '_adorer'}[kind]
            key = f'spell145_pylon{pylon}{suffix}'
        if kind == 'structure top':
            body, body_layer, _, _ = parts.get(key, (canvas * 0, None, plate, None))
            parts[key] = (np.maximum(body, canvas), body_layer, plate, canvas)
        elif key in parts:
            top_parts = parts[key]
            parts[key] = (np.maximum(top_parts[0], canvas), layer, plate, top_parts[3])
        else:
            parts[key] = (canvas, layer, plate, None)
    for key, (canvas, layer, plate, plumes) in parts.items():
        x, y, right, bottom = Image.fromarray(canvas).getbbox()
        save_ink(canvas[y:bottom, x:right], GATES_OUT, key)
        item = dict(x=GATES_X_144_145 + x, y=y, w=right-x, h=bottom-y, spell=int(key[5:8]),
                    source_layer=int(layer['id']), source_name=layer['name'], plate=plate)
        if plumes is not None:
            px, py, pright, pbottom = Image.fromarray(plumes).getbbox()
            item['plumes'] = dict(base=pbottom - y, center=(px + pright) / 2 - x, half_width=(pright - px) / 2)
        figures[key] = item
        if key.startswith('spell144') and key.endswith('_keeper'):
            room = catalog[key.removesuffix('_keeper')]
            entries[key] = dict(name=room['name'] + ' keeper', descriptions=room['descriptions'],
                                journal=room.get('journal', True))
    save_ink(strip, GATES_OUT, 'strip144_145')
    return w


def gates_figure_node(key, item):
    lines = [f'[node name="{key}" type="Sprite2D" parent="Figures/Spell{item["spell"]}/Plate{item["plate"]}"]',
             f'position = Vector2({item["x"]}, {item["y"]})']
    if key.endswith('_adorer'):
        lines.append('visible = false')    # each appears once its keeper is named
    if 'plumes' in item:
        lines.append(f'material = SubResource("plumes_{key}")')
    lines += [f'texture = ExtResource("{key}")', 'centered = false',
              f'metadata/registry_id = "{key}"', f'metadata/source_layer_id = {item["source_layer"]}']
    return '\n'.join(lines)


def plumes_material(key, item):
    plumes = item['plumes']
    return (f'[sub_resource type="ShaderMaterial" id="plumes_{key}"]\nshader = ExtResource("plumes")\n'
            f'shader_parameter/base = {plumes["base"]:.1f}\nshader_parameter/center = {plumes["center"]:.1f}\n'
            f'shader_parameter/half_width = {plumes["half_width"]:.1f}')


def write_gates_scene(figures):
    scene = ROOT/'godot/scenes/gates.tscn'
    if scene.exists():
        add_to_gates_scene(scene, figures)
        return
    x_far = GATES_X_144_145
    text = ['[gd_scene format=3]']
    for kind, path, key in [
        ('Script', 'scripts/gates/gates.gd', 'level'),
        ('Script', 'scripts/avatar.gd', 'avatar'),
        ('Script', 'scripts/hud.gd', 'hud'),
        ('Shader', 'scripts/papyrus.gdshader', 'papyrus'),
        ('Shader', 'scripts/gates/plumes.gdshader', 'plumes'),
    ]:
        text.append(f'[ext_resource type="{kind}" path="res://{path}" id="{key}"]')
    for key in ['strip', 'strip144_145', *figures]:
        text.append(f'[ext_resource type="Texture2D" path="res://assets/gates/figures/{key}.png" id="{key}"]')
    text.append('[sub_resource type="ShaderMaterial" id="paper"]\nshader = ExtResource("papyrus")')
    text += [plumes_material(key, item) for key, item in figures.items() if 'plumes' in item]
    text.append(f'''[node name="Gates" type="Node2D"]
script = ExtResource("level")
level_key = "gates"

[node name="Papyrus" type="ColorRect" parent="."]
material = SubResource("paper")
offset_left = -2000.0
offset_top = -1000.0
offset_right = {x_far + 15000}.0
offset_bottom = 2600.0
mouse_filter = 2
metadata/_edit_lock_ = true

[node name="Strip" type="Node2D" parent="."]
metadata/_edit_group_ = true

[node name="Strip146_147" type="Sprite2D" parent="Strip"]
texture = ExtResource("strip")
centered = false

[node name="Strip144_145" type="Sprite2D" parent="Strip"]
position = Vector2({x_far}, 0)
texture = ExtResource("strip144_145")
centered = false

[node name="Figures" type="Node2D" parent="."]''')
    groups = []
    for item in figures.values():
        spell, plate = f'Spell{item["spell"]}', f'Plate{item["plate"]}'
        if spell not in groups:
            groups.append(spell)
            text.append(f'[node name="{spell}" type="Node2D" parent="Figures"]')
        if (spell, plate) not in groups:
            groups.append((spell, plate))
            text.append(f'[node name="{plate}" type="Node2D" parent="Figures/{spell}"]')
    for key, item in figures.items():
        text.append(gates_figure_node(key, item))
    text.append(avatar_node(x_far + 12830, 530, -1, 'spell145_pylon1_adorer', -131.5) + '''

[node name="Foreground" type="Node2D" parent="."]
z_index = 6''')
    text.append(camera_and_hud(x_far + 12150))
    scene.write_text('\n\n'.join(text) + '\n')


def add_to_gates_scene(scene, figures):
    """Add sprites missing from the saved scene; saved nodes, positions and edits stay as they are."""
    text = scene.read_text()
    present = set(re.findall(r'metadata/registry_id = "([^"]+)"', text))
    missing = {key: item for key, item in figures.items() if key not in present}
    if not missing:
        return
    resources, materials, strips, nodes = [], [], [], []
    if 'id="plumes"' not in text:
        resources.append('[ext_resource type="Shader" path="res://scripts/gates/plumes.gdshader" id="plumes"]')
    if 'id="strip144_145"' not in text:
        resources.append('[ext_resource type="Texture2D" path="res://assets/gates/figures/strip144_145.png" id="strip144_145"]')
        strips.append(f'[node name="Strip144_145" type="Sprite2D" parent="Strip"]\nposition = Vector2({GATES_X_144_145}, 0)\n'
                     'texture = ExtResource("strip144_145")\ncentered = false')
    for key, item in missing.items():
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/gates/figures/{key}.png" id="{key}"]')
        if 'plumes' in item:
            materials.append(plumes_material(key, item))
        spell_path = f'Figures/Spell{item["spell"]}'
        # The editor saves headers with a unique_id after the parent, so match only up to the parent.
        spell = f'[node name="Spell{item["spell"]}" type="Node2D" parent="Figures"'
        if spell not in text + '\n'.join(nodes):
            nodes.append(spell + ']')
        group = f'[node name="Plate{item["plate"]}" type="Node2D" parent="{spell_path}"'
        if group not in text + '\n'.join(nodes):
            nodes.append(group + ']')
        nodes.append(gates_figure_node(key, item))
    first_sub = min(i for i in (text.find('\n[sub_resource'), text.find('\n[node')) if i >= 0)
    text = text[:first_sub] + ''.join('\n\n' + r for r in resources) + text[first_sub:]
    first_node = text.find('\n[node')
    text = text[:first_node] + ''.join('\n\n' + m for m in materials) + text[first_node:]
    behind = text.find('\n[node name="Figures"')
    text = text[:behind] + ''.join('\n\n' + n for n in strips) + text[behind:]
    avatar = text.find('\n[node name="Avatar"')
    text = text[:avatar] + ''.join('\n\n' + n for n in nodes) + text[avatar:]
    scene.write_text(re.sub(r'([^\n])\n\[', r'\1\n\n[', text))


# --- cosmos -------------------------------------------------------------------------------------

def cosmos():
    source = ROOT/'art/cosmos17-21.mdp'
    out = ROOT/'godot/assets/cosmos'
    digest = sha(source)
    w, h, layers, chunks, _ = read_mdp(source)
    byid = {l['id']: l for l in layers}
    background = np.zeros((h, w), np.uint8)
    for l in layers:
        parent = byid.get(l.get('parentId'), {}).get('name', '')
        if l['type'] != '32bpp' or parent not in ('guidelines', 'text_below') or l.get('clipping') == 'true':
            continue
        background = np.maximum(background, canvas_of(l, w, h, chunks, parent == 'guidelines'))
    save_ink(background, out, 'strip')
    data = json.loads((out/'figures.json').read_text())
    avatar = data['figures']['deceased_with_staff']
    level = dict(source='art/cosmos17-21.mdp', sha256=digest, width=w, height=h,
                 ground=534, view_height=701, scale=1.5, plates=data['plates'], figures=data['figures'])
    (out/'level.json').write_text(json.dumps(level, indent=1, ensure_ascii=False)+'\n')
    resources = ['[gd_scene format=3]\n',
     '[ext_resource type="Script" path="res://scripts/walk/walk.gd" id="level"]',
     '[ext_resource type="Texture2D" path="res://assets/cosmos/figures/strip.png" id="strip"]',
     '[ext_resource type="Script" path="res://scripts/avatar.gd" id="avatar"]',
     '[ext_resource type="Script" path="res://scripts/hud.gd" id="hud"]',
     '[ext_resource type="Shader" path="res://scripts/papyrus.gdshader" id="papyrus"]']
    for name in data['figures']:
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/cosmos/figures/{name}.png" id="{name}"]')
    nodes = ['''[sub_resource type="ShaderMaterial" id="paper"]
shader = ExtResource("papyrus")
shader_parameter/base = Color(0.906, 0.839, 0.682, 1)
shader_parameter/fibre = Color(0.47, 0.35, 0.16, 1)

[node name="Cosmos" type="Node2D"]
script = ExtResource("level")
level_key = "cosmos"
hint_key = "cosmos"
title = "The Night Journey"
journal_hint = "Click figures in the scroll to record them here."
intro_title = "Spell 17: The Night Journey"
intro_body = "Explore the night world as it is drawn.\\n\\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Click a figure to walk up to it and read its description. Open the Journal with [j]."

[node name="Papyrus" type="ColorRect" parent="."]
material = SubResource("paper")
offset_left = -2000.0
offset_top = -1000.0
offset_right = 14000.0
offset_bottom = 2600.0
mouse_filter = 2
metadata/_edit_lock_ = true
color = Color(0.906, 0.839, 0.682, 1)

[node name="Strip" type="Sprite2D" parent="."]
texture = ExtResource("strip")
centered = false
metadata/_edit_lock_ = true

[node name="Figures" type="Node2D" parent="."]
''']
    groups = {}
    for name, e in data['figures'].items():
        if name == 'deceased_with_staff':
            continue
        group = ''.join(word[:1].upper() + word[1:] for word in e['group'].split('/')[0].split())   # PascalCase
        groups.setdefault(group, []).append((name, e))
    for group, figures in groups.items():
        nodes.append(f'[node name="{group}" type="Node2D" parent="Figures"]\n')
        for name, e in figures:
            nodes.append(f'[node name="{name}" type="Sprite2D" parent="Figures/{group}"]\n'
                         f'position = Vector2({e["x"]}, {e["y"]})\ntexture = ExtResource("{name}")\n'
                         f'centered = false\nmetadata/registry_id = "{name}"\n')
    x = avatar['x'] + avatar['w']/2
    nodes.append(avatar_node(f'{x:g}', 534, 1, 'deceased_with_staff', f"{-avatar['h']/2:g}")
                 + '\n\n' + camera_and_hud(11164) + '\n')
    (ROOT/'godot/scenes/cosmos.tscn').write_text('\n'.join(resources)+'\n\n'+'\n'.join(nodes))
    assert sha(source) == digest
    print(f'Cosmos: {len(data["figures"])} exported figures, 51 static sprites and one walking avatar; source unchanged')


LEVELS = {'gates': gates, 'survival': survival, 'cosmos': cosmos}

if __name__ == '__main__':
    if len(sys.argv) != 2 or sys.argv[1] not in LEVELS:
        sys.exit('usage: python .claude/skills/build-levels/build_scene.py ' + '|'.join(LEVELS))
    LEVELS[sys.argv[1]]()
