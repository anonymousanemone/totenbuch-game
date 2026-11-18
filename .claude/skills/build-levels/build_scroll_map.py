"""Write godot/scenes/scroll.tscn: the map as one register of the scroll (mockups/menus.html, option A).

    python .claude/skills/build-levels/build_scroll_map.py

Acts sit side by side between double rules, reading right to left, each captioned above its cards;
the chosen scene's name is the tag on the strip's band, with its description and Play / View below.
Reuses the theme and button styles of the archived map (archive/godot/scenes/scroll.tscn) and the
scenes and acts of godot/scripts/scroll.gd. Overwrites the scene: preserve editor changes first.
"""
import os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OLD = f'{ROOT}/archive/godot/scenes/scroll.tscn'
OUT = f'{ROOT}/godot/scenes/scroll.tscn'
GD = f'{ROOT}/godot/scripts/scroll.gd'

INK = 'Color(0.18039216, 0.11372549, 0.0627451, 1)'
TAG = 'Color(0.5882353, 0.24313726, 0.15686275, 1)'
OCHRE = 'Color(0.38431373, 0.21960784, 0.05490196, 1)'
CREAM = 'Color(0.94509804, 0.90588236, 0.8039216, 1)'
DEEP = 'Color(0.79607844, 0.6901961, 0.4862745, 1)'
PAPYRUS = 'Color(0.8862745, 0.8156863, 0.6509804, 1)'

BAR, BAND, STRIP = 46, 16, 120          # the title bar, the frame band, the strip (band included)
ABOVE, BELOW = 34, 54                   # papyrus between the bands and the register's double rules
CARD_W, PIC_W, PIC_H = 380, 350, 216    # a card, and its picture with its 4px frame
LINE, DOUBLE = 4, 12                    # a rule, and a double rule (line, gap, line)


def scenes_and_acts():
    src = open(GD).read()
    acts = dict(re.findall(r'"(\w+)": "((?:Prologue|Act)[^"]*)"', src.split('const SCENES')[0]))
    scenes = []
    for m in re.finditer(r'\{"key": "(\w+)", "act": "(\w+)", "title": "([^"]*)", "spells": "([^"]*)", "plates": "([^"]*)"', src):
        scenes.append(dict(zip(['key', 'act', 'title', 'spells', 'plates'], m.groups())))
    return scenes, acts


def header():
    """The archived map's resources: font, icons, pictures, theme and button styles."""
    old = open(OLD).read()
    head = old[:old.index('[node ')]
    head = re.sub(r'\[gd_scene[^\]]*\]', '[gd_scene format=3]', head, count=1)
    pics = {}
    for m in re.finditer(r'\[node name="Picture"[^\]]*parent="Levels/Acts/\w+/(\w+)/Frame"[^\]]*\]\n(?:[^\[]*?)texture = ExtResource\("([^"]+)"\)', old):
        pics[m.group(1)] = m.group(2)
    styles = {}
    play = old[old.index('[node name="Play"'):]
    for state in ['normal', 'pressed', 'hover', 'disabled', 'focus']:
        styles[state] = re.search(rf'theme_override_styles/{state} = SubResource\("([^"]+)"\)', play).group(1)
    current = re.search(r'\[node name="Current"[^\]]*\]\n(?:[^\[]*?)theme_override_styles/panel = SubResource\("([^"]+)"\)', old).group(1)
    ankh = re.search(r'path="res://assets/ui/icon_ankh.png" id="([^"]+)"', old).group(1)
    back = re.search(r'path="res://assets/ui/icon_back.png" id="([^"]+)"', old).group(1)
    band = re.search(r'path="res://assets/ui/band_top.png" id="([^"]+)"', old).group(1)
    head = head.replace('[sub_resource', '[ext_resource type="Texture2D" path="res://assets/ui/icon_settings.png" id="icon_settings"]\n\n[sub_resource', 1)
    # the strip's tag and the chosen picture's frame
    head += f'''[sub_resource type="StyleBoxFlat" id="tag_box"]
content_margin_left = 12.0
content_margin_right = 12.0
bg_color = {TAG}
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = {INK}

[sub_resource type="StyleBoxFlat" id="here_box"]
content_margin_left = 10.0
content_margin_right = 10.0
bg_color = {TAG}
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = {INK}

[sub_resource type="StyleBoxFlat" id="frame_box"]
content_margin_left = 4.0
content_margin_top = 4.0
content_margin_right = 4.0
content_margin_bottom = 4.0
bg_color = {PAPYRUS}
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = {PAPYRUS}

'''
    return head, pics, styles, current, ankh, back, band


class Scene:
    def __init__(self):
        self.out = []

    def node(self, name, kind, parent, **props):
        p = '' if parent is None else f' parent="{parent}"'
        self.out.append(f'[node name="{name}" type="{kind}"{p}]')
        for k, v in props.items():
            self.out.append(f'{k.replace("__", "/")} = {v}')
        self.out.append('')

    def rect(self, name, parent, l, t, r, b, ol, ot, orr, ob, color=INK):
        """An ink line, anchored (l, t, r, b) and offset (ol, ot, orr, ob)."""
        self.node(name, 'ColorRect', parent, layout_mode=1, anchor_left=f'{l}.0', anchor_top=f'{t}.0',
                  anchor_right=f'{r}.0', anchor_bottom=f'{b}.0', offset_left=f'{ol}.0', offset_top=f'{ot}.0',
                  offset_right=f'{orr}.0', offset_bottom=f'{ob}.0', mouse_filter=2, color=color)

    def double_h(self, name, parent):
        """A double rule across: line, gap, line."""
        self.node(name, 'Control', parent, custom_minimum_size=f'Vector2(0, {DOUBLE})', layout_mode=2, mouse_filter=2)
        self.rect('Outer' if name == 'Top' else 'Inner', f'{parent}/{name}', 0, 0, 1, 0, 0, 0, 0, LINE)
        self.rect('Inner' if name == 'Top' else 'Outer', f'{parent}/{name}', 0, 1, 1, 1, 0, -LINE, 0, 0)

    def double_v(self, name, parent):
        """A double rule down: line, gap, line."""
        self.node(name, 'Control', parent, custom_minimum_size=f'Vector2({DOUBLE}, 0)', layout_mode=2, mouse_filter=2)
        self.rect('Left', f'{parent}/{name}', 0, 0, 0, 1, 0, 0, LINE, 0)
        self.rect('Right', f'{parent}/{name}', 1, 0, 1, 1, -LINE, 0, 0, 0)

    def cap(self, name, parent, side):
        """An end of the register: each line of its double rule turns into the same line of the top
        and bottom rules, so the gap between them runs round the corner."""
        p = f'{parent}/{name}'
        self.node(name, 'Control', parent, custom_minimum_size=f'Vector2({DOUBLE}, 0)', layout_mode=2, layout_direction=2,
                  mouse_filter=2)   # left to right, so its sides are not mirrored inside the right-to-left register
        self.rect('OuterTop', p, 0, 0, 1, 0, 0, 0, 0, LINE)
        self.rect('OuterBottom', p, 0, 1, 1, 1, 0, -LINE, 0, 0)
        if side == 'right':     # outer line on the outside (right), inner line on the left
            self.rect('OuterSide', p, 1, 0, 1, 1, -LINE, 0, 0, 0)
            self.rect('InnerTop', p, 0, 0, 0, 0, 0, 2 * LINE, LINE, 3 * LINE)
            self.rect('InnerBottom', p, 0, 1, 0, 1, 0, -3 * LINE, LINE, -2 * LINE)
            self.rect('InnerSide', p, 0, 0, 0, 1, 0, 2 * LINE, LINE, -2 * LINE)
        else:
            self.rect('OuterSide', p, 0, 0, 0, 1, 0, 0, LINE, 0)
            self.rect('InnerTop', p, 1, 0, 1, 0, -LINE, 2 * LINE, 0, 3 * LINE)
            self.rect('InnerBottom', p, 1, 1, 1, 1, -LINE, -3 * LINE, 0, -2 * LINE)
            self.rect('InnerSide', p, 1, 0, 1, 1, -LINE, 2 * LINE, 0, -2 * LINE)

    def label(self, name, parent, text, size, color, **props):
        props.setdefault('layout_mode', 2)
        self.node(name, 'Label', parent, **props, theme_override_colors__font_color=color,
                  theme_override_font_sizes__font_size=size, text=f'"{text}"', metadata__font_size=size)


def act_node(act):
    return 'Prologue' if act == 'Prologue' else 'Act' + act


def main():
    scenes, acts = scenes_and_acts()
    head, pics, styles, current, ankh, back, band = header()
    s = Scene()
    # saved as long as the whole register, so the editor shows every act; in play it fits the window (scroll_screen.gd)
    order = list(dict.fromkeys(sc['act'] for sc in scenes))
    length = 2 * 28 + 2 * DOUBLE + (len(order) - 1) * DOUBLE + len(scenes) * CARD_W + (len(scenes) - len(order)) * DOUBLE
    s.node('Scroll', 'ColorRect', None, script='ExtResource("scroll_logic")', offset_right=f'{length}.0',
           offset_bottom='720.0', mouse_filter=2, theme='SubResource("Theme_irvca")', color=PAPYRUS)

    # the register
    s.node('Levels', 'ScrollContainer', '.', layout_mode=1, anchor_right='1.0', anchor_bottom='1.0',
           offset_top=f'{BAR + BAND + ABOVE}.0', offset_bottom=f'{-(STRIP + BELOW)}.0', follow_focus='true',
           horizontal_scroll_mode=3, vertical_scroll_mode=0)
    s.node('Acts', 'HBoxContainer', 'Levels', layout_mode=2, size_flags_vertical=3, layout_direction=3,
           theme_override_constants__separation=0)
    reel = 'Levels/Acts'
    s.node('PadRight', 'Control', reel, custom_minimum_size='Vector2(28, 0)', layout_mode=2, mouse_filter=2)
    s.cap('CapRight', reel, 'right')
    for i, act in enumerate(order):
        if i:
            s.double_v(f'Gap{i}', reel)
        a = f'{reel}/{act_node(act)}'
        s.node(act_node(act), 'VBoxContainer', reel, layout_mode=2, layout_direction=2, theme_override_constants__separation=0)
        s.double_h('Top', a)
        s.node('Caption', 'MarginContainer', a, custom_minimum_size='Vector2(0, 68)', layout_mode=2,
               theme_override_constants__margin_left=20, theme_override_constants__margin_top=8,
               theme_override_constants__margin_right=20, theme_override_constants__margin_bottom=8)
        s.label('Title', f'{a}/Caption', acts[act], 24, TAG, size_flags_vertical=4, horizontal_alignment=1,
                autowrap_mode=3, theme_override_constants__line_spacing=2)
        s.node('Rule', 'ColorRect', a, custom_minimum_size=f'Vector2(0, {LINE})', layout_mode=2, mouse_filter=2, color=INK)
        s.node('Cards', 'HBoxContainer', a, layout_mode=2, size_flags_vertical=3, layout_direction=3,
               theme_override_constants__separation=0)
        first = True
        for sc in [x for x in scenes if x['act'] == act]:
            if not first:
                s.double_v(f'Divider{sc["key"].capitalize()}', f'{a}/Cards')
            first = False
            c = f'{a}/Cards/{sc["key"]}'
            s.node(sc['key'], 'VBoxContainer', f'{a}/Cards', custom_minimum_size=f'Vector2({CARD_W}, 0)', layout_mode=2,
                   layout_direction=2, focus_mode=2, mouse_filter=0, mouse_default_cursor_shape=2,
                   theme_override_constants__separation=0, metadata__key=f'"{sc["key"]}"')
            s.node('Space', 'Control', c, custom_minimum_size='Vector2(0, 36)', layout_mode=2, mouse_filter=2)
            s.node('Frame', 'PanelContainer', c, layout_mode=2, size_flags_horizontal=4, mouse_filter=2,
                   theme_override_styles__panel='SubResource("frame_box")')
            s.node('Picture', 'TextureRect', f'{c}/Frame', custom_minimum_size=f'Vector2({PIC_W - 8}, {PIC_H - 8})',
                   layout_mode=2, mouse_filter=2, texture=f'ExtResource("{pics[sc["key"]]}")', expand_mode=1, stretch_mode=6)
            s.node('Restored', 'TextureRect', f'{c}/Frame/Picture', visible='false', layout_mode=1, anchor_left='1.0',
                   anchor_top='1.0', anchor_right='1.0', anchor_bottom='1.0', offset_left='-34.0', offset_top='-38.0',
                   offset_right='-6.0', offset_bottom='-6.0', mouse_filter=2, texture=f'ExtResource("{ankh}")')
            s.node('Current', 'PanelContainer', f'{c}/Frame/Picture', visible='false', layout_mode=0, offset_left='-7.0',
                   offset_top='-54.0', offset_right='-7.0', offset_bottom='-54.0', mouse_filter=2,
                   theme_override_styles__panel='SubResource("here_box")')
            s.label('Label', f'{c}/Frame/Picture/Current', 'You are here', 16, CREAM, custom_minimum_size='Vector2(0, 20)',
                    vertical_alignment=1)
            s.node('Gap', 'Control', c, custom_minimum_size='Vector2(0, 10)', layout_mode=2, mouse_filter=2)
            s.label('Title', c, sc['title'], 24, INK, custom_minimum_size=f'Vector2({PIC_W}, 0)', size_flags_horizontal=4,
                    theme_override_constants__line_spacing=2)
            s.node('Gap2', 'Control', c, custom_minimum_size='Vector2(0, 6)', layout_mode=2, mouse_filter=2)
            s.label('Spells', c, f'Spells {sc["spells"]} — pl. {sc["plates"]}', 16, OCHRE,
                    custom_minimum_size=f'Vector2({PIC_W}, 0)', size_flags_horizontal=4)
        s.double_h('Bottom', a)
    s.cap('CapLeft', reel, 'left')
    s.node('PadLeft', 'Control', reel, custom_minimum_size='Vector2(28, 0)', layout_mode=2, mouse_filter=2)

    # how much is restored, under the register's far end
    s.label('Count', '.', f'0 of {len(scenes)} scenes restored', 16, OCHRE, layout_mode=1, anchor_left='1.0',
            anchor_top='1.0', anchor_right='1.0', anchor_bottom='1.0', offset_left='-628.0',
            offset_top=f'{-(STRIP + 18 + 18)}.0', offset_right='-28.0', offset_bottom=f'{-(STRIP + 18)}.0',
            grow_horizontal=0, grow_vertical=0, horizontal_alignment=2)

    # the title bar and its band
    s.node('Header', 'ColorRect', '.', layout_mode=1, anchor_right='1.0', offset_bottom=f'{BAR}.0', mouse_filter=2,
           color=DEEP, metadata___edit_lock_='true')
    s.node('Band', 'TextureRect', 'Header', texture_filter=1, layout_mode=1, anchor_top='1.0', anchor_right='1.0',
           anchor_bottom='1.0', offset_bottom=f'{BAND}.0', mouse_filter=2, texture=f'ExtResource("{band}")', stretch_mode=1)
    s.node('Row', 'HBoxContainer', 'Header', layout_mode=1, anchor_right='1.0', anchor_bottom='1.0', offset_left='16.0',
           offset_right='-16.0', theme_override_constants__separation=22)
    s.label('Heading', 'Header/Row', 'The Scroll', 32, INK, size_flags_horizontal=3, size_flags_vertical=4)
    for name, tex, tip in [('Settings', 'icon_settings', 'Settings'), ('Back', back, 'Back')]:
        s.node(name, 'TextureButton', 'Header/Row', texture_filter=1, layout_mode=2, size_flags_vertical=4,
               tooltip_text=f'"{tip}"', mouse_default_cursor_shape=2, texture_normal=f'ExtResource("{tex}")')

    # the strip: its band, the chosen scene's name as the tag across it, what it is, Play and View
    s.node('Footer', 'ColorRect', '.', layout_mode=1, anchor_top='1.0', anchor_right='1.0', anchor_bottom='1.0',
           offset_top=f'{-STRIP}.0', mouse_filter=2, color=DEEP, metadata___edit_lock_='true')
    s.node('Band', 'TextureRect', 'Footer', texture_filter=1, layout_mode=1, anchor_right='1.0', offset_bottom=f'{BAND}.0',
           mouse_filter=2, texture=f'ExtResource("{band}")', stretch_mode=1)
    s.node('Selection', 'HBoxContainer', 'Footer', layout_mode=1, anchor_right='1.0', anchor_bottom='1.0',
           offset_left='28.0', offset_top='24.0', offset_right='-24.0', theme_override_constants__separation=24)
    s.label('About', 'Footer/Selection', scenes[0]['title'], 32, INK, size_flags_horizontal=3, size_flags_vertical=4,
            autowrap_mode=3, theme_override_constants__line_spacing=0)
    for name in ['Play', 'View']:
        props = dict(custom_minimum_size='Vector2(240, 52)', layout_mode=2, size_flags_vertical=4,
                     theme_override_colors__font_color=INK, theme_override_colors__font_focus_color=CREAM,
                     theme_override_colors__font_hover_color=TAG,
                     theme_override_colors__font_disabled_color='Color(0.56078434, 0.44313726, 0.25882354, 1)',
                     theme_override_font_sizes__font_size=32)
        for state, sub in styles.items():
            props[f'theme_override_styles__{state}'] = f'SubResource("{sub}")'
        if name == 'View':
            props = {'visible': 'false', **props}
        s.node(name, 'Button', 'Footer/Selection', **props, text=f'"{name}"')
    s.node('Tag', 'PanelContainer', 'Footer', layout_mode=0, offset_left='24.0', offset_top='-10.0', offset_right='24.0',
           offset_bottom='26.0', mouse_filter=2, theme_override_styles__panel='SubResource("tag_box")')
    s.label('Name', 'Footer/Tag', scenes[0]['title'], 24, CREAM, size_flags_vertical=4)

    open(OUT, 'w').write(head + '\n'.join(s.out))
    print('wrote', OUT, len(scenes), 'cards in', len(order), 'acts,', length, 'px long')


if __name__ == '__main__':
    main()
