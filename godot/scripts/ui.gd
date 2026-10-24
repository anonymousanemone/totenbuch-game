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
const TAG_MINIGAME := Color("456137") ## minigame instructions, clues and feedback
const TAG_HINT := Color("d2ad46")     ## Hint-button messages
const CREAM := Color("f1e7cd")

# Display colors and ink multipliers are deliberately separate.
const DANGER := Color("b55b3c")
const SUCCESS := Color(1.8, 1.4, 0.6)
const PREVIEW := Color(1.9, 1.0, 0.6, 0.2)
## Matches the level selector in glow.gdshader; all hover glow colors live there.
enum Glow { DEFAULT, PROCESSION, DANGER, SUCCESS }
const SUCCESS_GLOW := Color(156.0 / 255.0, 184.0 / 255.0, 79.0 / 255.0, 0.4)  ## UI band light green #9cb84f
const SUCCESS_IN := 0.8       ## s for a success glow to come up ...
const SUCCESS_OUT := 3.2      ## ... and to fade
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


static func glow_material(texture: Texture2D, level: Glow = Glow.DEFAULT) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GLOW_SHADER
	mat.set_shader_parameter("level", level)
	mat.set_shader_parameter("success", SUCCESS_GLOW)
	if level == Glow.SUCCESS:
		mat.set_shader_parameter("pad", 20.0)
	mat.set_shader_parameter("strength", 0.0)
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		var whole: Vector2 = atlas.atlas.get_size()
		var rect: Rect2 = atlas.region
		mat.set_shader_parameter("region", Vector4(rect.position.x / whole.x, rect.position.y / whole.y, rect.size.x / whole.x, rect.size.y / whole.y))
	return mat


## A glow behind part of a sprite's drawing: `region` in the sprite's px (in the frame it shows,
## if it is a sheet; the sprite not centred). Part for whole: a figure in the strip, or one figure
## of a sprite that holds several. Added under `sprite`, so it moves with it; its strength starts at 0.
static func part_glow(sprite: Sprite2D, region: Rect2, level: Glow = Glow.DEFAULT) -> Sprite2D:
	var cell := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
	var tex := AtlasTexture.new()
	tex.atlas = sprite.texture
	tex.region = Rect2(region.position + Vector2(sprite.frame_coords) * cell, region.size)
	var g := Sprite2D.new()
	g.texture = tex
	g.centered = false
	g.position = region.position
	g.show_behind_parent = true
	g.material = glow_material(tex, level)
	sprite.add_child(g)
	return g


## A glow behind a sprite's whole drawing (the frame it shows, if it is a sheet, following it as
## the frame changes). Added under `sprite`; its strength starts at 0.
static func sprite_glow(sprite: Sprite2D, level: Glow = Glow.DEFAULT) -> Sprite2D:
	var g := Sprite2D.new()
	g.material = glow_material(sprite.texture, level)
	g.show_behind_parent = true
	g.texture = sprite.texture
	g.centered = sprite.centered
	g.offset = sprite.offset
	g.flip_h = sprite.flip_h
	g.hframes = sprite.hframes
	g.vframes = sprite.vframes
	sprite.add_child(g)
	if sprite.hframes * sprite.vframes == 1:
		return g
	var follow := func() -> void:
		g.frame = sprite.frame
		var n := Vector2(sprite.hframes, sprite.vframes)
		(g.material as ShaderMaterial).set_shader_parameter("region", Vector4(sprite.frame_coords.x / n.x, sprite.frame_coords.y / n.y, 1.0 / n.x, 1.0 / n.y))
	follow.call()
	sprite.frame_changed.connect(follow)
	g.tree_exiting.connect(func() -> void: sprite.frame_changed.disconnect(follow))
	return g


## A task done: the drawings it set right glow pale green for a moment (`success` in glow.gdshader).
static func success_flash(sprite: Sprite2D) -> void:
	flash_glow(sprite_glow(sprite, Glow.SUCCESS))


## Bring a glow (made at strength 0) up and fade it out again, then free it.
static func flash_glow(g: Sprite2D) -> void:
	var mat := g.material as ShaderMaterial
	var set_strength := func(v: float) -> void: mat.set_shader_parameter("strength", v)
	var t := g.create_tween()
	t.tween_method(set_strength, 0.0, 1.0, SUCCESS_IN).set_trans(Tween.TRANS_SINE)
	t.tween_method(set_strength, 1.0, 0.0, SUCCESS_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_callback(g.queue_free)


static func flash(node: CanvasItem) -> void:
	success_flash(node as Sprite2D)


static func plain(text: String) -> String:
	return text.replace("[b]", "").replace("[/b]", "").replace("[i]", "").replace("[/i]", "")
