## Shared input, pause, action dispatch and scene lifetime.
extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1


func press_t(echo := false, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_T
	event.pressed = pressed
	event.echo = echo
	root.push_input(event)


func _run() -> void:
	var progress = root.get_node("Scroll")
	var menu: DebugMenu = null
	for child in progress.get_children():
		if child is DebugMenu:
			menu = child
	expect(menu != null, "Scroll owns the debug playtest menu")
	if menu == null:
		quit(1)
		return
	change_scene_to_file("res://scenes/menu.tscn")
	await scene_changed
	await process_frame
	press_t()
	expect(menu._panel.visible and menu._entries.get_child(0) is Label, "title offers no completion actions")
	current_scene._show(current_scene._map)
	await process_frame
	press_t()
	press_t()
	expect(menu._panel.visible and menu._entries.get_child(0) is Label, "map offers no completion actions")
	progress.open("procession")
	await scene_changed
	await process_frame
	expect(not menu._panel.visible and menu._entries.get_child_count() == 0, "scene change clears the previous menu")
	press_t()
	expect(paused and menu._panel.visible and menu._entries.get_child(0).disabled, "T opens over the paused intro with actions disabled")
	press_t(true)
	press_t(false, false)
	expect(menu._panel.visible, "repeats and key releases do not toggle")
	press_t()
	expect(paused and not menu._panel.visible, "closing the menu preserves the intro pause")
	var level = current_scene
	level.hud.dismiss_intro()
	press_t()
	var setup: Button = menu._entries.get_child(0)
	expect(not setup.disabled, "Procession setup action is enabled during play")
	level.hud.toggle_journal(true)
	setup.pressed.emit()
	expect(menu._panel.visible and not level.in_table, "dispatch rechecks pause after the Journal opens")
	level.hud.toggle_journal(false)
	setup.pressed.emit()
	expect(not menu._panel.visible and level.in_table and level.solved.t4, "registered action closes the menu and sets up the table")
	progress.open("dangers")
	await scene_changed
	await process_frame
	current_scene.hud.dismiss_intro()
	current_scene.finish()
	press_t()
	expect(menu._panel.visible and menu._entries.get_child(0).disabled, "Dangers disables completion before its ending wipe")
	progress.open("cosmos")
	await scene_changed
	await process_frame
	current_scene.hud.dismiss_intro()
	press_t()
	expect(menu._entries.get_child_count() == 1 and menu._entries.get_child(0).text == "Complete level",
		"levels without hooks receive only the shared action")
	progress.open("procession", true)
	await scene_changed
	await process_frame
	press_t()
	expect(menu._entries.get_child_count() == 1 and menu._entries.get_child(0) is Label, "View mode offers no completion actions")
	print("DEBUG MENU REGRESSIONS ", "OK" if failures == 0 else "FAILED")
	quit(0 if failures == 0 else 1)
