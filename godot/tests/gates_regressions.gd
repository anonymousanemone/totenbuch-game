## Spells 144–146 exploration: complete artwork, authored placement, picking, navigation and the pylon plumes.
extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1
func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 480)]:
		root.size = dimensions
		var scene = load("res://scenes/gates.tscn").instantiate()
		var authored := {}
		for sprite in scene.get_node("Figures").find_children("*", "Sprite2D", true, false):
			authored[sprite] = sprite.position
		root.add_child(scene)
		for i in 8:
			await process_frame
		expect(paused and scene.hud.is_blocking(), "intro pauses exploration")
		expect(scene.level.sources.size() == 2 and scene.figures.size() == 121, "spells 144–146 import 121 rooms, pylons, portals and their gods")
		expect(scene._descriptions.journal_total() == 100, "every room, pylon, portal and god counts in the journal; adorers do not")
		var pylons: Array = scene.figures.keys().filter(func(id): return id.begins_with("spell145_pylon") and id.count("_") == 1)
		expect(pylons.size() == 21 and pylons.all(func(id): return scene.figures[id].material is ShaderMaterial \
			and scene.figures[id].material.get_shader_parameter("base") > 0.0), "every pylon carries its plumes' sway")
		var adorers: Array = scene.figures.keys().filter(func(id): return id.ends_with("_adorer"))
		expect(adorers.size() == 21 and adorers.all(func(id): return not scene.figures[id].visible), "every adorer is hidden until his keeper is named")
		expect(scene.get_node("Avatar/Sprite").texture.get_height() == scene.figures["spell145_pylon1_adorer"].texture.get_height() + 4 \
			and scene.avatar.drawn_facing == -1, "the avatar is a copy of the first adorer, who faces left")
		var pylon: Sprite2D = scene.figures["spell145_pylon1"]
		var lift := func() -> float: return float(pylon.material.get_shader_parameter("lift"))
		var tween: Tween = PylonPlumes.react(pylon, true)
		tween.custom_step(PylonPlumes.RISE + 0.1)
		var risen: float = lift.call()
		tween.custom_step(PylonPlumes.HOLD + PylonPlumes.SETTLE)
		expect(risen > 0.9 and absf(lift.call()) < 0.001, "a right name raises the plumes, which then settle")
		tween = PylonPlumes.react(pylon, false)
		tween.custom_step(PylonPlumes.RISE + 0.1)
		var sagged: float = lift.call()
		tween.custom_step(PylonPlumes.HOLD + PylonPlumes.SETTLE)
		expect(sagged < -0.9 and absf(lift.call()) < 0.001, "a wrong name makes the plumes sag, then settle")
		scene.name_given(3, false)
		expect(not scene.figures["spell145_pylon3_adorer"].visible, "a wrong name brings no adorer")
		scene.name_given(3, true)
		expect(scene.figures["spell145_pylon3_adorer"].visible and not scene.figures["spell145_pylon4_adorer"].visible, "a right name brings that pylon's adorer only")
		expect(scene.figures.values().all(func(n): return authored.has(n) and n.position == authored[n]), "saved nodes retain editor positions")
		scene.hud.dismiss_intro()
		scene.avatar.set_process(false)
		var start: Vector2 = scene.avatar.position
		Input.action_press("ui_left")
		scene.avatar._process(0.2)
		Input.action_release("ui_left")
		expect(scene.avatar.position.x < start.x, "arrow navigation walks left")
		for edge in [-10000.0, 10000.0]:
			scene.walk_then(edge)
			scene.avatar._process(100.0)
			scene.avatar._process(0.1)
			scene._update_camera(1.0)
			var view: Rect2 = scene.SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
			expect(view.position.x >= -0.1 and view.end.x <= scene.level.width + 0.1, "unrestricted click walking and camera stay within scroll")
		var missed := []
		for id in scene.figures:
			var sprite: Sprite2D = scene.figures[id]
			var image := sprite.texture.get_image()
			var found := false
			for y in range(0, image.get_height(), 4):
				for x in range(0, image.get_width(), 4):
					if image.get_pixel(x,y).a > 0.5 and scene._pick(sprite.to_global(Vector2(x,y))) == id:
						found = true
						break
				if found:
					break
			if not found and scene.figures[id].visible:
				missed.append(id)
			if found and not scene.figures[id].visible:
				missed.append(id + " (hidden)")
		expect(missed.is_empty(), "every shown gate and god is separately pickable, hidden adorers are not: %s" % [missed])
		var id := "spell146_p65_5_figure"
		scene._set_hover(id)
		expect(is_instance_valid(scene._glow), "hover uses shared glow")
		scene.walk_then(5200, scene.record.bind(id))
		scene.avatar._process(100.0)
		scene.avatar._process(0.1)
		scene.record(id)
		expect(scene.journal.size() == 1 and scene.hud._text == scene._descriptions.text(id), "arrival describes and journals figure once")
		scene.hud.toggle_journal(true)
		expect(paused and scene.hud.is_blocking(), "journal pauses exploration")
		scene.hud.toggle_journal(false)
		scene.reset()
		expect(scene.journal.is_empty() and scene.avatar.position == start, "restart restores saved start")
		expect(not scene.figures["spell145_pylon3_adorer"].visible, "restart hides the adorers again")
		var page: Rect2 = scene.get_canvas_transform() * Rect2(0, scene.VIEW_TOP, 100, scene.level.view_height - scene.VIEW_TOP)
		expect(page.position.y >= scene.hud.top_height()-1 and page.end.y <= dimensions.y-scene.hud.bottom_height()+1, "scroll fits HUD at both window sizes")
		scene.free()
		await process_frame
	print("GATES REGRESSIONS ", "OK" if failures == 0 else "FAILED")
	quit(0 if failures == 0 else 1)
