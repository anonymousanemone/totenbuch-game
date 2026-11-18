"""Re-frame a strip .mdp: move every layer so the outer guide lines sit MARGIN px from the top and
from both ends, and set the canvas to (frame width + 2*MARGIN) x HEIGHT.

Nothing is cropped or redrawn: each layer's pixels are copied as they are and only placed at a new
offset; a layer grows (negative ofsx/ofsy, as MediBang does itself) wherever it would no longer cover
the canvas or its content would fall off it. The plain white 'bg' layer is refilled to the new canvas.

    python resize_canvas.py <in.mdp> <out.mdp> [margin=30] [height=1000]
"""
import re, struct, sys
from pathlib import Path
import numpy as np
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools' / 'mdp300'))
from mdp import read_mdp, decode_layer
from write_mdp import parse_raw, encode_layer, pac

GUIDES = ("horizont", "vertical", "Layer1017")   # the outer frame lines live in these guide layers


def frame_box(W, H, layers, chunks):
    """(x0, y0, x1, y1) of all guide-line ink, in canvas pixels (inclusive)."""
    box = None
    for i, L in enumerate(layers):
        if L['type'] == 'folder' or L['name'] not in GUIDES:
            continue
        a = decode_layer(chunks[L['bin']], int(L['width']), int(L['height']), L['type'])[..., 3] > 128
        ys, xs = np.nonzero(a)
        b = (xs.min() + int(L['ofsx']), ys.min() + int(L['ofsy']), xs.max() + int(L['ofsx']), ys.max() + int(L['ofsy']))
        box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    return box


def resize(src, dst, margin=30, height=1000):
    W, H, layers, chunks, _ = read_mdp(src)
    x0, y0, x1, _ = frame_box(W, H, layers, chunks)
    dx, dy = margin - x0, margin - y0
    W2, H2 = x1 - x0 + 1 + 2 * margin, height
    head, xml, raw = parse_raw(src)
    entries = list(re.finditer(r'[ \t]*<Layer [^>]*/>\n', xml))
    new_chunks = {}
    out_entries = []
    for m, L in zip(entries, layers):
        s = m.group(0)
        if L['type'] == 'folder':
            kv = dict(ofsx=0, ofsy=0, width=W2, height=H2)
        else:
            assert L['type'] == '32bpp', L['type']
            w, h, ox, oy = int(L['width']), int(L['height']), int(L['ofsx']) + dx, int(L['ofsy']) + dy
            img = decode_layer(chunks[L['bin']], w, h, L['type'])[..., [2, 1, 0, 3]]   # stored BGRA -> RGBA
            if L['name'] == 'bg' and (img[..., 3] == 255).all() and (img[..., :3] == 255).all():
                nx, ny, img2 = 0, 0, np.full((H2, W2, 4), 255, np.uint8)
            else:
                nx, ny = min(0, ox), min(0, oy)
                nw, nh = max(W2, ox + w) - nx, max(H2, oy + h) - ny
                img2 = np.zeros((nh, nw, 4), np.uint8)
                img2[oy - ny:oy - ny + h, ox - nx:ox - nx + w] = img
            kv = dict(ofsx=nx, ofsy=ny, width=img2.shape[1], height=img2.shape[0])
            new_chunks[L['bin']] = pac(L['bin'], encode_layer(img2))
        for k, v in kv.items():
            s = re.sub(rf'\b{k}="[^"]*"', f'{k}="{v}"', s)
        out_entries.append(s)
    first, last = entries[0].start(), entries[-1].end()
    xml2 = xml[:first] + ''.join(out_entries) + xml[last:]
    xml2 = re.sub(r'(<Mdiapp[^>]*?) width="\d+"', rf'\1 width="{W2}"', xml2, count=1)
    xml2 = re.sub(r'(<Mdiapp[^>]*?) height="\d+"', rf'\1 height="{H2}"', xml2, count=1)
    body = b''.join(new_chunks.get(name, c) for name, c in raw)
    xb = xml2.encode()
    open(dst, 'wb').write(head + struct.pack('<2I', len(xb), len(body)) + xb + body)
    return (W, H), (W2, H2), (dx, dy)


if __name__ == '__main__':
    a = sys.argv[1:]
    print(resize(a[0], a[1], *(int(v) for v in a[2:])))
