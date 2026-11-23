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

## A point on figure `h`'s drawing (clicks hit drawings, and a box's middle may be empty paper).
func on_figure(level: Node, h: Dictionary) -> Vector2:
	for y in 21:
		for x in 21:
			var point: Vector2 = h.rect.position + h.rect.size * Vector2((x + 0.5) / 21.0, (y + 0.5) / 21.0)
			if level._pick(point).get("spot", {}) == h:
				return point
	return h.rect.get_center()


## A point on the drawing that `finder` (a Callable taking a point) accepts, searched over `box`.
func on_drawing(box: Rect2, finder: Callable) -> Vector2:
	for y in 31:
		for x in 31:
			var point: Vector2 = box.position + box.size * Vector2((x + 0.5) / 31.0, (y + 0.5) / 31.0)
			if finder.call(point):
				return point
	return Vector2.INF


## Loose pieces glow alone; pieces locked into place belong to the whole table, and the goose locked in the
## bearer's arms to the goose-man: they glow and answer as the whole does.
func _locked_belong_to_whole() -> void:
	var level = load("res://scenes/procession.tscn").instantiate()
	root.add_child(level)
	level.hud.dismiss_intro()
	level.set_process(false)
	level.avatar.set_process(false)
	var offerings = level.offerings
	level.enter_table(true)
	arrive(level)
	var table_point: Vector2 = on_figure(level, level._table)
	var whole_in_table: Dictionary = level._table_pick(table_point)
	var whole_walking: Dictionary = level._pick(table_point)
	level._stack_table_but_frond()
	var frond := ""
	for id in offerings.pieces:
		if not offerings.placed.has(id):
			frond = id
	expect(frond != "" and offerings.pieces[frond].kind == "frond" and offerings.placed.size() == offerings.pieces.size() - 1,
		"table: every piece but the frond is locked in place")
	var locked: String = offerings.placed.keys()[0]
	var locked_point: Vector2 = on_drawing(level._descriptions.sprite_bounds(offerings.objects[locked].sprite), func(p): return offerings.placed_at(p) == locked)
	var frond_point: Vector2 = on_drawing(level._descriptions.sprite_bounds(offerings.sprite_of(frond)), func(p): return offerings.pick(p) == frond)
	expect(locked_point != Vector2.INF and frond_point != Vector2.INF, "table: a point on a locked piece and on the loose frond were found")
	# in the minigame, the table is not rebuilt: the whole table is not pointed at, so neither is a locked piece
	expect(whole_in_table.is_empty() and level._table_pick(locked_point).is_empty() and level._glow_targets(level._table_pick(locked_point)).is_empty(),
		"in the minigame a locked piece glows nothing, as the unfinished table does")
	var loose: Dictionary = level._table_pick(frond_point)
	expect(loose.get("type") == "piece" and level._glow_targets(loose) == [offerings.sprite_of(frond)], "in the minigame a loose piece glows alone")
	# the goose locked in the bearer's arms belongs to the goose-man, before the table is rebuilt too
	offerings.take("goose")
	level._act_bearer()
	expect(offerings.bearer == "goose", "table: the goose is locked in the bearer's arms")
	var goose_point: Vector2 = on_drawing(level._descriptions.sprite_bounds(offerings._bearer_sprite), func(p): return offerings.goose_at(p))
	var goose_man: Dictionary = level._table_pick(goose_point)
	expect(goose_point != Vector2.INF and goose_man.get("type") == "bearer"
		and level._glow_targets(goose_man) == [level._bearer_rect] + offerings.bearer_sprites(),
		"a locked goose glows the whole goose-man, drawing and goose")
	level.leave_table()
	# walking: the unfinished table glows as a whole, and a locked piece with it
	var walking_locked: Dictionary = level._pick(locked_point)
	expect(whole_walking.get("spot") == level._table and walking_locked.get("spot") == level._table
		and level._glow_targets(walking_locked) == level._glow_targets(whole_walking) and not level._glow_targets(walking_locked).is_empty(),
		"walking, a locked piece glows what the unfinished table glows")
	# rebuilt: the whole table glows with everything on it, whichever piece is pointed at
	level.enter_table(true)
	level._place_table_piece(frond)
	expect(level.solved.t3 and offerings.complete(), "table: placing the frond rebuilds the table")
	var whole: Array = level._glow_targets(level._table_pick(table_point))
	expect(whole.size() == offerings.pieces.size() + 1, "the rebuilt table glows with every piece on it")
	var all_whole := true
	for id in offerings.placed:
		var point: Vector2 = on_drawing(level._descriptions.sprite_bounds(offerings.objects[id].sprite), func(p): return offerings.placed_at(p) == id)
		all_whole = all_whole and point != Vector2.INF and level._glow_targets(level._pick(point)) == whole
	expect(all_whole, "every locked piece of the rebuilt table glows the whole table")
	# clicks follow the whole too
	level.leave_table()
	level.hud.say("Scribe", "Nothing yet.")
	level._click_world(locked_point)
	arrive(level)
	expect(level.hud._text == level.PUZZLES.text("procession.offerings", "success"), "clicking a locked piece of the rebuilt table reads as the table")
	level.hud.say("Scribe", "Nothing yet.")
	level._click_world(goose_point)
	arrive(level)
	expect(level.hud._text == level.PUZZLES.text("procession.goose", "feedback", "success_carrying"), "clicking the locked goose reads as the goose-man")
	level.free()

func _run() -> void:
	var level = load("res://scenes/procession.tscn").instantiate()
	root.add_child(level)
	level.hud.dismiss_intro()
	level.set_process(false)
	level.avatar.set_process(false)
	# Figures may overlap; verify each subject still has a clickable area under the real picking priorities.
	for region_id in level.hotspots.map(func(h): return h.id) + level.CAPTIONS.map(func(c): return c.id):
		if str(region_id).begins_with("caption_") or (region_id == "hauler" and not level.haul.hauler_shown()):
			continue
		var box: Rect2 = level._descriptions.box(region_id) if str(region_id).begins_with("caption_") else level._hot_rect(region_id)
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
	for sample in [[100.0, 200.0], [400.0, 280.0], [230.0, 230.0]]:
		level.avatar.position.x = sample[0]
		expect(level.avatar.reach(subject) == sample[1], "approach walks to the nearest edge, or stays put in front of it")
	var mummy: Dictionary = level.hotspots.filter(func(h): return h.id == "anubis_and_the_mummy")[0]
	level._click_world(on_figure(level, mummy))
	expect(level.avatar.is_walking() and not level.water.active, "mummy click approaches without entering the water game")
	arrive(level)
	expect(not level.water.active and level.hud._text == level._descriptions.text("anubis_and_the_mummy", "unopened"), "mummy inspection explains the unopened mouth")
	var woman: Dictionary = level.hotspots.filter(func(h): return h.id == "kneeling_woman")[0]
	level._click_world(on_figure(level, woman))
	arrive(level)
	expect(not level.water.active and level.hud._text == level._descriptions.text("kneeling_woman"), "kneeling woman is inspected without entering water")
	var priest: Dictionary = level.hotspots.filter(func(h): return h.id == "priest_with_jar")[0]
	level._click_world(on_figure(level, priest))
	arrive(level)
	expect(level.water.active, "jar priest starts the water game")
	level.leave_water()
	level.avatar.position.x = 5000
	level.act_mouth("adze")
	expect(level.avatar.is_walking() and level.mouth.carrying() == "", "adze is picked up only after approaching")
	arrive(level)
	expect(level.mouth.carrying() == "adze", "arrival picks up the adze")
	level.put_back()
	var hints_before_recital: Dictionary = level._hints._steps.duplicate()
	level._click_world(on_figure(level, level._lector))
	arrive(level)
	expect(level.hud._text == level._descriptions.text("lector_with_plumes") + " " + level.PUZZLES.text("procession.standards", "feedback", "speaking"), "plumed lector click shows default description with speaking cue at the bottom")
	expect(level._recital.get_child_count() == 8, "plumed lector still recites all eight standards")
	expect(level._recital.get_children().all(func(glyph): return Color(glyph.modulate, 1.0).is_equal_approx(UI.inked(UI.RED))), "plumed lector's spoken signs use heka red")
	expect(level._recital.get_children().all(func(glyph): return is_equal_approx(glyph.position.y + glyph.texture.get_size().y * glyph.scale.y, level.level.recital.bottom - level.RECITE_RAISE)),
		"plumed lector's signs hang RECITE_RAISE higher than the recital's bottom row")
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
	expect(level.hud._text == level._descriptions.text(second.id), "second offering table has its own description")
	var id: String = offerings.speaking()
	var imprint: Sprite2D = offerings._placement_imprint
	expect(imprint.visible and imprint.position == offerings.pieces[id].rect.get_center()
		and imprint.texture == offerings._tex[id], "priest clue shows the same piece at its destination")
	offerings._speak_tween.custom_step(offerings.SPEAK_FADE_IN)
	expect(imprint.modulate.is_equal_approx(UI.inked(UI.FAINT_INK)) and offerings._speak.modulate.a == 1.0, "piece clue and faint imprint fade in together")
	expect(offerings._speak.modulate.is_equal_approx(UI.inked(UI.RED)), "lector's spoken offering uses heka red after fading in")
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
	expect(level.hud._text == level.PUZZLES.text("procession.goose", "feedback", "instructions_empty"), "empty bearer keeps forlorn description")
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
	offerings.reset()
	level.enter_table(true)
	arrive(level)
	level._stack_table_but_frond()
	level._place_table_piece(offerings.stackable()[0])
	offerings.take("goose")
	level._act_bearer()
	level.leave_table()
	var loaf_drawing: Sprite2D = offerings.objects[loaf].sprite
	expect(level.solved.t3 and level.solved.t4 and loaf_drawing.is_visible_in_tree(),
		"completed table shows the bread after the goose is returned")
	var goose_box: Rect2 = level._descriptions.sprite_bounds(offerings._bearer_sprite)
	var goose_point := Vector2.INF
	for y in 12:
		for x in 12:
			var sample := goose_box.position + goose_box.size * Vector2((x + 0.5) / 12, (y + 0.5) / 12)
			if offerings.goose_at(sample):
				goose_point = sample
				break
		if goose_point != Vector2.INF:
			break
	expect(goose_point != Vector2.INF, "returned goose has a readable hotspot")
	if goose_point != Vector2.INF:
		level._click_world(goose_point)
		arrive(level)
		expect(level.hud._text == level.PUZZLES.text("procession.goose", "feedback", "success_carrying")
			and offerings.placed.has(loaf) and loaf_drawing.is_visible_in_tree(),
			"inspecting the returned goose (as the goose-man) leaves the bread visible on the table")
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
		var box: Rect2 = level._hot_rect(animal_id)
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
	var saved_progress: Array[String] = scroll.restored.duplicate()
	var built: Array = scroll.SCENES.map(func(e): return e.key).filter(scroll.is_built)
	scroll.unlock_all = false   # as in a release build
	for n in built.size() + 1:
		var finished: Array[String] = []
		finished.assign(built.slice(0, n))
		var current: String = built[n] if n < built.size() else ""
		scroll.restored.assign(finished)
		menu._refresh_map()
		expect(scroll.current() == current, "map progress selects the first unfinished playable chapter: " + str(finished))
		expect(menu._play_key() == (current if current != "" else scroll.SCENES[0].key),
			"Play agrees with saved progress, with replay available after completion")
		var markers: Array[String] = []
		var rules := true
		for entry in scroll.SCENES:
			var card: Control = menu._cards.find_child(entry.key, true, false)
			if card.get_node("Frame/Picture/Current").visible:
				markers.append(entry.key)
			var done: bool = entry.key in finished
			rules = rules and (card.get_node("Frame/Picture").self_modulate.a == 1.0) == done
			menu._choose(entry.key)
			rules = rules and menu._chosen_go.disabled == not (done or entry.key == current)
			rules = rules and menu._map.chosen_view.visible == done
		expect(rules, "only restored chapters are in dark ink and can be viewed; only they and the next can be played: " + str(finished))
		expect(markers == ([current] if current != "" else []),
			"You are here marks only unfinished progress, and disappears once everything is complete")
	scroll.unlock_all = true    # as in a debug build
	scroll.restored.assign([])
	menu._refresh_map()
	var debug_rules := true
	for entry in scroll.SCENES:
		menu._choose(entry.key)
		debug_rules = debug_rules and menu._chosen_go.disabled == not scroll.is_built(entry.key) and menu._map.chosen_view.visible == scroll.is_built(entry.key)
	expect(debug_rules, "debug builds can play and view every built chapter")
	scroll.restored.assign(saved_progress)
	menu.free()
	_locked_belong_to_whole()
	print("PROCESSION INTERACTIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
