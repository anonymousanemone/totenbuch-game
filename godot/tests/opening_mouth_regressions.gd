## Opening of the Mouth integration: focus, input ownership, pause, harmless misses and reset.
## Optional --mouth-images=/tmp/mouth captures the actual close views with a display renderer.
extends SceneTree

var failures: Array[String] = []
var image_dir := ""

func _initialize() -> void:
	_run.call_deferred()

func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures.append(label)

func frames(count := 5) -> void:
	for i in count:
		await process_frame

func shot(name: String) -> void:
	if image_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(image_dir.path_join(name + ".png"))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mouth-images="):
			image_dir = arg.trim_prefix("--mouth-images=")
			DirAccess.make_dir_recursive_absolute(image_dir)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 480)]:
		root.size = dimensions
		var level = load("res://scenes/procession.tscn").instantiate()
		root.add_child(level)
		await frames(8)
		level.hud.dismiss_intro()
		level.mouth.take_adze()
		level.avatar.sprite.flip_h = false
		level.avatar.sprite.position.y = -4.0
		level.mouth._process(0.0)
		var grip_world: Vector2 = level.mouth._adze.global_transform * OpeningMouth.ADZE_GRIP
		var grip_local := Transform2D(0.5305801, Vector2(-28.0, -290.0)) * OpeningMouth.ADZE_GRIP
		var hand_world: Vector2 = level.avatar.global_position + grip_local + Vector2(0.0, -4.0)
		expect(grip_world.is_equal_approx(hand_world), "the carried adze sits in the player's hand and follows the walking bob")
		level.avatar.position.x -= 40.0
		level.mouth._process(0.0)
		expect((level.mouth._adze.global_transform * OpeningMouth.ADZE_GRIP).is_equal_approx(grip_world - Vector2(40.0, 0.0)),
			"the adze travels with the player before carving")
		level.avatar.sprite.flip_h = true
		level.mouth._process(0.0)
		expect((level.mouth._adze.global_transform * OpeningMouth.ADZE_GRIP).is_equal_approx(level.avatar.global_position + Vector2(-grip_local.x, grip_local.y - 4.0))
			and level.mouth._adze.global_transform.determinant() < 0.0, "turning mirrors both the carried adze's position and drawing")
		await shot("%dx%d-carry" % [dimensions.x, dimensions.y])
		level.mouth.put_back()
		expect(level.mouth._adze.transform == level.mouth._adze_home_transform, "returning a mirrored adze restores its stand pose")
		level.mouth.take_adze()
		var stand: float = level._mouth_stand_x()
		var woman: Rect2 = level._descriptions.region_bounds(level._inspection_regions["kneeling_woman"])
		expect(stand == level.get_node("pieces/opening_mouth/StandPosition").global_position.x
			and stand > level.mouth.face_view().end.x and stand < woman.position.x,
			"mouth approach position lies between the mummy and kneeling woman")
		level.avatar.position.x = stand + 250.0
		level.enter_mouth()
		level._update_camera(1.0)
		expect(level.avatar.is_walking() and not level.mouth.active and level._focus != "mouth",
			"placing the adze starts walking before the face zoom")
		level.avatar._process(0.25)
		expect(not level.mouth.active, "the face view stays closed during the approach")
		for i in 100:
			if not level.avatar.is_walking():
				break
			level.avatar._process(0.05)
		expect(level.avatar.position.x == stand and level.mouth.active and level.avatar.facing == -1,
			"arrival between the figures opens the face view facing the mummy")
		await frames(8)
		level._update_camera(1.0)
		await frames(2)
		var tag := "%dx%d " % [dimensions.x, dimensions.y]
		var source: Dictionary = level.level.sprites.mouth_features
		expect(level.mouth._feature_origin == Vector2(source.x, source.y), tag + "face features align with their source-art coordinates")
		var all_carved := true
		for y in level.mouth._feature_image.get_height():
			for x in level.mouth._feature_image.get_width():
				if level.mouth._feature_image.get_pixel(x, y).a > 0.1:
					all_carved = all_carved and level.mouth._pixel_stroke[y * level.mouth._feature_image.get_width() + x] >= 0
		expect(all_carved, tag + "carving paths cover the current eye and mouth cutouts")
		var face: Rect2 = level.get_canvas_transform() * level.mouth.face_view()
		var usable := Rect2(0, level.hud.top_height(), dimensions.x,
			dimensions.y - level.hud.top_height() - level.hud.bottom_height())
		expect(usable.grow(1.0).encloses(face), tag + "face fits between the HUD bars")
		expect(level._focus == "mouth" and not level.avatar.keys, tag + "carving owns focus and movement")
		level.mouth._process(0.0)
		expect((level.mouth._adze.global_transform * OpeningMouth.ADZE_GRIP).is_equal_approx(level.mouth.get_global_mouse_position())
			and level.mouth._adze.global_transform.determinant() > 0.0, tag + "carving releases the adze to the pointer without a carried mirror")
		# Put the carried adze at its next target for the visual review.
		level.mouth.set_process(false)
		level.mouth._adze.position = level.mouth.next_chip(0) - OpeningMouth.ADZE_TIP * level.mouth._adze.scale
		await shot(tag.strip_edges() + "-start")
		level.mouth.strike(level.mouth.next_chip(0))
		var held_at: Vector2 = level.mouth.next_chip(0) - (OpeningMouth.ADZE_TIP - OpeningMouth.ADZE_GRIP) * OpeningMouth.CARVING_SCALE
		level.mouth._adze.rotation = -OpeningMouth.SWING / 2.0
		var grip: Vector2 = OpeningMouth.ADZE_GRIP * OpeningMouth.CARVING_SCALE
		level.mouth._adze.position = held_at - grip.rotated(level.mouth._adze.rotation)
		expect((level.mouth._adze.global_transform * OpeningMouth.ADZE_GRIP).is_equal_approx(held_at), tag + "adze handle stays at the pointer while rotated")
		expect(level.mouth.tip_at(held_at).is_equal_approx(level.mouth._adze.global_transform * OpeningMouth.ADZE_TIP), tag + "strike point matches the visible rotated blade tip")
		level.mouth._adze.rotation = 0.0
		var before: float = level.mouth._progress[0]
		expect(level.mouth.chop(held_at) and level.mouth._progress[0] > before and level.mouth._swing > 0.0,
			tag + "a click brings the adze down and chips where its blade's tip is, not under the pointer")
		var progress: float = level.mouth._progress[0]
		level._unhandled_input(InputEventMouseMotion.new())
		expect(level.mouth._progress[0] == progress, tag + "mouse motion cannot carve")
		level.hud.toggle_journal(true)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		level._unhandled_input(click)
		expect(paused and level.mouth._progress[0] == progress, tag + "Journal blocks carving input")
		level.hud.toggle_journal(false)
		var escape := InputEventAction.new()
		escape.action = "ui_cancel"
		escape.pressed = true
		level._unhandled_input(escape)
		level._update_camera(1.0)
		expect(not level.mouth.active and level.avatar.keys and level._focus == "", tag + "Esc restores walking and the normal view")
		level.mouth._process(0.0)
		expect((level.mouth._adze.global_transform * OpeningMouth.ADZE_GRIP).is_equal_approx(level.avatar.carrying_transform() * level.mouth._adze_carry_pose * OpeningMouth.ADZE_GRIP),
			tag + "leaving carving puts the adze back on the player")
		level.mouth.touch()
		level._update_camera(1.0)
		if dimensions.x == 1280:
			for i in 3:
				level.mouth.strike(level.mouth.next_chip(0))
			await shot("partial")
		var blank: Vector2 = level.mouth.face_view().position + Vector2(3, 3)
		progress = level.mouth._progress[0]
		for i in 20:
			level.mouth.strike(blank)
		expect(level.mouth.active and level.mouth._progress[0] == progress, tag + "repeated misses neither exit nor reset carving")
		level.reset()
		await create_timer(0.4).timeout
		expect(level.mouth._body.position == level.mouth._body_home
			and level.mouth.phase == OpeningMouth.Phase.START and not level.mouth._words.visible,
			tag + "restart restores the mummy and clears the minigame")
		expect(level.mouth._adze.transform == level.mouth._adze_home_transform, tag + "restart restores the adze stand pose")
		level.mouth.take_adze()
		level.mouth.touch()
		for stroke in [1, 0]:
			while level.mouth.active and not level.mouth.stroke_done(stroke):
				level.mouth.strike(level.mouth._feature_bounds[stroke].get_center())
		expect(level.mouth._features.texture.get_image().get_data() == level.mouth._feature_image.get_data(), tag + "completed carving restores the original feature pixels")
		level.mouth.take_words()
		expect(level.mouth.phase == OpeningMouth.Phase.SPOKEN, tag + "words cannot be picked up during their reveal")
		await create_timer(1.8).timeout
		level.mouth.take_words()
		expect(level.mouth.phase == OpeningMouth.Phase.WORDS, tag + "spoken words can be carried once revealed")
		level.mouth._process(0.0)
		expect(level.mouth._words.global_position.is_equal_approx(level.mouth.get_global_mouse_position()), tag + "carried words still follow the pointer")
		level.queue_free()
		await frames()
	print("MOUTH REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
