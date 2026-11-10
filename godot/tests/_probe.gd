extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var level = load("res://scenes/procession.tscn").instantiate()
	root.add_child(level)
	for i in 8: await process_frame
	level.hud.dismiss_intro()
	print("mummy rect ", level.mouth.mummy_rect(), " hot ", level._descriptions.region_bounds(level._inspection_regions["anubis_and_the_mummy"]))
	level.avatar.position.x = level._mouth_stand_x()
	level.mouth.take_adze()
	for i in 5: await process_frame
	print("carrying ", level.mouth.carrying(), " avatar ", level.avatar.position)
	var r: Rect2 = level.mouth.mummy_rect()
	for fy in [0.2, 0.5, 0.8]:
		for fx in [0.2, 0.5, 0.8]:
			var p := r.position + r.size * Vector2(fx, fy)
			print(p, " -> ", level._pick(p))
	quit()
