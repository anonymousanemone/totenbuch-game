## Screen-space interface: a title bar and the scribe's strip under the scene, both deep papyrus
## and each set off from the scene by the scroll's own frame band. The strip holds the last line said (its speaker as a tag on the
## band), what you carry, and the Journal and Hint buttons; the Journal opens as a page over the
## scene. Built in code so the level scenes stay small. Each level passes its own titles and texts
## to setup(). Its look (palette, font, band, icons) is in ui.gd.
extends CanvasLayer

signal hint_pressed
signal restart_pressed
signal menu_pressed

const TOP_BAR := 46.0         ## the title bar, without its band
const STRIP := 130.0          ## the scribe's strip, its band included
const BOXED := false          ## the band also down the screen's sides and along its bottom, round the strip
const EDGE := 12.0            ## that band, which has ink only on the strip's side
const TAG_H := 32.0           ## the speaker's tag, centred on the band
const OVERLAY_W := 900.0      ## the intro and outro cards' text, at most this wide (at the dialogue size)

## Keys are written in brackets ("hold [shift]"); these are shown as written, not read as BBCode
## tags ("[s]" would otherwise start a strikethrough).
const KEY_NAMES := ["space", "shift", "esc", "←", "→", "↑", "↓", "w", "a", "s", "d"]

var _level: Node
var _cfg: Dictionary
var _root: Control
var _say: RichTextLabel
var _tag: PanelContainer
var _tag_label: Label
var _journal_page: Control
var _journal_grid: GridContainer
var _journal_title: Label
var _journal_empty: Label
var _held: TextureRect
var _intro: Control
var _outro: Control
var _outro_text: RichTextLabel
var _text := ""
var _journal_entries := {}
var _journal_scroll: ScrollContainer
var _overlay_layouts: Array = []
var _revision := 0
var _title_label: Label


## cfg keys: title, journal_hint, intro_title, intro_body, outro_title.
func setup(level: Node, cfg: Dictionary) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_level = level
	_cfg = cfg
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.theme()
	add_child(_root)
	_build_top_bar()
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
	get_viewport().size_changed.connect(_resize_hud)
	_resize_hud.call_deferred()
	_sync_pause()
	if "--journal" in OS.get_cmdline_user_args():   # dev: open the Journal (for a screenshot)
		toggle_journal.call_deferred(true)


# ---------------------------------------------------------------- API used by the level

func top_height() -> float:
	return TOP_BAR + UI.BAND


## How far the speaker's tag reaches up above the strip (it sits centred on the strip's band).
func tag_reach() -> float:
	return (TAG_H - UI.BAND) / 2.0


func bottom_height() -> float:
	return STRIP


func is_blocking() -> bool:
	return _intro.visible or _outro.visible or _journal_page.visible


func dismiss_intro() -> void:
	_intro.visible = false
	_sync_pause()


func reset_view() -> void:
	_journal_entries.clear()
	for c in _journal_grid.get_children():
		c.queue_free()
	_journal_empty.visible = true
	_journal_title.text = "JOURNAL"
	_journal_page.visible = false
	_outro.visible = false
	_sync_pause()


func say(who: String, text: String, category := "default") -> void:
	# Hint-button messages take precedence over the surrounding gameplay context.
	if who == "Hint":
		category = "hint"
	var color: Color = UI.TAG_HINT if category == "hint" else UI.TAG_MINIGAME if category == "minigame" else UI.TAG
	_tag.add_theme_stylebox_override("panel", UI.box(color, UI.INK, 4, 12, 0))
	_tag_label.add_theme_color_override("font_color", UI.INK if category == "hint" else UI.CREAM)
	_text = UI.plain(text)
	_tag_label.text = who
	_tag.visible = who != ""
	_revision += 1
	_say.text = _keys(_text)   # always at the dialogue size (two font pixels to a screen pixel), never paged


func _sync_pause() -> void:
	var blocked := is_blocking()
	if get_tree().paused and not blocked:
		# A key used while reading must not become a movement/exit on resume.
		for action in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept"]:
			Input.action_release(action)
	get_tree().paused = blocked


## Deferred messages are discarded when an interaction, reset, or later line supersedes them.
func say_later(who: String, text: String, seconds: float, category := "default") -> void:
	var revision := _revision
	await get_tree().create_timer(seconds, false).timeout
	if revision == _revision:
		say(who, text, category)


func show_outro_later(body: String, seconds: float) -> void:
	var revision := _revision
	await get_tree().create_timer(seconds, false).timeout
	if revision == _revision:
		show_outro(body)


## The piece follows the pointer at roughly its on-screen size.
func update_held(piece: String, tex: Texture2D, zoom: float) -> void:
	_held.visible = piece != ""
	if piece == "":
		return
	_held.texture = tex
	_held.size = tex.get_size() * zoom * 0.8
	_held.position = _root.get_local_mouse_position() + Vector2(14, 10)


func add_journal_entry(label: String, note: String, tex: Texture2D, count: int, total: int, id := "", speaker := "") -> void:
	_journal_empty.visible = false
	_journal_title.text = "Journal · %d/%d" % [count, total]
	if id == "":
		id = label
	if speaker == "":
		speaker = label
	if _journal_entries.has(id):
		var old: Dictionary = _journal_entries[id]
		old.label.text = label
		old.picture.texture = tex
		old.text = note
		old.speaker = speaker
		return
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
	_journal_entries[id] = {"node": entry, "label": name_label, "picture": pic, "text": note, "speaker": speaker}
	entry.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var observed: Dictionary = _journal_entries[id]
			say(observed.speaker, observed.text))
	_journal_grid.add_child(entry)
	_journal_grid.move_child(entry, 0)


func show_outro(body: String) -> void:
	var next := Scroll.next_built(_level.scene_file_path.get_file().get_basename())
	var destination: String = "Next: [b]%s[/b]." % next.title if not next.is_empty() else "Return to the scroll."
	_outro_text.text = _keys(body + "\n\n" + destination)
	_outro.visible = true
	_resize_hud.call_deferred()
	_sync_pause()


## The Journal opens over the scene; [j] or the button toggles it, [esc] or a click beside it closes it.
func toggle_journal(open := not _journal_page.visible) -> void:
	_journal_page.visible = open
	_sync_pause()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _intro.visible or _outro.visible:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			if _intro.visible:
				dismiss_intro()
			else:
				Scroll.finish(_level.scene_file_path.get_file().get_basename())
			get_viewport().set_input_as_handled()
		return
	if _journal_page.visible and event.keycode in [KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN, KEY_HOME, KEY_END]:
		match event.keycode:
			KEY_UP: _journal_scroll.scroll_vertical -= 70
			KEY_DOWN: _journal_scroll.scroll_vertical += 70
			KEY_PAGEUP: _journal_scroll.scroll_vertical -= 240
			KEY_PAGEDOWN: _journal_scroll.scroll_vertical += 240
			KEY_HOME: _journal_scroll.scroll_vertical = 0
			KEY_END: _journal_scroll.scroll_vertical = int(_journal_scroll.get_v_scroll_bar().max_value)
		get_viewport().set_input_as_handled()
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
	_title_label = title
	title.text = _cfg.title
	title.add_theme_font_size_override("font_size", UI.BIG)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(spacer)
	row.add_child(UI.icon_button("restart", "Restart", func(): restart_pressed.emit()))
	row.add_child(UI.icon_button("menu", "Menu", func(): menu_pressed.emit()))


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
	row.offset_right = -edge - 16
	row.offset_top = UI.BAND + 8
	row.offset_bottom = -edge - 8
	row.add_theme_constant_override("separation", 24)
	strip.add_child(row)

	# what is said, centred in the strip
	_say = _rich(UI.DIALOGUE)
	_say.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_say.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_say.add_theme_constant_override("line_separation", 0)
	_say.add_theme_constant_override("paragraph_separation", 0)
	row.add_child(_say)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_child(_labelled_button("journal", "journal", "Journal  [j]", func(): toggle_journal()))
	buttons.add_child(_labelled_button("hint", "hint", "Hint", func(): hint_pressed.emit()))
	row.add_child(buttons)

	# the speaker's tag sits on the band
	_tag = PanelContainer.new()
	_tag.add_theme_stylebox_override("panel", UI.box(UI.TAG, UI.INK, 4, 12, 0))
	_tag.custom_minimum_size.y = TAG_H
	_tag.position = Vector2(edge + 24, (UI.BAND - TAG_H) / 2.0)
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.visible = false
	_tag_label = Label.new()
	_tag_label.add_theme_color_override("font_color", UI.CREAM)
	_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tag.add_child(_tag_label)
	strip.add_child(_tag)


## The Journal: a page over the scene, between the title bar and the strip.
func _build_journal_page() -> void:
	_journal_page = ColorRect.new()
	(_journal_page as ColorRect).color = UI.DIM
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
	close.text = "↑↓ scroll · j/esc close"
	close.add_theme_color_override("font_color", UI.OCHRE)
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
	_journal_empty.add_theme_color_override("font_color", UI.OCHRE)
	v.add_child(_journal_empty)
	var scroll := ScrollContainer.new()
	_journal_scroll = scroll
	scroll.custom_minimum_size = Vector2(600, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journal_grid = GridContainer.new()
	_journal_grid.columns = 7
	_journal_grid.add_theme_constant_override("h_separation", 22)
	_journal_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_journal_grid)
	v.add_child(scroll)


func _build_overlay(title: String, body: String, button: String, on_press: Callable) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(UI.DIM, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = false
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 4, 36, 30))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", UI.BIG)
	t.add_theme_color_override("font_color", UI.TAG)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var b := _rich(UI.DIALOGUE)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.name = "Body"
	b.custom_minimum_size.x = OVERLAY_W
	b.text = _keys(body)
	scroll.add_child(b)
	_overlay_layouts.append({"scroll": scroll, "body": b, "title": t})
	var btn := Button.new()
	btn.text = button
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.add_theme_font_size_override("font_size", UI.BIG)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(on_press)
	var button_margin := MarginContainer.new()
	button_margin.add_theme_constant_override("margin_top", 6)
	button_margin.add_child(btn)
	v.add_child(button_margin)
	_overlay_layouts[-1]["button"] = btn
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
	text = text.replace("\n\n", "\n")
	text = text.replace("[b]", "[color=#%s]" % UI.TAG.to_html(false)).replace("[/b]", "[/color]")
	text = text.replace("[i]", "[color=#%s]" % UI.OCHRE.to_html(false)).replace("[/i]", "[/color]")
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


func _resize_hud() -> void:
	var viewport := get_viewport().get_visible_rect().size
	_title_label.add_theme_font_size_override("font_size", UI.SMALL if viewport.x < 900.0 else UI.BIG)
	var journal_width := clampf(viewport.x - 100.0, 240.0, 960.0)
	_journal_scroll.custom_minimum_size = Vector2(journal_width, clampf(viewport.y - top_height() - STRIP - 150.0, 80.0, 380.0))
	_journal_grid.columns = maxi(1, floori((journal_width + 22.0) / 134.0))
	for layout in _overlay_layouts:
		var width := clampf(viewport.x - 120.0, 200.0, OVERLAY_W)
		layout.body.custom_minimum_size.x = width
		layout.title.custom_minimum_size.x = width
		var available: float = viewport.y - 142.0 - layout.title.get_combined_minimum_size().y - layout.button.get_combined_minimum_size().y
		var height: float = minf(maxf(40.0, available), layout.body.get_content_height() + 8.0)
		layout.scroll.custom_minimum_size = Vector2(width, maxf(40.0, height))


func _exit_tree() -> void:
	get_tree().paused = false
