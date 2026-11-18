"""What the cutters, scene builders and sheet makers share: the ink colour, ink as an image, and a layer
of an .mdp as ink on the full canvas."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent / "mdp300"))
from mdp import decode_layer  # noqa: E402

INK = (46, 29, 16)             # dark brown, reads as ink on papyrus
PAPYRUS = (226, 208, 166)


def ink_rgba(alpha):
    """`alpha` (0..255 coverage) as an INK-coloured RGBA image, transparent elsewhere."""
    out = np.zeros(alpha.shape + (4,), np.uint8)
    out[..., 0], out[..., 1], out[..., 2] = INK
    out[..., 3] = alpha
    return Image.fromarray(out)


def save_ink(alpha, out, key):
    """`alpha` as <out>/figures/<key>.png."""
    (Path(out) / 'figures').mkdir(parents=True, exist_ok=True)
    ink_rgba(alpha).save(Path(out) / 'figures' / f'{key}.png')


def canvas_of(layer, w, h, chunks, raw_alpha):
    """Ink alpha of one layer placed on the full canvas. `raw_alpha` layers (the scan's backing is
    already transparent) keep their alpha; the others become ink by darkness times alpha."""
    image = decode_layer(chunks[layer['bin']], int(layer['width']), int(layer['height']), '32bpp')
    alpha = image[..., 3] if raw_alpha else np.rint(
        (255 - image[..., :3].mean(2)) * image[..., 3] / 255).astype(np.uint8)
    alpha[alpha <= 8] = 0
    canvas = np.zeros((h, w), np.uint8)
    ox, oy = int(layer['ofsx']), int(layer['ofsy'])
    x0, y0 = max(0, ox), max(0, oy)
    x1, y1 = min(w, ox + alpha.shape[1]), min(h, oy + alpha.shape[0])
    canvas[y0:y1, x0:x1] = alpha[y0-oy:y1-oy, x0-ox:x1-ox]
    return canvas

