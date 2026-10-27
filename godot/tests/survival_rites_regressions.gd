## Survival's rites (survival_play.gd): sceptres, splicing, the gate and the mummy, the dwelling,
## upside down, and the water of 57 and 59.
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
func seconds(s: float) -> void:
	await create_timer(s).timeout
## Walk him to x at once (the avatar's own step, run long).
func walk(scene, x: float) -> void:
	scene.walk_then(x)
	scene.avatar._process(100.0)
	scene.avatar._process(0.1)
	scene._process(0.016)
func _run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.time_scale = 6.0
	var scene = load("res://scenes/survival.tscn").instantiate()
	root.add_child(scene)
	await frames(8)
	scene.hud.dismiss_intro()
	scene.avatar.set_process(false)

	# the drawing is whole: every piece is in place, except where a rite starts wrong
	expect(scene.pieces.size() == 46, "every cut piece has a saved sprite")
	for key in ["spell43_sceptre1", "spell44_door", "spell45_mummy_body", "spell53_loaf1", "spell54_sail", "spell59_mw1"]:
		expect(scene.pieces[key].visible, key + " is drawn in place")
	expect(not scene.pieces.spell47_ba.visible, "the ba is missing until the dwelling is claimed")
	expect(not scene.pieces.spell57_upper_body.visible and not scene.pieces.spell57_lower_body.visible, "no one stands under the 57 water")
	expect(scene.pieces.spell57_stream.region_rect.size.y < scene.pieces.spell57_stream.texture.get_height() * 0.5, "the 57 water only dribbles")
	expect(not scene.pieces.spell57_tray.visible, "the 57 tray is in the tree")
	expect(not scene.pieces.spell59_seated_man.visible and not scene.pieces.spell59_stream.visible, "the 59 chair is empty and no water flows")
	expect(not scene.figures.spell43_worshipper.visible and not scene.figures.spell51_walking_man.visible, "the figures he stands in for are hidden")
	expect(scene._look == "43", "he starts as the 43 worshipper")

	# 43: the sceptres go onto his back
	scene._use("#sceptres", Vector2.ZERO)
	scene.avatar._process(100.0)
	scene.avatar._process(0.1)
	expect(scene._carried.size() == 3 and scene._sceptres.all(func(o): return o.state == MoveableObject.State.WORN), "clicking the sceptres puts all three on his back")
	scene._sceptres[0].follow()
	expect(scene._pick(scene._sceptres[0].sprite.global_transform * Vector2(4, 120)) in ["#sceptres", ""], "the carried sceptres can be clicked")

	# 43|44: spliced at the line, both ways
	scene.avatar.position.x = scene.SPLICE_43_44 + 20.0
	scene._process(0.016)
	expect(scene._splice.visible and scene._look == "43", "at the 43|44 line he is drawn in two parts")
	expect(is_equal_approx((scene._splice.material as ShaderMaterial).get_shader_parameter("clip_max"), scene.SPLICE_43_44), "the part past the line is the 44 man")
	walk(scene, scene.SPLICE_43_44 - 200.0)
	expect(scene._look == "44" and not scene._splice.visible, "past the line he is the 44 man")
	expect(scene.get_node("Figures/Spell44/DoorDark").visible, "in 44 the door turns black")
	walk(scene, scene.SPLICE_43_44 + 200.0)
	expect(scene._look == "43", "walking back he is the worshipper again")

	# 44: the door takes a sceptre; he becomes the mummy, then the 46 man
	walk(scene, -10000.0)
	expect(scene.avatar.position.x >= scene.LINE_44_45, "the 44|45 line bars the way on")
	scene._use("#door", Vector2.ZERO)
	scene.avatar._process(100.0)
	scene.avatar._process(0.1)
	expect(scene.mode == scene.Mode.SCENE and scene._carried.size() == 2, "entering the gate costs a sceptre")
	scene.avatar.set_process(true)
	await seconds(4.0 + scene.MUMMY_ROCK + 3.0 * scene.DARK)
	expect(scene.gate_used and scene._look == "46" and scene.mode == scene.Mode.WALK, "after the mummy he walks on as the 46 man")
	expect(scene._carried.size() == 2 and scene._carried.all(func(o): return o.sprite.visible), "he keeps the two sceptres left")
	expect(is_equal_approx(scene.avatar.max_x, scene.LINE_45_46 - scene.HALF), "there is no way back past 45|46")
	scene.avatar.set_process(false)

	# 47: a note each time he passes the dwelling unclaimed
	walk(scene, (scene.DWELLING.x + scene.DWELLING.y) / 2.0)
	expect(scene.hud._text == scene._hints.message("survival.dwelling"), "passing 47 unclaimed, the scribe asks him to claim his seat")

	# 49|50, 50|51: spliced into the 50 man, then the 51 man upside down
	walk(scene, scene.SPLICE_49_50 - 200.0)
	expect(scene._look == "50", "past 49|50 he is the 50 man")
	walk(scene, scene.SPLICE_50_51 - 200.0)
	expect(scene.upside and scene._look == "51" and scene.avatar.upturn < 0.0, "through 50|51 he comes out as the 51 man, upside down")
	# dragged upward past halfway, he stands upright
	var h: float = scene.avatar.sprite.texture.get_height()
	var top := Vector2(scene.avatar.position.x, scene.avatar.position.y - h * 0.5)
	expect(scene._pick(top) == "#flip", "upside down, he can be taken hold of")
	scene._use("#flip", top)
	scene._flip_from = 0.0
	# _flip_input reads the pointer; drive the drag by its result instead
	scene.avatar.upturn = 0.4
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	scene._flip_input(release)
	await seconds(1.5)
	expect(not scene.upside and scene.mode == scene.Mode.WALK, "released past halfway, he snaps upright")
	# back upside down, into 52: he eats filth and loses a sceptre
	scene.upside = true
	walk(scene, scene.LINE_51_52 - 100.0)
	expect(scene._carried.size() == 1 and not scene.upside, "headlong into 52 costs a sceptre")

	# 57: held up under the water, the tray comes out of the tree
	walk(scene, scene.level.pieces.spell57_lower_body.x + 40.0)
	scene._use("#water57", Vector2.ZERO)
	scene.avatar._process(100.0)
	scene.avatar._process(0.1)
	await seconds(1.5)
	expect(scene.mode == scene.Mode.WATER57 and scene.pieces.spell57_upper_body.visible, "he fades into the 57 man")
	expect(scene._bending and scene.pieces.spell57_stream.region_rect.size.y == scene.pieces.spell57_stream.texture.get_height(), "the water flows in full")
	scene._water57(0.5)
	expect(scene._bend < 0.0, "let go, he bends lower")
	for i in 200:
		scene._bend = 0.0
		scene._bend_v = 0.0
		scene._water57(0.05)
		if scene._solved.has(57):
			break
	expect(scene._solved.has(57), "kept in the stream, the tray comes all the way out")
	await seconds(2.5)
	expect(scene.mode == scene.Mode.WALK and scene.avatar.visible and scene.pieces.spell57_upper_body.visible, "he stands up beside the 57 man, who stays")

	# 59: the lines in their order make the water flow
	walk(scene, (scene.VIGNETTE_59.x + scene.VIGNETTE_59.y) / 2.0)
	expect(scene._sequence_busy, "entering 59, the sequence plays")
	await seconds((scene.LINE_ORDER.size() + 3) * (scene.FLASH + scene.FLASH_GAP))
	expect(not scene._sequence_busy, "after the sequence the lines can be clicked")
	scene._line59(scene.LINE_ORDER[1])
	expect(scene._sequence_busy and scene._next == 0, "a wrong line replays the sequence")
	await seconds((scene.LINE_ORDER.size() + 3) * (scene.FLASH + scene.FLASH_GAP))
	for key in scene.LINE_ORDER:
		scene._line59(key)
	await seconds(2.0)
	expect(scene._solved.has(59) and scene.mode == scene.Mode.SEATED59 and scene.pieces.spell59_seated_man.visible, "in order, the water flows and he sits beneath it")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	scene._unhandled_input(esc)
	await seconds(2.0)
	expect(scene.mode == scene.Mode.WALK and scene.avatar.visible and scene.pieces.spell59_seated_man.visible, "esc stands him up; the seated man stays")

	# no sceptres left at the door: his head falls and the level begins again
	scene.reset()
	await frames()
	walk(scene, scene.LINE_44_45 + scene.HALF)
	scene.journal.append("spell43_osiris")
	scene._enter_gate()
	expect(scene.mode == scene.Mode.SCENE and not scene.avatar.visible, "without sceptres, the gate kills him")
	await seconds(3.2)
	expect(not scene.gate_used and scene._look == "43" and scene.avatar.position == scene._start and scene._sceptres.all(func(o): return o.state == MoveableObject.State.WORLD), "after his head falls the level begins again")
	expect(scene.journal.has("spell43_osiris"), "the Journal is kept")
	Engine.time_scale = 1.0
	scene.free()
	await frames()
	print("SURVIVAL RITES REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
