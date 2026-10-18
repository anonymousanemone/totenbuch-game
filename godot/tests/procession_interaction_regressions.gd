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
	level.enter_table(true)
	arrive(level)
	expect(level.in_table and level.hud._text == level.PUZZLES.text("procession.offerings", "instructions")
		and level.offerings.speaking() != "", "clicking the table priest opens instructions and the current piece clue")
	var offerings = level.offerings
	var id: String = offerings.speaking()
	var imprint: Sprite2D = offerings._placement_imprint
	expect(imprint.visible and imprint.position == offerings.pieces[id].rect.get_center()
		and imprint.texture == offerings._tex[id], "priest clue shows the same piece at its destination")
	offerings._speak_tween.custom_step(offerings.SPEAK_FADE_IN)
	expect(imprint.modulate.is_equal_approx(UI.PREVIEW) and offerings._speak.modulate.a == 1.0, "piece clue and faint imprint fade in together")
	offerings._speak_tween.custom_step(offerings.SPEAK_HOLD + offerings.SPEAK_FADE_OUT + 0.1)
	expect(not imprint.visible and not offerings._speak.visible, "piece clue and imprint fade out together")
	level.enter_table(true)
	expect(offerings.speaking() != "" and level.hud._text == level.PUZZLES.text("procession.offerings", "instructions"), "priest can repeat instructions and clue while already at the table")
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
	level.bulls.enter()
	var hints_before: Dictionary = level._hints._steps.duplicate()
	var expected := {
		"sacrifice": "The Apis bull should never be slaughtered. (Not even Cambyses did it, despite what Herodotus claimed.)",
		"calf": "The young calf shakes at the sight of the sacrifice.",
		"plumed_ox": "A bull."
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
		var card: Control = menu._card(entry)
		var picture: Control = card.get_node("Frame").get_child(0)
		expect((picture.modulate.a == 1.0) == scroll.is_built(entry.key), "map ink follows playable scene availability: " + entry.key)
		menu._choose(entry.key)
		expect(menu._chosen_go.disabled == not scroll.is_built(entry.key), "playable map scenes are unlocked: " + entry.key)
		card.free()
	var saved_progress: Array[String] = scroll.restored.duplicate()
	for sample in [
		{"finished": [], "current": "procession"},
		{"finished": ["dangers"], "current": "procession"},
		{"finished": ["procession"], "current": "cosmos"},
		{"finished": ["procession", "cosmos"], "current": "dangers"},
		{"finished": ["procession", "cosmos", "dangers"], "current": ""}
	]:
		scroll.restored.assign(sample.finished)
		expect(scroll.current() == sample.current, "map progress selects the first unfinished playable chapter: " + str(sample.finished))
		expect(menu._play_key() == (sample.current if sample.current != "" else "procession"),
			"Play agrees with saved progress, with replay available after completion")
		var markers: Array[String] = []
		var unlocked := true
		for entry in scroll.SCENES:
			var card: Control = menu._card(entry)
			if card.find_children("*", "Label", true, false).any(func(label): return label.text == "You are here"):
				markers.append(entry.key)
			menu._choose(entry.key)
			unlocked = unlocked and menu._chosen_go.disabled == not scroll.is_built(entry.key)
			card.free()
		expect(unlocked, "all implemented chapters stay unlocked regardless of progress")
		expect(markers == ([sample.current] if sample.current != "" else []),
			"You are here marks only unfinished progress, and disappears once everything is complete")
	scroll.restored.assign(saved_progress)
	menu.free()
	print("PROCESSION INTERACTIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
