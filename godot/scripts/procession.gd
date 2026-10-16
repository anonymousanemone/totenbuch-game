## Spells 1-15: the funeral procession (Lepsius, Todtenbuch pl. I-VI).
##
## World coordinates are pixels of the strip (assets/procession/strip.png), which reads right
## to left: the player starts at the head of plate I (far right) and walks left. The strip is
## art/procession1-15.mdp as drawn. Saved nodes own piece placement; level.json, exported by
## tools/cut_procession300.py, retains source-art data, descriptions and interaction geometry.
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const VIEW_TOP := 36.0   ## the row under the top register's upper rule: the title bar's band takes its place
## Zoomed out (at the table, the standards, the water), the top guideline stays flush under the
## title bar and more of the text below shows. false: the scene stays centred between the bars.
## (At the usual zoom the two are the same.)
const FRAME_FROM_TOP := true
const DATA_PATH := "res://assets/procession/level.json"
const BESIDE := 70.0         ## stand just behind (right of) what you interact with, not on top of it
const STAND_GAP := 6.0       ## plate px between you and a figure you walk up to (never overlapping it)
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

## Places a piece can go: the standard-bearers' poles. `home` is the standard that belongs there.
const SLOTS := {
	"pole1": {"kind": "std",   "home": "emb_e1",  "label": "the first standard-bearer"},
	"pole2": {"kind": "std",   "home": "emb_e2",  "label": "the second standard-bearer"},
	"pole3": {"kind": "std",   "home": "emb_e3",  "label": "the third standard-bearer"},
	"pole4": {"kind": "std",   "home": "emb_e4",  "label": "the fourth standard-bearer"},
	"pole5": {"kind": "std",   "home": "emb_e5",  "label": "the fifth standard-bearer"},
	"pole6": {"kind": "std",   "home": "emb_e6",  "label": "the sixth standard-bearer"},
	"pole7": {"kind": "std",   "home": "emb_e7",  "label": "the seventh standard-bearer"},
	"pole8": {"kind": "std",   "home": "emb_e8",  "label": "the eighth standard-bearer"},
}

## The disorder the player finds: the mummy's sledge stalled (see haul.gd), standards deranged,
## the offering table collapsed, with the goose-bearer holding a loaf (see offering_table.gd), the
## priest's jar upright with no water running from it (see pour_water.gd), the mummy's mouth
## closed and the words over Ra gone (see opening_mouth.gd), and the offering stand before Ra
## gone, its pieces hidden along the scroll (see ending.gd).
const START := {
	"pole1": "emb_e6", "pole2": "emb_e1", "pole3": "emb_e7", "pole4": "emb_e5",
	"pole5": "emb_e3", "pole6": "emb_e8", "pole7": "emb_e4", "pole8": "emb_e2",
}
const POLES := ["pole1", "pole2", "pole3", "pole4", "pole5", "pole6", "pole7", "pole8"]
## Pieces that stay where they are drawn (the ox walks with the hauling, see haul.gd).
const FIXED := ["ox", "calf"]
## Only the ox-driver starts hauling; the other figures direct the player to him.
const HAUL_FIGURES := ["Hauler", "Ox-driver", "The funerary bier"]
const INTO_POSE := 0.5        ## s for you to fade into the hauler's pose on the rope (and out again)
const HAUL_AHEAD := 200.0     ## plate px of the road ahead of the ox the camera shows while hauling
## The figures round the purifying water (plate V); clicking one steps up to the jar until the
## water runs as drawn.
const WATER_FIGURES := ["Priest with jar", "Kneeling woman", "Anubis and the mummy"]

## The plumed lector's recital: one sign at a time over his sheet, each fading in, held,
## and fading as the next comes.
const RECITE_STEP := 1.1     ## s from one sign to the next
const RECITE_FADE_IN := 0.25
const RECITE_FADE_OUT := 0.25


const INK := UI.INK
const HOVER := Color(0.64, 0.2, 0.12, 0.55)  ## only for the `--show-hits` dev outlines
const HOVER_SLOT := Color(0.3, 0.42, 0.16, 0.7)
const DRAG := 8.0            ## screen px: let go further than this from where you took it and it is set down there
const SCENE_MARGIN := 40.0   ## strip px of papyrus kept either side of the table scene
const GLOW_FADE := 0.15      ## s for the hover glow to come and go
const GLOW := UI.Glow.PROCESSION
const REFOCUS := 0.8         ## s for the camera to ease to a new focus (the table, the standards, the water, the rope)
const CAPTION_LINE := 187.0  ## first row below the frame line over the figures: glows start here
## The captions in the top register, between its frame lines (rows): the titles of the spells, from
## C. H. S. Davis, The Egyptian Book of the Dead (1894), which translates this papyrus. Clicking one
## shows it. (The third title of spell 15, over Ra, is the Opening of the Mouth's words: not here.)
const CAPTION_ROWS := Vector2(50.0, 178.0)
const CAPTIONS := [
	{"spell": 1, "x": [13275, 14878], "title": "Beginning of the chapters about the going forth by day and the carrying of the shades into the Netherworld."},
	{"spell": 1, "x": [10164, 13275], "title": "To be said on the day of burial (in order to) go in after coming forth."},
	{"spell": 15, "x": [3819, 4730], "title": "Adoration to Ra when he rises above the eastern horizon in Heaven."},
	{"spell": 15, "x": [2166, 2752], "title": "Adoration to the sun when it sets in the Land of Life."},
]
## Figures whose arm turns in code (see haul.gd, pour_water.gd): their Journal picture is the frame
## as drawn of their (hand-drawn) sheet, each frame the whole figure.
const SHEETS := {"haul_driver": "haul_driver_sheet", "water_priest": "water_sheet"}
## Journal figures that are sprites of the hauling now: they glow as those drawings.
const HAUL_GLOW := {"Hauler": ["haul_hauler"], "Ox-driver": ["haul_driver", "haul_driver_arm"]}
## Journal figures that are pieces (sprites, not in the strip): they glow as those drawings.
const PIECE_GLOW := {"Ox": "ox", "Calf": "calf"}
## Figures drawn inside the sledge sprite (with its rope and the censer priest): each glows as its
## own part of that drawing, and moves with it.
const SLEDGE_PARTS := ["The funerary bier", "Priest with censer"]

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
var solved := {"t1": false, "t2": false, "t3": false, "t4": false, "t5": false, "t6": false, "t7": false}
var finished := false
var journal: Array[String] = []

var _generation := 0
var _authored := {}          ## stable piece ID -> saved scene node
var _pieces := {}            ## piece -> Sprite2D
var _hover := {}
var _seats := {}             ## standard -> where it sits on its pole (sprite px): see _seat()
var _glows: Array = []       ## the glows behind what is under the pointer
var in_standards := false
var _standards_view := Vector2.ZERO
var _hauling := false        ## you hold the rope in the hauler's place
var in_table := false        ## at the offering table: the camera holds on it, you work with the pieces
var _drag_from := Vector2.INF  ## where (screen px) the piece in hand was taken up, while the button is down
var _hint_step := {}
var _feedback := {}
var _table_told := false
var _focus := ""             ## what the camera holds on: "" (you), "table", "water", "standards" or "haul"
var _refocus := {}           ## an ease to a new focus under way: its start (zoom, x) and time
var _dust: Array = []
var _time := 0.0
var _table := {}
var _reader := {}            ## the lector beside the table, who shows what can be stacked next
var _lector := {}            ## the plumed lector in plate V, who recites the standards
var _bearer_rect: Rect2      ## the goose-bearer beside the lector
var offerings: OfferingTable
var haul: HaulSledge
var ending: EndingStand
var water: PourWater
var mouth: OpeningMouth
var _testing := false        ## the autotest: the ending does not leave the scene
var _strip_img: Image        ## the strip, for journal pictures of figures that are sprites now
var _recital: Node2D
var _recital_tween: Tween
var _show_hits := false
var _last_said := ""         ## the last line said, for the autotest

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
	for node in $pieces.find_children("*", "Node2D", true, false):
		if node.has_meta("piece_id"):
			var id: String = node.get_meta("piece_id")
			assert(not _authored.has(id), "Duplicate Procession piece ID: " + id)
			_authored[id] = node
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
	# part for whole: a figure lying inside another is picked first, so it glows alone; anywhere
	# else on the whole, the whole glows (the part with it)
	var parts := hotspots.filter(func(h): return hotspots.any(func(o): return o != h and o.rect.encloses(h.rect)))
	hotspots = parts + hotspots.filter(func(h): return not h in parts)
	wall_x = level.plates.III.x + 6.0 * unit
	start_x = avatar.position.x

	for piece in NAMES:
		var p: Sprite2D = _authored[piece]
		_pieces[piece] = p
		sprite_rects[piece] = Rect2(p.position, p.texture.get_size())
	_recital = $pieces/recital
	var b: Dictionary = level.slots.arms
	_bearer_rect = Rect2(b.x, b.y, b.w, b.h)
	offerings = $pieces/offering_table
	offerings.setup(level.table, sprite_rects.goose, ground, _authored)
	offerings.changed.connect(_on_offerings_changed)
	haul = $pieces/hauling
	haul.setup(_pieces.ox, $Papyrus.material, self, $Strip.get_index() + 1, _authored)
	haul.said.connect(say)
	haul.finished.connect(_check)
	ending = $pieces/ending
	ending.setup(level, _authored)
	ending.said.connect(say)
	ending.changed.connect(func():
		_check()
		_render())
	ending.ended.connect(_ended)
	water = $pieces/water
	water.setup(level, "res://assets/procession/%s.png", _authored)
	water.said.connect(say)
	water.finished.connect(_check)
	mouth = $pieces/opening_mouth
	mouth.setup(level, _authored)
	mouth.said.connect(say)
	mouth.changed.connect(func():
		_check()
		_render())

	overlay.draw.connect(_draw_overlay)
	hud.setup(self, {
		"title": "The Funeral Procession",
		"journal_hint": "Click figures in the scroll to record them here.",
		"intro_title": "Spells 1–15: The Funeral Procession",
		"intro_body": "The bier has stalled on its way to the tomb. Help put the procession in order.\n\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Click a figure to look or act. Each task explains its controls; Hint offers help.",
		"outro_title": "The procession reaches the tomb",
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	reset()
	_maybe_run_cli()


func reset() -> void:
	_generation += 1
	slot = START.duplicate()
	held = ""
	held_from = ""
	solved = {"t1": false, "t2": false, "t3": false, "t4": false, "t5": false, "t6": false, "t7": false}
	finished = false
	journal.clear()
	_clear_recital()
	offerings.reset()
	haul.reset()
	ending.reset()
	water.reset()
	mouth.reset()
	_set_hover({})
	in_table = false
	_table_told = false
	_hint_step.clear()
	_feedback.clear()
	_drag_from = Vector2.INF
	_hauling = false
	in_standards = false
	avatar.rotation = 0.0
	avatar.visible = true
	avatar.modulate = Color.WHITE
	avatar.keys = true
	avatar.set_process(true)
	avatar.stop()
	avatar.position = Vector2(start_x, ground)
	avatar.facing = -1
	hud.reset_view()
	say("Scribe", "The procession has stalled at the head of the scroll. Walk left (the scroll reads right to left) and see what is wrong.")
	_render()
	_update_camera(1.0)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or finished:
		return
	if in_standards and event.is_action_pressed("ui_cancel"):
		leave_standards()
		return
	if in_standards:    # with the standard-bearers: drag the standards; a click never walks you off
		_standards_input(event)
		return
	if haul.active:     # holding the rope: Space, Shift or a click pulls; Esc lets go
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]):
			haul.quit()
		elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_SHIFT]:
			haul.press()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			haul.press()
		get_viewport().set_input_as_handled()
		return
	if water.active:    # at the water: press on the jar and drag to tip it; Esc (or walking off) steps away
		if event.is_action_pressed("ui_cancel"):
			leave_water()
			get_viewport().set_input_as_handled()
		else:
			_water_input(event)
		return
	if in_table:        # at the offering table: Esc (or walking off with the arrow keys) steps away
		if event.is_action_pressed("ui_cancel"):
			leave_table()
			get_viewport().set_input_as_handled()
		else:
			_table_input(event)
		return
	if event is InputEventMouseMotion:
		_set_hover(_pick(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		var h := _pick(p)
		if h.is_empty():
			walk_then(p.x)
		elif h.type == "ending":
			walk_then(ending.where(h.id).x + BESIDE * unit, act_ending.bind(h.id))
		elif h.type == "bearer":   # the scene starts from the lector or the heap, not from him
			if offerings.bearer != "goose":
				say("Scribe", "Odd that he's holding a loaf of bread.")
		elif h.type == "piece" or (h.type == "hot" and (h.spot == _table or h.spot == _reader)):
			enter_table(h.get("spot", {}) == _reader)
		elif h.type == "mouth":
			act_mouth(h.id)
		elif h.type == "water" or (h.type == "hot" and h.spot.label in WATER_FIGURES and not water.done):
			enter_water(h.get("spot", {}))
		elif h.type == "caption":
			say("Spell %d" % h.spell, h.title)
		elif h.type == "slot":
			if solved.t2:
				say("Standard-bearers", "All eight standards are in order.")
			else:
				enter_standards()
		elif h.spot.label in HAUL_FIGURES and not haul.done:
			if h.spot.label == "Ox-driver":   # you walk to the hauler's place and take up his rope
				var hl: Dictionary = level.sprites.haul_hauler
				walk_then(hl.x + hl.w / 2.0, take_rope.bind(h.spot))
			else:
				walk_then(_beside(h.rect), say.bind(h.spot.label, h.spot.note + " The bier is stalled. Ask the ox-driver how to haul it."))
		elif h.spot.label == "Hauler":   # home: he has his rope again
			walk_then(_beside(h.spot.rect), func():
				say("Hauler", "You've helped the procession advance.")
				_add_journal(h.spot))
		elif h.spot == _lector:   # stand in front of him (he faces left), to hear him
			walk_then(h.spot.rect.position.x - STAND_GAP * unit - sprite_rects.avatar.size.x / 2.0, record.bind(h.spot))
		else:
			walk_then(_beside(h.spot.rect), record.bind(h.spot))


## What is under the pointer: a loose offering, a hidden piece of the offering stand or its place,
## the goose-bearer, a placed piece or slot, then a journal hotspot.
func _pick(p: Vector2) -> Dictionary:
	var off := offerings.pick(p)
	if off != "":
		return {"type": "piece", "id": off}
	var e := ending.pick(p)
	if e != "":
		return {"type": "ending", "id": e}
	var m := mouth.pick(p)
	if m != "":
		return {"type": "mouth", "id": m}
	if not water.active and water.on_jar(p):   # from along the scroll: step up to the water
		return {"type": "water"}
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
		if h.label == "Hauler" and not haul.hauler_shown():   # absent while exploring before the first haul
			continue
		if h.rect.has_point(p):
			return {"type": "hot", "spot": h, "rect": h.rect}
	var boat: Dictionary = level.sprites.haul_sledge
	if Rect2(boat.x + haul.offset, boat.y, boat.w, boat.h).has_point(p):
		var spot: Dictionary = hotspots.filter(func(h): return h.label == "The funerary bier")[0]
		return {"type": "hot", "spot": spot, "rect": Rect2(boat.x + haul.offset, boat.y, boat.w, boat.h)}
	for c in CAPTIONS:
		var r := Rect2(c.x[0], CAPTION_ROWS.x, c.x[1] - c.x[0], CAPTION_ROWS.y - CAPTION_ROWS.x)
		if r.has_point(p):
			return {"type": "caption", "spell": c.spell, "title": c.title, "rect": r}
	return {}


# ---------------------------------------------------------------- hover glow

## What is under the pointer glows (glow.gdshader), and the pointer becomes a hand.
func _set_hover(h: Dictionary) -> void:
	if h == _hover:
		return
	_hover = h
	for g in _glows:
		if is_instance_valid(g):
			var t := (g as Node).create_tween()
			t.tween_method(_glow_strength.bind(g), (g.material as ShaderMaterial).get_shader_parameter("strength"), 0.0, GLOW_FADE)
			t.tween_callback(g.queue_free)
	_glows.clear()
	for target in _glow_targets(h):
		var g := _glow(target)
		g.create_tween().tween_method(_glow_strength.bind(g), 0.0, 1.0, GLOW_FADE)
		_glows.append(g)
	overlay.queue_redraw()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if h else Input.CURSOR_ARROW)


## What glows for a pick: drawings that are sprites, or the strip under a figure's rect.
func _glow_targets(h: Dictionary) -> Array:
	match h.get("type", ""):
		"piece":
			var sp := offerings.sprite_of(h.id)
			return [sp] if sp else []
		"ending":   # a hidden piece glows; the empty place glows with what already stands there
			if h.id == "back":
				return []
			if h.id != "place":
				return [ending.sprite_of(h.id)]
			return [ending.place_rect()] + ending.placed.keys().map(func(nm): return ending.sprite_of(nm))
		"bearer":
			return [_bearer_rect] + offerings.bearer_sprites()
		"water":   # his forearm and jar
			return [water.arm_sprite()]
		"mouth":
			return [mouth.glow_target(h.id)]
		"caption":
			return [h.rect]
		"std":     # with the standard-bearers: only the standard under the pointer
			return [_pieces[slot[h.id]]]
		"slot":
			var out: Array = []
			for id in POLES:
				out.append(_slot_hit_rect(id))
				if slot[id] != "" and _pieces[slot[id]].visible:
					out.append(_pieces[slot[id]])
			return out
		"hot":
			if PIECE_GLOW.has(h.spot.label):
				return [_pieces[PIECE_GLOW[h.spot.label]]]
			if HAUL_GLOW.has(h.spot.label):
				return HAUL_GLOW[h.spot.label].map(func(nm): return haul.sprite_of(nm)).filter(func(sp): return sp != null and sp.is_visible_in_tree())
			if h.spot == _table and solved.t3:   # rebuilt: the whole table glows, its offerings with it
				return [h.spot.rect] + offerings.placed_sprites()
			if h.spot.label == "Offering stand":   # part for whole: the stand glows with all on it
				return [h.spot.rect] + mouth.on_stand()
			if h.spot.label in SLEDGE_PARTS:   # its own part of the sledge's drawing
				var home: Rect2 = sprite_rects.haul_sledge
				var r: Rect2 = h.spot.rect.intersection(home)
				return [{"sprite": haul.sprite_of("haul_sledge"), "region": Rect2(r.position - home.position, r.size)}]
			if h.spot.label == "Priest with jar":   # he is a sprite now, his arm with him
				return [water.priest_sprite(), water.arm_sprite()]
			return [h.spot.rect]
	return []


## A glow behind a sprite's drawing; behind the strip's drawing inside a rect; or behind part of a
## sprite's drawing ({sprite, region}). Its strength starts at 0.
func _glow(target, level := GLOW) -> Sprite2D:
	var g: Sprite2D
	if target is Dictionary:
		g = UI.part_glow(target.sprite, target.region, level)
	elif target is Rect2:
		var r: Rect2 = target
		if r.position.y < CAPTION_LINE and r.end.y > CAPTION_LINE:   # a figure: not the frame line above it
			r = Rect2(r.position.x, CAPTION_LINE, r.size.x, r.end.y - CAPTION_LINE)
		g = UI.part_glow($Strip, r, level)
	else:
		g = UI.sprite_glow(target as Sprite2D, level)
	return g


## A task done: what it set right glows pale green for a moment (targets as for _glow).
func _success(targets: Array) -> void:
	for target in targets:
		UI.flash_glow(_glow(target, UI.Glow.SUCCESS))


func _glow_strength(v: float, g: Sprite2D) -> void:
	(g.material as ShaderMaterial).set_shader_parameter("strength", v)


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
## Where you stop to deal with what is at `r`: a few px clear of it, on the side you come from.
func _beside(r: Rect2) -> float:
	var half: float = sprite_rects.avatar.size.x / 2.0
	if avatar.position.x < r.get_center().x:
		return r.position.x - STAND_GAP * unit - half
	return r.end.x + STAND_GAP * unit + half


func walk_then(x: float, then := Callable()) -> void:
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	avatar.walk_to(clampf(x, avatar.min_x, avatar.max_x), func():
		if then.is_valid():
			then.call())


# ---------------------------------------------------------------- the offering table scene

## Step up to the offering table: you stand just behind the lector and the camera holds on the
## table, from the man with the jar to the goose-bearer. `ask` has the lector show a piece at once.
func enter_table(ask := false) -> void:
	if in_table:
		return
	_set_hover({})
	walk_then(level.table.stand, func():
		_table_now()
		if ask:
			record(_reader))


func _table_now() -> void:
	in_table = true
	avatar.stop()
	avatar.facing = -1
	if not _table_told:
		_table_told = true
		say("Lector priest", "Can you help restore the offering table? Drag items to their rightful place. I can help you if you get lost.")


## Step away from the table (Esc, or walking off): what you hold goes back; nothing is lost.
func leave_table() -> void:
	if not in_table:
		return
	if offerings.holding() != "":
		offerings.put_back()
	_drag_from = Vector2.INF
	in_table = false
	_set_hover({})


## At the table: press on a piece to take it up; it follows the pointer. Let go after dragging,
## or click again, and it is set down there: in its place, in the band above, back to the
## goose-bearer, or onto the floor.
## At the table, the table itself (the scene you are in) is not something to point at.
func _table_pick(p: Vector2) -> Dictionary:
	var h := _pick(p)
	return {} if h.get("spot", {}) == _table else h


func _table_input(event: InputEvent) -> void:
	var p := get_global_mouse_position()
	if event is InputEventMouseMotion:
		_set_hover(_table_pick(p))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if offerings.holding() != "":
				_table_drop(p)
				return
			var h := _table_pick(p)
			match h.get("type", ""):
				"piece":
					_take_offering(h.id)
				"bearer":
					_act_bearer()
				"hot":
					record(h.spot)
			if offerings.holding() != "":
				_drag_from = event.position
				_set_hover({})
		else:
			if _drag_from != Vector2.INF and offerings.holding() != "" and event.position.distance_to(_drag_from) > DRAG:
				_table_drop(p)
			_drag_from = Vector2.INF


func _table_drop(p: Vector2) -> void:
	_drag_from = Vector2.INF
	if _bearer_rect.has_point(p):
		_act_bearer()
	elif offerings.in_header(p):
		offerings.park(p)
	else:
		_drop_offering(p)


# ---------------------------------------------------------------- the water

## Step up to the water: you stand behind the priest and the camera holds on the scene, from the
## stela's edge to his back. `h` is the figure clicked, recorded on arrival.
func enter_water(h := {}) -> void:
	if water.active or water.done:
		return
	if _hands_full():
		say("Scribe", _hands_message())
		return
	_set_hover({})
	walk_then(water.stand_x(), func():
		if not h.is_empty():
			_add_journal(h)
		_water_now())


func _water_now() -> void:
	avatar.stop()
	avatar.facing = -1
	water.enter()


## Step away from the water (Esc, or walking off): you let go of the jar.
func leave_water() -> void:
	if not water.active:
		return
	water.leave()
	_set_hover({})


## At the water: press on the jar to take hold of it, drag to tip it, let go to let it rise.
## At the water: hold Space to lift the priest's drooping arm.
func _water_input(event: InputEvent) -> void:
	var p := get_global_mouse_position()
	if event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		water.raising = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_set_hover(_pick(p))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := _pick(p)
		if h.get("type", "") == "hot":
			record(h.spot)


# ---------------------------------------------------------------- puzzle rules

func _take_offering(id: String) -> void:
	if held != "" or mouth.carrying() != "":
		say("Scribe", _hands_message())
		return
	if offerings.holding() != "":
		say("Scribe", "You are already carrying %s." % offerings.held_name())
		return
	offerings.take(id)


func _drop_offering(p: Vector2) -> void:
	var what := offerings.holding()
	match offerings.drop_at(p):
		"toppled":
			_tell_once("support", "It needs support. Place the lower offerings first.")
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
			if offerings.bearer == "" and offerings.held_from() == "bearer":
				offerings.put_back()
				say("Goose-bearer", "He takes the loaf back.")
			else:
				say("Scribe", "He has no use for that. It belongs on the offering table.")
		"empty":
			say("Scribe", "His arms are empty. He carried a goose; it must be among the fallen offerings.")
		"has_goose":
			say("Goose-bearer", "He carries his goose to the tomb.")


func _on_offerings_changed() -> void:
	_check()
	_render()


func enter_standards() -> void:
	var bounds := _slot_hit_rect(POLES[0])
	for id in POLES:
		bounds = bounds.merge(_slot_hit_rect(id))
	var left := bounds.position.x - 80.0 * unit
	var right := bounds.end.x + 80.0 * unit
	var stand := left if absf(avatar.position.x - left) < absf(avatar.position.x - right) else right
	walk_then(stand, func():
		avatar.stop()
		avatar.facing = 1 if stand == left else -1
		_standards_view = Vector2(left - 60.0 * unit, right + 60.0 * unit)
		in_standards = true
		say("Standard-bearers", "Can you help us? We carry each other's gods. Drag each standard to the bearer it belongs to."))


func leave_standards() -> void:
	put_back()
	in_standards = false
	_set_hover({})


func act_slot(id: String) -> void:
	var s: Dictionary = SLOTS[id]
	var here: String = slot[id]
	if solved.t2:   # in order: they stay so
		say("Standard-bearers", "All eight standards are in order.")
		return
	if mouth.carrying() != "":
		say("Scribe", _hands_message())
		return
	if held == "":
		if here == "":
			say("Scribe", "Take a standard from another bearer first.")
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
		if here != "" and held_from != "":   # the one there goes where yours came from
			slot[held_from] = here
			say("Scribe", "You set %s at %s; %s goes to %s." % [NAMES[held], s.label, NAMES[here], SLOTS[held_from].label])
		else:
			say("Scribe", "You set %s at %s." % [NAMES[held], s.label])
		if _god(held) == _god(s.home):
			_flash(_pieces[held])
		held = ""
		held_from = ""
	_check()
	_render()


## With the standard-bearers: drag a standard. Press on it to take it up; let go over any pole to
## set it there (it swaps with the one there), anywhere else and it goes back.
func _standards_input(event: InputEvent) -> void:
	var p := get_global_mouse_position()
	if event is InputEventMouseMotion:
		_set_hover(_standard_at(p) if held == "" else {})
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			var h := _standard_at(p)
			if held == "" and not h.is_empty():
				act_slot(h.id)
				_set_hover({})
		elif held != "":
			_drop_standard(p)


## The standard (its top: the emblem on the pole) under the pointer.
func _standard_at(p: Vector2) -> Dictionary:
	for id in POLES:
		if slot[id] != "":
			var r := Rect2(_pieces[slot[id]].position, sprite_rects[slot[id]].size).grow(6.0 * unit)
			if r.has_point(p):
				return {"type": "std", "id": id, "rect": r}
	return {}


## The pole whose top is near `p` (where a standard can be set down), or "".
func _pole_at(p: Vector2) -> String:
	for id in POLES:
		var home: Rect2 = sprite_rects[SLOTS[id].home]
		if Rect2(home.position.x - 30.0 * unit, home.position.y - 50.0 * unit, home.size.x + 60.0 * unit, home.size.y + 100.0 * unit).has_point(p):
			return id
	return ""


func _drop_standard(p: Vector2) -> void:
	var id := _pole_at(p)
	if id == "" or id == held_from:
		put_back(true)
	else:
		act_slot(id)


## Where a standard sits on its pole (sprite px): the bottom of its middle part, where it meets the
## stub (a streamer or tail may hang lower, beside it).
func _seat(piece: String) -> Vector2:
	if not _seats.has(piece):
		var img: Image = _pieces[piece].texture.get_image()
		var w := img.get_width()
		var seat := Vector2(w / 2.0, img.get_height())
		for y in range(img.get_height() - 1, -1, -1):
			var xs: Array = range(int(w * 0.3), int(w * 0.7) + 1).filter(func(x): return img.get_pixel(x, y).a > 0.24)
			if not xs.is_empty():
				seat = Vector2((xs[0] + xs[-1]) / 2.0, y + 1)
				break
		_seats[piece] = seat
	return _seats[piece]


## Which god a standard shows (the two falcons are the same god).
func _god(piece: String) -> String:
	return SAME.get(piece, piece)


func kind_of(_piece: String) -> String:
	return "std"


## At the hauling: take up the rope (and record the figure clicked).
func take_rope(h: Dictionary) -> void:
	_add_journal(h)
	if _hands_full():
		say("Scribe", _hands_message())
		return
	_set_hover({})
	avatar.stop()
	avatar.set_process(false)   # you stand on the rope in the hauler's place (see _process)
	avatar.facing = -1
	_hauling = true
	haul.start()
	var hauler: CanvasItem = haul.sprite_of("haul_hauler")   # you fade into his pose
	if haul.instant:
		avatar.modulate.a = 0.0
		return
	hauler.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(avatar, "modulate:a", 0.0, INTO_POSE)
	t.parallel().tween_property(hauler, "modulate:a", 1.0, INTO_POSE)


## Off the rope (let go, or the sledge is home): you fade back in and walk again.
func _off_rope() -> void:
	_hauling = false
	avatar.rotation = 0.0
	avatar.set_process(true)
	if haul.instant:
		avatar.modulate.a = 1.0
	else:
		create_tween().tween_property(avatar, "modulate:a", 1.0, INTO_POSE)


## A piece of the offering stand: take it from where it lies hidden (one at a time), put it back
## there, or set what you carry at its place before Ra.
func act_ending(id: String) -> void:
	if id == "place":
		ending.set_down()
	elif id == "back":
		put_back()
	elif not ending.imprint_shown:   # not before the stela shows what they are for
		say(EndingStand.TAGS[id], "This might come in handy later, but you wouldn't want your hands full right now.")
	elif _hands_full():
		say("Scribe", _hands_message())
	else:
		ending.take(id)
	_set_hover({})


## `quiet`: no word said (a dragged standard let go away from the poles goes back without comment).
func put_back(quiet := false) -> void:
	if not ending.carried.is_empty():
		say("Scribe", "You put %s back." % ending.carried_name())
		ending.put_back()
		return
	if mouth.carrying() != "":
		mouth.put_back()
		say("Scribe", "You put %s back." % ("the adze" if mouth.phase == OpeningMouth.Phase.START else "the words"))
		return
	if held == "":
		return
	if held_from != "" and slot[held_from] == "":
		slot[held_from] = held
		if not quiet:
			say("Scribe", "You put %s back." % NAMES[held])
	else:
		return
	held = ""
	held_from = ""
	_check()
	_render()


## Every rite but the stand before Ra: hauling, standards, table, goose, water and mouth.
func rites_done() -> bool:
	return solved.t1 and solved.t2 and solved.t3 and solved.t4 and solved.t5 and solved.t6


## Something is in your hands: a standard, an offering, the adze, the words or a piece of the stand.
func _hands_full() -> bool:
	return held != "" or offerings.holding() != "" or mouth.carrying() != "" or not ending.carried.is_empty()


## The Opening of the Mouth: take the adze, touch it to the mummy, take the words it speaks, and
## set them at their imprint over Ra.
func act_mouth(id: String) -> void:
	match id:
		"adze", "words":
			if _hands_full():
				say("Scribe", _hands_message())
				return
			if id == "adze":
				mouth.take_adze()
			else:
				mouth.take_words()
		"mummy":
			walk_then(_beside(mouth.mummy_rect()), mouth.touch)
		"home":
			walk_then(_beside(mouth.home_rect()), mouth.place_words)
		"back":     # where the adze or the words were taken from: they go back there
			walk_then(_beside(mouth.back_rect()), put_back)
	_set_hover({})


func _check() -> void:
	var was := solved.duplicate()
	solved.t1 = haul.done
	solved.t2 = POLES.all(func(p): return _god(slot[p]) == _god(SLOTS[p].home))
	solved.t3 = offerings.complete()
	solved.t4 = offerings.goose_returned()
	solved.t5 = water.done
	solved.t6 = mouth.done()
	solved.t7 = ending.complete()
	var rites := rites_done()
	var were: bool = was.t1 and was.t2 and was.t3 and was.t4 and was.t5 and was.t6
	if solved.t1 and not was.t1:
		say("Ox-driver", "Well hauled! The sledge stands where it should, and the mummy goes on toward the tomb.")
		var o: Dictionary = level.sprites.ox
		var sl: Dictionary = level.sprites.haul_sledge
		_kick_dust(Rect2(o.x, 0, sl.x + sl.w - o.x, 0))
		_success([_pieces.ox] + ["haul_sledge", "haul_hauler", "haul_driver", "haul_driver_arm"].map(haul.sprite_of))
		avatar.position.x = level.sprites.haul_hauler.x + level.sprites.haul_hauler.w + BESIDE * unit
		_off_rope()
	if solved.t2 and not was.t2:
		say("Standard-bearers", "All eight standards are in order.")
		_success(POLES.map(func(p): return _pieces[slot[p]]))
	if solved.t3 and not was.t3:
		say("Scribe", "The offering table is whole again.")
		_success([_table.rect] + offerings.placed_sprites())
	if solved.t4 and not was.t4:
		_success(offerings.bearer_sprites())
	if solved.t5 and not was.t5:
		_success([water.priest_sprite(), water.arm_sprite(), water.stream_sprite()])
	if solved.t6 and not was.t6:
		_success([mouth.glow_target("words"), mouth.glow_target("adze"), mouth.glow_target("mummy")])
	if solved.t7 and not was.t7:
		_success(EndingStand.PIECES.map(ending.sprite_of))
	if rites and not were:
		ending.show_imprint()     # the stela only shows the stand once everything else is right
	if rites and not were and not solved.t7:
		hud.say_later("Scribe", "The procession is in order. Head over to Ra on his throne.", 1.6)
	if solved.values().all(func(v): return v) and not was.values().all(func(v): return v):
		var generation := _generation
		get_tree().create_timer(1.2, false).timeout.connect(func():
			if generation == _generation:
				finish())


## Clicking a figure: record it in the journal, and run the figures that do something.
func record(h: Dictionary) -> void:
	if h == _lector:  # no words, only the signs he reads out; you stand before him, facing him
		_add_journal(h)
		avatar.facing = 1
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
	elif h.label == "Stela" and not ending.imprint_shown:   # blank until the other rites are done
		text = "A round-topped stela under the winged sun. Its face is blank."
		h = h.merged({"note": text}, true)
	say(who, text)
	_add_journal(h)


func _add_journal(h: Dictionary) -> void:
	if h.label in journal:
		return
	journal.append(h.label)
	hud.add_journal_entry(h.label, h.note, _journal_picture(h.rect), journal.size(), hotspots.size())


## The strip under `r`, with the figures that are sprites now (the hauling, the water priest,
## and the stream once it runs) drawn in as drawn.
func _journal_picture(r: Rect2) -> Texture2D:
	var overlays: Array = HaulSledge.PIECES + ["ox", "water_priest"] + (["water_stream"] if water.done else [])
	overlays = overlays.filter(func(nm): return r.intersects(_drawn_rect(nm)))
	if overlays.is_empty():
		var tex := AtlasTexture.new()
		tex.atlas = $Strip.texture
		tex.region = r
		return tex
	if _strip_img == null:
		_strip_img = $Strip.texture.get_image()
		if _strip_img.is_compressed():
			_strip_img.decompress()
		_strip_img.convert(Image.FORMAT_RGBA8)
	var ri := Rect2i(r)
	var img := _strip_img.get_region(ri)
	for nm in overlays:
		var src := _drawn_image(nm)
		img.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(_drawn_rect(nm).position) - ri.position)
	return ImageTexture.create_from_image(img)


## Where a figure that is a sprite now lies as drawn on the strip: its cut's box, or its sheet's cell.
func _drawn_rect(nm: String) -> Rect2:
	if SHEETS.has(nm):
		var m := _sheet(nm)
		return Rect2(m.origin[0], m.origin[1], m.cell[0], m.cell[1])
	var s: Dictionary = level.sprites[nm]
	return Rect2(s.x, s.y, s.w, s.h)


## A figure's drawing as drawn (of a sheet, its frame as drawn).
func _drawn_image(nm: String) -> Image:
	var src: Image = load("res://assets/procession/%s.png" % SHEETS.get(nm, nm)).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	if SHEETS.has(nm):
		var m := _sheet(nm)
		var cell := Vector2i(int(m.cell[0]), int(m.cell[1]))
		var rest := int(m.rest)
		src = src.get_region(Rect2i(Vector2i(rest % int(m.cols), rest / int(m.cols)) * cell, cell))
	return src


func _sheet(nm: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/procession/%s.json" % SHEETS[nm]))


## Everything is in order: you walk to the adorer's place before Ra and kneel there, and the light
## takes the scene (see ending.gd). For now the level then goes back to the menu.
func finish() -> void:
	if finished:
		return
	finished = true
	_set_hover({})
	_render()
	say("Lector priest", "The procession has arrived. Kneel before Ra as he sets.")
	avatar.keys = false
	avatar.set_process(true)
	walk_then(ending.kneel_x(), func():
		avatar.facing = -1
		ending.kneel(avatar))


func _ended() -> void:
	if not _testing:
		Scroll.finish("procession")


func _tell_once(key: String, text: String) -> void:
	if not _feedback.has(key):
		_feedback[key] = true
		say("Scribe", text)


func _hands_message() -> String:
	var item: String = NAMES.get(held, "")
	if offerings.holding() != "":
		item = offerings.held_name()
	if mouth.carrying() != "":
		item = "the adze" if mouth.carrying() == "adze" else "the words"
	if not ending.carried.is_empty():
		item = ending.carried_name()
	return "You carry %s. Put it back where you took it to free your hands." % item


func _hint_lines(task: String, lines: Array) -> void:
	var step: int = _hint_step.get(task, 0)
	say("Hint", lines[mini(step, lines.size() - 1)])
	_hint_step[task] = step + 1


func hint() -> void:
	if haul.active:
		say("Hint", "Heave with [space] as the whip falls. Too early or late makes the bier slip back.")
	elif in_standards or (held != "" and kind_of(held) == "std"):
		_hint_lines("standards", ["The priest with two plumes reads the order. He stands beyond the offering table.",
			"Jackal, ibis, falcon, bull, vulture, placenta, plumes, falcon: follow the procession from its front."])
	elif in_table:
		_hint_lines("table", ["Build lowest first. An offering falls if its support is missing.",
			"Drag pieces above the upper shelf to clear space. They fall onto it; drag them back across to use them.",
			"Click the lector beside the table. He shows an offering you can place now."])
	elif water.active:
		_hint_lines("water", ["Hold [space] to lift his drooping arm; let go to let it sink.",
			"Too high only drips; drooped too far, the water splashes short. Keep the stream on its faint guide.",
			"His arm droops faster or slower from moment to moment: watch it, and lift as it sinks."])
	elif mouth.carrying() == "adze":
		say("Hint", "Touch the adze to the mummy that Anubis holds upright.")
	elif mouth.carrying() == "words":
		say("Hint", "Carry the words to their faint outline over Ra, at the far left.")
	elif not solved.t1:
		say("Hint", "Walk left to the stalled bier. Speak with the ox-driver beside the ox.")
	elif not solved.t2:
		say("Hint", "Click the group of eight standard-bearers to put their standards in order.")
	elif not solved.t3:
		say("Hint", "Click the collapsed offering table to begin rebuilding it.")
	elif not solved.t4:
		say("Hint", "The goose-bearer holds a loaf. Take it, then find his goose among the fallen offerings.")
	elif not solved.t5:
		say("Hint", "Find the priest with a jar above a kneeling woman. Click him to pour the water.")
	elif not solved.t6:
		say("Hint", "Take the hooked adze beside the obelisks and touch the mummy's mouth." if mouth.phase == OpeningMouth.Phase.START else "Carry the words above the mummy to Ra, at the far left.")
	else:
		_hint_lines("stand", ["The stela beside Ra shows the missing offering stand.",
			"Look behind the women mourners, on the bier, and on the offering pile for its three pieces.",
			"Place the stand before Ra, then the sun disc, then the lotus."])


func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


func say(who: String, text: String) -> void:
	_last_said = text
	hud.say(who, text)


# ---------------------------------------------------------------- per-frame

func _process(delta: float) -> void:
	_time += delta
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	if in_standards and (Input.get_axis("ui_left", "ui_right") != 0.0 or Input.get_axis("ui_up", "ui_down") != 0.0):
		leave_standards()
	if in_table and Input.get_axis("ui_left", "ui_right") != 0.0:   # walking off steps away
		leave_table()
	if water.active and Input.get_axis("ui_left", "ui_right") != 0.0:
		leave_water()
	if haul.active:     # you hold the rope where the hauler is drawn, leaning on the beat
		var h: Dictionary = level.sprites.haul_hauler
		avatar.position.x = h.x + h.w / 2.0 + haul.offset
	elif _hauling:      # let go: walk again
		_off_rope()

	for d in _dust:
		d.pos += d.vel * delta
		d.life -= delta
	_dust = _dust.filter(func(d): return d.life > 0.0)

	_update_camera(delta)
	hud.update_held(held, _pieces[held].texture if held != "" else null, camera.zoom.x)
	overlay.queue_redraw()


## Fit the scene's height into the space between the HUD bars; keep at least ~1000 px of
## scroll visible on narrow windows.
func _update_camera(delta: float) -> void:
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var fit := (vp.y - top - bottom - 10.0) / (_view_height() - VIEW_TOP)
	var z := clampf(minf(fit, vp.x / (1000.0 * unit)), 0.4 / unit, 2.4 / unit)
	var target_x := avatar.position.x - vp.x / z * 0.05
	if in_table or water.active or in_standards or haul.active:   # hold on the whole scene: the table, the water, the hauling
		var v: Vector2 = _standards_view if in_standards else (water.view() if water.active else _haul_view() if haul.active else Vector2(level.table.view[0], level.table.view[1]))
		z = clampf(minf(fit, vp.x / (v.y - v.x + 2.0 * SCENE_MARGIN)), 0.2 / unit, 2.4 / unit)
		target_x = (v.x + v.y) / 2.0
	var focus := "table" if in_table else "water" if water.active else "standards" if in_standards else "haul" if haul.active else ""
	if focus != _focus:
		_focus = focus
		_refocus = {"t": 0.0, "z": camera.zoom.x, "x": camera.position.x} if delta < 1.0 else {}
	if not _refocus.is_empty():   # ease in and out to the new focus, instead of lunging at it
		_refocus.t += delta
		var s := smoothstep(0.0, REFOCUS, _refocus.t)
		z = lerpf(_refocus.z, z, s)
		target_x = SCROLL_CAMERA.clamp_horizontal(target_x, vp.x / z, level.width)
		camera.zoom = Vector2(z, z)
		camera.position.x = lerpf(_refocus.x, target_x, s)
		if _refocus.t >= REFOCUS:
			_refocus = {}
	else:
		var k := SCROLL_CAMERA.smoothing(delta)
		z = lerpf(camera.zoom.x, z, k)
		camera.zoom = Vector2(z, z)
		target_x = SCROLL_CAMERA.clamp_horizontal(target_x, vp.x / z, level.width)
		camera.position.x = lerpf(camera.position.x, target_x, k)
	if FRAME_FROM_TOP:
		camera.position.y = VIEW_TOP + (vp.y / 2.0 - top) / z
	else:
		camera.position.y = SCROLL_CAMERA.vertical_center(_view_height(), top, bottom, z, VIEW_TOP)


## While hauling the camera holds still on the train and the road ahead of the ox, from the
## ox's nose to the hauler where he stands back at the start: the train comes up toward it.
func _haul_view() -> Vector2:
	var o: Dictionary = level.sprites.ox
	var h: Dictionary = level.sprites.haul_hauler
	return Vector2(o.x - HAUL_AHEAD * unit, h.x + h.w + HaulSledge.BACK)


## Rows the camera fits on screen: the strip plus the visible part of the faded text below.
func _view_height() -> float:
	return level.get("view_height", level.height)


func _visible_rect() -> Rect2:
	return SCROLL_CAMERA.visible_rect(camera, get_viewport_rect().size)


# ---------------------------------------------------------------- drawing

func _render() -> void:
	for p in _pieces.values():
		p.visible = false
	for piece in FIXED:
		_pieces[piece].visible = true
		if piece == "ox":
			haul.set_ox_home(sprite_rects.ox.position)
		else:
			_pieces[piece].position = sprite_rects[piece].position
	for id in SLOTS:
		var piece: String = slot[id]
		if piece == "":
			continue
		var home: Rect2 = sprite_rects[SLOTS[id].home]   # its seat on the stub where this pole's own standard sits
		_pieces[piece].position = home.position + _seat(SLOTS[id].home) - _seat(piece)
		_pieces[piece].visible = true


func _draw_overlay() -> void:
	if _show_hits:  # dev: `--show-hits` outlines every click region
		for id in SLOTS:
			overlay.draw_rect(_slot_hit_rect(id), HOVER_SLOT, false, 3.0)
		for h in hotspots:
			overlay.draw_rect(h.rect, HOVER, false, 3.0)
	for d in _dust:
		overlay.draw_circle(d.pos, 3.0 * unit, Color(0.79, 0.66, 0.41, clampf(d.life, 0.0, 1.0)))


func _kick_dust(r: Rect2) -> void:
	for i in 16:
		_dust.append({
			"pos": Vector2(r.position.x + randf() * r.size.x, ground - 4.0 * unit),
			"vel": Vector2(randf_range(-35.0, 15.0), randf_range(-40.0, -20.0)) * unit,
			"life": randf_range(0.6, 1.1),
		})


func _flash(node: CanvasItem) -> void:
	UI.flash(node)


## The plumed lector reads out the standards in the order they walk, jackal first: one sign at a
## time, centred over the top of his sheet, each replacing the one before.
func recite() -> void:
	_clear_recital()
	var r: Dictionary = level.recital
	var signs: Array = POLES.map(func(p): return SLOTS[p].home)
	var tallest := 0.0
	for piece in signs:
		tallest = maxf(tallest, sprite_rects[piece].size.y)
	var s: float = (r.bottom - r.top) / tallest
	_recital_tween = create_tween()
	for piece in signs:
		var size: Vector2 = sprite_rects[piece].size * s
		var glyph := Sprite2D.new()
		glyph.texture = _pieces[piece].texture
		glyph.centered = false
		glyph.scale = Vector2(s, s)
		glyph.position = Vector2(r.centre - size.x / 2.0, r.bottom - size.y)   # over the top of his sheet
		glyph.modulate.a = 0.0
		_recital.add_child(glyph)
		_recital_tween.tween_property(glyph, "modulate:a", 1.0, RECITE_FADE_IN)
		_recital_tween.tween_interval(RECITE_STEP - RECITE_FADE_IN - RECITE_FADE_OUT)
		_recital_tween.tween_property(glyph, "modulate:a", 0.0, RECITE_FADE_OUT)
	_recital_tween.tween_callback(_clear_recital)


func _clear_recital() -> void:
	if _recital_tween and _recital_tween.is_valid():
		_recital_tween.kill()
	for c in _recital.get_children():
		c.queue_free()
	_recital.modulate.a = 1.0


# ---------------------------------------------------------------- command line

## `-- --autotest` solves the level through the same rules the player uses and prints the
## result. `-- --screenshot=path.png` saves a frame after start-up and quits; `--recite` shows
## the plumed lector's whole line of signs at once, `--speak` has the lector beside the table show
## a piece, `--table` stands you at the offering table, `--hover=x,y` hovers there (strip px), and `--wait` lets the fallen offerings settle (about 5 s) before the screenshot.
func _maybe_run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_autotest()
	for a in args:  # dev helpers: `--at=4300` starts the avatar there, `--take=pole1` lifts that slot's piece
		if a.begins_with("--at="):
			avatar.position.x = a.trim_prefix("--at=").to_float()
			_update_camera(1.0)
		elif a == "--show-hits":
			_show_hits = true
		elif a.begins_with("--take="):
			act_slot(a.trim_prefix("--take="))
		elif a == "--recite":   # stops at the third sign
			recite()
			_recital_tween.custom_step(RECITE_STEP * 2.5)
		elif a == "--speak":
			offerings.speak()
		elif a == "--ending" or a == "--finale":   # dev: carry the stand's pieces, before Ra (and with --finale, set them up and kneel)
			hud.dismiss_intro()
			ending.take("stand")
			avatar.position.x = ending.place_rect().end.x + BESIDE * unit
			_update_camera(1.0)
			if a == "--finale":
				for i in 3:
					ending.set_down()
				finished = true
				avatar.keys = false
				walk_then(ending.kneel_x(), ending.kneel.bind(avatar))
		elif a == "--water" or a.begins_with("--pour="):   # dev: stand at the water (and with --pour=rad, hold the jar at that tilt from as drawn)
			hud.dismiss_intro()
			avatar.position.x = water.stand_x()
			_water_now()
			_update_camera(1.0)
			if a.begins_with("--pour="):
				water.hold_at(a.trim_prefix("--pour=").to_float())
		elif a == "--mouth" or a == "--open-mouth":   # dev: stand by the mummy with the adze in hand (and with --open-mouth, touch it)
			hud.dismiss_intro()
			mouth.take_adze()
			avatar.position.x = mouth.mummy_rect().end.x + BESIDE * unit
			_update_camera(1.0)
			if a == "--open-mouth":
				mouth.touch()
		elif a == "--table":   # dev: stand at the offering table, in its scene
			avatar.position.x = level.table.stand
			_table_now()
			_update_camera(1.0)
		elif a.begins_with("--hover="):   # dev: hover there (strip px "x,y") for a screenshot of the glow
			var xy := a.trim_prefix("--hover=").split(",")
			_set_hover(_pick(Vector2(xy[0].to_float(), xy[1].to_float())))
	if "--haul" in args or "--haul-bot" in args:   # dev: take up the rope at once (and with --haul-bot, pull on the beats)
		hud.dismiss_intro()
		avatar.position.x = level.sprites.haul_hauler.x
		take_rope(hotspots.filter(func(h): return h.label == "Hauler")[0])
		if "--haul-bot" in args:
			var bot := Timer.new()
			bot.wait_time = 1.0 / 60.0
			add_child(bot)
			var n := [0, -1]      # pulls, the last beat pulled on
			bot.timeout.connect(func():
				var k := roundi(haul.clock / HaulSledge.BEAT)
				if haul.phase == HaulSledge.Phase.PLAYING and k >= HaulSledge.COUNT_IN and k > n[1] and absf(haul.clock - k * HaulSledge.BEAT) < 0.04:
					n[1] = k
					n[0] += 1
					if n[0] == 4:       # one off the beat, to show the rope going slack
						get_tree().create_timer(HaulSledge.BEAT * 0.45).timeout.connect(haul.press)
					else:
						haul.press())
			bot.start()
	for a in args:   # dev: save every 3rd frame as <dir>/fNNNN.png for N seconds (`--record=dir --seconds=N`)
		if a.begins_with("--record="):
			var secs := 12.0
			for b in args:
				if b.begins_with("--seconds="):
					secs = b.trim_prefix("--seconds=").to_float()
			var dir := a.trim_prefix("--record=")
			var k := 0
			for i in int(secs * 60.0):
				await get_tree().process_frame
				if i % 3 == 0:
					get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [dir, k])
					k += 1
			get_tree().quit()
	for a in args:
		if a.begins_with("--screenshot="):
			hud.dismiss_intro()
			for i in (300 if "--wait" in args else 30):
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


func _autotest() -> void:
	hud.dismiss_intro()
	_testing = true
	var fails: Array[String] = []   # lambdas capture locals by value, so collect into an array
	var expect := func(cond: bool, what: String):
		print(("PASS " if cond else "FAIL ") + what)
		if not cond:
			fails.append(what)
	expect.call(not _lector.is_empty(), "plumed lector found in plate V")
	expect.call(not ending.imprint_shown and not ending._imprint.visible, "the stela is blank until the other rites are done")
	expect.call(min_x() < _lector.rect.position.x, "the lector in plate V can be reached from the start")
	record(_lector)
	var shown: Array = _recital.get_children().map(func(c): return c.texture)
	var order: Array = POLES.map(func(p): return _pieces[SLOTS[p].home].texture)
	expect.call(shown == order, "lector recites the eight standards in order, jackal first")
	var mids: Array = _recital.get_children().map(func(c): return roundi(c.position.x + c.texture.get_width() * c.scale.x / 2.0))
	expect.call(mids.all(func(x): return x == roundi(level.recital.centre)), "each sign stands in the same place, centred over his sheet")
	_recital_tween.custom_step(RECITE_STEP * 2.5)
	var lit: Array = _recital.get_children().filter(func(c): return c.modulate.a > 0.5)
	expect.call(lit.size() == 1 and lit[0].texture == order[2], "one sign at a time: the third replaces the second")
	# a click in the middle of every slot and journal region picks exactly that region (unless a
	# fallen offering or a hidden piece of the offering stand lies over it)
	var missed: Array[String] = []
	for id in SLOTS:
		var h := _pick(_slot_hit_rect(id).get_center())
		if h.get("type") != "slot" or h.id != id:
			missed.append(id)
	for spot in hotspots:
		var h := _pick(spot.rect.get_center())
		if h.get("type") in ["piece", "ending", "water"] or (spot.label == "Hauler" and not haul.hauler_shown()):
			continue
		if h.get("type") != "hot" or h.spot != spot:
			missed.append(spot.label)
	expect.call(missed.is_empty(), "every region picked by a click at its centre %s" % [missed])
	_set_hover(_pick(_slot_hit_rect("pole1").get_center()))
	expect.call(_glows.size() == 16 and _glows[1].get_parent() == _pieces[slot.pole1], "a standard-bearer glows whole under the pointer: the man and his standard")
	_set_hover(_pick(hotspots[0].rect.get_center()))
	expect.call(_glows.size() == 1 and _glows[0].get_parent() == $Strip, "a journal figure glows under the pointer")
	_set_hover({})
	expect.call(_glows.is_empty(), "nothing glows when the pointer leaves")
	var stand: Dictionary = hotspots.filter(func(h): return h.label == "Offering stand")[0]
	_set_hover(_pick(stand.rect.get_center()))
	expect.call(_glows.size() == 4 and _glows[0].get_parent() == $Strip, "the adze's stand glows whole, with the rods, the foreleg and the adze")
	_set_hover(_pick(mouth.glow_target("adze").position + Vector2(10, 10)))
	expect.call(_glows.size() == 1 and _glows[0].get_parent() == mouth.glow_target("adze"), "the adze alone glows alone")
	for figure in PIECE_GLOW:   # pieces, not in the strip: their own drawings glow
		_set_hover(_pick(hotspots.filter(func(h): return h.label == figure)[0].rect.get_center()))
		expect.call(_glows.size() == 1 and _glows[0].get_parent() == _pieces[PIECE_GLOW[figure]], "the %s glows as its own drawing" % figure.to_lower())
	_set_hover({})
	_autotest_haul(expect)
	for p in POLES:  # take the right standard from wherever it is and set it here: the two swap
		if _god(slot[p]) == _god(SLOTS[p].home):
			continue
		for q in POLES:
			if q != p and _god(slot[q]) == _god(SLOTS[p].home) and _god(slot[q]) != _god(SLOTS[q].home):
				act_slot(q)
				act_slot(p)
				break
	expect.call(held == "", "setting a standard down swaps it with the one there: nothing is left in hand")
	expect.call(solved.t2, "all eight standards on their own poles")
	expect.call(_success_glowing(_pieces[slot.pole1]), "in order, the standards flash pale green")
	act_slot(POLES[0])
	expect.call(held == "" and solved.t2, "once in order the standards are locked")
	expect.call(held == "", "hand empty after sorting the standards")
	_autotest_table(expect)
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)


## (autotest) A success flash is glowing behind `sprite`.
func _success_glowing(sprite: Node) -> bool:
	return sprite.get_children().any(func(c): return c.material is ShaderMaterial and (c.material as ShaderMaterial).get_shader_parameter("level") == UI.Glow.SUCCESS)


## Haul the sledge through the same calls the keys make, stepping the beat clock by hand.
func _autotest_haul(expect: Callable) -> void:
	var step := func(t: float):
		while t > 0.0:
			var d := minf(t, 1.0 / 60.0)
			haul._process(d)
			t -= d
	haul.instant = true
	expect.call(not haul.hauler_shown(), "nobody hauls the sledge until you take up the rope")
	var hauler: Dictionary = hotspots.filter(func(h): return h.label == "Hauler")[0]
	take_rope(hauler)
	expect.call(haul.active and is_equal_approx(haul.offset, HaulSledge.BACK), "taking up the rope sets the sledge back and opens the vignette")
	expect.call(avatar.modulate.a == 0.0 and haul.hauler_shown(), "you become the original hauler while holding the rope")
	step.call(haul.to_next_beat())
	var whip := haul.sprite_of("haul_driver_arm")
	expect.call(is_equal_approx(whip.rotation, -HaulSledge.STRIKE), "on the beat the driver's whip is struck down")
	haul.press()
	expect.call(is_equal_approx(haul.target, HaulSledge.BACK - HaulSledge.BACK / HaulSledge.PULLS), "a pull on the beat gains a step")
	var before := haul.target
	step.call(HaulSledge.BEAT * 0.5)
	haul.press()
	expect.call(haul.target > before, "a pull off the beat lets the sledge slip back")
	before = haul.target
	step.call(HaulSledge.BEAT * 2.0)
	expect.call(is_equal_approx(haul.target, before), "a beat let pass: the bier stops")
	step.call(haul.to_next_beat())
	haul.press()
	expect.call(_last_said == "That's it. Keep the beat.", "a good pull after a miss answers it, so the miss is not left standing")
	var guard := 0
	while haul.active and guard < 40:
		guard += 1
		step.call(haul.to_next_beat())
		haul.press()
		step.call(0.05)
	step.call(2.0)
	expect.call(haul.done and solved.t1, "the sledge hauled home on the beat")
	expect.call(not haul.active and haul.offset == 0.0 and avatar.modulate.a == 1.0, "the vignette closes, the train stands as drawn, you walk again")
	expect.call(haul.hauler_shown(), "the hauler appears on the rope once the sledge is home")
	expect.call(_success_glowing(haul.sprite_of("haul_sledge")) and _success_glowing(_pieces.ox), "hauled home, the train flashes pale green")
	expect.call(whip.rotation == 0.0, "home again, the driver holds his whip as drawn")
	haul.instant = false


## Pour the water through the calls a drag on the jar makes, stepping the water's clock by hand.
func _autotest_water(expect: Callable) -> void:
	var step := func(t: float):
		while t > 0.0:
			var d := minf(t, 1.0 / 60.0)
			water._process(d)
			t -= d
	water.instant = true
	var reveal := func() -> float:
		return (water.stream_sprite().material as ShaderMaterial).get_shader_parameter("reveal")
	expect.call(water.progress == 0.0 and reveal.call() == 0.0 and is_equal_approx(water.tilt, PourWater.START_TILT), "at the start the jar is upright and no water runs")
	expect.call(is_equal_approx(water.arm_sprite().rotation, PourWater.START_TILT), "his arm shows the jar raised upright")
	var priest: Dictionary = hotspots.filter(func(h): return h.label == "Priest with jar")[0]
	var ink := func(img: Image) -> float:
		var n := 0.0
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				n += img.get_pixel(x, y).a
		return n
	var bare := AtlasTexture.new()
	bare.atlas = $Strip.texture
	bare.region = priest.rect
	expect.call(ink.call(_journal_picture(priest.rect).get_image()) > ink.call(bare.get_image()) * 1.5, "he is not in the strip, but his Journal picture shows him (his sheet's frame as drawn)")
	var h := _pick(priest.rect.get_center())
	expect.call(h.get("type") == "hot" and h.spot == priest, "the priest with the jar can be clicked")
	expect.call(_pick(water.arm_rect().get_center()).get("type") == "water", "his jar can be clicked from along the scroll")
	_water_now()
	expect.call(water.active, "clicking him steps up to the water")
	expect.call(_pick(water.arm_rect().get_center()).get("type") != "water", "at the water, the jar is not something to click")
	step.call(0.5)
	expect.call(water.tilt < PourWater.START_TILT, "his arm droops by itself")
	water._droop = PourWater.DROOP.x
	water._droop_left = 10.0
	water._spin = 0.0   # still, not swinging down from the droop before
	var before := water.tilt
	water.raising = true
	step.call(0.5)
	water.raising = false
	expect.call(water.tilt > before, "holding Space lifts it")
	var rates := []
	for i in 6:
		water._droop_left = 0.0
		step.call(1.0 / 60.0)
		rates.append(water._droop)
	expect.call(rates.all(func(r): return r >= PourWater.DROOP.x and r <= PourWater.DROOP.y) and rates.any(func(r): return r != rates[0]), "the droop changes, at random, within its range")
	water.hold_at(0.25)
	step.call(1.5)
	expect.call(water.flow == PourWater.Flow.DRIP and water.progress == 0.0 and not water._drops.is_empty(), "too high: it only drips")
	water.hold_at(-0.4)
	water.tilt = -0.4   # straight there, not swept through the window
	step.call(1.0)
	var on_hands: bool = water._drops.any(func(d): return d.pos.distance_to(Vector2(level.water.hands[0], level.water.hands[1])) < 40.0)
	expect.call(water.flow == PourWater.Flow.GUSH and water.progress == 0.0 and on_hands, "drooped too far: it gushes out and falls short, onto the woman's hands")
	water.hold_at(0.0)
	step.call(2.5)
	var poured := water.progress
	expect.call(water.flow == PourWater.Flow.POUR and poured > 0.2 and reveal.call() == poured, "held as drawn, the line draws itself in")
	water.hold_at(-0.4)
	step.call(10.0)
	expect.call(water.progress < poured and is_equal_approx(water.progress, water.best * PourWater.KEEP), "poured wrong, the line dries back, but never below its share of the furthest reached")
	leave_water()
	expect.call(not water.active and not water.raising, "Esc steps away")
	_water_now()
	water.hold_at(0.05)
	var guard := 0
	while not water.done and guard < 60 * 20:
		guard += 1
		step.call(1.0 / 60.0)
	expect.call(water.done and solved.t5, "held steady, the water runs the whole line")
	expect.call(water.tilt == 0.0 and water.arm_sprite().rotation == 0.0 and reveal.call() == 1.0, "the jar and the stream as drawn")
	expect.call(not water.active and _pick(water.arm_rect().get_center()).get("type") != "water", "once it runs, the jar is no longer to be worked")
	water.instant = false


## Take the adze to the mummy, and the words it speaks to their place over Ra.
func _autotest_mouth(expect: Callable) -> void:
	mouth.instant = true
	var words: Dictionary = level.sprites.mouth_words
	var adze: Dictionary = level.sprites.mouth_adze
	var home := Rect2(words.x, words.y, words.w, words.h)
	expect.call(mouth._imprint.visible and not mouth._words.visible, "at the start the words over Ra show only faintly")
	var h := _pick(Rect2(adze.x, adze.y, adze.w, adze.h).get_center())
	expect.call(h.get("type") == "mouth" and h.id == "adze", "the adze on the offering stand can be clicked")
	expect.call(_pick(mouth.mummy_rect().get_center()).get("type") != "mouth", "without the adze, the mummy is only a figure")
	act_mouth("adze")
	expect.call(mouth.carrying() == "adze", "clicking the adze takes it up")
	expect.call(_pick(Rect2(adze.x, adze.y, adze.w, adze.h).get_center()).get("id") == "back", "with the adze in hand, its place on the stand can be clicked")
	put_back()
	expect.call(mouth.carrying() == "" and mouth._adze.position == Vector2(adze.x, adze.y), "clicking the stand puts the adze back")
	act_mouth("adze")
	h = _pick(mouth.mummy_rect().get_center())
	expect.call(h.get("type") == "mouth" and h.id == "mummy", "with the adze in hand, the mummy can be touched")
	mouth.touch()
	var said := mouth.words_rect()
	expect.call(mouth.phase == OpeningMouth.Phase.SPOKEN and mouth._adze.position == Vector2(adze.x, adze.y), "the touch opens the mouth; the adze goes back on the stand")
	var band_free: bool = said.position.x > 850.0 and said.end.x <= 2172.0 and said.position.y >= 50.0 and said.end.y <= 180.0
	expect.call(said.size == home.size and band_free and said.end.x > mouth.mummy_rect().position.x, "the words sit whole in the empty band above the mummy")
	h = _pick(said.get_center())
	expect.call(h.get("type") == "mouth" and h.id == "words", "the spoken words can be taken")
	act_mouth("words")
	expect.call(mouth.carrying() == "words" and not solved.t6, "taken up, the words are carried")
	expect.call(_pick(said.get_center()).get("id") == "back", "with the words in hand, their place above the mummy can be clicked")
	h = _pick(home.get_center())
	expect.call(h.get("type") == "mouth" and h.id == "home", "their imprint over Ra takes them")
	mouth.place_words()
	expect.call(solved.t6 and not mouth._imprint.visible and mouth.words_rect() == home, "the words stand over Ra as drawn")
	mouth.instant = false


## Find the three pieces of the offering stand, set them up before Ra, and kneel.
func _autotest_ending(expect: Callable) -> void:
	ending.instant = true
	expect.call(ending.imprint_shown and ending._imprint.visible, "with every other rite done, the stand's imprint comes up on the stela")
	expect.call(not ending._kneeler.visible, "the adorer before Ra is not there at the start")
	var at := {}
	for nm in EndingStand.PIECES:
		at[nm] = ending.where(nm)
	var women: Rect2 = hotspots.filter(func(h): return h.label == "Women mourners")[0].rect
	var bier: Dictionary = level.sprites.haul_sledge
	expect.call(at.stand.x < women.position.x and at.stand.x > women.position.x - 200.0, "the stand is hidden right behind the women mourners")
	expect.call(at.sun.x > bier.x and at.sun.x < bier.x + bier.w and ending.sprite_of("sun").get_parent() == haul.sprite_of("haul_sledge"), "the sun disc rides on the mummy's bier")
	expect.call(at.lotus.x > level.plates.V.x and at.lotus.x < level.plates.V.x + level.plates.V.w, "the lotus lies on the offering pile of plate V")
	for nm in EndingStand.PIECES:
		var h := _pick(at[nm])
		expect.call(h.get("type") == "ending" and h.id == nm, "%s can be clicked where it lies" % nm)
	act_ending("sun")
	ending._process(0.0)
	expect.call(ending.sprite_of("sun").global_position == get_global_mouse_position(), "a piece taken up follows the pointer")
	act_ending("lotus")
	expect.call(ending.carried == ["sun"], "one piece at a time")
	var r := ending.set_down()
	expect.call(r == "unsupported" and not ending.placed.has("sun"), "the sun disc cannot go on before the stand")
	expect.call(_pick(at.sun).get("id") == "back", "where it was found takes it back")
	act_ending("back")
	expect.call(ending.carried.is_empty() and ending.where("sun") == at.sun, "put back where it was found")
	var h := _pick(ending.place_rect().get_center())
	expect.call(h.get("type") == "ending" and h.id == "place", "the stand's place before Ra can be clicked")
	for nm in EndingStand.PIECES:
		act_ending(nm)
		act_ending("place")
	expect.call(ending.complete() and solved.t7, "stand, sun disc and lotus set up before Ra")
	for nm in EndingStand.PIECES:
		expect.call(ending.sprite_of(nm).position == ending._rects[nm].get_center(), "%s stands where it is drawn" % nm)
	expect.call(solved.values().all(func(v): return v), "all seven rites done")
	finish()
	avatar.position.x = ending.kneel_x()
	ending.kneel(avatar)
	expect.call(finished and ending.kneeling and ending._kneeler.visible and not avatar.visible, "you kneel in the adorer's place before Ra")


func _autotest_table(expect: Callable) -> void:
	expect.call(not offerings.pieces.is_empty(), "the offering table has loose pieces (%d)" % offerings.pieces.size())
	_table_now()
	expect.call(in_table, "clicking the table steps up to it")
	var some := ""
	for id in offerings.pieces:
		if offerings.pieces[id].kind == "loose":
			some = id
			break
	var above := Vector2(lerpf(offerings.view.x, offerings.view.y, 0.7), (offerings.header.x + offerings.header.y) / 2.0)
	offerings.take(some)
	_table_drop(above)
	var lying := offerings.sprite_of(some)
	expect.call(offerings.holding() == "" and lying != null and lying.get_parent() is RigidBody2D and offerings.pick(lying.global_position) == some, "upper-register offerings have gravity and can be taken up again")
	offerings.take(some)
	leave_table()
	expect.call(not in_table and offerings.holding() == "" and offerings.sprite_of(some) != null, "Esc steps away from the table; what you held goes back")
	_table_now()
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
	expect.call(offerings.bearer != "" and offerings.holding() == "", "the loaf goes back to him")
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
	leave_table()
	_autotest_water(expect)
	_autotest_mouth(expect)
	expect.call(rites_done() and not finished, "all six rites done; the level waits for the offering stand")
	_autotest_ending(expect)

	# Restart must clear both the carried piece and its visible preview.
	reset()
	offerings.take(some)
	expect.call(offerings._held_sprite.visible, "a carried offering is visible before restarting")
	reset()
	expect.call(offerings.holding() == "" and not offerings._held_sprite.visible , "restarting clears the carried offering")
	_autotest_soft_lock(expect)


## Before the stela shows the imprint (other rites undone), the stand's pieces stay where they hide.
func _autotest_soft_lock(expect: Callable) -> void:
	reset()
	ending.instant = true
	expect.call(not ending._imprint.visible, "restarting blanks the stela again")
	for nm in EndingStand.PIECES:
		act_ending(nm)
	expect.call(ending.carried.is_empty(), "the stand's pieces can't be taken before the stela shows them")
	expect.call(_last_said == "This might come in handy later, but you wouldn't want your hands full right now.", "a hidden piece says it may come in handy later")
