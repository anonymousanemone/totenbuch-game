"""Side-column vignettes (stacked boxes, like pl. VI's left column = bod16) at 300 dpi.

For each region below, the boxes inside are found from the rule lines, cleaned, scaled 1.5x
and stacked top-to-bottom in a portrait file, each box its own layer, with pixel-perfect frame
guides around every box (same guide colour and 6 px line width as the strips). Right above each
box layer is a hidden "<box> rest" layer with what the cut left out around it (as in the strips).
The full pages of spells 110 (pl. XLI) and 125 (pl. L) are done by hand in art/ and not made here.

    python .claude/skills/splice-plates/strips/panels.py <out dir>
"""
import json, os, sys
import numpy as np
from scipy import ndimage as ndi

from detect import page, plate, runs_mask
import build_strips as bs

# name -> (plate, (x0, x1, y0, y1) region in plate px, spells, note)
REGIONS = {
    "110a_pl40":  (40, (822, 1246, 1045, 1875), "110", "adoring figure"),
    "110_pl42":   (42, (572, 1096, 222, 1893), "110", "Field of Reeds panels", {"rows": [(260, 662), (712, 1081), (1132, 1482), (1533, 1879)]}),
    "110a_pl42":  (42, (1088, 1454, 1095, 1893), "110", "adoring figure"),
    "142-143_pl59": (59, (104, 444, 226, 1934), "142-143", "left column", "nosplit"),
    "149-150_pl73": (73, (72, 604, 234, 1904), "149-150", "mounds of 150"),
    "151-153_pl74": (74, (1386, 1879, 96, 1904), "151", "right column a/c/e"),
    "148_pl70":   (70, (60, 1110, 440, 1885), "148", "cows and rudders grid"),
    "148b_pl70":  (70, (1110, 1930, 440, 1885), "148", "offering scene", "nosplit"),
    "157-161_pl76": (76, (135, 974, 234, 1448), "161", "panels a/b", "nosplit"),
}
LINE, PAD, GAP, MARGIN = 6, 10, 30, 60
LINE_GAP = 8                  # between the two lines of a double frame line, as in the strips
MANIFEST = []
S = 1.5


def _runs(prof, thr):
    out = []
    for i in np.nonzero(prof > thr)[0]:
        if out and i - out[-1][1] <= 4: out[-1][1] = i
        else: out.append([i, i])
    return out


def cells(Bd, reg, nosplit=False, rows_=None):
    """Boxes from rule lines: rows where ink covers most of the region's width, then columns
    where ink covers most of a row band's height."""
    x0, x1, y0, y1 = reg
    R = Bd[y0:y1, x0:x1]
    h, w = R.shape
    Rh = ndi.binary_dilation(R, structure=np.ones((5, 1)))   # tolerate slight tilt
    rows = _runs(Rh.mean(1), 0.6)
    ys = [0] + [c for a, b in rows for c in (a, b)] + [h]
    bands = [[ys[i], ys[i + 1]] for i in range(0, len(ys), 2) if ys[i + 1] - ys[i] > 12]
    merged = []   # a thin band (floor, water) belongs to the panel above it
    for bd in bands:
        if merged and bd[1] - bd[0] < 70: merged[-1][1] = bd[1]
        else: merged.append(bd)
    bands = merged
    if rows_: bands, nosplit = [[a - y0, b - y0] for a, b in rows_], True
    res = []
    for a, b in bands:
        sub = ndi.binary_dilation(R[a:b], structure=np.ones((1, 5)))
        vc = [] if nosplit else _runs(sub.mean(0), 0.9)
        xs = [0] + [c for p, q in vc for c in (p, q)] + [w]
        for i in range(0, len(xs), 2):
            if xs[i + 1] - xs[i] > 70:
                res.append((x0 + xs[i] + 3, x0 + xs[i + 1] - 3, y0 + a + 3, y0 + b - 3))
    keep = []
    for (cx0, cx1, cy0, cy1) in res:
        m = bs.clean(Bd, cy0, cy1, cx0, cx1)
        lab, n = ndi.label(ndi.binary_dilation(m, iterations=1))
        hmax = max([sl[0].stop - sl[0].start for sl in ndi.find_objects(lab)] or [0])
        if m.sum() > 150 and hmax >= 25:
            keep.append(((cx0, cx1, cy0, cy1), m))
    return keep


def snap(vals, tol):
    """Positions within tol of the one before become one (their mean): a rule two boxes share is one line."""
    groups = []
    for v in sorted(set(vals)):
        if groups and v - groups[-1][-1] <= tol: groups[-1].append(v)
        else: groups.append([v])
    return {v: round(sum(g) / len(g)) for g in groups for v in g}


def frames(guide, rects):
    """A double frame line round each box (6 px lines, LINE_GAP apart), centred on its edge."""
    near = 2 * (LINE + LINE_GAP) + LINE      # boxes closer than this share one frame line between them
    sx = snap([v for r in rects for v in (r[0], r[2])], near)
    sy = snap([v for r in rects for v in (r[1], r[3])], near)
    h, d = LINE // 2, (LINE + LINE_GAP) // 2
    for x0, y0, x1, y1 in rects:
        x0, y0, x1, y1 = sx[x0], sy[y0], sx[x1], sy[y1]
        for e in (-d, d):
            a, b, c, f = x0 - e, y0 - e, x1 + e, y1 + e
            guide[b - h:b + h, a - h:c + h] = True
            guide[f - h:f + h, a - h:c + h] = True
            guide[b - h:f + h, a - h:a + h] = True
            guide[b - h:f + h, c - h:c + h] = True


def build(name, n, reg, out_mdp, nosplit=False, rows_=None):
    B0 = plate(n); ang = bs.skew_angle(B0); Bd = bs.deskew(B0, ang) > 0.5
    F = bs.deskew(page(n), ang)     # the same rotation about the page centre, at 300 dpi
    cs = cells(Bd, reg, nosplit, rows_)
    # layout: every box keeps its place on the plate, scaled S, inside a margin
    gx = min(c[0][0] for c in cs) - PAD - LINE; gy = min(c[0][2] for c in cs) - PAD - LINE
    W = int(np.ceil((max(c[0][1] for c in cs) + PAD + LINE - gx) * S)) + 2 * MARGIN
    H = int(np.ceil((max(c[0][3] for c in cs) + PAD + LINE - gy) * S)) + 2 * MARGIN
    layers, guide, rects = [], np.zeros((H, W), bool), []
    T = lambda x, y: (int(round((x - gx) * S)) + MARGIN, int(round((y - gy) * S)) + MARGIN)
    for k, ((cx0, cx1, cy0, cy1), m) in enumerate(cs):
        cut, rest = bs.cut_and_rest(Bd.shape, m, cy0, cy1, cx0, cx1)
        ox, oy = T(0, 0)
        M = np.array([[S, 0, ox], [0, S, oy]], float)
        name_k = f"{bs.ROMAN(n)}-{k + 1}"
        layers += [(name_k, bs.render(F, cut, M, W, H), True), (f"{name_k} rest", bs.render(F, rest, M, W, H), False)]
        MANIFEST.append(dict(file=f"bod{name}.mdp", layer=f"{bs.ROMAN(n)}-{k + 1}", plate=n, pdf_page=n + 23,
            deskew_deg=round(ang, 3), cell_x=[int(cx0), int(cx1)], cell_rows=[int(cy0), int(cy1)],
            scale=S, sheet_origin_plate=[int(gx), int(gy)], margin=MARGIN,
            plate_to_sheet=f"x' = {MARGIN} + (x - {gx})*{S}, y' = {MARGIN} + (y - {gy})*{S}",
            note="whole cell kept, text included" ))
        rects.append(T(cx0 - 3, cy0 - 3) + T(cx1 + 3, cy1 + 3))
    frames(guide, rects)
    bs.H = H
    write_portrait(f"{out_mdp}/bod{name}.mdp", W, H, layers, guide)
    print(f"bod{name}: pl. {bs.ROMAN(n)}, {len(layers) // 2} panels, {W}x{H}")


def write_portrait(path, W, H, layers, guide):
    old = bs.H; bs.H = H
    try:
        bs.write_mdp(path, W, layers, guide, np.zeros_like(guide))
    finally:
        bs.H = old


if __name__ == "__main__":
    out_mdp = sys.argv[1]
    os.makedirs(out_mdp, exist_ok=True)
    for name, (n, reg, sp, note, *opt) in REGIONS.items():
        rows_ = next((o["rows"] for o in opt if isinstance(o, dict)), None)
        build(name, n, reg, out_mdp, "nosplit" in opt, rows_)
    json.dump(MANIFEST, open(f"{out_mdp}/manifest_panels.json", "w"), indent=1)
