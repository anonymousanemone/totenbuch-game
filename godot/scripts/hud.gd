## Screen-space interface: title bar, minimap of the whole scroll, scribe text, the hand,
## the checklist of rites and the journal of recorded figures. Built in code so the level
## scenes stay small. Each level passes its own titles, tasks and texts to setup().
extends CanvasLayer

signal hint_pressed
signal restart_pressed
signal minimap_clicked(world_x: float)
signal menu_pressed

const TOP_BAR := 40.0
const MINIMAP_H := 30.0
const SHOW_MINIMAP := false   ## the overview strip of the whole scroll under the title bar
const BOTTOM := 184.0

const PAPYRUS := Color("e7d6ae")
const PANEL := Color("f3e8cc")
const DARK := Color("2a1d10")
const LINE := Color("b89c64")
const INK := Color("2e1d10")
const OCHRE := Color("9a5b1e")
const RED := Color("a3321f")
const OK := Color("4d6b2a")
const CREAM := Color("ead9b0")
## Keys are written in brackets ("hold [shift]"); these are shown as written, not read as BBCode
## tags ("[s]" would otherwise start a strikethrough).
const KEY_NAMES := ["space", "shift", "esc", "←", "→", "↑", "↓", "w", "a", "s", "d"]

var _level: Node
var _cfg: Dictionary
var _root: Control
var _say: RichTextLabel
var _hand_icon: TextureRect
var _hand_label: RichTextLabel
var _tasks: Array[RichTextLabel] = []
var _journal_title: Label
var _journal_box: HBoxContainer
var _journal_empty: Label
var _held: TextureRect
var _minimap: Minimap
var _intro: Control
var _outro: Control
var _outro_text: RichTextLabel


## cfg keys: title, subtitle, tasks (Array of String), rites_heading, journal_hint,
## intro_title, intro_body, outro_title; optional bottom (panel height) and task_size.
func setup(level: Node, cfg: Dictionary) -> void:
	_level = level
	_cfg = cfg
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_build_top_bar()
	if SHOW_MINIMAP:
		_build_minimap()
	_build_bottom()
	_held = TextureRect.new()
	_held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_held.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_held.modulate.a = 0.9
	_held.visible = false
	_root.add_child(_held)
	_intro = _build_overlay(cfg.intro_title, cfg.intro_body, "Begin", dismiss_intro)
	_intro.visible = true
	_outro = _build_overlay(cfg.outro_title, "", "Play again", func(): restart_pressed.emit())
	_outro_text = _outro.find_child("Body", true, false)


# ---------------------------------------------------------------- API used by the level

func top_height() -> float:
	return TOP_BAR + (MINIMAP_H if SHOW_MINIMAP else 0.0)


func bottom_height() -> float:
	return _cfg.get("bottom", BOTTOM)


func is_blocking() -> bool:
	return _intro.visible or _outro.visible


func dismiss_intro() -> void:
	_intro.visible = false


func reset_view() -> void:
	for c in _journal_box.get_children():
		if c != _journal_empty:
			c.queue_free()
	_journal_empty.visible = true
	_journal_title.text = "JOURNAL"
	_outro.visible = false


func say(who: String, text: String) -> void:
	_say.text = "[color=#%s][b]%s:[/b][/color] %s" % [RED.to_html(false), who, _keys(text)]


func update_tasks(done: Array) -> void:
	var tasks: Array = _cfg.tasks
	for i in tasks.size():
		var line := "%d. %s" % [i + 1, tasks[i]]
		_tasks[i].text = "[color=#%s][s]%s[/s][/color]" % [OK.to_html(false), line] if done[i] else line


func update_hand(piece: String, label: String, tex: Texture2D, note := "[esc] puts it back.") -> void:
	_hand_icon.texture = tex
	if piece == "":
		_hand_label.text = "[i]Nothing in hand.[/i]"
	else:
		_hand_label.text = "Holding [b]%s[/b]. %s" % [label, _keys(note)]


## The piece follows the pointer at roughly its on-screen size.
func update_held(piece: String, tex: Texture2D, zoom: float) -> void:
	_held.visible = piece != ""
	if piece == "":
		return
	_held.texture = tex
	_held.size = tex.get_size() * zoom * 0.8
	_held.position = _root.get_local_mouse_position() + Vector2(14, 10)


func update_minimap(avatar_x: float, view: Rect2, wall_x: float, wall_visible: bool) -> void:
	if _minimap == null:
		return
	_minimap.avatar_x = avatar_x
	_minimap.view = view
	_minimap.wall_x = wall_x
	_minimap.wall_visible = wall_visible
	_minimap.queue_redraw()


func add_journal_entry(label: String, note: String, tex: Texture2D, count: int, total: int) -> void:
	_journal_empty.visible = false
	_journal_title.text = "JOURNAL · %d/%d" % [count, total]
	var entry := VBoxContainer.new()
	entry.custom_minimum_size.x = 100
	entry.mouse_filter = Control.MOUSE_FILTER_STOP
	entry.tooltip_text = note
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(PAPYRUS, LINE, 4, 2))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := TextureRect.new()
	pic.texture = tex
	pic.custom_minimum_size = Vector2(96, 64)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(pic)
	var name_label := Label.new()
	name_label.text = label
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(frame)
	entry.add_child(name_label)
	entry.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			say(label, note))
	_journal_box.add_child(entry)
	_journal_box.move_child(entry, 0)
	frame.modulate = Color(1.6, 1.3, 0.7)
	create_tween().tween_property(frame, "modulate", Color.WHITE, 1.0)


func show_outro(body: String) -> void:
	_outro_text.text = _keys(body)
	_outro.visible = true


# ---------------------------------------------------------------- building

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _box(DARK, DARK, 0, 0, 16, 4))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size.y = TOP_BAR
	_root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bar.add_child(row)
	var title := Label.new()
	title.text = _cfg.title
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", CREAM)
	var sub := Label.new()
	sub.text = _cfg.subtitle
	sub.add_theme_color_override("font_color", Color(CREAM, 0.65))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hint := Button.new()
	hint.text = "Hint"
	hint.pressed.connect(func(): hint_pressed.emit())
	var restart := Button.new()
	restart.text = "Restart"
	restart.pressed.connect(func(): restart_pressed.emit())
	var levels := Button.new()
	levels.text = "Levels"
	levels.pressed.connect(func(): menu_pressed.emit())
	for b in [hint, restart, levels]:
		b.focus_mode = Control.FOCUS_NONE     # keep the arrow keys for walking
	for c in [title, sub, spacer, hint, restart, levels]:
		row.add_child(c)
		if c is Label:
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.strip = _level.get_node("Strip").texture
	_minimap.level_width = _level.level.width
	_minimap.plates = _level.level.plates
	_minimap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_minimap.offset_top = TOP_BAR
	_minimap.offset_bottom = TOP_BAR + MINIMAP_H
	_minimap.clicked.connect(func(x): minimap_clicked.emit(x))
	_root.add_child(_minimap)


func _build_bottom() -> void:
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _box(DARK, DARK, 0, 0, 14, 10))
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -bottom_height()
	_root.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bottom.add_child(row)

	# scribe + hand
	var scribe := _card(row, "SCRIBE", 1.3)
	_say = _rich(18)
	_say.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scribe.add_child(_say)
	var hand := HBoxContainer.new()
	hand.add_theme_constant_override("separation", 10)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _box(PAPYRUS, LINE, 4, 3))
	box.custom_minimum_size = Vector2(92, 52)
	_hand_icon = TextureRect.new()
	_hand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_hand_icon)
	_hand_label = _rich(15)
	_hand_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hand_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hand.add_child(box)
	hand.add_child(_hand_label)
	scribe.add_child(hand)

	# rites
	var rites := _card(row, _cfg.rites_heading, 1.0)
	for t in _cfg.tasks:
		var l := _rich(_cfg.get("task_size", 16))
		rites.add_child(l)
		_tasks.append(l)

	# journal
	var j := _card(row, "JOURNAL", 1.2)
	_journal_title = j.get_child(0)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journal_box = HBoxContainer.new()
	_journal_box.add_theme_constant_override("separation", 8)
	_journal_empty = Label.new()
	_journal_empty.text = _cfg.journal_hint
	_journal_empty.autowrap_mode = TextServer.AUTOWRAP_WORD
	_journal_empty.custom_minimum_size.x = 260
	_journal_empty.modulate.a = 0.6
	_journal_box.add_child(_journal_empty)
	scroll.add_child(_journal_box)
	j.add_child(scroll)


func _card(parent: Control, heading: String, ratio: float) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(PANEL, LINE, 6, 1, 12, 8))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = ratio
	parent.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var h := Label.new()
	h.text = heading
	h.add_theme_font_size_override("font_size", 13)
	h.add_theme_color_override("font_color", OCHRE)
	v.add_child(h)
	return v


func _build_overlay(title: String, body: String, button: String, on_press: Callable) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = false
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, LINE, 8, 2, 26, 22))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var b := _rich(17)
	b.name = "Body"
	b.custom_minimum_size.x = 580
	b.text = _keys(body)
	v.add_child(b)
	var btn := Button.new()
	btn.text = button
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(on_press)
	v.add_child(btn)
	return dim


## `text` with its bracketed key names escaped for BBCode.
static func _keys(text: String) -> String:
	for k in KEY_NAMES:
		text = text.replace("[%s]" % k, "[lb]%s[rb]" % k)
	return text


func _rich(size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _box(bg: Color, border: Color, radius: int, border_w: int, pad_x := 8, pad_y := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	return s


func _make_theme() -> Theme:
	var th := Theme.new()
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Cormorant Garamond", "Georgia", "Times New Roman", "serif"])
	th.default_font = serif
	th.default_font_size = 16
	th.set_color("font_color", "Label", INK)
	th.set_color("default_color", "RichTextLabel", INK)
	th.set_color("font_color", "Button", INK)
	th.set_color("font_hover_color", "Button", INK)
	th.set_color("font_pressed_color", "Button", INK)
	th.set_stylebox("normal", "Button", _box(PANEL, LINE, 4, 1, 12, 3))
	th.set_stylebox("hover", "Button", _box(Color("fff4d8"), LINE, 4, 1, 12, 3))
	th.set_stylebox("pressed", "Button", _box(PAPYRUS, LINE, 4, 1, 12, 3))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return th


## The whole scroll in one thin band: where you are, what is on screen, and the barrier.
class Minimap extends Control:
	signal clicked(world_x: float)

	var strip: Texture2D
	var level_width := 1.0
	var plates := {}
	var avatar_x := 0.0
	var view := Rect2()
	var wall_x := 0.0
	var wall_visible := true

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(event.position.x / size.x * level_width)
			accept_event()

	func _draw() -> void:
		var k := size.x / level_width
		draw_rect(Rect2(Vector2.ZERO, size), Color("d6c08e"))
		draw_texture_rect(strip, Rect2(0, 2, size.x, size.y - 4), false, Color(1, 1, 1, 0.75))
		var font := get_theme_default_font()
		for n in plates:
			var p: Dictionary = plates[n]
			draw_string(font, Vector2((p.x + p.w) * k - 34, 12), "pl. " + n, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("2a1d10"))
		if wall_visible:
			var y := 0.0
			while y < size.y:
				draw_line(Vector2(wall_x * k, y), Vector2(wall_x * k, y + 4), Color("2a1d10"), 3)
				y += 8
		draw_rect(Rect2(view.position.x * k, 0, view.size.x * k, size.y), Color(0.64, 0.2, 0.12, 0.08))
		draw_rect(Rect2(view.position.x * k, 1, view.size.x * k, size.y - 2), Color("a3321f"), false, 2)
		draw_rect(Rect2(avatar_x * k - 1.5, 2, 3, size.y - 4), Color("a3321f"))
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color("2a1d10"), 2)
