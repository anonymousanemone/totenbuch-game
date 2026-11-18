"""Cut the Survival pieces (the layers cut out of the figures in the .mdp) into game sprites,
without re-cutting the rest of the level.

Each piece is saved as godot/assets/survival/figures/<key>.png and listed in level.json under
"pieces". The figures they were cut from are cut again at their saved bounds, so the scene's
sprites keep their positions. Two avatar looks are also made: the 44 and 51 men with their heads.

    python .claude/skills/build-levels/extract_survival_pieces.py            # all pieces
    python .claude/skills/build-levels/extract_survival_pieces.py KEY ...    # only these pieces (and their figures), or figures

The .mdp is only read.
"""
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from mdp import read_mdp
from cutlib import canvas_of, save_ink as save_figure

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'art/survival43-63.mdp'
OUT = ROOT / 'godot/assets/survival'

# piece layer id: (key, the figure or caption it was cut from)
PIECES = {
    1156: ('spell43_sceptre1', 'spell43_osiris'),
    1157: ('spell43_sceptre2', 'spell43_osiris'),
    1082: ('spell43_sceptre3', 'spell43_osiris'),
    1083: ('spell44_door', 'spell44_shrine'),
    1084: ('spell44_head', 'spell44_staff_bearer'),
    1085: ('spell45_mummy_body', 'spell45_mummy'),
    1086: ('spell45_mummy_head', 'spell45_mummy'),
    1167: ('spell45_arm', 'spell45_mummy'),
    1158: ('spell45_tm', 'spell45_caption_1033'),
    1087: ('spell47_ba', 'spell47_bird_shrine'),
    1159: ('spell47_seat', 'spell47_caption_1038'),
    1088: ('spell48_oar', 'spell48_caption_1041'),
    1089: ('spell48_feather', 'spell48_caption_1041'),
    1090: ('spell51_head', 'spell51_walking_man'),
    1122: ('spell52_altar', 'spell52_seated_man'),
    1091: ('spell52_chair', 'spell52_seated_man'),
    1092: ('spell52_arm', 'spell52_seated_man'),
    1126: ('spell52_forearm', 'spell52_seated_man'),
    1093: ('spell52_head', 'spell52_seated_man'),
    1127: ('spell52_excrement', 'spell52_caption_1049'),
    1123: ('spell53_offering_table', 'spell53_seated_man'),
    **{lid: (f'spell53_loaf{n}', 'spell53_seated_man')
       for lid, n in [(1131, 1), (1132, 2), (1133, 3), (1134, 4), (1135, 5), (1136, 6), (1137, 7)]},
    **{lid: (f'spell53_whisp{n}', 'spell53_seated_man')
       for lid, n in [(1138, 1), (1139, 2), (1140, 3), (1141, 4), (1094, 5)]},
    1101: ('spell53_chair', 'spell53_seated_man'),
    1130: ('spell53_arm', 'spell53_seated_man'),
    1102: ('spell53_forearm', 'spell53_seated_man'),
    1142: ('spell53_hand', 'spell53_seated_man'),
    1103: ('spell53_head', 'spell53_seated_man'),
    1124: ('spell59_seated_man', 'spell59_tree'),
    1104: ('spell59_stream', 'spell59_tree'),
    1105: ('spell59_chair', 'spell59_tree'),
    **{lid: (f'spell59_mw{n}', 'spell59_caption_1071')
       for lid, n in [(1111, 1), (1110, 2), (1109, 3), (1108, 4), (1107, 5), (1106, 6)]},
    1147: ('spell57_stream', 'spell57_tree'),
    1125: ('spell57_man', 'spell57_tree'),
    1114: ('spell57_tray', 'spell57_tree'),
    1115: ('spell62_sail', 'spell62_breath'),
    1116: ('spell61_sail', 'spell61_breath'),
    1117: ('spell60_sail', 'spell60_breath'),
    1118: ('spell56_sail', 'spell56_ankh'),
    1119: ('spell55_sail', 'spell55_breath'),
    1120: ('spell54_sail', 'spell54_breath'),
    1121: ('spell58_sail', 'spell58_drinking'),
    1155: ('spell58_nw', 'spell58_drinking'),
}
# One layer holding several separate marks, cut into one piece per mark (left to right, split where
# there is a gap in the ink of more than SPLIT_GAP px): layer id -> key prefix. These lie over drawing
# that stays (the four breath signs where a sail can be found are also drawn in their texts).
SPLITS = {1162: 'breath_loc'}
SPLIT_GAP = 20
# Figures that were part of another layer and now have their own: layer id -> (key, spell). Cut to
# their ink and added to level.json when missing (the scene needs a sprite for them).
NEW_FIGURES = {1129: ('spell53_caption_1129', 53)}
# The seated men's arms, turned about their joints in the game: (upper arm, forearm, hand or None).
# Each joint is where the two pieces overlap; the shoulder is the far end of the upper arm, and with no
# hand the tip is the far end of the forearm. Strip px, in level.json "rigs".
RIGS = {'spell52': ('spell52_arm', 'spell52_forearm', None),
        'spell53': ('spell53_arm', 'spell53_forearm', 'spell53_hand')}
# Whole looks for the walking avatar: a figure with the head cut from it put back on.
AVATARS = {'avatar_44': ('spell44_staff_bearer', 'spell44_head'),
           'avatar_51': ('spell51_walking_man', 'spell51_head')}


def ink(layer, chunks):
    """The layer's ink as alpha (darkness times opacity), as the scene builder measures it."""
    return canvas_of(layer, SIZE[0], SIZE[1], chunks, False)


def save_ink(alpha, name):
    save_figure(alpha, OUT, name)


def bbox(alpha):
    box = Image.fromarray(alpha).getbbox()
    assert box
    return box


def joint(a, b):
    """The middle of where the ink of `a` and `b` (whole-strip alphas) meet."""
    def grow(x, r=2):
        m = np.pad(x > 8, r)
        out = np.zeros(x.shape, bool)
        for dy in range(2 * r + 1):
            for dx in range(2 * r + 1):
                out |= m[dy:dy + x.shape[0], dx:dx + x.shape[1]]
        return out
    ys, xs = np.nonzero(grow(a) & grow(b))
    assert len(xs), 'the two pieces do not meet'
    return [round(float(xs.mean()), 1), round(float(ys.mean()), 1)]


def far_end(a, p):
    """The ink pixel of `a` farthest from `p`."""
    ys, xs = np.nonzero(a > 8)
    i = int(np.argmax((xs - p[0]) ** 2 + (ys - p[1]) ** 2))
    return [float(xs[i]), float(ys[i])]


def main(keys):
    global SIZE
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    w, h, layers, chunks, _ = read_mdp(SOURCE)
    SIZE = (w, h)
    level = json.loads((OUT / 'level.json').read_text())
    by_id = {int(l['id']): l for l in layers}
    figure_ids = {key: item['source_layer'] for key, item in level['figures'].items()}
    wanted = {lid: v for lid, v in PIECES.items() if not keys or v[0] in keys}
    pieces = level.setdefault('pieces', {})
    canvases = {}
    for lid, (key, figure) in wanted.items():
        alpha = ink(by_id[lid], chunks)
        canvases[key] = alpha
        x0, y0, x1, y1 = bbox(alpha)
        save_ink(alpha[y0:y1, x0:x1], key)
        pieces[key] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0, figure=figure, source_layer=lid)
    for lid, prefix in SPLITS.items():
        if keys and not any(k.startswith(prefix) for k in keys):
            continue
        alpha = ink(by_id[lid], chunks)
        cols = np.nonzero((alpha > 8).any(0))[0]
        runs, start = [], cols[0]
        for a, b in zip(cols, cols[1:]):
            if b - a > SPLIT_GAP:
                runs.append((start, a + 1))
                start = b
        runs.append((start, cols[-1] + 1))
        for n, (c0, c1) in enumerate(runs, 1):
            part = np.zeros_like(alpha)
            part[:, c0:c1] = alpha[:, c0:c1]
            x0, y0, x1, y1 = bbox(part)
            key = f'{prefix}{n}'
            save_ink(part[y0:y1, x0:x1], key)
            pieces[key] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0, figure=None, source_layer=lid)
    for lid, (key, spell) in NEW_FIGURES.items():
        if keys and key not in keys:
            continue
        alpha = ink(by_id[lid], chunks)
        x0, y0, x1, y1 = bbox(alpha)
        save_ink(alpha[y0:y1, x0:x1], key)
        level['figures'][key] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0, spell=spell, source_layer=lid)
    for name, parts in RIGS.items():
        if all(p is None or p in canvases for p in parts):
            arm, fore, hand = (None if p is None else canvases[p] for p in parts)
            elbow = joint(arm, fore)
            rig = dict(shoulder=far_end(arm, elbow), elbow=elbow)
            if hand is None:
                rig['tip'] = far_end(fore, elbow)
            else:
                rig['wrist'] = joint(fore, hand)
            level.setdefault('rigs', {})[name] = rig
    # the figures, cut again at the bounds the scene has them at
    # the figures the pieces were cut from, and any figure named itself
    named = {k for k in keys if k in level['figures']}
    for figure in sorted({f for _, f in wanted.values() if f} | named):
        item = level['figures'][figure]
        alpha = ink(by_id[figure_ids[figure]], chunks)
        x, y, fw, fh = item['x'], item['y'], item['w'], item['h']
        outside = alpha.copy()
        outside[y:y + fh, x:x + fw] = 0
        assert not outside.any(), f'{figure} has ink outside its saved bounds'
        save_ink(alpha[y:y + fh, x:x + fw], figure)
    for name, (figure, head) in AVATARS.items():
        if figure in {f for _, f in wanted.values()}:
            item = level['figures'][figure]
            body = ink(by_id[figure_ids[figure]], chunks)
            head_alpha = ink(by_id[next(l for l, v in PIECES.items() if v[0] == head)], chunks)
            whole = np.maximum(body, head_alpha)
            x0, y0, x1, y1 = bbox(whole)
            save_ink(whole[y0:y1, x0:x1], name)
            level.setdefault('avatars', {})[name] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0)
    level['sha256'] = digest
    (OUT / 'level.json').write_text(json.dumps(level, indent=1) + '\n')
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == digest
    print(f'Survival pieces: {len(wanted)} cut; MDP unchanged.')


if __name__ == '__main__':
    main(set(sys.argv[1:]))
