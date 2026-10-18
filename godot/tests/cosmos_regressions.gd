## Cosmos exploration integration: scene artwork, navigation, picking, journal, and framing.
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
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 480)]:
		root.size = dimensions
		var scene = load("res://scenes/cosmos.tscn").instantiate()
		var authored: Array = scene.get_node("Figures").find_children("*", "Sprite2D", true, false)
		root.add_child(scene)
		await frames(8)
		var tag := "%dx%d " % [dimensions.x, dimensions.y]
		expect(paused and scene.hud.is_blocking(), tag + "introduction pauses exploration")
		expect(scene.figures.size() == 51 and scene.level.figures.size() == 52, tag + "all 52 source cutouts are loaded, including the walking avatar")
		expect(scene.figures.values().all(func(n): return n in authored), tag + "runtime reuses saved figure sprites")
		expect(scene.get_node("Avatar/Sprite").texture != null, tag + "avatar uses the deceased cutout")
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
		expect(is_equal_approx(scene.avatar.position.x, scene.min_x()), tag + "click walking can reach the left edge without a puzzle gate")
		scene._update_camera(1.0)
		var view: Rect2 = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
		expect(view.position.x >= -0.1, tag + "camera stays inside the left edge")
		scene.walk_then(100000.0)
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		scene._update_camera(1.0)
		view = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
		expect(is_equal_approx(scene.avatar.position.x, scene.max_x()) and view.end.x <= scene.level.width + 0.1, tag + "rightward travel and camera stay inside the scroll")
		if dimensions.x == 1280:
			var missed: Array = []
			for id in scene.figures:
				var sprite: Sprite2D = scene.figures[id]
				var image: Image = sprite.texture.get_image()
				var found := false
				for y in range(0, image.get_height(), 5):
					for x in range(0, image.get_width(), 5):
						if image.get_pixel(x, y).a > 0.5 and scene._pick(sprite.to_global(Vector2(x, y))) == id:
							found = true
							break
					if found:
						break
				if not found:
					missed.append(id)
			expect(missed.is_empty(), "every figure has independently pickable ink: %s" % [missed])
			expect(scene._pick(Vector2(-100.0, -100.0)) == "", "empty papyrus does not select a figure")
			scene._set_hover("lion_left")
			expect(is_instance_valid(scene._glow) and scene._glow.get_parent() == scene.figures.lion_left, "hover uses the shared glow on the saved sprite")
			scene._set_hover("")
		var id := "lion_left"
		scene.walk_then(scene.min_x(), func(): scene.record(id))
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		expect(scene.journal.has(id) and scene.hud._text == scene._descriptions.text(id), tag + "walking arrival displays and journals the figure description")
		scene.record(id)
		expect(scene.journal.size() == 1, tag + "repeat looks do not duplicate journal entries")
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
		expect(scene.journal.is_empty() and scene.avatar.position == scene._start and not scene.avatar.is_walking(), tag + "restart restores the start and clears pending travel and journal")
		var page: Rect2 = scene.get_canvas_transform() * Rect2(0, scene.VIEW_TOP, 100, scene.level.view_height - scene.VIEW_TOP)
		expect(page.position.y >= scene.hud.top_height() - 1 and page.end.y <= dimensions.y - scene.hud.bottom_height() + 1, tag + "scroll fits between the shared HUD bars")
		scene.free()
		await frames()
	print("COSMOS REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
