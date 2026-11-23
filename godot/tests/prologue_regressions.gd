## The prologue (Guarding the Body): saved scene, the column's pans down, the row's walk, framing and the ending.
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


## Walk left with the keyboard until he stops at the left limit (and pushes on it once).
func walk_left(scene) -> void:
	Input.action_press("ui_left")
	for i in 400:
		scene.avatar._process(0.05)
		if scene._changing:
			break
	Input.action_release("ui_left")


func rows_fit(scene, dimensions: Vector2i) -> bool:
	var v: Dictionary = scene.view()
	var rows: Rect2 = scene.get_canvas_transform() * Rect2(v.left, v.top, 100, v.bottom - v.top)
	return rows.position.y >= scene.hud.top_height() - 1 and rows.end.y <= dimensions.y - scene.hud.bottom_height() + 1


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = dimensions
		var tag := "prologue %dx%d " % [dimensions.x, dimensions.y]
		var scene = load("res://scenes/prologue.tscn").instantiate()
		var authored: Array = scene.get_node("Figures").find_children("*", "Sprite2D", true, false)
		root.add_child(scene)
		await frames(8)
		expect(scene.figures.size() == scene._descriptions.entries.size() and scene.figures.size() == authored.size(), tag + "every registry entry is a saved sprite")
		expect(scene.get_node("Hitboxes").get_child_count() == scene.figures.size(), tag + "every figure has a hitbox")
		expect(scene.get_node("Foreground").z_index > scene.avatar.z_index, tag + "the frames' rules lie over the avatar")
		scene.hud.dismiss_intro()
		scene.avatar.set_process(false)
		if dimensions.x == 1280:
			var missed: Array = []
			for id in scene.figures:
				var sprite: Sprite2D = scene.figures[id]
				var image: Image = sprite.texture.get_image()
				var found := false
				for y in range(0, image.get_height(), 3):
					for x in range(0, image.get_width(), 3):
						if image.get_pixel(x, y).a > 0.5 and scene._pick(sprite.to_global(sprite.get_rect().position + Vector2(x, y))) == id:
							found = true
							break
					if found:
						break
				if not found:
					missed.append(id)
			expect(missed.is_empty(), tag + "every figure has pickable ink: %s" % [missed])
			scene.record("spell151ab_anubis")
			expect(scene.journal == ["spell151ab_anubis"], tag + "a figure clicked goes into the journal")
			scene.journal.clear()
		var first: Dictionary = scene.stage("151ab")
		var o: Vector2 = scene.origin("151ab")
		expect(scene.part == 0 and scene.avatar.position.y == o.y + first.ground and scene.avatar.position.x < o.x + first.wall_right, tag + "he starts in 151ab, inside its right wall, on its ground")
		var zoom: float = scene.camera.zoom.x
		expect(rows_fit(scene, dimensions), tag + "151ab: the rows shown fit between the HUD bars")
		var centre: float = o.x + (first.outer_left + first.outer_right) / 2.0
		expect(absf(scene.camera.position.x - centre) < 1.0, tag + "151ab: the camera holds on the vignette")
		scene.walk_then(100000.0)
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		expect(is_equal_approx(scene.avatar.position.x, scene.max_x()) and scene.max_x() < o.x + first.wall_right, tag + "151ab's right wall stops him")
		for key in ["151c", "151de"]:
			walk_left(scene)
			var width: float = scene.avatar.get_node("Sprite").texture.get_width()
			var above: String = scene.level.column[scene.part - 1]
			expect(scene._changing, tag + "walking out past %s's left wall starts the pan down" % above)
			expect(scene.avatar.position.x + width / 2.0 > scene.origin(key).x, tag + "the avatar is placed in " + key)
			await create_timer(scene.PAN + scene.FADE + 0.3).timeout
			scene._update_camera(1.0)
			var s: Dictionary = scene.stage(key)
			var ok: Vector2 = scene.origin(key)
			expect(not scene._changing and scene.avatar.modulate.a > 0.99, tag + key + ": he appears once the camera has panned")
			expect(scene.avatar.position.y == ok.y + s.ground and scene.avatar.position.x < ok.x + s.wall_right, tag + key + ": inside its right wall, on its ground")
			expect(is_equal_approx(scene.camera.zoom.x, zoom), tag + key + ": the camera keeps its size")
			expect(rows_fit(scene, dimensions), tag + key + ": the rows shown fit between the HUD bars")
			if key == "151c":
				expect(absf(scene.camera.position.x - (ok.x + (s.outer_left + s.outer_right) / 2.0)) < 1.0, tag + "151c: the camera holds on the vignette")
		expect(scene.in_row(), tag + "151de begins the row")
		var de: Dictionary = scene.stage("151de")
		expect(scene.max_x() < scene.origin("151de").x + de.wall_right, tag + "the row ends on the right at 151de's right wall")
		scene.walk_then(scene.origin("152").x + 300.0)
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		var before: float = scene.camera.position.x
		scene._update_camera(1.0)
		expect(scene.camera.position.x < before - 10.0 and not scene._changing, tag + "the camera follows him along the row into 152")
		scene.walk_then(100000.0)
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		expect(is_equal_approx(scene.avatar.position.x, scene.max_x()), tag + "he can walk back to 151de")
		scene._update_camera(1.0)
		var view: Rect2 = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
		expect(view.end.x <= scene.level.view_right + 0.5, tag + "the camera stops at the row's right double line")
		var actions: Array = scene.playtest_actions()
		expect(actions.size() == 5 and actions.all(func(a): return a[0].begins_with("Setup: ")), tag + "one setup action per vignette")
		actions[4][1].call()
		expect(scene.in_row() and scene.avatar.position.x > scene.origin("154").x and scene.avatar.position.x < scene.origin("152").x, tag + "Setup: stand in 154 puts him in 154")
		actions[1][1].call()
		expect(scene.part == 1, tag + "Setup: stand in 151c puts him in the column")
		actions[4][1].call()
		walk_left(scene)
		expect(scene.playtest_is_finishing(), tag + "154's left wall ends the prologue")
		scene.queue_free()
		await frames(2)
	if failures.is_empty():
		print("PROLOGUE REGRESSIONS OK")
	else:
		print("FAILURES: ", failures)
	quit(0 if failures.is_empty() else 1)
