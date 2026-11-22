## Shared debug shortcuts for the current playable scroll scene.
class_name DebugMenu
extends CanvasLayer

@onready var _progress := get_parent()

var _panel: PanelContainer
var _entries: VBoxContainer
var _scene_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 129 # Above the Dangers ending wipe (128).
	_panel = PanelContainer.new()
	_panel.theme = UI.theme()
	_panel.add_theme_stylebox_override("panel", UI.box(UI.PAPYRUS, UI.INK, 2))
	_panel.theme.set_stylebox("disabled", "Button", UI.box(UI.DARK_PAPYRUS, UI.INK, 4, 16, 8))
	_panel.theme.set_color("font_disabled_color", "Button", UI.INK.darkened(0.15))
	_panel.position = Vector2(16, 16)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_entries = VBoxContainer.new()
	_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_entries)
	add_child(_panel)
	_close()
	get_tree().scene_changed.connect(_close)
	get_viewport().size_changed.connect(_fit)
	set_process(false)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T):
		return
	var level := get_tree().current_scene
	if level == null:
		return
	var key := level.scene_file_path.get_file().get_basename()
	get_viewport().set_input_as_handled()
	if _panel.visible:
		_close()
		return
	_scene_id = level.get_instance_id()
	if _progress.viewing or not _is_level(key):
		var label := Label.new()
		label.text = "No playtest actions here."
		_entries.add_child(label)
	else:
		if level.has_method("playtest_actions"):
			for entry in level.playtest_actions():
				_add_action(entry[0], entry[1])
		_add_action("Complete level", _progress.finish.bind(key))
	_panel.show()
	_fit()
	_process(0.0)
	set_process(true)


func _add_action(label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func():
		if not _can_run():
			return
		_close()
		action.call())
	_entries.add_child(button)


func _process(_delta: float) -> void:
	var enabled := _can_run()
	for entry in _entries.get_children():
		if entry is Button:
			entry.disabled = not enabled


func _can_run() -> bool:
	var level := get_tree().current_scene
	if get_tree().paused or _progress.viewing or level == null or level.get_instance_id() != _scene_id:
		return false
	return not level.has_method("playtest_is_finishing") or not level.playtest_is_finishing()


func _is_level(key: String) -> bool:
	return _progress.SCENES.any(func(entry): return entry.key == key) and _progress.is_built(key)


func _fit() -> void:
	var content := _entries.get_combined_minimum_size()
	var available := get_viewport().get_visible_rect().size - Vector2(32, 32)
	_panel.size = (content + Vector2(32, 16)).min(available)


func _close() -> void:
	_panel.hide()
	for entry in _entries.get_children():
		_entries.remove_child(entry)
		entry.queue_free()
	_scene_id = 0
	set_process(false)
