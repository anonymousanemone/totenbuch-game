## Saved menu layouts, responsive navigation, and the map: one register of the scroll between fixed bars.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures.append(label)

func frames(count := 8) -> void:
	for i in count:
		await process_frame

func inside(control: Control) -> bool:
	return Rect2(Vector2.ZERO, Vector2(root.size)).grow(1).encloses(control.get_global_rect())

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	var progress = root.get_node("Scroll")
	var saved: Array[String] = progress.restored.duplicate()
	var preview = load("res://scenes/scroll.tscn").instantiate()
	preview.set_script(null)
	root.size = Vector2i(preview.size)
	root.add_child(preview)
	await frames()
	var reel: Control = preview.get_node("Levels/Acts")
	expect(preview.size.y == 720 and reel.get_combined_minimum_size().x == preview.size.x and preview.get_node("Levels").size.x == preview.size.x,
		"scroll authored as long as the whole register, so the editor shows every act")
	root.remove_child(preview)
	expect(preview.get_node("Header").get_meta("_edit_lock_") and preview.get_node("Footer").get_meta("_edit_lock_"), "header and footer are locked editor elements")
	var act_names: Array[String] = []
	for child in preview.get_node("Levels/Acts").get_children():
		if child is VBoxContainer:
			act_names.append(child.name)
	expect(act_names == ["Prologue", "ActI", "ActII", "ActIII", "ActIV", "ActV", "ActVI"], "the register holds every act, first to last: " + str(act_names))
	expect(preview.get_node("Levels/Acts/Prologue/Caption/Title").text == "Prologue"
		and preview.get_node("Levels/Acts/ActVI/Caption/Title").text == progress.ACTS["VI"], "act captions follow Scroll.ACTS")
	preview.free()
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 480)]:
		root.size = dimensions
		var menu = load("res://scenes/menu.tscn").instantiate()
		var title: Control = menu.get_node("Title")
		var map: Control = menu.get_node("Scroll")
		var authored_cards: Array = map.get_node("Levels/Acts").find_children("*", "VBoxContainer", true, false)
		var heading: Label = title.get_node("Frame/Center/Content/Heading")
		heading.text = "TOTENBUCH"
		root.add_child(menu)
		await frames()
		var tag := "%dx%d " % [dimensions.x, dimensions.y]
		expect(menu._title == title and menu._map == map, tag + "runtime reuses authored pages")
		expect(menu.size == Vector2(dimensions) and map.size == Vector2(dimensions), tag + "pages fit the game viewport")
		expect(inside(title.get_node("Frame/Center/Content")), tag + "title artwork and four buttons fit")
		var buttons: GridContainer = title.get_node("Frame/Center/Content/Buttons")
		expect(buttons.get_child_count() == 4 and buttons.get_node("Play").pressed.get_connections().size() == 1,
			tag + "saved title has four connected actions")
		buttons.get_node("TheScroll").pressed.emit()
		await frames()
		expect(map.visible and not title.visible, tag + "The scroll button opens the saved map")
		var keys: Array[String] = []
		for card in map.cards:
			keys.append(card.get_meta("key"))
			expect(card in authored_cards, tag + "saved card reused: " + card.name)
		expect(keys.size() == progress.SCENES.size() and not keys.has("sun") and not keys.has("amulets"), tag + "map contains exactly the current index")
		for entry in progress.SCENES:
			var card: Control = menu._cards.find_child(entry.key, true, false)
			card.grab_focus()
			expect(menu._chosen == entry.key and menu._chosen_go.disabled == not progress.is_built(entry.key), tag + "keyboard selection: " + entry.key)
		menu._choose("survival")
		expect(menu._chosen_go.text in ["Play", "Play again"] and not menu._chosen_go.disabled, tag + "Survival is playable")
		progress.restored.assign(["prologue", "procession"])
		menu._refresh_map()
		expect(map.card("procession").get_node("Frame/Picture/Restored").visible and map.card("cosmos").get_node("Frame/Picture/Current").visible,
			tag + "progress updates saved indicators")
		var head_before: Rect2 = map.get_node("Header").get_global_rect()
		var foot_before: Rect2 = map.get_node("Footer").get_global_rect()
		var levels: ScrollContainer = map.get_node("Levels")
		levels.scroll_horizontal = 100000
		await frames()
		var far: int = levels.scroll_horizontal
		levels.scroll_horizontal = 0
		await frames()
		expect(far > 0, tag + "the register scrolls sideways")
		expect(map.get_node("Header").get_global_rect() == head_before and map.get_node("Footer").get_global_rect() == foot_before,
			tag + "header and footer stay fixed while scrolling")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		levels.scroll_horizontal = far
		map._wheel(wheel)
		expect(levels.scroll_horizontal < far, tag + "the wheel moves on along the scroll, to the left")
		for key in ["prologue", "mounds", "hall"]:
			map._show_card(key)
			await frames()
			var shown: Rect2 = map.card(key).get_global_rect()
			var view: Rect2 = levels.get_global_rect()
			expect(shown.position.x >= view.position.x - 1 and shown.end.x <= view.end.x + 1, tag + "a chosen card comes into view: " + key)
		expect(map.card("prologue").get_global_rect().position.x > map.card("procession").get_global_rect().position.x, tag + "the register reads right to left")
		expect(inside(map.get_node("Header")) and inside(map.get_node("Footer")) and inside(menu._chosen_go), tag + "fixed bars and Play stay inside viewport")
		expect(map.get_node("Levels").clip_contents, tag + "cards clip between fixed bars in play")
		map.get_node("Header/Row/Settings").pressed.emit()
		await frames()
		expect(menu._settings.visible and not map.visible, tag + "the map's Settings opens the settings")
		menu._show(map)
		await frames()
		map.get_node("Header/Row/Back").pressed.emit()
		await frames()
		expect(title.visible and not map.visible, tag + "Back returns to title")
		buttons.get_node("Settings").pressed.emit()
		await frames()
		expect(menu._settings.visible and title.visible, tag + "Settings opens over saved title")
		menu._show(menu._controls)
		await frames()
		expect(inside(menu._controls.get_child(0).get_child(0)), tag + "controls retain responsive layout")
		menu.free()
		await frames()
	progress.restored.assign(saved)
	print("MENU SCENE REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
