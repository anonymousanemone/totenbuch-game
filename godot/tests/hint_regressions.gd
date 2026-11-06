## Hint-button integration: data, context, independent ladders, phases, and restart.
extends SceneTree
const HINTS := preload("res://scripts/puzzles.gd")
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func expect(value: bool, label: String) -> void:
	print(("PASS " if value else "FAIL ") + label)
	if not value:
		failures.append(label)
func _run() -> void:
	var reader = HINTS.new()
	var ranks := {"notice": 2, "interpret": 3, "act": 4}
	var valid := true
	var text_valid := true
	for id in reader.data.puzzles:
		var entry: Dictionary = reader.data.puzzles[id]
		text_valid = text_valid and entry.keys() == ["instructions", "success", "feedback", "hints"]
		for field in ["instructions", "success"]:
			text_valid = text_valid and entry[field] is String and not entry[field].is_empty()
		for value in entry.feedback.values():
			text_valid = text_valid and value is String and not value.is_empty()
		valid = valid and not entry.hints.find.default.is_empty() and not entry.hints.phases.is_empty()
		for entries in entry.hints.phases.values():
			var previous := 0
			valid = valid and not entries.is_empty()
			for line in entries:
				valid = valid and ranks.has(line.level) and ranks.get(line.level, 0) > previous and not line.text.is_empty()
				previous = ranks.get(line.level, 0)
			valid = valid and entries[-1].level == "act"
	expect(valid, "all puzzles have Find text and nonempty, ordered hint levels ending with an action")
	expect(text_valid, "every puzzle has plain instructions/success strings, named feedback, and the requested field order")
	var steps: Dictionary = reader._steps.duplicate()
	reader.text("procession.bulls", "instructions")
	reader.text("procession.bulls", "success")
	var taken: String = reader.text("procession.standards", "feedback", "standard_taken") % ["<standard>", "<bearer>"]
	expect(taken.contains("<standard>") and taken.contains("<bearer>"), "feedback preserves runtime formatting placeholders")
	expect(reader._steps == steps, "reading puzzle instructions and success text does not consume hint levels")
	for puzzle in reader.data.puzzles:
		expect(reader.find(puzzle).ends_with(HINTS.MORE_HINTS), "Find includes the next-hint reminder: " + puzzle)
		for phase in reader.data.puzzles[puzzle].hints.phases:
			var entries: Array = reader.data.puzzles[puzzle].hints.phases[phase]
			for index in entries.size():
				var line: String = reader.advance(puzzle, phase)
				expect(line.ends_with(HINTS.MORE_HINTS) == (index < entries.size() - 1),
					"only non-final hints include the reminder: %s/%s/%d" % [puzzle, phase, index])
	reader.reset()
	var p = load("res://scenes/procession.tscn").instantiate()
	root.add_child(p)
	p.hud.dismiss_intro()
	p.set_process(false)
	p.avatar.set_process(false)
	p.say("Scribe", "Ordinary speech")
	expect(p.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG, "ordinary speech uses the red tag")
	p.say_game("Scribe", "Minigame instructions")
	expect(p.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG_MINIGAME, "minigame messages use the green tag")
	p.say_game("Hint", "A hint during a minigame")
	expect(p.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG_HINT
		and p.hud._tag_label.get_theme_color("font_color") == UI.INK, "hints override minigame context with a yellow tag and dark readable text")
	p._descriptions.show("calf", p.hud)
	expect(p.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG
		and p.hud._tag_label.get_theme_color("font_color") == UI.CREAM, "character descriptions restore the default red tag and cream text")
	p.avatar.position.x = p.start_x
	p.hud.hint_pressed.emit()
	expect(p.hud._text == reader.find("procession.haul") and p._hints._steps.is_empty(), "exploration Find identifies unfinished work without consuming puzzle hints")
	p.avatar.position.x = p.bulls.calf_sprite().position.x
	p.hint()
	expect(p.hud._text == reader.find("procession.bulls"), "nearby unfinished puzzle takes priority over earlier distant work")
	p.solved.t8 = true
	p.hint()
	expect(p.hud._text != reader.find("procession.bulls"), "Find excludes completed puzzles")
	p.solved.t8 = false
	p.in_standards = true
	p.hint()
	var first: String = p.hud._text
	p.in_standards = false
	p.in_table = true
	p.hint()
	expect(in_phase(reader, "procession.offerings", "build", p.hud._text), "active puzzle takes priority over location and earlier unfinished tasks")
	p.say("Lector priest", "A clue")
	var saved: Dictionary = p._hints._steps.duplicate()
	p.offerings.speak()
	expect(saved == p._hints._steps, "NPC clues and ordinary instructions do not advance Hint-button levels")
	p.in_table = false
	p.in_standards = true
	p.hint()
	var last: String = p.hud._text
	p.hint()
	expect(first == phase_hint(reader, "procession.standards", "sort", 0) and last == phase_hint(reader, "procession.standards", "sort", 1) and p.hud._text == last, "returning preserves the independent ladder and exhausted hints repeat their final answer")
	p.in_standards = false
	p.bulls.active = true
	p.hint()
	p.hint()
	expect(p.hud._text == phase_hint(reader, "procession.bulls", "calf", 1), "calf phase gives its own action")
	p.bulls.calf_sprite().scale.x = 1.0
	p.hint()
	expect(p.hud._text == first_bull_hint(reader), "new plumes phase starts with its first hint")
	p.hint()
	expect(p.hud._text == phase_hint(reader, "procession.bulls", "plumes", 1), "completed calf phase is excluded from plumes advice")
	p.bulls.active = false
	p.in_table = true
	p.solved.t3 = true
	p.offerings.bearer = ""
	p.hint()
	expect(p.hud._text == phase_hint(reader, "procession.goose", "find_goose", 0), "completed offering table routes to the remaining goose task without claiming he still holds a loaf")
	p.bulls.active = false
	p.in_table = false
	for attempt in 2:
		p.bulls.enter()
		expect(p.hud._text == reader.text("procession.bulls", "instructions") and p.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG_MINIGAME, "bulls instructions replace hints on every entry")
		p.hint()
		p.bulls.leave()
		p.water.enter()
		expect(p.hud._text == reader.text("procession.water", "instructions"), "water instructions replace hints on every entry")
		p.hint()
		p.water.leave()
		p.solved.t4 = true
		p.enter_table(true)
		expect(not p.in_table, "once the table and the goose are done, the table cannot be entered again")
		p.solved.t4 = false
	p.reset()
	p.hud.dismiss_intro()
	expect(p._hints._steps.is_empty(), "restart clears every hint ladder")
	for id in p.solved:
		p.solved[id] = true
	p.hint()
	expect(p.hud._text == reader.message("procession.complete"), "completed level shows completion guidance rather than solved puzzle advice")
	p.free()
	var d = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(d)
	d.hud.dismiss_intro()
	d.set_process(false)
	d._instant = true
	d.avatar.set_process(false)
	var encounter: Dictionary = d.ENCOUNTERS.filter(func(e): return e.id == "e37")[0]
	d.start_fight(encounter)
	expect(d.hud._text == reader.text("dangers.e37", "instructions") and d.hud._tag.get_theme_stylebox("panel").bg_color == UI.TAG_MINIGAME, "fight entry uses centralized puzzle instructions")
	d.hud.hint_pressed.emit()
	expect(d.hud._text == phase_hint(reader, "dangers.e37", "fight", 0), "active Merti fight preserves the existing hint without exposing which sign predicts which snake")
	d.leave_fight()
	encounter = d.ENCOUNTERS.filter(func(e): return e.id == "e41")[0]
	d.start_fight(encounter)
	d.hint()
	expect(d.hud._text == phase_hint(reader, "dangers.e41", "fight", 0), "the sheaf fight hints at its controls")
	d.leave_fight()
	d.avatar.position.x = d.span(encounter).x + 50.0
	d.hint()
	expect(d.hud._text == reader.find("dangers.e41", "nearby"), "walking in an unfinished vignette shows Find rather than fight instructions")
	d.solved[encounter.id] = true
	d.hint()
	expect(d.hud._text == reader.find("dangers.e31", "right"), "solving a later vignette excludes it from Find and falls back to unfinished scroll order")
	d.reset()
	expect(d._hints._steps.is_empty(), "Dangers restart clears phase progression")
	encounter = d.ENCOUNTERS.filter(func(e): return e.id == "e38")[0]
	d.avatar.position.x = (d.span(encounter).x + d.span(encounter).y) / 2.0
	d.hint()
	expect(d.hud._text == reader.data.puzzles["dangers.e38"].hints.phases.choose[0].text, "standing at the offered signs selects the choice puzzle hint without requiring a fight")
	for e in d.ENCOUNTERS:
		d.solved[e.id] = true
	var before: String = d.hud._text
	d.hint()
	expect(d.hud._text == before, "Dangers completion does not rely on a stale current encounter: Hint says nothing more")
	d.free()
	var cosmos = load("res://scenes/cosmos.tscn").instantiate()
	root.add_child(cosmos)
	cosmos.hud.dismiss_intro()
	cosmos.hud.hint_pressed.emit()
	expect(cosmos.hud._text == reader.message("cosmos.explore") and cosmos._hints._steps.is_empty(), "Cosmos keeps general exploration help without puzzle ladders")
	cosmos.free()
	print("HINT REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
func first_bull_hint(reader) -> String:
	return phase_hint(reader, "procession.bulls", "plumes", 0)


## The Hint-button text for one step of a puzzle phase, as `puzzles.gd` shows it.
func phase_hint(reader, puzzle: String, phase: String, step: int) -> String:
	var entries: Array = reader.data.puzzles[puzzle].hints.phases[phase]
	return entries[step].text + (HINTS.MORE_HINTS if step < entries.size() - 1 else "")


func in_phase(reader, puzzle: String, phase: String, text: String) -> bool:
	for step in reader.data.puzzles[puzzle].hints.phases[phase].size():
		if text == phase_hint(reader, puzzle, phase, step):
			return true
	return false
