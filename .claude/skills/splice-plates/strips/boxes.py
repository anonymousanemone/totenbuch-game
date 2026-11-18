"""Where the boxes (caption + vignette) of a plate are, found from its rule lines, and two pictures for checking
that by eye. Used by build_strips.py and pages.py; the steps are in NOTES.md ("Box detection").

    python boxes.py review A B out.png [--overrides]   plates A..B, each box outlined: the vignette in red (kept) or
                                                       blue (dropped), its caption in green, its number below;
                                                       --overrides applies overrides.json (run in this folder)
    python boxes.py ruler out.png N [N ...]            plates N.., with a ruler in plate px along the top and left,
                                                       for reading off coordinates for overrides.json
"""
import numpy as np, json, sys
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from detect import plate, runs_mask

def segments(m, axis):
    """connected straight-line segments from a run mask -> list of (y0,y1,x0,x1)"""
    lab, n = ndi.label(m)
    out = []
    for sl in ndi.find_objects(lab):
        out.append((sl[0].start, sl[0].stop-1, sl[1].start, sl[1].stop-1))
    return out


def find_boxes(n, ov=None):
    ov = ov or {}
    B = plate(n); H, W = B.shape
    hm = runs_mask(B, 1, 90)
    hs = [s for s in segments(ndi.binary_dilation(hm, iterations=1), 1) if s[0] < 900 and s[1]-s[0] < 30]
    wide = sorted([s for s in hs if s[3]-s[2] > W*0.5], key=lambda s: s[0])
    L0 = wide[0][1]
    for s in wide[1:]:
        if s[0] - L0 < 16: L0 = s[1]
    L0 = ov.get('L0', L0)
    l1 = np.full(W, -1); l1b = np.full(W, -1); l2 = np.full(W, -1)
    for (y0, y1, x0, x1) in sorted(hs, key=lambda s: s[0]):
        if L0 + 45 < y0 < L0 + ov.get('l1max', 170):
            sel = l1[x0:x1+1] < 0; l1[x0:x1+1][sel] = y1; l1b[x0:x1+1][sel] = y0
    if ov.get('nocap'): l1[:] = -1
    best = np.zeros(W)
    for (y0, y1, x0, x1) in hs:
        ln = x1 - x0
        for x in range(x0, x1+1):
            lo = (l1[x] if l1[x] >= 0 else L0) + ov.get('minvig', 90)
            if lo < y0 < L0 + ov.get('maxvig', 640) and (ln > best[x] + 30 or (abs(ln - best[x]) <= 30 and y0 < l2[x])):
                l2[x] = y0; best[x] = max(ln, best[x])
    vm = runs_mask(B, 0, 50)
    vs = segments(vm, 0)
    seps = []
    for (a, b, c, e) in vs:
        if e - c > 40: continue
        x = (c + e) // 2
        if l2[x] < 0 and l2[max(x-6,0):x+7].max() < 0: continue
        bot = l2[max(x-6,0):x+7].max()
        top = max(l1[max(x-6,0):x+7].max(), L0)
        if a <= top + 18 and b >= bot - 18: seps.append((c, e))
    seps += [(x, x) for x in ov.get('seps', [])]
    seps.sort()
    # merge adjacent separator lines (double lines)
    ms = []
    for c, e in seps:
        if ms and c - ms[-1][1] < 14: ms[-1][1] = max(ms[-1][1], e)
        else: ms.append([c, e])
    # boxes between separators where l2 exists across
    boxes = []
    edges = [[0, -1]] + ms + [[W, W]]
    for (a0, a1), (b0, b1) in zip(edges, edges[1:]):
        x0, x1 = a1 + 2, b0 - 2
        if x1 - x0 < 40: continue
        cov = (l2[x0:x1] >= 0).mean()
        if cov < 0.6: continue
        xs = np.arange(x0, x1)[l2[x0:x1] >= 0]
        x0, x1 = max(x0, xs.min()), min(x1, xs.max())
        g = int(np.median(l2[x0:x1][l2[x0:x1] >= 0]))
        capc = (l1[x0:x1] >= 0).mean()
        if capc > 0.6:
            c1 = int(np.median(l1[x0:x1][l1[x0:x1] >= 0])); c1b = int(np.median(l1b[x0:x1][l1b[x0:x1] >= 0]))
            cap = (L0 + 2, c1b - 1); vig = (c1 + 2, g - 1)
        else:
            cap = None; vig = (L0 + 2, g - 1)
        # vignette test: a tall non-line component inside
        sub = B[vig[0]:vig[1], x0:x1] & ~runs_mask(B[vig[0]:vig[1], x0:x1], 1, 90) & ~runs_mask(B[vig[0]:vig[1], x0:x1], 0, 40)
        lab, k = ndi.label(ndi.binary_dilation(sub, iterations=1))
        hmax = max([sl[0].stop - sl[0].start for sl in ndi.find_objects(lab)] or [0])
        boxes.append(dict(x0=int(x0), x1=int(x1), cap=cap, vig=vig, tall=int(hmax), keep=bool(hmax >= ov.get('tall', 75))))
    for a in ov.get('add', []):
        x0, x1 = a[:2]
        g = l2[x0:x1][l2[x0:x1] >= 0]; g = int(np.median(g)) if len(g) else None
        c = l1[x0:x1][l1[x0:x1] >= 0]; cb = l1b[x0:x1][l1b[x0:x1] >= 0]
        cap = (L0 + 2, int(np.median(cb)) - 1) if len(c) > 0.6*(x1-x0) else None
        vig = (int(np.median(c)) + 2 if cap else L0 + 2, (g or 0) - 1)
        if len(a) == 4: vig = (a[2], a[3]); cap = None   # explicit vignette rows, no caption
        boxes.append(dict(x0=x0, x1=x1, cap=cap, vig=vig, tall=0, keep=True, added=True))
    added = [b for b in boxes if b.get('added')]
    boxes = [b for b in boxes if b.get('added') or not any(min(b['x1'], a['x1']) - max(b['x0'], a['x0']) > 0.5 * (b['x1'] - b['x0']) for a in added)]
    boxes.sort(key=lambda b: b['x0'])
    for i in ov.get('drop', []): boxes[i]['keep'] = False
    if ov.get('dropall'):
        for b in boxes: b['keep'] = False
    for i in ov.get('force', []): boxes[i]['keep'] = True
    return B, L0, boxes

def review(ns, out, ovs={}):
    tiles = []
    for n in ns:
        B, L0, boxes = find_boxes(n, ovs.get(str(n)))
        H, W = B.shape
        y1 = max([b['vig'][1] for b in boxes] + [L0 + 380]) + 30
        oy = max(L0-40, 0)
        im = Image.fromarray(((~B[oy:y1]) * 255).astype(np.uint8)).convert('RGB'); d = ImageDraw.Draw(im)
        for i, b in enumerate(boxes):
            col = (220, 30, 30) if b['keep'] else (150, 150, 255)
            d.rectangle([b['x0'], b['vig'][0]-oy, b['x1'], b['vig'][1]-oy], outline=col, width=4)
            if b['cap']: d.rectangle([b['x0']+6, b['cap'][0]-oy, b['x1']-6, b['cap'][1]-oy], outline=(0,170,0), width=3)
            d.text((b['x0']+8, b['vig'][1]-oy-14), f'{i}', fill=col)
        d.text((10, 5), f'pl {n}', fill=(255,0,0))
        tiles.append(im.resize((W//2, im.height//2)))
    Wt = max(t.width for t in tiles); Ht = sum(t.height+6 for t in tiles)
    sheet = Image.new('RGB', (Wt, Ht), (90,90,90)); y = 0
    for t in tiles: sheet.paste(t, (0, y)); y += t.height + 6
    sheet.save(out)

def ruler(out, ns):
    """Plates `ns` with a ruler (red: x, blue: y, in plate px) round them, in one picture."""
    tiles = []
    for n in ns:
        B = plate(n); H, W = B.shape
        y0, y1 = 80, 720
        im = Image.fromarray(((~B[y0:y1]) * 255).astype(np.uint8)).convert('RGB'); d = ImageDraw.Draw(im)
        for x in range(0, W, 50):
            d.line([(x, 0), (x, 25 if x % 100 else 45)], fill=(255,0,0), width=3)
            if x % 200 == 0: d.text((x+3, 28), str(x), fill=(255,0,0))
        for y in range(0, y1-y0, 50):
            d.line([(0, y), (25 if y % 100 else 45, y)], fill=(0,0,255), width=3); d.text((48, y-5), str(y+y0), fill=(0,0,255))
        d.text((W-120, 5), f'pl {n}', fill=(255,0,0))
        tiles.append(im.resize((W*2//5, (y1-y0)*2//5)))
    sh = Image.new('RGB', (max(t.width for t in tiles), sum(t.height+4 for t in tiles)), (80,80,80)); y = 0
    for t in tiles: sh.paste(t, (0, y)); y += t.height + 4
    sh.save(out)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['review'] and len(a) in (4, 5) and a[4:] in ([], ['--overrides']):
        review(range(int(a[1]), int(a[2])+1), a[3], json.load(open('overrides.json')) if a[4:] else {})
    elif a[:1] == ['ruler'] and len(a) >= 3:
        ruler(a[1], map(int, a[2:]))
    else:
        sys.exit(__doc__)
