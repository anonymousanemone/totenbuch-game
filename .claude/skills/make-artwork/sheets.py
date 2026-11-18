"""Animation sheets drawn from the cut art, for the figures that swing an arm or bend. Both kinds are meant to be
touched up by hand afterwards: a sheet already there is left alone (delete it to make it again).

    python .claude/skills/make-artwork/sheets.py procession art/procession1-15.mdp godot/assets/procession [preview_dir]
    python .claude/skills/make-artwork/sheets.py procession --parts art/procession1-15.mdp godot/assets/procession
    python .claude/skills/make-artwork/sheets.py survival [--gif DIR]            # --gif also writes previews to DIR
    (procession needs the `general` conda environment: ~/miniconda3/envs/general/bin/python)

procession  The two swinging arms of the procession as sprite sheets, from art/procession1-15.mdp (only read).
            Each arm is drawn on its own layer beside its figure (`water game/arms` beside `water game/man`,
            `haul/whip+arm` beside `haul/driver`), and the elbow is drawn on both: the pin is where the two
            overlap. Every frame is the whole figure, the body as drawn and the arm turned about the pin, so the
            elbow can be drawn over by hand frame by frame. The pin sits at the same place in every cell.
                <name>_sheet.png   COLS frames a row, CW x CH cells, ink in INK colour on transparent
                <name>_sheet.json  the cell size, columns, each frame's turn from as drawn (rad, Godot's sense:
                                   + is clockwise on screen), the frame as drawn, the pin in the cell and on
                                   the strip, and where the cell's top-left lies on the strip
            With --parts it writes instead the body (without the old copy of the arm) and the arm as two
            sprites, for the game to turn the arm about the pin in code, and prints where they lie:
                <name>_body.png, <name>_arm.png   cropped to their ink, in INK colour on transparent

survival    Draft sheets for Survival, made from the cut pieces (godot/assets/survival/figures):
            - spell53_arm_sheet.png: the seated man of 53 (no chair) holding out his cup. His elbow bends and
              stretches so the cup moves along a level line, from drawn in close to stretched out: the upper arm
              turns about the shoulder, the forearm about the elbow, and the hand with the cup only moves (it
              stays level).
            - spell57_bend_sheet.png: the 57 man bending at the waist, from a little upright to bent low, the
              upper body turned about the waist.
            Each frame is the whole figure, all frames the same size, in a row; the frame drawn as on the plate is
            listed in the .json beside the sheet, with the frame size and where the frame's top-left lies in
            strip px.
"""
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[3]
sys.path[0:0] = [str(ROOT / 'tools'), str(ROOT / 'tools' / 'mdp300'), str(ROOT / '.claude' / 'skills' / 'build-levels')]
from cutlib import INK, PAPYRUS  # noqa: E402
from level_images import image_path  # noqa: E402


def write_gif(frames, path, resample, ms):
    """`frames` (2D, ink 0..255) there and back on papyrus, at twice the size."""
    images = []
    for f in frames:
        a = (np.asarray(f) / 255.0)[..., None]
        rgb = (np.array(INK) * a + np.array(PAPYRUS) * (1 - a)).astype(np.uint8)
        im = Image.fromarray(rgb)
        images.append(im.resize((im.width * 2, im.height * 2), resample))
    loop = images + images[-2:0:-1]
    loop[0].save(path, save_all=True, append_images=loop[1:], duration=ms, loop=0)


# --- procession: the water priest and the ox-driver -----------------------------------------------

PAD = 8
ARM_SHEETS = {
    # the water priest: the game's whole tilt range (pour_water.gd LOW..HIGH) at 0.05 rad a frame,
    # many frames as the game is the swivel
    "water": {"body": "water game/man", "arm": "water game/arms", "cols": 6,
              "turns": [round(-0.55 + 0.05 * i, 2) for i in range(24)]},
    # the ox-driver: wound back (haul.gd WIND) through as drawn to the full strike (-STRIKE)
    "haul_driver": {"body": "haul/driver", "arm": "haul/whip+arm", "cols": 8,
                    "turns": [0.2, 0.1, 0.0, -0.11, -0.22, -0.33, -0.44, -0.55]},
}




def split_arm(body, arm):
    """The pin (the centre of the elbow, the smallest piece the two layers share), and the body
    without anything else it shares with the arm (an old copy of the arm left under it)."""
    both = (body > 0) & (arm > 0)
    lab, n = ndi.label(both, np.ones((3, 3)))
    sizes = ndi.sum(both, lab, range(1, n + 1))
    elbow = lab == 1 + int(np.argmin(np.where(sizes > 3, sizes, np.inf)))
    pin = ndi.center_of_mass(elbow)[::-1]
    copy = ndi.binary_dilation(both & ~elbow, iterations=2) & ~ndi.binary_dilation(elbow, iterations=4)
    out = np.where(copy, 0, body).astype(np.uint8)
    lab, n = ndi.label(out > 0, np.ones((3, 3)))   # specks along the copy's edge
    sizes = ndi.sum(out > 0, lab, range(1, n + 1))
    for i in np.nonzero(sizes < 40)[0] + 1:
        if copy[ndi.binary_dilation(lab == i)].any():
            out[lab == i] = 0
    return out, pin


def turned(points, pin, a):
    """Strip points turned by `a` (Godot's sense) about `pin`."""
    c, s = math.cos(a), math.sin(a)
    d = points - pin
    return np.stack([pin[0] + d[:, 0] * c - d[:, 1] * s, pin[1] + d[:, 0] * s + d[:, 1] * c], 1)


def arm_sheet(mdp, spec):
    body, pin = split_arm(mdp[spec["body"]], mdp[spec["arm"]])
    arm = mdp[spec["arm"]]
    ys, xs = np.nonzero(arm)
    pts = np.stack([xs, ys], 1).astype(float)
    reach = np.concatenate([turned(pts, np.array(pin), a) for a in spec["turns"]])
    ys, xs = np.nonzero(body)
    x0 = int(math.floor(min(xs.min(), reach[:, 0].min()))) - PAD
    y0 = int(math.floor(min(ys.min(), reach[:, 1].min()))) - PAD
    x1 = int(math.ceil(max(xs.max(), reach[:, 0].max()))) + PAD + 1
    y1 = int(math.ceil(max(ys.max(), reach[:, 1].max()))) + PAD + 1
    cw, ch = x1 - x0, y1 - y0
    b, a = body[y0:y1, x0:x1], Image.fromarray(arm[y0:y1, x0:x1])
    centre = (pin[0] - x0, pin[1] - y0)
    cols = spec["cols"]
    rows = math.ceil(len(spec["turns"]) / cols)
    out = np.zeros((rows * ch, cols * cw), np.uint8)
    for i, t in enumerate(spec["turns"]):
        r = np.array(a) if t == 0 else np.array(a.rotate(-math.degrees(t), resample=Image.BICUBIC, center=centre))
        cy, cx = divmod(i, cols)
        out[cy * ch:(cy + 1) * ch, cx * cw:(cx + 1) * cw] = np.maximum(b, r)
    meta = {"cell": [cw, ch], "cols": cols, "turns": spec["turns"], "rest": spec["turns"].index(0.0),
            "pin": [round(float(centre[0]), 1), round(float(centre[1]), 1)], "pin_strip": [round(float(pin[0]), 1), round(float(pin[1]), 1)],
            "origin": [x0, y0], "layers": [spec["body"], spec["arm"]]}
    return out, meta


def preview(out, meta, path):
    """The frames there and back on papyrus, at twice the size."""
    cw, ch = meta["cell"]
    cells = [out[cy * ch:(cy + 1) * ch, cx * cw:(cx + 1) * cw].astype(float)
             for cy, cx in (divmod(i, meta["cols"]) for i in range(len(meta["turns"])))]
    write_gif(cells, path, Image.NEAREST, 1000 // 12)


def procession_parts(mdp_path, out_dir):
    """Each figure's body and arm, cropped, and where they and the pin lie on the strip."""
    from extract_procession300 import ink_rgba, load_mdp
    mdp, _ = load_mdp(mdp_path)
    names = {"water": "water_priest", "haul_driver": "haul_driver"}
    for name, spec in ARM_SHEETS.items():
        body, pin = split_arm(mdp[spec["body"]], mdp[spec["arm"]])
        for part, a in (("body", body), ("arm", mdp[spec["arm"]])):
            ys, xs = np.nonzero(a)
            x0, y0 = int(xs.min()), int(ys.min())
            ink_rgba(a[y0:ys.max() + 1, x0:xs.max() + 1]).save(image_path(Path(out_dir), f"{names[name]}_{part}"))
            print(f"{names[name]}_{part}.png at ({x0}, {y0}), {xs.max() + 1 - x0}x{ys.max() + 1 - y0}")
        print(f"{names[name]} pin ({pin[0]:.1f}, {pin[1]:.1f})")


def procession(mdp_path, out_dir, preview_dir=None):
    from extract_procession300 import ink_rgba, load_mdp
    mdp, _ = load_mdp(mdp_path)
    for name, spec in ARM_SHEETS.items():
        png = image_path(Path(out_dir), f"{name}_sheet")
        if png.exists():   # the sheets are drawn over by hand: never remade
            print(f"{name}_sheet.png is there already: left as it is")
            continue
        out, meta = arm_sheet(mdp, spec)
        ink_rgba(out).save(png)
        png.with_suffix(".json").write_text(json.dumps(meta, indent=1) + "\n")
        print(f"{name}_sheet.png: {len(spec['turns'])} frames, cells {meta['cell']}, pin {meta['pin_strip']}")
        if preview_dir:
            preview(out, meta, Path(preview_dir) / f"{name}_sheet.gif")


# --- survival: the seated man of 53, the bending man of 57 ----------------------------------------

ASSETS = ROOT / 'godot/assets/survival'
OUT = ASSETS / 'animation'

# 53, strip px
SHOULDER = (4452.0, 304.0)
ELBOW = (4500.0, 352.0)
WRIST = (4525.0, 311.0)
UPPER_ARM_WIDTH = 7.0          # either side of the shoulder–elbow line
WRIST_X = np.arange(4485.0, 4566.0, 10.0)  # the wrist's x in each frame, at the drawn wrist's height (4525: as drawn)
# 57
WAIST = (3210.0, 400.0)                    # the hips: what the bend turns about
BEND = np.array([0.12, 0.06, 0.0, -0.08, -0.16, -0.25, -0.34, -0.43, -0.52, -0.61, -0.7])  # rad, as Godot turns it (negative bends him forward)
BEND_FROM = 0.0                # px above the hips where the bend begins (below, he does not move) ...
BEND_TO = 30.0                 # ... and where it is whole: in between his back curves
MESH = 6                       # px between the bend's mesh points


def item(key):
    level = json.loads((ASSETS / 'level.json').read_text())
    return level['figures'].get(key) or level['pieces'][key]


def layer(key, box):
    """The sprite's ink on a canvas covering `box` (strip px)."""
    x0, y0, x1, y1 = box
    canvas = np.zeros((y1 - y0, x1 - x0), np.float32)
    it = item(key)
    a = np.asarray(Image.open(ASSETS / 'figures' / f'{key}.png'))[..., 3].astype(np.float32)
    x, y = it['x'] - x0, it['y'] - y0
    sx, sy = max(0, -x), max(0, -y)
    dx, dy = max(0, x), max(0, y)
    w, h = min(a.shape[1] - sx, canvas.shape[1] - dx), min(a.shape[0] - sy, canvas.shape[0] - dy)
    canvas[dy:dy + h, dx:dx + w] = a[sy:sy + h, sx:sx + w]
    return canvas


def move(a, box, frm, to, angle):
    """Turn `a` by `angle` (rad, clockwise on screen) about `frm`, which lands on `to` (strip px)."""
    c, s = math.cos(angle), math.sin(angle)
    fx, fy = frm[0] - box[0], frm[1] - box[1]
    tx, ty = to[0] - box[0], to[1] - box[1]
    m = np.float32([[c, -s, tx - (c * fx - s * fy)], [s, c, ty - (s * fx + c * fy)]])
    return cv2.warpAffine(a, m, (a.shape[1], a.shape[0]), flags=cv2.INTER_LINEAR)


def corridor(box, p, q, width):
    """A band `width` either side of the segment p–q, on the box's canvas."""
    m = np.zeros((box[3] - box[1], box[2] - box[0]), np.uint8)
    pts = np.int32([[p[0] - box[0], p[1] - box[1]], [q[0] - box[0], q[1] - box[1]]])
    cv2.line(m, tuple(pts[0]), tuple(pts[1]), 1, int(width * 2))
    return m.astype(bool)


def ik(target):
    """The elbow for a wrist at `target`: on the side it is drawn (below the shoulder–wrist line)."""
    l1 = math.dist(SHOULDER, ELBOW)
    l2 = math.dist(ELBOW, WRIST)
    d = min(math.dist(SHOULDER, target), l1 + l2 - 0.01)
    a = math.atan2(target[1] - SHOULDER[1], target[0] - SHOULDER[0])
    phi = math.acos((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d))
    options = [(SHOULDER[0] + l1 * math.cos(a + k * phi), SHOULDER[1] + l1 * math.sin(a + k * phi)) for k in (1, -1)]
    return max(options, key=lambda e: e[1])


JOINT = 5                  # px, the arm's line


def _toward(p, q, d):
    a = angle(p, q)
    return (p[0] + d * math.cos(a), p[1] + d * math.sin(a))


def _px(p, box):
    return (int(round(p[0] - box[0])), int(round(p[1] - box[1])))


def angle(p, q):
    return math.atan2(q[1] - p[1], q[0] - p[0])


def arm53():
    box = (4360, 230, 4640, 540)
    body = layer('spell53_offerings', box)
    head = layer('spell53_head', box)
    forearm = layer('spell53_forearm', box)
    band = corridor(box, (SHOULDER[0] + 3, SHOULDER[1] + 1), (ELBOW[0] - 2, ELBOW[1] - 2), UPPER_ARM_WIDTH)
    upper = np.where(band, body, 0)
    body = np.where(band, 0, body)
    cols = np.arange(box[2] - box[0])[None, :] + box[0]
    hand = np.where(cols >= WRIST[0] + 1, forearm, 0)
    fore = np.where(cols >= WRIST[0] + 1, 0, forearm)
    frames = []
    for x in WRIST_X:
        wrist = (x, WRIST[1])
        elbow = ik(wrist)
        f = np.maximum(body, head)
        f = np.maximum(f, move(upper, box, SHOULDER, SHOULDER, angle(SHOULDER, elbow) - angle(SHOULDER, ELBOW)))
        f = np.maximum(f, move(fore, box, ELBOW, elbow, angle(elbow, wrist) - angle(ELBOW, WRIST)))
        f = np.maximum(f, move(hand, box, WRIST, wrist, 0.0))
        # close the joints the turning opens: a short stroke across the elbow and the wrist
        joints = np.zeros_like(f)
        for p, q in [(_toward(elbow, SHOULDER, 5), _toward(elbow, wrist, 5)), (_toward(wrist, elbow, 5), (wrist[0] + 3, wrist[1]))]:
            cv2.line(joints, _px(p, box), _px(q, box), 255.0, JOINT)
        frames.append(np.maximum(f, cv2.GaussianBlur(joints, (3, 3), 0)))
    drawn = int(np.argmin(np.abs(WRIST_X - WRIST[0])))
    return frames, box, drawn


def bend57():
    """The whole man bent, not cut: a mesh over the drawing, each point of it turned about the
    hips by a share of the bend that eases in with its height above them. Above the waist band
    the share is whole, so his upper body turns as it is drawn (no part of it narrows); in the
    band his back curves. The drawing follows the mesh (piecewise affine)."""
    from skimage.transform import PiecewiseAffineTransform, warp
    box = (3060, 220, 3300, 540)
    man = np.maximum(layer('spell57_lower_body', box), layer('spell57_upper_body', box)) / 255.0
    px, py = WAIST[0] - box[0], WAIST[1] - box[1]
    h, w = man.shape
    gy, gx = np.mgrid[0:h + 1:MESH, 0:w + 1:MESH]
    src = np.column_stack([gx.ravel(), gy.ravel()]).astype(np.float64)
    rise = np.clip((py - src[:, 1] - BEND_FROM) / (BEND_TO - BEND_FROM), 0.0, 1.0)
    share = rise * rise * (3.0 - 2.0 * rise)              # smoothstep
    frames = []
    for b in BEND:
        a = b * share
        c, s = np.cos(a), np.sin(a)
        dx, dy = src[:, 0] - px, src[:, 1] - py
        dst = np.column_stack([px + c * dx - s * dy, py + s * dx + c * dy])
        tf = PiecewiseAffineTransform.from_estimate(dst, src)   # warp() wants where each output point comes from
        frames.append(warp(man, tf, output_shape=man.shape, order=3, mode='constant', cval=0.0).clip(0, 1) * 255.0)
    return frames, box, int(np.argmin(np.abs(BEND)))


def crop(frames, box):
    used = np.maximum.reduce(frames) > 8
    ys, xs = np.nonzero(used)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    return [f[y0:y1, x0:x1] for f in frames], (box[0] + int(x0), box[1] + int(y0))


def save_survival(name, frames, box, drawn, gif_dir):
    frames, origin = crop(frames, box)
    h, w = frames[0].shape
    sheet = np.zeros((h, w * len(frames), 4), np.uint8)
    sheet[..., :3] = INK
    for i, f in enumerate(frames):
        sheet[:, i * w:(i + 1) * w, 3] = np.clip(np.rint(f), 0, 255)
    OUT.mkdir(exist_ok=True)
    path = OUT / f'{name}.png'
    if path.exists():
        print(f'{path.name} is already there (touched up by hand?): left alone')
    else:
        Image.fromarray(sheet).save(path)
        (OUT / f'{name}.json').write_text(json.dumps(dict(frames=len(frames), w=w, h=h, x=origin[0], y=origin[1], drawn=drawn), indent=1) + '\n')
        print(f'{path.name}: {len(frames)} frames of {w}x{h}, drawn frame {drawn}')
    if gif_dir:
        write_gif(frames, Path(gif_dir) / f'{name}.gif', Image.Resampling.LANCZOS, 110)


def survival(gif_dir=None):
    save_survival('spell53_arm_sheet', *arm53(), gif_dir)
    save_survival('spell57_bend_sheet', *bend57(), gif_dir)


if __name__ == '__main__':
    args = sys.argv[1:]
    if args[:1] == ['procession'] and args[1:2] == ['--parts'] and len(args) == 4:
        procession_parts(*args[2:4])
    elif args[:1] == ['procession'] and 3 <= len(args) <= 4:
        procession(*args[1:4])
    elif args[:1] == ['survival'] and args[1:2] in ([], ['--gif']) and len(args) in (1, 3):
        survival(*args[2:3])
    else:
        sys.exit('usage: python .claude/skills/make-artwork/sheets.py procession [--parts] <procession.mdp> <out dir> [preview dir]'
                 ' | survival [--gif DIR]')
