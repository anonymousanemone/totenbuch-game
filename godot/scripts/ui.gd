## The look shared by the HUD and the menus: the palette, the pixel font, square panels, the
## scroll's frame band, and bare pixel icons that act as buttons. Old Fax is a pixel font: 16 px
## is one font pixel to a screen pixel, 32 px two.
class_name UI
extends RefCounted

const FONT := preload("res://assets/fonts/OldFax.ttf")
const BIG := 32
const SMALL := 16
const DIALOGUE := 32
const BAND := 16.0            ## the frame band's thickness

const PAPYRUS := Color("e2d0a6")     ## the scene's papyrus: pages
const DEEP := Color("cbb07c")        ## deep papyrus: bars, strips, buttons
const INK := Color("2e1d10")
const RULE := Color("8f7142")
const OCHRE := Color("62380e")
const TAG := Color("963e28")         ## speakers' tags, headings, the main button
const CREAM := Color("f1e7cd")

# Display colors and ink multipliers are deliberately separate.
const DANGER := Color("b55b3c")
const SUCCESS := Color(1.8, 1.4, 0.6)
const PREVIEW := Color(1.9, 1.0, 0.6, 0.2)
const HOVER := Color(0.95, 0.62, 0.22, 0.6)
const DIM := Color(0.12, 0.08, 0.04, 0.5)
const INK_TINT := Color(DANGER.r / INK.r, DANGER.g / INK.g, DANGER.b / INK.b)
const GLOW_SHADER := preload("res://scripts/glow.gdshader")

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
static func icon_button(icon: String, tip: String, on_press: Callable, keyboard := false) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(IMAGES % ("icon_" + icon))
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_ALL if keyboard else Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(on_press)
	b.mouse_entered.connect(func(): b.modulate = SUCCESS)
	b.mouse_exited.connect(func(): b.modulate = Color.WHITE)
	b.focus_entered.connect(func(): b.modulate = SUCCESS)
	b.focus_exited.connect(func(): b.modulate = Color.WHITE)
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
	th.set_constant("line_spacing", "Label", 6)
	th.set_constant("line_separation", "RichTextLabel", 6)
	th.set_constant("paragraph_separation", "RichTextLabel", 10)
	th.set_color("font_color", "Label", INK)
	th.set_color("default_color", "RichTextLabel", INK)
	th.set_color("font_color", "Button", INK)
	th.set_color("font_hover_color", "Button", INK)
	th.set_color("font_pressed_color", "Button", INK)
	th.set_color("font_focus_color", "Button", INK)
	th.set_stylebox("normal", "Button", box(PAPYRUS, INK, 4, 16, 8))
	th.set_stylebox("hover", "Button", box(Color("efe0bb"), INK, 4, 16, 8))
	th.set_stylebox("pressed", "Button", box(DEEP, INK, 4, 16, 8))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())   # menu buttons turn red instead (menu.gd)
	th.set_stylebox("panel", "TooltipPanel", box(PAPYRUS, INK, 2, 8, 4))
	th.set_color("font_color", "TooltipLabel", INK)
	return th


static func glow_material(texture: Texture2D) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GLOW_SHADER
	mat.set_shader_parameter("glow", HOVER)
	mat.set_shader_parameter("strength", 0.0)
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		var whole: Vector2 = atlas.atlas.get_size()
		var rect: Rect2 = atlas.region
		mat.set_shader_parameter("region", Vector4(rect.position.x / whole.x, rect.position.y / whole.y, rect.size.x / whole.x, rect.size.y / whole.y))
	return mat


## A glow behind the strip's own drawing inside `rect` (a figure or a caption that is part of the
## picture, not a sprite), added under `strip`; its strength starts at 0.
static func strip_glow(strip: Sprite2D, rect: Rect2) -> Sprite2D:
	var tex := AtlasTexture.new()
	tex.atlas = strip.texture
	tex.region = rect
	var g := Sprite2D.new()
	g.texture = tex
	g.centered = false
	g.position = rect.position
	g.show_behind_parent = true
	g.material = glow_material(tex)
	strip.add_child(g)
	return g


static func flash(node: CanvasItem, duration := 0.8) -> void:
	var previous: Tween = node.get_meta("success_flash") if node.has_meta("success_flash") else null
	if previous and previous.is_valid():
		previous.kill()
	var keep: Color = node.get_meta("resting_color", node.modulate)
	node.set_meta("resting_color", keep)
	node.modulate = Color(SUCCESS, keep.a)
	var tween := node.create_tween()
	node.set_meta("success_flash", tween)
	tween.tween_property(node, "modulate", keep, duration)


static func plain(text: String) -> String:
	return text.replace("[b]", "").replace("[/b]", "").replace("[i]", "").replace("[/i]", "")
