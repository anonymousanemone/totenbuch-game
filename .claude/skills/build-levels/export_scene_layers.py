"""Refresh Procession and Dangers from their current MDP layers (read-only).

Run with the project's scientific Python environment:
    python .claude/skills/build-levels/export_scene_layers.py [procession|dangers ...]

Exports every non-background, non-clipping artwork layer. Existing gameplay images
retain their canvas rectangles where possible, so hand-placed pivots and puzzle
geometry survive a refresh. New static figures become saved scene sprites. The
manifest records MDP layer IDs and source rectangles; authored descriptions stay
in the separate per-level registries. No previews or MDP writes are performed.
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
from mdp import read_mdp, decode_layer
from cutlib import INK, ink_rgba
from level_images import image_path

ROOT = Path(__file__).resolve().parents[3]
PROCESSION = {
    '80': 'avatar', '99': 'haul_sledge', '100': 'haul_hauler',
    '101': 'haul_driver', '102': 'haul_whip', '135': 'ox',
    '98': 'emb_e1', '97': 'emb_e2', '96': 'emb_e3', '95': 'emb_e4',
    '94': 'emb_e5', '93': 'emb_e6', '92': 'emb_e7', '91': 'emb_e8',
    '144': 'plumed_ox', '164': 'plumes', '145': 'calf',
    '78': 'goose', '79': 'clothes', '112': 'mouth_adze',
    '118': 'mouth_column', '117': 'mouth_spoon', '108': 'water_stream',
    '109': 'water_arm', '155': 'mouth_mummy', '175': 'mouth_features',
    '111': 'mouth_words', '159': 'kneeler', '104': 'stand',
    '105': 'lotus', '106': 'sun',
    '73': 't01', '62': 't02', '74': 't03', '76': 't04', '75': 't05',
    '61': 't06', '53': 't07', '54': 't08', '68': 't09', '58': 't10',
    '56': 't11', '59': 't12', '57': 't13', '72': 't14', '69': 't15',
    '64': 't16', '60': 't17', '65': 't18', '55': 't19', '70': 't20',
    '71': 't21', '52': 't22', '67': 't23', '66': 't24', '51': 't25',
}
DANGERS = {
    '1111': 'breath_giver',
    '1036': 'c31a', '1037': 'c31b', '1038': 'c31c', '1039': 'c31d',
    '1043': 'c32a', '1044': 'c32b', '1045': 'c32c', '1046': 'c32d',
    '1035': 'spear31', '1041': 'spear32', '1061': 'spear33',
    '1066': 'spear35', '1088': 'spear36', '1085': 'spear37',
    '1051': 'spear39', '1092': 'spear40', '1048': 'spear41',
    '1062': 'snake33', '1067': 'snake35', '1089': 'beetle36',
    '1086': 'snake37', '1130': 'glyph37_left', '1131': 'glyph37_right',
    '1071': 'sail38', '1068': 'ankh38', '1146': 'glyph38_breath', '1052': 'apep',
    '1093': 'snake40', '1028': 'donkey40', '1140': 'tail40', '1049': 'snake41',
    '1097': 'heka_e31_hekat', '1100': 'heka_e32_hekat',
    '1134': 'sheaf41_stalks', '1138': 'sheaf41_band1',
    '1137': 'sheaf41_band2', '1136': 'sheaf41_band3', '1135': 'sheaf41_band4',
}


def rect(a, x=0, y=0):
    yy, xx = np.nonzero(a > 0)
    if not len(xx):
        return None
    return dict(x=int(xx.min()) + x, y=int(yy.min()) + y,
                w=int(xx.max() - xx.min() + 1), h=int(yy.max() - yy.min() + 1))


def union(a, b):
    x, y = min(a['x'], b['x']), min(a['y'], b['y'])
    return dict(x=x, y=y, w=max(a['x']+a['w'], b['x']+b['w'])-x,
                h=max(a['y']+a['h'], b['y']+b['h'])-y)


def stamp(dst, a, r):
    dst[r['y']:r['y']+r['h'], r['x']:r['x']+r['w']] = np.maximum(
        dst[r['y']:r['y']+r['h'], r['x']:r['x']+r['w']], a)


def write_sprite(out, name, a, r, old=None, filled=False):
    tight = rect(a)
    if tight is None:
        raise ValueError(f'Empty sprite: {name}')
    a = a[tight['y']:tight['y']+tight['h'], tight['x']:tight['x']+tight['w']]
    r = dict(x=r['x']+tight['x'], y=r['y']+tight['y'], w=tight['w'], h=tight['h'])
    box = union(r, old) if old else r.copy()
    crop = np.zeros((box['h'], box['w']), np.uint8)
    x, y = r['x']-box['x'], r['y']-box['y']
    crop[y:y+r['h'], x:x+r['w']] = a
    if filled:
        from extract_procession300 import filled_rgba
        image = filled_rgba(crop)
    else:
        image = ink_rgba(crop)
    image.save(image_path(out, f'{name}'))
    return box


def new_asset(layer_name, lid, taken):
    """The asset of a layer the saved level has not seen: its name as a file name (the layer id too, if that is taken)."""
    stem = re.sub(r'[^a-z0-9]+', '_', layer_name.lower()).strip('_') or 'layer'
    asset = f'figures/{stem}.png'
    return asset if asset not in taken else f'figures/{stem}_{lid}.png'


def property_set(block, name, value):
    pattern = rf'^{re.escape(name)} = .*?$'
    line = f'{name} = {value}'
    if re.search(pattern, block, re.M):
        return re.sub(pattern, lambda _: line, block, flags=re.M)
    return block.rstrip() + '\n' + line + '\n\n'


def refresh_scene(scene, level, entries, changes):
    text = scene.read_text()
    resources = dict(re.findall(r'\[ext_resource[^\n]*path="res://assets/'+level+r'/figures/([^"/]+)\.png"[^\n]*id="([^"]+)"', text))
    # Keep existing scene transforms and pivots; compensate only for expanded crops.
    for name, (old, new) in changes.items():
        if all(old[k] == new[k] for k in ('x', 'y', 'w', 'h')) or name not in resources:
            continue
        resource = resources[name]
        def adjust(match):
            block = match.group()
            if f'texture = ExtResource("{resource}")' not in block:
                return block
            centered = 'centered = false' not in block
            found = re.search(r'^offset = Vector2\(([^,]+), ([^)]+)\)', block, re.M)
            x, y = map(float, found.groups()) if found else (0.0, 0.0)
            x += new['x']-old['x'] + ((new['w']-old['w'])/2 if centered else 0)
            y += new['y']-old['y'] + ((new['h']-old['h'])/2 if centered else 0)
            return property_set(block, 'offset', f'Vector2({x:g}, {y:g})')
        text = re.sub(r'\[node [^\n]*\]\n.*?(?=\[node |\Z)', adjust, text, flags=re.S)
    if level == 'dangers':
        def bearer_bounds(match):
            block = match.group()
            found = re.search(r'metadata/actor_id = "(spear[^"]+)"', block)
            if not found:
                return block
            name = found[1].removesuffix('_pole')
            if name not in changes:
                return block
            old, new = changes[name]
            if old == new:
                return block
            found = re.search(r'^position = Vector2\(([^,]+), ([^)]+)\)', block, re.M)
            x, y = map(float, found.groups())
            x += new['x']+new['w']/2-old['x']-old['w']/2
            y += new['y']+new['h']-old['y']-old['h']
            block = property_set(block, 'position', f'Vector2({x:g}, {y:g})')
            return property_set(block, 'metadata/size', f"Vector2({new['w']}, {new['h']})")
        text = re.sub(r'\[node [^\n]*\]\n.*?(?=\[node |\Z)', bearer_bounds, text, flags=re.S)
    inspection_ids = {}
    for block in re.findall(r'\[node [^\n]*\]\n.*?(?=\[node |\Z)', text, re.S):
        source = re.search(r'metadata/source_layer_id = "([^"]+)"', block)
        registry = re.search(r'metadata/registry_id = "([^"]+)"', block)
        if source and registry:
            inspection_ids[source[1]] = registry[1]
    # Replace only this exporter's static layer group, making repeated exports safe.
    if level == 'procession' and '[node name="Hitboxes"' in text:
        # The hand-edited boxes (under Hitboxes) were drawn for these sprites; update their images without rebuilding nodes.
        scene.write_text(text)
        return
    text = re.sub(r'\[ext_resource[^\n]*id="layer_[^"]+"\]\n', '', text)
    text = re.sub(r'\[node name="Figures"[^\n]*\]\n.*?(?=\[node [^\n]*parent="\."|\Z)', '', text, flags=re.S)
    ext, nodes = [], ['[node name="Figures" type="Node2D" parent="."]\n']
    for e in entries:
        if not e['static']:
            continue
        rid, r = f"layer_{e['layer_id']}", e['rect']
        ext.append(f'[ext_resource type="Texture2D" path="res://assets/{level}/{e["asset"]}" id="{rid}"]\n')
        # the node is named by its registry ID; a layer without one by its layer name (no layer number)
        name = inspection_ids.get(e['layer_id']) or re.sub(r'[^A-Za-z0-9_]+', '_', e['name']).strip('_')
        nodes.append(f'[node name="{name}" type="Sprite2D" parent="Figures"]\n'
                     f'position = Vector2({r["x"]}, {r["y"]})\ntexture = ExtResource("{rid}")\n'
                     f'centered = false\nmetadata/source_layer_id = "{e["layer_id"]}"\n' + (f'metadata/registry_id = "{inspection_ids[e["layer_id"]]}"\n' if e["layer_id"] in inspection_ids else ""))
    index = text.index('[sub_resource')
    text = text[:index] + ''.join(ext) + '\n' + text[index:]
    index = text.index('[node name="Pieces"')
    text = text[:index] + '\n'.join(nodes) + '\n' + text[index:]
    scene.write_text(text)


def export(level):
    filename = 'procession1-15.mdp' if level == 'procession' else 'dangers31-42.mdp'
    source = ROOT / 'art' / filename
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    out = ROOT / 'godot/assets' / level
    scene = ROOT / 'godot/scenes' / f'{level}.tscn'
    data = json.loads((out/'level.json').read_text())
    figure_assets = {e['layer_id']: e['asset'] for e in json.loads((out/'layers.json').read_text())['layers']}
    taken = set(figure_assets.values())     # asset names in use; a layer new to the drawing gets a free one
    old_sprites = {k: v.copy() for k, v in data['sprites'].items()}
    mapping = PROCESSION if level == 'procession' else DANGERS
    w, h, layers, chunks, _ = read_mdp(source)
    byid = {l['id']: l for l in layers}
    background = np.zeros((h, w), np.uint8)
    artwork = np.zeros_like(background)
    entries, changes = [], {}
    (out/'figures').mkdir(exist_ok=True)
    for layer in layers:
        if layer['type'] != '32bpp' or layer['bin'] not in chunks:
            continue
        parent = byid.get(layer.get('parentId'), {}).get('name', '')
        if layer['name'] == 'bg' or layer.get('clipping') == 'true':
            continue
        image = decode_layer(chunks[layer['bin']], int(layer['width']), int(layer['height']), '32bpp')
        # BGRA darkness removes opaque white from lassoed cutouts.
        alpha = np.rint((255-image[..., :3].mean(axis=2))*image[..., 3]/255).astype(np.uint8)
        ox, oy = int(layer['ofsx']), int(layer['ofsy'])
        x0, y0 = max(0, ox), max(0, oy)
        x1, y1 = min(w, ox+alpha.shape[1]), min(h, oy+alpha.shape[0])
        alpha = alpha[y0-oy:y1-oy, x0-ox:x1-ox].copy()
        if parent == 'guidelines':
            # The clipping layers recolor these guides black in the drawing.
            alpha = image[y0-oy:y1-oy, x0-ox:x1-ox, 3].copy()
        del image
        alpha[alpha <= 8] = 0
        r = rect(alpha, x0, y0)
        if not r:
            continue
        a = alpha[r['y']-y0:r['y']-y0+r['h'], r['x']-x0:r['x']-x0+r['w']].copy()
        del alpha
        is_background = parent in ('guidelines', 'text_below', 'captions') or layer['name'] in ('toptext', 'croctexts')
        if is_background:
            if layer.get('visible') == 'true':
                stamp(background, a, r)
            continue
        lid = layer['id']
        name = mapping.get(lid)
        # These layers have specialized live representations (body/arm split and wrong plumes).
        special = level == 'procession' and lid in ('115', '163')
        asset = f'figures/{name}.png' if name else figure_assets.get(lid) or new_asset(layer['name'], lid, taken)
        taken.add(asset)
        static = name is None and not special
        if name:
            old = old_sprites.get(name) or data.get('table', {}).get('pieces', {}).get(name)
            # Sheet bearers are exported too; their hand-edited animation sheets are left as they are.
            box = write_sprite(out, name, a, r, old, filled=level=='procession' and (name.startswith('t') and name[1:].isdigit() or name=='goose'))
            if name in old_sprites:
                data['sprites'][name] = box
            if old:
                changes[name] = (old, box)
        else:
            box = write_sprite(out/'figures', Path(asset).stem, a, r)
        entries.append(dict(layer_id=lid, name=layer['name'], folder=parent,
                            asset=asset, rect=box, static=static))
        if static:
            stamp(artwork, a, r)
    if level == 'procession':
        # The body/arm sprites (haul_driver_*, water_priest_*) are made once by make-artwork's sheets.py
        # (procession --parts) and left as they are here.
        # Journal/region glows still use a flat reference of the static figures.
        ink_rgba(np.maximum(background,artwork)).save(image_path(out, 'illustration'))
    # bundle41 (the union of spell 41's hand-separated bands and stalks) was made once and is left as it is.
    ink_rgba(background).save(image_path(out, 'strip'))
    (out/'layers.json').write_text(json.dumps(dict(source=f'art/{filename}', sha256=digest,
        width=w,height=h,layers=entries),indent=1)+'\n')
    (out/'level.json').write_text(json.dumps(data,indent=1)+'\n')
    if level == 'dangers':
        for name in list(data['sprites']):
            if name.endswith('_pole') and name.removesuffix('_pole') in data['sprites']:
                data['sprites'][name] = data['sprites'][name.removesuffix('_pole')].copy()
        (out/'level.json').write_text(json.dumps(data,indent=1)+'\n')
    refresh_scene(scene,level,entries,changes)
    assert hashlib.sha256(source.read_bytes()).hexdigest()==digest, 'Source MDP changed'
    print(f'{level}: exported {len(entries)} layers, {sum(e["static"] for e in entries)} new static scene sprites', flush=True)


if __name__=='__main__':
    for name in sys.argv[1:] or ['procession','dangers']:
        if name not in ('procession','dangers'):
            raise SystemExit('Expected procession or dangers')
        export(name)
