## Saved menu layouts, responsive navigation, and fixed map header/footer.
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
	expect(preview.size == Vector2(1280, 1686), "scroll authored at viewport width and full content height")
	expect(preview.get_node("Header").get_meta("_edit_lock_") and preview.get_node("Footer").get_meta("_edit_lock_"), "header and footer are locked editor elements")
	root.size = Vector2i(1280, 1686)
	root.add_child(preview)
	await frames()
	var last: Control = preview.get_node("Levels/Acts/ActF")
	expect(last.get_global_rect().end.y < preview.get_node("Footer").get_global_rect().position.y,
		"full editor layout shows the finale above the footer")
	expect(preview.get_node("Levels").scroll_vertical == 0 and preview.get_node("Levels").get_v_scroll_bar().max_value <= preview.get_node("Levels").size.y,
		"all map content fits the expanded editor layout")
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
		for row in menu._cards.get_children():
			for card in row.get_children():
				if card.has_meta("key"):
					keys.append(card.get_meta("key"))
					expect(card in authored_cards, tag + "saved card reused: " + card.name)
		expect(keys.size() == progress.SCENES.size() and not keys.has("sun") and not keys.has("amulets"), tag + "map contains exactly the current index")
		for entry in progress.SCENES:
			var card: Control = menu._cards.find_child(entry.key, true, false)
			card.grab_focus()
			expect(menu._chosen == entry.key and menu._chosen_go.disabled == not progress.is_built(entry.key), tag + "keyboard selection: " + entry.key)
		menu._choose("survival")
		expect(menu._chosen_go.text in ["Play", "Play again"] and not menu._chosen_go.disabled, tag + "Survival is playable")
		progress.restored.assign(["procession"])
		menu._refresh_map()
		expect(map.get_node("Levels/Acts/ActI/procession/Frame/Picture/Restored").visible and map.get_node("Levels/Acts/ActI/cosmos/Frame/Picture/Current").visible,
			tag + "progress updates saved indicators")
		var head_before: Rect2 = map.get_node("Header").get_global_rect()
		var foot_before: Rect2 = map.get_node("Footer").get_global_rect()
		map.get_node("Levels").scroll_vertical = 100000
		await frames()
		expect(map.get_node("Levels").scroll_vertical > 0, tag + "full list scrolls to its end")
		expect(map.get_node("Header").get_global_rect() == head_before and map.get_node("Footer").get_global_rect() == foot_before,
			tag + "header and footer stay fixed while scrolling")
		expect(inside(map.get_node("Header")) and inside(map.get_node("Footer")) and inside(menu._chosen_go), tag + "fixed bars and Play stay inside viewport")
		expect(map.get_node("Levels").clip_contents, tag + "cards clip between fixed bars in play")
		map.get_node("Header/Back").pressed.emit()
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
