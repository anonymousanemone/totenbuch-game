"""Export the "Dangers on the road" level (spells 31-42) from the hand-made 300-dpi strip bod31-42.mdp.

Nothing is redrawn and the .mdp is only read. The layers are in one folder per vignette (crocs31,
crocs32, snake33, ...); every character has its own layer. This script names them for the game,
writes each as a sprite, and writes everything else (plate panels, captions, the text below, the
black frame `blacklines`) as strip.png. The coloured `guidelines` folder is left out, and so is any
layer hidden on its own (a hidden folder is taken as hidden only while working: its layers count).
The characters are taken whether shown or not.

Two characters are still part of a larger layer and are copied out with a rectangle (see
FROM_LAYER): the donkey of spell 40 (in `ass`, with the caption; its tail is its own layer
`snakeass40/tail`, cut as tail40) and the sheaf of spell 41 (now drawn only in its pieces, the
`sheaf41` folder, which together are bundle41; before, in p19). The spear-bearers are taken out of the strip but not written: their sprites and spear tips
stay as they are in level.json, since .claude/skills/make-artwork/spearers.py lays out its sheet from them. The player
figure is the adoring deceased of spell 30 (plate XVI), cut from the 300-dpi plate (art/og_300dpi),
since that panel is not on this strip.

Usage (always partial: only what is named is cut, into the level already there; the strip, the
other sprites and the rest of level.json are left as they are):
    python .claude/skills/build-levels/extract_dangers300.py art/dangers31-42.mdp godot/assets/dangers NAME [NAME ...]
        NAME: a sprite of FROM_LAYERS (ankh38, sail38, snake33, ...), `tail40` (spell 40's donkey
        and its tail, cut apart; also `donkey40`) or `sheaf41` (spell 41's sheaf pieces)
The whole level (strip, every sprite, level.json written anew) only when asked for:
    python .claude/skills/build-levels/extract_dangers300.py --all art/dangers31-42.mdp art/og_300dpi godot/assets/dangers
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from level_images import image_path  # noqa: E402
from mdp import read_mdp, decode_layer  # noqa: E402
from cutlib import ink_rgba  # noqa: E402

SCALE = 1.5          # 300 dpi strip px per 200 dpi plate px
GROUND = 526         # figures stand on the inner bottom line
TEXT_SHOW = 120      # rows of the text below the frame the game camera keeps in view

# game sprite name -> layer path in the .mdp ("folder/layer"); several layers make one sprite
FROM_LAYERS = {
    # 31: four crocodiles in two lanes, a = top left, b = bottom left, c = top right, d = bottom right
    "c31a": ["crocs31/croc1a"], "c31b": ["crocs31/croc1b"], "c31c": ["crocs31/croc1c"], "c31d": ["crocs31/croc1d"],
    "spear31": ["crocs31/spearer1"],
    # 32
    "c32a": ["crocs32/croc2a"], "c32b": ["crocs32/croc2b"], "c32c": ["crocs32/croc2c"], "c32d": ["crocs32/croc2d"],
    "spear32": ["crocs32/spearer2"],
    # 33: the lunging snake
    "snake33": ["snake33/snake1"], "spear33": ["snake33/spearer1"],
    # 35: snake on the ground
    "snake35": ["snake35/snake2"], "spear35": ["snake35/spearer2"],
    # 36: the roach (beetle)
    "beetle36": ["roach36/roach"], "spear36": ["roach36/spearer"],
    # 37: the two Merti snakes, and the two snake signs of its caption (they flash red in the fight)
    "snake37": ["snake37/snake3"], "spear37": ["snake37/spearer3"],
    "glyph37_left": ["snake37/left snake glyph"], "glyph37_right": ["snake37/right snake glyph"],
    # 38: the ankh (life) and the sail (breath) he holds out, each a sprite of its own
    "ankh38": ["breath38/ankh"], "sail38": ["breath38/breath"],
    # and the breath sign of its caption (it flashes red until a sign is taken)
    "glyph38_breath": ["breath38/breath_text"],
    # 39: Apep
    "apep": ["snake39/snake4"], "spear39": ["snake39/spearer4"],
    # 40: the snake on the donkey
    "snake40": ["snakeass40/ass snake"], "spear40": ["snakeass40/spearer"],
    # 41: the snake coiled on the sheaf
    "snake41": ["snake41/snake5"], "spear41": ["snake41/spearer5"],
}
# characters still inside a larger layer: (layer, rectangle x0, y0, x1, y1 in canvas px)
FROM_LAYER = {
    "donkey40": ("snakeass40/ass", (850, 290, 1270, 560)),
    "bundle41": ("snake41/p19", (180, 420, 330, 545)),
}
# Spell 41's sheaf, in pieces for the fight: its stalks and its four bands (top to bottom), as the
# layers `stalks`, `band1`..`band4` of a `sheaf41` folder when the .mdp has one; else split from
# the bundle: long horizontal strokes are the bands, upright ones the stalks, and every other bit
# of ink goes to the stroke nearest it (the stalks keep the crossings, so they are whole without
# the bands). Sprites sheaf41_stalks, sheaf41_band1..4; the whole bundle stays as bundle41.
# Spell 40's donkey swishes its tail: the tuft that hangs below the line the donkey lies on is cut
# from donkey40 as its own sprite, tail40: the layer TAIL_LAYER, drawn on its own beside `ass` (not in
# it), when the .mdp has it; else the layer `tail` of a `tail40` folder (a copy of the tail in `ass`);
# else canvas rows from TAIL_ROW and columns from TAIL_X.
TAIL_LAYER = "snakeass40/tail"
TAIL_FOLDER = "tail40"
TAIL_ROW = 531
TAIL_X = 1190
SHEAF_FOLDER = "sheaf41"
SHEAF_PIECES = ["stalks", "band1", "band2", "band3", "band4"]
SHEAF_FROM = "bundle41"
HEKA_FOLDER = "heka"    # caption signs on their own layers (in this folder, or named HEKA_LAYERS)
HEKA_LAYERS = ("hekat", "heka")   # flash red in the croc fights; clicking one gives the hold-H hint.
                        # A layer is split by vignette: each fight has only its own signs.
AVATAR_PLATE = (16, (2677, 360, 2802, 635))   # page_0016 = pl. XVI, the adoring deceased of spell 30
FRAME_LAYER = "/blacklines"                    # the frame in black (the guides are only a guide)


def load(path):
    W, H, L, C, _ = read_mdp(path)
    byid = {l["id"]: l for l in L}

    def shown(l):
        """Not hidden on its own (a folder's eye is only for working)."""
        return l["visible"] == "true"

    def ink(l):
        """Layer darkness 0..255, cropped to the canvas."""
        img = decode_layer(C[l["bin"]], int(l["width"]), int(l["height"]), "32bpp")[..., [2, 1, 0, 3]].astype(np.float32)
        d = (255 - img[..., :3].mean(-1)) * img[..., 3] / 255
        out = np.zeros((H, W), np.float32)
        ox, oy = int(l["ofsx"]), int(l["ofsy"])
        x0, y0, x1, y1 = max(0, ox), max(0, oy), min(W, ox + d.shape[1]), min(H, oy + d.shape[0])
        out[y0:y1, x0:x1] = d[y0 - oy:y1 - oy, x0 - ox:x1 - ox]
        return out

    layers = {}
    hidden = set()      # layers hidden on their own: characters may come from them, the strip does not
    guides = np.zeros((H, W), np.float32)
    for l in L:
        if l["type"] == "folder":
            continue
        folder = byid[l["parentId"]]["name"] if l["parentId"] != "-1" else ""
        if folder == "guidelines":
            if l["name"] in ("horizont", "vertical", "textline"):
                guides = np.maximum(guides, (ink(l) > 0) * 255.0)   # the guides as ink, if no black frame
            continue
        if l["name"] == "bg":
            continue
        a = ink(l)
        key = f"{folder}/{l['name']}"
        # the black frame is the frame whether or not it is shown while drawing
        if not shown(l) and key != FRAME_LAYER:
            hidden.add(key)
        if key in layers:   # two layers with the same name in one folder: tell them apart by x
            xs = np.nonzero(a.any(0))[0]
            key += f"@{xs.min()}"
            first = layers.pop(f"{folder}/{l['name']}")
            fx = np.nonzero(first.any(0))[0]
            layers[f"{folder}/{l['name']}@{fx.min()}"] = first
        layers[key] = a
    if FRAME_LAYER not in layers:
        layers[FRAME_LAYER] = guides
    return W, H, layers, hidden


def split_sheaf(a):
    """The bundle `a` (canvas-sized darkness) as {"stalks": ..., "band1".. "band4": ...}, top band first."""
    from scipy import ndimage as ndi
    on = a > 60
    horiz = ndi.binary_opening(on, structure=np.ones((1, 21)))
    vert = ndi.binary_opening(on, structure=np.ones((7, 1))) & ~horiz
    blab, n = ndi.label(ndi.binary_dilation(horiz, np.ones((3, 3))) & on, np.ones((3, 3)))
    if n != 4:
        raise SystemExit(f"sheaf41: found {n} bands, not 4")
    core = np.where(horiz, blab, 0)
    core[vert] = n + 1
    _, (iy, ix) = ndi.distance_transform_edt(core == 0, return_indices=True)
    owner = np.where(a > 0, core[iy, ix], 0)
    cross = (a > 0) & ndi.binary_dilation(vert, np.ones((13, 3)))    # across a band's full thickness
    pieces = {"stalks": np.where((owner == n + 1) | cross, a, 0)}
    for k, i in enumerate(sorted(range(1, n + 1), key=lambda i: np.nonzero(owner == i)[0].mean())):
        pieces[f"band{k + 1}"] = np.where(owner == i, a, 0)
    return pieces


def split_tail(donkey, layers):
    """The donkey (canvas-sized darkness) without its tail, and the tail."""
    key = f"{TAIL_FOLDER}/tail"
    if TAIL_LAYER in layers:
        tail = layers[TAIL_LAYER]
        print(f"tail40: from the .mdp layer `{TAIL_LAYER}`")
    elif key in layers:
        tail = layers[key]
        print(f"tail40: from the .mdp folder `{TAIL_FOLDER}`")
    else:
        tail = np.zeros_like(donkey)
        tail[TAIL_ROW:, TAIL_X:] = donkey[TAIL_ROW:, TAIL_X:]
        print(f"tail40: cut below the donkey's line (no `{TAIL_FOLDER}` folder yet)")
    return np.where(tail > 0, 0, donkey), tail


def cut_sprite(a, name, out):
    """Write sprite `name` from canvas-sized darkness `a`, cropped to its ink (without a bit of the
    double line caught along its left or right edge); its rect."""
    ys, xs = np.nonzero(a > 8)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    crop = np.clip(a[y0:y1, x0:x1], 0, 255).astype(np.uint8)
    # a full-height line along the left or right edge is a bit of the double line caught in
    # the layer, not part of the figure
    while crop.shape[1] > 2 and ((crop[:, -1] > 90).mean() > 0.9 or not crop[:, -1].any()):
        crop = crop[:, :-1]
        x1 -= 1
    while crop.shape[1] > 2 and ((crop[:, 0] > 90).mean() > 0.9 or not crop[:, 0].any()):
        crop = crop[:, 1:]
        x0 += 1
    ink_rgba(crop).save(image_path(out, f"{name}"))
    return {"x": int(x0), "y": int(y0), "w": int(x1 - x0), "h": int(y1 - y0)}


def write_sprite(a, name, out):
    ys, xs = np.nonzero(a > 8)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    ink_rgba(np.clip(a[y0:y1, x0:x1], 0, 255).astype(np.uint8)).save(image_path(out, f"{name}"))
    return {"x": int(x0), "y": int(y0), "w": int(x1 - x0), "h": int(y1 - y0)}


def patch_tail(mdp_path, out_dir):
    """Write only spell 40's donkey and its tail (cut apart) into the level already in out_dir."""
    out = Path(out_dir)
    W, H, layers, _ = load(mdp_path)
    k, (x0, y0, x1, y1) = FROM_LAYER["donkey40"]
    donkey = np.zeros((H, W), np.float32)
    donkey[y0:y1, x0:x1] = layers[k][y0:y1, x0:x1]
    rest, tail = split_tail(donkey, layers)
    level = json.loads((out / "level.json").read_text())
    level["sprites"]["donkey40"] = write_sprite(rest, "donkey40", out)
    level["sprites"]["tail40"] = write_sprite(tail, "tail40", out)
    (out / "level.json").write_text(json.dumps(level, indent=1))
    print("patched: donkey40, tail40")


def sheaf_sprites(layers, bundle, out):
    """Write spell 41's sheaf pieces (from the `sheaf41` folder, else split from `bundle`); {name: rect}."""
    keys = {nm: f"{SHEAF_FOLDER}/{nm}" for nm in SHEAF_PIECES}
    if all(k in layers for k in keys.values()):
        pieces = {nm: layers[k] for nm, k in keys.items()}
        print(f"sheaf41: from the .mdp folder `{SHEAF_FOLDER}`")
    else:
        pieces = split_sheaf(bundle)
        print(f"sheaf41: split from the bundle (no `{SHEAF_FOLDER}` folder yet)")
    rects = {}
    for nm, a in pieces.items():
        ys, xs = np.nonzero(a > 8)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        ink_rgba(np.clip(a[y0:y1, x0:x1], 0, 255).astype(np.uint8)).save(image_path(out, f"sheaf41_{nm}"))
        rects[f"sheaf41_{nm}"] = {"x": int(x0), "y": int(y0), "w": int(x1 - x0), "h": int(y1 - y0)}
    return rects


def patch_sheaf(mdp_path, out_dir):
    """Write only spell 41's sheaf pieces into the level already in out_dir (and name its snake
    snake41: it was cut as `heads41`)."""
    out = Path(out_dir)
    W, H, layers, _ = load(mdp_path)
    bundle = None       # only needed to split the sheaf when it is not drawn in its pieces
    if not all(f"{SHEAF_FOLDER}/{nm}" in layers for nm in SHEAF_PIECES):
        k, (x0, y0, x1, y1) = FROM_LAYER[SHEAF_FROM]
        bundle = np.zeros((H, W), np.float32)
        bundle[y0:y1, x0:x1] = layers[k][y0:y1, x0:x1]
    level = json.loads((out / "level.json").read_text())
    level["sprites"].update(sheaf_sprites(layers, bundle, out))
    if "heads41" in level["sprites"]:
        level["sprites"]["snake41"] = level["sprites"].pop("heads41")
        (image_path(out, "heads41")).rename(image_path(out, "snake41"))
        stale = image_path(out, "heads41").with_suffix(".png.import")
        if stale.exists():
            stale.unlink()
    (out / "level.json").write_text(json.dumps(level, indent=1))
    print("patched: sheaf41 pieces")


def resolve(layers, key):
    """'folder/name@x' picks, among same-named layers, the one whose ink starts nearest x."""
    if "@" not in key:
        return key
    base, x = key.split("@")
    same = [k for k in layers if k.split("@")[0] == base]
    return min(same, key=lambda k: abs(int(np.nonzero(layers[k].any(0))[0].min()) - int(x)))


def main(mdp_path, plates_dir, out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    W, H, layers, hidden = load(mdp_path)
    used = set(hidden)
    sprites, alphas = {}, {}
    for name, keys in FROM_LAYERS.items():
        a = np.zeros((H, W), np.float32)
        for k in keys:
            k = resolve(layers, k)
            a = np.maximum(a, layers[k]); used.add(k)
        alphas[name] = a
    heka_keys = [k for k in layers if k.split("/")[0] == HEKA_FOLDER or k.split("/")[-1].split("@")[0] in HEKA_LAYERS]
    used.update(heka_keys)
    # the red `spear` clipping layers are masks for .claude/skills/make-artwork/spearers.py, not ink
    used.update(k for k in layers if k.split("/")[-1].split("@")[0] == "spear")
    # the folders that hold pieces cut apart for a fight copy ink that is in the drawing already
    used.update(k for k in layers if k.split("/")[0] in (SHEAF_FOLDER, TAIL_FOLDER))
    used.add(TAIL_LAYER)       # the tail is a sprite of its own
    cut = {k: v.copy() for k, v in layers.items()}
    for name, (k, (x0, y0, x1, y1)) in FROM_LAYER.items():
        if k not in cut:     # (drawn in pieces of its own now: see below)
            continue
        a = np.zeros((H, W), np.float32)
        a[y0:y1, x0:x1] = cut[k][y0:y1, x0:x1]
        cut[k][y0:y1, x0:x1] = 0
        alphas[name] = a
    sheaf = [a for k, a in layers.items() if k.split("/")[0] == SHEAF_FOLDER]
    if sheaf:   # the sheaf is drawn in its pieces (not in p19): the bundle is the pieces together
        alphas[SHEAF_FROM] = np.maximum.reduce(sheaf)
    sprites.update(sheaf_sprites(layers, alphas[SHEAF_FROM], out))
    alphas["donkey40"], alphas["tail40"] = split_tail(alphas["donkey40"], layers)
    # the spear-bearers stay as they are (see the docstring)
    kept = json.loads((out / "level.json").read_text())
    spears = kept["spears"]
    sprites.update({n: r for n, r in kept["sprites"].items() if n.startswith("spear")})
    for name, a in alphas.items():
        if not name.startswith("spear"):
            sprites[name] = cut_sprite(a, name, out)

    strip = np.zeros((H, W), np.float32)
    for k, a in cut.items():
        if k not in used:
            strip = np.maximum(strip, a)
    strip[strip < 12] = 0   # faint resampling haze
    ink_rgba(np.clip(strip, 0, 255).astype(np.uint8)).save(image_path(out, "strip"), optimize=True)

    # the player: the adoring deceased of spell 30, from the plate at 300 dpi
    pg, (ax0, ay0, ax1, ay1) = AVATAR_PLATE
    P = np.array(Image.open(f"{plates_dir}/page_{pg:04d}.png").convert("L")).astype(np.float32)
    av = (255 - P[ay0:ay1, ax0:ax1]) / 255          # darkness as ink
    ys, xs = np.nonzero(av > 0.05)
    av = av[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    ink_rgba(np.clip(av * 255, 0, 255).astype(np.uint8)).save(image_path(out, "avatar"))
    sprites["avatar"] = {"x": W - 30 - 40 - av.shape[1], "y": GROUND - av.shape[0], "w": av.shape[1], "h": av.shape[0]}

    # vignette boxes: each frame panel, named after the spell of the sprite inside it
    frame = layers[FRAME_LAYER]
    band = frame[200:500] > 128
    on = band.mean(0) > 0.6
    runs, s = [], None
    for x in range(W + 1):
        v = x < W and on[x]
        if v and s is None:
            s = x
        if not v and s is not None:
            runs.append((s, x - 1)); s = None
    gaps = [(a[1] + 1, b[0]) for a, b in zip(runs, runs[1:]) if b[0] - a[1] > 60]
    boxes = {}
    for name, r in sprites.items():
        if name == "avatar" or name.startswith("heka_") or not name[-2:].isdigit():
            continue
        cx = r["x"] + r["w"] / 2
        for g in gaps:
            if g[0] <= cx < g[1]:
                boxes[f"e{name[-2:]}"] = [int(g[0]), int(g[1])]
    top = int(np.argmax((frame[:, :W // 2] > 128).mean(1) > 0.6))     # the frame's top line
    # the ruled lines round the picture band: the line under the captions and the double line below
    rows = (frame[:, :W // 2] > 128).mean(1) > 0.6
    rules, s0 = [], None
    for y in range(H + 1):
        v = y < H and rows[y]
        if v and s0 is None:
            s0 = y
        if not v and s0 is not None:
            rules.append([s0, y]); s0 = None
    caption = [max(r[1] for r in rules if r[0] < 100), min(r[0] for r in rules if 100 < r[0] < GROUND)]
    rules = [r for r in rules if 100 < r[0] < GROUND + 40]
    # the heka signs, one sprite per vignette they stand in
    heka = {}
    for k in heka_keys:
        slug = "".join(ch if ch.isalnum() else "_" for ch in k.split("/")[-1])
        for eid, (g0, g1) in boxes.items():
            part = np.zeros_like(layers[k])
            part[:, g0:g1] = layers[k][:, g0:g1]
            ys, xs = np.nonzero(part > 8)
            if not len(xs):
                continue
            name = f"heka_{eid}_{slug}"
            x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
            ink_rgba(np.clip(part[y0:y1, x0:x1], 0, 255).astype(np.uint8)).save(image_path(out, f"{name}"))
            sprites[name] = {"x": int(x0), "y": int(y0), "w": int(x1 - x0), "h": int(y1 - y0)}
            heka.setdefault(eid, []).append(name)
    level = {"width": W, "height": H, "scale": SCALE, "ground": GROUND, "frame_top": top, "rules": rules, "caption": caption, "spears": spears, "heka": heka,
             "view_height": GROUND + 20 + TEXT_SHOW, "plates": {}, "sprites": sprites,
             "boxes": dict(sorted(boxes.items()))}
    (out / "level.json").write_text(json.dumps(level, indent=1))
    print(f"strip {W}x{H}, {len(sprites)} sprites, boxes {level['boxes']}")


def cut_only(mdp_path, out_dir, names):
    """Cut only the sprites `names` into the level already in out_dir: their pictures and their
    rects in level.json; nothing else changes."""
    out = Path(out_dir)
    names = list(dict.fromkeys(names))
    unknown = [n for n in names if n not in FROM_LAYERS and n not in ("tail40", "donkey40", "sheaf41")]
    if unknown:
        raise SystemExit(f"not a sprite this cutter knows: {', '.join(unknown)}")
    if "tail40" in names or "donkey40" in names:
        patch_tail(mdp_path, out_dir)
    if "sheaf41" in names:
        patch_sheaf(mdp_path, out_dir)
    plain = [n for n in names if n in FROM_LAYERS]
    if not plain:
        return
    W, H, layers, _ = load(mdp_path)
    level = json.loads((out / "level.json").read_text())
    for name in plain:
        a = np.zeros((H, W), np.float32)
        for k in FROM_LAYERS[name]:
            a = np.maximum(a, layers[resolve(layers, k)])
        level["sprites"][name] = cut_sprite(a, name, out)
    (out / "level.json").write_text(json.dumps(level, indent=1))
    print("cut:", ", ".join(plain))


if __name__ == "__main__":
    if sys.argv[1] == "--all":
        main(*sys.argv[2:5])
    else:
        cut_only(sys.argv[1], sys.argv[2], sys.argv[3:])
