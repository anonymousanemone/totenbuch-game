## The menus: the title page, the map of the scroll, and the settings (with the controls).
## Built in code, in the look of ui.gd; scenes, progress and settings come from the Scroll autoload.
## `-- --level=procession` (any scene's key) skips straight to that scene; `-- --screen=map` (or
## settings, controls) opens that page and `-- --screenshot=path.png` saves a frame and quits.
extends Control

const CARD := Vector2(220, 140)
const DIM := Color(0.12, 0.08, 0.04, 0.5)

var _title: Control
var _map: Control
var _settings: Control
var _controls: Control
var _cards: VBoxContainer         ## the map's acts and their cards
var _count: Label
var _chosen := ""                 ## the scene chosen on the map
var _chosen_name: Label
var _chosen_about: Label
var _chosen_go: Button
var _sound_pips: Array[ColorRect] = []
var _fullscreen_value: Label


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--level="):
			Scroll.open.call_deferred(a.trim_prefix("--level="))
			return
	theme = UI.theme()
	_title = _build_title()
	_map = _build_map()
	_settings = _build_settings()
	_controls = _build_controls()
	_show(_title)
	for a in args:
		if a.begins_with("--screen="):
			match a.trim_prefix("--screen="):
				"map": _show(_map)
				"settings": _show(_settings)
				"controls": _show(_controls)
		elif a.begins_with("--screenshot="):
			await get_tree().create_timer(0.5).timeout
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


## Esc steps back: from the controls to the settings, from anything else to the title page.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show(_settings if _controls.visible else _title)


## The title page, or the map; settings and controls open over the title page.
func _show(page: Control) -> void:
	_title.visible = page in [_title, _settings, _controls]
	_map.visible = page == _map
	_settings.visible = page == _settings
	_controls.visible = page == _controls
	if page == _map:
		_refresh_map()


# ---------------------------------------------------------------- the title page

func _build_title() -> Control:
	var page := _fill(UI.DEEP)
	var frame := _fill(UI.PAPYRUS, page)
	frame.offset_left = 24
	frame.offset_top = 24
	frame.offset_right = -24
	frame.offset_bottom = -24
	UI.band(frame, "band_top", Control.PRESET_TOP_WIDE, Rect2(0, 0, 0, UI.BAND))
	UI.band(frame, "band_top", Control.PRESET_BOTTOM_WIDE, Rect2(0, -UI.BAND, 0, 0))
	UI.band(frame, "band_vertical", Control.PRESET_LEFT_WIDE, Rect2(0, 0, UI.BAND, 0))
	UI.band(frame, "band_vertical", Control.PRESET_RIGHT_WIDE, Rect2(-UI.BAND, 0, 0, 0))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	center.add_child(v)
	var pic := PanelContainer.new()
	pic.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 4, 4, 4))
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.add_child(_picture(load("res://assets/menu/frontispiece.png"), Vector2(360, 210)))
	v.add_child(pic)
	var title := _label("TOTENBUCH", 64, UI.TAG)
	var spaced := FontVariation.new()
	spaced.base_font = UI.FONT
	spaced.spacing_glyph = 8
	title.add_theme_font_override("font", spaced)
	for l in [title, _label("The Book of the Dead of Iufankh", UI.BIG, UI.INK),
			_label("after Lepsius, Das Todtenbuch der Ägypter, 1842", UI.SMALL, UI.OCHRE)]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size.y = 14
	v.add_child(gap)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_child(_button("Continue", func(): Scroll.open(Scroll.current()), true))
	grid.add_child(_button("The scroll", func(): _show(_map)))
	grid.add_child(_button("Settings", func(): _show(_settings)))
	grid.add_child(_button("Quit", func(): get_tree().quit()))
	v.add_child(grid)
	return page


# ---------------------------------------------------------------- the map

## Every scene, act by act under a length of the band, each row reading right to left as the
## scroll does. The chosen scene opens in the strip along the bottom.
func _build_map() -> Control:
	var page := _fill(UI.PAPYRUS)
	var head := HBoxContainer.new()
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_left = 40
	head.offset_right = -40
	head.offset_top = 16
	head.add_theme_constant_override("separation", 22)
	page.add_child(head)
	head.add_child(_label("The Scroll", UI.BIG, UI.TAG))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	_count = _label("", UI.SMALL, UI.OCHRE)
	head.add_child(_count)
	head.add_child(UI.icon_button("back", "Back", func(): _show(_title)))

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40
	scroll.offset_right = -40
	scroll.offset_top = 70
	scroll.offset_bottom = -100
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # the wheel scrolls it
	page.add_child(scroll)
	_cards = VBoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 10)
	scroll.add_child(_cards)

	var strip := _fill(UI.DEEP, page)
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -96
	var rule := _fill(UI.INK, strip)
	rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rule.offset_bottom = 4
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 40
	row.offset_right = -40
	row.offset_top = 4
	row.add_theme_constant_override("separation", 24)
	strip.add_child(row)
	_chosen_name = _label("", UI.BIG, UI.TAG)
	_chosen_about = _label("", UI.SMALL, UI.INK)
	_chosen_about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chosen_about.autowrap_mode = TextServer.AUTOWRAP_WORD
	_chosen_go = _button("", func(): Scroll.open(_chosen))
	for c in [_chosen_name, _chosen_about, _chosen_go]:
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	return page


func _refresh_map() -> void:
	for c in _cards.get_children():
		c.queue_free()
	_count.text = "%d of %d restored — right to left" % [Scroll.restored.size(), Scroll.SCENES.size()]
	if _chosen == "":
		_chosen = Scroll.current()
	for act in Scroll.ACTS:
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 14)
		head.add_child(_label(Scroll.ACTS[act], UI.SMALL, UI.TAG))
		var band := Control.new()
		band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		band.custom_minimum_size.y = UI.BAND
		band.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UI.band(band, "band_top", Control.PRESET_FULL_RECT, Rect2())
		head.add_child(band)
		_cards.add_child(head)
		var flow := HFlowContainer.new()
		flow.layout_direction = Control.LAYOUT_DIRECTION_RTL     # the scroll reads right to left
		flow.add_theme_constant_override("h_separation", 14)
		flow.add_theme_constant_override("v_separation", 18)
		for s in Scroll.SCENES.filter(func(s): return s.act == act):
			flow.add_child(_card(s))
		_cards.add_child(flow)
	_choose(_chosen)


## A scene's card: its picture (faint until reached), name and spells.
func _card(s: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.layout_direction = Control.LAYOUT_DIRECTION_LTR
	card.add_theme_constant_override("separation", 2)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_choose(s.key))
	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := _picture(load("res://assets/menu/%s.png" % s.key), CARD)
	var restored: bool = s.key in Scroll.restored
	if not restored and s.key != Scroll.current():
		pic.modulate.a = 0.22
	frame.add_child(pic)
	card.add_child(frame)
	if restored:   # marks sit on the picture, which doesn't lay out its children
		var ankh := TextureRect.new()
		ankh.texture = load(UI.IMAGES % "icon_ankh")
		ankh.position = Vector2(CARD.x - 36, 6)
		pic.add_child(ankh)
	if s.key == Scroll.current():
		var here := PanelContainer.new()
		here.add_theme_stylebox_override("panel", UI.box(UI.TAG, UI.INK, 4, 8, 0))
		here.add_child(_label("You are here", UI.SMALL, UI.CREAM))
		here.position = Vector2(10, -16)
		pic.add_child(here)
	var faint := UI.RULE if pic.modulate.a < 1.0 else UI.INK
	card.add_child(_label(s.title, UI.SMALL, faint))
	card.add_child(_label("Spells %s — pl. %s" % [s.spells, s.plates], UI.SMALL, UI.OCHRE))
	card.set_meta("key", s.key)
	return card


func _choose(key: String) -> void:
	_chosen = key
	for flow in _cards.get_children():
		for card in flow.get_children():
			if card.has_meta("key"):
				var frame: PanelContainer = card.get_node("Frame")
				frame.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.TAG if card.get_meta("key") == key else UI.INK, 4, 4, 4))
	var s := Scroll.scene(key)
	_chosen_name.text = s.title
	_chosen_about.text = s.about
	_chosen_go.disabled = not Scroll.is_built(key)
	if not Scroll.is_built(key):
		_chosen_go.text = "Not yet made"
	elif key in Scroll.restored:
		_chosen_go.text = "Play again"
	else:
		_chosen_go.text = "Continue" if key == Scroll.current() else "Play"


# ---------------------------------------------------------------- settings and controls

func _build_settings() -> Control:
	var sheet := _sheet("Settings")
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	for i in 10:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(12, 24)
		pips.add_child(p)
		_sound_pips.append(p)
	sheet.add_child(_setting("Sound", pips, func(d): Scroll.set_sound(Scroll.sound + d)))
	_fullscreen_value = _label("", UI.BIG, UI.OCHRE)
	sheet.add_child(_setting("Fullscreen", _fullscreen_value, func(_d): Scroll.set_fullscreen(not Scroll.fullscreen)))
	sheet.add_child(_row("Controls  →", UI.INK, func(): _show(_controls)))
	sheet.add_child(_row("Begin the scroll again", UI.TAG, func():
		Scroll.begin_again()
		_chosen = ""))
	sheet.add_child(_row("← Back", UI.INK, func(): _show(_title)))
	_refresh_settings()
	return sheet.get_meta("page")


func _refresh_settings() -> void:
	for i in _sound_pips.size():
		_sound_pips[i].color = UI.OCHRE if i < Scroll.sound else Color(UI.RULE, 0.35)
	_fullscreen_value.text = "On" if Scroll.fullscreen else "Off"


func _build_controls() -> Control:
	var sheet := _sheet("Controls")
	for k in [["Walk", "[←] [→] or click"], ["Look, take", "click"], ["Put back", "[esc]"], ["Journal", "[j]"],
			["Thrust", "[space]"], ["Heka", "hold [shift]"], ["Move (fights)", "[↑] [↓]"]]:
		var row := HBoxContainer.new()
		var name := _label(k[0], UI.BIG, UI.INK)
		name.custom_minimum_size.x = 280
		row.add_child(name)
		row.add_child(_label(k[1], UI.BIG, UI.OCHRE))
		sheet.add_child(row)
	sheet.add_child(_row("← Back", UI.INK, func(): _show(_settings)))
	return sheet.get_meta("page")


## A sheet over the dimmed title page, with its heading and a double rule; rows go in the returned box.
func _sheet(heading: String) -> VBoxContainer:
	var page := _fill(DIM)
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 4, 30, 18))
	panel.custom_minimum_size.x = 660
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	v.add_child(_label(heading, UI.BIG, UI.TAG))
	for i in 2:   # the double rule
		var r := ColorRect.new()
		r.color = UI.INK
		r.custom_minimum_size.y = 4
		v.add_child(r)
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	v.add_child(gap)
	v.set_meta("page", page)
	return v


## A setting: its name, and its value between ← and →, which step it.
func _setting(label: String, value: Control, step: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var name := _label(label, UI.BIG, UI.INK)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var holder := CenterContainer.new()
	holder.custom_minimum_size.x = 220
	holder.add_child(value)
	for d in [-1, 1]:
		var arrow := _flat("←" if d < 0 else "→", UI.INK, func():
			step.call(d)
			_refresh_settings())
		row.add_child(arrow)
		if d < 0:
			row.add_child(holder)
	return row


## A row that is itself a button.
func _row(text: String, color: Color, on_press: Callable) -> Button:
	var b := _flat(text, color, on_press)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b


# ---------------------------------------------------------------- small pieces

func _fill(color: Color, parent: Control = self) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _picture(tex: Texture2D, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## A title-page button: deep papyrus, or red for the main one; it lights up under the pointer.
func _button(text: String, on_press: Callable, main := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 52)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UI.BIG)
	var fill := UI.TAG if main else UI.DEEP
	var lit := UI.INK if main else UI.PAPYRUS
	b.add_theme_stylebox_override("normal", UI.box(fill, UI.INK, 4, 16, 0))
	b.add_theme_stylebox_override("hover", UI.box(lit, UI.INK, 4, 16, 0))
	b.add_theme_stylebox_override("pressed", UI.box(lit, UI.INK, 4, 16, 0))
	b.add_theme_stylebox_override("disabled", UI.box(Color(UI.DEEP, 0.5), UI.RULE, 4, 16, 0))
	b.add_theme_color_override("font_color", UI.CREAM if main else UI.INK)
	b.add_theme_color_override("font_hover_color", UI.CREAM if main else UI.TAG)
	b.add_theme_color_override("font_disabled_color", UI.RULE)
	b.pressed.connect(on_press)
	return b


## Text that acts as a button: no box, red under the pointer.
func _flat(text: String, color: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", UI.BIG)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", UI.TAG)
	b.add_theme_color_override("font_pressed_color", UI.TAG)
	b.pressed.connect(on_press)
	return b
