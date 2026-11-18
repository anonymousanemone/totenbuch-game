"""Cut the figures of the night-journey level (Spells 17-21, pl. VII-XI) from the `dissected` folder.

Every layer in art/cosmos17-21.mdp's `dissected` folder (and its sub-folders) is one figure or
group cut out of the plates by hand. Each becomes a PNG of its own, cropped to its ink, and an
entry in level.json with its ID, place on the canvas and plate. Authored descriptions
live separately in assets/cosmos/registry.json. The .mdp is only read.

The layer names in the .mdp are often wrong (a cow called "Ram shrine", a ba-bird called
"Walking woman", two baboons called "Baboon 1"), so the names here come from looking at each
figure: FIGURES below is keyed by the layer's id in the .mdp, which stays put when a layer is
renamed or moved. A layer in `dissected` that is not in FIGURES is reported and skipped:
look at it, then add it.

Usage:
    python .claude/skills/build-levels/extract_cosmos_figures.py art/cosmos17-21.mdp godot/assets/cosmos/figures [NAME...]
        (with names, only those figures are cut again and their entries replaced; the rest of
        level.json is kept)

Outputs (ink in INK colour on transparent, world units = .mdp canvas pixels):
    <name>.png, level.json
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from mdp import read_mdp, decode_layer  # noqa: E402
from cutlib import INK  # noqa: E402

FOLDER = "dissected"
# The plate layers the figures were cut from (folder `plates`): a figure belongs to the plate
# its ink lies on.
PLATE_LAYERS = {"VII": "61", "VIII": "62", "IX": "63", "X": "64", "XI": "65"}
INK_MIN = 8  # alpha below this (after taking out the white the figures were lassoed with) is dropped

# Layer ID -> asset name. Authored descriptions live in assets/cosmos/registry.json.
FIGURES = {
    "130": "isis_nephthys_kneeling",
    "129": "nut_over_scarab",
    "132": "osiris_enthroned",
    "133": "offering_stand",
    "134": "deceased_adoring",
    "135": "anubis",
    "114": "chest_bearer",
    "115": "isis_nephthys_standing_1",
    "117": "baboons_praising_1",
    "119": "atum_evening_boat",
    "120": "baboons_praising_2",
    "122": "isis_nephthys_standing_2",
    "124": "baboons_seated_x",
    "96": "khepri_boat",
    "97": "deceased_kneeling",
    "98": "two_apes_isis_nephthys",
    "100": "falcon_on_standard",
    "101": "great_cat_and_apep",
    "103": "ished_tree",
    "104": "small_seated_god",
    "105": "twin_souls",
    "107": "two_bowls",
    "108": "horus_khenty_irty",
    "109": "spirit_with_emblem",
    "110": "duamutef",
    "111": "imsety",
    "112": "chest_with_head_of_ra",
    "113": "hapy",
    "83": "qebehsenuef",
    "84": "mehet_weret",
    "85": "offerer_before_cow",
    "86": "wedjat_shrine",
    "87": "thoth_baboon",
    "88": "rosetau_gate",
    "90": "heh_and_wadj_wer",
    "92": "nephthys_kite",
    "93": "mummy_on_bier",
    "94": "isis_kite",
    "95": "benu",
    "74": "lion_tomorrow",
    "75": "lion_yesterday",
    "73": "horizon",
    "76": "sun_boat_with_crew",
    "77": "adorer_with_flowers",
    "78": "adorer_before_boat",
    "79": "ba",
    "80": "falcon_on_perch",
    "81": "senet_booth",
    "82": "deceased_with_staff",
    "67": "inscriptions_vii",
    "68": "inscriptions_viii",
    "69": "inscriptions_ix"
}


def ink_alpha(img):
    """The figures were lassoed with the plate's white around them: ink is how dark a pixel is."""
    dark = 255 - img[..., :3].astype(np.float32).mean(2)
    a = img[..., 3].astype(np.float32) * dark / 255
    a[a < INK_MIN] = 0
    return np.round(a).astype(np.uint8)


def main():
    args = sys.argv[1:]
    if len(args) < 2:
        sys.exit(__doc__)
    mdp, out = Path(args[0]), Path(args[1])
    only = set(args[2:])
    known = set(FIGURES.values())
    if only - known:
        sys.exit(f"unknown figures: {sorted(only - known)}")
    out.mkdir(parents=True, exist_ok=True)

    W, H, layers, chunks, _ = read_mdp(mdp)
    by_id = {l["id"]: l for l in layers}

    def decode(l):
        return decode_layer(chunks[l["bin"]], int(l["width"]), int(l["height"]), l["type"])

    def path(l):
        p = []
        while l["parentId"] != "-1":
            l = by_id[l["parentId"]]
            p.append(l["name"])
        return p[::-1]

    plates = {}
    for name, lid in PLATE_LAYERS.items():
        ink = ink_alpha(decode(by_id[lid])) > 0
        xs = np.nonzero(ink.any(0))[0]
        plates[name] = {"x": int(xs.min()), "w": int(xs.max() + 1 - xs.min()),
                        "ink": ndi.binary_dilation(ink, iterations=2)}

    level_path = out.parent / "figures.json"
    level = json.loads(level_path.read_text()) if only and level_path.exists() else {}
    figures = level.get("figures", {})
    for l in layers:
        p = path(l)
        if FOLDER not in p or l["type"] == "folder":
            continue
        if l["id"] not in FIGURES:
            print(f"not in FIGURES, skipped: id {l['id']} '{l['name']}' in {'/'.join(p)}")
            continue
        name = FIGURES[l["id"]]
        if only and name not in only:
            continue
        img = decode(l)
        a = ink_alpha(img)
        ys, xs = np.nonzero(a)
        x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
        rgba = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        rgba[..., :3] = INK
        rgba[..., 3] = a[y0:y1, x0:x1]
        Image.fromarray(rgba, "RGBA").save(out / f"{name}.png")
        on = a > 0
        plate = max(plates, key=lambda n: int((plates[n]["ink"] & on).sum()))
        entry = {"x": x0, "y": y0, "w": x1 - x0, "h": y1 - y0, "plate": plate,
                 "layer": l["name"], "group": "/".join(p[p.index(FOLDER) + 1:]),
                 "id": name}
        figures[name] = entry
        print(f"{name:26s} {plate:5s} ({x0}, {y0}, {x1 - x0}, {y1 - y0})  <- '{l['name']}'")

    level = {"source": mdp.name, "folder": FOLDER, "width": W, "height": H,
             "plates": {n: {"x": p["x"], "w": p["w"]} for n, p in plates.items()},
             "figures": dict(sorted(figures.items(), key=lambda kv: kv[1]["x"]))}
    level_path.write_text(json.dumps(level, indent=1, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
