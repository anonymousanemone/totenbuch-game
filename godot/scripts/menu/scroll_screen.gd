## The map: every scene on one register of the scroll, reading right to left between its double rules,
## the acts captioned above their cards. The chosen scene's name is the tag on the strip's band, with
## what it is and Play / View beside it. The register scrolls sideways (wheel, arrows, or a card taking focus).
## The saved scene is written by tools/build_scroll_map.py; the earlier map is in archive/.
extends ColorRect

signal back_requested
signal settings_requested

const WHEEL_STEP := 120.0
const LONG := 120               ## a description longer than this is set small, to fit the strip

var chosen := ""
var cards: Array[Control] = []    ## every scene's card, in playing order
@onready var levels: ScrollContainer = $Levels
@onready var count: Label = $Count
@onready var chosen_name: Label = $Footer/Tag/Name
@onready var chosen_about: Label = $Footer/Selection/About
@onready var chosen_go: Button = $Footer/Selection/Play
@onready var chosen_view: Button = $Footer/Selection/View


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	levels.clip_contents = true
	for c in $Levels/Acts.find_children("*", "Control", true, false):
		if c.has_meta("key"):
			cards.append(c)
	cards.sort_custom(func(a, b): return _index(a.get_meta("key")) < _index(b.get_meta("key")))
	for button in [$Header/Row/Back, $Header/Row/Settings]:
		for signal_name in ["mouse_entered", "focus_entered"]:
			button.connect(signal_name, func(): button.modulate = UI.SUCCESS)
		for signal_name in ["mouse_exited", "focus_exited"]:
			button.connect(signal_name, func(): button.modulate = Color.WHITE)
	$Header/Row/Back.pressed.connect(_back)
	$Header/Row/Settings.pressed.connect(func(): settings_requested.emit())
	chosen_go.pressed.connect(func(): Scroll.open(chosen))
	chosen_view.pressed.connect(func(): Scroll.open(chosen, true))
	for button in [chosen_go, chosen_view]:
		button.focus_entered.connect(func(): button.add_theme_color_override("font_hover_color", UI.CREAM))
		button.focus_exited.connect(func(): button.add_theme_color_override("font_hover_color", UI.TAG))
	for card in cards:
		var key: String = card.get_meta("key")
		card.focus_entered.connect(choose.bind(key))
		card.gui_input.connect(_card_input.bind(card, key))
	levels.gui_input.connect(_wheel)
	get_viewport().size_changed.connect(_resize)
	refresh()


func _index(key: String) -> int:
	for i in Scroll.SCENES.size():
		if Scroll.SCENES[i].key == key:
			return i
	return -1


func card(key: String) -> Control:
	return cards[_index(key)]


func _back() -> void:
	if back_requested.get_connections().is_empty():
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	else:
		back_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().current_scene == self and event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


func _card_input(event: InputEvent, which: Control, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		choose(key)
	elif event.is_action_pressed("ui_accept"):
		choose(key)
		which.accept_event()


## The wheel moves along the scroll: down (or right) goes on, to the left; up goes back.
func _wheel(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var step := 0.0
	match event.button_index:
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			step = -WHEEL_STEP
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			step = WHEEL_STEP
		_:
			return
	levels.scroll_horizontal += int(step * maxf(event.factor, 1.0))
	levels.accept_event()


## Refresh state on the saved cards without replacing their layout or artwork; the chosen scene comes into view.
func refresh() -> void:
	count.text = "%d of %d scenes restored" % [Scroll.restored.size(), Scroll.SCENES.size()]
	if chosen == "":
		chosen = Scroll.current()
		if chosen == "":
			chosen = Scroll.SCENES[0].key
	for c in cards:
		var key: String = c.get_meta("key")
		var pic: TextureRect = c.get_node("Frame/Picture")
		var done: bool = key in Scroll.restored
		var inked := done or (Scroll.unlock_all and Scroll.is_built(key))   # restored scenes, or in debug every built one, are in dark ink
		pic.self_modulate.a = 1.0 if inked else 0.22
		pic.get_node("Restored").visible = done
		pic.get_node("Current").visible = key == Scroll.current()
		c.get_node("Title").add_theme_color_override("font_color", UI.INK if inked else UI.RULE)
	choose(chosen)
	_show_card.call_deferred(chosen)


func choose(key: String) -> void:
	chosen = key
	for c in cards:
		var frame: PanelContainer = c.get_node("Frame")
		var box := UI.box(UI.PAPYRUS, UI.TAG if c.get_meta("key") == key else UI.PAPYRUS, 4, 4, 4)
		frame.add_theme_stylebox_override("panel", box)
	var entry := Scroll.scene(key)
	chosen_name.text = entry.title
	$Footer/Tag.reset_size()
	chosen_about.text = entry.about
	chosen_about.set_meta("font_size", UI.BIG if entry.about.length() <= LONG else UI.SMALL)   # as the mockup: a long description in small type
	_resize()
	chosen_go.disabled = not Scroll.is_open(key)
	chosen_view.visible = Scroll.can_view(key)
	if not Scroll.is_built(key):
		chosen_go.text = "Not yet made"
	elif not Scroll.is_open(key):
		chosen_go.text = "Locked"
	elif key in Scroll.restored:
		chosen_go.text = "Play again"
	else:
		chosen_go.text = "Play"


## Scroll the register so the card is in the middle of the view.
func _show_card(key: String) -> void:
	var c := card(key)
	var x := c.global_position.x - levels.global_position.x + levels.scroll_horizontal
	levels.scroll_horizontal = int(x + c.size.x / 2.0 - levels.size.x / 2.0)


func _resize() -> void:
	var viewport := get_viewport_rect().size
	var compact := viewport.x < 1000.0 or viewport.y < 650.0
	for label in find_children("*", "Label", true, false):
		if label.has_meta("font_size"):
			var original: int = label.get_meta("font_size")
			label.add_theme_font_size_override("font_size", maxi(UI.SMALL, original / 2) if compact else original)
	for button in [chosen_go, chosen_view]:
		button.add_theme_font_size_override("font_size", UI.SMALL if compact else UI.BIG)
		button.custom_minimum_size = Vector2(160, 40) if compact else Vector2(240, 52)
	$Footer/Tag.reset_size()
