## View mode: a restored level opens as the finished scroll, with nothing to play.
extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1
func _load(key: String) -> Node:
	var scene = load("res://scenes/%s.tscn" % key).instantiate()
	root.add_child(scene)
	return scene
func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	var scroll: Node = root.get_node("Scroll")
	scroll.viewing = true
	expect(UI.VIEW != Color.WHITE, "view mode has its own frame tint")

	var procession := _load("procession")
	for i in 6:
		await process_frame
	var tinted: bool = procession.hud.find_children("*", "TextureRect", true, false).any(func(t): return t.modulate == UI.VIEW)
	expect(tinted, "the frame band is tinted while viewing")
	expect(procession.solved.values().all(func(v): return v) and not procession.finished, "procession: every rite is shown done, with no ending")
	expect(procession.haul.done and procession.water.done and procession.bulls.done and procession.mouth.done() \
		and procession.offerings.complete() and procession.offerings.goose_returned() and procession.ending.complete(), "procession: each puzzle is restored")
	expect(procession.slot.keys().all(func(p): return procession.slot[p] == procession.SLOTS[p].home), "procession: standards stand on their own poles")
	procession.hud.dismiss_intro()
	var stand: Rect2 = procession.ending.place_rect()
	procession._click_world(stand.get_center())
	expect(not procession.in_table and not procession.in_standards and not procession.haul.active and not procession.water.active \
		and not procession.bulls.active and procession.ending.worn.is_empty() and procession.ending.held == "", "procession: clicks start no puzzle")
	procession._check()
	procession.queue_free()
	await process_frame

	var dangers := _load("dangers")
	for i in 6:
		await process_frame
	expect(dangers.current.is_empty() and dangers.gate.is_empty() and dangers.solved.size() >= 10, "dangers: every danger is overcome and no gate bars the way")
	expect(dangers._fight_at(dangers.actor_rect("c31a").get_center()).is_empty(), "dangers: a creature starts no fight")
	expect(dangers._item_at(dangers.actor_rect("ankh38").get_center()) == "" and dangers.items.is_empty(), "dangers: the signs cannot be taken")
	dangers.finish()
	expect(not dangers.finished, "dangers: the level never ends by itself")
	dangers.queue_free()
	await process_frame

	var survival := _load("survival")
	for i in 6:
		await process_frame
	expect(not survival._ready_done and survival.mode == survival.Mode.WALK, "survival: the rites are not set up")
	survival.queue_free()
	await process_frame

	scroll.viewing = false
	var before: Array[String] = scroll.restored.duplicate()
	scroll.restored.clear()
	var map = load("res://scenes/scroll.tscn").instantiate()
	root.add_child(map)
	await process_frame
	scroll.unlock_all = false
	map.choose("procession")
	expect(not map.chosen_view.visible, "map: an unrestored level offers no View")
	scroll.restored.append("procession")
	map.choose("procession")
	expect(map.chosen_view.visible and map.chosen_view.text == "View" and map.chosen_go.text == "Play again", "map: a restored level offers Play again and View")
	map.choose("hall")
	expect(not map.chosen_view.visible, "map: an unbuilt level offers no View")
	scroll.unlock_all = true
	scroll.restored.clear()
	map.choose("procession")
	expect(map.chosen_view.visible, "map: in debug builds an unrestored level offers View")
	scroll.unlock_all = OS.is_debug_build()
	scroll.restored.assign(before)
	map.queue_free()
	await process_frame
	print("VIEW MODE REGRESSIONS " + ("OK" if failures == 0 else "FAILED (%d)" % failures))
	quit(failures)
