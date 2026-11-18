import struct, zlib, re, sys, os, numpy as np
from mdp import read_mdp, decode_layer
from common import layer_ink
from PIL import Image

def parse_raw(path):
    d = open(path, 'rb').read()
    xl = struct.unpack('<I', d[12:16])[0]
    xml = d[20:20+xl].decode()
    chunks = []
    p = 20 + xl
    while p < len(d):
        sz = struct.unpack('<I', d[p+4:p+8])[0]
        name = d[p+68:p+132].split(b'\0')[0].decode()
        chunks.append([name, d[p:p+sz]])
        p += sz
    return d[:12], xml, chunks

def rename_chunk(raw, new):
    nb = new.encode().ljust(64, b'\0')
    return raw[:68] + nb + raw[132:]

def encode_layer(rgba, ts=128):
    """rgba: HxWx4 uint8 RGBA (straight alpha). Returns layer body + full PAC chunk builder."""
    h, w = rgba.shape[:2]
    bgra = rgba[..., [2, 1, 0, 3]]
    tiles = []
    for ty in range((h + ts - 1)//ts):
        for tx in range((w + ts - 1)//ts):
            t = np.zeros((ts, ts, 4), np.uint8)
            blk = bgra[ty*ts:(ty+1)*ts, tx*ts:(tx+1)*ts]
            if not blk[..., 3].any(): continue
            t[:blk.shape[0], :blk.shape[1]] = blk
            z = zlib.compress(t.tobytes(), 6)
            tiles.append(struct.pack('<4I', tx, ty, 0, len(z)) + z + b'\0'*((4 - len(z) % 4) % 4))
    return struct.pack('<2I', len(tiles), ts) + b''.join(tiles)

def encode_placed(rgba, ox, oy, ts=128):
    """Layer body for `rgba` placed at (ox, oy) >= 0 inside a larger, otherwise empty layer whose
    origin is (0, 0): only the tiles the picture touches are written."""
    h, w = rgba.shape[:2]
    bgra = rgba[..., [2, 1, 0, 3]]
    tiles = []
    for ty in range(oy // ts, (oy + h - 1) // ts + 1):
        for tx in range(ox // ts, (ox + w - 1) // ts + 1):
            t = np.zeros((ts, ts, 4), np.uint8)
            y0, x0 = ty * ts, tx * ts
            sy0, sx0 = max(y0, oy), max(x0, ox)
            sy1, sx1 = min(y0 + ts, oy + h), min(x0 + ts, ox + w)
            t[sy0 - y0:sy1 - y0, sx0 - x0:sx1 - x0] = bgra[sy0 - oy:sy1 - oy, sx0 - ox:sx1 - ox]
            if not t[..., 3].any(): continue
            z = zlib.compress(t.tobytes(), 6)
            tiles.append(struct.pack('<4I', tx, ty, 0, len(z)) + z + b'\0'*((4 - len(z) % 4) % 4))
    return struct.pack('<2I', len(tiles), ts) + b''.join(tiles)

def pac(name, body):
    hdr = b'PAC ' + struct.pack('<4I', 132 + len(body), 0, len(body), len(body)) + b'\0'*48 + name.encode().ljust(64, b'\0')
    assert len(hdr) == 132
    return hdr + body

def add_folder(path, out, insert_after_index, folder_name, layers):
    """layers: list of (name, rgba) or (name, rgba, x, y) bottom->top; a placed picture may reach past
    the canvas's right or bottom edge (the layer grows to hold it). Inserted as children of a new folder placed right above
    the existing layer at insert_after_index. Existing layers' data is copied byte for byte."""
    head, xml, chunks = parse_raw(path)
    entries = list(re.finditer(r'[ \t]*<Layer [^>]*/>\n', xml))
    attrs = [dict(re.findall(r'(\w+)="([^"]*)"', m.group(0))) for m in entries]
    W = int(re.search(r'<Mdiapp width="(\d+)"', xml).group(1)); H = int(re.search(r'<Mdiapp[^>]* height="(\d+)"', xml).group(1))
    ids = [int(a['id']) for a in attrs]
    nid = max(ids) + 1
    fid = nid + len(layers)
    tmpl32 = next(m.group(0) for m, a in zip(entries, attrs) if a['type'] == '32bpp')
    tmplF = next((m.group(0) for m, a in zip(entries, attrs) if a['type'] == 'folder'), None)
    def setattrs(s, kv):
        for k, v in kv.items():
            s, n = re.subn(rf'\b{k}="[^"]*"', f'{k}="{v}"', s)
            if n == 0: s = s.replace(' />', f' {k}="{v}" />')
        return s
    new_entries = []
    for i, (name, rgba, *at) in enumerate(layers):
        if at:
            x, y = at
            lw, lh, body = max(W, x + rgba.shape[1]), max(H, y + rgba.shape[0]), encode_placed(rgba, x, y)
        else:
            lw, lh, body = W, H, encode_layer(rgba)
        new_entries.append(('new', setattrs(tmpl32, dict(ofsx=0, ofsy=0, width=lw, height=lh, mode='normal', alpha=255, visible='true',
            protectAlpha='false', locked='false', clipping='false', masking='false', maskingType=0, group=-1, id=nid+i, draft='false',
            parentId=fid, name=name, type='32bpp')), body))
    if tmplF is None:
        tmplF = tmpl32.replace('type="32bpp"', 'type="folder"')
    fe = setattrs(tmplF, dict(ofsx=0, ofsy=0, width=W, height=H, mode='through', alpha=255, visible='true', protectAlpha='false',
        locked='false', clipping='false', masking='false', maskingType=0, group=-1, id=fid, draft='false', parentId=-1,
        name=folder_name, folderOpen='true', type='folder'))
    new_entries.append(('new', fe, None))
    old = [('old', m.group(0), a) for m, a in zip(entries, attrs)]
    order = old[:insert_after_index+1] + new_entries + old[insert_after_index+1:]
    # renumber bins in stacking order (MediBang's own convention: layer0img, layer1img, ...)
    cmap = {n: raw for n, raw in chunks}
    out_entries, out_chunks = [], [c for c in chunks if c[0] == 'thumb']
    for i, e in enumerate(order):
        b = f'layer{i}img'
        if e[0] == 'old':
            s, a = e[1], e[2]
            s = re.sub(r'\bbin="[^"]*"', f'bin="{b}"', s)
            if a['bin'] in cmap: out_chunks.append([b, rename_chunk(cmap[a['bin']], b)])
        else:
            s = re.sub(r'\bbin="[^"]*"', f'bin="{b}"', e[1])
            if e[2] is not None: out_chunks.append([b, pac(b, e[2])])
        out_entries.append(s)
    # every original chunk accounted for
    assert len(out_chunks) == len(chunks) + len(layers), (len(out_chunks), len(chunks))
    first, last = entries[0].start(), entries[-1].end()
    xml2 = xml[:first] + ''.join(out_entries) + xml[last:]
    act = int(re.search(r'<Layers active="(\d+)"', xml).group(1))
    if act > insert_after_index: act += len(new_entries)
    xml2 = re.sub(r'<Layers active="\d+"', f'<Layers active="{act}"', xml2, count=1)
    xb = xml2.encode()
    body = b''.join(c[1] for c in out_chunks)
    data = head + struct.pack('<2I', len(xb), len(body)) + xb + body
    open(out, 'wb').write(data)
    return order

def add_to_folder(path, out, folder_name, layers):
    """Like add_folder, but into the existing top-level folder `folder_name`: the new layers
    (bottom->top) go on top of what it already holds. Existing layers' data is copied byte for byte."""
    head, xml, chunks = parse_raw(path)
    entries = list(re.finditer(r'[ \t]*<Layer [^>]*/>\n', xml))
    attrs = [dict(re.findall(r'(\w+)="([^"]*)"', m.group(0))) for m in entries]
    W = int(re.search(r'<Mdiapp width="(\d+)"', xml).group(1)); H = int(re.search(r'<Mdiapp[^>]* height="(\d+)"', xml).group(1))
    fi = next(i for i, a in enumerate(attrs) if a['type'] == 'folder' and a['name'] == folder_name)
    fid = attrs[fi]['id']
    nid = max(int(a['id']) for a in attrs) + 1
    tmpl32 = next(m.group(0) for m, a in zip(entries, attrs) if a['type'] == '32bpp')
    def setattrs(s, kv):
        for k, v in kv.items():
            s, n = re.subn(rf'\b{k}="[^"]*"', f'{k}="{v}"', s)
            if n == 0: s = s.replace(' />', f' {k}="{v}" />')
        return s
    new_entries = []
    for i, (name, rgba, *at) in enumerate(layers):
        if at:
            x, y = at
            lw, lh, body = max(W, x + rgba.shape[1]), max(H, y + rgba.shape[0]), encode_placed(rgba, x, y)
        else:
            lw, lh, body = W, H, encode_layer(rgba)
        new_entries.append(('new', setattrs(tmpl32, dict(ofsx=0, ofsy=0, width=lw, height=lh, mode='normal', alpha=255, visible='true',
            protectAlpha='false', locked='false', clipping='false', masking='false', maskingType=0, group=-1, id=nid+i, draft='false',
            parentId=fid, name=name, type='32bpp')), body))
    old = [('old', m.group(0), a) for m, a in zip(entries, attrs)]
    order = old[:fi] + new_entries + old[fi:]   # a folder's children come just before its own entry
    cmap = {n: raw for n, raw in chunks}
    out_entries, out_chunks = [], [c for c in chunks if c[0] == 'thumb']
    for i, e in enumerate(order):
        b = f'layer{i}img'
        if e[0] == 'old':
            s, a = e[1], e[2]
            s = re.sub(r'\bbin="[^"]*"', f'bin="{b}"', s)
            if a['bin'] in cmap: out_chunks.append([b, rename_chunk(cmap[a['bin']], b)])
        else:
            s = re.sub(r'\bbin="[^"]*"', f'bin="{b}"', e[1])
            out_chunks.append([b, pac(b, e[2])])
        out_entries.append(s)
    assert len(out_chunks) == len(chunks) + len(layers), (len(out_chunks), len(chunks))
    first, last = entries[0].start(), entries[-1].end()
    xml2 = xml[:first] + ''.join(out_entries) + xml[last:]
    act = int(re.search(r'<Layers active="(\d+)"', xml).group(1))
    if act >= fi: act += len(new_entries)
    xml2 = re.sub(r'<Layers active="\d+"', f'<Layers active="{act}"', xml2, count=1)
    xb = xml2.encode()
    body = b''.join(c[1] for c in out_chunks)
    open(out, 'wb').write(head + struct.pack('<2I', len(xb), len(body)) + xb + body)
    return order

def build_rgba(f, fixed, rows=None):
    """New layer: opaque white exactly where the old layer was opaque, high-res ink drawn on it."""
    old = np.array(Image.open(f'{f}/{fixed}.png').convert('RGBA'))
    ink = np.load(f'ink_{f}_{fixed}.npy').astype(np.float32)
    a_old = old[..., 3].astype(np.float32)/255
    a = 1 - (1 - a_old)*(1 - ink)
    if rows is not None:
        m = np.zeros(a.shape, bool); m[rows[0]:rows[1]] = True
        a = np.where(m, a, 0); ink = np.where(m, ink, 0)
    with np.errstate(invalid='ignore', divide='ignore'):
        g = np.where(a > 0, 255*a_old*(1-ink)/np.maximum(a, 1e-6), 0)
    g = np.clip(np.where(a > 0, np.minimum(g, 255), 0), 0, 255)
    # pixels where ink extends beyond the old footprint: pure black ink with its own alpha
    rgba = np.dstack([g, g, g, a*255]).round().astype(np.uint8)
    rgba[rgba[..., 3] == 0] = 0
    return rgba
