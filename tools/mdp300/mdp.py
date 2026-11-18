import struct, zlib, re
import numpy as np

def read_mdp(path):
    d = open(path, 'rb').read()
    xl = struct.unpack('<I', d[12:16])[0]
    xml = d[20:20+xl].decode()
    hdr = re.search(r'<Mdiapp[^>]*>', xml).group(0)
    W = int(re.search(r'width="(\d+)"', hdr).group(1)); H = int(re.search(r'height="(\d+)"', hdr).group(1))
    layers = []
    for m in re.finditer(r'<Layer [^>]*>', xml):
        s = m.group(0)
        layers.append({k: v for k, v in re.findall(r'(\w+)="([^"]*)"', s)})
    chunks = {}
    p = 20 + xl
    while p < len(d):
        sz = struct.unpack('<I', d[p+4:p+8])[0]
        flag, clen, rlen = struct.unpack('<3I', d[p+8:p+20])
        name = d[p+68:p+132].split(b'\0')[0].decode()
        body = d[p+132:p+132+clen]
        if flag == 1: body = zlib.decompress(body)
        chunks[name] = body
        p += sz
    return W, H, layers, chunks, xml

def decode_layer(body, w, h, typ):
    if typ == 'folder' or len(body) < 8: return None
    ntiles, ts = struct.unpack('<2I', body[:8])
    ch = 4 if typ == '32bpp' else 1
    img = np.zeros((h, w, ch), np.uint8)
    q = 8
    for _ in range(ntiles):
        tx, ty, fl, cl = struct.unpack('<4I', body[q:q+16]); q += 16
        raw = zlib.decompress(body[q:q+cl]); q += cl
        q += (4 - cl % 4) % 4
        t = np.frombuffer(raw, np.uint8).reshape(ts, ts, ch)
        y0, x0 = ty*ts, tx*ts
        hh, ww = min(ts, h-y0), min(ts, w-x0)
        img[y0:y0+hh, x0:x0+ww] = t[:hh, :ww]
    return img
