"""The spear-bearers of "Dangers on the road" (spells 31-41) as sprite sheets: three sheets from one cutting.

    python .claude/skills/make-artwork/spearers.py thrust   art/dangers31-42.mdp godot/assets/dangers [spear35 ...]
    python .claude/skills/make-artwork/spearers.py lean     art/dangers31-42.mdp godot/assets/dangers
    python .claude/skills/make-artwork/spearers.py strike35 art/dangers31-42.mdp godot/assets/dangers

All three leave the man as drawn (the art is moved, never redrawn) and write beside the other sheets in
<out>/animation/. They share split() (a bearer cut from the MDP: his ink, and his spear in pieces along its
axis), pose() and bowed() (the spear moved along its axis, or along its own bowed line).

thrust    The thrust of every bearer, as one sheet. The man stays exactly as drawn. His spear is the ink under
          the red `spear` clipping layer above each spearer in art/dangers31-42.mdp; only its ends move: the
          arrowhead and the hook slide along the spear's axis and the shaft between them is lengthened or
          trimmed (nothing of the man is cut).
          spearers.png: one row per bearer (ROWS), CW x CH cells, each bearer's drawn box centred PAD above the
          cell's bottom edge. Columns 0..7 are the figure in POSES (-1 drawn back: a little back and up the
          axis; 0 as drawn; 1 the full strike, REACH past it); columns 8..15 are the spear alone in the same
          poses, a mask for tinting it red (heka). spearers.json has the layout and each spear's drawn tip
          and direction (strip px). A spear that bows (BOWED) moves whole along its own bowed line instead.
          Naming bearers redraws only their rows in the existing sheet (spearers.json is left as it is).

lean      Spell 41's bearer leaning in to strike each of the sheaf's four bands.
          The four bands lie on the spear's own line, so the spear only slides along its axis (its direction
          never changes) until its point rests on the band, 2 px in, as drawn at the top band. He bends at the
          hip, his feet and hem planted; his hands keep to the spear's line and his elbows follow (two-bone,
          bending as drawn). The man is moved by a rigid moving-least-squares warp of his drawn ink; the spear
          is split from him as in thrust, and the gaps it leaves in his lines are bridged. Needs spearers.json.
          spear41_lean.png: one row per band (top first), each a spearers.png row: columns 0..7 the figure in
          POSES (-1 drawn back, 0 resting on the band, 1 the full strike), columns 8..15 the spear alone in the
          same poses (the mask for tinting it red).
          spear41_lean_steps.png: the in-betweens from each band to the next, the spear drawn back as it rests
          in a fight (STEPS - 1 per step), then their spear masks; `between` in the json gives each one's place
          (1.25 = a quarter of the way from band 2 to band 3).
          spear41_lean.json: the layout, the cell's window on the strip, and the point's place at each band.

strike35  Spell 35's bearer pinning the snake's head, frame for frame with snake35_turn_over.png.
          The first frame: his spear at rest in a fight, drawn back. A thrust (spearers.png's poses) runs it
          out to the full strike; there it meets the head, and from then on the point goes on down a little
          deeper than the head every frame, so it is the spear that carries the head down. His spear bows, so
          it moves whole along its own bowed line (bowed()).
          spear35_strike.png: a cell per frame of snake35_turn_over.png (spearers.png's cell, the bearer where
          he is there), then the spear alone in each (the mask for tinting it red).
          spear35_strike.json: the layout; how far the spear is moved along its axis at each frame (strip px;
          + out); and `along`: how far along the spear's axis (strip px; + out) the snake lies from where it is
          drawn, for its head to be DEEP under the point at the full strike.
"""
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

TOOLS = Path(__file__).resolve().parents[3] / "tools"
sys.path[1:1] = [str(TOOLS), str(TOOLS / "mdp300")]
from mdp import read_mdp, decode_layer  # noqa: E402
from cutlib import INK  # noqa: E402

ROWS = {  # sprite: mdp folder, spearer layer (the red `spear` clipping layer sits right above it)
    "spear31": ("crocs31", "spearer1"), "spear32": ("crocs32", "spearer2"), "spear33": ("snake33", "spearer1"),
    "spear35": ("snake35", "spearer2"), "spear36": ("roach36", "spearer"), "spear37": ("snake37", "spearer3"),
    "spear39": ("snake39", "spearer4"), "spear40": ("snakeass40", "spearer"), "spear41": ("snake41", "spearer5")}
CW, CH, PAD = 336, 415, 30
POSES = [-1, -0.66, -0.33, 0, 0.25, 0.5, 0.75, 1]
BACK, REACH = 14.0, 15.0     # strip px the ends go back (up the axis) / out; REACH = dangers.gd CROC_THRUST * 1.5
BOWED = {"spear35"}     # spears that bow: moved whole along their own line (bowed())
SPECK = 60              # (bowed) ink of his this small, by the spear near its point, is the spear's (px)


def load(mdp_path, out_dir):
    """(out/animation, level.json, the MDP's layers, by id, and a layer's BGRA pixels) for the sheets."""
    out = Path(out_dir)
    level = json.loads((out / "level.json").read_text())
    W, H, L, C, _ = read_mdp(mdp_path)
    byid = {l["id"]: l for l in L}

    def img(l):
        return decode_layer(C[l["bin"]], int(l["width"]), int(l["height"]), "32bpp")[..., [2, 1, 0, 3]].astype(np.float32)

    (out / "animation").mkdir(parents=True, exist_ok=True)
    return out / "animation", level, L, byid, img


def save_sheet(a, path):
    """The ink `a` (0..255 coverage, cells in a row or column) as the INK-coloured sheet `path`."""
    o = np.zeros(a.shape + (4,), np.uint8)
    o[..., :3] = INK
    o[..., 3] = np.clip(a, 0, 255)
    Image.fromarray(o).save(path)
    print(f"{path.name} {a.shape[1]}x{a.shape[0]}")


def split(L, byid, img, level, name, folder, spearer):
    """One bearer's cell (CW x CH round his drawn box): his ink, and his spear in pieces along its axis
    (shaft, arrowhead, hook), the strokes of his that cross it in both. Used by all three sheets."""
    i = next(i for i, l in enumerate(L) if l["name"] == spearer and l["parentId"] != "-1"
             and byid[l["parentId"]]["name"] == folder)
    red_l = L[i + 1]
    assert red_l["clipping"] == "true" and red_l["parentId"] == L[i]["parentId"], f"no spear layer above {folder}/{spearer}"
    s = level["sprites"][name]
    bx, by, bw, bh = s["x"], s["y"], s["w"], s["h"]
    ox, oy = (CW - bw) // 2, CH - PAD - bh
    X0, Y0 = bx - ox, by - oy                 # the cell's window on the strip
    f = img(L[i])[Y0:Y0 + CH, X0:X0 + CW]
    a = (255 - f[..., :3].mean(-1)) * f[..., 3] / 255
    a[:oy] = 0; a[oy + bh:] = 0; a[:, :ox] = 0; a[:, ox + bw:] = 0     # only what the game shows
    for y in range(oy, oy + 8):               # a bit of the frame line caught along the top
        if (a[y, ox:ox + bw] > 90).mean() > 0.3:
            a[max(0, y - 2):y + 3] = 0
    sp = (a > 0) & (img(red_l)[Y0:Y0 + CH, X0:X0 + CW, 3] > 0)
    yy, xx = np.mgrid[0:CH, 0:CW].astype(np.float32)
    ys, xs = np.nonzero(sp)
    P = np.stack([xs, ys], 1).astype(float); c = P.mean(0)
    dv = np.linalg.svd(P - c, full_matrices=False)[2][0]
    if dv[1] < 0: dv = -dv                       # towards the point
    t = (xx - c[0]) * dv[0] + (yy - c[1]) * dv[1]
    nrm = np.array([-dv[1], dv[0]])
    tp, op = (P - c) @ dv, (P - c) @ nrm
    # the arrowhead begins where the spear gets wide near the point; the hook where it bends away
    bins = np.arange(np.floor(tp.min()), np.ceil(tp.max()) + 1, 3)
    wide = [(b, np.ptp(op[(tp >= b) & (tp < b + 3)]) if ((tp >= b) & (tp < b + 3)).any() else 0) for b in bins]
    core = np.median([wd for _, wd in wide])
    t_head = next(b for b, wd in wide if b > 0 and wd > core * 2.5)
    off_mid = np.median(op)
    dev = [(b, abs(np.median(op[(tp >= b) & (tp < b + 3)]) - off_mid) if ((tp >= b) & (tp < b + 3)).any() else 9.0) for b in bins]
    t_hook = next(dev[i][0] for i in range(len(dev) - 3) if all(d < 2.0 for _, d in dev[i:i + 4]))   # straight from here down
    # strokes of the man that cross the shaft (a fist round it, an arm over it): ink of his on both
    # sides of the shaft, a little off it. They stay with him and go with the spear as well
    def his(dx, dy):
        m = (a > 60) & ~sp
        out = np.zeros_like(m)
        out[max(0, dy):min(CH, CH + dy), max(0, dx):min(CW, CW + dx)] = m[max(0, -dy):min(CH, CH - dy), max(0, -dx):min(CW, CW - dx)]
        return out
    k = 5
    cross = sp & his(int(round(nrm[0] * k)), int(round(nrm[1] * k))) & his(int(round(-nrm[0] * k)), int(round(-nrm[1] * k)))
    cross = cv2.dilate(cross.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) & sp
    # what of the spear touches his ink (the fist's edge) is kept for him as well; faint fringe of
    # the spear that is not his is the spear's
    his_ink = (a > 60) & ~sp
    touch = cv2.dilate(his_ink.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool)
    near_spear = cv2.dilate(sp.astype(np.uint8), np.ones((7, 7), np.uint8)).astype(bool)
    n_c, lab_c = cv2.connectedComponents(((a > 0) & ~sp).astype(np.uint8), connectivity=8)
    strong = np.zeros(n_c, bool); strong[np.unique(lab_c[his_ink])] = True
    fringe = (a > 0) & ~sp & near_spear & ~strong[lab_c]
    sp = sp | fringe
    body = np.where(sp & ~(cross | (touch & (a > 60))), 0, a); spear = np.where(sp, a, 0)   # crossings in both
    clean = np.ones_like(t, bool)       # where along the shaft there are no crossings to copy from
    crossing_t = t[cross]
    band = lambda im, lo, hi: np.where((t >= lo) & (t < hi), im, 0)
    def shift(im, s):
        dx, dy = int(round(dv[0] * s)), int(round(dv[1] * s))
        out = np.zeros_like(im)
        out[max(0, dy):min(CH, CH + dy), max(0, dx):min(CW, CW + dx)] = im[max(0, -dy):min(CH, CH - dy), max(0, -dx):min(CW, CW - dx)]
        return out
    # the ends: past the shaft, and anything of the spear well off its line near them (the barbs reach
    # back along the shaft, the hook curls off it)
    o_px = (xx - c[0]) * nrm[0] + (yy - c[1]) * nrm[1] - off_mid
    off_line = np.abs(o_px) > 6
    is_head = (t >= t_head) | (off_line & (t >= t_head - 60))
    is_hook = (t < t_hook) | (off_line & (t < t_hook + 25))
    head = np.where(is_head, spear, 0); hook = np.where(is_hook & ~is_head, spear, 0)
    shaft = np.where(~is_head & ~is_hook, spear, 0)
    return {k: v for k, v in locals().items() if k in (
        'body', 'head', 'hook', 'shaft', 't', 'dv', 'nrm', 'c', 'xs', 'ys',
        'tp', 't_head', 't_hook', 'crossing_t', 'band', 'shift', 'X0', 'Y0', 'ox', 'oy')}


def pose(g, s):
    """A bearer (split()) with his spear moved `s` strip px along its axis (- back up it, + out): the figure,
    and the spear alone. Used by strike35."""
    body, head, hook, shaft, crossing_t, band, shift, t_head, t_hook = (g[k] for k in (
        'body', 'head', 'hook', 'shaft', 'crossing_t', 'band', 'shift', 't_head', 't_hook'))

    def clean_from(lo, step, length):
        """Start of the nearest stretch of shaft of `length` from `lo` (moving by `step`) crossed by nothing."""
        while any((crossing_t >= lo - 1) & (crossing_t < lo + length + 1)) and t_hook <= lo <= t_head - length:
            lo += step
        return lo
    J = 1.5      # the pieces overlap this much at each join, so no seam opens between them
    sh = band(shaft, t_hook + s - J, t_head + s + J)
    if s > 0:    # the next stretch of shaft, repeated: from the nearest stretch with nothing crossing it
        src = clean_from(t_head - s, -1, s)
        sh = np.maximum(sh, band(shift(band(shaft, src - J, src + s + J), t_head - src), t_head - J, t_head + s + J))
    elif s < 0:
        src = clean_from(t_hook, 1, -s)
        sh = np.maximum(sh, band(shift(band(shaft, src - J, src - s + J), t_hook + s - src), t_hook + s - J, t_hook + J))
    m = np.maximum.reduce([sh, shift(head, s), shift(hook, s)])
    return np.maximum(body, m), m


def bowed(g):
    """The bearer (split()) and his whole spear, its ink by the point given back to it, and a function moving it
    `s` along its own bowed line: each pixel `s` along the axis, keeping its distance from the bow. Used by
    strike35."""
    t, c, dv, nrm = g["t"], g["c"], g["dv"], g["nrm"]
    body = g["body"].copy()
    spear = np.maximum.reduce([g["head"], g["hook"], g["shaft"]])
    near = cv2.dilate((spear > 40).astype(np.uint8), np.ones((15, 15), np.uint8)) > 0
    n, lab, stats, _ = cv2.connectedComponentsWithStats((body > 0).astype(np.uint8), connectivity=8)
    for i in range(1, n):
        m = lab == i
        if stats[i, cv2.CC_STAT_AREA] < SPECK and near[m].all() and t[m].mean() > g["t_head"] - 40:
            spear = np.maximum(spear, np.where(m, body, 0))
            body[m] = 0
    yy, xx = np.mgrid[0:CH, 0:CW].astype(np.float32)
    o = (xx - c[0]) * nrm[0] + (yy - c[1]) * nrm[1]
    sh = g["shaft"] > 60
    bow = np.poly1d(np.polyfit(t[sh], o[sh], 2))      # the shaft's distance from the axis, along it

    def move(s):
        src_t = t - s
        src_o = o - bow(t) + bow(src_t)
        mx = (c[0] + src_t * dv[0] + src_o * nrm[0]).astype(np.float32)
        my = (c[1] + src_t * dv[1] + src_o * nrm[1]).astype(np.float32)
        return cv2.remap(spear.astype(np.float32), mx, my, cv2.INTER_LINEAR, borderValue=0)
    return body, move



def thrust(mdp_path, out_dir, *only):
    anim, level, L, byid, img = load(mdp_path, out_dir)
    rows, meta = [], {"cell": [CW, CH], "pad": PAD, "poses": POSES, "rest": POSES.index(0), "back": BACK,
                      "reach": REACH, "bearers": {}}
    for r, (name, (folder, spearer)) in enumerate(ROWS.items()):
        if only and name not in only:
            rows.append(None)
            continue
        g = split(L, byid, img, level, name, folder, spearer)
        dv, xs, ys, tp, X0, Y0, ox, oy = (g[k] for k in ('dv', 'xs', 'ys', 'tp', 'X0', 'Y0', 'ox', 'oy'))
        offsets = [p * BACK if p < 0 else p * REACH for p in POSES]
        if name in BOWED:
            body, move = bowed(g)
            masks = [move(s) for s in offsets]
            figs = [np.maximum(body, m) for m in masks]
        else:
            figs, masks = zip(*(pose(g, s) for s in offsets))
        rows.append(np.concatenate(list(figs) + list(masks), 1))
        tip = np.array([xs[np.argmax(tp)], ys[np.argmax(tp)]], float)      # the spear's point, as drawn
        meta["bearers"][name] = {"row": r, "ox": ox, "oy": oy, "tip": [round(X0 + tip[0], 1), round(Y0 + tip[1], 1)],
                                 "dir": [round(float(dv[0]), 4), round(float(dv[1]), 4)]}
        print(f"{name}: arrowhead from {g['t_head']:.0f}, hook to {g['t_hook']:.0f} along the axis")
    if only:            # only these rows, into the sheet as it is
        o = np.array(Image.open(anim / "spearers.png"))
        for r, row in enumerate(rows):
            if row is not None:
                o[r * CH:(r + 1) * CH, :, :3] = INK
                o[r * CH:(r + 1) * CH, :, 3] = np.clip(row, 0, 255)
        Image.fromarray(o).save(anim / "spearers.png")
        print(f"spearers.png: redrew {', '.join(only)}")
        return
    save_sheet(np.concatenate(rows, 0), anim / "spearers.png")
    (anim / "spearers.json").write_text(json.dumps(meta, indent=1))


# --- lean: spell 41's bearer leaning in to each band -----------------------------------------------

LEAN = "spear41"

BANDS = [f"sheaf41_band{i}" for i in (1, 2, 3, 4)]   # top to bottom
STEPS = 4                       # frames from one band to the next (the last is the band itself)
# the man, in cell px. Fixed: feet, hem and shins. The trunk and head turn about the hip.
P_HIP = np.array([195.0, 225.0])
FIXED = [(130, 380), (172, 380), (222, 382), (258, 368), (135, 346), (250, 346), (140, 300), (245, 300)]
APRON = [(152, 252), (202, 252), (180, 250)]        # hangs from the belt: goes with the hip
TORSO = [(195, 150), (190, 123), (192, 106), (176, 130), (205, 125), (200, 180), (180, 190), (215, 190),
         (190, 218), (214, 212), (166, 228)]
ARMS = {"raised": [(215, 145), (245, 142), (243, 88)],   # shoulder, elbow, hand
        "lower": [(163, 160), (148, 228), (100, 240)]}
KEY_PHI = [0, -7, -14, -21]                          # the trunk's lean at each band (deg)
KEY_HIP = [(0, 0), (-3, 2), (-6, 5), (-9, 8)]        # the hip's give at each band (px)
SHAFT_PIECE = 20.0              # the clean stretch of shaft repeated along the axis
BARB_REACH = 16                 # the arrowhead's barbs: this far either side of the shaft ...
BARB_FROM = 9                   # ... from this far past the lower fist



def interp(keys, lam):
    i = min(int(np.floor(lam)), len(keys) - 2)
    a, b = np.array(keys[i], float), np.array(keys[i + 1], float)
    return a + (b - a) * (lam - i)


def cross2(a, b):
    return a[0] * b[1] - a[1] * b[0]


def elbow(s, h, s0, e0, h0):
    """Where the elbow goes for shoulder s and hand h, the arm's two lengths kept, bent as drawn."""
    l1, l2 = np.linalg.norm(e0 - s0), np.linalg.norm(h0 - e0)
    v = h - s
    dist = np.linalg.norm(v)
    if dist >= l1 + l2 - 0.5:
        return s + v * l1 / (l1 + l2)
    a = (l1 ** 2 - l2 ** 2 + dist ** 2) / (2 * dist)
    hgt = np.sqrt(max(l1 ** 2 - a ** 2, 0))
    u = v / dist
    perp = np.array([-u[1], u[0]])
    side = np.sign(cross2(h0 - s0, e0 - s0)) or 1
    e = s + u * a + perp * hgt
    if np.sign(cross2(h - s, e - s)) != side:
        e = s + u * a - perp * hgt
    return e


def mls_rigid(src, dst, xx, yy, alpha=1.6):
    """Rigid moving-least-squares warp (Schaefer et al. 2006), as a backward map: for each output
    pixel, where to read the drawing. `src` are points on the drawing, `dst` where they go."""
    v = np.stack([xx.ravel(), yy.ravel()], 1).astype(np.float64)
    p, q = dst, src
    w = 1.0 / (np.sum((p[None] - v[:, None]) ** 2, -1) ** alpha + 1e-8)
    ws = w.sum(1, keepdims=True)
    ps, qs = (w @ p) / ws, (w @ q) / ws
    ph, qh = p[None] - ps[:, None], q[None] - qs[:, None]
    vp = v - ps
    vperp = np.stack([-vp[..., 1], vp[..., 0]], -1)
    a1 = np.sum(ph * vp[:, None], -1)
    a2 = np.sum(ph * vperp[:, None], -1)
    fr = np.stack([np.sum(w * (qh[..., 0] * a1 + qh[..., 1] * a2), 1),
                   np.sum(w * (qh[..., 1] * a1 - qh[..., 0] * a2), 1)], 1)
    out = np.linalg.norm(vp, axis=1, keepdims=True) * fr / (np.linalg.norm(fr, axis=1, keepdims=True) + 1e-9) + qs
    shape = xx.shape
    return out[:, 0].reshape(shape).astype(np.float32), out[:, 1].reshape(shape).astype(np.float32)


class Bearer:
    def __init__(self, g, sprites, tip):
        self.dv, self.c, self.t = g["dv"], g["c"], g["t"]
        self.X0, self.Y0 = g["X0"], g["Y0"]
        self.yy, self.xx = np.mgrid[0:CH, 0:CW].astype(np.float32)
        head, hook, shaft, body = (g[k].astype(np.float32) for k in ("head", "hook", "shaft", "body"))
        spear = np.maximum.reduce([head, hook, shaft])
        t, dv, c = self.t, self.dv, self.c
        nrm = np.array([-dv[1], dv[0]])
        o = (self.xx - c[0]) * nrm[0] + (self.yy - c[1]) * nrm[1]
        o_mid = np.median(o[shaft > 0])
        # the arrowhead's barbs reach back to his lower fist and were given to him: past it they are the spear's
        t_fist = float((np.array(ARMS["lower"][2], float) - c) @ dv)
        barbs = (t > t_fist + BARB_FROM) & (np.abs(o - o_mid) < BARB_REACH) & (body > 0)
        self.head = np.maximum(head, np.where(barbs, body, 0))
        body = np.where(barbs, 0, body)
        # the gaps the shaft leaves in his lines, bridged
        gaps = ((spear > 0) & (body < 30)).astype(np.uint8)
        b = cv2.inpaint(np.clip(body, 0, 255).astype(np.uint8), cv2.dilate(gaps, np.ones((2, 2), np.uint8)), 2,
                        cv2.INPAINT_TELEA).astype(np.float32)
        self.body = np.where(b < 25, 0, b)
        self.hook = hook
        # a clean shaft: one stretch with nothing crossing it, repeated along the axis
        self.t_hook, self.t_head = g["t_hook"], g["t_head"]
        lo = self.t_hook + 10
        while np.any((g["crossing_t"] >= lo - 2) & (g["crossing_t"] <= lo + SHAFT_PIECE + 2)):
            lo += 1
        self.lo = lo
        self.piece = np.where((t >= lo) & (t < lo + SHAFT_PIECE) & (np.abs(o - o_mid) < 4), shaft, 0)
        # the point rests on each band 2 px in, as drawn on the top one
        self.tip = np.array(tip, float) - (self.X0, self.Y0)
        self.s_band = [((sprites[b]["y"] + 2 - self.Y0) - self.tip[1]) / dv[1] for b in BANDS]
        self._maps = {}

    def shift(self, im, s):
        M = np.float32([[1, 0, self.dv[0] * s], [0, 1, self.dv[1] * s]])
        return cv2.warpAffine(im, M, (CW, CH), flags=cv2.INTER_LINEAR)

    def shaft(self, a, b):
        out = np.zeros_like(self.piece)
        k = a - self.lo
        while self.lo + k < b:
            out = np.maximum(out, self.shift(self.piece, k))
            k += SHAFT_PIECE - 1          # overlap a pixel so no seam opens
        return np.where((self.t >= a - 1) & (self.t < b + 1), out, 0)

    def spear(self, s):
        return np.maximum.reduce([self.shift(self.head, s), self.shift(self.hook, s),
                                  self.shaft(self.t_hook + s, self.t_head + s)])

    def rot(self, p, phi, hip):
        r = np.radians(phi)
        R = np.array([[np.cos(r), -np.sin(r)], [np.sin(r), np.cos(r)]])
        return R @ (np.asarray(p, float) - P_HIP) + P_HIP + hip

    def on_line(self, p):
        """The spear slides along its own axis, so its line stays put: the hands keep to it."""
        return self.tip + self.dv * ((np.asarray(p) - self.tip) @ self.dv)

    def warp(self, lam):
        phi, hip = float(interp([[p] for p in KEY_PHI], lam)[0]), interp(KEY_HIP, lam)
        src, dst = [], []
        for p in FIXED:
            src.append(p); dst.append(p)
        for p in APRON:
            src.append(p); dst.append(np.asarray(p) + hip * 0.8)
        for p in TORSO:
            src.append(p); dst.append(self.rot(p, phi, hip))
        for s0, e0, h0 in (np.array(v, float) for v in ARMS.values()):
            s = self.rot(s0, phi, hip)
            h = self.on_line(self.rot(h0, phi, hip))
            e = elbow(s, h, s0, e0, h0)
            for f in (0.0, 0.5, 1.0):
                src.append(s0 + (e0 - s0) * f); dst.append(s + (e - s) * f)
                src.append(e0 + (h0 - e0) * f); dst.append(e + (h - e) * f)
        return mls_rigid(np.array(src, float), np.array(dst, float), self.xx, self.yy)

    def figure(self, lam, p=0.0):
        """Leaning to band `lam` (0 top .. 3 bottom; between bands for the steps), in thrust pose p.
        Returns the figure and the spear alone."""
        key = round(lam, 3)
        if key not in self._maps:
            self._maps[key] = self.warp(lam)
        mx, my = self._maps[key]
        man = cv2.remap(self.body, mx, my, cv2.INTER_LINEAR, borderValue=0)
        s = float(interp([[s] for s in self.s_band], lam)[0]) - self.s_band[0]
        s += p * BACK if p < 0 else p * REACH
        sp = self.spear(s)
        return np.maximum(man, sp), sp


def lean(mdp_path, out_dir):
    anim, level, L, byid, img = load(mdp_path, out_dir)
    tip = json.loads((anim / "spearers.json").read_text())["bearers"][LEAN]["tip"]
    folder, spearer = ROWS[LEAN]
    g = split(L, byid, img, level, LEAN, folder, spearer)
    man = Bearer(g, level["sprites"], tip)

    def row(lam, poses):
        pairs = [man.figure(lam, p) for p in poses]
        return np.concatenate([f for f, _ in pairs] + [m for _, m in pairs], 1)

    save_sheet(np.concatenate([row(k, POSES) for k in range(len(BANDS))], 0), anim / f"{LEAN}_lean.png")
    between = [k + i / STEPS for k in range(len(BANDS) - 1) for i in range(1, STEPS)]
    steps = [man.figure(lam, POSES[0]) for lam in between]     # drawn back, as it rests in a fight
    save_sheet(np.concatenate([f for f, _ in steps] + [m for _, m in steps], 1), anim / f"{LEAN}_lean_steps.png")
    tips = [[round(float(man.tip[0] + man.dv[0] * s + man.X0), 1), round(float(man.tip[1] + man.dv[1] * s + man.Y0), 1)]
            for s in man.s_band]
    (anim / f"{LEAN}_lean.json").write_text(json.dumps({
        "cell": [CW, CH], "pad": PAD, "poses": POSES, "rest": POSES.index(0), "back": BACK, "reach": REACH,
        "window": [int(man.X0), int(man.Y0)], "ox": int(g["ox"]), "oy": int(g["oy"]),
        "dir": [round(float(x), 4) for x in man.dv], "bands": BANDS, "tips": tips,
        "steps": STEPS, "step_pose": POSES[0], "between": between}, indent=1) + "\n")


# --- strike35: spell 35's bearer pinning the snake's head ------------------------------------------

STRIKE = "spear35"
DEEP = 4.0              # struck, the point this far deeper than the head (strip px)


def strike35(mdp_path, out_dir):
    from snakes import DROP
    anim, level, L, byid, img = load(mdp_path, out_dir)
    g = split(L, byid, img, level, STRIKE, *ROWS[STRIKE])
    # the head goes down its line DROP (x BACK) from the strike on; the last frame is the snake as drawn
    offsets = [-BACK] + [REACH + (d - DROP[1]) * BACK for d in DROP[1:]] + [REACH - DROP[1] * BACK]
    body, move = bowed(g)
    masks = [move(s) for s in offsets]
    figs = [np.maximum(body, m) for m in masks]
    save_sheet(np.concatenate(figs + masks, 1), anim / f"{STRIKE}_strike.png")
    (anim / f"{STRIKE}_strike.json").write_text(json.dumps({
        "cell": [CW, CH], "frames": len(offsets), "ox": int(g["ox"]), "oy": int(g["oy"]),
        "offsets": [round(float(s), 2) for s in offsets],
        "along": round(float(REACH - DEEP - DROP[1] * BACK), 2)}, indent=1) + "\n")


SHEETS = {"thrust": thrust, "lean": lean, "strike35": strike35}

if __name__ == "__main__":
    if len(sys.argv) < 4 or sys.argv[1] not in SHEETS:
        sys.exit("usage: python .claude/skills/make-artwork/spearers.py " + "|".join(SHEETS) + " <dangers.mdp> <out dir> [spear35 ...]")
    SHEETS[sys.argv[1]](*sys.argv[2:])
