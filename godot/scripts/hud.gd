## Screen-space interface: a title bar and the scribe's strip under the scene, both deep papyrus
## and each set off from the scene by the scroll's own frame band. The strip holds the last line said (its speaker as a tag on the
## band), what you carry, and the Journal and Hint buttons; the Journal opens as a page over the
## scene. Built in code so the level scenes stay small. Each level passes its own titles and texts
## to setup(). Its look (palette, font, band, icons) is in ui.gd.
extends CanvasLayer

signal hint_pressed
signal restart_pressed
signal minimap_clicked(world_x: float)
signal menu_pressed

const TOP_BAR := 46.0         ## the title bar, without its band
const STRIP := 120.0          ## the scribe's strip, its band included
const BOXED := false          ## the band also down the screen's sides and along its bottom, round the strip
const EDGE := 12.0            ## that band, which has ink only on the strip's side
const MINIMAP_H := 30.0
const SHOW_MINIMAP := false   ## the overview strip of the whole scroll under the title bar

## Keys are written in brackets ("hold [shift]"); these are shown as written, not read as BBCode
## tags ("[s]" would otherwise start a strikethrough).
const KEY_NAMES := ["space", "shift", "esc", "←", "→", "↑", "↓", "w", "a", "s", "d"]

var _level: Node
var _cfg: Dictionary
var _root: Control
var _say: RichTextLabel
var _tag: PanelContainer
var _tag_label: Label
var _hand: Control
var _hand_icon: TextureRect
var _hand_label: Label
var _journal_count: Label
var _journal_page: Control
var _journal_grid: GridContainer
var _journal_title: Label
var _journal_empty: Label
var _held: TextureRect
var _minimap: Minimap
var _intro: Control
var _outro: Control
var _outro_text: RichTextLabel
var _who := ""
var _text := ""
var _done: Array = []         ## the rites, as the level last reported them (no longer listed)


## cfg keys: title, journal_hint, intro_title, intro_body, outro_title. (subtitle, tasks,
## rites_heading, bottom and task_size belong to the old three-card panel and are ignored.)
func setup(level: Node, cfg: Dictionary) -> void:
	_level = level
	_cfg = cfg
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.theme()
	add_child(_root)
	_build_top_bar()
	if SHOW_MINIMAP:
		_build_minimap()
	_build_strip()
	_build_journal_page()
	_held = TextureRect.new()
	_held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_held.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_held.modulate.a = 0.9
	_held.visible = false
	_root.add_child(_held)
	_intro = _build_overlay(cfg.intro_title, cfg.intro_body, "Begin", dismiss_intro)
	_intro.visible = true
	_outro = _build_overlay(cfg.outro_title, "", "Go on", func(): Scroll.finish(level.scene_file_path.get_file().get_basename()))
	_outro_text = _outro.find_child("Body", true, false)
	if "--journal" in OS.get_cmdline_user_args():   # dev: open the Journal (for a screenshot)
		toggle_journal.call_deferred(true)


# ---------------------------------------------------------------- API used by the level

func top_height() -> float:
	return TOP_BAR + UI.BAND + (MINIMAP_H if SHOW_MINIMAP else 0.0)


func bottom_height() -> float:
	return STRIP


func is_blocking() -> bool:
	return _intro.visible or _outro.visible or _journal_page.visible


func dismiss_intro() -> void:
	_intro.visible = false


func reset_view() -> void:
	for c in _journal_grid.get_children():
		c.queue_free()
	_journal_empty.visible = true
	_journal_count.text = "journal"
	_journal_title.text = "JOURNAL"
	_journal_page.visible = false
	_outro.visible = false


func say(who: String, text: String) -> void:
	_who = who
	_text = text
	_tag_label.text = who
	_tag.visible = who != ""
	_set_say_size(UI.BIG)
	_say.text = _keys(text)
	_fit_say()


## Two font pixels to a screen pixel if the line fits the strip, else one. The text waits hidden
## for a frame while it is laid out at the large size.
func _fit_say() -> void:
	var text := _text
	_say.modulate.a = 0.0
	await get_tree().process_frame
	if text != _text:
		return
	if _say.get_content_height() > STRIP - UI.BAND - (EDGE if BOXED else 0.0) - 8.0:
		_set_say_size(UI.SMALL)
	_say.modulate.a = 1.0


func _set_say_size(size: int) -> void:
	for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_say.add_theme_font_size_override(k, size)


## The rites are no longer listed: the scene shows what is still wrong. Levels still report them.
func update_tasks(done: Array) -> void:
	_done = done


func update_hand(piece: String, label: String, tex: Texture2D, note := "[esc] puts it back.") -> void:
	_hand.visible = piece != ""
	_hand_icon.texture = tex
	_hand.tooltip_text = "Holding %s." % label if piece != "" else ""
	_hand_label.text = note


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
	_journal_count.text = "%d/%d" % [count, total]
	_journal_title.text = "JOURNAL — %d of %d figures recorded" % [count, total]
	var entry := VBoxContainer.new()
	entry.custom_minimum_size.x = 112
	entry.mouse_filter = Control.MOUSE_FILTER_STOP
	entry.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box(UI.DEEP, UI.RULE, 2, 4, 4))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := TextureRect.new()
	pic.texture = tex
	pic.custom_minimum_size = Vector2(104, 72)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(pic)
	var name_label := Label.new()
	name_label.text = label
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.x = 112
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(frame)
	entry.add_child(name_label)
	entry.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			say(label, note))
	_journal_grid.add_child(entry)
	_journal_grid.move_child(entry, 0)
	frame.modulate = Color(1.6, 1.3, 0.7)
	create_tween().tween_property(frame, "modulate", Color.WHITE, 1.0)


func show_outro(body: String) -> void:
	_outro_text.text = _keys(body)
	_outro.visible = true


## The Journal opens over the scene; [j] or the button toggles it, [esc] or a click beside it closes it.
func toggle_journal(open := not _journal_page.visible) -> void:
	_journal_page.visible = open


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo) or _intro.visible or _outro.visible:
		return
	if event.keycode == KEY_J:
		toggle_journal()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and _journal_page.visible:
		toggle_journal(false)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- building

func _build_top_bar() -> void:
	var bar := ColorRect.new()
	bar.color = UI.DEEP
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOP_BAR
	_root.add_child(bar)
	UI.band(bar, "band_top", Control.PRESET_BOTTOM_WIDE, Rect2(0, 0, 0, UI.BAND))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)
	var title := Label.new()
	title.text = _cfg.title
	title.add_theme_font_size_override("font_size", UI.BIG)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(spacer)
	row.add_child(UI.icon_button("restart", "Restart", func(): restart_pressed.emit()))
	row.add_child(UI.icon_button("menu", "Menu", func(): menu_pressed.emit()))


func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.strip = _level.get_node("Strip").texture
	_minimap.level_width = _level.level.width
	_minimap.plates = _level.level.plates
	_minimap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_minimap.offset_top = TOP_BAR + UI.BAND
	_minimap.offset_bottom = TOP_BAR + UI.BAND + MINIMAP_H
	_minimap.clicked.connect(func(x): minimap_clicked.emit(x))
	_root.add_child(_minimap)


## The strip: deep papyrus under the band (and, if BOXED, inside it along the screen's edges), the
## line said with its speaker's tag on the band, what you carry, Journal and Hint.
func _build_strip() -> void:
	var strip := ColorRect.new()
	strip.color = UI.DEEP
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -STRIP
	_root.add_child(strip)
	UI.band(strip, "band_top", Control.PRESET_TOP_WIDE, Rect2(0, 0, 0, UI.BAND))
	var edge := EDGE if BOXED else 0.0
	if BOXED:
		UI.band(strip, "band_bottom", Control.PRESET_BOTTOM_WIDE, Rect2(0, -EDGE, 0, 0))
		UI.band(strip, "band_left", Control.PRESET_LEFT_WIDE, Rect2(0, UI.BAND, EDGE, -EDGE))
		UI.band(strip, "band_right", Control.PRESET_RIGHT_WIDE, Rect2(-EDGE, UI.BAND, 0, -EDGE))

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = edge + 28
	row.offset_right = -edge - 24
	row.offset_top = UI.BAND + 8
	row.offset_bottom = -edge
	row.add_theme_constant_override("separation", 24)
	strip.add_child(row)

	# what you carry: a small picture of it, and what Esc does
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 10)
	_hand.visible = false
	_hand.mouse_filter = Control.MOUSE_FILTER_PASS
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 4, 4, 4))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hand_icon = TextureRect.new()
	_hand_icon.custom_minimum_size = Vector2(56, 52)
	_hand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_hand_icon)
	_hand_label = Label.new()
	_hand_label.custom_minimum_size.x = 120
	_hand_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hand_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hand_label.add_theme_color_override("font_color", UI.OCHRE)
	_hand.add_child(frame)
	_hand.add_child(_hand_label)
	row.add_child(_hand)

	_say = _rich(UI.BIG)
	_say.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_say.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_say)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 22)
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var journal := _labelled_button("journal", "journal", "Journal  [j]", func(): toggle_journal())
	_journal_count = journal.get_child(1)
	buttons.add_child(journal)
	buttons.add_child(_labelled_button("hint", "hint", "Hint", func(): hint_pressed.emit()))
	row.add_child(buttons)

	# the speaker's tag sits on the band
	_tag = PanelContainer.new()
	_tag.add_theme_stylebox_override("panel", UI.box(UI.TAG, UI.INK, 4, 12, 2))
	_tag.position = Vector2(edge + 24, -14)
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.visible = false
	_tag_label = Label.new()
	_tag_label.add_theme_color_override("font_color", UI.CREAM)
	_tag.add_child(_tag_label)
	strip.add_child(_tag)


## The Journal: a page over the scene, between the title bar and the strip.
func _build_journal_page() -> void:
	_journal_page = ColorRect.new()
	(_journal_page as ColorRect).color = Color(0.12, 0.08, 0.04, 0.5)
	_journal_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_journal_page.offset_top = top_height()
	_journal_page.offset_bottom = -STRIP
	_journal_page.mouse_filter = Control.MOUSE_FILTER_STOP
	_journal_page.visible = false
	_journal_page.gui_input.connect(func(e):    # a click beside the page closes it
		if e is InputEventMouseButton and e.pressed:
			toggle_journal(false))
	_root.add_child(_journal_page)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_journal_page.add_child(center)
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 4, 28, 20))
	center.add_child(sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	sheet.add_child(v)
	var head := HBoxContainer.new()
	_journal_title = Label.new()
	_journal_title.text = "JOURNAL"
	_journal_title.add_theme_font_size_override("font_size", UI.BIG)
	_journal_title.add_theme_color_override("font_color", UI.TAG)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Label.new()
	close.text = "[j] or [esc] closes"
	close.add_theme_color_override("font_color", UI.RULE)
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_journal_title)
	head.add_child(spacer)
	head.add_child(close)
	v.add_child(head)
	var rule := ColorRect.new()
	rule.color = UI.INK
	rule.custom_minimum_size.y = 4
	v.add_child(rule)
	_journal_empty = Label.new()
	_journal_empty.text = _cfg.get("journal_hint", "")
	_journal_empty.add_theme_color_override("font_color", UI.RULE)
	v.add_child(_journal_empty)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(960, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journal_grid = GridContainer.new()
	_journal_grid.columns = 7
	_journal_grid.add_theme_constant_override("h_separation", 22)
	_journal_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_journal_grid)
	v.add_child(scroll)


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
	panel.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 4, 28, 22))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", UI.BIG)
	t.add_theme_color_override("font_color", UI.TAG)
	v.add_child(t)
	var b := _rich(UI.SMALL)
	b.name = "Body"
	b.custom_minimum_size.x = 640
	b.text = _keys(body)
	v.add_child(b)
	var btn := Button.new()
	btn.text = button
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.add_theme_font_size_override("font_size", UI.BIG)
	btn.pressed.connect(on_press)
	v.add_child(btn)
	return dim


## An icon button with a small word under it (the Journal's count, "hint").
func _labelled_button(icon: String, word: String, tip: String, on_press: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var b := UI.icon_button(icon, tip, on_press)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER   # signs centre on one line, the words sit below
	var l := Label.new()
	l.text = word
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", UI.OCHRE)
	v.add_child(b)
	v.add_child(l)
	return v


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
