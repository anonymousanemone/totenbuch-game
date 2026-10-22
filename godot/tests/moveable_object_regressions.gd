## Shared movement states and puzzle-specific recovery/placement contracts.
extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func expect(value: bool, label: String) -> void:
	print(("PASS " if value else "FAIL ") + label)
	if not value:
		failures.append(label)

func _ink_point(sprite: Sprite2D) -> Vector2:
	var image := sprite.texture.get_image()
	if image.is_compressed():
		image.decompress()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				return sprite.to_global(sprite.get_rect().position + Vector2(x, y))
	return sprite.global_position

func _run() -> void:
	var scene = load("res://scenes/procession.tscn").instantiate()
	root.add_child(scene)
	scene.hud.dismiss_intro()
	scene.set_process(false)
	scene.avatar.set_process(false)
	var item: MoveableObject = scene.ending.objects.lotus
	expect(item.base_world_scale.is_equal_approx(Vector2.ONE), "lotus starts at full scale")
	scene.ending.take("lotus")
	expect(scene.hud._text == "You pick up the lotus.", "scene-to-avatar collection shows pickup message")
	var worn_scale := item.sprite.global_scale.abs()
	scene.hud.say("Scribe", "Existing description.")
	scene.ending.hold("lotus")
	expect(scene.hud._text == "Existing description.", "dragging from avatar does not announce pickup")
	item.move_held(Vector2(500, 120))
	expect(item.sprite.global_scale.abs().is_equal_approx(worn_scale), "dragging preserves worn lotus size")
	scene.avatar.position.x += 120
	scene.ending.unhold()
	expect(scene.hud._text == "Existing description.", "returning to avatar does not announce pickup")
	var expected: Transform2D = scene.avatar.carrying_transform() * scene.ending.pose("lotus")
	expect(item.state == MoveableObject.State.WORN and item.sprite.global_transform.is_equal_approx(expected), "cancel returns to current moving avatar attachment")
	scene._descriptions.entries.lotus = {"name": "Lotus", "descriptions": {"default": "The lotus description."}}
	var mouse := InputEventMouseMotion.new()
	scene._begin_carried(item, scene.get_global_mouse_position())
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	scene._carried_input(release)
	expect(scene.hud._text == "The lotus description.", "attached object click reads its description")
	expect(item.state == MoveableObject.State.WORN and scene.ending.held == "", "clicking worn object leaves it attached")
	scene._begin_carried(item, scene.get_global_mouse_position())
	scene._descriptions.entries.lotus.descriptions.default = "The lotus has changed."
	mouse.position = scene._object_press_screen + Vector2(20, 0)
	scene._carried_input(mouse)
	expect(scene.hud._text == "The lotus has changed.", "drag start resolves description from current game state")
	scene._carried_input(mouse)
	expect(scene.hud._text == "The lotus has changed.", "drag motion keeps description visible")
	expect(item.state == MoveableObject.State.HELD and scene.ending.held == "lotus", "crossing drag threshold detaches worn object")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	scene._carried_input(cancel)
	expect(item.state == MoveableObject.State.WORN and scene.ending.held == "", "Escape cancels active carried drag")
	var parent := Node2D.new()
	parent.scale = Vector2(2, 3)
	scene.add_child(parent)
	item.set_to_loc(parent, Transform2D(0.2, Vector2(20, 40)), 2)
	item.place()
	expect(item.sprite.global_scale.abs().is_equal_approx(worn_scale), "scaled destination parent does not resize item")
	expect(is_zero_approx(item.sprite.global_transform.x.dot(item.sprite.global_transform.y)), "nonuniformly scaled parent does not shear the object")
	item.lock_in_place()
	item.hold()
	expect(item.state == MoveableObject.State.PLACED, "placement lock refuses holding")
	item.reset()
	expect(not item.locked_in_place and item.sprite.get_parent() == item.from_loc_parent, "reset clears lock and restores source parent")
	var table = scene.offerings
	expect(is_equal_approx(table.floor_x.y, scene._bearer_rect.end.x), "table bounds extend to goose bearer right edge")
	var found_blocker := false
	for child in table.get_children():
		if child is StaticBody2D:
			for shape in child.get_children():
				if shape is CollisionShape2D and shape.position.is_equal_approx(table.lector_rect.get_center()):
					found_blocker = true
	expect(found_blocker, "lector has a physical blocker")
	var loaf: String = table.bearer
	table.bearer_act()
	expect(table.holding() == loaf and table.held_from() == "bearer", "direct loaf drag records bearer origin")
	table.put_back()
	expect(table.bearer == loaf and table.holding() == "", "cancel direct loaf drag returns it to bearer")
	table.bearer_act()
	table.drop_at(Vector2(table.floor_x.x + 100, table.ground - 80))
	table.take(loaf)
	expect(table.held_from() == "floor", "loaf released to table acquires floor origin")
	table.put_back()
	expect(table.bearer == "" and table.holding() == "" and table.sprite_of(loaf) != null, "cancel table loaf returns to table, not bearer")
	table.take(loaf)
	table.reject_held()
	expect(table.holding() == "" and table.sprite_of(loaf) != null, "rejected object becomes floor physics, never pointer-following")
	table.reset()
	table.take("goose")
	var result: String = table.bearer_act()
	expect(result == "swapped" and table.bearer == "goose" and table.holding() == "", "goose swap drops loaf without putting it in hand")
	expect(table.sprite_of(loaf) != null and table.objects.goose.locked_in_place, "displaced loaf has physics and accepted goose is locked")
	expect(table.objects.goose.state == MoveableObject.State.PLACED and table.objects.goose.sprite.visible, "accepted goose uses its movable sprite and placed state")
	scene._click_world(_ink_point(table.objects.goose.sprite))
	expect(scene.hud._text == "He clings to his goose, refusing to give it up again.", "clicking accepted goose shows its own refusal description")
	expect(table.bearer_act() == "has_goose" and table.holding() == "", "accepted goose cannot be taken back")
	var body := table.sprite_of(loaf).get_parent() as RigidBody2D
	expect(body.position.x >= table.floor_x.x and body.position.x <= table.floor_x.y, "displaced loaf spawns within expanded floor bounds")
	var half: Vector2 = table._tex[loaf].get_size() / 2.0
	expect(not table.lector_rect.grow(half.length()).has_point(body.position), "fallback drop avoids lector blocker")
	scene.bulls.reset()
	scene.bulls.enter()
	var plumes: MoveableObject = scene.bulls.plumes_object
	plumes.wear(scene.avatar, Transform2D.IDENTITY)
	expect(plumes.state == MoveableObject.State.WORLD, "non-carriable plumes refuse avatar attachment")
	scene.bulls.press("plumes", scene.bulls._plumes.global_position)
	scene.bulls.drag(scene.bulls._right)
	scene.bulls.release(scene.bulls._right)
	expect(plumes.locked_in_place and scene.bulls.crowned() and not scene.bulls.done, "plumes lock before calf puzzle completion")
	scene.bulls.press("plumes", scene.bulls._right)
	expect(scene.bulls.held == "" and plumes.state == MoveableObject.State.PLACED, "placed plumes cannot be dragged again")
	scene.mouth.take_adze()
	expect(scene.hud._text == "You pick up the adze.", "adze collection shows pickup message")
	scene._click_world(scene.mouth.mummy_rect().get_center())
	expect(not scene.avatar.is_walking() and not scene.mouth.active, "clicking mummy does not approach or start carving")
	scene._begin_carried(scene.mouth.adze_object, scene.get_global_mouse_position())
	mouse.position = scene._object_press_screen + Vector2(20, 0)
	scene._carried_input(mouse)
	var mummy_bounds: Rect2 = scene.mouth._mummy
	scene.mouth._mummy = Rect2(scene.get_global_mouse_position() - Vector2(10, 10), Vector2(20, 20))
	scene._carried_input(release)
	scene.mouth._mummy = mummy_bounds
	expect(scene.avatar.is_walking() and not scene.mouth.active, "dropping adze onto mummy starts approach")
	scene.avatar.position.x = scene.avatar._target
	scene.avatar._process(0)
	expect(scene.mouth.active, "adze drop starts carving on arrival")
	scene.mouth._process(0)
	expect(scene.mouth.adze_object.interaction_mode == MoveableObject.InteractionMode.TOOL_USE and scene.mouth._adze.scale.is_equal_approx(Vector2.ONE * 0.5), "adze carving uses approved 50 percent tool scale")
	scene.mouth.leave()
	scene.mouth._process(0)
	expect(scene.mouth._adze.global_scale.abs().is_equal_approx(Vector2.ONE), "leaving tool mode restores adze scale")
	scene.mouth.instant = true
	scene.mouth._speak()
	scene.mouth.take_words()
	expect(scene.mouth.words_object.transport_mode == MoveableObject.TransportMode.CLICK_FOLLOW, "words keep explicit click-follow exception")
	scene.bulls.leave()
	scene.mouth._words_home.position = scene.get_global_mouse_position() + Vector2(10000, 10000)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	scene._unhandled_input(click)
	expect(scene.mouth.phase == OpeningMouth.Phase.SPOKEN and scene.mouth._words.position == scene.mouth._spoken, "words return to their appearance location")
	scene.mouth.take_words()
	scene._unhandled_input(cancel)
	expect(scene.mouth.phase == OpeningMouth.Phase.SPOKEN, "Escape returns click-follow words to their appearance location")
	scene.free()
	var dangers = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(dangers)
	dangers.hud.dismiss_intro()
	dangers.set_process(false)
	dangers.avatar.set_process(false)
	var encounter: Dictionary = dangers.ENCOUNTERS.filter(func(e): return e.id == "e38")[0]
	dangers.take(encounter, "ankh38")
	expect(dangers.hud._text == "You pick up the ankh.", "ankh collection shows pickup message")
	var sign: MoveableObject = dangers.objects.ankh38
	sign.hold()
	sign.move_held(Vector2(40, 40))
	dangers.avatar.position.x -= 70
	sign.cancel_hold()
	expect(sign.state == MoveableObject.State.WORN and sign.sprite.global_transform.is_equal_approx(dangers.avatar.carrying_transform() * dangers._item_poses.ankh38.transform), "Dangers sign returns to current avatar with no destination")
	dangers.reset()
	expect(sign.state == MoveableObject.State.WORLD and sign.sprite.transform.is_equal_approx(sign.from_loc_transform), "Dangers reset restores authored source")
	dangers.take(encounter, "sail38")
	expect(dangers.hud._text == "You pick up the breath sign.", "breath collection shows pickup message")
	dangers.free()
	print("MOVEABLE OBJECT REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
