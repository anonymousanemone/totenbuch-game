import numpy as np, json, sys
from pathlib import Path
import cv2
from PIL import Image
from scipy import ndimage as ndi

PAGES = Path(__file__).resolve().parents[4] / 'art' / 'og_300dpi'   # page_NNNN.png = plate N, 300 dpi (read only)
P = 1.5                                                             # 300-dpi page px per 200-dpi plate px


def page(n):
    """Plate n at 300 dpi, as darkness 0..1."""
    return 1 - np.asarray(Image.open(PAGES / f'page_{n:04d}.png').convert('L'), np.float32) / 255


def plate(n):
    """Plate n on the 200-dpi grid that the detection and overrides.json are measured in; ink = True."""
    d = page(n)
    return cv2.resize(d, (int(d.shape[1] / P), int(d.shape[0] / P)), interpolation=cv2.INTER_AREA) > 0.5

def runs_mask(B, axis, minlen):
    """pixels belonging to straight runs of at least minlen along axis (0=vertical,1=horizontal)"""
    st = np.ones((1, minlen), bool) if axis == 1 else np.ones((minlen, 1), bool)
    return ndi.binary_opening(B, structure=st)

def hlines(B, frac=0.12):
    H, W = B.shape
    m = runs_mask(B, 1, int(W*frac))
    rows = np.nonzero(m.sum(1) > 0)[0]
    out = []
    for r in rows:
        if out and r - out[-1][1] <= 2: out[-1][1] = r
        else: out.append([r, r])
    res = []
    for a, b in out:
        xs = np.nonzero(m[a:b+1].any(0))[0]
        res.append(dict(y0=int(a), y1=int(b), x0=int(xs.min()), x1=int(xs.max()), cover=float(m[a:b+1].any(0).sum()/W)))
    return res, m

if __name__ == '__main__':
    for n in map(int, sys.argv[1:]):
        B = plate(n); L, _ = hlines(B)
        print(n, [(l['y0'], l['y1'], l['x0'], l['x1'], round(l['cover'],2)) for l in L if l['y0'] < 1300])
