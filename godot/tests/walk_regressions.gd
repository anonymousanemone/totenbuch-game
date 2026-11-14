## Walk-only levels (the Fourteen Mounds, Mouth and Heart): saved scene, navigation, picking, journal and framing.
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
	for key in ["mounds", "mouth", "hall"]:
		for dimensions in [Vector2i(1280, 720), Vector2i(800, 600)]:
			root.size = dimensions
			var scene = load("res://scenes/%s.tscn" % key).instantiate()
			var authored: Array = scene.get_node("Figures").find_children("*", "Sprite2D", true, false)
			root.add_child(scene)
			await frames(8)
			var tag := "%s %dx%d " % [key, dimensions.x, dimensions.y]
			expect(root.get_node("Scroll").is_built(key), tag + "the scroll list recognizes the built scene")
			expect(paused and scene.hud.is_blocking(), tag + "introduction pauses exploration")
			expect(scene.figures.size() == scene._descriptions.entries.size(), tag + "every registry entry is a saved sprite")
			expect(scene.figures.values().all(func(n): return n in authored), tag + "runtime reuses saved figure sprites")
			expect(scene.figures.keys().all(func(id): return scene.level.figures.has(id)), tag + "every figure has its source rectangle in level.json")
			expect(scene.get_node("Hitboxes").get_child_count() == scene.figures.size(), tag + "every figure has a hitbox")
			expect(scene.get_node("Avatar/Sprite").texture != null and scene.avatar.position == Vector2(scene.level.start.x, scene.level.start.y), tag + "avatar starts at the right end on the ground line")
			scene.hud.dismiss_intro()
			expect(not paused, tag + "Begin resumes exploration")
			scene.avatar.set_process(false)
			var start: Vector2 = scene.avatar.position
			Input.action_press("ui_left")
			scene.avatar._process(0.2)
			Input.action_release("ui_left")
			expect(scene.avatar.position.x < start.x, tag + "left arrow walks toward the end of the scroll")
			scene.walk_then(-10000.0)
			scene.avatar._process(100.0)
			scene.avatar._process(0.1)
			expect(is_equal_approx(scene.avatar.position.x, scene.min_x()), tag + "click walking reaches the left end")
			scene._update_camera(1.0)
			var view: Rect2 = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
			expect(view.position.x >= -0.1 or view.size.x > scene.level.width, tag + "camera stays inside the left edge (or shows all of the scroll)")
			scene.walk_then(100000.0)
			scene.avatar._process(100.0)
			scene.avatar._process(0.1)
			scene._update_camera(1.0)
			view = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
			expect(is_equal_approx(scene.avatar.position.x, scene.max_x()) and (view.end.x <= scene.level.width + 0.1 or view.size.x > scene.level.width), tag + "rightward travel and camera stay inside the scroll (or show all of it)")
			var rows: Rect2 = scene.get_canvas_transform() * Rect2(0, scene.level.view_top, 100, scene.level.view_height - scene.level.view_top)
			expect(rows.position.y >= scene.hud.top_height() - 1 and rows.end.y <= dimensions.y - scene.hud.bottom_height() + 1, tag + "the rows shown fit between the shared HUD bars")
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
				expect(missed.is_empty(), tag + "every figure has pickable ink: %s" % [missed])
				expect(scene._pick(Vector2(-100.0, -100.0)) == "", tag + "empty papyrus does not select a figure")
				var first: String = scene.figures.keys()[0]
				scene._set_hover(first)
				expect(is_instance_valid(scene._glow) and scene._glow.get_parent() == scene.figures[first], tag + "hover uses the shared glow on the saved sprite")
				scene._set_hover("")
				var columns: Array = scene.level.columns.keys()
				if scene.has_node("Foreground"):
					var foreground: Node = scene.get_node("Foreground")
					expect(foreground.z_index > scene.avatar.z_index and foreground.get_child_count() == columns.size(), tag + "foreground columns lie over the avatar, one per column in level.json")
					var misplaced: Array = []
					for column in columns:
						var box: Dictionary = scene.level.columns[column]
						var node: Node2D = foreground.get_node("Column" + column.trim_prefix("column_"))
						if node.position != Vector2(box.x, box.y) or node.get_node("Papyrus").size != Vector2(box.w, box.h):
							misplaced.append(column)
					expect(misplaced.is_empty(), tag + "each column's papyrus backing covers exactly its recorded rectangle: %s" % [misplaced])
				else:
					expect(columns.is_empty(), tag + "no foreground node only when level.json has no columns")
			var id: String = scene.figures.keys().filter(func(i): return scene._descriptions.entries[i].get("journal", true))[0]
			scene.walk_then(scene.min_x(), func(): scene.record(id))
			scene.avatar._process(100.0)
			scene.avatar._process(0.1)
			expect(scene.journal.has(id) and scene.hud._text == scene._descriptions.text(id), tag + "walking arrival displays and journals the figure description")
			scene.record(id)
			expect(scene.journal.size() == 1, tag + "repeat looks do not duplicate journal entries")
			var unjournaled: Array = scene.figures.keys().filter(func(i): return not scene._descriptions.entries[i].get("journal", true))
			if not unjournaled.is_empty():
				scene.record(unjournaled[0])
				expect(scene.journal.size() == 1 and scene.hud._text == scene._descriptions.text(unjournaled[0]), tag + "captions and legends are read but not journaled")
			var captions: Array = scene.figures.keys().filter(func(i): return i.contains("caption"))
			if not captions.is_empty():
				var box: Rect2 = scene._descriptions.box(captions[0])
				expect(scene._pick(box.get_center()) == captions[0], tag + "a caption is hit by its box")
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
			scene.free()
			await frames()
	print("WALK REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
