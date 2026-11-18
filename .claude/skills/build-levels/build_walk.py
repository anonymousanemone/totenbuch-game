"""Export a walk-only level (one lane, no puzzles) from its hand-edited MDP and write its saved scene.

    python .claude/skills/build-levels/build_walk.py mounds|mouth|hall|doors [--into DIR]

  mounds  art/mounds149.mdp   spell 149, the fourteen mounds      -> godot/assets/mounds, scenes/mounds.tscn
  mouth   art/heart21-30.mdp  spells 21-30, mouth and heart       -> godot/assets/mouth,  scenes/mouth.tscn
  hall    art/judgement125.mdp spell 125, the weighing of the heart -> godot/assets/hall,  scenes/hall.tscn
  doors   art/thoth161.mdp    spell 161, Thoth opens the doors of the sky -> godot/assets/doors, scenes/doors.tscn

The MDP is only read, and checked unchanged at the end. Writes, under godot/ (or DIR/godot with --into,
which is how to check the tool without touching the repository):

  assets/<key>/figures/*.png   every figure and caption, cropped to its ink, and the strip
  assets/<key>/level.json      stable IDs, source rectangles (MDP canvas pixels), ground, columns
  assets/<key>/registry.json   written only when it does not exist, so edited descriptions survive
  scenes/<key>.tscn            written only when it does not exist, so placement edited in Godot survives

Where the pieces come from:
  - Each visible layer inside a spell (or mound) folder is one sprite, keyed by layer ID, which stays
    put when a layer is renamed or moved. In the hall, every layer inside the folders named in `roots` is
    one (its group is its top folder); the adoring deceased is the avatar alone. A `toptext` layer is the spell's caption (CAPTIONS).
  - The strip is every other visible layer: the plates' leftover ink, the lower inscriptions and the
    frame guides. Hidden layers and folders (`keys`, the old plates) stay out, except the hall's `captions` folder, which is read though hidden.
  - Doors has no folders: its drawing is one layer (`edited`), cut into figures by rectangle (PIECES). Each patch
    of ink goes to the rectangle that holds its middle; what no rectangle holds stays in the strip. The two registers
    stay stacked as drawn and the avatar walks the lower one. There is no deceased on the plate, so the avatar is the
    hall's, scaled to the Thoths; this level also writes its map picture (the upper register).
  - A column is tall hieroglyphic text that rises into the row the avatar walks along (the lower text
    above the ground line). The scene lays it over the avatar on papyrus, rule to rule.
"""
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
TOOLS = Path(__file__).resolve().parents[3] / 'tools'
sys.path[0:0] = [str(TOOLS), str(TOOLS / 'mdp300')]
from mdp import read_mdp
from cutlib import canvas_of, save_ink
from build_scene import save_menu_picture

ROOT = Path(__file__).resolve().parents[3]
SCALE = 1.5                  # the avatar's walking speed and the camera's limits are in units of this
VIEW_TOP = 20                # the first row the camera shows: just above the frame
BELOW_GROUND = 215           # rows shown under the ground line: the head of the lower inscriptions

# Layer ID -> (name, description, reference). The ID of a sprite is its folder's prefix plus the layer name.
HALL_FIGURES = {}   # filled below, with the assessors' invocations
MOUND_FIGURES = {
    '2029': ('Adorer', 'A figure in a wig raises one hand in adoration.', 'as drawn'),
    '2030': ('Stand', 'A tall stand narrows at the waist and splays at the foot, with a small dish on top.', 'as drawn'),
    '2031': ('Falcon', 'A falcon stands on a low base, its tail feathers trailing behind it.', 'as drawn'),
    '2032': ('Snake', 'A snake winds in loops along the ground, its head raised.', 'as drawn'),
    '2033': ('Kneeling figure', 'A figure kneels with one knee raised and an arm lifted, in a banded kilt.', 'as drawn'),
    '2034': ('Mummy', 'A wrapped figure stands upright with one arm raised, a small round sign at its side.', 'as drawn'),
    '2035': ('Two-headed figure', 'A figure with two heads walks with a knife in each hand.', 'as drawn'),
    '2036': ('Jackal-headed god', "A god with a jackal's head stands upright in a banded kilt.", 'as drawn'),
    '2037': ('Sphinx', 'A sphinx with a wigged human head lies down.', 'as drawn'),
    '2038': ('Sphinx', 'A sphinx with a wigged human head lies down.', 'as drawn'),
    '2039': ('Reclining figure', "A figure lies stretched out flat, its body banded like a mummy's.", 'as drawn'),
    '2040': ('Crocodile-headed figure', "A figure with a crocodile's head and a long wig stands upright.", 'as drawn'),
    '2041': ('Scarab', 'A scarab beetle with a round disc on its back, its legs curving beneath it.', 'as drawn'),
    '2042': ('Seated god', 'A god in a tall headdress sits on a block seat, holding upright stems in one hand.', 'as drawn'),
    '2043': ('Dais', 'A low dais is drawn as two long lines under the seated god.', 'as drawn'),
    '2044': ('Beast', 'A heavy beast with a curling tail and a mane stands on short legs, its mouth open.', 'as drawn'),
    '2045': ('Knife stand', 'A stand with a flared base crossed with bands holds a bunch of upright blades.', 'as drawn'),
    '2046': ('Stepped mound', 'A mound rises in steps on one side to a flat top and curves round at the other end.', 'as drawn'),
    '2047': ('Outer guardian', 'A guardian with a tail walks with a knife in each hand.', 'as drawn'),
    '2048': ('Inner guardian', "A guardian with a lion's head and long hair stands holding a knife.", 'as drawn'),
    '2049': ('Arch', 'A tall arched shape is crossed by two diagonal lines.', 'as drawn'),
    '2050': ('Guardian', 'A guardian in a banded kilt raises two knives above his head.', 'as drawn'),
    '2051': ('Winged figure', 'A thin figure stands with outspread wings, its head turned to one side.', 'as drawn'),
    '2052': ('Serpent', 'A long creature with a crested head and a body of fine feathers slopes down from its raised head to a pointed tail.', 'as drawn'),
    '2053': ('Guardian', 'A guardian with snakes rising from his head holds a knife in one hand.', 'as drawn'),
    '2054': ('Guardian', 'A guardian with snakes rising from his head and long hair down his back holds a knife.', 'as drawn'),
    '2055': ('Sign', 'A long loop is drawn round a row of short strokes like a feather.', 'as drawn'),
    '2056': ('Guardian', "A guardian with a bird's head holds a knife in one hand.", 'as drawn'),
    '2057': ('Lower sign', 'A long loop is drawn round a wavy snake.', 'as drawn'),
    '2058': ('Upper sign', 'A long loop is drawn round a row of short strokes like a feather.', 'as drawn'),
    '2059': ('Guardian', "A guardian with a bird's head and a tail holds a knife.", 'as drawn'),
    '2060': ('Lower sign', 'A long narrow loop encloses a thin, pointed shape.', 'as drawn'),
    '2061': ('Upper sign', 'A narrow band is folded back on itself into three bars.', 'as drawn'),
    '2062': ('God on a sphinx', 'A god in a banded kilt stands on a crouching sphinx, one hand held out.', 'as drawn'),
    '2063': ('Oval', 'An oval is crossed by two curved lines.', 'as drawn'),
    '2064': ('Eye', 'A small eye is drawn alone.', 'as drawn'),
    '2065': ('Three bearers', 'Three men stand in a row with their arms raised, together holding up a board over their heads.', 'as drawn'),
    '2066': ('Snake on a board', 'A long snake winds in loops along a straight board.', 'as drawn'),
    '2067': ('Pillar', 'A tall slender pillar stands upright.', 'as drawn'),
    '2068': ('Three-headed figure', 'A figure with three heads stands upright, his arms at his sides.', 'as drawn'),
    '2069': ('Guardian', 'A guardian with long hair and a banded kilt holds a knife.', 'as drawn'),
    '2070': ('Sign', 'A narrow loop is folded back on itself, with a round end.', 'as drawn'),
    '2071': ('Guardian', 'A guardian in a banded kilt and a long cloak holds a knife.', 'as drawn'),
    '2072': ('Basin', 'A wide basin curves like a shallow bowl.', 'as drawn'),
    '2073': ('Guardian', 'A guardian with a spray of spikes on his head holds a knife.', 'as drawn'),
    '2074': ('Sign', 'A square sign with a T-shaped stem is drawn on a base.', 'as drawn'),
}
HEART_FIGURES = {
    '1187': ('Pedestal', 'A low pedestal stands under the scarab.', 'as drawn'),
    '1189': ('Adorer', 'The deceased kneels before the scarab with both hands raised in adoration.', 'Davis 1894'),
    '1190': ('Scarab', 'A large scarab beetle with a sun disc over its head stands on a pedestal.', 'Davis 1894'),
    '1191': ('Pedestal', 'A low block carries the seated god.', 'as drawn'),
    '1193': ('Adorer', 'The deceased stands with both hands raised in adoration before the god.', 'Davis 1894'),
    '1194': ('Ankh', 'A tall ankh stands upright, a tied band hanging from its arms.', 'as drawn'),
    '1195': ('Seated god', 'A god in a long wig and a striped garment sits on a pedestal with his knees drawn up, a staff beside him.', 'as drawn'),
    '1197': ('Kneeling man', 'The deceased kneels with the sign of the heart held against his breast and one hand raised before the four gods.', 'Davis 1894'),
    '1198': ('Four gods', "Four gods sit in a row on a bench, each wrapped in bands and holding an ankh: the first has a bird's head, the second a jackal's, the third a beast's and the fourth a man's. Davis names them Amset, Hapi, Tiaoumautef and Kebhsennouf.", 'Davis 1894'),
    '1199': ('Bench', 'A long low bench carries the four gods.', 'as drawn'),
    '1200': ('Pedestal', 'A low pedestal carries the bird.', 'as drawn'),
    '1202': ('Kneeling man', 'The deceased kneels with the sign of the heart held against his breast and one hand raised before the bird.', 'Davis 1894'),
    '1203': ('Human-headed bird', "A bird with a man's head and a long wig stands on a pedestal, its tail trailing behind it: the emblem of the soul.", 'Davis 1894'),
    '1205': ('Man on the right', 'A man stands with one hand raised in front of him.', 'as drawn'),
    '1206': ('Man on the left', 'A man stands facing him, holding a small object in one hand.', 'as drawn'),
    '1208': ('Man gesturing', 'A man stands with one hand held out in front of him.', 'as drawn'),
    '1209': ('Man with a staff', 'A man in a long wig stands with a tall staff in one hand.', 'as drawn'),
    '1211': ('Man with a jar', 'A man holds a small round jar in one hand and raises the other.', 'as drawn'),
    '1212': ('Man with a staff', 'A man in a long wig stands with a tall staff in his hand.', 'as drawn'),
    '1214': ('Offering man', 'A man holds out a small object on one outstretched arm and a shallow bowl in the other hand. Davis has a priest presenting a vase and the ram-headed wand to two personages.', 'Davis 1894'),
    '1215': ('Standing man', 'A man stands with a long staff in one hand: the standing one of the two personages.', 'Davis 1894'),
    '1216': ('Seated man', 'A man sits on a chair with a latticed side, a staff in his hand: the seated one of the two personages.', 'Davis 1894'),
}
# Heart captions: layer ID -> (id, spell number(s) shown, Davis's title, reference). The pair in 21-22 is read
# right to left, as the scroll is.
HEART_CAPTIONS = {
    '1188': ('spell30_caption', 'Spell 30', 'A chapter about not letting the heart of the man act against him in the Netherworld.', 'Davis 1894'),
    '1192': ('spell28_caption', 'Spell 28', 'A chapter about not depriving the man of his heart in the Netherworld.', 'Davis 1894'),
    '1196': ('spell27_caption', 'Spell 27', 'A chapter about not letting the man be deprived of his heart in the Netherworld.', 'Davis 1894'),
    '1201': ('spell26_caption', 'Spell 26', 'A chapter about giving back to the man his heart in the Netherworld.', 'Davis 1894'),
    '1204': ('spell25_caption', 'Spell 25', 'A chapter about making the man remember in the Netherworld.', 'Davis 1894'),
    '1207': ('spell24_caption', 'Spell 24', 'A chapter about the bringing of the magic charms by the man, with himself, in the Netherworld.', 'Davis 1894'),
    '1210': ('spell23_caption', 'Spell 23', 'A chapter about opening the man\'s mouth in the Netherworld.', 'Davis 1894'),
    '1213': ('spell22_caption', 'Spell 22', 'Another chapter about giving back his mouth to the man in the Netherworld.', 'Davis 1894; which of the two texts is 22 is my reading'),
    '1217': ('spell21_caption', 'Spell 21', 'A chapter about giving back his mouth to the man in the Netherworld.', 'Davis 1894; which of the two texts is 21 is my reading'),
}

# The hall (spell 125). Davis 1894 describes the vignette, and invokes the forty-two assessors in two sections of
# twenty-one. The frieze is read right to left, as the text is, so the first invocation is spoken to assessor 42.
INVOCATIONS = [
    ('O the Stridor gone out of On!', 'I did not do evil.'),
    ('O the one who opens his mouth, gone out of Keraon!', 'I did not commit violence.'),
    ('O nostril gone out of Hermopolis!', 'I did not torment any heart.'),
    ('O eater of Spirits gone out of the windows of Heaven!', 'I did not steal.'),
    ('O . . . . gone out of Restau!', 'I did not get any man treacherously killed.'),
    ('O Double Lion gone out of Heaven!', 'I did not lessen the offerings.'),
    ('O the Eye of Flame gone out of Sechem!', 'I did not do any harm.'),
    ('O the Face of Flames appearing when going back and gone out of Heliopolis!', 'I did not carry off the sacred things.'),
    ('O the one who takes possession of the bones gone out of Heracleopolis!', 'I did not utter any lie.'),
    ('O Breath of Flame gone out of Memphis!', 'I did not carry off what belongs (to others).'),
    ('O Land of Bubastis gone out of the mysterious dwelling!', 'I did not make any one weep.'),
    ('O the one whose head is behind gone out of the passage!', 'I did not commit the act of self-pollution.'),
    ('O Kerti gone out of the Amenti!', 'I did not fornicate.'),
    ('O the Glowing Feet gone out of the night!', 'I did not get any suppressed wrath.'),
    ('O the White-Toothed One gone out of his borders!', 'I did not trespass.'),
    ('O Eater of Blood gone out of the place of execution!', 'I did not kill the sacred animals.'),
    ('O Eater of Bowels gone out of the dwelling of the thirty!', 'I did not commit any perfidy.'),
    ('O Master of Truth gone out of the Region of Truth!', 'I did not damage any cultivated piece of land.'),
    ('O the Turner Away gone out of Bubastis!', 'I was not an accuser.'),
    ('O Follower gone out of Heliopolis!', 'I did not make my mouth work.'),
    ('O the doubly-wicked, gone out of . . . .!', 'I was angry only when there was reason for.'),
    ('O Double Viper ouamem gone out of . . . .!', 'I had no intercourse with a married woman.'),
    ('O the One Contemplating what is brought in the dwelling of Khem!', 'I did not pollute myself.'),
    ('O Chiefs gone out of the trees nar, gone out of Tattu!', 'I did not cause any terror.'),
    ('O Lord of Sechem gone out of Kherouou!', 'I did not trespass.'),
    ('O Director of the Words gone out of the Great House!', 'I did not burn my mouth.'),
    ('O Child gone out of Hageh!', 'I did not turn a deaf ear to the words of Truth.'),
    ('O Ke ne menti, gone out of Nem!', 'I did not do any witchcraft.'),
    ('O Good-Bringer gone out of Saïs!', 'I was not a bully.'),
    ('O the One who Takes Possession of the Words gone out of Ouns!', 'I did not commit any act of rebellion.'),
    ('O Master of the Faces: gone out of Nedjat!', 'I did not make any rash judgment.'),
    ('O the God of the House of Execution, gone out of Outent!', 'I did not cut the skin of the sacred cattle.'),
    ('O Master of the Double Horn, gone out of Saïs!', 'I did not use too many words when speaking.'),
    ('O Nofre-Tmu, gone out of Memphis!', 'I did not wound! I did not do any harm to a sick one.'),
    ('O Tmu at his moment, gone out of Tattu!', 'I did not do any witchcraft against the King, I did not do any witchcraft against my father.'),
    ('O the One who acts according to his Heart gone out of Sahou!', 'I did not soil the water.'),
    ('O the Priest gone out of the Heavenly Abyss!', 'I did not commit any exaggeration of words.'),
    ('O the One who makes the Intelligent Ones thrive, gone out of Saïs!', 'I did not blaspheme a god.'),
    ('O the One who Associates the Splendors, gone out of Heliopolis!', 'I did not lessen the bread consecrated to the gods. I did not make the slave be misused by his master.'),
    ('O the One who Associates the Offerings, gone out of his retreat!', 'I did not act only according to my schemes and preferences; I was not imperious.'),
    ('O the One who Disposes his Head, gone out of his temple!', 'I did not impose my schemes. I did not strip the mummies of their stuffs.'),
    ('O the One who Brings in his Arm, gone out of Auker!', 'I did not despise God in my heart.'),
]
DAVIS = ('Davis, C. H. S. The Egyptian Book of the Dead: The Most Ancient and the Most Important of the Extant Religious Texts of '
         'Ancient Egypt. New York and London: G. P. Putnam\'s Sons, 1894. (English version of Pierret\'s French translation of '
         'P. Turin 1791.) https://sites.dlib.nyu.edu/viewer/books/ifa_egypt000060')
D94 = 'Davis 1894'
HALL_FIGURES.update({
    '66': ('Ma\'at', 'A tall goddess with a feather on her head stands holding an ankh and a long staff. Davis has the deceased introduced into the hall by Truth.', D94),
    '68': ('Small attendant', 'A small figure in a long kilt stands with one arm raised toward the pan beside him and the other held out.', 'as drawn'),
    '71': ('Balance post', 'A tall post carries the balance, with a plumb line hanging beside it.', 'as drawn'),
    '231': ('Plumb line', 'A plumb line hangs from the beam of the balance, a small weight at its end.', 'as drawn'),
    '72': ('Balance beam', 'The long beam of the balance, a hook at each end.', 'as drawn'),
    '73': ('Right pan', 'A pan hangs from the beam on cords. The heart lies in it.', 'as drawn'),
    '74': ('Left pan', 'A pan hangs from the beam on cords. The image of Truth sits in it.', D94),
    '76': ('Heart', 'The heart is drawn as a jar with two handles, and lies in the right pan. Davis has it weighed against the image of Truth.', D94),
    '77': ('Image of Truth', 'A small seated figure with a feather on her head sits in the left pan: the image of Truth that the heart must weigh the same as.', D94),
    '79': ('Baboon', 'A baboon sits on a flat perch at the top of the balance post.', 'as drawn'),
    '81': ('Falcon-headed attendant', 'A figure with a falcon\'s head and a long wig stands by the post of the balance with one arm raised toward it, an ankh in the other hand. Davis has Horus and Anubis weigh the heart.', D94),
    '82': ('Anubis', 'A god with a jackal\'s head stands at the left pan, one arm stretched toward it and an ankh in the other hand. Davis has him announce that the heart weighs the same as Truth.', D94),
    '85': ('Thoth', 'A god with an ibis\'s head holds a pen to a palette. Davis has Thoth, lord of the divine words, register the sentence.', D94),
    '87': ('Figure on a crook', 'A tiny figure squats on top of a shepherd\'s crook.', 'as drawn'),
    '90': ('Beast of the Amenti', 'A fantastic beast with gaping jaws sits on a pedestal in the shape of a pylon, its top ribbed, watching the balance. Davis calls her the one who destroys the foes by devouring them.', D94),
    '93': ('Genii of destiny', 'Two figures in long wigs and banded garments sit side by side with their knees drawn up. Davis has two genii of destiny, Shai and Ranen, sit above the beast.', D94),
    '230': ('Lion sign', 'A lion\'s head is drawn on a long low base, a hieroglyph beside the two seated figures.', 'as drawn'),
    '96': ('Altar of offerings', 'An altar loaded with offerings is topped with a bundle of lotus, and stands on a tall slender stem; a tall lotus bud rises on either side of its foot. Davis has the four funerary genii above it.', D94),
    '100': ('Four funerary genii', 'Four mummiform figures stand in a row above the altar, with the head of a man, of an ape, of a jackal and of a falcon. Davis has the four funerary genii here.', D94),
    '106': ('Dais', 'A long dais under the throne, its side decorated with a row of ankh signs above a low flight of steps.', 'as drawn'),
    '109': ('Draped standard', 'A tall pole rises from a base, a long spotted cloth hanging from it.', 'as drawn'),
    '229': ('Osiris', 'Osiris sits enthroned in the atef crown, the crook and flail held across his breast. The scene is his.', D94),
    '222': ('Shrine', 'The tall frame of Osiris\'s shrine stands on a low base, a ribbed cornice over its top.', 'as drawn'),
    '223': ('Judges\' platform', 'A long low ledge runs along the foot of the row of judges.', 'as drawn'),
    '114': ('Kneeling deity', 'A figure in a long wig kneels with both arms raised before an offering stand.', 'as drawn'),
    '116': ('Offering standard', 'A slender stand with a flared foot carries a round object under a cone-shaped cap.', 'as drawn'),
    '225': ('Cornice line', 'A long ledge runs under the row of cobras and signs along the top of the hall.', 'as drawn'),
    '205': ('Eastern baboon', 'A baboon in a long wig kneels at the right-hand end of the cornice and poises a pair of scales. Davis has one at each end of the row.', D94),
    '208': ('Tmu and the two eyes', 'A god kneels with his arms stretched out above two eyes, each in an oval. Davis has Tmu here between the sixth and seventh groups of signs.', D94),
    '210': ('Western baboon', 'A baboon in a long wig kneels at the left-hand end of the cornice and poises a pair of scales. Davis has one at each end of the row.', D94),
})
for n in range(1, 43):
    invocation, denial = INVOCATIONS[42 - n]
    HALL_FIGURES[str((119, 135, 151)[(42 - n) // 14] + (42 - n) % 14)] = (f'Assessor {n}',
        f'A judge sits wrapped in bands, the feather of truth on his head. The deceased says to him: "{invocation} {denial}"',
        f'{D94}; which judge hears which invocation is my reading')
HALL_FIGURES['186'] = ('Cornice signs', 'Twelve groups of three signs ornament the cornice: a rearing cobra, an arch with a tie round its stem, '
                       'and a tall striped shape curled at the top. The groups on the left and on the right mirror each other. '
                       'Davis describes them as groups formed with the hieroglyphs of truth and of fire and an uraeus.', D94)

# The hall's hieroglyphic legends, cut by hand into the MDP's `captions` folder (hidden there, so the figures' own
# drawing stays clean; the export reads that folder anyway). Layer ID -> (ID, name, description, reference). Davis
# translates the spell but not these legends, so they are described as drawn.
HALL_TEXTS = {
    '211': ('spell125_text_damaged_column', 'Damaged column of text', 'A column of hieroglyphs runs down the page between the deceased and Ma\'at, its outline broken where the drawing is damaged.', 'as drawn'),
    '213': ('spell125_text_arrival', 'Text over Ma\'at and the deceased', 'A row of short columns of hieroglyphs hangs from the rule above Ma\'at, and a long column runs down beside the deceased.', 'as drawn'),
    '214': ('spell125_text_osiris', 'Text before Osiris', 'Three columns of hieroglyphs stand before the face of Osiris, inside his shrine.', 'as drawn'),
    '215': ('spell125_text_altar', 'Text by the altar', 'Two columns of hieroglyphs stand beside the altar of offerings.', 'as drawn'),
    '216': ('spell125_text_genii', 'Text by the genii', 'Two short columns of hieroglyphs stand above the two seated figures.', 'as drawn'),
    '217': ('spell125_text_thoth', 'Text over Thoth', 'Three columns of hieroglyphs stand above Thoth\'s head and his writing.', 'as drawn'),
    '218': ('spell125_text_balance', 'Text over the balance', 'Three columns of hieroglyphs stand above the beam of the balance, to one side of the baboon.', 'as drawn'),
    '226': ('spell125_text_attendant', 'Sign by the attendant', 'A bird sign and a tall stroke stand beside the raised hand of the falcon-headed attendant.', 'as drawn'),
    '227': ('spell125_text_deities', 'Signs under the seated figures', 'A short group of hieroglyphs, ending in a round sign over a bar, is drawn under the two seated figures.', 'as drawn'),
}

# Layers whose names say nothing (or the wrong thing) get a stable ID from here: layer ID -> ID without the prefix.
HALL_SLUGS = {'81': 'scale_attendant', '100': 'funerary_genii', '222': 'osiris_shrine', '223': 'judges_platform',
              '225': 'cornice_line', '230': 'lion_sign', '229': 'osiris'}

# Thoth opening the doors of the sky (spell 161, pl. LXXVI): two registers, each with two Thoths facing the doors
# between them (the inner vertical rules), a legend above each Thoth and a column of text beside each door. Numbered
# in reading order, right to left and top to bottom. ID -> (group, (x0, y0, x1, y1) in canvas pixels).
DOORS_PIECES = {
    'spell161_thoth_1': ('Upper', (895, 535, 1170, 975)),
    'spell161_thoth_1_caption': ('Upper', (930, 95, 1130, 365)),
    'spell161_door_1_caption': ('Upper', (820, 90, 909, 968)),
    'spell161_door_2_caption': ('Upper', (474, 90, 570, 935)),
    'spell161_thoth_2_caption': ('Upper', (255, 90, 440, 300)),
    'spell161_thoth_2': ('Upper', (215, 490, 472, 975)),
    'spell161_thoth_3': ('Lower', (895, 1390, 1160, 1868)),
    'spell161_thoth_3_caption': ('Lower', (925, 1080, 1090, 1375)),
    'spell161_door_3_caption': ('Lower', (800, 1080, 909, 1840)),
    'spell161_door_4_caption': ('Lower', (470, 1080, 565, 1866)),
    'spell161_thoth_4_caption': ('Lower', (255, 1080, 425, 1305)),
    'spell161_thoth_4': ('Lower', (210, 1390, 472, 1868)),
}
DOORS_FIGURES = {
    'spell161_thoth_1': ('Thoth', 'Thoth, with the head of an ibis, faces left with both arms stretched out to the door before him.', 'as drawn'),
    'spell161_thoth_2': ('Thoth', 'Thoth, with the head of an ibis, faces right with both arms stretched out to the door before him.', 'as drawn'),
    'spell161_thoth_3': ('Thoth', 'Thoth, with the head of an ibis, faces left with both arms stretched out to the door before him.', 'as drawn'),
    'spell161_thoth_4': ('Thoth', 'Thoth, with the head of an ibis, faces right with both arms stretched out to the door before him.', 'as drawn'),
}
DOORS_CAPTIONS = {
    'spell161_thoth_1_caption': ('spell161_thoth_1_caption', 'Text above Thoth', 'Short columns of hieroglyphs stand above the head of Thoth.', 'as drawn'),
    'spell161_thoth_2_caption': ('spell161_thoth_2_caption', 'Text above Thoth', 'Short columns of hieroglyphs stand above the head of Thoth.', 'as drawn'),
    'spell161_thoth_3_caption': ('spell161_thoth_3_caption', 'Text above Thoth', 'Short columns of hieroglyphs stand above the head of Thoth.', 'as drawn'),
    'spell161_thoth_4_caption': ('spell161_thoth_4_caption', 'Text above Thoth', 'Short columns of hieroglyphs stand above the head of Thoth.', 'as drawn'),
    'spell161_door_1_caption': ('spell161_door_1_caption', 'Text by the door', 'A long column of hieroglyphs runs down beside the door.', 'as drawn'),
    'spell161_door_2_caption': ('spell161_door_2_caption', 'Text by the door', 'A long column of hieroglyphs runs down beside the door.', 'as drawn'),
    'spell161_door_3_caption': ('spell161_door_3_caption', 'Text by the door', 'A long column of hieroglyphs runs down beside the door.', 'as drawn'),
    'spell161_door_4_caption': ('spell161_door_4_caption', 'Text by the door', 'A long column of hieroglyphs runs down beside the door.', 'as drawn'),
}


LEVELS = {
    'mounds': dict(
        source='art/mounds149.mdp', root='Mounds', title='The Fourteen Mounds',
        intro_title='Spell 149: The Fourteen Mounds',
        intro_body='Explore the mounds as they are drawn: fourteen in a row, each with its guardians.\n\n'
                   'Walk [b]right to left[/b] with [←] [→] or click the papyrus. Click a figure to walk up '
                   'to it and read its description. Open the Journal with [j].',
        folder=re.compile(r'mound (\d+)'),
        group=lambda m: (['Spell149', f'Mound{m[1]}'], f'spell149_mound{m[1]}_'),
        figures=MOUND_FIGURES, captions={}, avatar='2029', avatar_facing=1,
        references={}),
    'mouth': dict(
        source='art/heart21-30.mdp', root='Mouth', title='Mouth and Heart',
        intro_title='Spells 21–30: Mouth and Heart',
        intro_body='Explore the spells for the mouth and the heart as they are drawn.\n\n'
                   'Walk [b]right to left[/b] with [←] [→] or click the papyrus. Click a figure or caption '
                   'to walk up to it and read about it. Open the Journal with [j].',
        folder=re.compile(r'(\d+)(?:-(\d+))?$'),
        group=lambda m: ([f'Spell{m[1]}' + (f'And{m[2]}' if m[2] else '')], f'spell{m[1]}' + (f'_{m[2]}' if m[2] else '') + '_'),
        figures=HEART_FIGURES, captions=HEART_CAPTIONS, avatar='1209', avatar_facing=-1,
        references={'Davis 1894': DAVIS}),
    'hall': dict(
        source='art/judgement125.mdp', root='Hall', title='The Weighing of the Heart',
        intro_title='Spell 125: The Hall of the Two Truths',
        intro_body='Explore the hall as it is drawn: Ma\u2019at, the balance, the forty-two judges and Osiris in his shrine.\n\n'
                   'Walk [b]right to left[/b] with [\u2190] [\u2192] or click the papyrus. Click a figure to walk up '
                   'to it and read its description. Open the Journal with [j].',
        roots=('captions', 'arrival', 'Weighing of the heart', 'Offerings before Osiris', 'Osiris shrine', 'judges', 'Roof frieze'),
        spell='Spell125', prefix='spell125_', slugs=HALL_SLUGS, behind={222, 223, 225}, show_hidden=('captions',), front=('Captions',),
        figures=HALL_FIGURES, captions=HALL_TEXTS,
        avatar='64', avatar_only=True, avatar_facing=-1, scale=5.9, ground=2797, view_top=40, view_height=2850,
        quiet={'RoofFrieze'},
        references={'Davis 1894': DAVIS}),
    'doors': dict(
        source='art/thoth161.mdp', root='Doors', title='Thoth Opens the Sky',
        intro_title='Spell 161: Thoth Opens the Doors of the Sky',
        intro_body='Explore the doors as they are drawn: four Thoths, in two rows, each at a door of the sky.\n\n'
                   'Walk [b]right to left[/b] with [\u2190] [\u2192] or click the papyrus. Click a figure or its text '
                   'to walk up to it and read about it. Open the Journal with [j].',
        cut='edited', pieces=DOORS_PIECES, spell='Spell161', guides=('horizont', 'vertical'), skip=('Layer1',),
        figures=DOORS_FIGURES, captions=DOORS_CAPTIONS, avatar=None, avatar_facing=-1,
        avatar_texture='res://assets/hall/figures/spell125_adoring_deceased.png', avatar_height=1160, avatar_scale=0.4,
        scale=3.8, ground=1868, view_top=20, view_height=1897,
        card=((30, 990), (30, 1299)),
        references={}),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snake(name):
    return re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')


def visible(layer, by_id):
    while True:
        if layer['visible'] == 'false':
            return False
        if layer['parentId'] == '-1':
            return True
        layer = by_id[layer['parentId']]


def top_folder(layer, by_id):
    while layer['parentId'] != '-1':
        layer = by_id[layer['parentId']]
    return layer['name']


def rules_in(canvas, y0, y1):
    """The x ranges (x0, x1 exclusive) of the vertical rules: runs of columns inked over almost all rows y0..y1."""
    full = (canvas[y0:y1] > 0).sum(0) >= 0.9 * (y1 - y0)
    runs, start = [], None
    for x, on in enumerate(np.append(full, False)):
        if on and start is None:
            start = x
        elif not on and start is not None:
            runs.append((start, x))
            start = None
    return runs


def find_columns(text, vertical, ground, top):
    """Inscription columns that stand in the walking row: ink of `text` between `top` and the ground line, grouped
    where it lies within 40 px, and widened to the outer edge of the rules on either side."""
    band = (text[top:ground - 10] > 0).sum(0) >= 5
    runs, start, last = [], None, None
    for x, on in enumerate(band):
        if on:
            if start is None:
                start = x
            last = x
        elif start is not None and x - last > 40:
            runs.append((start, last + 1))
            start = None
    if start is not None:
        runs.append((start, last + 1))
    rules = rules_in(vertical, top, ground - 10)
    columns = []
    for x0, x1 in runs:
        left = max((r[0] for r in rules if r[1] <= x0 + 8), default=x0)
        right = min((r[1] for r in rules if r[0] >= x1 - 8), default=x1)
        y0 = int(np.nonzero((text[top:, x0:x1] > 0).any(1))[0].min()) + top
        columns.append((left, y0 - 2, right, text.shape[0]))
    return columns


def cut_pieces(canvas, pieces):
    """[(id, groups, ink)] for each rectangle of `pieces`, and the ink no rectangle holds. A patch of ink (joined
    across gaps of 2 px) goes whole to the rectangle that holds the middle of its bounds."""
    from scipy import ndimage
    labels, _ = ndimage.label(ndimage.binary_dilation(canvas > 0, iterations=2), np.ones((3, 3)))
    labels[canvas == 0] = 0
    out = {fid: np.zeros_like(canvas) for fid in pieces}
    rest = np.zeros_like(canvas)
    for n, box in enumerate(ndimage.find_objects(labels), 1):
        if box is None:
            continue
        cy, cx = (box[0].start + box[0].stop) / 2, (box[1].start + box[1].stop) / 2
        owner = next((fid for fid, (_, (x0, y0, x1, y1)) in pieces.items() if x0 <= cx < x1 and y0 <= cy < y1), None)
        mask = labels[box] == n
        (out[owner] if owner else rest)[box][mask] = canvas[box][mask]
    return [(fid, out[fid]) for fid in pieces], rest


def pascal(name):
    return ''.join(word[:1].upper() + word[1:] for word in re.split(r'[^A-Za-z0-9]+', name))


def figure_group(cfg, layer, by_id):
    """(groups, prefix) when `layer` is a figure of the level, else None (it belongs to the strip)."""
    chain, parent = [], layer
    while parent['parentId'] != '-1':
        parent = by_id[parent['parentId']]
        chain.append(parent['name'])
    chain.reverse()
    if cfg.get('roots'):
        return ([cfg['spell'], pascal(chain[0])], cfg['prefix']) if chain and chain[0] in cfg['roots'] else None
    m = cfg['folder'].fullmatch(chain[-1] if chain else '')
    return cfg['group'](m) if m else None


def export(key, base):
    cfg = LEVELS[key]
    source = ROOT / cfg['source']
    out = base / 'godot/assets' / key
    digest = sha(source)
    w, h, layers, chunks, _ = read_mdp(source)
    by_id = {l['id']: l for l in layers}
    strip = np.zeros((h, w), np.uint8)
    text = np.zeros((h, w), np.uint8)       # the lower inscriptions alone: where columns are found
    vertical = np.zeros((h, w), np.uint8)
    figures, entries, order = {}, {}, []

    def add_figure(fid, canvas, groups, layer, key=None):
        assert fid not in figures, f'duplicate figure ID {fid}'
        ys, xs = np.nonzero(canvas)
        x, y, right, bottom = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
        save_ink(canvas[y:bottom, x:right], out, fid)
        figures[fid] = dict(x=x, y=y, w=right - x, h=bottom - y, group='/'.join(groups),
                            source_layer=int(layer['id']), source_name=layer['name'])
        order.append((fid, key or layer['id']))

    def shown(layer):
        return visible(layer, by_id) or top_folder(layer, by_id) in cfg.get('show_hidden', ())

    for layer in layers:
        if layer['type'] != '32bpp' or layer['name'] in ('bg', *cfg.get('skip', ())) or not shown(layer):
            continue
        if cfg.get('pieces'):
            canvas = canvas_of(layer, w, h, chunks, layer['name'] in cfg['guides'])
            if layer['name'] == cfg['cut']:
                cut, canvas = cut_pieces(canvas, cfg['pieces'])
                for fid, ink in cut:
                    assert ink.any(), f'no ink in the rectangle of {fid}'
                    add_figure(fid, ink, [cfg['spell'], cfg['pieces'][fid][0]], layer, fid)
            strip = np.maximum(strip, canvas)
            if layer['name'] == 'vertical':
                vertical = canvas
            continue
        parent = by_id[layer['parentId']]['name'] if layer['parentId'] != '-1' else ''
        canvas = canvas_of(layer, w, h, chunks, parent == 'guidelines')
        found = figure_group(cfg, layer, by_id)
        if not found:
            strip = np.maximum(strip, canvas)
            if parent == 'bottomtext':
                text = np.maximum(text, canvas)
            if layer['name'] == 'vertical':
                vertical = canvas
            continue
        groups, prefix = found
        if layer['id'] in cfg['captions']:
            fid = cfg['captions'][layer['id']][0]
        elif layer['name'].startswith('toptext'):
            raise SystemExit(f"caption layer {layer['id']} '{layer['name']}' in '{parent}' is not in CAPTIONS")
        else:
            fid = prefix + snake(cfg.get('slugs', {}).get(layer['id'], layer['name']))
        add_figure(fid, canvas, groups, layer)
        if layer['id'] == cfg['avatar'] and cfg.get('avatar_only'):
            figures[fid]['avatar_only'] = True     # the player: no entry, no hitbox, only the avatar's picture
    if cfg.get('behind') or cfg.get('front'):
        # frames and ledges go first in their group, drawn and picked under what stands in them; the `front` groups
        # (the hall's legends) go last, so the thin text is picked over the frames and figures it lies among
        groups = list(dict.fromkeys(f['group'] for f in figures.values()))
        rank = {fid: (groups.index(f['group']) + (len(groups) if f['group'].split('/')[-1] in cfg.get('front', ()) else 0),
                      f['source_layer'] not in cfg.get('behind', ())) for fid, f in figures.items()}
        figures = {fid: figures[fid] for fid in sorted(figures, key=lambda fid: rank[fid])}
        order = sorted(order, key=lambda item: rank[item[0]])
    listed = {**cfg['figures'], **cfg['captions']}
    missing = [f for f, lid in order if lid not in listed and not figures[f].get('avatar_only')]
    if missing:
        print('no description yet (layer ids):', ', '.join(lid for f, lid in order if f in missing))
    for fid, lid in order:
        if lid in cfg['figures']:
            name, description, reference = cfg['figures'][lid]
            entries[fid] = dict(name=name, descriptions={'default': description},
                                journal=figures[fid]['group'].split('/')[-1] not in cfg.get('quiet', ()), reference=reference)
        elif lid in cfg['captions']:
            _, name, description, reference = cfg['captions'][lid]
            entries[fid] = dict(name=name, descriptions={'default': description}, journal=False, reference=reference)
    save_ink(strip, out, 'strip')

    ground, scale = cfg.get('ground', 526), cfg.get('scale', SCALE)
    columns = {}
    rects = cfg['columns'] if cfg.get('columns') else (find_columns(text, vertical, ground, 170) if text[:ground].any() else [])
    for n, (x0, y0, x1, y1) in enumerate(rects, 1):
        save_ink(strip[y0:y1, x0:x1], out, f'column_{n}')
        columns[f'column_{n}'] = dict(x=x0, y=y0, w=x1 - x0, h=y1 - y0)

    avatar = next((f for f, lid in order if lid == cfg['avatar']), None)
    start = dict(x=figures[avatar]['x'] + figures[avatar]['w'] // 2 if cfg.get('avatar_only') else w - round(60 * scale), y=ground)
    level = dict(source=cfg['source'], sha256=digest, width=w, height=h, ground=ground, view_top=cfg.get('view_top', VIEW_TOP),
                 view_height=cfg.get('view_height', ground + BELOW_GROUND), scale=scale, start=start,
                 avatar=avatar or cfg['avatar_texture'],
                 figures=figures, columns=columns)
    (out / 'level.json').write_text(json.dumps(level, indent=1, ensure_ascii=False) + '\n')
    registry = out / 'registry.json'
    if registry.exists():
        print(f'assets/{key}/registry.json exists and is kept; delete it to write it afresh.')
    else:
        registry.write_text(json.dumps(dict(references=cfg['references'], entries=entries), indent=1, ensure_ascii=False) + '\n')
    write_scene(base, key, cfg, figures, avatar, start, columns)
    if cfg.get('card'):
        (rows, (x0, x1)), pad = cfg['card'], 400
        width = round((rows[1] - rows[0]) * 440 / 280)    # the card's proportions; papyrus fills the sides
        ink = np.pad(strip, ((0, 0), (pad, pad)))
        for fid, item in figures.items():
            region = ink[item['y']:item['y'] + item['h'], pad + item['x']:pad + item['x'] + item['w']]
            np.maximum(region, np.asarray(Image.open(out / 'figures' / f'{fid}.png'))[..., 3], out=region)
        left = pad + (x0 + x1) // 2 - width // 2
        (base / 'godot/assets/menu').mkdir(parents=True, exist_ok=True)
        save_menu_picture(key, ink, rows, (left, left + width), base / 'godot/assets/menu')
    assert sha(source) == digest
    print(f'{cfg["root"]}: {len(figures)} sprites, {len(columns)} columns; MDP unchanged.')


def write_scene(base, key, cfg, figures, avatar, start, columns):
    scene = base / f'godot/scenes/{key}.tscn'
    if scene.exists():
        print(f'scenes/{key}.tscn exists and is kept; delete it to write it afresh.')
        return
    resources = ['[gd_scene format=3]\n',
                 '[ext_resource type="Script" path="res://scripts/walk/walk.gd" id="level"]',
                 '[ext_resource type="Script" path="res://scripts/avatar.gd" id="avatar"]',
                 '[ext_resource type="Script" path="res://scripts/hud.gd" id="hud"]',
                 '[ext_resource type="Shader" path="res://scripts/papyrus.gdshader" id="papyrus"]',
                 f'[ext_resource type="Texture2D" path="res://assets/{key}/figures/strip.png" id="strip"]']
    resources += [f'[ext_resource type="Texture2D" path="res://assets/{key}/figures/{f}.png" id="{f}"]' for f in figures]
    resources += [f'[ext_resource type="Texture2D" path="res://assets/{key}/figures/{c}.png" id="{c}"]' for c in columns]
    if not avatar:
        avatar = 'avatar_picture'
        resources.append(f'[ext_resource type="Texture2D" path="{cfg["avatar_texture"]}" id="{avatar}"]')
    resources.append('\n[sub_resource type="ShaderMaterial" id="paper"]\nshader = ExtResource("papyrus")')
    size = json.loads((base / f'godot/assets/{key}/level.json').read_text())
    width = size['width']
    side = max(1000, 2 * size['height'])     # a plate narrower than the view (the doors) still has papyrus at both sides
    body = cfg['intro_body'].replace('\n', '\\n')
    text = [f'''[node name="{cfg['root']}" type="Node2D"]
script = ExtResource("level")
level_key = "{key}"
title = "{cfg['title']}"
intro_title = "{cfg['intro_title']}"
intro_body = "{body}"

[node name="Papyrus" type="ColorRect" parent="."]
material = SubResource("paper")
offset_left = -{side}.0
offset_top = -1000.0
offset_right = {width + side}.0
offset_bottom = {size['height'] + 1000}.0
mouse_filter = 2
metadata/_edit_lock_ = true

[node name="Strip" type="Sprite2D" parent="."]
texture = ExtResource("strip")
centered = false
metadata/_edit_lock_ = true

[node name="Figures" type="Node2D" parent="."]''']
    made = set()
    for fid, item in figures.items():
        if item.get('avatar_only'):
            continue
        path = ''
        for part in item['group'].split('/'):
            parent = path or '.'
            path = f'{path}/{part}' if path else part
            if path not in made:
                made.add(path)
                text.append(f'[node name="{part}" type="Node2D" parent="Figures{"/" + parent if parent != "." else ""}"]')
        text.append(f'[node name="{fid}" type="Sprite2D" parent="Figures/{item["group"]}"]\n'
                    f'position = Vector2({item["x"]}, {item["y"]})\ntexture = ExtResource("{fid}")\ncentered = false\n'
                    f'metadata/registry_id = "{fid}"\nmetadata/source_layer_id = {item["source_layer"]}')
    shrink = cfg.get('avatar_scale', 1)
    text.append(f'[node name="Avatar" type="Node2D" parent="."]\nposition = Vector2({start["x"]}, {start["y"]})\n'
                + (f'scale = Vector2({shrink:g}, {shrink:g})\n' if shrink != 1 else '') +
                f'script = ExtResource("avatar")\ndrawn_facing = {cfg["avatar_facing"]}\n\n'
                f'[node name="Sprite" type="Sprite2D" parent="Avatar"]\ntexture = ExtResource("{avatar}")\n'
                f'offset = Vector2(0, {-(figures[avatar]["h"] if avatar in figures else cfg["avatar_height"]) / 2:g})')
    if columns:
        text.append('[node name="Foreground" type="Node2D" parent="."]\nz_index = 6')
        for n, (name, box) in enumerate(columns.items(), 1):
            node = f'Column{n}'
            text.append(f'[node name="{node}" type="Node2D" parent="Foreground"]\nposition = Vector2({box["x"]}, {box["y"]})')
            text.append(f'[node name="Papyrus" type="ColorRect" parent="Foreground/{node}"]\nmaterial = SubResource("paper")\n'
                        f'offset_right = {box["w"]}.0\noffset_bottom = {box["h"]}.0\nmouse_filter = 2')
            text.append(f'[node name="Ink" type="Sprite2D" parent="Foreground/{node}"]\n'
                        f'texture = ExtResource("{name}")\ncentered = false')
    text.append(f'[node name="Camera" type="Camera2D" parent="."]\nposition = Vector2({start["x"]}, {start["y"] - 108})\n\n'
                '[node name="HUD" type="CanvasLayer" parent="."]\nscript = ExtResource("hud")')
    scene.parent.mkdir(parents=True, exist_ok=True)
    scene.write_text('\n'.join(resources) + '\n\n' + '\n\n'.join(text) + '\n')


if __name__ == '__main__':
    args = sys.argv[1:]
    if not args or args[0] not in LEVELS:
        sys.exit(__doc__)
    base = ROOT
    if args[1:2] == ['--into']:
        base = Path(args[2]).resolve()
        assert ROOT not in base.parents and base != ROOT, '--into must be outside the repository'
    elif args[1:]:
        sys.exit(__doc__)
    export(args[0], base)
