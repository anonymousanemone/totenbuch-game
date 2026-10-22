## The menus: the title page, the map of the scroll, and the settings (with the controls).
## Title and map layouts are saved in menus.tscn and scroll.tscn; Scroll supplies game state.
## `-- --level=procession` (any scene's key) skips straight to that scene; `-- --screen=map` (or
## settings, controls) opens that page and `-- --screenshot=path.png` saves a frame and quits.
extends Control

const DIM := UI.DIM

var _frontispiece: TextureRect
var _sheets: Array[PanelContainer] = []
var _control_names: Array[Label] = []
var _title: Control
var _map: Control
var _settings: Control
var _controls: Control
var _cards: VBoxContainer         ## the map's acts and their cards
var _chosen: String:
	get:
		return _map.chosen
	set(value):
		_map.chosen = value
var _chosen_go: Button
var _sound_pips: Array[ColorRect] = []
var _fullscreen_value: Label


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--level="):
			Scroll.open.call_deferred(a.trim_prefix("--level="))
			return
	_title = $Title
	_map = $Scroll
	_frontispiece = $Title/Frame/Center/Content/ArtFrame/Frontispiece
	_cards = $Scroll/Levels/Acts
	_chosen_go = $Scroll/Footer/Selection/Play
	_map.back_requested.connect(func(): _show(_title))
	var buttons := $Title/Frame/Center/Content/Buttons
	buttons.get_node("Play").pressed.connect(func(): Scroll.open(_play_key()))
	buttons.get_node("TheScroll").pressed.connect(func(): _show(_map))
	buttons.get_node("Settings").pressed.connect(func(): _show(_settings))
	buttons.get_node("Quit").pressed.connect(func(): get_tree().quit())
	for name in ["TheScroll", "Settings", "Quit"]:
		var button: Button = buttons.get_node(name)
		button.focus_entered.connect(func(): button.add_theme_color_override("font_hover_color", UI.CREAM))
		button.focus_exited.connect(func(): button.add_theme_color_override("font_hover_color", UI.TAG))
	_settings = _build_settings()
	_controls = _build_controls()
	_show(_title)
	get_viewport().size_changed.connect(_resize_menu)
	_resize_menu()
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
	for button in _title.find_children("*", "BaseButton", true, false):
		button.focus_mode = Control.FOCUS_ALL if page == _title else Control.FOCUS_NONE
	if page == _map:
		_refresh_map()
	_resize_menu.call_deferred()
	_focus_page.call_deferred(page)


## A new game starts at Procession; otherwise resume the first unfinished playable chapter.
func _play_key() -> String:
	var current: String = Scroll.current()
	return current if current != "" else Scroll.SCENES[0].key


func _refresh_map() -> void:
	_map.refresh()


func _choose(key: String) -> void:
	_map.choose(key)


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
	for k in [["Walk", "[←] [→] or click"], ["Look / take", "click"], ["Leave / close", "[esc]"], ["Journal", "[j]"],
			["Begin / attack", "[space]"], ["Red crocodiles", "hold [shift]"], ["Aim / turn", "arrows (each fight explains)"]]:
		var row := HBoxContainer.new()
		var name := _label(k[0], UI.BIG, UI.INK)
		name.custom_minimum_size.x = 280
		_control_names.append(name)
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
	_sheets.append(panel)
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
	l.set_meta("font_size", size)
	return l


## Text that acts as a button: no box, red under the pointer.
func _flat(text: String, color: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", UI.BIG)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", UI.TAG)
	b.add_theme_color_override("font_pressed_color", UI.TAG)
	b.add_theme_color_override("font_focus_color", UI.TAG)
	b.pressed.connect(on_press)
	return b


func _focus_page(page: Control) -> void:
	for button in page.find_children("*", "BaseButton", true, false):
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return


func _resize_menu() -> void:
	var viewport := get_viewport_rect().size
	var compact := viewport.x < 1000.0 or viewport.y < 650.0
	var image_height := clampf(viewport.y - 380.0, 80.0, 210.0)
	_frontispiece.custom_minimum_size = Vector2(image_height * 360.0 / 210.0, image_height)
	for panel in _sheets:
		panel.custom_minimum_size.x = clampf(viewport.x - 80.0, 320.0, 660.0)
	for label in _control_names:
		label.custom_minimum_size.x = 140.0 if compact else 280.0
	for label in find_children("*", "Label", true, false):
		if _map.is_ancestor_of(label):
			continue
		if label.has_meta("font_size"):
			var original: int = label.get_meta("font_size")
			label.add_theme_font_size_override("font_size", maxi(UI.SMALL, original / 2) if compact else original)
	for button in find_children("*", "Button", true, false):
		if _map.is_ancestor_of(button):
			continue
		button.add_theme_font_size_override("font_size", UI.SMALL if compact else UI.BIG)
		if button.custom_minimum_size.x > 0.0:
			button.custom_minimum_size.x = 160.0 if compact else 240.0
			button.custom_minimum_size.y = 40.0 if compact else 52.0
