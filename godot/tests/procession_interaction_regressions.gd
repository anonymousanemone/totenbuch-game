## Exploration approach, offering clues/snapping, standards drag and map availability.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func expect(value: bool, label: String) -> void:
	print(("PASS " if value else "FAIL ") + label)
	if not value:
		failures.append(label)

func arrive(level: Node) -> void:
	if level.avatar._target != null:
		level.avatar.position.x = level.avatar._target
		level.avatar._process(0.0)

func _run() -> void:
	var level = load("res://scenes/procession.tscn").instantiate()
	root.add_child(level)
	level.hud.dismiss_intro()
	level.set_process(false)
	level.avatar.set_process(false)
	# Authored boxes may overlap and need not equal the artwork's alpha bounds.
	# Verify each subject still has a clickable area under the real picking priorities.
	for region_id in level._inspection_regions:
		if str(region_id).begins_with("caption_") or (region_id == "hauler" and not level.haul.hauler_shown()):
			continue
		var box: Rect2 = level._descriptions.region_bounds(level._inspection_regions[region_id])
		var reachable := false
		for y in 21:
			for x in 21:
				var pick: Dictionary = level._pick(box.position + box.size * Vector2((x + 0.5) / 21.0, (y + 0.5) / 21.0))
				if pick.get("spot", {}).get("id", "") == region_id or (region_id == "priest_with_jar" and pick.get("type") == "water"):
					reachable = true
					break
			if reachable: break
		expect(reachable, "edited hitbox leaves the subject clickable: " + region_id)
	var subject := Rect2(200, 100, 80, 100)
	for sample in [[100.0, 200.0], [400.0, 280.0], [230.0, 250.0]]:
		level.avatar.position.x = sample[0]
		expect(level._reach(subject, Vector2(250, 150)) == sample[1], "approach uses nearest edge or clicked position")
	level.avatar.position.x = 230
	expect(level._reach(subject, Vector2(500, 150)) == 280, "approach stays within the subject bounds")
	var mummy: Dictionary = level.hotspots.filter(func(h): return h.id == "anubis_and_the_mummy")[0]
	level._click_world(mummy.rect.get_center())
	expect(level.avatar.is_walking() and not level.water.active, "mummy click approaches without entering the water game")
	arrive(level)
	expect(not level.water.active and level.hud._text.contains("needs the right tool"), "mummy inspection explains the unopened mouth")
	var woman: Dictionary = level.hotspots.filter(func(h): return h.id == "kneeling_woman")[0]
	level._click_world(woman.rect.get_center())
	arrive(level)
	expect(not level.water.active and level.hud._text == level._descriptions.text("kneeling_woman"), "kneeling woman is inspected without entering water")
	var priest: Dictionary = level.hotspots.filter(func(h): return h.id == "priest_with_jar")[0]
	level._click_world(priest.rect.get_center())
	arrive(level)
	expect(level.water.active, "jar priest starts the water game")
	level.leave_water()
	level.avatar.position.x = 5000
	level.act_mouth("adze")
	expect(level.avatar.is_walking() and level.mouth.carrying() == "", "adze is picked up only after approaching")
	arrive(level)
	expect(level.mouth.carrying() == "adze", "arrival picks up the adze")
	level.put_back()
	expect(level._descriptions.entries.offering_stand.name == "Low table"
		and level._descriptions.text("offering_stand") == "A small stand with two rods, a hooked adze, and a foreleg laid on it.", "low table uses the requested name and description")
	expect(level._descriptions.text("priest_with_arm_censer").contains("purifying the sacred implements"), "censer priest explains the purification ritual")
	var hints_before_recital: Dictionary = level._hints._steps.duplicate()
	level._click_world(level._lector.rect.get_center())
	arrive(level)
	expect(level.hud._text == level._descriptions.text("lector_with_plumes") + " He speaks to you.", "plumed lector click shows default description with speaking cue at the bottom")
	expect(level._recital.get_child_count() == 8, "plumed lector still recites all eight standards")
	expect(level._recital.get_children().all(func(glyph): return Color(glyph.modulate, 1.0).is_equal_approx(UI.INK_TINT)), "plumed lector's spoken signs use heka red")
	expect(level.journal.has("lector_with_plumes"), "plumed lector click records his default description")
	expect(level._hints._steps == hints_before_recital, "plumed lector clue does not advance Hint-button hints")
	level.enter_table(true)
	arrive(level)
	expect(level.in_table and level.hud._text == level.PUZZLES.text("procession.offerings", "instructions")
		and level.offerings.speaking() == "", "first priest click keeps instructions visible before offering clues")
	level.enter_table(true)
	expect(level.hud._text == level.PUZZLES.text("procession.offerings", "feedback", "speaking")
		and level.offerings.speaking() != "", "clicking the priest again shows the offering clue after instructions")
	var offerings = level.offerings
	var starts_over_table := true
	for body in offerings._bodies.get_children():
		var piece_id: String = body.get_meta("id")
		if piece_id != "goose" and offerings.pieces[piece_id].kind != "loose":
			continue
		starts_over_table = starts_over_table and body.position.x >= level.level.table.floor[0] and body.position.x <= level.level.table.floor[1]
	expect(starts_over_table, "loose offerings start over the table within its original bounds")
	expect(offerings.floor_x.y >= offerings.bearer_rect.end.x, "offering physics still extends to the goose-bearer")
	for restored_id in ["t04", "t05", "t21"]:
		var drawing: Sprite2D = offerings.objects[restored_id].sprite
		var source: Dictionary = level.level.table.pieces[restored_id]
		expect(drawing.offset == Vector2.ZERO and offerings.pieces[restored_id].rect.position == Vector2(source.x, source.y), "restored offering artwork aligns with original snap target: " + restored_id)
	var second: Dictionary = level.hotspots.filter(func(h): return h.id == "second_offering_table")[0]
	var second_clickable := false
	for y in 10:
		for x in 10:
			if level._pick(second.rect.position + second.rect.size * Vector2((x + 0.5) / 10, (y + 0.5) / 10)).get("spot", {}).get("id") == second.id:
				second_clickable = true
	expect(second_clickable, "second offering table is clickable")
	level.record(second)
	expect(level.hud._text == "Another large pile of offerings, with more architectural integrity.", "second offering table has its own description")
	var id: String = offerings.speaking()
	var imprint: Sprite2D = offerings._placement_imprint
	expect(imprint.visible and imprint.position == offerings.pieces[id].rect.get_center()
		and imprint.texture == offerings._tex[id], "priest clue shows the same piece at its destination")
	offerings._speak_tween.custom_step(offerings.SPEAK_FADE_IN)
	expect(imprint.modulate.is_equal_approx(UI.PREVIEW) and offerings._speak.modulate.a == 1.0, "piece clue and faint imprint fade in together")
	expect(offerings._speak.modulate.is_equal_approx(UI.INK_TINT), "lector's spoken offering uses heka red after fading in")
	offerings._speak_tween.custom_step(offerings.SPEAK_HOLD + offerings.SPEAK_FADE_OUT + 0.1)
	expect(not imprint.visible and not offerings._speak.visible, "piece clue and imprint fade out together")
	level.enter_table(true)
	expect(offerings.speaking() != "" and level.hud._text == level.PUZZLES.text("procession.offerings", "feedback", "speaking"), "priest can repeat instructions and clue while already at the table")
	var high := ""
	for candidate in offerings.pieces:
		if offerings.pieces[candidate].kind == "loose" and not offerings.can_place(candidate):
			high = candidate
			break
	offerings.take(high)
	expect(not offerings.snap_held(offerings.pieces[high].rect.get_center()) and offerings.holding() == high, "unsupported pieces do not snap while held")
	offerings.put_back()
	id = offerings.stackable()[0]
	if offerings.bearer == id:
		offerings.bearer_act()
	else:
		offerings.take(id)
	expect(not offerings.snap_held(offerings.pieces[id].rect.get_center() + Vector2(100, 0)), "pieces do not snap outside the placement radius")
	expect(offerings.snap_held(offerings.pieces[id].rect.get_center()) and offerings.placed.has(id)
		and offerings.holding() == "", "supported pieces snap and leave the hand before mouse release")
	var loaf: String = offerings.bearer
	level._describe_bearer()
	expect(offerings.bearer == loaf and offerings.holding() == "", "whole bearer inspection leaves his bread in his arms")
	var bread_image: Image = offerings._bearer_sprite.texture.get_image()
	if bread_image.is_compressed():
		bread_image.decompress()
	var bread_point := Vector2.ZERO
	for y in bread_image.get_height():
		for x in bread_image.get_width():
			if bread_image.get_pixel(x, y).a > 0.5:
				bread_point = offerings._bearer_sprite.to_global(offerings._bearer_sprite.get_rect().position + Vector2(x, y))
				break
		if bread_point != Vector2.ZERO:
			break
	expect(level._pick(bread_point).get("type") == "bearer_loaf", "held bread has a separate ink hotspot")
	expect(level._glow_targets(level._pick(bread_point)) == [offerings._bearer_sprite], "bread hover highlights only the bread")
	level._act_bearer()
	level._describe_bearer()
	expect(level.hud._text == "He stares forlornly at his empty hands.", "empty bearer keeps forlorn description")
	level._table_drop(offerings.bearer_rect.get_center())
	expect(offerings.bearer == "" and offerings.sprite_of(loaf) != null, "bread falls through instead of returning to bearer")
	level.hud.say("Scribe", "Keep this description.")
	offerings.take("goose")
	level._drop_offering(Vector2(offerings.floor_x.x + 100, offerings.ground - 80))
	expect(level.hud._text == "Keep this description.", "dropping the goose adds no message")
	level.solved.t3 = true
	level.record(level._reader)
	expect(level.hud._text == level._descriptions.text("lector_priest"), "completed table priest uses his default description")
	level.record(level._table)
	expect(level.hud._text == level.PUZZLES.text("procession.offerings", "success"), "completed table click reports it is whole again")
	level.solved.t3 = false
	level.leave_table()
	level.in_standards = true
	var original: Sprite2D = level._pieces[level.slot.pole1]
	var original_scale: Vector2 = original.scale
	var pointer := original.position + Vector2(8, 12)
	level._standard_grab = pointer - original.position
	level.act_slot("pole1")
	var held: Sprite2D = level._pieces[level.held]
	expect(held.visible and held.scale == original_scale and held.z_index == 10,
		"dragged standard remains a full-size scene sprite")
	level._process(0.0)
	expect(held.position + level._standard_grab == level.get_global_mouse_position()
		and not level.hud._held.visible, "standard keeps its grab point at the pointer with no smaller HUD copy")
	level._drop_standard(Vector2(-100, -100))
	expect(level.held == "" and level.slot.pole1 != "", "releasing outside a pole returns the standard")
	level.leave_standards()
	var bull_center: float = (level.bulls.view().x + level.bulls.view().y) / 2.0
	var sacrifice: Dictionary = level.hotspots.filter(func(h): return h.id == "sacrifice")[0]
	for side in [level.bulls.view().x, level.bulls.view().y]:
		level.avatar.position.x = side
		var destination: float = level.bulls.stand_x(side)
		level.enter_bulls(sacrifice)
		arrive(level)
		expect(level.bulls.active and is_equal_approx(level.avatar.position.x, destination), "player stands at the nearer end of the bull scene")
		var half: float = level.sprite_rects.avatar.size.x / 2.0
		var ox: Sprite2D = level.bulls.ox_sprite()
		expect(destination + half < sacrifice.rect.position.x or destination - half > ox.position.x + ox.offset.x + ox.texture.get_width(), "player stands outside the animals on either side")
		level._update_camera(1.0)
		expect(is_equal_approx(level.camera.position.x, bull_center), "bull camera stays centered from either end")
		level.leave_bulls()
	level.bulls.enter()
	var hints_before: Dictionary = level._hints._steps.duplicate()
	var expected := {
		"sacrifice": "The Apis bull should never be slaughtered. (Not even Cambyses did it, despite what Herodotus claimed.)",
		"calf": "The young calf shakes at the sight of the sacrifice.",
		"plumed_ox": "A bull walking towards the sacrifice."
	}
	for animal_id in expected:
		var box: Rect2 = level._descriptions.region_bounds(level._inspection_regions[animal_id])
		level._bulls_press(box.get_center())
		expect(level.bulls.active and level.hud._text == expected[animal_id], "animal click shows its unresolved description during the game: " + animal_id)
		expect(level.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG_MINIGAME,
			"animal clue uses the green minigame tag: " + animal_id)
		expect(level.hud._journal_entries["procession/" + animal_id].text == expected[animal_id],
			"animal clue records the observed description in the journal: " + animal_id)
		if animal_id == "calf":
			expect(level.bulls.held == "calf", "clicking the calf still takes hold for dragging")
			level.bulls.release(box.get_center())
	var plume_point: Vector2 = level._descriptions.sprite_bounds(level.bulls.plumes_sprite()).get_center()
	level._bulls_press(plume_point)
	expect(level.bulls.held == "plumes" and level.hud._text == expected.sacrifice,
		"the slaughtered bull's plumes retain dragging and show its clue")
	level.bulls.release(Vector2.INF)
	expect(level._hints._steps == hints_before, "animal description clues do not consume Hint-button hints")
	level.free()
	var menu = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	var scroll = root.get_node("Scroll")
	for entry in scroll.SCENES:
		var card: Control = menu._cards.find_child(entry.key, true, false)
		var picture: Control = card.get_node("Frame").get_child(0)
		expect((picture.modulate.a == 1.0) == scroll.is_built(entry.key), "map ink follows playable scene availability: " + entry.key)
		menu._choose(entry.key)
		expect(menu._chosen_go.disabled == not scroll.is_built(entry.key), "playable map scenes are unlocked: " + entry.key)
	var saved_progress: Array[String] = scroll.restored.duplicate()
	for sample in [
		{"finished": [], "current": "procession"},
		{"finished": ["dangers"], "current": "procession"},
		{"finished": ["procession"], "current": "cosmos"},
		{"finished": ["procession", "cosmos"], "current": "dangers"},
		{"finished": ["procession", "cosmos", "dangers"], "current": "survival"},
		{"finished": ["procession", "cosmos", "dangers", "survival"], "current": "gates"},
		{"finished": ["procession", "cosmos", "dangers", "survival", "gates"], "current": ""}
	]:
		scroll.restored.assign(sample.finished)
		menu._refresh_map()
		expect(scroll.current() == sample.current, "map progress selects the first unfinished playable chapter: " + str(sample.finished))
		expect(menu._play_key() == (sample.current if sample.current != "" else "procession"),
			"Play agrees with saved progress, with replay available after completion")
		var markers: Array[String] = []
		var unlocked := true
		for entry in scroll.SCENES:
			var card: Control = menu._cards.find_child(entry.key, true, false)
			if card.get_node("Frame/Picture/Current").visible:
				markers.append(entry.key)
			menu._choose(entry.key)
			unlocked = unlocked and menu._chosen_go.disabled == not scroll.is_built(entry.key)
		expect(unlocked, "all implemented chapters stay unlocked regardless of progress")
		expect(markers == ([sample.current] if sample.current != "" else []),
			"You are here marks only unfinished progress, and disappears once everything is complete")
	scroll.restored.assign(saved_progress)
	menu.free()
	print("PROCESSION INTERACTIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
