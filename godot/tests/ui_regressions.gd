## UI integration checks: pause, layout, pagination, context, and state-aware hints.
## Optional --ui-images=/tmp/totenbuch-ui saves representative rendered screenshots.
extends SceneTree

var failures: Array[String] = []
var image_dir := ""


func _initialize() -> void:
	_run.call_deferred()


func expect(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures.append(description)


func frames(count := 5) -> void:
	for i in count:
		await process_frame


func inside(control: Control) -> bool:
	var rect := control.get_global_rect()
	return Rect2(Vector2.ZERO, Vector2(root.size)).grow(1.0).encloses(rect)


func shot(name: String) -> void:
	if image_dir == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(image_dir.path_join(name + ".png"))


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ui-images="):
			image_dir = argument.trim_prefix("--ui-images=")
			DirAccess.make_dir_recursive_absolute(image_dir)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 480)]:
		root.size = dimensions
		await frames()
		for name in ["procession", "dangers", "cosmos", "field", "hall"]:
			var level = load("res://scenes/%s.tscn" % name).instantiate()
			root.add_child(level)
			var hud = level.hud
			await frames(8)
			var label := "%s %dx%d" % [name, dimensions.x, dimensions.y]
			expect(paused, label + " introduction pauses gameplay")
			var layout: Dictionary = hud._overlay_layouts[0]
			expect(inside(layout.scroll.get_parent().get_parent()), label + " introduction fits viewport")
			if dimensions.x == 1280:
				await shot(name + "-intro")
			hud.dismiss_intro()
			expect(not paused, label + " begin resumes gameplay")
			level.set_process(false)
			hud.set_context("[space] attack · [esc] explore", "2/3")
			hud.say("Scribe", "Drag each offering to its place, lowest first. The upper shelf catches loose offerings. Only a piece you are dragging can cross the shelf. The lector beside the table shows a piece you can place next. Ask for a hint if you need help.")
			await frames(8)
			expect(hud._say.get_theme_font_size("normal_font_size") == UI.DIALOGUE, label + " dialogue keeps its readable font size")
			expect(hud._say.get_content_height() <= hud._say.size.y + 1.0, label + " dialogue page fits")
			if hud._say.get_content_height() > hud._say.size.y + 1.0:
				print("LAYOUT ", hud._say.size, " content=", hud._say.get_content_height(), " page=", hud._pages[0])
			expect(inside(hud._next) and inside(hud._context), label + " paging and controls fit viewport")
			if not inside(hud._next) or not inside(hud._context):
				print("BOUNDS next=", hud._next.get_global_rect(), " context=", hud._context.get_global_rect())
			var rebuilt := " ".join(hud._pages).replace("\n", " ")
			expect(rebuilt == hud._text, label + " paging preserves every word")
			hud.next_page()
			expect(hud._context.text.contains("[esc]"), label + " feedback pages preserve exit controls")
			hud.update_hand("test", "the jackal standard", level.get_node("Strip").texture)
			await frames(8)
			expect(hud._say.get_content_height() <= hud._say.size.y + 1.0, label + " carried item leaves dialogue readable")
			hud.say("You, before the last judge", "The judges have heard you.")
			await frames()
			expect(inside(hud._tag), label + " long speaker tag fits viewport")
			hud.update_hand("", "", null)
			hud.say("Scribe", "Drag offerings into place, lowest first. The upper shelf catches loose offerings. Drag them across it to use them.")
			await frames()
			if dimensions.x == 800 and name == "procession":
				await shot("dialogue-800")
			for i in 12:
				hud.add_journal_entry("Figure %d" % i, "A figure in the procession.", level.get_node("Strip").texture, i + 1, 12)
			level.set_process(true)
			hud.toggle_journal(true)
			var before: Vector2 = level.avatar.position
			var press := InputEventAction.new()
			press.action = "ui_left"
			press.pressed = true
			Input.parse_input_event(press)
			await frames()
			expect(paused and level.avatar.position == before, label + " Journal blocks keyboard movement")
			press.pressed = false
			Input.parse_input_event(press)
			expect(inside(hud._journal_scroll.get_parent().get_parent()), label + " Journal fits viewport")
			if dimensions.x == 640 and name == "procession":
				await shot("journal-640")
			Input.action_press("ui_down")
			hud.toggle_journal(false)
			expect(not paused, label + " closing Journal resumes gameplay")
			expect(not Input.is_action_pressed("ui_down"), label + " reading keys cannot exit a scene on resume")
			if dimensions.x == 1280 and name == "dangers":
				level.start_fight(level.ENCOUNTERS[2])
				level.hint()
				expect(hud._text == level.fight.e.hint, "hint describes the chosen fight rather than the first unsolved one")
				var before_time: float = level.fight.t
				hud.toggle_journal(true)
				await frames()
				expect(level.fight.t == before_time, "Journal freezes active danger timing")
				hud.toggle_journal(false)
				level.leave_fight()
			if dimensions.x == 1280 and name == "procession":
				level._table_now()
				level.hint()
				expect(hud._text.contains("offering"), "offering hints take priority over unfinished hauling")
				level.leave_table()
				hud.say("Scribe", "Old interaction")
				hud.say_later("Scribe", "Stale message", 0.01)
				hud.say("Scribe", "New interaction")
				await create_timer(0.03).timeout
				expect(hud._text == "New interaction", "delayed feedback cannot overwrite a newer instruction")
			if dimensions.x == 1280 and name == "cosmos":
				level.take("sun")
				level.hint()
				expect(hud._text.contains("[esc]"), "carried sun hint explains how to clear the blocked path")
				level.put_back()
				level.take("ba")
				level.hint()
				expect(hud._text.contains("mummy"), "carried ba hint gives its destination")
			if dimensions.x == 1280 and name == "field":
				level.take_grain()
				level.hint()
				expect(hud._text.contains("table"), "carried grain hint gives its destination")
			if dimensions.x == 1280 and name == "hall":
				level._render()
				expect(not hud._hand_label.text.contains("esc"), "heart does not advertise an unavailable return action")
			if dimensions.x == 1280 and name != "procession":
				level.finish()
				await create_timer(1.3).timeout
				expect(hud._outro.visible, name + " actual ending remains readable")
				var next: Dictionary = root.get_node("Scroll").next_built(name)
				expect(hud._outro_text.text.contains(next.get("title", "Return to the scroll")), name + " ending names the actual next destination")
				await shot(name + "-outro")
			hud.show_outro("The road is clear. You carry the breath of life.\n\nGo on to the next scene.")
			await frames(8)
			expect(paused and inside(hud._overlay_layouts[1].scroll.get_parent().get_parent()), label + " outro pauses and fits viewport")
			if dimensions.x == 640 and name == "hall":
				await shot("outro-640")
			level.free()
			await frames()
		var menu = load("res://scenes/menu.tscn").instantiate()
		root.add_child(menu)
		await frames()
		for page in [menu._title, menu._settings, menu._controls, menu._map]:
			menu._show(page)
			await frames()
			if page == menu._title:
				expect(inside(menu._title.get_child(0).get_child(4).get_child(0)), "%dx%d title page fits viewport" % [dimensions.x, dimensions.y])
				if dimensions.x == 640:
					await shot("title-640")
			if page == menu._settings or page == menu._controls:
				expect(inside(page.get_child(0).get_child(0)), "%dx%d menu sheet fits viewport" % [dimensions.x, dimensions.y])
			if page == menu._map:
				var selected := false
				for row in menu._cards.get_children():
					for card in row.get_children():
						if card.has_meta("key") and not selected:
							card.grab_focus()
							expect(menu._chosen == card.get_meta("key"), "keyboard focus selects and highlights its map card")
							selected = true
			if dimensions.x == 800 and page == menu._controls:
				await shot("controls-800")
		menu.free()
		await frames()
	await _test_feedback()
	await _test_procession_scenes()
	print("UI REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)


func _test_feedback() -> void:
	root.size = Vector2i(1280, 720)
	var level = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(level)
	level.hud.dismiss_intro()
	level._instant = true
	level.take(level.ENCOUNTERS.filter(func(e): return e.id == "e38")[0])
	expect(not level.hud._hand_label.text.contains("esc"), "breath of life does not advertise an unavailable return action")
	var volume := AudioServer.get_bus_volume_db(0)
	AudioServer.set_bus_volume_db(0, -80.0)
	for encounter in level.ENCOUNTERS:
		if encounter.kind not in level.FIGHTS:
			continue
		level.start_fight(encounter)
		level.fight.awaiting_start = true
		var before: float = level.fight.t
		level._update_fight(1.0)
		expect(level.fight.t == before, encounter.id + " danger waits while muted")
		var space := InputEventKey.new()
		space.keycode = KEY_SPACE
		space.pressed = true
		level._unhandled_input(space)
		expect(not level.fight.awaiting_start, encounter.id + " Space starts the chosen danger")
		level._update_fight_context()
		expect(level.hud._context.text.contains("[esc]"), encounter.id + " controls remain available after starting")
		level._feedback_once("test", "First mistake")
		level._feedback_once("test", "Repeated mistake")
		expect(level.hud._text == "First mistake", encounter.id + " repeated mistakes do not spam instructions")
		if encounter.kind == "crocs":
			var croc: Dictionary = level.fight.crocs[0]
			croc.s = "crawl"
			croc.red = true
			croc.node.position = level.fight.pos + level._tip_offset() - level._croc_head(croc.node, croc.dir)
			level.fight.force_heka = false
			level._croc_strike()
			expect(level.hud._text.contains("bronze"), encounter.id + " plain hit on a magic crocodile explains why it failed")
		level.fight.awaiting_start = true
		level.fight.health = 2 if level.fight.has("health") else 0
		if encounter.kind in ["crocs", "twin", "creep", "apep", "sheaf"]:
			await frames()
			await shot("danger-" + encounter.id)
			if encounter.id == "e31" and image_dir != "":
				var filter := CanvasLayer.new()
				filter.layer = 100
				var rect := ColorRect.new()
				rect.size = Vector2(root.size)
				rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var shader := Shader.new()
				shader.code = "shader_type canvas_item; uniform sampler2D screen : hint_screen_texture, filter_nearest; void fragment() { vec3 c = texture(screen, SCREEN_UV).rgb; COLOR = vec4(vec3(dot(c, vec3(0.2126, 0.7152, 0.0722))), 1.0); }"
				var material := ShaderMaterial.new()
				material.shader = shader
				rect.material = material
				filter.add_child(rect)
				root.add_child(filter)
				await frames()
				await shot("danger-grayscale")
				filter.free()
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		level._unhandled_input(escape)
		expect(level.fight.is_empty() and level.avatar.visible, encounter.id + " Esc returns to exploration")
		level.start_fight(encounter)
		expect(level.fight.get("feedback", {}).is_empty(), encounter.id + " reopening resets first-occurrence advice")
		level.leave_fight()
	AudioServer.set_bus_volume_db(0, volume)
	level.free()
	await frames()


func _test_procession_scenes() -> void:
	root.size = Vector2i(1280, 720)
	var level = load("res://scenes/procession.tscn").instantiate()
	root.add_child(level)
	level.hud.dismiss_intro()
	var bounds: Rect2 = level._slot_hit_rect(level.POLES[0])
	for pole in level.POLES:
		bounds = bounds.merge(level._slot_hit_rect(pole))
	for side in [-1, 1]:
		level.avatar.position.x = bounds.position.x - 80.0 * level.unit if side < 0 else bounds.end.x + 80.0 * level.unit
		level._update_camera(1.0)
		level.enter_standards()
		level.avatar._process(0.0)
		await frames(20)
		expect(level.in_standards, "standards entry works from either side")
		expect(level._visible_rect().has_point(level.avatar.position), "avatar remains in the standards frame")
		if not level._visible_rect().has_point(level.avatar.position):
			print("FRAME ", level._visible_rect(), " avatar=", level.avatar.position)
		level.act_slot("pole1")
		expect(level._standard_guides.pole1.visible, "empty standard pole shows its required emblem")
		level.hint()
		expect(level.hud._text.contains("pole") or level.hud._text.contains("priest"), "carried-standard hint stays with the sorting task")
		if side < 0:
			await frames()
			await shot("standards-frame")
		Input.action_press("ui_left")
		level._process(0.0)
		Input.action_release("ui_left")
		expect(not level.in_standards and level.held == "", "arrow exit returns carried standard safely")
	level._table_now()
	level._table_told = true
	level.reset()
	expect(not level._table_told, "restart restores the table introduction")
	var driver: Dictionary = level.hotspots.filter(func(h): return h.label == "Ox-driver")[0]
	level.take_rope(driver)
	level.haul._tween.custom_step(1.0)
	expect(level.haul.phase == HaulSledge.Phase.READY, "hauling waits after the introduction")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	level._unhandled_input(space)
	expect(level.haul.phase == HaulSledge.Phase.PLAYING, "Space begins the hauling count-in")
	level.haul.instant = true
	var arrow := InputEventKey.new()
	arrow.keycode = KEY_RIGHT
	arrow.pressed = true
	level._unhandled_input(arrow)
	level._process(0.0)
	expect(not level.haul.active and level.avatar.visible, "hauling arrow exit restores the walking avatar")
	level.free()
	await frames()
