"""The snake sheets of "Dangers on the road": the drawing moved along its own centre line, never redrawn.

    python .claude/skills/make-artwork/snakes.py turn      godot/assets/dangers      # spell 35's snake speared: front swings round
    python .claude/skills/make-artwork/snakes.py turn_over godot/assets/dangers      # spell 35's snake speared: head flips back
    python .claude/skills/make-artwork/snakes.py apep      godot/assets/dangers      # spell 39's Apep striking

All three read the cut figure (figures/snake35.png, figures/apep.png) and write beside the other sheets in
<out>/animation/. `turn` and `turn_over` also need spearers.json (spearers.py thrust). They share the
geometry: centerline() (the filled body, its centre line from the tail tip, half-widths), hermite() and
by_arc() (curves), and bend() (the drawing along one centre line laid onto another).

turn      Spell 35's snake speared: from creeping (head raised, right side up) to as drawn (head turned back).
          Creeping, his body lies along the ground and his neck rises, the head raised and facing forward (the
          drawn head mirrored). Speared on the head, the spear carries it down its own line while his front
          swings round in front of his body (seen side on, it narrows to nothing and widens again, flipped)
          and his body rises into its drawn arc; the head lands where it is drawn. His body and neck are bent
          along the drawing's own centre line, his front (neck end to head) is carried whole.
          snake35_turn.png: FRAMES cells in a row, the first creeping, the last the drawing itself.
          snake35_turn.json: the cell; per frame the spear's pose (spearers.json `poses`) and the pin (the head
          under the spear point) in cell px; where the drawing's top-left sits in the cell (so the last frame
          lines up with the drawn sprite).

turn_over Spell 35's snake speared, the head flipped back: from creeping (head raised, facing forward) to as
          drawn. (`turn` swings his whole front round in front of him instead.)
          Creeping, his body lies along the ground in waves and his neck rises high, the head facing forward
          (the drawn head mirrored) under the spear point drawn back. The spear strikes and knocks the head
          down; the head alone flips round where it is, to face back as drawn, his neck hooking over to it;
          then, as the spear carries it down its line, his neck and head cross down in front of his body while
          his body rises into its drawn arc, and the head lands where it is drawn. His body and neck are bent
          along the drawing's own centre line, the head is carried whole (as in `turn`).
          snake35_turn_over.png: the frames in a row, the first creeping, the last the drawing itself.
          snake35_turn_over.json: the cell; per frame the pin (the head's place under the spear point) in cell
          px; where the drawing's top-left sits in the cell (so the last frame lines up with the drawn sprite);
          and `creep`, the first frame on its own: its box in the cell, and in the box his tail tip, where his
          tail begins (for shaking it) and his front (the head's tip). DROP is also what strike35 in
          spearers.py follows.

apep      Spell 39's Apep striking: the part of him folded back under the spear point (the lower strand and his
          head) flips over about the fold like a turned page, to point forward, and then he straightens out and
          strikes straight ahead at the bearer (played backwards, he lies down again). His front (from the top
          strand just before the fold to his head) is laid along a centre line that moves, all in one piece. In
          the flip, the centre line past the tip of the fold is squeezed across it and out the other side, and
          the head with it, edge-on in between (only for a frame or two, and the flip is quick). Then the
          centre line eases from the turned-over shape to a straight strike (STRUCK, a smooth curve through a
          few points); the head rides on its end, the way the neck ends.
          apep_strike.png: a row of FRAMES cells; the first is his front as drawn.
          apep_strike_body.png: the drawing without his front (the body the waves run along).
          apep_strike.json: the cell; where the drawing's top-left sits in a cell (it may be left of it); where
          the front leaves the body (the drawing's px); per row, the last frame of the rear and of the swing.
"""
import heapq
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage as nd
from scipy.interpolate import CubicSpline
from scipy.spatial import cKDTree

sys.path.insert(1, str(Path(__file__).resolve().parents[3] / "tools"))
from cutlib import INK  # noqa: E402

SNAKE, APEP = "snake35", "apep"
PAD = 4
SEAM = 2                # front and neck (or body) overlap this much where they join (px)
FOLD = 188              # spell 35: the fold begins here, in px along the centre line from the tail tip
PIN = 300               # spell 35: the spear point holds the head here (px along the line)
SMOOTH = 12             # spell 35, creeping: his body keeps only the turns of the line quicker than this (px)


def load_figure(out_dir, name):
    """(out dir, the ink alpha of figures/<name>.png)."""
    out = Path(out_dir)
    return out, np.array(Image.open(out / "figures" / f"{name}.png").convert("RGBA"))[..., 3].astype(np.float32)


def spear_pose(out):
    """Spell 35's spear direction and how far it draws back (strip px), from spearers.json."""
    spear = json.loads((out / "animation" / "spearers.json").read_text())
    return np.array(spear["bearers"]["spear35"]["dir"]), float(spear["back"])


def nearest_index(alpha, solid, C):
    """For every pixel of the drawing (ink or filled body): the index of the nearest point of the centre line C
    (-1 elsewhere): which stretch of him it belongs to."""
    ys, xs = np.nonzero((alpha > 0) | solid)
    near = np.full(alpha.shape, -1)
    near[ys, xs] = cKDTree(C).query(np.stack([xs, ys], 1))[1]
    return near


def crop_box(cells):
    """x0, x1, y0, y1 round the ink of all the cells, PAD clear."""
    on = np.nonzero(np.max(cells, 0) > 0)
    return on[1].min() - PAD, on[1].max() + PAD + 1, on[0].min() - PAD, on[0].max() + PAD + 1


def save_ink(a, path):
    """The ink `a` (0..255 coverage) as the INK-coloured PNG `path`."""
    o = np.zeros(a.shape + (4,), np.uint8)
    o[..., :3] = INK
    o[..., 3] = np.clip(a, 0, 255)
    Image.fromarray(o).save(path)


def centerline(alpha, step=3.0):
    """The filled body, its centre line from the tail tip (leftmost) to the head 1 px apart, and the half-widths
    along it."""
    ink = alpha > 60
    closed = cv2.morphologyEx(ink.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8)) > 0
    solid = nd.binary_fill_holes(closed)
    h, w = solid.shape
    ys, xs = np.nonzero(solid)
    i = np.argmin(xs)
    start = (ys[i], xs[i])
    dist = np.full((h, w), np.inf)
    dist[start] = 0
    q = [(0.0, start)]
    nb = [(dy, dx, np.hypot(dy, dx)) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]
    while q:
        d, (y, x) = heapq.heappop(q)
        if d > dist[y, x]:
            continue
        for dy, dx, c in nb:
            yy, xx = y + dy, x + dx
            if 0 <= yy < h and 0 <= xx < w and solid[yy, xx] and d + c < dist[yy, xx]:
                dist[yy, xx] = d + c
                heapq.heappush(q, (d + c, (yy, xx)))
    pts = []
    for b in np.arange(0, dist[solid].max(), step):
        yy, xx = np.nonzero(solid & (dist >= b) & (dist < b + step))
        if len(xx):
            pts.append((xx.mean(), yy.mean()))
    pts = np.array(pts)
    sm = np.stack([nd.gaussian_filter1d(pts[:, k], 1.2, mode="nearest") for k in (0, 1)], 1)
    sm[0], sm[-1] = pts[0], pts[-1]
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(sm, axis=0), axis=1))]
    s = np.arange(0, seg[-1], 1.0)
    C = np.stack([np.interp(s, seg, sm[:, 0]), np.interp(s, seg, sm[:, 1])], 1)
    edt = nd.distance_transform_edt(solid)
    half = np.array([edt[max(int(y) - 2, 0):int(y) + 3, max(int(x) - 2, 0):int(x) + 3].max() for x, y in C])
    return solid, C, half


def angles(C):
    T = np.gradient(C, axis=0)
    return np.unwrap(np.arctan2(T[:, 1], T[:, 0]))


def by_arc(P, n):
    """`n` points evenly along the polyline P."""
    seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    u = np.linspace(0, seg[-1], n)
    return np.stack([np.interp(u, seg, P[:, 0]), np.interp(u, seg, P[:, 1])], 1)


def hermite(a, ta, z, tz, n, k=None):
    """`n` points evenly along the curve from a (heading ta) to z (heading tz); `k`: how far it holds each
    heading (default, by how far apart a and z are)."""
    k = 1.2 * np.linalg.norm(z - a) if k is None else k
    u = np.linspace(0, 1, 400)[:, None]
    H = ((2 * u ** 3 - 3 * u ** 2 + 1) * a + (u ** 3 - 2 * u ** 2 + u) * ta * k
         + (-2 * u ** 3 + 3 * u ** 2) * z + (u ** 3 - u ** 2) * tz * k)
    return by_arc(H, n)


def bend(img, C0, half, C1, shape):
    """The drawing `img` (along C0) bent onto C1 (as many points, the same places along him), into `shape`.
    Only the tail end is capped: past C1's last point is his front's."""
    th0, th1 = angles(C0), angles(C1)
    h, w = shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    p = np.stack([xx.ravel(), yy.ravel()], 1)
    d, i = cKDTree(C1).query(p)
    v = p - C1[i]
    t1 = np.stack([np.cos(th1[i]), np.sin(th1[i])], 1)
    u, n = (v * t1).sum(1), v[:, 1] * t1[:, 0] - v[:, 0] * t1[:, 1]
    ok = (d <= half[i] + 2.0) & ~((i == len(C1) - 1) & (u > SEAM))
    t0 = np.stack([np.cos(th0[i]), np.sin(th0[i])], 1)
    n0 = np.stack([-t0[:, 1], t0[:, 0]], 1)
    src = C0[i] + u[:, None] * t0 + n[:, None] * n0
    mx = np.where(ok, src[:, 0], -10).astype(np.float32).reshape(h, w)
    my = np.where(ok, src[:, 1], -10).astype(np.float32).reshape(h, w)
    return cv2.remap(img, mx, my, cv2.INTER_LINEAR, borderValue=0)


# --- turn: spell 35, the front swings round ---------------------------------------------------------

TURN_FRONT = 275        # his front, carried whole, from here to the head (px along the line)
TURN_NECK = 35          # creeping, his neck rises over this much ground (px)
TURN_SPIN = [0, 30, 60, 78, 105, 130, 155, 180]       # his front's turn at each frame (deg; 180 as drawn)
TURN_POSE = [-1, -1, -0.66, -0.66, -0.33, -0.33, 0, 0]  # the spear's pose at each frame: it carries the head down


def turn(out_dir):
    out, alpha = load_figure(out_dir, SNAKE)
    dv, back = spear_pose(out)
    solid, C, half = centerline(alpha)
    th = angles(C)
    # which of the drawing is his front (from TURN_FRONT on), which his body and neck
    near = nearest_index(alpha, solid, C)
    front_ink = np.where(near >= TURN_FRONT - SEAM, alpha, 0).astype(np.float32)
    front_solid = (solid & (near >= TURN_FRONT)).astype(np.float32)
    body_ink = np.where((near >= 0) & (near < TURN_FRONT + SEAM), alpha, 0).astype(np.float32)

    # a big canvas, cropped at the end; O: where the drawing's top-left is on it
    O = np.array([260.0, 60.0])
    H, W = int(alpha.shape[0] + 100), int(alpha.shape[1] + 320)
    to = lambda P: np.asarray(P) + O

    def front_at(pin, sx, P):
        """His front's points P with the spear point at `pin`, turned so its x is scaled by `sx`."""
        d = np.asarray(P) - C[PIN]
        return pin + np.stack([d[..., 0] * sx, d[..., 1]], -1)

    # creeping: his body along the ground (only its small turns), his neck rising to the raised head
    th_flat = th - nd.gaussian_filter1d(th, SMOOTH, mode="nearest")
    step = np.stack([np.cos(th_flat[:FOLD]), np.sin(th_flat[:FOLD])], 1)
    flat = np.r_[[[0.0, 0.0]], np.cumsum((step[1:] + step[:-1]) / 2, 0)]
    a = -np.arctan2(flat[-1, 1] - flat[0, 1], flat[-1, 0] - flat[0, 0])      # laid level
    flat = flat @ np.array([[np.cos(a), np.sin(a)], [-np.sin(a), np.cos(a)]])
    pin0 = C[PIN] + dv * back * TURN_POSE[0]
    z0 = front_at(pin0, -1.0, C[TURN_FRONT])
    flat += np.array([z0[0] - TURN_NECK, C[PIN, 1]]) - flat[-1]

    def neck(a, ta, z, tz):
        return hermite(a, ta / np.linalg.norm(ta), z, tz / np.linalg.norm(tz), TURN_FRONT - FOLD + 1)

    def front_dir(pin, sx):
        d = front_at(pin, sx, C[TURN_FRONT + 4]) - front_at(pin, sx, C[TURN_FRONT])
        return d if np.linalg.norm(d) > 0.5 else np.array([0.0, 1.0])

    # the drawn neck, less the curve that joins its ends as drawn: added back in full by the last frame
    drawn_neck = by_arc(C[FOLD - 1:TURN_FRONT + 1], TURN_FRONT - FOLD + 1)
    rest = drawn_neck - neck(C[FOLD - 1], C[FOLD - 1] - C[FOLD - 4], C[TURN_FRONT], C[TURN_FRONT + 4] - C[TURN_FRONT])

    cells, pins = [], []
    for spin, pose in zip(TURN_SPIN, TURN_POSE):
        lam = spin / 180.0
        pin = C[PIN] + dv * back * pose
        pins.append(pin)
        if spin == 180:     # as drawn
            cell = np.zeros((H, W), np.float32)
            cell[int(O[1]):int(O[1]) + alpha.shape[0], int(O[0]):int(O[0]) + alpha.shape[1]] = alpha
            cells.append(cell)
            continue
        sx = -np.cos(np.radians(spin))
        body = flat * (1 - lam) + C[:FOLD] * lam
        a, ta = body[-1], body[-1] - body[-4]
        z = front_at(pin, sx, C[TURN_FRONT])
        nk = neck(a, ta, z, front_dir(pin, sx)) + rest * lam ** 2
        line = np.r_[body[:-1], nk[:-1]]                    # TURN_FRONT points: C[0..TURN_FRONT-1]
        bod = bend(body_ink, C[:TURN_FRONT], half[:TURN_FRONT], to(line), (H, W))
        # his front, carried whole, turned in front of his body
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        mx = (C[PIN, 0] + (xx - O[0] - pin[0]) / sx).astype(np.float32)
        my = (C[PIN, 1] + (yy - O[1] - pin[1])).astype(np.float32)
        fr = cv2.remap(front_ink, mx, my, cv2.INTER_LINEAR, borderValue=0)
        cover = cv2.remap(front_solid, mx, my, cv2.INTER_LINEAR, borderValue=0) > 0.3
        if 0 < spin < 180:
            bod = np.where(cv2.dilate(cover.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0, 0, bod)
        cells.append(np.maximum(bod, fr))

    x0, x1, y0, y1 = crop_box(cells)
    cells = [c[y0:y1, x0:x1] for c in cells]
    sheet = np.concatenate(cells, 1)
    save_ink(sheet, out / "animation" / f"{SNAKE}_turn.png")
    shift = O - (x0, y0)
    (out / "animation" / f"{SNAKE}_turn.json").write_text(json.dumps({
        "cell": [int(x1 - x0), int(y1 - y0)], "frames": len(TURN_SPIN), "poses": TURN_POSE,
        "pins": [[round(float(v), 1) for v in p + shift] for p in pins],
        "drawn_at": [int(v) for v in shift]}, indent=1) + "\n")
    print(f"{SNAKE}_turn.png {sheet.shape[1]}x{sheet.shape[0]}")


# --- turn_over: spell 35, the head flips back ------------------------------------------------------

HEAD = 285              # his head, carried whole, from here on (px along the line from the tail tip)
OVER_FRONT = 245       # his neck and head, in front of his body, from here on (px along the line)
GROUND = 14             # creeping, his body lies this far below the drawn head (nearer us) (px)
WAVE = (14.0, 120.0)    # creeping, his body waves: by this much (deg), this long a wave (px), as drawn
HOOK = -20              # facing back, his body ends this far along from the pin, his neck hooking over (px)
# per frame: the head's width as it flips (-1 facing forward, 1 facing back as drawn); where the head is on the
# spear's line (as a pose: -1 at the point drawn back, 0 as drawn; once struck it goes down every frame, the spear
# taking the next of its poses at or below it); how far his body has gone toward its drawn line; his body's end (where the neck begins) above where it lies creeping
# (px); how much of him (from the head back) bends as his neck (px): creeping, less, so it rises sharply
FLIP = [-1, -1, -0.4, 0.4, 1, 1, 1, 1]
DROP = [-1, -0.66, -0.58, -0.5, -0.42, -0.3, -0.16, 0]
GO = [0, 0, 0.1, 0.2, 0.35, 0.55, 0.75, 0.9]
LIFT = [0, 0, 0, 0, 0, 16, 32, 50]
NECKS = [40, 40, 55, 70] + [HEAD - FOLD] * 4
TAIL = 100              # creeping, his tail is this much of him from the tip (px)


def turn_over(out_dir):
    out, alpha = load_figure(out_dir, SNAKE)
    dv, back = spear_pose(out)
    solid, C, half = centerline(alpha)
    th = angles(C)
    near = nearest_index(alpha, solid, C)
    head_ink = np.where(near >= HEAD - SEAM, alpha, 0).astype(np.float32)
    head_solid = (solid & (near >= HEAD)).astype(np.float32)
    # his neck (and the stretch of body just behind it, so they join) drawn in front of the rest of his body
    neck_ink = np.where((near >= OVER_FRONT - 10) & (near < HEAD + SEAM), alpha, 0).astype(np.float32)
    neck_solid = (solid & (near >= OVER_FRONT) & (near < HEAD)).astype(np.float32)
    body_ink = np.where((near >= 0) & (near < OVER_FRONT - 10 + SEAM), alpha, 0).astype(np.float32)

    O = np.array([260.0, 80.0])
    H, W = int(alpha.shape[0] + 140), int(alpha.shape[1] + 320)

    def head_at(pin, flip, P):
        """The head's points P (as drawn), `flip` wide (-1 mirrored), with its pin at `pin`."""
        d = np.asarray(P) - C[PIN]
        return pin + np.stack([d[..., 0] * flip, d[..., 1]], -1)

    # creeping: up to the head, the fold taken out and only the small turns of his line kept, in waves, laid level
    s = np.arange(HEAD)
    th_flat = th[:HEAD] - (th[np.clip(s, FOLD, HEAD)] - th[FOLD])
    th_flat = th_flat - nd.gaussian_filter1d(th_flat, SMOOTH, mode="nearest")
    th_flat = th_flat + np.radians(WAVE[0]) * np.sin(2 * np.pi * s / WAVE[1])
    step = np.stack([np.cos(th_flat), np.sin(th_flat)], 1)
    flat = np.r_[[[0.0, 0.0]], np.cumsum((step[1:] + step[:-1]) / 2, 0)]
    a = -np.arctan2(flat[-1, 1] - flat[0, 1], flat[-1, 0] - flat[0, 0])
    flat = flat @ np.array([[np.cos(a), np.sin(a)], [-np.sin(a), np.cos(a)]])
    ground = C[PIN, 1] + GROUND

    def neck(a, ta, z, tz, n, k=None):
        return hermite(a, ta / np.linalg.norm(ta), z, tz / np.linalg.norm(tz), n + 1, k)

    def length(P):
        return np.linalg.norm(np.diff(P, axis=0), axis=1).sum()

    # the drawn neck, less the curve that joins its ends as drawn: added back in full by the last frame
    full = HEAD - FOLD
    rest = by_arc(C[FOLD - 1:HEAD + 1], full + 1) - neck(C[FOLD - 1], C[FOLD - 1] - C[FOLD - 4], C[HEAD],
                                                         C[HEAD + 4] - C[HEAD], full)

    cells, pins = [], []
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    for flip, drop, go, lift, n in zip(FLIP, DROP, GO, LIFT, NECKS):
        pin = C[PIN] + dv * back * drop
        pins.append(pin)
        m = HEAD - n                                        # his body: C[0..m-1]
        body = (flat[:m] - flat[m - 1]) * (1 - go) + (C[:m] - C[m - 1]) * go
        ta = body[-1] - body[-4]
        z = head_at(pin, flip, C[HEAD])
        tz = head_at(pin, flip, C[HEAD + 4]) - z
        k = None
        if flip < 0:    # facing forward: his body slides back until his neck is as long as it is drawn
            for dx in np.arange(10.0, -200.0, -1.0):
                a = np.array([z[0] + dx, ground - lift])
                if length(neck(a, ta, z, tz, n)) >= n:
                    break
        else:           # facing back: his body's end under the head, his neck hooking round over to it
            a = np.array([pin[0] + HOOK, ground - lift])
        a = a + (C[m - 1] - a) * go ** 2
        if flip >= 0:
            for k in np.arange(5.0, 400.0, 1.0):
                if length(neck(a, ta, z, tz, n, k)) >= n:
                    break
        nk = neck(a, ta, z, tz, n, k) + (rest * go ** 2 if n == full else 0)
        line = np.r_[body[:-1] + a, nk] + O                 # HEAD points: C[0..HEAD-1]
        if not cells:
            creep = {"tail_tip": line[0], "tail_base": line[TAIL], "front": head_at(pin, flip, C[-1]) + O}
        bod = bend(body_ink, C[:HEAD], half[:HEAD], line, (H, W))
        nek = bend(neck_ink, C[:HEAD], half[:HEAD], line, (H, W))
        nek_cover = bend(neck_solid * 255, C[:HEAD], half[:HEAD], line, (H, W)) > 80
        # the head, carried whole: the drawing at each pixel's place, undone
        mx = (C[PIN, 0] + (xx - O[0] - pin[0]) / flip).astype(np.float32)
        my = (C[PIN, 1] + (yy - O[1] - pin[1])).astype(np.float32)
        hd = cv2.remap(head_ink, mx, my, cv2.INTER_LINEAR, borderValue=0)
        hd_cover = cv2.remap(head_solid, mx, my, cv2.INTER_LINEAR, borderValue=0) > 0.3
        # his neck and head in front of his body, the head in front of his neck
        hide = lambda im, cover: np.where(cv2.dilate(cover.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0, 0, im)
        cells.append(np.maximum.reduce([hide(bod, nek_cover | hd_cover), hide(nek, hd_cover), hd]))
    drawn = np.zeros((H, W), np.float32)
    drawn[int(O[1]):int(O[1]) + alpha.shape[0], int(O[0]):int(O[0]) + alpha.shape[1]] = alpha
    cells.append(drawn)
    pins.append(C[PIN])

    x0, x1, y0, y1 = crop_box(cells)
    sheet = np.concatenate([c[y0:y1, x0:x1] for c in cells], 1)
    save_ink(sheet, out / "animation" / f"{SNAKE}_turn_over.png")
    shift = O - (x0, y0)
    on = np.nonzero(cells[0][y0:y1, x0:x1] > 0)
    box = [int(on[1].min()), int(on[0].min()), int(on[1].max() - on[1].min() + 1), int(on[0].max() - on[0].min() + 1)]
    at = lambda p: [round(float(v), 1) for v in np.asarray(p) - (x0, y0) - box[:2]]
    (out / "animation" / f"{SNAKE}_turn_over.json").write_text(json.dumps({
        "cell": [int(x1 - x0), int(y1 - y0)], "frames": len(cells),
        "pins": [[round(float(v), 1) for v in p + shift] for p in pins],
        "drawn_at": [int(v) for v in shift],
        "creep": {"box": box, **{k: at(v) for k, v in creep.items()}}}, indent=1) + "\n")
    print(f"{SNAKE}_turn_over.png {sheet.shape[1]}x{sheet.shape[0]}")


# --- apep: spell 39 --------------------------------------------------------------------------------

BACK_FROM_TIP = 25      # his front leaves the body this far (px, along x) before the tip of the fold
HEAD_X = 432            # his head: from here to its snout, on the lower strand (drawing px)
FLIP_STEPS, STRIKE_STEPS = 5, 5  # frames in the flip, and in straightening out to strike
# the strike: the points the neck passes through after it leaves the body (the last is where the head
# begins), and the way the snout points (x, y); in the drawing's px, y down. The bearer stands to the right.
STRUCK = ([(482, 10), (508, 14), (534, 19), (560, 23)], (1.0, 0.12))
LOOSE = 60              # a bit of ink loose from him smaller than this (px) is dropped
SMOOTH_SRC = 4.0        # the drawing is read along its centre line smoothed this much (px), so that round
                        # the tight tip of the fold the lines across him do not cross
SMOOTH_TURN = 7.0       # turned over, his centre line is eased this much round the tip (px), not creased


def curve(points, n):
    """`n` points evenly along a smooth curve through `points`."""
    P = np.asarray(points, np.float64)
    u = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    s = CubicSpline(u, P, bc_type="natural")
    return by_arc(s(np.linspace(0, u[-1], 400)), n)


def apep(out_dir):
    out, alpha = load_figure(out_dir, APEP)
    solid, C, half = centerline(alpha)
    half = np.minimum(half, 1.25 * np.median(half))     # (round the fold, the hairpin's inside counts as body)
    tip = int(np.argmax(C[:, 0]))
    A = int(np.nonzero(C[:tip, 0] >= C[tip, 0] - BACK_FROM_TIP)[0][0])      # where the front leaves the body
    H = tip + int(np.nonzero(C[tip:, 0] <= HEAD_X)[0][0])                   # where the head begins
    near = nearest_index(alpha, solid, C)
    body_ink = np.where((near >= 0) & (near < A + SEAM), alpha, 0).astype(np.float32)
    neck_ink = np.where((near >= A - SEAM) & (near < H + SEAM), alpha, 0).astype(np.float32)
    head_ink = np.where(near >= H - SEAM, alpha, 0).astype(np.float32)

    # a big canvas, cropped at the end; O: where the drawing's top-left is on it
    O = np.array([20.0, 90.0])
    Hc, Wc = alpha.shape[0] + 130, alpha.shape[1] + 160
    yy, xx = np.mgrid[0:Hc, 0:Wc].astype(np.float64)
    n_neck = H - A + 1
    t0 = (C[H + 4] - C[H]) / np.linalg.norm(C[H + 4] - C[H])       # the snout's way, as drawn
    n0 = np.array([-t0[1], t0[0]])
    L = float(np.linalg.norm(np.diff(C[A:H + 1], axis=0), axis=1).sum())
    # the flip turns about the middle of the band at the tip of the fold
    cut = np.nonzero((near == tip) & ((alpha > 60) | solid))
    tx = float((cut[1].min() + cut[1].max()) / 2)
    cells = [np.zeros((Hc, Wc), np.float32)]
    cells[0][int(O[1]):int(O[1]) + alpha.shape[0], int(O[0]):int(O[0]) + alpha.shape[1]] = \
        np.maximum(neck_ink, head_ink)                     # as drawn
    lengths = [1.0]

    def turned(sx):
        """The drawn centre line, its part past the tip of the fold scaled across by `sx` about it."""
        P = C[A:H + 1].copy()
        P[tip - A:, 0] = tx + (P[tip - A:, 0] - tx) * sx
        if sx < 0.99:      # no crease at the tip: the turn eased in round it
            Q = np.stack([nd.gaussian_filter1d(P[:, k], SMOOTH_TURN, mode="nearest") for k in (0, 1)], 1)
            w = np.clip(1 - np.abs(np.arange(len(P)) - (tip - A)) / (3 * SMOOTH_TURN), 0, 1)[:, None]
            P = P * (1 - w) + Q * w
        return P

    C0 = np.stack([nd.gaussian_filter1d(C[A:H + 1, k], SMOOTH_SRC, mode="nearest") for k in (0, 1)], 1)

    def lay(nk, head):
        cell = np.maximum(bend(neck_ink, C0, half[A:H + 1], nk + O, (Hc, Wc)), head)
        # bits of ink left loose round the turned-over tip: drop them
        n_parts, parts, stats, _ = cv2.connectedComponentsWithStats((cell > 40).astype(np.uint8), connectivity=8)
        loose = [k for k in range(1, n_parts) if stats[k, cv2.CC_STAT_AREA] < LOOSE]
        return np.where(np.isin(parts, loose), 0, cell)

    # the flip: the turned-over part squeezed across the fold and out the other side, the head with it
    for i in range(1, FLIP_STEPS + 1):
        sx = float(np.cos(np.pi * i / FLIP_STEPS))
        sx = sx if abs(sx) > 0.08 else 0.08 * (1 if sx >= 0 else -1)
        nk = turned(sx)
        mx = (tx + (xx - O[0] - tx) / sx).astype(np.float32)
        my = (yy - O[1]).astype(np.float32)
        cells.append(lay(nk, cv2.remap(head_ink, mx, my, cv2.INTER_LINEAR, borderValue=0)))
        lengths.append(float(np.linalg.norm(np.diff(nk, axis=0), axis=1).sum()) / L)
    flipped = len(cells) - 1
    # straightening out: from the turned-over shape to the strike; the head, turned over, on its end
    M = turned(-1.0)
    S = curve([C[A]] + list(STRUCK[0]), n_neck)
    for i in range(1, STRIKE_STEPS + 1):
        k = 1 - (1 - i / STRIKE_STEPS) ** 2                   # quick at first, settling into the strike
        nk = M * (1 - k) + S * k
        t = nk[-1] - nk[-4]
        t = t / np.linalg.norm(t)
        n = np.array([-t[1], t[0]])
        q = np.stack([xx - O[0] - nk[-1][0], yy - O[1] - nk[-1][1]], -1)
        src = C[H] + (q @ t)[..., None] * t0 + (-(q @ n))[..., None] * n0
        hd = cv2.remap(head_ink, src[..., 0].astype(np.float32), src[..., 1].astype(np.float32),
                       cv2.INTER_LINEAR, borderValue=0)
        cells.append(lay(nk, hd))
        lengths.append(float(np.linalg.norm(np.diff(nk, axis=0), axis=1).sum()) / L)
    rows, marks = [cells], {"strike": {"reared": flipped, "swung": flipped}}
    print("neck length, of drawn:", " ".join(f"{v:.2f}" for v in lengths))

    x0, x1, y0, y1 = crop_box([c for r in rows for c in r])
    sheet = np.concatenate([np.concatenate([c[y0:y1, x0:x1] for c in r], 1) for r in rows], 0)
    save_ink(sheet, out / "animation" / f"{APEP}_strike.png")
    save_ink(body_ink, out / "animation" / f"{APEP}_strike_body.png")
    (out / "animation" / f"{APEP}_strike.json").write_text(json.dumps({
        "cell": [int(x1 - x0), int(y1 - y0)], "frames": len(rows[0]), "rows": list(marks),
        "drawn_at": [int(O[0] - x0), int(O[1] - y0)],
        "joint": [round(float(C[A, 0]), 1), round(float(C[A, 1]), 1)],
        "marks": marks}, indent=1) + "\n")
    print(f"{APEP}_strike.png {sheet.shape[1]}x{sheet.shape[0]}, front from x {C[A, 0]:.0f}, head from x {C[H, 0]:.0f}")


SHEETS = {"turn": turn, "turn_over": turn_over, "apep": apep}

if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in SHEETS:
        sys.exit("usage: python .claude/skills/make-artwork/snakes.py " + "|".join(SHEETS) + " <dangers assets dir>")
    SHEETS[sys.argv[1]](sys.argv[2])
