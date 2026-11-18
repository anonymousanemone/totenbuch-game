"""Images for the menus: a picture per scene of the scroll, the title page's frontispiece, the
band standing up, and a few pixel icons.

    python .claude/skills/make-artwork/menu_images.py <screenshots dir>

The screenshots dir holds 1280x720 frames of the built levels (`-- --level=<key> --screenshot=...`),
named <key>.png, plus frontispiece.png (the procession at Ra). Scenes without a screenshot are cut
from their Lepsius plate in art/og_300dpi. Writes godot/assets/menu/ and godot/assets/ui/.
"""
import os, sys
from PIL import Image, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
SHOTS = sys.argv[1]
MENU = f'{ROOT}/godot/assets/menu'
UI = f'{ROOT}/godot/assets/ui'
INK, PAPYRUS = (46, 29, 16), (226, 208, 166)
SIZE = (440, 280)             # twice the card's 220x140, for sharpness on larger windows
SCENE_BOX = (0, 62, 1280, 600)  # the scene between the HUD's bars in a screenshot

# plate number and the crop (fractions of the page) for each scene not yet built
PLATES = {
    'sun': (6, 0.02, 0.05, 0.36, 0.25), 'councils': (12, 0.2, 0.06, 0.62, 0.22),
    'mouth': (14, 0.1, 0.06, 0.52, 0.22), 'survival': (21, 0.25, 0.06, 0.67, 0.22),
    'forth': (25, 0.1, 0.06, 0.52, 0.22), 'forms': (31, 0.15, 0.06, 0.57, 0.22),
    'ba': (33, 0.45, 0.06, 0.87, 0.22), 'boats': (34, 0.5, 0.06, 0.92, 0.22),
    'souls': (44, 0.3, 0.06, 0.72, 0.22), 'lake': (51, 0.55, 0.06, 0.97, 0.22),
    'gates': (61, 0.1, 0.06, 0.52, 0.22), 'baboons': (68, 0.3, 0.06, 0.72, 0.22),
    'cows': (70, 0.0, 0.1, 0.42, 0.26), 'mounds': (71, 0.1, 0.06, 0.52, 0.22),
    'chamber': (74, 0.55, 0.06, 0.97, 0.22), 'amulets': (75, 0.5, 0.06, 0.92, 0.22),
    'creatures': (78, 0.1, 0.06, 0.52, 0.22),
}
BUILT = ['procession', 'dangers']   # the archived levels keep the pictures made while they were built

ICONS = {
    'ankh': ["..###..", ".#...#.", ".#...#.", "..#.#..", "#######", "...#...", "...#...", "...#..."],
    'back': ["...#....", "..##....", ".#######", "########", ".#######", "..##....", "...#...."],
    'settings': ["..#....", "#####.#", "..#..##", ".......", "#.#####", "##..#..", "#......"],
}

# hieroglyphs for the strip's buttons, drawn at the font's pixel size at 32 px (one dot = 2 px):
# straight lines one dot wide, slants two dots, so both read the same weight
SIGNS = {
    'journal': [  # 𓏞 the scribe's palette, water pot and reed holder
        "......#####...........##...##.",
        ".....##...##..........#.#.#.#.",
        "....##.....##.........#..#..#.",
        "....#.......#..........##.##..",
        "....#.......#...........###...",
        "....#.......#............#....",
        "....#.......#............####.",
        "....#.......#............####.",
        "....#.......#.........######..",
        "....#.......#.......######....",
        "....#.......#.....####...#....",
        "....#.......#...####.....#....",
        "##########..#..###.......#....",
        "#........#..#.##.........#....",
        "#..####..#.########......#....",
        "#.##..##.#..#....#.......#....",
        "#.#....#.#..#....#.......#....",
        "#.#....#.#..#....#.......#....",
        "#.##..##.#..##..##.......#....",
        "#..####..#...####........#....",
        "#........#...............#....",
        "#..####..#...............#....",
        "#.######.#...............#....",
        "#.######.#...............#....",
        "#.######.#...............#....",
        "#.######.#...............#....",
        "#..####..#...............#....",
        "#........#...............#....",
        "##########...............#....",
    ],
    'hint': [  # 𓂜 the negative arms, twice over
        "................###................",
        "...............##.##...............",
        "...............##.##...............",
        "..............##...##..............",
        "..............##...##..............",
        ".####........##.....##........####.",
        "....##########.......##########....",
        "#############.........#############",
        "...................................",
        "...................................",
        "................###................",
        "...............##.##...............",
        "...............##.##...............",
        "..............##...##..............",
        "..............##...##..............",
        ".####........##.....##........####.",
        "....##########.......##########....",
        "#############.........#############",
    ],
}


def fit(im, size=SIZE):
    """Centre-crop to the size's proportions, then scale."""
    w, h = size
    W, H = im.size
    if W / H > w / h:
        nw = int(H * w / h)
        im = im.crop(((W - nw) // 2, 0, (W - nw) // 2 + nw, H))
    else:
        nh = int(W * h / w)
        im = im.crop((0, (H - nh) // 2, W, (H - nh) // 2 + nh))
    return im.resize(size, Image.LANCZOS)


def plate(n, x0, y0, x1, y1):
    im = Image.open(f'{ROOT}/art/og_300dpi/page_%04d.png' % n).convert('L')
    W, H = im.size
    im = im.crop((int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H)))
    return ImageOps.colorize(ImageOps.autocontrast(im, cutoff=1), INK, PAPYRUS)


def pixels(rows, scale=4):
    im = Image.new('RGBA', (len(rows[0]), len(rows)), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c == '#':
                im.putpixel((x, y), INK + (255,))
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


os.makedirs(MENU, exist_ok=True)
for key in BUILT:
    fit(Image.open(f'{SHOTS}/{key}.png').convert('RGB').crop(SCENE_BOX)).save(f'{MENU}/{key}.png')
for key, p in PLATES.items():
    fit(plate(*p)).save(f'{MENU}/{key}.png')
front = Image.open(f'{SHOTS}/frontispiece.png').convert('RGB').crop((60, 176, 580, 468))
fit(front, (720, 420)).save(f'{MENU}/frontispiece.png')
Image.open(f'{UI}/band_top.png').rotate(90, expand=True).save(f'{UI}/band_vertical.png')
for name, rows in ICONS.items():
    pixels(rows).save(f'{UI}/icon_{name}.png')
for name, rows in SIGNS.items():
    pixels(rows, 2).save(f'{UI}/icon_{name}.png')
print('wrote', len(BUILT) + len(PLATES), 'scene pictures, the frontispiece, the vertical band and', len(ICONS) + len(SIGNS), 'icons')
