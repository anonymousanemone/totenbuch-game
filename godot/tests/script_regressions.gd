## Run with: godot --headless --path godot --script res://tests/script_regressions.gd
extends SceneTree

const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const DESCRIPTIONS := preload("res://scripts/descriptions.gd")
const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		_failures.append(description)


func _run() -> void:
	_test_scroll_text_opacity()
	_test_camera_bounds()
	_test_figure_mask()
	_test_procession_hitboxes()
	_test_procession_scene_pieces()
	_test_dangers_scene_actors()
	_test_dangers_inventory()
	_test_donkey_hover()
	_test_hover_glow()
	print("REGRESSIONS ", "OK" if _failures.is_empty() else "FAILED")
	quit(0 if _failures.is_empty() else 1)


func _test_scroll_text_opacity() -> void:
	for key in ["procession", "dangers", "cosmos"]:
		var scene = load("res://scenes/%s.tscn" % key).instantiate()
		var strip: Sprite2D = scene.get_node("Strip")
		_expect(strip.material == null and strip.modulate.a == 1.0 and strip.self_modulate.a == 1.0,
			key + " displays lower scroll text without an opacity effect")
		var image := strip.texture.get_image()
		if image.is_compressed(): image.decompress()
		var full_ink := true
		for row in [600, 700, 800, 900, 980]:
			var maximum := 0.0
			for x in image.get_width():
				maximum = maxf(maximum, image.get_pixel(x, row).a)
			full_ink = full_ink and maximum == 1.0
		_expect(full_ink, key + " retains full-strength text ink through the bottom of the imported texture")
		scene.free()


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


# Scene shapes are authored by hand. On mismatch, report both values and investigate scene
# edits versus exporter changes. Never recalculate shapes or synchronize either file here.
func _test_procession_hitboxes() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/procession/level.json"))
	var json_boxes := {}
	for entry in data.hotspots:
		json_boxes[entry.id] = entry
	for id in data.slots:
		json_boxes["GooseBearerHit" if id == "arms" else id] = data.slots[id]
	var scene = load("res://scenes/procession.tscn").instantiate()
	var count := 0
	for area in scene.find_children("*", "Area2D", true, false):
		if not area.get_parent() is Sprite2D:
			continue
		count += 1
		var sprite: Sprite2D = area.get_parent()
		var actual := DESCRIPTIONS.region_bounds(area)
		var id: String = area.get_meta("registry_id", area.get_meta("interaction_id", ""))
		var stored: Dictionary = json_boxes.get(id, {})
		var measured := {"x": actual.position.x, "y": actual.position.y, "w": actual.size.x, "h": actual.size.y}
		var aligned := measured.keys().all(func(key): return stored.has(key) and absf(float(stored[key]) - measured[key]) < 0.001)
		_expect(aligned, "JSON and scene nodes are aligned: " + id if aligned else
			"JSON and scene nodes are not aligned: %s; JSON=%s; scene=%s. Report and investigate; do not auto-fix." % [id, stored, measured])
		if not aligned:
			print("HITBOX_MISMATCH ", JSON.stringify({"id": id, "json": stored, "scene": measured}))
			print("Investigate manual shape/parent-transform edits and art re-exports; the test must not change either source.")
		var shape: CollisionShape2D = area.get_node("Shape")
		_expect(not shape.disabled and actual.size.x > 0.0 and actual.size.y > 0.0
			and actual.position.is_finite() and actual.size.is_finite(),
			"manually authored figure box is enabled and has valid bounds: " + id)
	_expect(count == 39, "all 30 describable figures, eight bearers and the goose-bearer own saved boxes")
	scene.free()
	var image := Image.create(20, 15, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(3, 4, 6, 5), Color.BLACK)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.offset = Vector2(2, 1)
	sprite.position = Vector2(100, 200)
	sprite.scale = Vector2(2, 3)
	_expect(DESCRIPTIONS.sprite_bounds(sprite).is_equal_approx(Rect2(110, 215, 12, 15)),
		"runtime bounds exclude transparent padding and respect sprite offset and scale")
	sprite.flip_h = true
	_expect(DESCRIPTIONS.sprite_bounds(sprite).size == Vector2(12, 15),
		"flipping a sprite preserves the tight hitbox size")
	sprite.free()


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
	for id in data.sprites:   # the forearms are drawn in the water priest's and the driver's sheets
		unique = unique and (id in ["avatar", "water_arm", "haul_whip"] or nodes.has(id))
	_expect(unique, "Procession scene contains every extracted piece with unique stable IDs")
	var standards := true
	for i in range(1, 9):
		var id := "emb_e%d" % i
		standards = standards and nodes[id].visible and nodes[id].position == Vector2(data.sprites[id].x, data.sprites[id].y)
	_expect(standards and nodes.calf.visible, "editor shows the correct standards and calf")
	_expect(nodes.calf.scale.x < 0.0 and nodes.plumes.position == Vector2(data.bulls.wrong.x, data.bulls.wrong.y)
		and nodes.plumes_place.position == Vector2(data.bulls.right.x, data.bulls.right.y) and nodes.plumed_ox.visible,
		"editor shows the three bulls as you find them: the calf facing the sacrifice, the plumes on it, their place on the plumed ox marked")
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
	_expect(nodes.water_priest_arm.get_parent() == nodes.water_priest and nodes.water_priest_arm.rotation == 0.0
		and nodes.haul_driver_arm.get_parent() == nodes.haul_driver_art and nodes.haul_driver_arm.rotation == 0.0,
		"editor shows the water priest and the ox-driver with their arms on them as drawn")
	_expect(nodes.water_stream.visible and nodes.stela_imprint.visible
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
	_expect(scene.bulls.calf_sprite() == nodes.calf and nodes.calf.position.x == scene.bulls.calf_sprite().position.x
		and scene.offerings.pieces.t03.rect.position == nodes.t03.position,
		"runtime reuses authored pieces and reads moved calf and offering positions")
	_expect(scene.haul._nodes.haul_sledge == nodes.haul_sledge and scene.water.priest_sprite() == nodes.water_priest
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
	var image: Image = scene.get_node("Avatar/Sprite").texture.get_image()
	var ink_opacity := 0.0
	for y in image.get_height():
		for x in image.get_width():
			ink_opacity = maxf(ink_opacity, image.get_pixel(x, y).a)
	_expect(ink_opacity == 1.0, "Dangers avatar retains fully opaque ink instead of a faded export")
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
	var cam: Camera2D = scene.get_node("Camera")
	_expect(absf(cam.position.x - scene.get_node("Avatar").position.x) < 1000.0 and cam.zoom.x < 1.0,
		"the dangers camera is authored where the level starts")
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
	var drawn: bool = ids.ankh38.visible and ids.sail38.visible
	for id in sheet_data.bearers:
		var actor = ids[id]
		var picture: Sprite2D = actor if actor is Sprite2D else actor.get_node("sprite")
		var frame: AtlasTexture = picture.texture
		drawn = drawn and actor.visible and frame.region.position == Vector2(sheet_data.rest * sheet_data.cell[0], sheet_data.bearers[id].row * sheet_data.cell[1])
	_expect(drawn, "editor shows the ankh and the sail held out, and all spear-bearers in their drawn poses")
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
	_expect(hidden and scene.actors.ankh38.visible and scene.actors.sail38.visible, "startup hides fight-only actors while retaining the ankh and the sail")
	moved.position += Vector2(20, 10)
	scene.reset()
	_expect(moved.position == home, "reset returns actors to their authored starting positions")
	scene.free()


func _test_dangers_inventory() -> void:
	for item in ["ankh38", "sail38"]:
		var scene = load("res://scenes/dangers.tscn").instantiate()
		root.add_child(scene)
		scene.hud.dismiss_intro()
		scene._instant = true
		var encounter: Dictionary = scene.ENCOUNTERS.filter(func(e): return e.id == "e38")[0]
		var other := "sail38" if item == "ankh38" else "ankh38"
		var sign: Sprite2D = scene.actors[item]
		var home: Vector2 = sign.position
		var other_home: Vector2 = scene.actors[other].position
		scene.take(encounter, item)
		scene.avatar.sprite.flip_h = false
		scene.avatar.sprite.position.y = -3.0
		scene._process(0.0)
		var pose := Vector2(-38, -233) if item == "ankh38" else Vector2(-35, -236)
		_expect(sign.visible and sign.global_position.is_equal_approx(scene.avatar.global_position + pose + Vector2(0, -3)), item + " is worn at the reference pose and follows the walking bob")
		_expect(scene.actors[other].visible and scene.actors[other].position == other_home, "the unchosen sign stays in the giver's hand")
		scene.avatar.position.x -= 60.0
		scene.avatar.sprite.flip_h = true
		scene._process(0.0)
		_expect(sign.global_position.is_equal_approx(scene.avatar.global_position + Vector2(-pose.x, pose.y - 3)) and sign.global_transform.determinant() < 0.0, item + " travels and mirrors with the player")
		scene.take(encounter, other)
		_expect(scene.items == [item], "carrying a sign does not allow taking the other one")
		scene.start_fight(scene.ENCOUNTERS[0])
		scene._process(0.0)
		_expect(not sign.visible, item + " hides with the player during combat")
		scene.leave_fight()
		scene._process(0.0)
		_expect(sign.visible and scene.items == [item], item + " returns to the player after leaving combat")
		scene.reset()
		_expect(scene.items.is_empty() and sign.visible and sign.position == home and sign.scale == Vector2.ONE and sign.rotation == 0.0 and sign.z_index == 0, item + " returns to its original pose on restart")
		scene.free()


## A real click opens the fight before subsequent mouse motion asks for hover targets.
func _test_donkey_hover() -> void:
	var scene = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(scene)
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.hud.dismiss_intro()
	var encounter: Dictionary = scene.ENCOUNTERS.filter(func(e): return e.id == "e40")[0]
	var sheaf: Dictionary = scene.ENCOUNTERS.filter(func(e): return e.id == "e41")[0]
	scene.gate = {}   # the road open past spell 38
	var between := Rect2(scene.column.position, (scene.column.get_node("papyrus") as ColorRect).size)
	_expect(scene.column.visible and scene.column.z_index > scene.avatar.z_index
		and between.position.x >= scene.span(sheaf).y and between.end.x <= scene.span(encounter).x + 1.0,
		"walking from spell 40 to 41, he passes behind the column of signs between them")
	_expect(scene._hover_at(scene.actor_rect(encounter.donkey).get_center()) == [encounter.foe, encounter.donkey, encounter.tail],
		"on the scroll the donkey glows (and takes the click) with the snake on its back")
	_expect(scene._hover_at(scene.actor_rect(sheaf.bundle).get_center()) == [sheaf.foe, sheaf.bundle],
		"on the scroll the sheaf glows (and takes the click) with its snake")
	scene.start_fight(encounter)
	_expect(not scene._instant and not scene.fight.has("foe"),
		"donkey hover regression uses the normal encounter state")
	_expect(scene._targets() == [encounter.foe], "donkey hover reads the snake from encounter data")
	scene._process(0.0)
	_expect(not scene.column.visible, "the column is not drawn over an open fight")
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
