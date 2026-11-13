## Field of Offerings exploration: saved scene, registers, navigation, picking, journal and framing.
extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures.append(label)
func frames(count := 4) -> void:
	for i in count:
		await process_frame
func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = dimensions
		var scene = load("res://scenes/field.tscn").instantiate()
		var authored: Array = scene.get_node("Figures").find_children("*", "Sprite2D", true, false)
		root.add_child(scene)
		await frames(8)
		var tag := "%dx%d " % [dimensions.x, dimensions.y]
		var lanes: Array = scene.level.lanes
		expect(paused and scene.hud.is_blocking(), tag + "introduction pauses exploration")
		expect(scene.figures.size() == scene._descriptions.entries.size(), tag + "every registry entry is a saved sprite")
		expect(scene.figures.values().all(func(n): return n in authored), tag + "runtime reuses saved figure sprites")
		expect(scene.figures.keys().all(func(id): return scene.level.figures.has(id)), tag + "every figure has its source rectangle in level.json")
		expect(scene.get_node("Avatar/Sprite").texture != null and scene.avatar.position == Vector2(scene.level.start.x, scene.level.start.y), tag + "avatar starts where the procession arrives")
		scene.hud.dismiss_intro()
		expect(not paused, tag + "Begin resumes exploration")
		scene.avatar.set_process(false)
		var start: Vector2 = scene.avatar.position
		Input.action_press("ui_left")
		scene.avatar._process(0.2)
		Input.action_release("ui_left")
		expect(scene.avatar.position.x < start.x, tag + "left arrow walks toward the scroll")
		scene.walk_then(-10000.0)
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		expect(is_equal_approx(scene.avatar.position.x, scene.min_x()), tag + "click walking reaches the left end of the page")
		scene._update_camera(1.0)
		var view: Rect2 = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
		expect(view.position.x >= scene.level.page.x - 0.1, tag + "camera stays inside the left edge of the page")
		scene.walk_then(100000.0)
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		scene._update_camera(1.0)
		view = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
		expect(is_equal_approx(scene.avatar.position.x, scene.max_x()) and view.end.x <= scene.level.page.x + scene.level.page.w + 0.1, tag + "rightward travel and camera stay inside the page")
		# registers: the avatar crosses between ground lines, the camera follows, and the ends hold
		expect(not scene.cross(-1) and scene.lane == 0, tag + "nothing lies above the top register")
		expect(scene.cross(1) and scene.lane == 1 and not scene.avatar.keys, tag + "down crosses to the middle register and holds the keys while it does")
		expect(not scene.cross(1), tag + "a second crossing waits for the first to finish")
		await create_timer(scene.CROSS_SECONDS + 0.3).timeout
		expect(is_equal_approx(scene.avatar.position.y, lanes[1].ground) and scene.avatar.keys, tag + "the avatar stands on the middle register's ground line")
		scene._update_camera(1.0)
		var rows: Dictionary = lanes[1]
		var page: Rect2 = scene.get_canvas_transform() * Rect2(0, rows.top, 100, rows.bottom - rows.top)
		expect(page.position.y >= scene.hud.top_height() - 1 and page.end.y <= dimensions.y - scene.hud.bottom_height() + 1, tag + "the register fits between the shared HUD bars")
		var water := Vector2(scene.level.water.x0 + 50.0, rows.inner_top - 20.0)
		expect(scene._water_step(water) == -1 and scene._water_step(Vector2(water.x, rows.ground + 30.0)) == 1 and scene._water_step(Vector2(water.x, rows.ground - 100.0)) == 0, tag + "water above and below a register crosses; the picture itself does not")
		expect(scene._water_step(Vector2(scene.level.water.x0 - 100.0, rows.inner_top - 20.0)) == 0, tag + "the sides of the scroll have no water to cross by")
		Input.action_press("ui_down")
		var key := InputEventKey.new()
		key.pressed = true
		key.keycode = KEY_DOWN
		scene._unhandled_input(key)
		Input.action_release("ui_down")
		expect(scene.lane == 2, tag + "the down arrow key crosses to the next lane")
		await create_timer(scene.CROSS_SECONDS + 0.3).timeout
		expect(scene.cross(1) and scene.lane == 3, tag + "the page's floor is below the third register")
		await create_timer(scene.CROSS_SECONDS + 0.3).timeout
		expect(is_equal_approx(scene.avatar.position.y, lanes[3].ground) and not scene.cross(1), tag + "the floor is the last lane")
		scene._update_camera(1.0)
		var floor_rows: Dictionary = lanes[3]
		var floor_view: Rect2 = scene.get_canvas_transform() * Rect2(0, floor_rows.top, 100, floor_rows.bottom - floor_rows.top)
		expect(floor_view.position.y >= scene.hud.top_height() - 1 and floor_view.end.y <= dimensions.y - scene.hud.bottom_height() + 1, tag + "the floor lane also fits between the HUD bars at the same zoom")
		expect(scene.cross(-1) and scene.lane == 2, tag + "up returns")
		await create_timer(scene.CROSS_SECONDS + 0.3).timeout
		if dimensions.x == 1280:
			var missed: Array = []
			for id in scene.figures:
				var sprite: Sprite2D = scene.figures[id]
				var image: Image = sprite.texture.get_image()
				var found := false
				for y in range(0, image.get_height(), 3):
					for x in range(0, image.get_width(), 3):
						if image.get_pixel(x, y).a > 0.5 and scene._pick(sprite.to_global(Vector2(x, y))) == id:
							found = true
							break
					if found:
						break
				if not found:
					missed.append(id)
			expect(missed.is_empty(), "every figure has independently pickable ink: %s" % [missed])
			expect(scene._pick(Vector2(-100.0, -100.0)) == "", "empty papyrus does not select a figure")
			var first: String = scene.figures.keys()[0]
			scene._set_hover(first)
			expect(is_instance_valid(scene._glow) and scene._glow.get_parent() == scene.figures[first], "hover uses the shared glow on the saved sprite")
			scene._set_hover("")
			var columns: Node = scene.get_node("Foreground")
			expect(columns.z_index > scene.avatar.z_index and columns.get_child_count() == scene.level.columns.size(), "foreground columns lie over the avatar, one per column in level.json")
			var misplaced: Array = []
			for key_name in scene.level.columns:
				var box: Dictionary = scene.level.columns[key_name]
				var node: Node2D = columns.get_node(key_name.to_pascal_case())
				var backing: Control = node.get_node("Papyrus")
				if node.position != Vector2(box.x, box.y) or backing.size != Vector2(box.w, box.h):
					misplaced.append(key_name)
			expect(misplaced.is_empty(), "each column's papyrus backing covers exactly its recorded rectangle: %s" % [misplaced])
		var id := "mummiform_god"
		scene.walk_then(scene.min_x(), func(): scene.record(id))
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		expect(scene.journal.has(id) and scene.hud._text == scene._descriptions.text(id), tag + "walking arrival displays and journals the figure description")
		scene.record(id)
		expect(scene.journal.size() == 1, tag + "repeat looks do not duplicate journal entries")
		scene.record("caption_top_rowing")
		expect(scene.journal.size() == 1, tag + "captions are read but not journaled")
		scene.hud.toggle_journal(true)
		var before: Vector2 = scene.avatar.position
		scene.avatar.set_process(true)
		Input.action_press("ui_right")
		await frames()
		Input.action_release("ui_right")
		expect(paused and scene.avatar.position == before, tag + "journal pauses walking")
		var click := InputEventMouseButton.new()
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		scene._unhandled_input(click)
		expect(not scene.avatar.is_walking(), tag + "journal blocks scene clicks")
		scene.hud.toggle_journal(false)
		scene.reset()
		expect(scene.journal.is_empty() and scene.lane == 0 and scene.avatar.position == scene._start and not scene.avatar.is_walking(), tag + "restart restores the start register and clears pending travel and journal")
		scene.free()
		await frames()
	print("FIELD REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
