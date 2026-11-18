"""Cut the parts of the funeral-procession level (Spells 1-15, pl. I-VI) that need more than the picture of a layer,
from art/procession1-15.mdp (only read).

The pictures themselves (the strip with the frame, the captions and the text below, and a sprite for every other
layer) come from `.claude/skills/build-levels/export_scene_layers.py procession`, which names layers by their id. What is cut here is what
that does not work out: where things lie and rest, as level.json data beside the sprites. Each mode writes only its
own sprites and its own part of level.json (the strip is not touched):

    python .claude/skills/build-levels/extract_procession300.py --water art/procession1-15.mdp godot/assets/procession
        (the water of plate V, from the layers `man`, `arms` and `stream` of the `water game` folder: the priest's
        arm with the jar and the stream as sprites, the stream's `water_path` (how far along it each pixel lies
        from the spout) and the water's `line` in level.json)
    python .claude/skills/build-levels/extract_procession300.py --table art/procession1-15.mdp godot/assets/procession
        (the offering table, from its `table` folder: its loose pieces cut anew, what each rests on, and the
        level's `table`)
    python .claude/skills/build-levels/extract_procession300.py --features art/procession1-15.mdp godot/assets/procession
        (the mummy's face lines for the Opening of the Mouth, from the layer `features` (in the folder
        FEATURES_FOLDER): mouth_features, and the mummy's body without them, mouth_mummy; what the old face lines
        held and the new do not goes back into the body)
    python .claude/skills/build-levels/extract_procession300.py --bulls art/procession1-15.mdp godot/assets/procession
        (the three bulls of plates III-IV, from the `bulls` folder: the plumed ox without its plumes and the
        plumes, as sprites; where the plumes sit on his head and on the sacrifice)

Run with the project's scientific Python environment. The cut that made the whole level from the old plate redraw
(`bod_300dpi`), with `--patch` and `--mouth`, is gone: that redraw is not in the .mdp any more.

Outputs (ink in INK colour on transparent, world units = strip pixels = .mdp canvas pixels):
    <sprite>.png, level.json
"""
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from level_images import image_path  # noqa: E402
from mdp import read_mdp, decode_layer  # noqa: E402
from cutlib import INK, ink_rgba  # noqa: E402


GROUND = 526                       # top of the bottom frame line: the figures stand on it

# The redraw moves figures relative to the plates, so everything below is measured on the strip
# itself (.mdp canvas pixels). Re-measure if the drawing moves on the canvas.


# Source regions: (plate, (x0, y0, x1, y1), registry ID), in strip pixels.
STRIP_HOTSPOTS = [
    ("I",   (14389, 197, 14694, GROUND), "mourners"),
    ("I",   (13689, 217, 14379, GROUND), "women_mourners"),
    ("I",   (13529, 232, 13674, GROUND), "canopy_frame"),
    ("I",   (13298, 237, 13525, GROUND), "man_hauling_the_canopy"),
    ("I",   (13024, 252, 13284, GROUND), "anubis_on_a_chest"),
    ("I",   (12807, 254, 13020, GROUND), "man_hauling_anubis"),
    ("II",  (11794, 202, 12819, GROUND), "funerary_bier"),   # the whole boat, plates II-I
    ("II",  (11529, 232, 11789, GROUND), "priest_with_censer"),
    ("II",  (11289, 212, 11484, GROUND), "hauler"),
    ("II",  (11099, 202, 11229, GROUND), "ox_driver"),
    ("II",  (10604, 227, 11081, GROUND), "ox"),
    ("III", (7669, 202, 8084, GROUND), "plumed_ox"),
    ("III", (7367, 383, 7599, GROUND), "calf"),
    ("III", (8224, 192, 8429, GROUND), "canopy_bearer"),
    ("III", (8479, 237, 8699, GROUND), "yoke_bearer"),
    ("III", (8754, 237, 8974, GROUND), "two_women"),
    ("IV",  (6654, 262, 7304, GROUND), "sacrifice"),
    ("IV",  (6094, 222, 6264, GROUND), "lector_priest"),
    ("IV",  (5174, 217, 5894, GROUND), "offering_table"),
    ("IV",  (4835, 197, 5005, GROUND), "man_with_a_water_jar"),   # not the bouquets beside him
    ("V",   (3612, 205, 3848, GROUND), "two_obelisks"),
    ("V",   (3950, 312, 4084, GROUND), "offering_stand"),   # its rods, foreleg and adze are the sprites mouth_*
    ("V",   (4109, 248, 4322, GROUND), "priest_with_arm_censer"),
    ("V",   (4523, 191, 4688, GROUND), "lector_with_plumes"),
    ("V",   (2255, 195, 2420, GROUND), "priest_with_jar"),
    ("V",   (2115, 315, 2250, GROUND), "kneeling_woman"),
    ("V",   (1765, 200, 1990, 495), "anubis_and_the_mummy"),
    ("VI",  (1501, 191, 1760, GROUND), "stela"),
    ("VI",  (1120, 195, 1428, GROUND), "tomb_chapel"),
    ("VI",  (120, 186, 475, GROUND), "ra_enthroned"),
]


# The offering table of plate IV, which has collapsed. Its loose pieces are the layers of the
# `table` folder in the .mdp, one offering per layer. The layer TABLE_BASE in that folder (the
# table and what stays standing on it) stays in the picture. The palm frond is a layer named with
# "frond" or "palm", else the widest piece; the loaf the goose-bearer holds instead of his goose
# is a layer named with "held", else TABLE_HELD. Layers may share a name.
TABLE_FOLDER = "table"
TABLE_BASE = "table"
TABLE_HELD = "t line"                # the first of the long loaves with a line along it
FILL = (231, 214, 174)               # papyrus: inside its outline each loose piece is ...
FILL_ALPHA = 0.5                     # ... this opaque, so pieces lying on each other read apart
# Pouring the water (plate V): the priest's forearm with the hand and the jar, which turns about
# the elbow, and the wavy stream that runs from the jar over Anubis and the mummy to their base.
# From the layers `arms` and `stream` of the `water game` folder. `path` is written beside the
# stream: how far along it each pixel lies from the spout (1..255).
WATER_FOLDER = "water game"
WATER = {
    "elbow": (2297, 318),             # the arm turns about this
    "spout": (2224, 204),             # the stream leaves the jar here (as drawn)
    "hands": (2140, 330),             # the woman's raised hands: a gush falls short onto them
    "view": (1690, 2470),             # the scene: from the stela's edge to the priest's back
    "stand": 2470,                    # where you stand in it, behind the priest
}
LINE_POINTS = 64                      # points along the stream written as the water's `line`
TABLE = {
    "box": (5172, 186, 5884, 498),   # the heap, above the table top
    "floor": (5140, 5895),           # between the two pairs of bouquets: fallen pieces stay here
    "frond_shift": 633,              # the fallen frond lies this far right of its place ...
    "frond_bottom": 172,             # ... in the empty band above the picture, resting on this row
    "speech": (5905, 192, 6085, 300),  # in front of the lector beside the table, above the bouquets
    "view": (4835, 6565),            # the table scene: from the man with the jar to the goose-bearer
    "stand": 6335,                   # where you stand in it, just behind the lector
    "header": (50, 178),             # the empty band above the picture: pieces can be laid here
}
SUPPORT_GAP = 8                      # a piece rests on what lies within this many rows below it


def filled_rgba(alpha):
    """Ink over a faint papyrus fill of everything inside the piece's outline."""
    on = alpha > 60
    inside = ndi.binary_fill_holes(ndi.binary_closing(on, iterations=2)) & ~on
    a = alpha.astype(np.float32) / 255
    f = np.where(inside, FILL_ALPHA, 0.0) * (1 - a)
    total = a + f
    out = np.zeros(alpha.shape + (4,), np.float32)
    for c in range(3):
        out[..., c] = np.where(total > 0, (INK[c] * a + FILL[c] * f) / np.maximum(total, 1e-6), 0)
    out[..., 3] = total * 255
    return Image.fromarray(np.round(out).astype(np.uint8), "RGBA")


def load_mdp(path):
    """The .mdp's layers as darkness 0..255 on the canvas: {"folder/layer": array}, and (W, H)."""
    W, H, L, C, _ = read_mdp(path)
    byid = {l["id"]: l for l in L}
    out = {}
    for l in L:
        if l["type"] != "32bpp" or l["bin"] not in C:
            continue
        img = decode_layer(C[l["bin"]], int(l["width"]), int(l["height"]), "32bpp")[..., [2, 1, 0, 3]].astype(np.float32)
        dark = np.round(255 * (1 - img[..., :3].mean(-1) / 255) * img[..., 3] / 255)
        a = np.zeros((H, W), np.uint8)
        ox, oy = int(l["ofsx"]), int(l["ofsy"])
        x0, y0, x1, y1 = max(0, ox), max(0, oy), min(W, ox + dark.shape[1]), min(H, oy + dark.shape[0])
        a[y0:y1, x0:x1] = dark[y0 - oy:y1 - oy, x0 - ox:x1 - ox]
        folder = byid[l["parentId"]]["name"] if l["parentId"] in byid else ""
        if folder == "guidelines":  # drawn in colour, shown black: take the line itself as ink
            a[y0:y1, x0:x1] = np.where(img[y0 - oy:y1 - oy, x0 - ox:x1 - ox, 3] > 0, 255, 0)
        key = f"{folder}/{l['name']}"
        if key in out or f"{key}@1" in out:   # layers sharing a name in one folder: number them
            if key in out:
                out[f"{key}@1"] = out.pop(key)
            n = 2
            while f"{key}@{n}" in out:
                n += 1
            key = f"{key}@{n}"
        out[key] = a
    return out, (W, H)


def build_table(masks, ink, out_dir):
    """Write each loose piece of the table as a sprite and describe the table for the game:
    where each piece belongs, what it rests on, and its outline for the physics."""
    named = sorted(masks.items(), key=lambda kv: (-np.nonzero(kv[1])[0].max(), np.nonzero(kv[1])[1].min()))
    ids, info = {}, {}
    width = lambda m: np.ptp(np.nonzero(m)[1])
    frond = next((n for n in masks if "frond" in n or "palm" in n), max(masks, key=lambda n: width(masks[n])))
    held = next((n for n in masks if "held" in n), next((n for n in masks if n.split("@")[0] == TABLE_HELD), None))
    for i, (name, mask) in enumerate(named):
        ids[name] = f"t{i + 1:02d}"
    owner = np.zeros(ink.shape, np.int32)   # which piece each pixel belongs to (index + 1)
    for i, (name, mask) in enumerate(named):
        owner[mask & (ink > 0)] = i + 1
    for i, (name, mask) in enumerate(named):
        alpha = np.where(mask, ink, 0).astype(np.uint8)
        ys, xs = np.nonzero(alpha > 0)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        pid = ids[name]
        filled_rgba(alpha[y0:y1, x0:x1]).save(image_path(out_dir, f"{pid}"))
        # what it rests on: other pieces just under its lowest ink, lower down than itself
        cy = ys.mean()
        under = set()
        for x in range(x0, x1):
            col = np.nonzero(alpha[:, x] > 60)[0]
            if not len(col):
                continue
            yb = col.max()
            below = owner[yb + 1:yb + 1 + SUPPORT_GAP, max(x - 1, 0):x + 2]
            for j in np.unique(below):
                if j and j != i + 1 and np.nonzero(named[j - 1][1])[0].mean() > cy:
                    under.add(ids[named[j - 1][0]])
        hull = cv2.convexHull(np.stack([xs - x0, ys - y0], 1).astype(np.int32))
        hull = cv2.approxPolyDP(hull, 1.5, True)[:, 0]
        kind = "frond" if name == frond else "held" if name == held else "loose"
        info[pid] = {"x": int(x0), "y": int(y0), "w": int(x1 - x0), "h": int(y1 - y0), "kind": kind,
                     "name": name, "rests_on": sorted(under), "hull": hull.flatten().tolist()}
    return info


def stream_path(alpha, spout):
    """How far along the stream each of its pixels lies from the spout: 1..255 (0 = no ink).
    Measured along the stroke (8-connected), so the wave counts its own length; specks the
    stroke does not reach take the value of the nearest pixel it does."""
    import heapq
    on = alpha > 0
    ys, xs = np.nonzero(on)
    d0 = (xs - spout[0]) ** 2 + (ys - spout[1]) ** 2
    start = (int(ys[d0.argmin()]), int(xs[d0.argmin()]))
    dist = np.full(alpha.shape, np.inf)
    dist[start] = 0.0
    heap = [(0.0, start)]
    steps = [(dy, dx, math.hypot(dy, dx)) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]
    while heap:
        d, (y, x) = heapq.heappop(heap)
        if d > dist[y, x]:
            continue
        for dy, dx, w in steps:
            ny, nx = y + dy, x + dx
            if 0 <= ny < on.shape[0] and 0 <= nx < on.shape[1] and on[ny, nx] and d + w < dist[ny, nx]:
                dist[ny, nx] = d + w
                heapq.heappush(heap, (d + w, (ny, nx)))
    reached = np.isfinite(dist)
    _, (iy, ix) = ndi.distance_transform_edt(~reached, return_indices=True)
    dist = dist[iy, ix]
    frac = dist / dist[reached].max()
    return np.where(on, np.round(1 + 254 * np.clip(frac, 0, 1)), 0).astype(np.uint8)


def cut_water(mdp, out_dir):
    """Write the water's arm and stream sprites and the stream's path, and return
    ({sprite: rect}, the level's `water`)."""
    layers = {k.split("/", 1)[1]: a for k, a in mdp.items() if k.startswith(WATER_FOLDER + "/")}
    arm = layers["arm"] if "arm" in layers else layers.get("arms")
    if arm is None or "stream" not in layers:
        raise SystemExit(f"water: the .mdp folder `{WATER_FOLDER}` needs the layers `arms` and `stream`")
    sprites = {}
    stream = layers["stream"]
    for name, a in (("water_arm", arm), ("water_stream", stream)):
        ys, xs = np.nonzero(a > 0)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        ink_rgba(a[y0:y1, x0:x1]).save(image_path(out_dir, f"{name}"))
        sprites[name] = {"x": int(x0), "y": int(y0), "w": int(x1 - x0), "h": int(y1 - y0)}
    s = sprites["water_stream"]
    crop = stream[s["y"]:s["y"] + s["h"], s["x"]:s["x"] + s["w"]]
    path = stream_path(crop, (WATER["spout"][0] - s["x"], WATER["spout"][1] - s["y"]))
    Image.fromarray(path, "L").save(image_path(out_dir, "water_path"))
    water = {k: list(v) for k, v in WATER.items() if k in ("elbow", "spout", "hands", "view")}
    water["stand"] = WATER["stand"]
    # the line in order from the spout: the middle of the stroke at each of LINE_POINTS shares
    ys, xs = np.nonzero(path)
    k = np.minimum((path[ys, xs].astype(int) - 1) * LINE_POINTS // 255, LINE_POINTS - 1)
    water["line"] = [[round(float(xs[k == i].mean()) + s["x"], 1), round(float(ys[k == i].mean()) + s["y"], 1)]
                     for i in range(LINE_POINTS) if (k == i).any()]
    return sprites, water


def patch_water(mdp_path, out_dir):
    """Cut only the water into the level already in out_dir: its sprites, path and `water`."""
    out_dir = Path(out_dir)
    mdp, _ = load_mdp(mdp_path)
    level = json.loads((out_dir / "level.json").read_text())
    new, water = cut_water(mdp, out_dir)
    level["sprites"].update(new)
    level["water"] = water
    (out_dir / "level.json").write_text(json.dumps(level, indent=1))
    print(f"patched: {sorted(new)}")


FEATURES_FOLDER = "mouth game"   # (inside `opening of mouth`) the face lines carved in the game: `features`


def patch_features(mdp_path, out_dir):
    """Cut only the face lines (mouth_features) and the mummy's body without them (mouth_mummy)
    into the level already in out_dir. The body is the old body and the old face lines together,
    less the new face lines."""
    out_dir = Path(out_dir)
    mdp, _ = load_mdp(mdp_path)
    level = json.loads((out_dir / "level.json").read_text())
    features = mdp[f"{FEATURES_FOLDER}/features"]
    m = level["sprites"]["mouth_mummy"]
    x0, y0, x1, y1 = m["x"], m["y"], m["x"] + m["w"], m["y"] + m["h"]
    body = np.array(Image.open(image_path(out_dir, "mouth_mummy")))[..., 3].copy()
    f = level["sprites"]["mouth_features"]
    old = np.array(Image.open(image_path(out_dir, "mouth_features")))[..., 3]
    region = body[f["y"] - y0:f["y"] - y0 + f["h"], f["x"] - x0:f["x"] - x0 + f["w"]]
    np.maximum(region, old, out=region)
    body[features[y0:y1, x0:x1] > 0] = 0
    ink_rgba(body).save(image_path(out_dir, "mouth_mummy"))
    ys, xs = np.nonzero(features > 0)
    bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    ink_rgba(features[by0:by1, bx0:bx1]).save(image_path(out_dir, "mouth_features"))
    level["sprites"]["mouth_features"] = {"x": int(bx0), "y": int(by0), "w": int(bx1 - bx0), "h": int(by1 - by0)}
    (out_dir / "level.json").write_text(json.dumps(level, indent=1))
    print(f"patched: mouth_features {level['sprites']['mouth_features']}, mouth_mummy (body)")


def table_level(pieces):
    """The level's `table`: the scene's measures and its pieces (the frond lying in the band above)."""
    table = {"floor": list(TABLE["floor"]), "view": list(TABLE["view"]), "stand": TABLE["stand"],
             "header": list(TABLE["header"]), "speech": dict(zip("xywh", (TABLE["speech"][0], TABLE["speech"][1],
             TABLE["speech"][2] - TABLE["speech"][0], TABLE["speech"][3] - TABLE["speech"][1]))), "pieces": pieces}
    for pid, p in pieces.items():
        if p["kind"] == "frond":
            table["frond_rest"] = {"x": p["x"] + TABLE["frond_shift"], "y": TABLE["frond_bottom"] - p["h"]}
    return table


def patch_table(mdp_path, out_dir):
    """Cut only the offering table (its `table` folder) into the level already in out_dir: the
    pieces are cut anew (old ones go) and the level's `table` is worked out again."""
    out_dir = Path(out_dir)
    mdp, (W, H) = load_mdp(mdp_path)
    level = json.loads((out_dir / "level.json").read_text())
    layers_t = {k.split("/", 1)[1]: a for k, a in mdp.items() if k.startswith(TABLE_FOLDER + "/")}
    layers_t.pop(TABLE_BASE)
    masks = {name: a > 0 for name, a in layers_t.items() if (a > 0).any()}
    for old in (out_dir / "figures").glob("t[0-9][0-9].png"):
        old.unlink()
    tink = np.zeros((H, W), np.uint8)
    for a in layers_t.values():
        tink = np.maximum(tink, a)
    pieces = build_table(masks, tink, out_dir)
    level["table"] = table_level(pieces)
    (out_dir / "level.json").write_text(json.dumps(level, indent=1))
    print(f"patched: the table, {len(pieces)} pieces")


BULLS_FOLDER = "bulls"   # `plumed ox`, `plumes` (on his head), `plumes_wrong` (the same, on the sacrifice), `calf`, `sacrifice`


def patch_bulls(mdp_path, out_dir):
    """Cut only the three bulls' sprites (the plumed ox, the plumes) into the level already in
    out_dir, and record where the plumes go (`bulls`: `right` on his head, `wrong` on the sacrifice)."""
    out_dir = Path(out_dir)
    mdp, _ = load_mdp(mdp_path)
    level = json.loads((out_dir / "level.json").read_text())
    ox, plumes, wrong = (mdp[f"{BULLS_FOLDER}/{n}"] for n in ("plumed ox", "plumes", "plumes_wrong"))

    def rect(a):
        ys, xs = np.nonzero(a > 0)
        return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)
    for name, a in (("plumed_ox", ox), ("plumes", plumes)):
        x0, y0, x1, y1 = rect(a)
        ink_rgba(a[y0:y1, x0:x1]).save(image_path(out_dir, f"{name}"))
        level["sprites"][name] = {"x": x0, "y": y0, "w": x1 - x0, "h": y1 - y0}
    level["bulls"] = {k: dict(zip(("x", "y"), rect(a)[:2])) for k, a in (("right", plumes), ("wrong", wrong))}
    (out_dir / "level.json").write_text(json.dumps(level, indent=1))
    print(f"patched: plumed_ox, plumes; plumes {level['bulls']}")


MODES = {"--water": patch_water, "--table": patch_table, "--features": patch_features, "--bulls": patch_bulls}

if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[1] not in MODES:
        sys.exit(__doc__)
    MODES[sys.argv[1]](*sys.argv[2:4])
