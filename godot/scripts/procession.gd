## Spells 1-15: the funeral procession (Lepsius, Todtenbuch pl. I-VI).
##
## World coordinates are pixels of the strip (assets/procession/strip.png), which reads right
## to left: the player starts at the head of plate I (far right) and walks left. The strip is
## art/procession1-15.mdp as drawn; positions come from assets/procession/level.json, written by
## tools/cut_procession300.py.
extends Node2D

const DATA_PATH := "res://assets/procession/level.json"
const BESIDE := 70.0         ## stand just behind (right of) what you interact with, not on top of it
const HIT_PAD := 20.0

## Movable pieces and how the scribe names them.
const NAMES := {
	"ox": "the ox", "calf": "the calf",
	"emb_e1": "the jackal standard", "emb_e2": "the ibis standard",
	"emb_e3": "the falcon standard", "emb_e4": "the bull standard",
	"emb_e5": "the vulture standard", "emb_e6": "the placenta standard",
	"emb_e7": "the plumes standard", "emb_e8": "the falcon standard",
}

## Standards that are the same god: either may stand on either pole.
const SAME := {"emb_e8": "emb_e3"}

## Places a piece can go. `home` is the piece that belongs there; `kind` stops the
## player putting an ox on a pole.
const SLOTS := {
	"yoke":  {"kind": "beast", "home": "ox",      "label": "the sledge yoke"},
	"pen":   {"kind": "beast", "home": "calf",    "label": "the place behind the plumed ox"},
	"pole1": {"kind": "std",   "home": "emb_e1",  "label": "the first standard-bearer"},
	"pole2": {"kind": "std",   "home": "emb_e2",  "label": "the second standard-bearer"},
	"pole3": {"kind": "std",   "home": "emb_e3",  "label": "the third standard-bearer"},
	"pole4": {"kind": "std",   "home": "emb_e4",  "label": "the fourth standard-bearer"},
	"pole5": {"kind": "std",   "home": "emb_e5",  "label": "the fifth standard-bearer"},
	"pole6": {"kind": "std",   "home": "emb_e6",  "label": "the sixth standard-bearer"},
	"pole7": {"kind": "std",   "home": "emb_e7",  "label": "the seventh standard-bearer"},
	"pole8": {"kind": "std",   "home": "emb_e8",  "label": "the eighth standard-bearer"},
}

## The disorder the player finds: calf and ox swapped, standards deranged (and the offering
## table collapsed, with the goose-bearer holding a loaf: see offering_table.gd).
const START := {
	"yoke": "calf", "pen": "ox",
	"pole1": "emb_e6", "pole2": "emb_e1", "pole3": "emb_e7", "pole4": "emb_e5",
	"pole5": "emb_e3", "pole6": "emb_e8", "pole7": "emb_e4", "pole8": "emb_e2",
}
const POLES := ["pole1", "pole2", "pole3", "pole4", "pole5", "pole6", "pole7", "pole8"]

## The plumed lector's recital: each sign fades in after the one before, the line stays a
## while, then fades away.
const RECITE_STEP := 0.55
const RECITE_FADE_IN := 0.3
const RECITE_HOLD := 4.0
const RECITE_FADE_OUT := 0.8

const INK := Color(0.18, 0.11, 0.06)
const HOVER := Color(0.64, 0.2, 0.12, 0.55)  ## only for the `--show-hits` dev outlines
const HOVER_SLOT := Color(0.3, 0.42, 0.16, 0.7)
const REACH := 260.0         ## at the table you can reach this far without walking (strip px)

var level: Dictionary
var ground := 248.0          ## feet line inside the strip (from level.json)
var unit := 1.0              ## strip pixels per 200-dpi plate pixel: distances below are in plate pixels
var sprite_rects := {}       ## piece -> Rect2 (where it sits on the original plate)
var hotspots: Array = []     ## [{rect, label, note}]
var wall_x := 0.0
var start_x := 0.0

# state
var slot := {}               ## slot id -> piece ("" = empty)
var held := ""
var held_from := ""
var solved := {"t1": false, "t2": false, "t3": false, "t4": false}
var finished := false
var journal: Array[String] = []

var _pieces := {}            ## piece -> Sprite2D
var _base := {}              ## piece -> resting position (set in _render)
var _hover := {}
var _dust: Array = []
var _time := 0.0
var _table := {}
var _reader := {}            ## the lector beside the table, who shows what can be stacked next
var _lector := {}            ## the plumed lector in plate V, who recites the standards
var _bearer_rect: Rect2      ## the goose-bearer beside the lector
var offerings: OfferingTable
var _recital: Node2D
var _recital_tween: Tween
var _show_hits := false

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	ground = level.get("ground", ground)
	unit = level.get("scale", 1.0)
	avatar.speed *= unit
	avatar.bob_height *= unit
	$Papyrus.size = Vector2(level.width + 4000.0, level.height + 1600.0)
	for piece in level.sprites:
		var s: Dictionary = level.sprites[piece]
		sprite_rects[piece] = Rect2(s.x, s.y, s.w, s.h)
	for h in level.hotspots:
		hotspots.append({"rect": Rect2(h.x, h.y, h.w, h.h), "label": h.label, "note": h.note})
		if h.label == "Lector priest":
			_reader = hotspots[-1]
		elif h.label == "Offering table":
			_table = hotspots[-1]
		elif h.label == "Lector with plumes":
			_lector = hotspots[-1]
	wall_x = level.plates.III.x + 6.0 * unit
	start_x = sprite_rects.avatar.get_center().x

	for piece in NAMES:
		var p := _make_sprite(piece)
		$Pieces.add_child(p)
		_pieces[piece] = p
	_recital = Node2D.new()
	$Pieces.add_child(_recital)
	var b: Dictionary = level.slots.arms
	_bearer_rect = Rect2(b.x, b.y, b.w, b.h)
	offerings = OfferingTable.new()
	$Pieces.add_child(offerings)
	offerings.setup(level.table, sprite_rects.goose, sprite_rects.clothes, ground, "res://assets/procession/%s.png")
	offerings.changed.connect(_on_offerings_changed)

	overlay.draw.connect(_draw_overlay)
	hud.setup(self, {
		"title": "The Funeral Procession",
		"subtitle": "Spells 1–15 · Lepsius, Todtenbuch, pl. I–VI",
		"rites_heading": "RITES OF THE PROCESSION",
		"tasks": [
			"Set the right beast to haul the sledge",
			"Return each standard to its bearer",
			"Rebuild the offering table",
			"Give the goose back to its bearer",
		],
		"journal_hint": "Click figures in the scroll to record them here.",
		"intro_title": "Spells 1–15: The Funeral Procession",
		"intro_body": "The mummy must be dragged to the tomb. But the procession has fallen into disorder: the wrong beast is yoked to the sledge, the gods' standards are on the wrong poles, and the great offering table has collapsed.\n\n"
			+ "The scroll reads [b]right to left[/b]. Click the papyrus to walk, or use ← →. Click figures to record them in your journal. Click movable pieces to pick them up, and click where they belong to set them down. Clicking a filled place swaps the two. Esc puts a piece back.\n\n"
			+ "[i]Every figure is cut directly from Lepsius's 1842 plates; nothing is redrawn.[/i]",
		"outro_title": "The procession reaches the tomb",
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	hud.minimap_clicked.connect(func(x): walk_then(x))
	reset()
	_maybe_run_cli()


func reset() -> void:
	slot = START.duplicate()
	held = ""
	held_from = ""
	solved = {"t1": false, "t2": false, "t3": false, "t4": false}
	finished = false
	journal.clear()
	_clear_recital()
	offerings.reset()
	avatar.stop()
	avatar.position = Vector2(start_x, ground)
	avatar.facing = -1
	hud.reset_view()
	say("Scribe", "The procession has stalled at the head of the scroll. Walk left (the scroll reads right to left) and see what is wrong.")
	_render()
	_update_camera(1.0)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking():
		return
	if event.is_action_pressed("ui_cancel"):
		if offerings.holding() != "":
			offerings.put_back()
		else:
			put_back()
	elif event is InputEventMouseMotion:
		var h := _pick(get_global_mouse_position())
		if h != _hover:
			_hover = h
			overlay.queue_redraw()
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if h else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		var h := _pick(p)
		if offerings.holding() != "" and h.get("type") != "bearer" and offerings.in_zone(p):
			_at_table(p.x, func(): _drop_offering(p))
		elif h.is_empty():
			walk_then(p.x)
		elif h.type == "piece":
			_at_table(p.x, _take_offering.bind(h.id))
		elif h.type == "bearer":
			walk_then(_bearer_rect.get_center().x + BESIDE * unit, _act_bearer)
		elif h.type == "slot":
			var home: Rect2 = sprite_rects[SLOTS[h.id].home]
			walk_then(home.get_center().x + BESIDE * unit, act_slot.bind(h.id))
		else:
			walk_then(h.spot.rect.get_center().x + BESIDE * unit, record.bind(h.spot))


## What is under the pointer: a loose offering, the goose-bearer, a placed piece or slot, then
## a journal hotspot.
func _pick(p: Vector2) -> Dictionary:
	var off := offerings.pick(p)
	if off != "":
		return {"type": "piece", "id": off}
	if _bearer_rect.has_point(p):
		return {"type": "bearer", "rect": _bearer_rect}
	for id in slot:
		var piece: String = slot[id]
		if piece != "" and _pieces[piece].visible and Rect2(_pieces[piece].position, sprite_rects[piece].size).has_point(p):
			return {"type": "slot", "id": id, "rect": Rect2(_pieces[piece].position, sprite_rects[piece].size)}
	for id in SLOTS:
		var r := _slot_hit_rect(id)
		if r.has_point(p):
			return {"type": "slot", "id": id, "rect": r}
	for h in hotspots:
		if h.rect.has_point(p):
			return {"type": "hot", "spot": h, "rect": h.rect}
	return {}


func _slot_hit_rect(id: String) -> Rect2:
	if level.has("slots") and level.slots.has(id):  # measured on the strip: the whole figure
		var r: Dictionary = level.slots[id]
		return Rect2(r.x, r.y, r.w, r.h)
	var home: Rect2 = sprite_rects[SLOTS[id].home]
	if SLOTS[id].kind == "std":  # the whole bearer, not just the small emblem
		return Rect2(home.position.x - HIT_PAD * unit, 0, home.size.x + HIT_PAD * unit * 2, ground)
	var r := home.grow(HIT_PAD * unit)
	r.end.y = minf(r.end.y, ground)  # not below the ground line
	return r


# ---------------------------------------------------------------- movement

## The whole scroll is open to walk.
func min_x() -> float:
	return 60.0 * unit


func max_x() -> float:
	return level.width - 60.0 * unit


func procession_moving() -> bool:
	return solved.t1 and solved.t2


## Walk toward x and run `then` on arrival.
func walk_then(x: float, then := Callable()) -> void:
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	avatar.walk_to(clampf(x, avatar.min_x, avatar.max_x), func():
		if then.is_valid():
			then.call())


## At the table you reach what you click; from further off you walk there first.
func _at_table(x: float, then: Callable) -> void:
	if absf(avatar.position.x - x) <= REACH * 1.0:
		avatar.stop()
		then.call()
	else:
		walk_then(x + BESIDE * unit, then)


# ---------------------------------------------------------------- puzzle rules

func _take_offering(id: String) -> void:
	if held != "":
		say("Scribe", "Your hands are full.")
		return
	if offerings.holding() != "":
		say("Scribe", "You are already carrying %s." % offerings.held_name())
		return
	offerings.take(id)


func _drop_offering(p: Vector2) -> void:
	var what := offerings.holding()
	match offerings.drop_at(p):
		"toppled":
			say("Scribe", "It slides off and falls: what it rests on is not there yet.")
		"dropped":
			if what == "goose":
				say("Scribe", "The goose is not an offering for this table. Its bearer is beside the lector.")


func _act_bearer() -> void:
	if held != "" and offerings.holding() == "":
		say("Scribe", "%s doesn't belong in his arms." % _cap(NAMES[held]))
		return
	match offerings.bearer_act():
		"took":
			say("Goose-bearer", "He hands you the loaf. It belongs on the offering table, and he is still missing his goose.")
		"gave":
			say("Goose-bearer", "He takes his goose back in his arms, as it is drawn.")
		"swapped":
			say("Goose-bearer", "He takes his goose and hands you the loaf. It belongs on the offering table.")
		"wrong":
			say("Scribe", "He has no use for that. It belongs on the offering table.")
		"empty":
			say("Scribe", "His arms are empty. He carried a goose; it must be among the fallen offerings.")
		"has_goose":
			say("Goose-bearer", "He carries his goose to the tomb.")


func _on_offerings_changed() -> void:
	_check()
	_render()


func act_slot(id: String) -> void:
	var s: Dictionary = SLOTS[id]
	var here: String = slot[id]
	if held == "":
		if here == "":
			say("Scribe", "This place is empty.")
			return
		held = here
		held_from = id
		slot[id] = ""
		say("Scribe", "You take %s from %s." % [NAMES[here], s.label])
	else:
		if kind_of(held) != s.kind:
			say("Scribe", "%s doesn't belong at %s." % [_cap(NAMES[held]), s.label])
			return
		slot[id] = held
		if here != "":
			say("Scribe", "You set %s at %s and take %s." % [NAMES[held], s.label, NAMES[here]])
		else:
			say("Scribe", "You set %s at %s." % [NAMES[held], s.label])
		if _god(held) == _god(s.home):
			_flash(_pieces[held])
		held = here
		held_from = id if here != "" else ""
	_check()
	_render()


## Which god a standard shows (the two falcons are the same god).
func _god(piece: String) -> String:
	return SAME.get(piece, piece)


func kind_of(piece: String) -> String:
	if piece == "ox" or piece == "calf":
		return "beast"
	return "std"


func put_back() -> void:
	if held == "":
		return
	if held_from != "" and slot[held_from] == "":
		slot[held_from] = held
		say("Scribe", "You put %s back." % NAMES[held])
	else:
		return
	held = ""
	held_from = ""
	_check()
	_render()


func _check() -> void:
	var was := solved.duplicate()
	solved.t1 = slot.yoke == "ox" and slot.pen == "calf"
	solved.t2 = POLES.all(func(p): return _god(slot[p]) == _god(SLOTS[p].home))
	solved.t3 = offerings.complete()
	solved.t4 = offerings.goose_returned()
	if solved.t1 and not was.t1:
		say("Ox-driver", "Now the sledge moves! The ox leans into the rope and the calf trots behind the plumed ox.")
		_kick_dust(sprite_rects.ox)
	if solved.t2 and not was.t2:
		say("Standard-bearers", "Each god rides again on its own pole: jackal, ibis, falcon, bull, vulture, placenta, plumes and falcon. The way ahead is clear.")
	if procession_moving() and not (was.t1 and was.t2):
		get_tree().create_timer(1.6).timeout.connect(func():
			say("Scribe", "The procession lurches forward."))
	if solved.t3 and not was.t3:
		say("Scribe", "The offerings are heaped again under the palm frond, as they are drawn.")
	if solved.values().all(func(v): return v) and not was.values().all(func(v): return v):
		get_tree().create_timer(1.2).timeout.connect(finish)


## Clicking a figure: record it in the journal, and run the figures that do something.
func record(h: Dictionary) -> void:
	if h == _lector:  # no words, only the signs he reads out
		_add_journal(h)
		recite()
		return
	if h == _reader:  # he shows, in front of him, an offering that can go on now
		_add_journal(h)
		offerings.speak()
		return
	var who: String = h.label
	var text: String = h.note
	if h == _table and not solved.t3:
		who = "Scribe"
		text = "The offering table has collapsed. Only a few loaves, a small head and a pomegranate still stand; everything else lies on the floor between the bouquets."
	say(who, text)
	_add_journal(h)


func _add_journal(h: Dictionary) -> void:
	if h.label in journal:
		return
	journal.append(h.label)
	var tex := AtlasTexture.new()
	tex.atlas = $Strip.texture
	tex.region = h.rect
	hud.add_journal_entry(h.label, h.note, tex, journal.size(), hotspots.size())


func finish() -> void:
	if finished:
		return
	finished = true
	_render()
	say("Lector priest", "The procession has arrived. Let the mouth be opened.")
	var body := "The sledge is hauled, the standards are raised, the offerings are heaped again and the goose-bearer has his goose.\n\n" \
		+ "Next scene: [b]Spell 15, arrival at the tomb[/b].\n\n" \
		+ "[i]Journal: %d of %d figures recorded.[/i]" % [journal.size(), hotspots.size()]
	get_tree().create_timer(0.9).timeout.connect(func(): hud.show_outro(body))


func hint() -> void:
	if not solved.t1:
		if avatar.position.x > sprite_rects.ox.end.x + 400.0 * unit:
			say("Hint", "Walk left to the mummy's sledge. Look at the animal hauling it: is it big enough?")
		else:
			say("Hint", "The sledge needs a full-grown ox. Pick up the calf, then find where a calf belongs: further left, behind the plumed ox. Pick up an animal and its proper place shows faintly.")
	elif not solved.t2:
		say("Hint", "The eight bearers with gods on their heads have the wrong standards. The lector with two plumes on his head, beyond the offering table, reads out their order. Take a standard off and the empty pole shows a faint outline of the one that belongs there.")
	elif not solved.t3:
		say("Hint", "The offering table has collapsed. Pick up an offering and set it down where it belongs (its place shows faintly while you carry it). The lowest go first: anything set on a missing piece falls off. Click the lector beside the table and he shows one that can go on now.")
	else:
		say("Hint", "The man beside the lector holds a loaf instead of his goose. Take the loaf, and find his goose among the fallen offerings.")


func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


func say(who: String, text: String) -> void:
	hud.say(who, text)


# ---------------------------------------------------------------- per-frame

func _process(delta: float) -> void:
	_time += delta
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	_animate_struggle(delta)

	for d in _dust:
		d.pos += d.vel * delta
		d.life -= delta
	_dust = _dust.filter(func(d): return d.life > 0.0)

	_update_camera(delta)
	hud.update_minimap(avatar.position.x, _visible_rect(), wall_x, false)
	hud.update_held(held, _pieces[held].texture if held != "" else null, camera.zoom.x)
	overlay.queue_redraw()


## Fit the scene's height into the space between the HUD bars; keep at least ~1000 px of
## scroll visible on narrow windows.
func _update_camera(delta: float) -> void:
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var z := clampf(minf((vp.y - top - bottom - 10.0) / _view_height(), vp.x / (1000.0 * unit)), 0.4 / unit, 2.4 / unit)
	camera.zoom = Vector2(z, z)
	var vis_w := vp.x / z
	var target_x := avatar.position.x - vis_w * 0.05
	target_x = clampf(target_x, vis_w / 2.0, maxf(vis_w / 2.0, level.width - vis_w / 2.0))
	var k := 1.0 if delta >= 1.0 else 1.0 - pow(0.001, delta)
	camera.position.x = lerpf(camera.position.x, target_x, k)
	camera.position.y = _view_height() / 2.0 + (bottom - top) / 2.0 / z


## Rows the camera fits on screen: the strip plus the visible part of the faded text below.
func _view_height() -> float:
	return level.get("view_height", level.height)


func _visible_rect() -> Rect2:
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)


# ---------------------------------------------------------------- drawing

func _render() -> void:
	for p in _pieces.values():
		p.visible = false
	for id in SLOTS:
		var piece: String = slot[id]
		if piece == "":
			continue
		var home: Rect2 = sprite_rects[SLOTS[id].home]
		var size: Vector2 = sprite_rects[piece].size
		var x := home.get_center().x - size.x / 2.0
		if id == "pen":
			x = maxf(wall_x + 8.0 * unit, x)  # the big ox must not spill into plate IV
		var base := home.end.y if SLOTS[id].kind == "std" else ground
		_pieces[piece].position = Vector2(x, base - size.y)
		_pieces[piece].visible = true
		_base[piece] = _pieces[piece].position
	hud.update_tasks([solved.t1, solved.t2, solved.t3, solved.t4])
	if offerings.holding() != "":
		hud.update_hand(offerings.holding(), offerings.held_name(), offerings.held_texture())
	else:
		hud.update_hand(held, NAMES.get(held, ""), _pieces[held].texture if held != "" else null)


func _draw_overlay() -> void:
	if _show_hits:  # dev: `--show-hits` outlines every click region
		for id in SLOTS:
			overlay.draw_rect(_slot_hit_rect(id), HOVER_SLOT, false, 3.0)
		for h in hotspots:
			overlay.draw_rect(h.rect, HOVER, false, 3.0)
	for d in _dust:
		overlay.draw_circle(d.pos, 3.0 * unit, Color(0.79, 0.66, 0.41, clampf(d.life, 0.0, 1.0)))


## The calf in the ox's place strains at the rope, gains a little, and slips back: it is too
## small to move the sledge.
func _animate_struggle(delta: float) -> void:
	var calf: Sprite2D = _pieces.calf
	if slot.yoke != "calf" or not _base.has("calf") or held == "calf":
		calf.rotation = 0.0
		return
	var period := 2.4
	var p := fmod(_time, period) / period
	var pull := 0.0   # 0..1, how far it has strained forward
	if p < 0.65:
		pull = ease(p / 0.65, 0.4)                  # slow heave forward
	elif p < 0.78:
		pull = 1.0 - ease((p - 0.65) / 0.13, 2.4)   # slips back
	var scrabble := sin(_time * 38.0) * 1.5 * unit * pull   # hooves scrabbling
	calf.position = _base.calf + Vector2(-9.0 * unit * pull + scrabble, absf(scrabble) * 0.6)
	# lean into the rope: tilt about the front hooves (the calf faces left)
	calf.rotation = -0.05 * pull
	calf.position += Vector2(0, sprite_rects.calf.size.y * 0.05 * pull)
	if p >= 0.65 and p - delta / period < 0.65:   # dust where it slips
		var r := Rect2(calf.position, sprite_rects.calf.size)
		for i in 6:
			_dust.append({
				"pos": Vector2(r.position.x + randf() * r.size.x, ground - 4.0 * unit),
				"vel": Vector2(randf_range(5.0, 30.0), randf_range(-25.0, -10.0)) * unit,
				"life": randf_range(0.4, 0.7),
			})


func _kick_dust(r: Rect2) -> void:
	for i in 16:
		_dust.append({
			"pos": Vector2(r.position.x + randf() * r.size.x, ground - 4.0 * unit),
			"vel": Vector2(randf_range(-35.0, 15.0), randf_range(-40.0, -20.0)) * unit,
			"life": randf_range(0.6, 1.1),
		})


func _flash(node: CanvasItem) -> void:
	var t := create_tween()
	node.modulate = Color(1.8, 1.4, 0.6)
	t.tween_property(node, "modulate", Color.WHITE, 1.0)


## The plumed lector reads out the standards in the order they walk, jackal first. The signs
## face left like him, so the line begins at its left end (as Egyptian text begins on the
## side its signs face) and fills back toward him, ending in front of his plumes.
func recite() -> void:
	_clear_recital()
	var r: Dictionary = level.recital
	var signs: Array = POLES.map(func(p): return SLOTS[p].home)
	var tallest := 0.0
	var widths := 0.0
	for piece in signs:
		tallest = maxf(tallest, sprite_rects[piece].size.y)
		widths += sprite_rects[piece].size.x
	var s: float = (r.bottom - r.top) / tallest
	var gap := 6.0 * unit
	var x: float = r.right - widths * s - gap * (signs.size() - 1)
	_recital_tween = create_tween()
	for i in signs.size():
		var size: Vector2 = sprite_rects[signs[i]].size * s
		var glyph := Sprite2D.new()
		glyph.texture = _pieces[signs[i]].texture
		glyph.centered = false
		glyph.scale = Vector2(s, s)
		glyph.position = Vector2(x, r.bottom - size.y)  # on one baseline, like a line of text
		glyph.modulate.a = 0.0
		_recital.add_child(glyph)
		x += size.x + gap
		if i > 0:
			_recital_tween.tween_interval(RECITE_STEP - RECITE_FADE_IN)
		_recital_tween.tween_property(glyph, "modulate:a", 1.0, RECITE_FADE_IN)
	_recital_tween.tween_interval(RECITE_HOLD)
	_recital_tween.tween_property(_recital, "modulate:a", 0.0, RECITE_FADE_OUT)
	_recital_tween.tween_callback(_clear_recital)


func _clear_recital() -> void:
	if _recital_tween and _recital_tween.is_valid():
		_recital_tween.kill()
	for c in _recital.get_children():
		c.queue_free()
	_recital.modulate.a = 1.0


func _make_sprite(piece: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://assets/procession/%s.png" % piece)
	s.centered = false
	return s


# ---------------------------------------------------------------- command line

## `-- --autotest` solves the level through the same rules the player uses and prints the
## result. `-- --screenshot=path.png` saves a frame after start-up and quits; `--recite` shows
## the plumed lector's whole line of signs at once, `--speak` has the lector beside the table show
## a piece, and `--wait` lets the fallen offerings settle (about 5 s) before the screenshot.
func _maybe_run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_autotest()
	for a in args:  # dev helpers: `--at=4300` starts the avatar there, `--take=yoke` lifts that slot's piece
		if a.begins_with("--at="):
			avatar.position.x = a.trim_prefix("--at=").to_float()
			_update_camera(1.0)
		elif a == "--show-hits":
			_show_hits = true
		elif a.begins_with("--take="):
			act_slot(a.trim_prefix("--take="))
		elif a == "--recite":
			recite()
			_recital_tween.custom_step(RECITE_STEP * POLES.size())
		elif a == "--speak":
			offerings.speak()
	for a in args:
		if a.begins_with("--screenshot="):
			hud.dismiss_intro()
			for i in (300 if "--wait" in args else 30):
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


func _autotest() -> void:
	var fails: Array[String] = []   # lambdas capture locals by value, so collect into an array
	var expect := func(cond: bool, what: String):
		print(("PASS " if cond else "FAIL ") + what)
		if not cond:
			fails.append(what)
	expect.call(not _lector.is_empty(), "plumed lector found in plate V")
	expect.call(min_x() < _lector.rect.position.x, "the lector in plate V can be reached from the start")
	record(_lector)
	var shown: Array = _recital.get_children().map(func(c): return c.texture)
	var order: Array = POLES.map(func(p): return _pieces[SLOTS[p].home].texture)
	expect.call(shown == order, "lector recites the eight standards in order, jackal first")
	var xs: Array = _recital.get_children().map(func(c): return c.position.x)
	var sorted := xs.duplicate()
	sorted.sort()
	expect.call(xs == sorted and xs[-1] < level.recital.right, "his line runs left to right and ends in front of him")
	# a click in the middle of every slot and journal region picks exactly that region (unless a
	# fallen offering lies over it)
	var missed: Array[String] = []
	for id in SLOTS:
		var h := _pick(_slot_hit_rect(id).get_center())
		if h.get("type") != "slot" or h.id != id:
			missed.append(id)
	for spot in hotspots:
		var h := _pick(spot.rect.get_center())
		if h.get("type") == "piece":
			continue
		if h.get("type") != "hot" or h.spot != spot:
			missed.append(spot.label)
	expect.call(missed.is_empty(), "every region picked by a click at its centre %s" % [missed])
	act_slot("yoke"); act_slot("pen"); act_slot("yoke")
	expect.call(solved.t1, "ox hitched, calf behind the plumed ox")
	for p in POLES:  # lift a wrong standard, carry each one home, until the first pole is filled
		if _god(slot[p]) == _god(SLOTS[p].home):
			continue
		act_slot(p)
		var guard := 0
		while held != "" and guard < 20:
			guard += 1
			for q in POLES:
				if _god(SLOTS[q].home) == _god(held) and (slot[q] == "" or _god(slot[q]) != _god(SLOTS[q].home)):
					act_slot(q)
					break
	expect.call(solved.t2, "all eight standards on their own poles")
	expect.call(held == "", "hand empty after sorting the standards")
	act_slot("yoke")
	act_slot("pole1")
	expect.call(held == "ox", "can't put an ox on a pole")
	put_back()
	_autotest_table(expect)
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)


func _autotest_table(expect: Callable) -> void:
	expect.call(not offerings.pieces.is_empty(), "the offering table has loose pieces (%d)" % offerings.pieces.size())
	expect.call(not offerings.stackable().is_empty(), "something can be stacked at the start")
	var high := ""
	for id in offerings.pieces:
		if offerings.pieces[id].kind == "loose" and not offerings.pieces[id].rests_on.is_empty():
			high = id
			break
	offerings.take(high)
	expect.call(offerings.holding() == high, "a fallen piece can be picked up")
	var r := offerings.drop_at(offerings.pieces[high].rect.get_center())
	expect.call(r == "toppled" and not offerings.placed.has(high), "a piece set on a missing one falls off")
	record(_reader)
	var shown := offerings.speaking()
	expect.call(shown != "" and offerings.can_place(shown), "the lector beside the table shows a piece that can go on now")
	expect.call(not offerings.clothes_showing(), "the loaf in his arms covers his clothes")
	_act_bearer()
	expect.call(offerings.holding() != "" and offerings.pieces[offerings.holding()].kind == "held", "the goose-bearer hands over his loaf")
	expect.call(offerings.clothes_showing(), "with his arms empty his clothes show")
	offerings.put_back()
	expect.call(offerings.bearer != "" and offerings.holding() == "", "Esc gives the loaf back to him")
	var frond_early := false
	var guard := 0
	while not offerings.complete() and guard < 200:
		guard += 1
		var can := offerings.stackable()
		if can.is_empty():
			break
		var id: String = can[0]
		if offerings.pieces[id].kind == "frond" and offerings.placed.size() < offerings.pieces.size() - 1:
			frond_early = true
		if offerings.bearer == id:
			_act_bearer()
		else:
			offerings.take(id)
		offerings.drop_at(offerings.pieces[id].rect.get_center())
	expect.call(offerings.complete() and solved.t3, "the table rebuilt, lowest pieces first")
	expect.call(not frond_early, "the palm frond goes on last")
	offerings.take("goose")
	_act_bearer()
	expect.call(solved.t4, "the goose is back with its bearer")
	expect.call(not offerings.clothes_showing(), "the goose covers his clothes again")
	expect.call(solved.values().all(func(v): return v), "all four rites done")
