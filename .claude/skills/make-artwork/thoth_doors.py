"""The doors of the sky opening (spell 161, the doors level), in two ways to choose from.

    python .claude/skills/make-artwork/thoth_doors.py slide|swing [--into DIR]

The door is two leaves that meet in the middle of the plate's centre panel (x MIDDLE), where nothing is drawn. The
two inner vertical lines are the leaves' bars (the two Thoths on each side hold one); they run through both
registers and the narrow bands above them (where they stand as four small nubs), from under the top double rule to
the end of the bottom one. A leaf is opaque (papyrus: nothing behind it shows through, and it is drawn over whatever
it passes) and carries all the ink on it: its bar and nubs, its text and the pieces of the rules that cross it. As
it opens, the drawing splits apart down the middle onto solid ink. The ink is moved, squeezed or carried, never
redrawn; frame 0 is the plate as drawn.

slide  Each leaf runs from its bar to the middle and slides whole, OPEN px toward the Thoths who pull it.
swing  Each leaf is twice as wide: its bar is the leaf's middle, so it takes in the legend outside the bar as well.
       It is hinged at its outer edge and swings in, away from us, to SWING degrees: it is foreshortened toward the
       hinge (its width times the cosine of the angle) and its far edge, the one at the middle, shrinks by up to TAPER
       of its height, so the rules on it slope in.
       The four Thoths hold the bars as they go. As a leaf swings in its bar comes toward the Thoths on that side, so
       each keeps his hands on it: his feet and hem stay planted and he leans back from the ankles, his body turned
       about his feet by an angle that grows from nothing at the ground to full at LEAN_FROM, so that his shoulders go
       back LEAN_SHARE of the way the bar comes. His arms bend to take the rest: the lower arm at its drawn elbow, the
       straight upper arm at its middle, both bending down. Each bone's ink (and the fist at its end) is split off and
       carried whole, so the arm keeps its line and length; the bones meet at the shoulder and elbow. SWING is as far as that reaches without his
       arms folding shut. A Thoth is opaque (papyrus within his outline), standing in front of the leaves.

Reads the exported level (godot/assets/doors: level.json, strip.png and the door and legend captions), so run
.claude/skills/build-levels/build_walk.py doors first. Writes, in godot/assets/doors/animation/ (under DIR/godot with --into):

  slide: spell161_door_<left|right>.png, each leaf's ink; doors_slide.json, each leaf's rectangle on the plate as
         drawn (x, y, w, h), its direction (-1 left, +1 right) and how far it has moved at each of FRAMES frames (px).
  swing: spell161_door_<left|right>_swing.png, a row of FRAMES cells of the leaf's rectangle, one per frame, for
         figure.gdshader: red is the ink, green the leaf's face (where it is opaque, filled with the papyrus).
         spell161_thoth_<n>_swing.png, each Thoth in the same frames and the same form, in a cell that lines up with
         the plate at the json's `thoths` x, y.
         doors_swing.json, each leaf's rectangle, its hinge side and its angle at each frame (degrees), and each
         Thoth's cell.
"""
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools'))
from cutlib import INK  # noqa: E402
from scipy import ndimage  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
FRAMES = 12                  # frame 0 shut, as drawn; frame FRAMES-1 fully open
OPEN = 70                    # slide: how far each leaf goes (plate px): as far as a Thoth can lean back holding it
SWING = 60                   # swing: the angle of a fully open leaf (degrees)
TAPER = 0.06                 # swing: how much the far edge shrinks at 90 degrees (a share of the leaf's height)
BARS = (449.5, 912.5)        # the middles of the two inner vertical lines
MIDDLE = 681                 # where the leaves meet: halfway between the bars
ROWS = (50, 1887)            # from under the top double rule to the last row of the bottom one (the bars' own span)
TEXTS = [f'spell161_door_{n}_caption' for n in range(1, 5)]       # the columns beside the bars
LEGENDS = [f'spell161_thoth_{n}_caption' for n in range(1, 5)]   # the text above each Thoth, outside the bars
LEAN_SHARE = 0.85            # swing: how much of the bar's coming the Thoth's shoulders take by leaning back
LEAN_FROM = 140              # px above the ground where the lean is full; below it the legs lean less, the feet none
BONE_REACH = 13              # ink within this of an arm's bone is the arm's
BONE_FROM = 0.25             # how far out from the shoulder the arm's own ink begins (a share of the first bone)
FIST = 36                    # ink within this of a hand is the hand's (the lower-left Thoth's hangs down)
# Each Thoth: his leaf, the middle of his feet (what he leans about), and his arms as drawn (plate px): shoulder,
# elbow (None for the straight upper arm, which bends at its middle) and the hand on the bar.
THOTHS = {
    1: dict(leaf='right', feet=(1038, 966), arms=(((1027, 594), None, (912, 581)),
                                                  ((1024, 604), (1000, 654), (914, 706)))),
    2: dict(leaf='left', feet=(338, 969), arms=(((350, 571), None, (455, 565)),
                                                ((362, 580), (372, 640), (452, 700)))),
    3: dict(leaf='right', feet=(1017, 1868), arms=(((1011, 1457), None, (911, 1434)),
                                                   ((1009, 1467), (991, 1552), (909, 1587)))),
    4: dict(leaf='left', feet=(339, 1868), arms=(((372, 1466), None, (450, 1463)),
                                                 ((370, 1468), (387, 1538), (450, 1593)))),
}


def ease(t):
    return t * t * (3 - 2 * t)


def ink(path):
    return np.asarray(Image.open(path))[..., 3]


def save(alpha, path):
    out = np.zeros(alpha.shape + (4,), np.uint8)
    out[..., :3] = INK
    out[..., 3] = np.clip(np.rint(alpha), 0, 255).astype(np.uint8)
    Image.fromarray(out).save(path)


def save_figure(alpha, face, path):
    """Ink and face as figure.gdshader reads them: red the ink, green the face (inside the outline)."""
    out = np.zeros(alpha.shape + (4,), np.uint8)
    out[..., 0] = np.clip(np.rint(alpha), 0, 255).astype(np.uint8)
    out[..., 1] = np.where(face > 127, 255, 0)
    out[..., 3] = 255
    Image.fromarray(out).save(path)


def swing(leaf, angle):
    """The leaf (hinged at its left edge) swung in by `angle` degrees: (ink, face), each the leaf's own size."""
    h, w = leaf.shape
    a = np.radians(angle)
    nw = max(1, int(round(w * np.cos(a))))
    if nw == w and angle == 0:
        return leaf.astype(np.float32), np.full((h, w), 255, np.float32)
    squeezed = cv2.resize(leaf.astype(np.float32), (nw, h), interpolation=cv2.INTER_AREA)
    face = np.full((h, nw), 255, np.float32)
    # the far edge shrinks toward the middle row, more the farther from the hinge
    yy, xx = np.mgrid[0:h, 0:nw].astype(np.float32)
    s = 1 - TAPER * np.sin(a) * xx / max(nw - 1, 1)
    cy = (h - 1) / 2
    my = (cy + (yy - cy) / s).astype(np.float32)
    ink_out = cv2.remap(squeezed, xx, my, cv2.INTER_LINEAR, borderValue=0)
    face_out = cv2.remap(face, xx, my, cv2.INTER_LINEAR, borderValue=0)
    pad = ((0, 0), (0, w - nw))
    return np.pad(ink_out, pad), np.pad(face_out, pad)


def on_leaf(point, leaf, angle):
    """Where a point drawn on a shut leaf is when it has swung in by `angle` (as swing() moves the ink)."""
    a = np.radians(angle)
    hinge = leaf['x'] if leaf['hinge'] == 'left' else leaf['x'] + leaf['w']
    x = hinge + (point[0] - hinge) * np.cos(a)
    s = 1 - TAPER * np.sin(a) * abs(point[0] - hinge) / leaf['w']
    cy = leaf['y'] + (leaf['h'] - 1) / 2
    return np.array([x, cy + (point[1] - cy) * s])


def elbow(s, h, l1, l2):
    """The elbow of a two-bone arm from shoulder `s` to hand `h`, bones `l1` and `l2`, bending down."""
    d = float(np.clip(np.linalg.norm(h - s), abs(l1 - l2) + 1e-3, l1 + l2 - 1e-6))
    u = (h - s) / max(np.linalg.norm(h - s), 1e-6)
    perp = np.array([-u[1], u[0]])
    if perp[1] < 0:
        perp = -perp
    ca = np.clip((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d), -1, 1)
    return s + l1 * (u * ca + perp * np.sqrt(1 - ca * ca))


def opaque(alpha):
    """The figure's face: its ink, 2 px round it, and everything that encloses."""
    solid = ndimage.binary_dilation(alpha > 40, iterations=2)
    return np.where(ndimage.binary_fill_holes(solid), 255, 0).astype(np.float32)


def thoth_frames(n, cfg, level, src, leaves, angles):
    """Thoth n holding his bar through the swing: (cell box, ink frames, face frames)."""
    fid = f'spell161_thoth_{n}'
    f = level['figures'][fid]
    body = ink(src / f'figures/{fid}.png').astype(np.float32)
    leaf = leaves[f'spell161_door_{cfg["leaf"]}']
    back = -1 if cfg['leaf'] == 'left' else 1           # which way he leans: away from his bar
    margin = 170                                       # room for the lean
    cx0 = f['x'] - 10 - (margin if back < 0 else 0)
    cx1 = f['x'] + f['w'] + 10 + (margin if back > 0 else 0)
    cx0, cx1 = max(cx0, 0), min(cx1, level['width'])     # within the plate
    cy0, cy1 = f['y'] - 10, max(f['y'] + f['h'], cfg['feet'][1]) + 4
    cw, ch = cx1 - cx0, cy1 - cy0
    drawn = np.zeros((ch, cw), np.float32)
    drawn[f['y'] - cy0:f['y'] - cy0 + f['h'], f['x'] - cx0:f['x'] - cx0 + f['w']] = body
    feet = np.array(cfg['feet'], float)
    arms = [(np.array(sh, float), None if el is None else np.array(el, float), np.array(ha, float))
            for sh, el, ha in cfg['arms']]
    arms = [(sh, (sh + ha) / 2 if el is None else el, ha) for sh, el, ha in arms]
    yy, xx = np.mgrid[0:ch, 0:cw].astype(np.float32)
    px, py = xx + cx0, yy + cy0                             # plate coordinates of every cell pixel
    # each arm's bones (the first starts a little out from the shoulder, which stays with the body) and the ink
    # that is theirs: within BONE_REACH of the bone, and the hand's fist round its end
    bones, near = [], np.full((ch, cw), np.inf, np.float32)
    owner = np.full((ch, cw), -1, np.int32)
    for sh, el, ha in arms:
        for a, b, t0 in ((sh, el, BONE_FROM), (el, ha, 0.0)):
            d = b - a
            t = np.clip(((px - a[0]) * d[0] + (py - a[1]) * d[1]) / (d @ d), t0, 1)
            dist = np.hypot(px - (a[0] + t * d[0]), py - (a[1] + t * d[1]))
            if b is ha:
                dist = np.minimum(dist, np.where(np.hypot(px - ha[0], py - ha[1]) < FIST, 0, np.inf))
            mine = (dist < BONE_REACH) & (dist < near)
            owner[mine] = len(bones)
            near = np.minimum(near, np.where(mine, dist, near))
            bones.append((a, b))
    inked = drawn > 0
    for i, (sh, el, ha) in enumerate(arms):        # an arm keeps only the ink joined to its hand; the rest is body
        labels, _ = ndimage.label(inked & ((owner == 2 * i) | (owner == 2 * i + 1)), np.ones((3, 3)))
        fist = np.hypot(px - ha[0], py - ha[1]) < FIST
        keep = np.isin(labels, np.unique(labels[fist & (labels > 0)]))
        owner[((owner == 2 * i) | (owner == 2 * i + 1)) & ~keep] = -1
    for k in range(2 * len(arms)):                # and the soft edge just outside its ink, so none is left behind
        fringe = ndimage.binary_dilation(owner == k, iterations=4) & inked & (owner < 0) & (drawn < 128)
        owner[fringe] = k
    crumbs, count = ndimage.label(inked & (owner < 0), np.ones((3, 3)))   # loose crumbs of the arm's edge
    sizes = ndimage.sum(np.ones_like(crumbs), crumbs, range(1, count + 1))
    for k in range(2 * len(arms)):
        close = ndimage.binary_dilation(owner == k, iterations=6)
        for c in np.unique(crumbs[close & (crumbs > 0)]):
            if sizes[c - 1] < 40:
                owner[crumbs == c] = k
    parts = [np.where(inked & (owner == i), drawn, 0) for i in range(len(bones))]
    trunk = np.where(inked & (owner < 0), drawn, 0)
    inks, faces = [], []
    for angle in angles:
        if angle == 0:
            inks.append(drawn.copy())
            faces.append(opaque(drawn))
            continue
        bar = BARS[0] if cfg['leaf'] == 'left' else BARS[1]
        come = abs(on_leaf((bar, 0), leaf, angle)[0] - bar)     # how far his bar has come toward him
        shoulder_h = feet[1] - min(sh[1] for sh, _, _ in arms)
        theta = back * LEAN_SHARE * come / shoulder_h

        def turn(h):
            return theta * np.clip(h / LEAN_FROM, 0, 1) ** 1.5

        def lean(p):
            a = turn(feet[1] - p[1])
            r = np.asarray(p, float) - feet
            return feet + np.array([[np.cos(a), -np.sin(a)], [np.sin(a), np.cos(a)]]) @ r
        # the body: each pixel read from where the lean brought it from (turned back about the feet, twice over,
        # since how far it turns depends on its height)
        sx, sy = px.astype(np.float64), py.astype(np.float64)
        for _ in range(3):
            a = -turn(feet[1] - sy)
            rx, ry = px - feet[0], py - feet[1]
            sx, sy = feet[0] + np.cos(a) * rx - np.sin(a) * ry, feet[1] + np.sin(a) * rx + np.cos(a) * ry
        frame = cv2.remap(trunk, (sx - cx0).astype(np.float32), (sy - cy0).astype(np.float32), cv2.INTER_LINEAR,
                          borderValue=0)
        # the arms: each bone carried whole, from where it is drawn to where the lean and the bar put it
        i = 0
        for sh, el, ha in arms:
            l1, l2 = np.linalg.norm(el - sh), np.linalg.norm(ha - el)
            sh2, ha2 = lean(sh), on_leaf(ha, leaf, angle)
            el2 = elbow(sh2, ha2, l1, l2)
            for (a, b), (a2, b2) in zip(bones[i:i + 2], ((sh2, el2), (el2, ha2))):
                phi = np.arctan2(*(b2 - a2)[::-1]) - np.arctan2(*(b - a)[::-1])
                rx, ry = px - a2[0], py - a2[1]
                bx = a[0] + np.cos(-phi) * rx - np.sin(-phi) * ry
                by = a[1] + np.sin(-phi) * rx + np.cos(-phi) * ry
                piece = cv2.remap(parts[i], (bx - cx0).astype(np.float32), (by - cy0).astype(np.float32),
                                  cv2.INTER_LINEAR, borderValue=0)
                frame = np.maximum(frame, piece)
                i += 1
        frame = np.where(frame < 12, 0, frame)
        inks.append(frame)
        faces.append(opaque(frame))
    return dict(x=cx0, y=cy0, w=cw, h=ch), inks, faces


def main(mode, base):
    src = ROOT / 'godot/assets/doors'
    level = json.loads((src / 'level.json').read_text())
    plate = ink(src / 'figures/strip.png').copy()
    for fid in TEXTS + (LEGENDS if mode == 'swing' else []):
        f = level['figures'][fid]
        region = plate[f['y']:f['y'] + f['h'], f['x']:f['x'] + f['w']]
        np.maximum(region, ink(src / f'figures/{fid}.png'), out=region)
    out = base / 'godot/assets/doors/animation'
    out.mkdir(parents=True, exist_ok=True)
    y0, y1 = ROWS
    half = MIDDLE - BARS[0]
    if mode == 'slide':
        lines = (int(BARS[0] - 2.5), int(BARS[1] + 3.5))     # the bars' outer edges
        leaves = (('left', (lines[0], MIDDLE), -1), ('right', (MIDDLE, lines[1]), 1))
    else:
        lines = (int(round(BARS[0] - half)), int(round(BARS[1] + half)))
        leaves = (('left', (lines[0], MIDDLE), -1), ('right', (MIDDLE, lines[1]), 1))
    meta = dict(mode=mode, frames=FRAMES, leaves={})
    for name, (x0, x1), way in leaves:
        leaf = plate[y0:y1, x0:x1]
        key = f'spell161_door_{name}'
        if mode == 'slide':
            save(leaf, out / f'{key}.png')
            meta['leaves'][key] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0, way=way,
                                       offsets=[round(OPEN * ease(i / (FRAMES - 1)), 2) * way for i in range(FRAMES)])
            continue
        angles = [round(SWING * ease(i / (FRAMES - 1)), 2) for i in range(FRAMES)]
        inks, faces = [], []
        for angle in angles:
            hinged = leaf if way < 0 else leaf[:, ::-1]      # the right leaf is hinged at its right edge
            i, f = swing(hinged, angle)
            inks.append(i if way < 0 else i[:, ::-1])
            faces.append(f if way < 0 else f[:, ::-1])
        assert (inks[0] == leaf).all(), 'frame 0 must be the drawing'
        save_figure(np.hstack(inks), np.hstack(faces), out / f'{key}_swing.png')
        meta['leaves'][key] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0, hinge='left' if way < 0 else 'right',
                                   angles=angles)
    if mode == 'swing':
        meta['thoths'] = {}
        for n, cfg in THOTHS.items():
            box, inks, faces = thoth_frames(n, cfg, level, src, meta['leaves'], angles)
            save_figure(np.hstack(inks), np.hstack(faces), out / f'spell161_thoth_{n}_swing.png')
            meta['thoths'][f'spell161_thoth_{n}'] = box
            print(f'Thoth {n}: {len(inks)} frames, {box["w"]}x{box["h"]}')
    meta['behind'] = dict(    # what the split opens onto: solid ink over the leaves' whole rectangle, under them
        x=lines[0], y=y0, w=lines[1] - lines[0], h=y1 - y0)
    (out / f'doors_{mode}.json').write_text(json.dumps(meta, indent=1) + '\n')
    print(f'{mode}: two leaves, {FRAMES} frames')


if __name__ == '__main__':
    args = sys.argv[1:]
    if not args or args[0] not in ('slide', 'swing'):
        sys.exit(__doc__)
    base = ROOT
    if args[1:2] == ['--into']:
        base = Path(args[2]).resolve()
        assert ROOT not in base.parents and base != ROOT, '--into must be outside the repository'
    elif args[1:]:
        sys.exit(__doc__)
    main(args[0], base)
