## Run with: godot --headless --path godot --script res://tests/script_regressions.gd
extends SceneTree

const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		_failures.append(description)


func _run() -> void:
	_test_camera_bounds()
	_test_figure_mask()
	_test_procession_scene_pieces()
	_test_dangers_scene_actors()
	_test_donkey_hover()
	_test_hover_glow()
	print("REGRESSIONS ", "OK" if _failures.is_empty() else "FAILED")
	quit(0 if _failures.is_empty() else 1)


func _test_camera_bounds() -> void:
	_expect(SCROLL_CAMERA.clamp_horizontal(-100.0, 800.0, 3000.0) == 400.0,
		"camera cannot reveal space before the scroll")
	_expect(SCROLL_CAMERA.clamp_horizontal(4000.0, 800.0, 3000.0) == 2600.0,
		"camera cannot reveal space after the scroll")
	_expect(SCROLL_CAMERA.clamp_horizontal(500.0, 4000.0, 3000.0) == 2000.0,
		"a viewport wider than the scroll keeps the original framing")
	_expect(SCROLL_CAMERA.smoothing(0.0) == 0.0 and SCROLL_CAMERA.smoothing(1.0) == 1.0,
		"camera pauses at zero delta and snaps during reset")
	var two_steps := 1.0 - pow(1.0 - SCROLL_CAMERA.smoothing(1.0 / 60.0), 2.0)
	_expect(is_equal_approx(two_steps, SCROLL_CAMERA.smoothing(1.0 / 30.0)),
		"camera smoothing gives the same result at different frame rates")
	_expect(SCROLL_CAMERA.fit_zoom(Vector2(1280, 720), 40.0, 200.0, 480.0, 1.0, 0.4, 2.4)
		== 470.0 / 480.0, "camera reserves space for both HUD bars")


func _test_figure_mask() -> void:
	var source := Image.create(21, 21, false, Image.FORMAT_RGBA8)
	# A closed ink outline encloses blank pixels; the exterior stays transparent.
	for pixel in range(5, 16):
		for point in [Vector2i(pixel, 5), Vector2i(pixel, 15), Vector2i(5, pixel), Vector2i(15, pixel)]:
			source.set_pixelv(point, Color(0, 0, 0, 1))
	var texture := ImageTexture.create_from_image(source)
	var result := FIGURE_MASK.create_texture(texture, 2).get_image()
	_expect(result.get_size() == Vector2i(25, 25), "figure mask preserves the requested padding")
	_expect(result.get_pixel(12, 12).g == 1.0 and result.get_pixel(12, 12).r == 0.0,
		"figure interior is filled without adding ink")
	_expect(result.get_pixel(7, 12).r == 1.0, "figure outline preserves its ink")
	_expect(result.get_pixel(0, 0).g == 0.0 and result.get_pixel(0, 0).r == 0.0,
		"figure exterior remains outside the fill")
	source.set_pixel(10, 5, Color.TRANSPARENT)
	var repaired := FIGURE_MASK.create_texture(ImageTexture.create_from_image(source), 2).get_image()
	_expect(repaired.get_pixel(12, 12).g == 1.0, "a small gap in the outline does not leak the fill")


## The editor arrangement intentionally mixes restored rites with hidden-piece starts.
func _test_procession_scene_pieces() -> void:
	var scene = load("res://scenes/procession.tscn").instantiate()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/procession/level.json"))
	var nodes := {}
	var unique := true
	for node in scene.get_node("pieces").find_children("*", "Node2D", true, false):
		if node.has_meta("piece_id"):
			var id: String = node.get_meta("piece_id")
			unique = unique and not nodes.has(id)
			nodes[id] = node
	for id in data.sprites:
		unique = unique and (id == "avatar" or nodes.has(id))
	_expect(unique, "Procession scene contains every extracted piece with unique stable IDs")
	var standards := true
	for i in range(1, 9):
		var id := "emb_e%d" % i
		standards = standards and nodes[id].visible and nodes[id].position == Vector2(data.sprites[id].x, data.sprites[id].y)
	_expect(standards and nodes.calf.visible, "editor shows the correct standards and calf")
	var table := true
	for id in data.table.pieces:
		var source: Dictionary = data.table.pieces[id]
		if source.kind == "loose":
			table = table and nodes[id].visible and nodes[id].position == Vector2(source.x, source.y)
	_expect(table and not nodes.t08.visible and nodes.held_loaf.visible and nodes.goose.visible,
		"editor arranges offerings on the table with the loaf held and goose on the floor")
	_expect(nodes.t25.position == Vector2(data.table.frond_rest.x, data.table.frond_rest.y)
		and nodes.frond_place.position == Vector2(data.table.pieces.t25.x, data.table.pieces.t25.y),
		"frond starts on the upper register with a separate table placement marker")
	_expect(nodes.jug_arm.rotation == 0.0 and nodes.water_stream.visible and nodes.stela_imprint.visible
		and nodes.kneeler.visible and nodes.mouth_words.visible,
		"editor displays restored water, stela imprint, kneeler and words above Ra")
	_expect(nodes.stand.position == Vector2(data.ending.hide.stand.x, data.ending.hide.stand.y) + nodes.stand.texture.get_size() / 2.0
		and nodes.sun.get_parent() == nodes.haul_sledge.get_child(0)
		and is_equal_approx(nodes.lotus.rotation_degrees, 90.0)
		and is_equal_approx(nodes.lotus.position.x, data.ending.hide.lotus.cx),
		"editor puts stand, sun and turned lotus in their hidden starting locations")
	var props := true
	for id in ["mouth_column", "mouth_spoon"]:
		props = props and nodes[id].visible and nodes[id].position == Vector2(data.sprites[id].x, data.sprites[id].y)
	_expect(props, "additional mouth props are visible at their exported source positions")
	var start: Vector2 = scene.get_node("Avatar").position
	_expect(start == Vector2(data.sprites.avatar.x + data.sprites.avatar.w / 2.0, data.ground)
		and absf(scene.get_node("Camera").position.x - start.x) < 1000.0,
		"avatar and camera are authored at the beginning of the scroll")
	nodes.calf.position.x += 12.0
	nodes.t03.position.x += 6.0
	nodes.sun.position.x += 5.0
	nodes.mouth_adze.position.x += 3.0
	var sun_home: Transform2D = nodes.sun.transform
	root.add_child(scene)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(scene._pieces.calf == nodes.calf and scene.sprite_rects.calf.position == nodes.calf.position
		and scene.offerings.pieces.t03.rect.position == nodes.t03.position,
		"runtime reuses authored pieces and reads moved calf and offering positions")
	_expect(scene.haul._nodes.haul_sledge == nodes.haul_sledge and scene.water.arm_sprite() == nodes.water_arm
		and scene.mouth._adze == nodes.mouth_adze and scene.ending._nodes.sun == nodes.sun,
		"all Procession puzzle components reuse their saved scene figures")
	_expect(not nodes.kneeler.visible and not nodes.stela_imprint.visible and not nodes.mouth_words.visible
		and scene.water.tilt == scene.water.START_TILT and scene.slot == scene.START,
		"startup restores the existing hidden figures, raised jug and shuffled standards")
	scene.ending._set_at_place("sun")
	scene.ending.reset()
	_expect(nodes.sun.transform == sun_home and nodes.sun.get_parent() == scene.haul.sprite_of("haul_sledge"),
		"ending reset restores the authored sun position on the moving sledge")
	scene.offerings._place("t03")
	_expect(nodes.t03.visible and scene.offerings.placed_sprites() == [nodes.t03],
		"restoring an offering reveals its saved sprite without duplicating table pieces")
	scene.offerings.reset()
	_expect(not nodes.t03.visible and scene.offerings.placed_sprites().is_empty(),
		"offering reset hides authored table pieces before scattering loose bodies")
	scene.free()


## Authored actors must be inspectable before _ready(), then retain scene placement in play.
func _test_dangers_scene_actors() -> void:
	var scene = load("res://scenes/dangers.tscn").instantiate()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dangers/level.json"))
	var sheet_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dangers/spearers.json"))
	var ids := {}
	var aligned := true
	for actor in scene.get_node("actors").find_children("*", "Node2D", true, false):
		if not actor.has_meta("actor_id"):
			continue
		var id: String = actor.get_meta("actor_id")
		aligned = aligned and not ids.has(id)
		ids[id] = actor
		var source: Dictionary = data.sprites[id.trim_suffix("_pole")] if id.ends_with("_pole") else data.sprites[id]
		aligned = aligned and actor.position.is_equal_approx(Vector2(source.x + source.w / 2.0, source.y + source.h))
	for id in data.sprites:
		aligned = aligned and (id == "avatar" or ids.has(id))
	_expect(aligned, "Dangers scene contains unique IDs and source-art placements for every actor")
	_expect(scene.get_node("actors/spell31_crocs/croc31a") == ids.c31a
		and scene.get_node("actors/spell31_crocs/spear_bearer") == ids.spear31,
		"actors have readable names and are organized beneath their spell")
	var simple := true
	for id in ids:
		if id in ["snake33", "snake35", "apep", "snake41"]:
			simple = simple and not ids[id] is Sprite2D and ids[id].has_node("sprite")
		else:
			simple = simple and ids[id] is Sprite2D and not ids[id].has_node("sprite")
	_expect(simple, "single-picture actors are Sprite2D nodes; multipart snakes retain their drawing child")
	var avatar_in_front := true
	for id in ids:
		avatar_in_front = avatar_in_front and scene.get_node("Avatar").z_index > ids[id].z_index
	_expect(avatar_in_front, "walking avatar draws above scene creatures so its papyrus fill occludes them")
	var drawn: bool = ids.breath38.visible
	for id in sheet_data.bearers:
		var actor = ids[id]
		var picture: Sprite2D = actor if actor is Sprite2D else actor.get_node("sprite")
		var frame: AtlasTexture = picture.texture
		drawn = drawn and actor.visible and frame.region.position == Vector2(sheet_data.rest * sheet_data.cell[0], sheet_data.bearers[id].row * sheet_data.cell[1])
	_expect(drawn, "editor shows held breath and all spear-bearers in their drawn poses")
	var moved = ids.c31a
	moved.position += Vector2(12, -3)
	var home: Vector2 = moved.position
	root.add_child(scene)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(scene.actors.c31a == moved and moved.get_meta("home") == home and scene.rects.c31a.get_center().x == home.x,
		"runtime reuses authored actors and derives homes and bounds from scene placement")
	var hidden := true
	for id in scene.actors:
		if id.begins_with("spear") or id.begins_with("sheaf41_"):
			hidden = hidden and not scene.actors[id].visible
	_expect(hidden and scene.actors.breath38.visible, "startup hides fight-only actors while retaining the held breath")
	moved.position += Vector2(20, 10)
	scene.reset()
	_expect(moved.position == home, "reset returns actors to their authored starting positions")
	scene.free()


## A real click opens the fight before subsequent mouse motion asks for hover targets.
func _test_donkey_hover() -> void:
	var scene = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(scene)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.hud.dismiss_intro()
	var encounter: Dictionary = scene.ENCOUNTERS.filter(func(e): return e.id == "e40")[0]
	scene.start_fight(encounter)
	_expect(not scene._instant and scene.fight.awaiting_start and not scene.fight.has("foe"),
		"donkey hover regression uses the normal encounter state before Space")
	_expect(scene._targets() == [encounter.foe], "donkey hover reads the snake from encounter data")
	_expect(scene._hover_at(scene.actor_rect(encounter.foe).get_center()) == [encounter.foe],
		"moving the pointer over the donkey snake after entry finds its hover target")
	scene._unhandled_input(InputEventMouseMotion.new())
	scene._croc_open(1.0)
	_expect(scene._hover_at(scene.actor_rect(encounter.foe).get_center()) == [encounter.foe],
		"donkey snake remains hoverable after the vignette opens")
	scene._unhandled_input(InputEventMouseMotion.new())
	scene.reset()
	scene.free()


func _test_hover_glow() -> void:
	var level = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(level)
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var expected_signs := []
	for words in level.level.get("heka", {}).values():
		expected_signs.append_array(words)
	_expect(level._all_heka() == expected_signs, "cached heka signs retain their scroll order")
	var actor: String = level.ENCOUNTERS[0].foes[0]
	level._glow(actor, true)
	var glow: Sprite2D = level.actors[actor].get_node("Glow")
	var fade: Tween = glow.get_meta("fade")
	fade.custom_step(0.2)
	_expect(glow.visible and is_equal_approx(glow.material.get_shader_parameter("strength"), 1.0),
		"hovered drawings finish fading into view")
	_expect(glow.offset == level.actors[actor].offset, "hover glow preserves the flattened sprite drawing offset")
	level._glow(actor, false)
	fade = glow.get_meta("fade")
	fade.custom_step(0.2)
	_expect(not glow.visible and is_zero_approx(glow.material.get_shader_parameter("strength")),
		"invisible glows stop drawing after their fade")
	level._glow(actor, true)
	fade = glow.get_meta("fade")
	fade.custom_step(0.05)
	level._glow(actor, false)
	var interrupted: Tween = glow.get_meta("fade")
	interrupted.custom_step(0.05)
	level._glow(actor, true)
	_expect(not interrupted.is_valid() and glow.visible, "re-entering cancels an unfinished fade out")
	fade = glow.get_meta("fade")
	fade.custom_step(0.2)
	_expect(glow.visible and is_equal_approx(glow.material.get_shader_parameter("strength"), 1.0),
		"rapid hover changes leave the drawing glowing")
	level.free()
