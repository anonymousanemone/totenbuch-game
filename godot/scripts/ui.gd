## The look shared by the HUD and the menus: the palette, the pixel font, square panels, the
## scroll's frame band, and bare pixel icons that act as buttons. Old Fax is a pixel font: 16 px
## is one font pixel to a screen pixel, 32 px two.
class_name UI
extends RefCounted

const FONT := preload("res://assets/fonts/OldFax.ttf")
const BIG := 32
const SMALL := 16
const BAND := 16.0            ## the frame band's thickness

const PAPYRUS := Color("e2d0a6")     ## the scene's papyrus: pages
const DEEP := Color("cbb07c")        ## deep papyrus: bars, strips, buttons
const INK := Color("2e1d10")
const RULE := Color("8f7142")
const OCHRE := Color("6e3e10")
const TAG := Color("963e28")         ## speakers' tags, headings, the main button
const CREAM := Color("f1e7cd")

const IMAGES := "res://assets/ui/%s.png"


## A tiled run of the frame band (`image` in assets/ui), laid along one side of `parent`.
static func band(parent: Control, image: String, preset: int, offsets: Rect2) -> void:
	var t := TextureRect.new()
	t.texture = load(IMAGES % image)
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_preset(preset)
	t.offset_left = offsets.position.x
	t.offset_top = offsets.position.y
	t.offset_right = offsets.size.x
	t.offset_bottom = offsets.size.y
	parent.add_child(t)


## A bare pixel icon (assets/ui/icon_<icon>.png) that acts as a button.
static func icon_button(icon: String, tip: String, on_press: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(IMAGES % ("icon_" + icon))
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE     # keep the arrow keys for walking
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(on_press)
	b.mouse_entered.connect(func(): b.modulate.a = 0.6)
	b.mouse_exited.connect(func(): b.modulate.a = 1.0)
	return b


## A square-cornered panel: fill, border, and padding.
static func box(bg: Color, border: Color, border_w: int, pad_x := 8, pad_y := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	return s


static func theme() -> Theme:
	var th := Theme.new()
	th.default_font = FONT
	th.default_font_size = SMALL
	th.set_color("font_color", "Label", INK)
	th.set_color("default_color", "RichTextLabel", INK)
	th.set_color("font_color", "Button", INK)
	th.set_color("font_hover_color", "Button", INK)
	th.set_color("font_pressed_color", "Button", INK)
	th.set_stylebox("normal", "Button", box(PAPYRUS, INK, 4, 16, 2))
	th.set_stylebox("hover", "Button", box(Color("efe0bb"), INK, 4, 16, 2))
	th.set_stylebox("pressed", "Button", box(DEEP, INK, 4, 16, 2))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_stylebox("panel", "TooltipPanel", box(PAPYRUS, INK, 2, 8, 4))
	th.set_color("font_color", "TooltipLabel", INK)
	return th
