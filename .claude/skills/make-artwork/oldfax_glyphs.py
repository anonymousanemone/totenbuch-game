"""Add pixel glyphs to Old Fax: arrows and a middle dot, on its own grid (64 units = 1 px)."""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

SRC, DST = sys.argv[1], sys.argv[2]
PX = 64
# rows top to bottom; `base` is the height of the bottom row above the baseline, in px
GLYPHS = {
    0x2191: ('arrowup', 0, [
        "...##...",
        "..####..",
        ".######.",
        "########",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
    ]),
    0x2193: ('arrowdown', 0, [
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "########",
        ".######.",
        "..####..",
        "...##...",
    ]),
    0x00B7: ('periodcentered', 4, [
        "##",
        "##",
    ]),
}

# the side arrows are the up arrow turned on its side, pixel for pixel
UP = GLYPHS[0x2191][2]
RIGHT = ["".join(UP[len(UP) - 1 - x][y] for x in range(len(UP))) for y in range(len(UP[0]))]
GLYPHS[0x2192] = ('arrowright', 1, RIGHT)
GLYPHS[0x2190] = ('arrowleft', 1, [r[::-1] for r in RIGHT])

f = TTFont(SRC)
order = f.getGlyphOrder()
for cp, (name, base, rows) in GLYPHS.items():
    pen = TTGlyphPen(None)
    h = len(rows)
    for r, row in enumerate(rows):
        y = (base + h - 1 - r) * PX
        x = 0
        while x < len(row):          # one rectangle per run of ink in the row
            if row[x] != '#':
                x += 1
                continue
            x0 = x
            while x < len(row) and row[x] == '#':
                x += 1
            l, rgt = (x0 + 1) * PX, (x + 1) * PX       # 1 px left side bearing
            pen.moveTo((l, y)); pen.lineTo((l, y + PX)); pen.lineTo((rgt, y + PX)); pen.lineTo((rgt, y)); pen.closePath()
    if name not in order:
        order.append(name)
    f['glyf'].glyphs[name] = pen.glyph()
    f['hmtx'].metrics[name] = ((len(rows[0]) + 2) * PX, PX)
    for t in f['cmap'].tables:
        if t.isUnicode():
            t.cmap[cp] = name
f.setGlyphOrder(order)
f['glyf'].glyphOrder = order
f['maxp'].numGlyphs = len(order)
for tag in ('hdmx', 'LTSH', 'VDMX'):
    if tag in f:
        del f[tag]
f.save(DST)
print('added', [g[0] for g in GLYPHS.values()])
