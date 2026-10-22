## Saved map artwork fills its full length in the editor; only the list scrolls in play.
extends ColorRect

signal back_requested

var chosen := ""
@onready var cards: VBoxContainer = $Levels/Acts
@onready var count: Label = $Header/Count
@onready var chosen_name: Label = $Footer/Selection/Name
@onready var chosen_about: Label = $Footer/Selection/About
@onready var chosen_go: Button = $Footer/Selection/Play


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Levels.clip_contents = true
	$Header/Back.pressed.connect(_back)
	for signal_name in ["mouse_entered", "focus_entered"]:
		$Header/Back.connect(signal_name, func(): $Header/Back.modulate = UI.SUCCESS)
	for signal_name in ["mouse_exited", "focus_exited"]:
		$Header/Back.connect(signal_name, func(): $Header/Back.modulate = Color.WHITE)
	chosen_go.pressed.connect(func(): Scroll.open(chosen))
	chosen_go.focus_entered.connect(func(): chosen_go.add_theme_color_override("font_hover_color", UI.CREAM))
	chosen_go.focus_exited.connect(func(): chosen_go.add_theme_color_override("font_hover_color", UI.TAG))
	for row in cards.get_children():
		for card in row.get_children():
			if not card.has_meta("key"):
				continue
			var key: String = card.get_meta("key")
			card.focus_entered.connect(choose.bind(key))
			card.gui_input.connect(_card_input.bind(card, key))
	get_viewport().size_changed.connect(_resize)
	refresh()
	_resize()


func _back() -> void:
	if back_requested.get_connections().is_empty():
		get_tree().change_scene_to_file("res://scenes/menus.tscn")
	else:
		back_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().current_scene == self and event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


func _card_input(event: InputEvent, card: Control, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		choose(key)
	elif event.is_action_pressed("ui_accept"):
		choose(key)
		card.accept_event()


## Refresh state on authored cards without replacing editor layout or artwork.
func refresh() -> void:
	count.text = "%d of %d restored — right to left" % [Scroll.restored.size(), Scroll.SCENES.size()]
	if chosen == "":
		chosen = Scroll.current()
		if chosen == "":
			chosen = Scroll.SCENES[0].key
	for row in cards.get_children():
		for card in row.get_children():
			if not card.has_meta("key"):
				continue
			var key: String = card.get_meta("key")
			var pic: TextureRect = card.get_node("Frame/Picture")
			var built: bool = Scroll.is_built(key)
			pic.modulate.a = 1.0 if built else 0.22
			pic.get_node("Restored").visible = key in Scroll.restored
			pic.get_node("Current").visible = key == Scroll.current()
			card.get_node("Title").add_theme_color_override("font_color", UI.INK if built else UI.RULE)
	choose(chosen)


func choose(key: String) -> void:
	chosen = key
	for row in cards.get_children():
		for card in row.get_children():
			if card.has_meta("key"):
				var frame: PanelContainer = card.get_node("Frame")
				frame.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.TAG if card.get_meta("key") == key else UI.INK, 4, 4, 4))
	var entry := Scroll.scene(key)
	chosen_name.text = entry.title
	chosen_about.text = entry.about
	chosen_go.disabled = not Scroll.is_built(key)
	if not Scroll.is_built(key):
		chosen_go.text = "Not yet made"
	elif key in Scroll.restored:
		chosen_go.text = "Play again"
	else:
		chosen_go.text = "Play"


func _resize() -> void:
	var viewport := get_viewport_rect().size
	var compact := viewport.x < 1000.0 or viewport.y < 650.0
	for label in find_children("*", "Label", true, false):
		if label.has_meta("font_size"):
			var original: int = label.get_meta("font_size")
			label.add_theme_font_size_override("font_size", maxi(UI.SMALL, original / 2) if compact else original)
	chosen_go.add_theme_font_size_override("font_size", UI.SMALL if compact else UI.BIG)
	chosen_go.custom_minimum_size = Vector2(160, 40) if compact else Vector2(240, 52)
	chosen_name.add_theme_color_override("font_color", UI.INK if compact else UI.TAG)
	chosen_about.visible = viewport.x >= 1000.0
