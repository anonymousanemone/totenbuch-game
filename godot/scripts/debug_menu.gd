## Debug builds only: T opens a list of shortcuts to states of a level, for testing.
## Each entry is [label, Callable]; pressing one closes the menu and calls it.
class_name DebugMenu
extends CanvasLayer

var _panel: PanelContainer


func setup(entries: Array) -> void:
	layer = 100
	_panel = PanelContainer.new()
	_panel.theme = UI.theme()
	_panel.position = Vector2(16, 16)
	var list := VBoxContainer.new()
	_panel.add_child(list)
	for e in entries:
		var b := Button.new()
		b.text = e[0]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			_panel.visible = false
			e[1].call())
		list.add_child(b)
	_panel.visible = false
	add_child(_panel)


func toggle() -> void:
	_panel.visible = not _panel.visible
