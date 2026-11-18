"""Assemble the boxed vignettes of Lepsius pl. XII-LXXIX into 300-dpi strips laid out like the
hand-made bod1-15 / bod17-21 files: 582 px tall, double frame lines, a caption row
(47-178) and a vignette row (183-524) whose figures stand on the line at 524.

Each vignette box becomes its own layer (caption + picture); the frame and box separators
are drawn pixel-perfect in a guide colour on separate layers, as in the hand-made files.
Right above each box layer is a hidden "<box> rest" layer: what the cut left out around it (rule
lines, specks, the rest of its caption and picture rows), placed the same way, so merging the two
gives back the plate as it is. Ink is taken from the 300-dpi pages (detect.page).

    python .claude/skills/splice-plates/strips/build_strips.py <out dir> [first plate] [last plate]
"""
import json, math, os, re, sys, struct, zlib, time
import numpy as np, cv2
from scipy import ndimage as ndi

from detect import page, plate, runs_mask, P
from boxes import find_boxes

H = 582
TOP = [(28, 33), (42, 47)]
MID = (178, 183)
BOT = [(524, 529), (538, 543)]
CAP_BAND = (48, 177)          # rows available for captions
VIG_TOP, GROUND = 184, 524    # vignette rows; figures stand on GROUND
LEFT, RIGHT_M = 162, 145      # frame starts at x=162, ends 145 px from the right edge
END_LINES = [(0, 6), (14, 20)]  # double end lines, relative to the frame edge
GUIDE_RGB = (181, 91, 60)
S_MAX = 1.5                   # 200-dpi plate px -> 300-dpi strip px
SEP_W, SEP_PAD = 6, 10        # separator line width, gap on either side
MAX_W = 15200
REST_PAD = 8                  # plate px the rest layer reaches past the box on each side
MANIFEST = []   # one record per layer: where it came from and where it went

ROMAN = lambda n: ''.join(s * c for s, c in zip(['L', 'XL', 'X', 'IX', 'V', 'IV', 'I'], _roman_counts(n)))
def _roman_counts(n):
    out = []
    for v in [50, 40, 10, 9, 5, 4, 1]:
        out.append(n // v); n %= v
    return out

# spells on each plate, from Lepsius's plate headers
SPELLS = {12: (18, 18), 13: (18, 19), 14: (20, 24), 15: (25, 29), 16: (30, 32), 17: (32, 38), 18: (39, 40),
    19: (41, 42), 20: (42, 47), 21: (48, 52), 22: (53, 58), 23: (59, 64), 24: (64, 64), 25: (64, 68),
    26: (68, 71), 27: (71, 74), 28: (75, 78), 29: (78, 78), 30: (78, 80), 31: (80, 84), 32: (85, 87),
    33: (88, 92), 34: (92, 96), 35: (97, 99), 36: (99, 99), 37: (99, 101), 38: (102, 106), 39: (107, 109),
    40: (109, 110), 41: (110, 110), 42: (110, 111), 43: (112, 114), 44: (115, 119), 45: (120, 124),
    46: (124, 125), 47: (125, 125), 48: (125, 125), 49: (125, 125), 50: (125, 125), 51: (126, 128),
    52: (128, 130), 53: (130, 130), 54: (130, 133), 55: (133, 135), 56: (136, 137), 57: (138, 140),
    58: (141, 141), 59: (142, 143), 60: (144, 144), 61: (144, 145), 62: (145, 145), 63: (145, 145),
    64: (145, 145), 65: (145, 146), 66: (146, 146), 67: (146, 147), 68: (147, 147), 69: (148, 148),
    70: (148, 148), 71: (149, 149), 72: (149, 149), 73: (149, 150), 74: (151, 153), 75: (154, 156),
    76: (157, 161), 77: (162, 163), 78: (163, 164), 79: (164, 165)}


def skew_angle(B):
    """Plate tilt in degrees from the long vertical column rules (x drift along y)."""
    vm = runs_mask(B, 0, 400)
    lab, n = ndi.label(vm)
    angs = []
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        if sl[1].stop - sl[1].start > 40: continue
        ys, xs = np.nonzero(lab[sl] == i)
        if ys.max() - ys.min() < 600: continue
        k = np.polyfit(ys, xs, 1)[0]
        angs.append(math.degrees(math.atan(k)))
    return float(np.median(angs)) if angs else 0.0


def deskew(B, ang):
    h, w = B.shape
    R = cv2.getRotationMatrix2D((w / 2, h / 2), -ang, 1.0)   # rotate so that x no longer drifts with y
    F = cv2.warpAffine(B.astype(np.float32), R, (w, h), flags=cv2.INTER_CUBIC, borderValue=0)
    return np.clip(F, 0, 1)


def clean(Bd, y0, y1, x0, x1):
    """Ink of a box region without its rule lines and slivers of neighbouring boxes."""
    r = Bd[y0:y1, x0:x1].copy()
    h, w = r.shape
    hl = runs_mask(r, 1, max(40, int(w * 0.5)))
    vl = runs_mask(r, 0, max(40, int(h * 0.6)))
    edge = np.zeros_like(r)
    edge[:10] = edge[-10:] = True
    edge[:, :10] = edge[:, -10:] = True
    lines = ndi.binary_dilation(hl | vl, iterations=1)
    r &= ~(lines & ndi.binary_dilation(edge, iterations=4))
    # specks left at the very edges (rule remnants)
    lab, n = ndi.label(r, structure=np.ones((3, 3)))
    for i, sl in enumerate(ndi.find_objects(lab), 1):
        hh, ww = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        near = sl[0].start < 6 or sl[0].stop > h - 6 or sl[1].start < 6 or sl[1].stop > w - 6
        if near and (hh < 6 or ww < 6) and (lab[sl] == i).sum() < 120:
            r[sl][lab[sl] == i] = False
    return r


def render(F, mask, M, out_w, out_h, ss=4):
    """Render the 300-dpi page F where `mask` (on the plate grid) is set, through M (plate -> out,
    2x3), at ss x supersampling."""
    m = cv2.resize(mask.astype(np.uint8), (F.shape[1], F.shape[0]), interpolation=cv2.INTER_NEAREST)
    Ms = M.copy(); Ms[:, :2] /= P
    big = cv2.warpAffine(F * m, Ms * ss, (out_w * ss, out_h * ss), flags=cv2.INTER_LINEAR, borderValue=0)
    return cv2.resize(big, (out_w, out_h), interpolation=cv2.INTER_AREA)


def cut_and_rest(shape, mask, y0, y1, x0, x1):
    """The cut (`mask` at y0, x0, a pixel wider for the ink's soft edge) and the rest of the region
    around it, REST_PAD wider: together they are the whole region, each pixel in one of them."""
    cut = np.zeros(shape, bool); cut[y0:y1, x0:x1] = mask
    cut = ndi.binary_dilation(cut, structure=np.ones((3, 3)))
    rest = np.zeros(shape, bool)
    rest[max(0, y0 - REST_PAD):y1 + REST_PAD, max(0, x0 - REST_PAD):x1 + REST_PAD] = True
    return cut, rest & ~cut


def collect(plates, ov):
    items = []
    for n in plates:
        o = ov.get(str(n), {})
        if o.get('skip'):
            print(f'pl {ROMAN(n)}: skipped ({o["skip"]})'); continue
        B0 = plate(n)
        ang = skew_angle(B0)
        Bd = deskew(B0, ang) > 0.5
        F = deskew(page(n), ang)     # the same rotation about the page centre, at 300 dpi
        # detection on the deskewed plate
        import detect
        detect_plate = detect.plate
        detect.plate = lambda k, Bd=Bd: Bd
        import boxes as box_finder; box_finder.plate = detect.plate
        try:
            _, L0, boxes = find_boxes(n, o)
        finally:
            detect.plate = detect_plate; box_finder.plate = detect_plate
        kept = [b for b in boxes if b['keep']]
        print(f'pl {ROMAN(n)}: skew {ang:+.2f} deg, {len(kept)} vignettes')
        for i, b in enumerate(kept):
            items.append(dict(plate=n, idx=i + 1, box=b, F=F, B=Bd, skew=ang, L0=int(L0)))
    return items


def layout_box(it):
    b, F, B = it['box'], it['F'], it['B']
    x0, x1 = b['x0'], b['x1']
    vy0, vy1 = b['vig']
    vm = clean(B, vy0, vy1, x0, x1)
    ys, xs = np.nonzero(vm)
    if len(ys) == 0: return None
    top = vy0 + ys.min()
    has_cap = b['cap'] is not None
    room = GROUND - (VIG_TOP if has_cap else CAP_BAND[0]) - 4
    s = min(S_MAX, room / max(vy1 - top, 1))
    w = int(math.ceil((x1 - x0) * s))
    cap = None
    if has_cap:
        cy0, cy1 = b['cap']
        cm = clean(B, cy0, cy1, x0, x1)
        cys, cxs = np.nonzero(cm)
        if len(cys):
            ch = cys.max() - cys.min() + 1; cw = cxs.max() - cxs.min() + 1
            sc = min(S_MAX, (CAP_BAND[1] - CAP_BAND[0] - 8) / ch, (w - 16) / cw)
            cap = dict(mask=cm, y0=cy0, s=sc, cy=cy0 + (cys.min() + cys.max()) / 2, cx=x0 + (cxs.min() + cxs.max()) / 2)
    it.update(vmask=vm, s=s, w=w, cap=cap, has_cap=has_cap)
    return it


def draw_box(it, bx, W):
    """The box's layer and its rest layer (H x W alpha each), placed with its left edge at bx."""
    b, F, shape = it['box'], it['F'], it['B'].shape
    x0, x1 = b['x0'], b['x1']; vy0, vy1 = b['vig']; s = it['s']
    # vignette: plate (x, y) -> (bx + (x - x0) s, GROUND - (vy1 - y) s); the caption's rows (placed
    # with the caption) end where the picture's rows begin, so no ink is in both rest layers
    cut, rest = cut_and_rest(shape, it['vmask'], vy0, vy1, x0, x1)
    if b['cap']: rest[:b['cap'][1]] = False
    M = np.array([[s, 0, bx - x0 * s], [0, s, GROUND - vy1 * s]])
    out, left = render(F, cut, M, W, H), render(F, rest, M, W, H)
    c = it['cap']
    if c:
        cs = c['s']; cyc = (CAP_BAND[0] + CAP_BAND[1]) / 2; cy0, cy1 = b['cap']
        cut, rest = cut_and_rest(shape, c['mask'], cy0, cy1, x0, x1)
        rest[cy1:] = False
        M = np.array([[cs, 0, bx + it['w'] / 2 - c['cx'] * cs], [0, cs, cyc - c['cy'] * cs]])
        out = np.maximum(out, render(F, cut, M, W, H))
        left = np.maximum(left, render(F, rest, M, W, H))
    return out, left


def group(items):
    """Split the sequence (scroll order) into files no wider than MAX_W, at plate boundaries."""
    files, cur, cur_w = [], [], 0
    by_plate = {}
    for it in items: by_plate.setdefault(it['plate'], []).append(it)
    for n in sorted(by_plate):
        pw = sum(it['w'] + SEP_W + 2 * SEP_PAD for it in by_plate[n])
        if cur and cur_w + pw + LEFT + RIGHT_M + 40 > MAX_W:
            files.append(cur); cur, cur_w = [], 0
        cur += by_plate[n]; cur_w += pw
    if cur: files.append(cur)
    return files


def build_file(items):
    """Lay the boxes out right-to-left by plate (plate order = scroll order), each plate's
    boxes keeping their left-to-right order on the plate."""
    plates = sorted({it['plate'] for it in items})
    seq = []
    for n in reversed(plates):  # later plates further left
        seq += [it for it in items if it['plate'] == n]
    inner = sum(it['w'] for it in seq) + (len(seq) - 1) * (SEP_W + 2 * SEP_PAD) + 2 * SEP_PAD
    W = LEFT + 20 + inner + 20 + RIGHT_M
    x = LEFT + 20 + SEP_PAD
    layers, seps, caprows = [], [], []
    for k, it in enumerate(seq):
        img, rest = draw_box(it, x, W)
        name = f"{ROMAN(it['plate'])}-{it['idx']}"
        layers += [(name, img, True), (f"{name} rest", rest, False)]
        b = it['box']; c = it['cap']
        MANIFEST.append(dict(
            layer=name, plate=it['plate'], plate_roman=ROMAN(it['plate']), pdf_page=it['plate'] + 23,
            deskew_deg=round(it['skew'], 3), frame_top_row=it['L0'],
            box_x=[b['x0'], b['x1']],
            caption_rows=list(b['cap']) if b['cap'] else None,
            picture_rows=list(b['vig']),
            added_by_hand=bool(b.get('added')),
            picture_scale=round(it['s'], 4),
            caption_scale=round(c['s'], 4) if c else None,
            caption_center_plate=[round(c['cx'], 1), round(c['cy'], 1)] if c else None,
            strip_x=[int(x), int(x + it['w'])],
            strip_caption_rows=list(CAP_BAND) if c else None,
            strip_picture=dict(bottom_row=GROUND, plate_to_strip=f"x' = {x} + (x - {b['x0']})*{it['s']:.4f}, y' = {GROUND} - ({b['vig'][1]} - y)*{it['s']:.4f}"),
        ))
        if it['has_cap']: caprows.append((x - SEP_PAD, x + it['w'] + SEP_PAD))
        x += it['w']
        if k < len(seq) - 1:
            seps.append(x + SEP_PAD); x += SEP_W + 2 * SEP_PAD
    # guides
    hz = np.zeros((H, W), bool); vt = np.zeros((H, W), bool)
    fx0, fx1 = LEFT, W - RIGHT_M
    for a, b in TOP + BOT: hz[a:b + 1, fx0:fx1] = True
    for a, b in caprows: hz[MID[0]:MID[1] + 1, max(a, fx0 + 20):min(b + SEP_W, fx1 - 20)] = True
    for a, b in END_LINES:
        vt[TOP[0][0]:BOT[1][1] + 1, fx0 + a:fx0 + b] = True
        vt[TOP[0][0]:BOT[1][1] + 1, fx1 - b:fx1 - a] = True
    for sx in seps: vt[TOP[1][0]:BOT[0][1] + 1, sx:sx + SEP_W] = True
    return W, layers, hz, vt, plates


# ------------------------------------------------------------------ MDP writing

def tiles_body(rgba, ts=128):
    h, w = rgba.shape[:2]
    bgra = rgba[..., [2, 1, 0, 3]]
    out = []
    for ty in range((h + ts - 1) // ts):
        for tx in range((w + ts - 1) // ts):
            blk = bgra[ty * ts:(ty + 1) * ts, tx * ts:(tx + 1) * ts]
            if not blk[..., 3].any(): continue
            t = np.zeros((ts, ts, 4), np.uint8); t[:blk.shape[0], :blk.shape[1]] = blk
            z = zlib.compress(t.tobytes(), 6)
            out.append(struct.pack('<4I', tx, ty, 0, len(z)) + z + b'\0' * ((4 - len(z) % 4) % 4))
    return struct.pack('<2I', len(out), ts) + b''.join(out)


def pac(name, body, compressed=False, raw_len=None):
    return (b'PAC ' + struct.pack('<4I', 132 + len(body), 1 if compressed else 0, len(body), raw_len or len(body))
            + b'\0' * 48 + name.encode().ljust(64, b'\0') + body)


def write_mdp(path, W, layers, hz, vt):
    """layers: (name, alpha float, visible) for each layer, bottom first -> folder 'bod_300dpi'; plus bg
    and guide folder."""
    now = int(time.time()); ts = time.strftime('%Y-%m-%dT%H:%M:%S', time.localtime(now))
    entries, chunks = [], []
    def layer(name, rgba, lid, parent, visible=True, kind='32bpp', mode='normal', extra=''):
        i = len(entries)
        b = f'layer{i}img'
        entries.append(f'        <Layer ofsx="0" ofsy="0" width="{W}" height="{H}" mode="{mode}" alpha="255" visible="{"true" if visible else "false"}" '
                       f'protectAlpha="false" locked="false" clipping="false" masking="false" maskingType="0" group="-1" id="{lid}" draft="false" '
                       f'parentId="{parent}" name="{name}"{extra} binType="2" bin="{b}" type="{kind}" />\n')
        if rgba is not None: chunks.append(pac(b, tiles_body(rgba)))
    lid = 0
    bg = np.full((H, W, 4), 255, np.uint8)
    layer('bg', bg, lid, -1); lid += 1
    fid = 1000
    comp = np.full((H, W), 255, np.float32)    # for the thumbnail
    for name, a, visible in layers:            # one pass, so `layers` may be a generator
        rgba = np.zeros((H, W, 4), np.uint8); rgba[..., 3] = (255 * np.clip(a, 0, 1)).round().astype(np.uint8)
        layer(name, rgba, lid, fid, visible); lid += 1
        if visible: comp = np.minimum(comp, 255 - rgba[..., 3])
    layer('bod_300dpi', None, fid, -1, kind='folder', mode='through', extra=' folderOpen="true"')
    gid = 1001
    for name, m in (('horizont', hz), ('vertical', vt)):
        rgba = np.zeros((H, W, 4), np.uint8); rgba[m] = GUIDE_RGB + (255,)
        layer(name, rgba, lid, gid); lid += 1
    layer('guidelines', None, gid, -1, kind='folder', mode='through', extra=' folderOpen="false"')
    # thumbnail (256 wide), BGRA, zlib
    comp[hz | vt] = 120
    th = max(1, round(256 * H / W))
    t = cv2.resize(comp.astype(np.uint8), (256, th), interpolation=cv2.INTER_AREA)
    tb = np.dstack([t, t, t, np.full_like(t, 255)]).tobytes()
    thumb = pac('thumb', zlib.compress(tb), compressed=True, raw_len=len(tb))
    xml = ('<?xml version="1.0" encoding="UTF-8" ?>\n'
           f'<Mdiapp width="{W}" height="{H}" dpi="300" checkerBG="true" bgColorR="255" bgColorG="255" bgColorB="255">\n'
           f'    <CreateTime time="{now}" timeString="{ts}" />\n'
           f'    <UpdateTime time="{now}" timeString="{ts}" rev="1" />\n'
           f'    <Thumb width="256" height="{th}" bin="thumb" />\n'
           '    <Snaps />\n    <Guides />\n'
           '    <ICCProfiles enabled="false" cmykView="false" blackPoint="true" renderingIntent="perceptual" />\n'
           f'    <Layers active="1">\n' + ''.join(entries) + '    </Layers>\n'
           '    <appInfo name="MediBang Paint Pro" rev="86" bitType="64" />\n</Mdiapp>\n').encode()
    body = thumb + b''.join(chunks)
    with open(path, 'wb') as f:
        f.write(b'mdipack\0' + b'\0' * 4 + struct.pack('<2I', len(xml), len(body)) + xml + body)


def main(out_mdp, first=12, last=79):
    os.makedirs(out_mdp, exist_ok=True)
    ov = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'overrides.json')))
    items = [it for it in (layout_box(it) for it in collect(range(first, last + 1), ov)) if it]
    index = []
    for grp in group(items):
        W, layers, hz, vt, plates = build_file(grp)
        sp = (SPELLS[plates[0]][0], SPELLS[plates[-1]][1])
        stem = f'bod{sp[0]}-{sp[1]}'
        write_mdp(f'{out_mdp}/{stem}.mdp', W, layers, hz, vt)
        for m in MANIFEST:
            m.setdefault('file', f'{stem}.mdp')
        line = f'{stem}: pl. {ROMAN(plates[0])}-{ROMAN(plates[-1])}, {len(layers) // 2} vignettes, {W}x{H}'
        print(line); index.append(line)
    open(f'{out_mdp}/index.txt', 'w').write('\n'.join(index) + '\n')
    json.dump(MANIFEST, open(f'{out_mdp}/manifest.json', 'w'), indent=1)


if __name__ == '__main__':
    main(sys.argv[1], *map(int, sys.argv[2:4]))
