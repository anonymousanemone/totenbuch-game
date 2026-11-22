"""Write godot/scenes/scroll.tscn: the map as one register of the scroll (mockups/menus.html, option A).

    python .claude/skills/build-levels/build_scroll_map.py

Acts sit side by side between double rules, reading right to left, each captioned above its cards;
the chosen scene's name is the tag on the strip's band, with its description and Play / View below.
Uses the scenes and acts of godot/scripts/scroll.gd and their menu pictures. Overwrites the scene: preserve editor changes first.
"""
import os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
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


def header(scenes):
    pictures = '\n'.join(
        f'[ext_resource type="Texture2D" path="res://assets/menu/{scene["key"]}.png" id="picture_{scene["key"]}"]'
        for scene in scenes
    )
    return f'''[gd_scene format=3]

[ext_resource type="Script" uid="uid://cemx7nosbyg3v" path="res://scripts/menu/scroll_screen.gd" id="scroll_logic"]
[ext_resource type="FontFile" uid="uid://c8aqm1xotc72w" path="res://assets/fonts/OldFax.ttf" id="1_apkfn"]
[ext_resource type="Texture2D" uid="uid://c23x0nxvc3s3o" path="res://assets/ui/icon_back.png" id="2_ai4fp"]
[ext_resource type="Texture2D" uid="uid://3lxhm2tba5km" path="res://assets/ui/band_top.png" id="3_0daod"]
[ext_resource type="Texture2D" uid="uid://0pvydmjatq8v" path="res://assets/ui/icon_ankh.png" id="5_4wg3f"]
[ext_resource type="Texture2D" path="res://assets/ui/icon_settings.png" id="icon_settings"]
{pictures}

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_pbf8f"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_uu2ls"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.9372549, 0.8784314, 0.73333335, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_iuf6s"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.8862745, 0.8156863, 0.6509804, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_8b48n"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.79607844, 0.6901961, 0.4862745, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_1r33x"]
content_margin_left = 8.0
content_margin_top = 4.0
content_margin_right = 8.0
content_margin_bottom = 4.0
bg_color = Color(0.8862745, 0.8156863, 0.6509804, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="Theme" id="Theme_irvca"]
default_font = ExtResource("1_apkfn")
default_font_size = 16
Button/colors/font_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
Button/colors/font_focus_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
Button/colors/font_hover_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
Button/colors/font_pressed_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
Button/styles/focus = SubResource("StyleBoxEmpty_pbf8f")
Button/styles/hover = SubResource("StyleBoxFlat_uu2ls")
Button/styles/normal = SubResource("StyleBoxFlat_iuf6s")
Button/styles/pressed = SubResource("StyleBoxFlat_8b48n")
Label/colors/font_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
Label/constants/line_spacing = 6
RichTextLabel/colors/default_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
RichTextLabel/constants/line_separation = 6
RichTextLabel/constants/paragraph_separation = 10
TooltipLabel/colors/font_color = Color(0.18039216, 0.11372549, 0.0627451, 1)
TooltipPanel/styles/panel = SubResource("StyleBoxFlat_1r33x")

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_0emas"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.79607844, 0.6901961, 0.4862745, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_34pe2"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.8862745, 0.8156863, 0.6509804, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_ejt37"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.8862745, 0.8156863, 0.6509804, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_drs81"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.79607844, 0.6901961, 0.4862745, 0.5)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.56078434, 0.44313726, 0.25882354, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_ptxi0"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.5882353, 0.24313726, 0.15686275, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="tag_box"]
content_margin_left = 12.0
content_margin_right = 12.0
bg_color = Color(0.5882353, 0.24313726, 0.15686275, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="here_box"]
content_margin_left = 10.0
content_margin_right = 10.0
bg_color = Color(0.5882353, 0.24313726, 0.15686275, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.18039216, 0.11372549, 0.0627451, 1)

[sub_resource type="StyleBoxFlat" id="frame_box"]
content_margin_left = 4.0
content_margin_top = 4.0
content_margin_right = 4.0
content_margin_bottom = 4.0
bg_color = Color(0.8862745, 0.8156863, 0.6509804, 1)
border_width_left = 4
border_width_top = 4
border_width_right = 4
border_width_bottom = 4
border_color = Color(0.8862745, 0.8156863, 0.6509804, 1)

'''


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
                   layout_mode=2, mouse_filter=2, texture=f'ExtResource("picture_{sc["key"]}")', expand_mode=1, stretch_mode=6)
            s.node('Restored', 'TextureRect', f'{c}/Frame/Picture', visible='false', layout_mode=1, anchor_left='1.0',
                   anchor_top='1.0', anchor_right='1.0', anchor_bottom='1.0', offset_left='-34.0', offset_top='-38.0',
                   offset_right='-6.0', offset_bottom='-6.0', mouse_filter=2, texture='ExtResource("5_4wg3f")')
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
           anchor_bottom='1.0', offset_bottom=f'{BAND}.0', mouse_filter=2, texture='ExtResource("3_0daod")', stretch_mode=1)
    s.node('Row', 'HBoxContainer', 'Header', layout_mode=1, anchor_right='1.0', anchor_bottom='1.0', offset_left='16.0',
           offset_right='-16.0', theme_override_constants__separation=22)
    s.label('Heading', 'Header/Row', 'The Scroll', 32, INK, size_flags_horizontal=3, size_flags_vertical=4)
    for name, tex, tip in [('Settings', 'icon_settings', 'Settings'), ('Back', '2_ai4fp', 'Back')]:
        s.node(name, 'TextureButton', 'Header/Row', texture_filter=1, layout_mode=2, size_flags_vertical=4,
               tooltip_text=f'"{tip}"', mouse_default_cursor_shape=2, texture_normal=f'ExtResource("{tex}")')

    # the strip: its band, the chosen scene's name as the tag across it, what it is, Play and View
    s.node('Footer', 'ColorRect', '.', layout_mode=1, anchor_top='1.0', anchor_right='1.0', anchor_bottom='1.0',
           offset_top=f'{-STRIP}.0', mouse_filter=2, color=DEEP, metadata___edit_lock_='true')
    s.node('Band', 'TextureRect', 'Footer', texture_filter=1, layout_mode=1, anchor_right='1.0', offset_bottom=f'{BAND}.0',
           mouse_filter=2, texture='ExtResource("3_0daod")', stretch_mode=1)
    s.node('Selection', 'HBoxContainer', 'Footer', layout_mode=1, anchor_right='1.0', anchor_bottom='1.0',
           offset_left='28.0', offset_top='24.0', offset_right='-24.0', theme_override_constants__separation=24)
    s.label('About', 'Footer/Selection', scenes[0]['title'], 32, INK, size_flags_horizontal=3, size_flags_vertical=4,
            autowrap_mode=3, theme_override_constants__line_spacing=0)
    styles = {
        'normal': 'StyleBoxFlat_0emas',
        'pressed': 'StyleBoxFlat_34pe2',
        'hover': 'StyleBoxFlat_ejt37',
        'disabled': 'StyleBoxFlat_drs81',
        'focus': 'StyleBoxFlat_ptxi0',
    }
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

    open(OUT, 'w').write(header(scenes) + '\n'.join(s.out))
    print('wrote', OUT, len(scenes), 'cards in', len(order), 'acts,', length, 'px long')


if __name__ == '__main__':
    main()
