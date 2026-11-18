"""Export the Field of Offerings (spell 110, pl. XL–XLII) from art/fields110.mdp and write its saved exploration scene.

    python .claude/skills/build-levels/build_field.py [--into DIR]

The MDP is only read, and checked unchanged at the end. Writes, under godot/ (or DIR/godot with --into,
which is how to check the tool without touching the repository; copy the registry there first):

  assets/field/figures/*.png   every figure, caption and column, cropped to its ink
  assets/field/level.json      stable IDs, source rectangles (MDP canvas pixels), lanes, columns, the page
  assets/field/registry.json   new figures get their entry; every entry already there is kept as written
  scenes/field.tscn            written only when it does not exist, so placement edited in Godot survives
  assets/menu/field.png        the map picture, from the top of the double rule over the page

Where the pieces come from:
  - Each layer of the `dissected` folder is one sprite (FIGURES, keyed by layer ID, which stays put when a
    layer is renamed or moved). A layer not listed is reported and left in the strip.
  - The side plates (the four stacked panels of pl. XLII and the two large adorants) are not dissected in
    the MDP: SIDE_FIGURES cuts them out of the page layers by rectangle.
  - The captions are in the one scan layer with the frame: CAPTIONS cuts the strokes lying inside each
    caption's rectangle(s). Their registry IDs are the ones already in registry.json.
  - The strip is everything else, the frame guides included. A column (tall hieroglyphic text that
    covers the walking avatar) repeats the strip's ink in its rectangle; the scene lays it over the
    avatar on papyrus.
Folders hidden in the MDP stay out unless named in SHOWN_HIDDEN.
"""
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

sys.path.insert(0, str(Path(__file__).parent))
TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from mdp import read_mdp
from cutlib import canvas_of, save_ink
from build_scene import ROOT, sha, write_registry, avatar_node, save_menu_picture

SOURCE = ROOT / 'art/fields110.mdp'
PAGE = dict(x=1040, y=268, w=7580, h=2692)    # the drawn scroll on the 10000-px canvas; the strip is cut to it
# Each register: its ground line, the row where its framed picture begins (the water above is another
# register's way across), and how many of the ABOVE_BELOW rows its camera shows lie over the ground (the
# same height for every lane, so that the zoom is the same everywhere). The last lane, `base`, is the page's own floor: the
# lower panel of pl. XLII and the large adorants stand on it, below the third register's water.
LANES = [('top', 1230, 610, 660), ('middle', 1943, 1383, 660), ('bottom', 2754, 2108, 660), ('base', 2935, 2757, 685)]
ABOVE_BELOW = 710
WATER = (2938, 7087)                 # x range of the water frame round the three registers: click it to cross
SHOWN_HIDDEN = {'Solar crossing'}   # hidden in the MDP, but its figures are part of the top register
MIN_STROKE = 20                      # connected ink smaller than this is scan dust, left in the strip
SLACK = 10                           # a caption's strokes may overhang its rectangle by this much
AVATAR = 'walking_worshipper'        # the avatar is a copy of this man, drawn facing left
START = (7000, 1230)                 # in the water frame to the right of the top register: the procession arrives
# The map picture: from the top of the double rule over the page, the procession of worshippers and the
# gods they come to, without the lower inscriptions.
MENU = dict(x=5745, y=272, w=1540)

PLATE_XLI = 'Plate41'
# Layer ID -> (key, name, description, reference). The group is the layer's own folder in the MDP.
FIGURES = {
    '104': ('mummiform_god', 'Mummiform god', 'A god stands upright in mummy wrappings, with three heads crowded at the top, a cross on his chest and long bands down his body.', 'as drawn'),
    '102': ('bird_stand', 'Offering stand', 'A tall stand carries a row of small round offerings.', 'as drawn'),
    '101': ('bird_on_offerings', 'Bird on the offerings', 'A bird lies on top of the offerings on the stand beneath it.', 'as drawn'),
    '99': ('falcon', 'Falcon', 'A falcon stands on a tall pedestal.', 'as drawn'),
    '98': ('human_headed_bird', 'Human-headed bird', 'A bird with a human head, a long wig and a broad collar stands on a base, its tail trailing behind it.', 'as drawn'),
    '95': ('cup_bearer_boat', 'Cup bearer', 'A man holds out a small cup toward the boat.', 'as drawn'),
    '93': ('boat', 'The boat', 'A long boat with curving ends carries a table of tall jars and two bowls on stands; a man sits in it holding a pole.', 'as drawn'),
    '89': ('round_sign_3', '', '', ''),
    '90': ('round_sign_2', '', '', ''),
    '91': ('round_sign_1', '', '', ''),
    '86': ('seated_god_1', 'Seated god', 'One of three gods who sit side by side on a dais, each with a crown on his head.', 'as drawn'),
    '85': ('seated_god_2', 'Seated god', 'One of three gods who sit side by side on a dais, each with a crown on his head.', 'as drawn'),
    '84': ('seated_god_3', 'Seated god', 'One of three gods who sit side by side on a dais, each with a crown on his head.', 'as drawn'),
    '83': ('dais', 'Dais', 'A low dais with a ribbed top carries the three seated gods.', 'as drawn'),
    '81': ('heaped_stand', 'Heaped offering stand', 'A tall stand heaped with offerings stands before the seated gods: loaves and fruit, with a leaf curving over them.', 'as drawn'),
    '79': ('cup_bearer_procession', 'Cup bearer', 'A man at the head of the line holds out a small cup.', 'as drawn'),
    '78': ('adorant_procession', 'Adorant', 'A man in the line of worshippers raises one hand in adoration.', 'as drawn'),
    '77': ('walking_worshipper', 'Walking worshipper', 'A man walks forward in the line of worshippers, one arm hanging at his side.', 'as drawn'),
    '76': ('yoke_bearer', 'Man with a yoke', 'A man at the tail of the line carries a bar across his shoulders.', 'as drawn'),
    '73': ('enthroned_god', 'Enthroned god', 'A god sits on a block throne beneath a tall crown of upright stems.', 'as drawn'),
    '71': ('offering_stand', 'Offering stand', 'A slender stand carries offerings under a curving leaf, before the enthroned god.', 'as drawn'),
    '69': ('adorant_offering', 'Adorant', 'A man stands before the offering stand with both hands raised.', 'as drawn'),
    '68': ('kneeling_man', 'Kneeling man', 'A man kneels with his arms folded on his knee.', 'as drawn'),
    '67': ('adorant_heron', 'Adorant', 'A man raises one hand in adoration beside the heron.', 'as drawn'),
    '65': ('heron', 'Heron', 'A heron with a long beak is drawn above a small standard.', 'as drawn'),
    '62': ('grain_heap_left', 'Heap of grain', 'A domed heap of grain, its surface marked with round grains.', 'as drawn'),
    '61': ('grain_heap_right', 'Heap of grain', 'A domed heap of grain, its surface marked with small ears.', 'as drawn'),
    '59': ('threshing_ox', 'Ox', 'An ox walks on the threshing floor.', 'as drawn'),
    '58': ('flail_man', 'Man with a flail', 'A man raises a flail behind the ox on the threshing floor.', 'as drawn'),
    '57': ('threshing_floor', 'Threshing floor', 'The threshing floor is drawn as a long low strip of dotted ground.', 'as drawn'),
    '54': ('reaper_left', 'Reaper', 'A man bends to cut the standing grain with a sickle.', 'as drawn'),
    '53': ('reaper_right', 'Reaper', 'A man bends to cut the standing grain with a sickle.', 'as drawn'),
    '51': ('crops_left', 'Standing grain', 'Tall ripe grain stands in a bed, its ears high above the reapers.', 'as drawn'),
    '50': ('crops_right', 'Standing grain', 'Tall ripe grain stands in a bed, its ears high above the reapers.', 'as drawn'),
    '48': ('tree', 'Tree', 'A tall slender tree with many fine branches stands between the reapers and the sower.', 'as drawn'),
    '46': ('sower', 'Sower', 'A man throws seed with one arm raised above his head.', 'as drawn'),
    '45': ('seed', 'Seed', 'Seed falls in dotted streams in a wide arc from the sower.', 'as drawn'),
    '42': ('hoe_man', 'Man with a hoe', 'A man works the earth with a hoe behind the ox.', 'as drawn'),
    '41': ('plough_ox', 'Ox', 'An ox with long horns walks forward.', 'as drawn'),
    '38': ('caption_bot_heron_island', None, None, None),      # its entry is already in the registry
    '36': ('stairway_boat', 'Boat with a stairway', 'A boat with a snake\'s head at each end carries a flight of steps amidships.', 'as drawn'),
    '33': ('throne_boat', 'Boat with a throne', 'A boat with a snake\'s head at each end carries a throne; bundles of oars lean at both ends.', 'as drawn'),
    '30': ('canal_god_1', 'Seated god', 'One of three gods who sit in a row beside the channel, one knee raised.', 'as drawn'),
    '29': ('canal_god_2', 'Seated god', 'One of three gods who sit in a row beside the channel, one knee raised.', 'as drawn'),
    '28': ('canal_god_3', 'Seated god', 'One of three gods who sit in a row beside the channel, one knee raised.', 'as drawn'),
    '26': ('landing_steps', 'Landing steps', 'A short flight of steps rises at the water\'s edge.', 'as drawn'),
}
STATIC = {'round_sign_1', 'round_sign_2', 'round_sign_3'}   # no registry entry yet: sources do not say what they are

# The side plates are in the page layers 105 (left) and 106 (right), not dissected: key ->
# (layer ID, rectangle x0 y0 x1 y1 on the canvas, group, name, description, reference).
LEFT, RIGHT = '105', '106'
SIDE_FIGURES = {
    'panel1_goddesses': (LEFT, (1090, 640, 1345, 1090), 'Panel1', 'Two goddesses', 'Two women stand side by side, each with a sign on her head, each holding a long staff.', 'as drawn'),
    'panel1_barque': (LEFT, (1340, 630, 1835, 1095), 'Panel1', 'Boat with a shrine', 'A boat with high curving ends carries a shrine with a scarab beetle in it, and stands on a block patterned with waves.', 'as drawn'),
    'panel2_enthroned': (LEFT, (1095, 1290, 1440, 1735), 'Panel2', 'Enthroned god and goddess', 'A god sits on a throne in a tall crown with his sceptres, and a goddess stands behind him.', 'as drawn'),
    'panel2_stand': (LEFT, (1448, 1395, 1548, 1735), 'Panel2', 'Offering stand', 'A slender stand holds a round object, with a fan-shaped plume behind it.', 'as drawn'),
    'panel2_deceased': (LEFT, (1548, 1370, 1730, 1735), 'Panel2', 'Man with a staff', 'A man stands facing the throne with a long staff in his hand.', 'as drawn'),
    'panel2_adorant': (LEFT, (1730, 1400, 1835, 1735), 'Panel2', 'Adorant', 'A man raises both hands in adoration.', 'as drawn'),
    'panel3_gods': (LEFT, (1070, 1990, 1335, 2320), 'Panel3', 'Two seated gods', 'Two gods sit side by side on a block, knees raised, in long wigs and collars.', 'as drawn'),
    'panel3_table': (LEFT, (1395, 1930, 1640, 2320), 'Panel3', 'Offering table', 'A table stands on four tall jars; an animal lies on it, with a tray of offerings above.', 'as drawn'),
    'panel3_kneeling': (LEFT, (1645, 2020, 1810, 2320), 'Panel3', 'Kneeling man', 'A man kneels with both hands raised in adoration.', 'as drawn'),
    'panel4_gods': (LEFT, (1070, 2570, 1380, 2915), 'Panel4', 'Two seated gods', 'Two gods sit side by side on a block, knees raised, in long wigs and collars.', 'as drawn'),
    'panel4_stand': (LEFT, (1380, 2710, 1475, 2910), 'Panel4', 'Offering stand', 'A small stand holds a spray of upright stems.', 'as drawn'),
    'panel4_table': (LEFT, (1480, 2615, 1640, 2900), 'Panel4', 'Offering table', 'A table stands on four tall jars; an animal with long curved horns lies on it.', 'as drawn'),
    'panel4_kneeling': (LEFT, (1625, 2573, 1805, 2900), 'Panel4', 'Kneeling man', 'A man kneels with both hands raised in adoration.', 'as drawn'),
    'adorant_left': (LEFT, (1936, 1894, 2360, 2930), 'Adorants', 'Large adorant', 'A large figure stands in a long dress and sash with both hands raised, framed by columns of hieroglyphs.', 'as drawn'),
    'adorant_right': (RIGHT, (8090, 1792, 8510, 2930), 'Adorants', 'Large adorant', 'A large figure stands in a long dress and sash with both hands raised, framed by columns of hieroglyphs.', 'as drawn'),
}
SIDE_PLATE = {'Panel1': 'Plate42', 'Panel2': 'Plate42', 'Panel3': 'Plate42', 'Panel4': 'Plate42'}

# Captions, by their registry ID: x0 y0 x1 y1 rectangles on the canvas. A caption takes the strokes
# that lie wholly inside its rectangle(s) (give or take SLACK); ('clip', rect) takes whatever ink lies in the
# rectangle instead, for the ovals that touch each other or the frame. Which text belongs to which label is a reading, noted in each
# entry's `reference` and in TODO.md.
CAPTIONS = {
    'caption_top_oval_qenqenet': [('clip', (3103, 614, 3358, 758))],
    'caption_top_oval_no_sweat': [(3356, 625, 3605, 758)],
    'caption_top_oval_great_town': [('clip', (3103, 764, 3358, 906))],
    'caption_top_horizon_gods': [(3606, 618, 3705, 775)],
    'caption_top_hotep_falcon': [(3790, 625, 3990, 755)],
    'caption_top_being_hotep': [(3105, 985, 3500, 1215)],
    'caption_top_osiris_cup': [(4670, 620, 4760, 870)],
    'caption_top_osiris_boat': [(5335, 625, 5420, 875)],
    'caption_top_rowing': [(5432, 625, 5512, 880)],
    'caption_top_great_ennead': [(5835, 630, 6045, 712)],
    'caption_top_osiris_procession': [(6190, 628, 6475, 725)],
    'caption_mid_hapi': [(3215, 1384, 3310, 1660)],
    'caption_mid_osiris': [(3365, 1384, 3470, 1620)],
    'caption_mid_overflow': [(3600, 1640, 3850, 1880)],
    'caption_mid_oval_hotep': [(3915, 1384, 4130, 1486)],
    'caption_mid_oval_great_green': [(4132, 1384, 4346, 1486)],
    'caption_mid_oval_flourishing': [(4346, 1384, 4556, 1486)],
    'caption_mid_oval_knife': [(4558, 1384, 4790, 1500)],
    'caption_mid_hippo_lake': [(3930, 1488, 4850, 1700)],
    'caption_mid_ploughing': [(6290, 1455, 6660, 1565)],
    'caption_bot_oval_food': [('clip', (3103, 2108, 3297, 2210))],
    'caption_bot_oval_slaughter': [('clip', (3297, 2108, 3506, 2210))],
    'caption_bot_oval_nehet': [('clip', (3103, 2210, 3297, 2312))],
    'caption_bot_oval_strong': [('clip', (3297, 2210, 3506, 2312))],
    'caption_bot_rehorakhty_bark': [(3595, 2115, 4090, 2320)],
    'caption_bot_throne_bark': [(4395, 2108, 5100, 2210), (4160, 2108, 4290, 2420)],
    'caption_bot_great_food': [(5520, 2108, 5640, 2360)],
    'caption_bot_island_re': [(5940, 2150, 6062, 2292)],
    'caption_bot_blessed': [(6190, 2108, 6909, 2345)],
    'caption_bot_birthplace': [(6200, 2485, 6909, 2600)],
    'caption_bot_destroying_water': [(5995, 2530, 6190, 2610)],
    'caption_bot_three_gods': [(5890, 2570, 5995, 2745)],
}

# Tall hieroglyphic text that covers the avatar: x0 y0 x1 y1, each from the outer edge of its left rule to
# that of its right one so the avatar passes behind the rules too. The `short` ones stand over a large adorant.
COLUMNS = {
    'left_short': (1844, 424, 2394, 1770),
    'left_tall': (2390, 424, 2942, 2940),
    'right_tall': (7082, 424, 7967, 2940),
    'right_short': (7960, 424, 8612, 1667),
}


def visible(layer, by_id):
    """A layer shows when it and each folder around it does (SHOWN_HIDDEN folders count as shown)."""
    while True:
        if layer['visible'] == 'false' and layer['name'] not in SHOWN_HIDDEN:
            return False
        if layer['parentId'] == '-1':
            return True
        layer = by_id[layer['parentId']]


def folder_path(layer, by_id):
    names = []
    while layer['parentId'] != '-1':
        layer = by_id[layer['parentId']]
        names.append(layer['name'])
    return names[::-1]


def take(canvas, rect, inside):
    """Remove from `canvas` and return (as a mask of its size) the ink strokes of `rect` (x0, y0, x1, y1):
    those lying wholly inside it (`inside`), or all that touch it; strokes under MIN_STROKE px stay."""
    x0, y0, x1, y1 = rect
    pad = 60 if inside else 0   # inside: look this far around the rectangle, so a stroke leaving it is seen whole
    ox, oy = max(0, x0 - pad), max(0, y0 - pad)
    sub = canvas[oy:y1 + pad, ox:x1 + pad]
    labels, count = ndi.label(sub > 0, structure=np.ones((3, 3)))
    mask = np.zeros(canvas.shape, bool)
    areas = np.bincount(labels.ravel(), minlength=count + 1)
    for index, box in enumerate(ndi.find_objects(labels), 1):
        bx0, by0, bx1, by1 = box[1].start + ox, box[0].start + oy, box[1].stop + ox, box[0].stop + oy
        if areas[index] < MIN_STROKE:
            continue
        if inside and not (bx0 >= x0 - SLACK and by0 >= y0 - SLACK and bx1 <= x1 + SLACK and by1 <= y1 + SLACK):
            continue
        if not inside and (bx1 <= x0 or bx0 >= x1 or by1 <= y0 or by0 >= y1):
            continue
        mask[oy:y1 + pad, ox:x1 + pad] |= labels == index
    if not inside:      # a plain rectangle: the strokes are cut at its edge
        outside = np.ones(canvas.shape, bool)
        outside[y0:y1, x0:x1] = False
        mask &= ~outside
    return mask


def export(base):
    out = base / 'godot/assets/field'
    digest = sha(SOURCE)
    w, h, layers, chunks, _ = read_mdp(SOURCE)
    by_id = {l['id']: l for l in layers}
    figures, entries = {}, {}
    strip = np.zeros((h, w), np.uint8)
    preview = np.zeros((h, w), np.uint8)
    seen = set()
    listed = {i: v for i, v in FIGURES.items()}

    def put(key, mask, canvas, **info):
        ys, xs = np.nonzero(mask)
        x, y, right, bottom = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
        save_ink(np.where(mask, canvas, 0)[y:bottom, x:right], out, key)
        preview[mask] = np.maximum(preview[mask], canvas[mask])
        figures[key] = dict(x=x, y=y, w=right - x, h=bottom - y, **info)

    page_layers = {}
    for layer in layers:
        if layer['type'] != '32bpp' or layer['id'] == '0' or not visible(layer, by_id):
            continue
        path = folder_path(layer, by_id)
        canvas = canvas_of(layer, w, h, chunks, path[:1] == ['guidelines'])
        if layer['id'] in listed:
            key = listed[layer['id']][0]
            seen.add(layer['id'])
            group = ''.join(word[:1].upper() + word[1:] for word in path[1].split())   # PascalCase
            put(key, canvas > 0, canvas, plate=PLATE_XLI, group=group, source_layer=int(layer['id']),
                source_name=layer['name'])
            if listed[layer['id']][1] is not None and key not in STATIC:
                entries[key] = dict(name=listed[layer['id']][1], descriptions={'default': listed[layer['id']][2]},
                                    journal=True, reference=listed[layer['id']][3])
            continue
        if path[:1] == ['dissected'] and len(path) > 1:
            print(f"not in FIGURES, left in the strip: id {layer['id']} '{layer['name']}' in {'/'.join(path)}")
        page_layers[layer['id']] = canvas
    missing = set(listed) - seen
    assert not missing, f'FIGURES lists layers that are not visible in the MDP: {sorted(missing)}'

    for key, (lid, rect, group, name, description, reference) in SIDE_FIGURES.items():
        mask = take(page_layers[lid], rect, inside=False)
        put(key, mask, page_layers[lid], plate=SIDE_PLATE.get(group, 'Plate40'), group=group, source_layer=int(lid))
        page_layers[lid][mask] = 0
        entries[key] = dict(name=name, descriptions={'default': description}, journal=True, reference=reference)
    captions = page_layers['23']
    for key, rects in CAPTIONS.items():
        mask = np.zeros(captions.shape, bool)
        for rect in rects:
            mask |= take(captions, rect[1], inside=False) if rect[0] == 'clip' else take(captions, rect, inside=True)
        assert mask.any(), f'no strokes in the rectangle(s) of {key}'
        put(key, mask, captions, plate=PLATE_XLI, group='Captions' + key.split('_')[1].capitalize(), source_layer=23)
        captions[mask] = 0
    for canvas in page_layers.values():
        strip = np.maximum(strip, canvas)

    x0, y0 = PAGE['x'], PAGE['y']
    save_ink(strip[y0:y0 + PAGE['h'], x0:x0 + PAGE['w']], out, 'strip')
    columns = {}
    for key, (cx0, cy0, cx1, cy1) in COLUMNS.items():
        save_ink(strip[cy0:cy1, cx0:cx1], out, f'column_{key}')
        columns[key] = dict(x=cx0, y=cy0, w=cx1 - cx0, h=cy1 - cy0)

    lanes = [dict(key=key, ground=ground, top=ground - above, bottom=ground - above + ABOVE_BELOW, inner_top=inner_top)
             for key, ground, inner_top, above in LANES]
    level = dict(source='art/fields110.mdp', sha256=digest, width=w, height=h, page=PAGE, scale=1.5,
                 view_height=ABOVE_BELOW, start=dict(x=START[0], y=START[1]), avatar=AVATAR, lanes=lanes, water=dict(x0=WATER[0], x1=WATER[1]),
                 figures=figures, columns=columns)
    (out / 'level.json').write_text(json.dumps(level, indent=1, ensure_ascii=False) + '\n')
    registry = out / 'registry.json'
    assert registry.exists(), 'godot/assets/field/registry.json holds the captions and must exist'
    saved = json.loads(registry.read_text())['entries']
    for key in CAPTIONS:
        assert key in saved, f'caption {key} has no registry entry'
    orphans = [k for k in saved if k not in figures]
    assert not orphans, f'registry entries without a sprite: {orphans}'
    # Everything already in the registry stays in its order; new figures are appended.
    write_registry(registry, {**saved, **{k: v for k, v in entries.items() if k not in saved}})
    write_scene(base, figures)
    rows = (MENU['y'], MENU['y'] + round(MENU['w'] * 280 / 440))
    (base / 'godot/assets/menu').mkdir(parents=True, exist_ok=True)
    save_menu_picture('field', np.maximum(preview, strip), rows, (MENU['x'], MENU['x'] + MENU['w']), base / 'godot/assets/menu')
    assert sha(SOURCE) == digest
    print(f'Field: {len(figures)} sprites ({len(CAPTIONS)} captions, {len(SIDE_FIGURES)} cut from the side plates), '
          f'{len(columns)} columns; MDP unchanged.')


def write_scene(base, figures):
    scene = base / 'godot/scenes/field.tscn'
    if scene.exists():
        print('scenes/field.tscn exists and is kept; delete it to write it afresh.')
        return
    resources = ['[gd_scene format=3]\n',
            '[ext_resource type="Script" path="res://scripts/field/field.gd" id="level"]',
            '[ext_resource type="Script" path="res://scripts/avatar.gd" id="avatar"]',
            '[ext_resource type="Script" path="res://scripts/hud.gd" id="hud"]',
            '[ext_resource type="Shader" path="res://scripts/papyrus.gdshader" id="papyrus"]',
            '[ext_resource type="Texture2D" path="res://assets/field/figures/strip.png" id="strip"]']
    for key in figures:
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/field/figures/{key}.png" id="{key}"]')
    for key in COLUMNS:
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/field/figures/column_{key}.png" id="column_{key}"]')
    resources.append('\n[sub_resource type="ShaderMaterial" id="paper"]\nshader = ExtResource("papyrus")')
    text = []
    text.append(f'''[node name="Field" type="Node2D"]
script = ExtResource("level")

[node name="Papyrus" type="ColorRect" parent="."]
material = SubResource("paper")
offset_left = -1000.0
offset_top = -1000.0
offset_right = 11000.0
offset_bottom = 4300.0
mouse_filter = 2
metadata/_edit_lock_ = true

[node name="Strip" type="Sprite2D" parent="."]
position = Vector2({PAGE['x']}, {PAGE['y']})
texture = ExtResource("strip")
centered = false
metadata/_edit_lock_ = true

[node name="Figures" type="Node2D" parent="."]''')
    made = set()
    for key, item in figures.items():
        plate, group = item['plate'], item['group']
        if plate not in made:
            made.add(plate)
            text.append(f'[node name="{plate}" type="Node2D" parent="Figures"]')
        if (plate, group) not in made:
            made.add((plate, group))
            text.append(f'[node name="{group}" type="Node2D" parent="Figures/{plate}"]')
        lines = [f'[node name="{key}" type="Sprite2D" parent="Figures/{plate}/{group}"]',
                 f'position = Vector2({item["x"]}, {item["y"]})', f'texture = ExtResource("{key}")', 'centered = false']
        if key not in STATIC:
            lines.append(f'metadata/registry_id = "{key}"')
        lines.append(f'metadata/source_layer_id = {item["source_layer"]}')
        text.append('\n'.join(lines))
    avatar = figures[AVATAR]
    text.append(avatar_node(START[0], START[1], -1, AVATAR, f'{-avatar["h"] / 2:g}'))
    text.append('[node name="Foreground" type="Node2D" parent="."]\nz_index = 6')
    for key, box in {k: dict(x=v[0], y=v[1], w=v[2] - v[0], h=v[3] - v[1]) for k, v in COLUMNS.items()}.items():
        name = ''.join(part.title() for part in key.split('_'))
        text.append(f'[node name="{name}" type="Node2D" parent="Foreground"]\nposition = Vector2({box["x"]}, {box["y"]})')
        text.append(f'[node name="Papyrus" type="ColorRect" parent="Foreground/{name}"]\nmaterial = SubResource("paper")\n'
                    f'offset_right = {box["w"]}.0\noffset_bottom = {box["h"]}.0\nmouse_filter = 2')
        text.append(f'[node name="Ink" type="Sprite2D" parent="Foreground/{name}"]\n'
                    f'texture = ExtResource("column_{key}")\ncentered = false')
    text.append(f'[node name="Camera" type="Camera2D" parent="."]\nposition = Vector2({START[0]}, {START[1] - 330})\n\n'
                '[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("hud")')
    scene.parent.mkdir(parents=True, exist_ok=True)
    scene.write_text('\n'.join(resources) + '\n\n' + '\n\n'.join(text) + '\n')


if __name__ == '__main__':
    args = sys.argv[1:]
    base = ROOT
    if args[:1] == ['--into']:
        base = Path(args[1]).resolve()
        assert ROOT not in base.parents and base != ROOT, '--into must be outside the repository'
        registry = base / 'godot/assets/field/registry.json'
        registry.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(ROOT / 'godot/assets/field/registry.json', registry)
    elif args:
        sys.exit(__doc__)
    export(base)
