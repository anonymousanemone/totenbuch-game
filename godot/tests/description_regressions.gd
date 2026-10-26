## Registry integration: variants, stable IDs, observed journal text, saved regions and picking.
extends SceneTree
const DESCRIPTIONS := preload("res://scripts/descriptions.gd")
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func expect(value: bool, label: String) -> void:
	print(("PASS " if value else "FAIL ") + label)
	if not value:
		failures.append(label)
func _run() -> void:
	for key in ["procession", "dangers", "cosmos"]:
		var catalog = DESCRIPTIONS.new(key)
		var valid := true
		for entry in catalog.entries.values():
			valid = valid and entry.name is String and entry.descriptions.default is String and not entry.descriptions.default.is_empty()
		expect(valid, key + " registry has named entries with default descriptions")
	var p = load("res://scenes/procession.tscn").instantiate()
	p._descriptions.entries.stela.name = "Renamed stela"
	root.add_child(p)
	p.hud.dismiss_intro()
	p.set_process(false)
	p.avatar.set_process(false)
	for region in p.find_children("*", "Area2D", true, false):
		if not region.get_parent() is Sprite2D:
			continue
		var sprite: Sprite2D = region.get_parent()
		var before := DESCRIPTIONS.region_bounds(region)
		sprite.position.x += 17.0
		expect(DESCRIPTIONS.region_bounds(region).position.is_equal_approx(before.position + Vector2(17, 0)),
			"saved hitbox follows its sprite in the running scene: " + region.name)
		sprite.position.x -= 17.0
	var region_ids: Array = p._inspection_regions.keys()
	expect(region_ids.size() == p.hotspots.size() + p.CAPTIONS.size() and region_ids.all(func(id): return p._descriptions.entries.has(id)), "every saved inspection region resolves a unique registry ID")
	var before_caption: int = p.journal.size()
	p._descriptions.inspect("caption_1", p.hud, p.journal, p.get_node("Strip").texture, p.hotspots.size())
	expect(p.journal.size() == before_caption and p.hud._tag_label.text == "Spell 1", "background captions use registry text without adding unwanted journal cards")
	var stela: Dictionary = p.hotspots.filter(func(h): return h.id == "stela")[0]
	p.record(stela)
	var observed: Dictionary = p.hud._journal_entries["procession/stela"]
	var blank: String = p.hud._text
	var card: Node = observed.node
	expect(p.hud._tag_label.text == "Renamed stela" and blank.contains("blank"), "renaming a subject leaves stable-ID selection and blank-state description intact")
	p.ending.imprint_shown = true
	expect(observed.text == blank, "journal does not reveal a changed state before inspection")
	p.record(stela)
	expect(p.journal.count("stela") == 1 and p.hud._journal_entries["procession/stela"].node == card and observed.text == p._descriptions.text("stela"), "reinspection updates the existing stable-ID card to the current description")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	card.gui_input.emit(click)
	expect(p.hud._text == observed.text, "journal clicks read the latest observed text rather than a captured old variant")
	var calf: Dictionary = p.hotspots.filter(func(h): return h.id == "calf")[0]
	p.record(calf)
	expect(p.hud._text == p._descriptions.text("calf", "unsettled"), "unsettled calf uses its authored clue")
	p.bulls.calf_sprite().scale.x = 1.0
	p.record(calf)
	expect(p.hud._text == p._descriptions.text("calf", "settled") and p.journal.count("calf") == 1, "settled calf updates the same journal entry")
	expect(p._descriptions.text("calf", "unknown") == p._descriptions.text("calf"), "unknown states fall back to the default description")
	var art: Sprite2D = p._inspection_sprites.stela
	art.position.x += 60.0
	var moved: Rect2 = DESCRIPTIONS.region_bounds(p._inspection_regions.stela)
	var picked: Dictionary = p._pick(moved.get_center())
	expect(picked.get("type") == "hot" and picked.spot.id == "stela", "saved inspection shape follows its sprite when moved in the scene")
	p.record(stela)
	expect(p.hud._journal_entries["procession/stela"].picture.texture == art.texture, "sprite journal pictures use the actual saved sprite texture")
	p._descriptions.entries["npc_a"] = {"name": "Priest", "descriptions": {"default": "An observed figure."}, "speech": "A spoken clue.", "speaker": "The priest", "journal": true}
	p._descriptions.entries["npc_b"] = {"name": "Priest", "descriptions": {"default": "A different observed figure."}, "journal": true}
	p._descriptions.inspect("npc_a", p.hud, p.journal, art.texture, 32, "default", true)
	expect(p.hud._text == "A spoken clue." and p.hud._tag_label.text == "The priest", "NPC speech uses the authored speaker and spoken clue")
	p._descriptions.inspect("npc_b", p.hud, p.journal, art.texture, 32)
	expect(p.hud._journal_entries.has("procession/npc_a") and p.hud._journal_entries.has("procession/npc_b"), "identically named subjects retain separate journal entries")
	expect(p._hints._steps.is_empty(), "inspection and NPC clues do not advance Hint-button progression")
	var ra: Dictionary = p.hotspots.filter(func(h): return h.id == "ra_enthroned")[0]
	p.record(ra)
	expect(not p.ending._base_clue.visible, "Ra shows no stand imprint without a carried part")
	for part in EndingStand.PIECES:
		p.ending.reset()
		p.ending.take(part)
		p.record(ra)
		var clue: Sprite2D = p.ending._base_clue
		expect(clue.visible and clue.position == p.ending._rects.stand.position and clue.texture == p.ending.sprite_of("stand").texture,
			"Ra shows the base at its destination while wearing " + part)
		p.ending._base_clue_tween.custom_step(0.3)
		expect(clue.modulate.is_equal_approx(EndingStand.IMPRINT), "base imprint fades in using the shared imprint color")
		p.ending._base_clue_tween.custom_step(3.2)
		expect(not clue.visible and clue.modulate.a == 0.0, "base imprint fades out and hides")
		p.ending.hold(part)
		p.ending.show_base_clue()
		expect(clue.visible and p.ending.held == part, "a part in hand also permits the clue without being put down")
		p.record(ra)
		p.ending._base_clue_tween.custom_step(0.3)
		expect(clue.visible and clue.modulate.a > 0.0, "repeated Ra clicks restart the fade")
	p.ending.reset()
	p.ending.take("stand")
	p.record(ra)
	p.ending.set_down()
	expect(not p.ending._base_clue.visible, "placing the stand cancels its destination clue")
	p.ending.take("sun")
	p.record(ra)
	expect(not p.ending._base_clue.visible, "an already placed base is not shown as an imprint")
	p.reset()
	expect(p.hud._journal_entries.is_empty() and p.journal.is_empty(), "restart clears both observed journal state and rendered cards")
	p.free()
	var d = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(d)
	d.hud.dismiss_intro()
	d.set_process(false)
	d.avatar.set_process(false)
	var ids_valid := true
	for actor in d.actors.values():
		if actor.has_meta("registry_id"):
			ids_valid = ids_valid and d._descriptions.entries.has(actor.get_meta("registry_id"))
	expect(ids_valid, "all inspectable danger actors have valid registry IDs")
	var picture: Sprite2D = d._picture(d.actors.c31a)
	var image: Image = picture.texture.get_image()
	var ink := Vector2.ZERO
	var found := false
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			if image.get_pixel(x, y).a > 0.8:
				ink = picture.to_global(picture.get_rect().position + Vector2(x, y))
				found = true
				break
		if found:
			break
	expect(d._fight_at(ink).get("id") == "e31", "unsolved creature clicks retain combat priority")
	d.solved.e31 = true
	var subject: String = d._inspection_at(ink)
	expect(subject != "" and d._fight_at(ink).is_empty(), "completed creatures remain inspectable without restarting combat")
	d._record_actor(subject)
	expect(d.journal.has("e31") and d.hud._text == d._descriptions.text("e31", "settled"), "completed creature records the registry's settled description")
	expect(d._inspection_at(Vector2(-100, -100)) == "", "empty background remains click-to-walk rather than generic inspection")
	d.free()
	var c = load("res://scenes/cosmos.tscn").instantiate()
	root.add_child(c)
	c.hud.dismiss_intro()
	c.record("inscriptions_vii")
	c.record("inscriptions_viii")
	expect(c.journal.size() == 2, "Cosmos inscriptions with identical display names journal independently by ID")
	c.free()
	print("DESCRIPTION REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
