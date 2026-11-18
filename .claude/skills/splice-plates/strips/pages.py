"""Plates joined side by side into one 300-dpi sheet, text and all, for runs of plates where the
text belongs with the vignettes: spells 42-64 (pl. XX-XXIII) and 149 (pl. LXXI-LXXIII), down to
about half the frame, and the gates of 144-146 (pl. LXI-LXVI), whole.

Each plate is straightened as in the strips, then scaled so its frame (heading rule to the foot of
the columns) is as tall as the others' and set down with its heading rule on a common row, later plates further
left (scroll order), the frames joined edge to edge. Per plate, bottom first:
    "<plate>-<k>" / "<plate>-<k> rest"   each vignette box (caption + picture) and, hidden, the rest
                                          of its box;
    "<plate> text"                        everything else inside the frame, rule lines taken out (on a
                                          sheet cut part way down, the glyphs that start above the cut);
    "<plate> rest"                        hidden: the rule lines, the plate heading and numbers.
All of a plate's layers merged give back the plate. The rule lines are redrawn as guides: 6 px
lines, two lines that run close together as a double line with an 8 px gap.

    python .claude/skills/splice-plates/strips/pages.py <out dir> [sheet ...]     (after build_strips.py, which skips these
                                                           plates; no sheet names = all of SHEETS)
"""
import json, os, sys
import numpy as np
from scipy import ndimage as ndi

from detect import runs_mask
import build_strips as bs

# name -> plates; `left`: plate x where the sheet's part of a plate starts; `down`: how much of the
# frame to keep, from the heading rule
SHEETS = {
    "42-64": dict(plates=range(20, 24), down=0.5),
    "144-146": dict(plates=range(61, 67)),
    "149": dict(plates=range(71, 74), left={73: 595}, down=0.5),   # left of that on LXXIII: 150 (panels.py)
}
RULE = (230, 250)  # plate px: a vertical / horizontal run at least this long is a rule line
HEAD = 14         # plate px: the heading's double rule, from the frame top down
BRIDGE = 25       # plate px: gaps in a broken rule line up to this long are part of the line
GLYPH = 100       # plate px: no glyph reaches further than this past the cut
SIDE = 34         # plate px (about 50 sheet px) kept beyond the frame and the cut
JOIN = 10         # plate px: neighbouring frames overlap by their edge's double line
MARGIN, LINE, LINE_GAP = 60, 6, 8
NEAR = 16         # sheet px: rule lines this close are the two lines of a double


def load(n, ov, left=0, down=1.0):
    """Plate n straightened, its boxes, its frame (x0, x1, y0, y1: the outer column rules right of
    `left`, from the double rule under the heading to the foot of the columns), its rule lines, its
    text (down to `down` of the frame, whole glyphs) and the bottom row the sheet keeps."""
    o = dict(ov.get(str(n), {})); o.pop("skip", None)
    items = bs.collect([n], {str(n): o})
    B = items[0]["B"]
    vm, hm = runs_mask(B, 0, RULE[0]), runs_mask(B, 1, RULE[1])
    ys, xs = np.nonzero(vm[:, left:]); x0, x1, y1 = left + xs.min(), left + xs.max() + 1, ys.max() + 1
    y0 = np.nonzero(hm.any(1))[0].min()
    rules = ndi.binary_dilation(vm, np.ones((BRIDGE, 3))) | ndi.binary_dilation(hm, np.ones((3, BRIDGE)))
    text = np.zeros(B.shape, bool); text[y0 + HEAD:y1, x0:x1] = True
    text &= ~rules
    bottom, cut = B.shape[0], y0 + round(down * (y1 - y0))
    if cut < y1:      # keep the glyphs that start above the cut, whole
        lab = ndi.label(B & text, np.ones((3, 3)))[0]
        text &= ndi.binary_dilation(np.isin(lab, np.unique(lab[:cut])[1:]), np.ones((3, 3)))
        text[cut + GLYPH:] = False    # a slanted rule line is not a glyph
        bottom = np.nonzero(text.any(1))[0].max() + SIDE
    cols = slice(max(0, x0 - SIDE), x1 + SIDE)
    runs = [np.zeros(B.shape, bool) for _ in range(2)]
    for r, m in zip(runs, (vm, hm)): r[:bottom, cols] = m[:bottom, cols]
    return dict(n=n, B=B, F=items[0]["F"], skew=items[0]["skew"], frame=(x0, x1, y0, y1), cols=cols,
                boxes=[it["box"] for it in items if it["box"]["x0"] >= left],
                rules=rules, text=text, bottom=bottom, runs=runs)


def masks(p):
    """The plate's layers as masks on the plate grid; each plate pixel the sheet keeps is in exactly one."""
    B, rules = p["B"], p["rules"]
    region = np.zeros(B.shape, bool); region[:p["bottom"], p["cols"]] = True
    taken = np.zeros(B.shape, bool)
    out = []
    for k, b in enumerate(p["boxes"], 1):
        rows = [b["vig"]] + ([b["cap"]] if b["cap"] else [])
        box = np.zeros(B.shape, bool); box[min(r[0] for r in rows):b["vig"][1], b["x0"]:b["x1"]] = True
        cut = np.zeros(B.shape, bool)
        for r0, r1 in rows:
            cut[r0:r1, b["x0"]:b["x1"]] |= bs.clean(B, r0, r1, b["x0"], b["x1"])
        cut = ndi.binary_dilation(cut, np.ones((3, 3))) & box & ~rules
        name = f"{bs.ROMAN(p['n'])}-{k}"
        out += [(name, cut, True), (f"{name} rest", box & ~cut, False)]
        taken |= box
    text = p["text"] & ~taken
    out += [(f"{bs.ROMAN(p['n'])} text", text, True), (f"{bs.ROMAN(p['n'])} rest", region & ~taken & ~text, False)]
    return out


def segments(m, axis):
    """Rule lines of a run mask as (centre, thickness, start, end); axis 0 = vertical lines."""
    out = []
    for sl in ndi.find_objects(ndi.label(m)[0]):
        across, along = (sl[1], sl[0]) if axis == 0 else (sl[0], sl[1])
        out.append(((across.start + across.stop) / 2, across.stop - across.start, along.start, along.stop))
    return out


def draw_rules(guide, segs, axis):
    """Guide lines for rule segments (sheet px). Segments within NEAR of each other across their
    length are one rule: double if they are apart or thick enough to be two lines, else single."""
    groups = []
    for s in sorted(segs):
        if groups and s[0] - groups[-1][-1][0] <= NEAR: groups[-1].append(s)
        else: groups.append([s])
    for g in groups:
        lo, hi = g[0][0], g[-1][0]
        double = hi - lo > LINE or max(s[1] for s in g) > 2 * LINE
        c = round((lo + hi) / 2)
        d = (LINE + LINE_GAP) // 2
        lines = [(c - d - LINE // 2, c - d + LINE // 2), (c + d - LINE // 2, c + d + LINE // 2)] if double \
            else [(c - LINE // 2, c + LINE // 2)]
        for _, _, a, b in g:
            for p, q in lines:
                if axis == 0: guide[int(a):int(b), p:q] = True
                else: guide[p:q, int(a):int(b)] = True


def build(name, plates, ov, out_dir, left={}, down=1.0):
    ps = [load(n, ov, left.get(n, 0), down) for n in reversed(plates)]    # later plates further left
    S0 = bs.S_MAX
    tall = np.median([p["frame"][3] - p["frame"][2] for p in ps])
    for p in ps: p["s"] = S0 * tall / (p["frame"][3] - p["frame"][2])
    top = MARGIN + max(p["frame"][2] * p["s"] for p in ps)
    H = int(np.ceil(top + max((p["bottom"] - p["frame"][2]) * p["s"] for p in ps))) + MARGIN
    x = MARGIN + SIDE * S0                                  # sheet x of the next frame's left edge
    for p in ps:
        x0, x1, y0, _ = p["frame"]
        p["M"] = np.array([[p["s"], 0, x - x0 * p["s"]], [0, p["s"], top - y0 * p["s"]]])
        x += (x1 - x0 - JOIN) * p["s"]
    W = int(np.ceil(x + (JOIN + SIDE) * S0)) + MARGIN

    hz, vt, vsegs = np.zeros((H, W), bool), np.zeros((H, W), bool), []
    for p in ps:
        (s, _, ox), (_, _, oy) = p["M"]
        vsegs += [(ox + c * s, w * s, oy + a * s, oy + b * s) for c, w, a, b in segments(p["runs"][0], 0)]
        draw_rules(hz, [(oy + c * s, w * s, ox + a * s, ox + b * s) for c, w, a, b in segments(p["runs"][1], 1)], 1)
    draw_rules(vt, vsegs, 0)                                # across plates, so a join is one double line

    def layers():
        for p in ps:
            (s, _, ox), _ = p["M"]
            x0, x1 = p["cols"].start, p["cols"].stop
            lx = int(ox + x0 * s); w = int(np.ceil((x1 - x0) * s)) + 2     # render plate columns x0..x1 only
            M = p["M"].copy(); M[0, 2] -= lx
            for lname, m, visible in masks(p):
                a = np.zeros((H, W), np.float32)
                a[:, lx:lx + w] = bs.render(p["F"], m, M, w, H, ss=2)[:, :W - lx]
                yield lname, a, visible
            print(f"  pl {bs.ROMAN(p['n'])}: skew {p['skew']:+.2f} deg, scale {p['s']:.4f}, {len(p['boxes'])} boxes")

    old = bs.H; bs.H = H
    try:
        bs.write_mdp(f"{out_dir}/bod{name}.mdp", W, layers(), hz, vt)
    finally:
        bs.H = old
    what = "whole plates" if down == 1 else f"plates down to {down:.0%} of the frame"
    line = f"bod{name}: pl. {bs.ROMAN(plates[0])}-{bs.ROMAN(plates[-1])}, {what}, {W}x{H}"
    print(line)
    index = f"{out_dir}/index.txt"     # shared with build_strips.py, which writes it from scratch
    lines = open(index).read().splitlines() if os.path.exists(index) else []
    open(index, "w").write("\n".join(sorted([l for l in lines if not l.startswith(f"bod{name}:")] + [line],
                                             key=lambda l: int(l[3:].split("-")[0].split(":")[0]))) + "\n")
    return [dict(file=f"bod{name}.mdp", plate=p["n"], plate_roman=bs.ROMAN(p["n"]), pdf_page=p["n"] + 23,
                 deskew_deg=round(p["skew"], 3), frame=dict(zip(["x0", "x1", "y0", "y1"], map(int, p["frame"]))),
                 plate_to_sheet=f"x' = {p['M'][0, 2]:.1f} + x*{p['s']:.4f}, y' = {p['M'][1, 2]:.1f} + y*{p['s']:.4f}")
            for p in ps]


if __name__ == "__main__":
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    names = sys.argv[2:] or list(SHEETS)
    ov = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "overrides.json")))
    path = f"{out_dir}/manifest_pages.json"
    manifest = [r for r in (json.load(open(path)) if os.path.exists(path) else [])
                if r["file"] not in {f"bod{n}.mdp" for n in names}]
    for name in names:
        sh = dict(SHEETS[name])
        manifest += build(name, list(sh.pop("plates")), ov, out_dir, **sh)
    json.dump(manifest, open(path, "w"), indent=1)
