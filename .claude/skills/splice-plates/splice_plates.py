"""Splice plate pieces into a new strip .mdp (.claude/skills/splice-plates).

    python splice_plates.py <spec.json> <level> <template.mdp> <out.mdp> <preview_dir>

spec[level] = list of pieces, right to left: {"plate": N, "name": "...", "L": x, "R": x}, optionally
"ground_runs" ([[x0, x1], ...] plate x ranges of a ground line too short to detect, e.g. a narrow box),
"Lx"/"Rx" (an exact rule centre, for a broken or slanted edge rule) and "ground" (the plate row to put on
row 526, for a piece whose ground can't be found automatically). L/R are approximate plate-px positions
of the rules that bound the piece; each is snapped to the exact centre of the rule there. Pieces join rule
centre to rule centre. Rotation only, 1:1. The template supplies only the file header and layer-entry
format; every layer is written anew. Write <out.mdp> outside art/ and check it before copying it in.
The specs used so far are in splice_specs.json.
"""
import re, sys, struct, json
from pathlib import Path
import numpy as np, cv2
from PIL import Image

REPO = str(Path(__file__).resolve().parents[3])
sys.path.insert(0, f'{REPO}/tools/mdp300'); sys.path.insert(0, f'{REPO}/.claude/skills/splice-plates/strips')
from mdp import read_mdp, decode_layer
from write_mdp import parse_raw, encode_layer, pac, rename_chunk
from detect import runs_mask
from build_strips import skew_angle

spec_path, level, src, out, prev = sys.argv[1:6]
PIECES = json.load(open(spec_path))[level]
GUIDE = (181, 91, 60)
H = 1500
TOP, CAP, GROUND_UP, GROUND_LO = (30, 44), 180, 526, 540    # first rows of the frame lines; each line is 6 px


def plate(n, cache={}):
    if n in cache: return cache[n]
    g = np.asarray(Image.open(f'{REPO}/art/og_300dpi/page_{n:04d}.png').convert('L'))
    ang = skew_angle(g < 128)
    h, w = g.shape
    R = cv2.getRotationMatrix2D((w / 2, h / 2), -ang, 1.0)
    G = cv2.warpAffine(g, R, (w, h), flags=cv2.INTER_CUBIC, borderValue=255)
    V = cv2.warpAffine(np.full_like(g, 255), R, (w, h), flags=cv2.INTER_NEAREST, borderValue=0) > 0
    B = G < 128
    hm = runs_mask(B, 1, 300)
    rows = np.nonzero(hm.any(1))[0]
    groups = [r for r in np.split(rows, np.nonzero(np.diff(rows) > 1)[0] + 1) if len(r)]
    top = groups[0]                                  # top frame rule (may be a merged double)
    bottom = groups[-1]
    caps = [r for r in groups if top[-1] + 60 < r[0] < top[-1] + 300]
    cap = caps[0] if caps else None
    cache[n] = dict(ang=ang, G=G, V=V, B=B, hm=hm, top=(int(top[0]), int(top[-1])), bottom=(int(bottom[0]), int(bottom[-1])),
                    cap=(int(cap[0]), int(cap[-1])) if cap is not None else None)
    return cache[n]


def snap(n, x, win=32):
    """Exact centre of the vertical rule near x, from columns inked over most of the text rows."""
    P = plate(n); B = P['B']
    y0, y1 = P['top'][1] + 700, P['bottom'][0] - 100
    p = B[y0:y1, int(x) - win:int(x) + win].mean(0)
    xs = np.nonzero(p > 0.4)[0]
    if not len(xs): xs = np.nonzero(p > 0.25)[0]     # a slightly slanted rule spreads over more columns
    assert len(xs), (n, x)
    return int(x) - win + (xs.min() + xs.max()) / 2, int(x) - win + xs.min(), int(x) - win + xs.max()


def ground(n, x0, x1):
    """Bottom row of the lower ground line under x0..x1 (median over columns), or None."""
    P = plate(n); hm = P['hm']
    c = P['cap'][1] if P['cap'] else P['top'][1] + 140
    band = hm[c + 150:c + 520, x0:x1]
    cols = band.any(0)
    if cols.sum() < 60: return None
    last = np.array([np.nonzero(band[:, i])[0].max() for i in np.nonzero(cols)[0]])
    return float(np.median(last)) + c + 150


# ---- pieces: snap, measure, place ----
for p in PIECES:
    P = plate(p['plate'])
    # "Lx"/"Rx": an exact centre, for a broken or slanted edge rule that snapping can't read
    p['Rc'] = p['Rx'] if 'Rx' in p else snap(p['plate'], p['R'])[0]
    p['Lc'] = p['Lx'] if 'Lx' in p else snap(p['plate'], p['L'])[0]
    p['x0'], p['x1'] = int(round(p['Lc'])), int(round(p['Rc']))
    p['y0'], p['y1'] = P['top'][0] - 6, P['bottom'][1] + 5
    if 'ground' in p:
        p['dy'] = int(round(GROUND_UP - p['ground']))
        p['how'] = f"line row {p['ground']} on {GROUND_UP}"
    else:
        g = ground(p['plate'], p['x0'], p['x1'])
        how = 'ground in piece'
        if g is None:
            g = ground(p['plate'], 0, P['G'].shape[1]); how = 'ground elsewhere on plate'
        if g is not None:
            p['dy'] = int(round(GROUND_LO + 5 - g)); p['how'] = how
total = sum(p['Rc'] - p['Lc'] for p in PIECES)
W = int(round(total + 80))
xr = W - 40.5                                         # centre of the right-end double guide
for i, p in enumerate(PIECES):
    p['dx'] = int(round(xr - p['Rc']))
    xr = p['Lc'] + p['dx']
    if 'dy' not in p:                                 # no ground on the plate: top rule level with the neighbour's
        q = PIECES[i - 1]
        p['dy'] = int(round(plate(q['plate'])['top'][0] + q['dy'] - plate(p['plate'])['top'][0]))
        p['how'] = f"top rule level with {q['name']}"
print('canvas', W, H)
for p in PIECES:
    P = plate(p['plate'])
    print(f"  {p['name']:24s} ang {P['ang']:+.3f}  plate x {p['x0']}..{p['x1']}  dx {p['dx']} dy {p['dy']}  ({p['how']})"
          f"  top rule -> {P['top'][0] + p['dy']}  caption -> {P['cap'][0] + p['dy'] if P['cap'] else None}  canvas x {p['x0'] + p['dx']}..{p['x1'] + p['dx']}")


def placed(rgba, x, y):
    h, w = rgba.shape[:2]
    nx, ny = min(0, x), min(0, y)
    img = np.zeros((max(H, y + h) - ny, max(W, x + w) - nx, 4), np.uint8)
    img[y - ny:y - ny + h, x - nx:x - nx + w] = rgba
    return nx, ny, img


# ---- vertical guides ----
segs = []
for p in PIECES:
    P = plate(p['plate']); B = P['B']
    Bk = np.zeros_like(B); Bk[p['y0']:p['y1'], max(0, p['x0'] - 12):p['x1'] + 12] = B[p['y0']:p['y1'], max(0, p['x0'] - 12):p['x1'] + 12]
    v = runs_mask(Bk, 0, 300)
    cols = np.nonzero(v.any(0))[0]
    grp = np.split(cols, np.nonzero(np.diff(cols) > 6)[0] + 1)
    merged = []
    for g in grp:
        if not len(g): continue
        if merged and g[0] - merged[-1][-1] <= 14: merged[-1] = np.concatenate([merged[-1], g])
        else: merged.append(g)
    capr = P['cap'][1] if P['cap'] else P['top'][1] + 140
    gl = ground(p['plate'], p['x0'], p['x1']) or capr + 340
    for g in merged:
        cx = (g.min() + g.max()) / 2
        if cx < p['x0'] - 12 or cx > p['x1'] + 12: continue
        top = np.nonzero(v[:, g].any(1))[0].min()
        if top > capr + 25: continue
        prof = B[capr + 20:int(gl) - 40, g.min() - 8:g.max() + 9].mean(0) > 0.6
        double = int(np.sum(np.diff(prof.astype(int)) == 1) + prof[0]) >= 2
        start = TOP[1] + 1 if top <= P['top'][1] + 60 else CAP + 2
        segs.append(dict(x=cx + p['dx'], double=bool(double), start=start, piece=p['name']))
segs.sort(key=lambda s: s['x'])
ded = []
for s in segs:
    if ded and s['x'] - ded[-1]['x'] < 25:
        o = ded[-1]; o['x'] = (o['x'] + s['x']) / 2; o['double'] |= s['double']; o['start'] = min(o['start'], s['start'])
    else: ded.append(s)
# the two ends are always the frame's double lines at 30 px
ded = [s for s in ded if 60 < s['x'] < W - 60]
ded = [dict(x=39.5, double=True, start=TOP[1] + 1)] + ded + [dict(x=W - 40.5, double=True, start=TOP[1] + 1)]
vert = np.zeros((H, W, 4), np.uint8)
glines = []
for s in ded:
    xs = [int(round(s['x'] - 9.5)), int(round(s['x'] + 4.5))] if s['double'] else [int(round(s['x'] - 2.5))]
    for x in xs:
        vert[s['start']:H, x:x + 6] = (*GUIDE, 255); glines.append((x, x + 5))
print('vertical guides:', [(round(s['x'], 1), 'D' if s['double'] else 'S', s['start']) for s in ded])

# ---- horizontal guides: frame rows; ground only under the pieces' ground lines ----
hor = np.zeros((H, W, 4), np.uint8)
for r in (TOP[0], TOP[1], CAP):
    hor[r:r + 6, 31:W - 30] = (*GUIDE, 255)
runs = []
for p in PIECES:
    P = plate(p['plate'])
    g = ground(p['plate'], p['x0'], p['x1']) if 'ground' not in p else None
    if 'ground' in p:
        rows = slice(int(p['ground']) - 3, int(p['ground']) + 6)
    elif g is not None:
        rows = slice(int(g) - 40, int(g) + 12)        # a plate's ground can step by ~20 px between boxes
    else:
        continue
    cols = P['hm'][rows, p['x0']:p['x1']].any(0)
    xs = np.nonzero(cols)[0]
    if not len(xs): continue
    for r in np.split(xs, np.nonzero(np.diff(xs) > 20)[0] + 1):
        if len(r) >= 60: runs.append([r[0] + p['x0'] + p['dx'], r[-1] + p['x0'] + p['dx']])
for p in PIECES:                                      # "ground_runs": plate x ranges of ground lines too short to detect (a narrow box)
    for a, b in p.get('ground_runs', []): runs.append([a + p['dx'], b + p['dx']])
runs.sort()
mr = []
for a, b in runs:
    if mr and a - mr[-1][1] <= 30: mr[-1][1] = max(mr[-1][1], b)
    else: mr.append([a, b])
def snapx(x, side):
    near = [l for l in glines if abs((l[0] if side == 0 else l[1]) - x) <= 60 or l[0] - 60 <= x <= l[1] + 60]
    if not near: return x
    l = min(near, key=lambda l: abs((l[0] + l[1]) / 2 - x))
    return l[0] if side == 0 else l[1]
gsegs = []
for a, b in mr:
    a, b = int(snapx(a, 0)), int(snapx(b, 1))
    if gsegs and a - gsegs[-1][1] < 90: gsegs[-1] = (gsegs[-1][0], b)   # a short ground stub too small to detect
    else: gsegs.append((a, b))
for a, b in gsegs:
    for r in (GROUND_UP, GROUND_LO):
        hor[r:r + 6, a:b + 1] = (*GUIDE, 255)
print('ground guide segments:', gsegs)

# ---- write ----
head, xml, raw = parse_raw(src)
entries = list(re.finditer(r'[ \t]*<Layer [^>]*/>\n', xml))
attrs = [dict(re.findall(r'(\w+)="([^"]*)"', m.group(0))) for m in entries]
tmpl32 = next(m.group(0) for m, a in zip(entries, attrs) if a['type'] == '32bpp')
tmplF = next(m.group(0) for m, a in zip(entries, attrs) if a['type'] == 'folder')


def setattrs(s, kv):
    for k, v in kv.items():
        s, k_n = re.subn(rf'\b{k}="[^"]*"', f'{k}="{v}"', s)
        if k_n == 0: s = s.replace(' />', f' {k}="{v}" />')
    return s


ids = iter(range(2000, 100000))
order = []                                            # (xml entry, body or None) bottom -> top


def layer(name, parent, pl, visible='true'):
    ox, oy, img = pl
    return (setattrs(tmpl32, dict(ofsx=ox, ofsy=oy, width=img.shape[1], height=img.shape[0], mode='normal', alpha=255,
                                  visible=visible, group=-1, id=next(ids), parentId=parent, name=name, type='32bpp',
                                  protectAlpha='false', locked='false', clipping='false', masking='false')), encode_layer(img))


def folder(fid, name, visible='true'):
    return (setattrs(tmplF, dict(ofsx=0, ofsy=0, width=W, height=H, mode='through', alpha=255, visible=visible, group=-1,
                                 id=fid, parentId=-1, name=name, folderOpen='true', type='folder')), None)


order.append(layer('bg', -1, (0, 0, np.full((H, W, 4), 255, np.uint8))))
FD, FP, FG = 1001, 1002, 1003
check = []
for p in PIECES:
    P = plate(p['plate'])
    m = np.zeros_like(P['V']); m[p['y0']:p['y1'], p['x0']:p['x1']] = True
    for kind, sel in (('kept', P['V'] & m), ('disc', P['V'] & ~m)):
        rgba = np.dstack([P['G']] * 3 + [np.where(sel, 255, 0).astype(np.uint8)]); rgba[~sel] = 0
        p[kind] = placed(rgba, p['dx'], p['dy'])
    check.append(((P['V'] & m).astype(int) + (P['V'] & ~m).astype(int) == P['V']).all())
assert all(check)
for p in reversed(PIECES):
    order.append(layer(f"{p['name']} discarded", FD, p['disc']))
order.append(folder(FD, 'discarded (cut from plates, for splicing)', 'false'))
for p in reversed(PIECES):
    order.append(layer(p['name'], FP, p['kept']))
order.append(folder(FP, 'plates'))
order.append(layer('horizont', FG, (0, 0, hor)))
order.append(layer('vertical', FG, (0, 0, vert)))
order.append(folder(FG, 'guidelines'))

out_entries, out_chunks = [], [c for c in raw if c[0] == 'thumb']
for i, (e, body) in enumerate(order):
    b = f'layer{i}img'
    out_entries.append(re.sub(r'\bbin="[^"]*"', f'bin="{b}"', e))
    if body is not None: out_chunks.append([b, pac(b, body)])
first, last = entries[0].start(), entries[-1].end()
xml2 = xml[:first] + ''.join(out_entries) + xml[last:]
xml2 = re.sub(r'<Layers active="\d+"', f'<Layers active="{len(order) - 1}"', xml2, count=1)
xml2 = re.sub(r'(<Mdiapp[^>]*?) width="\d+"', rf'\1 width="{W}"', xml2, count=1)
xml2 = re.sub(r'(<Mdiapp[^>]*?) height="\d+"', rf'\1 height="{H}"', xml2, count=1)
xb = xml2.encode()
body = b''.join(c[1] for c in out_chunks)
open(out, 'wb').write(head + struct.pack('<2I', len(xb), len(body)) + xb + body)

# ---- read back: kept + discarded == rotated plate; preview ----
W2, H2, L2, C2, _ = read_mdp(out)
assert (W2, H2) == (W, H)
byname = {l['name']: l for l in L2}
def dec(l): return decode_layer(C2[l['bin']], int(l['width']), int(l['height']), '32bpp')[..., [2, 1, 0, 3]], int(l['ofsx']), int(l['ofsy'])
for p in PIECES:
    (k, kx, ky), (d, dx_, dy_) = dec(byname[p['name']]), dec(byname[p['name'] + ' discarded'])
    assert (kx, ky, k.shape) == (dx_, dy_, d.shape)
    assert not ((k[..., 3] > 0) & (d[..., 3] > 0)).any()
    s = np.where(k[..., 3:] > 0, k, d)
    P = plate(p['plate']); h, w = P['G'].shape
    oy, ox = p['dy'] - ky, p['dx'] - kx
    patch = s[oy:oy + h, ox:ox + w]
    assert patch.shape[:2] == (h, w) and ((patch[..., 3] > 0) == P['V']).all() and (patch[..., 0][P['V']] == P['G'][P['V']]).all()
    assert not s[..., 3].any() or (s[..., 3] > 0).sum() == P['V'].sum()
print('read back: every piece + its discarded layer == its rotated plate')
comp = np.full((H, W, 3), 255.)
for l in L2:
    if l['type'] == 'folder' or l['visible'] != 'true' or l['parentId'] == str(FD) or l['name'] == 'bg': continue
    im, ox, oy = dec(l); im = im.astype(np.float32)
    sub = im[-oy:-oy + H, -ox:-ox + W]
    a = sub[..., 3:] / 255; comp = comp * (1 - a) + sub[..., :3] * a
Image.fromarray(comp.astype(np.uint8)).save(f'{prev}/{level}_full.png')
Image.fromarray(comp.astype(np.uint8)).resize((W // 6, H // 6)).save(f'{prev}/{level}_small.png')
