## Spell 38 choices: mortality, repeating fights, journal scores, and active-play clue limits.
extends SceneTree

const GAME := preload("res://scripts/dangers/dangers.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures.append(label)


func level(item := ""):
	var scene = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(scene)
	scene.hud.dismiss_intro()
	scene.set_process(false)
	scene._instant = true
	if item != "":
		scene.take(encounter(scene, "e38"), item)
	return scene


func encounter(scene, id: String) -> Dictionary:
	return scene.ENCOUNTERS.filter(func(e): return e.id == id)[0]


func damage(scene) -> void:
	match scene.fight.kind:
		"apep": scene.apep._apep_bites()
		"donkey": scene.donkey._donkey_bitten()
		"sheaf": scene.sheaf._sheaf_hurt()


func hit(scene) -> void:
	match scene.fight.kind:
		"apep":
			var wave: Dictionary = scene.apep._apep_launch(false, 220.0)
			scene.apep._apep_pressed(wave)
			scene.apep._apep(scene.apep.APEP_HOLD + 0.01)
		"donkey":
			scene.donkey._donkey_struck()
			scene.donkey._donkey(scene.ROACH_FREEZE + 0.01)
		"sheaf":
			scene.fight.sn.at = 0 if scene.fight.hits == int(scene.fight.e.need) - 1 else 2
			scene.sheaf._sheaf_hit()
			scene.sheaf._sheaf(scene.ROACH_FREEZE + 0.01)


func _run() -> void:
	for item in ["", "sail38", "ankh38"]:
		var scene = level(item)
		for id in GAME.AFTER_CHOICE:
			var e := encounter(scene, id)
			scene.start_fight(e)
			expect(scene.hard() == (id == "e41" and item != "sail38"), id + " uses the selected difficulty, with easy scaffolding for untuned encounters: " + item)
			expect(scene.endless() == (item == "ankh38"), id + " is endless only with the ankh: " + item)
			if item != "ankh38":
				scene.fight.health = 1
				scene.fight.donkey_health = 1
				damage(scene)
				expect(scene.fight.lost, id + " still has a fatal last bite without the ankh: " + item)
			else:
				for i in 10:
					damage(scene)
				expect(not scene.fight.lost and int(scene.fight.get("donkey_health", scene.fight.get("health", 0))) > 0, id + " survives repeated damage with the ankh")
				expect(scene.fight.ankh_flash > 0.0, id + " flashes the ankh on a damaging mistake")
				if id == "e40":
					scene.donkey._donkey_speared()
					expect(not scene.fight.lost and scene.fight.phase == "latched", "spearing the donkey with the ankh recovers without a death")
				var speech: String = scene.hud._text
				for i in int(e.need) * 2 + 1:
					hit(scene)
				expect(not scene.fight.is_empty() and not scene.fight.lost and not scene.solved.has(id), id + " continues beyond two normally winning cycles")
				expect(scene._life_scores[id] == int(e.need) * 2 + 1, id + " counts every successful action across cycles")
				expect(scene.fight.hits < int(e.need), id + " resets progress so the snake can attack again")
				speech = scene.hud._text
				scene._life_hit()
				expect(scene.hud._text == speech and not scene.hud._journal_page.visible, "score updates are silent")
				var score: int = scene._life_scores[id]
				scene._record_actor(e.foe)
				expect(str(score) in scene.hud._journal_entries[id].text, "inspection preserves the journal score")
				scene.end_fight()
				expect(not scene.fight.is_empty() and not scene.solved.has(id), "the ankh cannot complete a post-choice encounter")
			scene.leave_fight()
		if item == "ankh38":
			expect(GAME.AFTER_CHOICE.all(func(id): return scene.hud._journal_entries.has(id)), "the journal keeps a separate score for each post-choice spell")
			scene.start_fight(encounter(scene, "e39"))
			expect(scene._life_scores.e39 > 0, "scores survive leaving and re-entering an encounter")
			scene.leave_fight()
			scene.finish()
			expect(not scene.finished, "the ankh never reaches the level ending")
		# Earlier encounters retain their original difficulty and three-bite mortality.
		scene.start_fight(encounter(scene, "e37"))
		expect(not scene.hard() and not scene.endless(), "spell 38 choices do not affect earlier encounters")
		scene.fight.health = 1
		scene.two_snakes._twin_bites(scene.fight.snakes[0])
		expect(scene.fight.lost, "the ankh does not prevent death before spell 38")
		scene.free()

	_test_clue()
	_test_optional_choice()
	print("LIFE MODE REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)


func _test_clue() -> void:
	var scene = level("ankh38")
	scene.start_fight(encounter(scene, "e39"))
	scene.fight.open = 0.0
	scene._tick_life(100.0)
	expect(scene._life_total == 0.0, "opening animation does not count toward the clue")
	scene.fight.open = 1.0
	scene.hud.toggle_journal(true)
	scene._tick_life(100.0)
	expect(scene._life_total == 0.0, "paused journal time does not count toward the clue")
	scene.hud.toggle_journal(false)
	scene._tick_life(30.0)
	scene.leave_fight()
	scene.start_fight(encounter(scene, "e39"))
	scene._tick_life(29.0)
	expect(not scene._life_clue_given, "the clue waits for the encounter time limit across visits")
	scene._tick_life(1.1)
	var clue: String = scene._hints.message("dangers.life_clue")
	expect(scene._life_clue_given and scene.hud._text == clue, "one encounter's active-play limit gives the exact clue")
	scene.say("Scribe", "Routine combat feedback")
	expect(scene.hud._text == clue, "routine combat feedback cannot immediately overwrite the clue")
	scene._life_clue_hold = 0.0
	scene.say("Scribe", "Later feedback")
	scene._tick_life(10.0)
	expect(scene.hud._text == "Later feedback", "the automatic clue is given only once")
	scene.reset()
	scene.hud.dismiss_intro()
	scene.take(encounter(scene, "e38"), "ankh38")
	for id in GAME.AFTER_CHOICE:
		scene.start_fight(encounter(scene, id))
		scene._tick_life(40.1)
		if id != "e41":
			expect(not scene._life_clue_given, "combined time remains below the clue threshold")
		scene.leave_fight()
	expect(scene._life_clue_given and scene._life_times.values().all(func(t): return t < GAME.LIFE_GAME_CLUE), "combined active play triggers the clue before any single encounter limit")
	scene.reset()
	expect(scene._life_scores.is_empty() and scene._life_times.is_empty() and scene._life_total == 0.0 and not scene._life_clue_given and scene.hud._journal_entries.is_empty(), "Restart clears scores, clue timers, and journal entries")
	scene.hud.dismiss_intro()
	scene.start_fight(encounter(scene, "e41"))
	scene._tick_life(200.0)
	expect(not scene._life_clue_given and scene._life_scores.is_empty(), "mortal play does not accumulate ankh scores or clue time")
	scene.free()


func _test_optional_choice() -> void:
	var scene = level()
	for e in scene.ENCOUNTERS:
		if e.kind in scene.FIGHTS and e.id not in GAME.AFTER_CHOICE:
			scene.solved[e.id] = true
	scene._refresh()
	expect(scene.gate.is_empty() and scene.current.id == "e39", "taking neither sign allows proceeding to the hard encounters")
	for id in GAME.AFTER_CHOICE:
		scene.solved[id] = true
	scene._refresh()
	expect(scene.current.is_empty(), "mortal completion does not require choosing a sign")
	scene.finish()
	expect(scene.finished and not "breath" in scene.hud._text, "the no-sign ending does not claim the player carries breath")
	scene.free()
