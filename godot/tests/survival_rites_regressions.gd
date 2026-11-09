## Survival's rites (survival_play.gd): sceptres, splicing, the gate and the mummy, the dwelling,
## upside down, the offering tables of 52 and 53, and the water of 57 and 59.
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
## Wait (up to `limit` s) until the scene is in `mode`.
func until_mode(scene, mode: int, limit := 10.0) -> void:
	var left := limit
	while scene.mode != mode and left > 0.0:
		await process_frame
		left -= 0.016
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
	expect(scene.pieces.size() == scene.level.pieces.size(), "every cut piece has a saved sprite")
	for key in ["spell43_sceptre1", "spell44_door", "spell45_mummy_body", "spell59_mw1"]:
		expect(scene.pieces[key].visible, key + " is drawn in place")
	expect(not scene.pieces.spell47_ba.visible, "the ba is missing until the dwelling is claimed")
	expect(not scene.pieces.spell57_man.visible, "no one stands under the 57 water")
	expect(scene.pieces.spell57_stream.region_rect.size.y < scene.pieces.spell57_stream.texture.get_height() * 0.5, "the 57 water only dribbles")
	expect(not scene.pieces.spell57_tray.visible, "the 57 tray is in the tree")
	expect(not scene.pieces.spell59_seated_man.visible and not scene.pieces.spell59_stream.visible, "the 59 chair is empty and no water flows")
	expect(not scene.figures.spell52_seated_man.visible and not scene.figures.spell53_seated_man.visible, "the 52 and 53 chairs are empty")
	expect(not scene.pieces.spell53_loaf1.visible and not scene.pieces.spell53_whisp5.visible, "the 53 table is bare")
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
	await until_mode(scene, scene.Mode.MUMMY)
	expect(scene.mode == scene.Mode.MUMMY and scene._swing > 0.0, "45: he is the mummy, rocking")
	var cam_at: Vector2 = scene.camera.position
	await seconds(scene.widen.OPEN + 0.3)
	expect(scene._swing > scene.MUMMY_START and absf(scene.get_node("Figures/Spell45/Mummy").rotation) > 0.0, "45: left alone, it rocks wider")
	expect(scene.camera.position == cam_at, "45: the camera holds still (minigame view)")
	var w = scene.widen
	expect(is_equal_approx(w.amount, 1.0) and is_equal_approx(w.sides[0].position.x, w._home[0].x - w.WIDEN) and is_equal_approx(w.sides[1].position.x, w._home[1].x + w.WIDEN), "45: what lies beyond the vignette's double lines is pushed out WIDEN px each side")
	expect(w._gaps.all(func(c): return c.position.y >= w.TOP and c.position.y + c.size.y <= w.GROUND and is_equal_approx(c.size.x, w.WIDEN)), "45: the gaps are WIDEN wide and stop at the ground rule; the text below stays")
	var tm: Sprite2D = scene.pieces.spell45_tm
	scene._mummy_input(_click(scene.get_canvas_transform() * (tm.global_position + tm.texture.get_size() / 2.0)))
	expect(tm.modulate != Color.WHITE, "45: clicking the tm sign flashes it")
	while scene.mode == scene.Mode.MUMMY:
		scene.click_tm()
		await process_frame
	await until_mode(scene, scene.Mode.WALK)
	expect(scene.widen.amount == 0.0 and not scene.widen.layer.visible, "45: won, the vignette is back as drawn")
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
	walk(scene, scene._waist().x + 40.0)
	scene._use("#water57", Vector2.ZERO)
	scene.avatar._process(100.0)
	scene.avatar._process(0.1)
	await seconds(1.5)
	expect(scene.mode == scene.Mode.WATER57 and scene.pieces.spell57_man.visible, "he fades into the 57 man")
	expect(scene.widen.amount == 1.0 and scene.widen.cell == scene.widen.CELLS[57], "57: the vignette opens out")
	expect(scene._bending and scene.pieces.spell57_stream.region_rect.size.y == scene.pieces.spell57_stream.texture.get_height(), "the water flows in full")
	scene._water57(0.5)
	expect(scene._bend < 0.0, "let go, he bends lower")
	expect(scene._drops.any(func(d): return d.kind == "fall"), "his hands out of the stream, it drips off its end")
	var splashed := false
	for i in 60:
		scene._move_drops(0.02)
		splashed = splashed or scene._drops.any(func(d): return d.kind == "splash")
	expect(splashed, "the drops splash where they land")
	for i in 200:
		scene._bend = 0.0
		scene._bend_v = 0.0
		scene._water57(0.05)
		if scene._solved.has(57):
			break
	expect(scene._solved.has(57), "kept in the stream, the tray comes all the way out")
	await seconds(2.5)
	expect(scene.mode == scene.Mode.WALK and scene.avatar.visible and scene.pieces.spell57_man.visible, "he stands up beside the 57 man, who stays")
	expect(scene.widen.amount == 0.0, "57: done, the vignette is back as drawn")

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

	# 52, 53: the seated man's arm moves his hand along a level line, leaning in only once it is straight
	scene.reset()
	await frames()
	var t = scene.tables
	for sp in [52, 53]:
		var r: Dictionary = t.rigs[sp]
		t.pose(r, r.T0.x)
		expect(r.eff.global_position.distance_to(r.T0) < 0.5 and r.u == 0.0, "%d: as drawn, his hand is where it is drawn" % sp)
		t.pose(r, r.T0.x - 20.0)
		expect(r.u == 0.0 and absf(r.eff.global_position.y - r.T0.y) < 0.5, "%d: bending in keeps his hand level, without leaning" % sp)
		t.pose(r, r.x_max)
		expect(r.u > 0.0 and absf(r.eff.global_position.y - r.T0.y) < 0.5 and absf(r.eff.global_position.x - r.x_max) < 0.5, "%d: stretched out, he leans in and his hand stays level" % sp)
	t.pose(t.rigs[53], t.rigs[53].x_min)
	expect(absf(scene.pieces.spell53_hand.global_rotation) < 0.001, "53: the cup stays level")
	var altar: Dictionary = scene.level.pieces.spell52_altar
	expect(t.rigs[52].loaves.y > altar.x + altar.w * 0.75, "52: his hand reaches most of the loaves")
	scene.reset()
	await frames()

	# 52: excrement his arm meets is kept off; on the loaves it costs a flesh sign
	t.start(52)
	await seconds(0.6)
	expect(scene.mode == scene.Mode.TABLE and t.g.playing and t.g.flesh == t.FLESH and scene.figures.spell52_seated_man.visible, "52: clicking the chair seats him and the game begins")
	expect(scene.widen.amount == 1.0 and scene.widen.cell == scene.widen.CELLS[52], "52: the vignette opens out")
	var r52: Dictionary = t.rigs[52]
	t.g.timer = 99.0
	t._drop()
	t.g.falling[-1].sprite.global_position = r52.eff.global_position
	t._fall(0.0)
	expect(t.g.blocked == 1, "52: excrement his hand meets is kept off the loaves")
	t.pose(r52, r52.x_min)
	t._drop()
	t.g.falling[-1].sprite.position = Vector2(r52.loaves.y, r52.loaves_top)
	t._fall(0.0)
	expect(t.g.flesh == t.FLESH - 1, "52: excrement on the loaves costs a flesh sign")
	# the last flesh sign: a was-sceptre is lost and the game begins again
	scene._carried.append(scene._sceptres[0])
	t.g.flesh = 1
	t._hurt()
	expect(scene._carried.is_empty() and not t.g.playing, "52: the last flesh sign loses the game and a sceptre")
	await seconds(2.0)
	expect(t.g.playing and t.g.flesh == t.FLESH and t.g.blocked == 0, "52: then the game begins again")
	t.g.blocked = t.COVER_NEED - 1
	t._drop()
	t.g.falling[-1].sprite.global_position = r52.eff.global_position
	t.process(0.0)
	t.process(0.0)
	await seconds(2.0)
	expect(scene._solved.has(52) and scene.mode == scene.Mode.WALK and scene.figures.spell52_seated_man.visible, "52: enough kept off, he stands up; the seated man stays")

	# 53: a caught part flies to its place on the table; caught excrement costs a flesh sign
	t.start(53)
	await seconds(0.6)
	var r53: Dictionary = t.rigs[53]
	var cup: Sprite2D = scene.pieces.spell53_hand
	var in_cup := func(f: Dictionary) -> void:
		var half: Vector2 = f.sprite.texture.get_size() / 2.0
		f.sprite.global_position = cup.global_position + cup.texture.get_size() / 2.0 - Vector2(0.0, half.y)
	t.g.timer = 99.0
	t.g.missed = -100
	t._drop()
	var part: String = t.g.falling[-1].kind
	in_cup.call(t.g.falling[-1])
	t._fall(0.0)
	await seconds(0.6)
	expect(part == t.PARTS[0] and t.g.placed == [part] and scene.pieces[part].visible, "53: a caught loaf goes to its place on the table")
	t.g.missed = 100
	t._drop()
	in_cup.call(t.g.falling[-1])
	t._fall(0.0)
	expect(t.g.flesh == t.FLESH - 1 and t.g.placed.size() == 1, "53: caught excrement costs a flesh sign")
	t.g.missed = -100
	t._drop()
	t.g.missed = 0
	t.g.falling[-1].sprite.position.y = float(scene.level.ground) + 200.0
	t._fall(0.0)
	expect(t.g.missed == 1, "53: a part that drops past him makes excrement likelier")
	t.g.placed.assign(t.PARTS.slice(0, t.PARTS.size() - 1))
	t.g.missed = -100
	t._drop()
	in_cup.call(t.g.falling[-1])
	t.process(0.0)
	t.process(0.0)
	await seconds(2.0)
	expect(scene._solved.has(53) and scene.mode == scene.Mode.WALK and scene.pieces.spell53_whisp5.visible, "53: the table heaped, he stands up")
	expect(r53.hips.visible, "53: the seated man stays")

	# 47: claimed, a death brings him back to the pylon, where he takes back the sceptres he claimed with
	scene.reset()
	await frames()
	scene.gate_used = true
	scene._take_sceptres()
	var seat: Sprite2D = scene.pieces.spell47_seat
	var img := seat.texture.get_image()
	var ink := Vector2.ZERO
	for y in img.get_height():
		for x in img.get_width():
			if ink == Vector2.ZERO and img.get_pixel(x, y).a > 0.8:
				ink = seat.global_position + Vector2(x, y)
	expect(scene._pick(ink) == "#claim", "47: the seat sign can be clicked")
	scene._use("#claim", ink)
	await seconds(0.3)
	expect(scene.claimed and scene.pieces.spell47_ba.visible and scene.claim_count == 2, "47: claiming the dwelling brings the ba")
	expect(scene._imprints.filter(func(s): return s.visible).size() == 2 and scene._imprints[0].modulate.a < 0.5 and not scene._imprints_full, "47: two faint sceptre imprints stand out of the pylon")
	scene._carried.clear()
	scene._die("51", scene.avatar.position, -1)
	await seconds(4.0)
	expect(scene.mode == scene.Mode.WALK and scene.claimed and is_equal_approx(scene.avatar.position.x, (scene.IMPRINT_X[0] + scene.IMPRINT_X[1]) / 2.0), "47: dead, claimed: he comes back at the pylon")
	expect(scene._imprints_full and scene._imprints[0].modulate.a == 1.0, "47: the imprints are full ink")
	scene._take_back()
	expect(scene._carried.size() == 2 and scene._carried.all(func(o): return o.sprite.visible) and not scene._imprints_full, "47: he takes back the sceptres he claimed with")

	# 54–62: the raised hands start empty; a sail found at a spot is held up, then dragged onto a hand
	scene.reset()
	await frames()
	var b = scene.breaths
	expect(b.HANDS.all(func(k): return not scene.pieces[k].visible), "54–62: the seven raised hands are empty")
	var ink_of := func(s: Sprite2D) -> Vector2:
		var im := s.texture.get_image()
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.8:
					return s.global_position + Vector2(x, y)
		return Vector2.ZERO
	var spot: Vector2 = ink_of.call(scene.pieces.breath_loc1)
	expect(scene._pick(spot) == "#breath_loc1", "a hidden sail's spot can be clicked")
	scene._use("#breath_loc1", spot)
	scene._use("#breath_loc2", Vector2.ZERO)
	await frames()
	expect(b.carried.size() == 2 and scene._pick(spot) != "#breath_loc1", "clicked, the spot gives him a sail, once")
	expect(b.carried[1].sprite.global_position.y < b.carried[0].sprite.global_position.y, "his sails are held up, stacked")
	var hand: Sprite2D = scene.pieces.spell55_sail
	var front: MoveableObject = b.carried[1]
	var grab: Vector2 = front.sprite.global_position + front.sprite.texture.get_size() / 2.0
	b.start_drag(front, grab)
	b.drag(Vector2(9999.0, 0.0))
	b.drop()
	await frames()
	expect(b.carried.size() == 2 and front.state == MoveableObject.State.WORN, "dropped away from a hand, the sail goes back to him")
	grab = front.sprite.global_position + front.sprite.texture.get_size() / 2.0
	b.start_drag(front, grab)
	b.drag(hand.global_position + hand.texture.get_size() / 2.0)
	b.drop()
	await seconds(0.5)
	expect(b.filled.has("spell55_sail") and hand.visible and b.carried.size() == 1, "dropped onto an empty raised hand, the sail fills it as drawn")
	scene.reset()
	await frames()
	expect(b.carried.is_empty() and b.taken.is_empty() and not hand.visible, "starting over, the sails are hidden again")

	# 45: rocked too wide, the mummy falls and its head comes off; he is back at the door
	scene.reset()
	await frames()
	scene._take_sceptres()
	walk(scene, scene.LINE_44_45 + scene.HALF)
	scene._enter_gate()
	scene.avatar.set_process(true)
	await until_mode(scene, scene.Mode.MUMMY)
	scene._swing = scene.MUMMY_FALL
	await frames(2)
	expect(scene.mode == scene.Mode.SCENE, "45: past the fall angle it falls")
	await seconds(2.0)
	expect(scene.pieces.spell45_mummy_head.position != scene._head_at or scene.mode == scene.Mode.WALK, "45: its head comes off")
	await until_mode(scene, scene.Mode.WALK)
	expect(scene.widen.amount == 0.0, "45: fallen, the vignette is back as drawn")
	expect(not scene.gate_used and scene._look == "44" and scene._carried.size() == 2 and scene.get_node("Figures/Spell44/DoorDark").visible, "45: fallen, he is back at the black door with the sceptres left")
	expect(scene.get_node("Figures/Spell45/Mummy").rotation == 0.0 and scene.pieces.spell45_mummy_head.position == scene._head_at, "45: the mummy stands as drawn again")
	# with no sceptre left once inside, the fall kills him
	scene._carried.pop_back().sprite.visible = false
	scene._enter_gate()
	await until_mode(scene, scene.Mode.MUMMY)
	scene._swing = scene.MUMMY_FALL
	await until_mode(scene, scene.Mode.WALK)
	expect(not scene.gate_used and scene._look == "43" and scene.avatar.position == scene._start, "45: fallen with no sceptre left, the level begins again")
	expect(scene.pieces.spell45_mummy_body.material == null and scene.pieces.spell45_mummy_head.position == scene._head_at, "45: starting over, the mummy is whole")
	scene.avatar.set_process(false)

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


func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.global_position = at
	e.position = at
	return e
