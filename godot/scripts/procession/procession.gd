## Spells 1-15: the funeral procession (Lepsius, Todtenbuch pl. I-VI).
##
## World coordinates are pixels of the strip (assets/procession/figures/strip.png), which reads right
## to left: the player starts at the head of plate I (far right) and walks left. The strip is
## art/procession1-15.mdp as drawn. Saved nodes own piece placement; level.json, exported by
## tools/cut_procession300.py, retains source-art data and interaction geometry; registry.json owns descriptions.
extends Node2D

const PUZZLES := preload("res://scripts/puzzles.gd")

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const VIEW_TOP := 36.0   ## the row under the top register's upper rule: the title bar's band takes its place
## Zoomed out (at the table, the standards, the water), the top guideline stays flush under the
## title bar and more of the text below shows. false: the scene stays centred between the bars.
## (At the usual zoom the two are the same.)
const FRAME_FROM_TOP := true
const DATA_PATH := "res://assets/procession/level.json"
const ILLUSTRATION := preload("res://assets/procession/figures/illustration.png")
const BESIDE := 70.0         ## stand just behind (right of) what you interact with, not on top of it
const STAND_GAP := 6.0       ## plate px between you and the plumed lector, whom you stand in front of

## Movable pieces and how the scribe names them.
const NAMES := {
	"ox": "the ox",
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
const FIXED := ["ox"]
## The ox-driver, or the empty rope where the hauler stands once it is home, starts hauling.
const HAUL_FIGURES := ["hauler", "ox_driver", "funerary_bier"]
const INTO_POSE := 0.5        ## s for you to fade into the hauler's pose on the rope (and out again)
const HAUL_AHEAD := 200.0     ## plate px of the road ahead of the ox the camera shows while hauling
## Only the jar priest starts the purifying-water minigame; nearby figures are inspected.
const WATER_FIGURES := ["priest_with_jar"]

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
const CAPTIONS := [
	{"spell": 1, "id": "caption_1"},
	{"spell": 1, "id": "caption_2"},
	{"spell": 15, "id": "caption_3"},
	{"spell": 15, "id": "caption_4"},
]
## Figures whose arm turns in code (see haul.gd, pour_water.gd): their Journal picture is the frame
## as drawn of their (hand-drawn) sheet, each frame the whole figure.
const SHEETS := {"haul_driver": "haul_driver_sheet", "water_priest": "water_sheet"}
## Journal figures that are sprites of the hauling now: they glow as those drawings.
const HAUL_GLOW := {"hauler": ["haul_hauler", "haul_rope"], "ox_driver": ["haul_driver", "haul_driver_arm"]}
## Journal figures that are pieces (sprites, not in the strip): they glow as those drawings.
const PIECE_GLOW := {"ox": "ox"}
## The figures of the three bulls (see bulls.gd); clicking one steps up to them until they are set right.
const BULL_FIGURES := ["calf", "plumed_ox", "sacrifice"]
## Figures drawn inside the sledge sprite (with its rope and the censer priest): each glows as its
## own part of that drawing, and moves with it.
const SLEDGE_PARTS := ["funerary_bier", "priest_with_censer"]

var _descriptions = preload("res://scripts/descriptions.gd").new("procession")
var _inspection_regions := {}
var _inspection_sprites := {}
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
var solved := {"t1": false, "t2": false, "t3": false, "t4": false, "t5": false, "t6": false, "t7": false, "t8": false}
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
var _standard_grab := Vector2.ZERO
var _object_press: MoveableObject
var _object_press_screen := Vector2.ZERO
var _object_dragging := false
var standard_objects := {}

var _drag_from := Vector2.INF  ## where (screen px) the piece in hand was taken up, while the button is down
var _hints = preload("res://scripts/puzzles.gd").new()
var _feedback := {}
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
var bulls: ThreeBulls
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
	for node in find_children("*", "Sprite2D", true, false):
		if node.has_meta("registry_id") and node.has_meta("source_layer_id"):
			_inspection_sprites[node.get_meta("registry_id")] = node
	for region in find_children("*", "Area2D", true, false):
		if not region.has_meta("registry_id"):
			continue
		var id: String = region.get_meta("registry_id")
		assert(not _inspection_regions.has(id), "Duplicate Procession inspection ID: " + id)
		_inspection_regions[id] = region
	for source in level.hotspots:
		var id: String = source.id
		var h := {"id": id, "rect": _descriptions.region_bounds(_inspection_regions[id]), "label": _descriptions.entries[id].name}
		hotspots.append(h)
		if id == "lector_priest":
			_reader = h
		elif id == "offering_table":
			_table = h
		elif id == "lector_with_plumes":
			_lector = h
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
		if not piece in FIXED:
			var item := MoveableObject.new()
			add_child(item)
			item.setup(piece, p)
			standard_objects[piece] = item
	_recital = $pieces/recital
	_bearer_rect = _descriptions.region_bounds($ArtworkLayers/goose_man_77/GooseBearerHit)
	offerings = $pieces/offering_table
	offerings.setup(level.table, sprite_rects.goose, ground, _authored, _bearer_rect, _descriptions.region_bounds(_inspection_regions.lector_priest))
	offerings.changed.connect(_on_offerings_changed)
	haul = $pieces/hauling
	haul.setup(_pieces.ox, $Papyrus.material, self, $Strip.get_index() + 1, _authored)
	haul.said.connect(say_game)
	haul.finished.connect(_check)
	ending = $pieces/ending
	ending.setup(level, _authored, avatar)
	ending.said.connect(say_game)
	ending.changed.connect(func():
		_check()
		_render())
	ending.ended.connect(_ended)
	water = $pieces/water
	water.setup(level, "res://assets/procession/figures/%s.png", _authored)
	water.said.connect(say_game)
	water.finished.connect(_check)
	bulls = $pieces/bulls
	bulls.setup(level, _authored)
	bulls.said.connect(say_game)
	bulls.finished.connect(_check)
	mouth = $pieces/opening_mouth
	mouth.setup(level, _authored, avatar)
	for item in ending.objects.values() + offerings.objects.values() + standard_objects.values() + [mouth.adze_object, mouth.words_object, bulls.plumes_object]:
		item.description_requested.connect(_describe_object)
	mouth.said.connect(say_game)
	mouth.changed.connect(func():
		avatar.keys = not mouth.active
		if mouth.active:
			avatar.stop()
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
	_object_press = null
	_object_dragging = false
	for item in standard_objects.values():
		item.reset()
	_generation += 1
	slot = START.duplicate()
	held = ""
	held_from = ""
	solved = {"t1": false, "t2": false, "t3": false, "t4": false, "t5": false, "t6": false, "t7": false, "t8": false}
	finished = false
	journal.clear()
	_clear_recital()
	offerings.reset()
	haul.reset()
	ending.reset()
	water.reset()
	mouth.reset()
	bulls.reset()
	_set_hover({})
	in_table = false
	_hints.reset()
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
	say("Scribe", PUZZLES.message("procession.start"))
	_render()
	_update_camera(1.0)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or finished:
		return
	if _object_press != null and _carried_input(event):
		return
	if mouth.active:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]):
			mouth.leave()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			mouth.chop(get_global_mouse_position())
		get_viewport().set_input_as_handled()
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
	if bulls.active:    # at the three bulls: drag the calf or the plumes; Esc (or walking off) steps away
		if event.is_action_pressed("ui_cancel"):
			leave_bulls()
			get_viewport().set_input_as_handled()
		else:
			_bulls_input(event)
		return
	if in_table:        # at the offering table: Esc (or walking off with the arrow keys) steps away
		if event.is_action_pressed("ui_cancel"):
			leave_table()
			get_viewport().set_input_as_handled()
		else:
			_table_input(event)
		return
	if ending.held != "":   # a piece of the stand taken off you, following the pointer
		_stand_piece_input(event)
		return
	if mouth.phase == OpeningMouth.Phase.WORDS and event.is_action_pressed("ui_cancel"):
		mouth.put_back()
		return
	if mouth.phase == OpeningMouth.Phase.WORDS and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mouth.home_rect().has_point(get_global_mouse_position()):
			mouth.place_words()
		else:
			mouth.put_back()
		return
	if event is InputEventMouseMotion:
		_set_hover(_pick(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_world(get_global_mouse_position())


func _describe_object(object_id: String, description_key: String) -> void:
	if _descriptions.entries.has(description_key):
		_descriptions.show(description_key, hud, _description_variant(description_key))
	elif object_id == "plumes":
		_descriptions.show("plumed_ox", hud, _description_variant("plumed_ox"))
	else:
		# Missing individual descriptions are left for the content author.
		var label: String = EndingStand.NAMES.get(object_id, NAMES.get(object_id, object_id.replace("_", " ")))
		if object_id in ["mouth_adze", "mouth_words"]:
			label = "the adze" if object_id == "mouth_adze" else "the words"
		if offerings.objects.has(object_id):
			label = offerings.name_of(object_id)
		say_game(label.capitalize(), label.capitalize())


func _begin_carried(item: MoveableObject, p: Vector2) -> void:
	_object_press = item
	_object_press_screen = get_canvas_transform() * p
	_object_dragging = false
	item.request_description()


func _carried_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		if _object_dragging:
			if ending.held != "":
				ending.unhold()
			else:
				_object_press.cancel_hold()
		_object_press = null
		_object_dragging = false
		return true
	if event is InputEventMouseMotion:
		if not _object_dragging and event.position.distance_to(_object_press_screen) > DRAG:
			if ending.objects.values().has(_object_press):
				ending.hold(_object_press.id)
			else:
				_object_press.hold()
			_object_dragging = true
			_object_press.request_description()
		if _object_dragging:
			_object_press.move_held(get_global_mouse_position())
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if _object_dragging:
				if ending.objects.values().has(_object_press):
					if ending.place_rect().has_point(get_global_mouse_position()):
						ending.set_down()
					else:
						ending.unhold()
				else:
					_object_press.cancel_hold()
					if mouth.mummy_rect().has_point(get_global_mouse_position()):
						enter_mouth()
			_object_press = null
			_object_dragging = false
		return true
	return false


## Exploration clicks approach a subject before its action; minigames own their input.
func _click_world(p: Vector2) -> void:
	var h := _pick(p)
	if h.is_empty():
		walk_then(p.x)
	elif h.type == "worn":
		_begin_carried(ending.objects[h.id], p)
	elif h.type == "worn_adze":
		_begin_carried(mouth.adze_object, p)
	elif h.type == "goose_locked":
		say_game("Goose-bearer", PUZZLES.text("procession.goose", "feedback", "goose_refuses"))
	elif h.type == "offering_placed":
		offerings.objects[h.id].request_description()
	elif h.type == "plumes_locked":
		bulls.plumes_object.request_description()
	elif h.type == "ending":
		walk_then(_reach(ending.place_rect() if h.id == "place" else ending.rect_of(h.id), p), act_ending.bind(h.id))
	elif h.type == "bearer":   # observe him after approaching; the lector starts the puzzle
		walk_then(_reach(_bearer_rect, p), _describe_bearer)
	elif h.type == "hot" and h.spot == _table and solved.t3:
		walk_then(_reach(h.spot.rect, p), record.bind(h.spot))
	elif h.type == "piece" or (h.type == "hot" and (h.spot == _table or h.spot == _reader)):
		enter_table(h.get("spot", {}) == _reader)
	elif h.type == "mouth":
		if mouth.phase == OpeningMouth.Phase.ADZE and h.id == "back":
			_descriptions.show("offering_stand", hud)
		else:
			act_mouth(h.id, p)
	elif h.type == "hot" and h.spot.id in BULL_FIGURES and not bulls.done:
		enter_bulls(h.spot)
	elif h.type == "water" or (h.type == "hot" and h.spot.id in WATER_FIGURES and not water.done):
		enter_water(h.get("spot", {}))
	elif h.type == "caption":
		_descriptions.show(h.id, hud)
	elif h.type == "slot":
		if solved.t2:
			say_game("Standard-bearers", PUZZLES.text("procession.standards", "success"))
		else:
			enter_standards()
	elif h.spot.id in HAUL_FIGURES and not haul.done:
		if h.spot.id in ["ox_driver", "hauler"]:   # you walk to the hauler's place and take up his rope
			var hl: Dictionary = level.sprites.haul_hauler
			walk_then(hl.x + hl.w / 2.0, take_rope.bind(h.spot))
		else:
			walk_then(_reach(h.rect, p), record.bind(h.spot))
	elif h.spot.id == "hauler":   # home: he has his rope again
		walk_then(_reach(h.spot.rect, p), func():
			say_game("Hauler", PUZZLES.text("procession.haul", "feedback", "success_hauler"))
			_add_journal(h.spot))
	elif h.spot == _lector:   # stand in front of him (he faces left), to hear him
		walk_then(h.spot.rect.position.x - STAND_GAP * unit - sprite_rects.avatar.size.x / 2.0, record.bind(h.spot))
	else:
		walk_then(_reach(h.spot.rect, p), record.bind(h.spot))


## What is under the pointer: a loose offering, a hidden piece of the offering stand or its place,
## the goose-bearer, a placed piece or slot, then a journal hotspot.
func _pick(p: Vector2) -> Dictionary:
	if mouth.phase == OpeningMouth.Phase.ADZE and not mouth.active and mouth.adze_object.contains_point(p):
		return {"type": "worn_adze", "id": "mouth_adze"}
	if in_table and offerings.loaf_at(p):
		return {"type": "bearer_loaf", "id": offerings.bearer}
	if offerings.goose_at(p):
		return {"type": "goose_locked", "id": "goose"}
	if bulls.plumes_object.locked_in_place and bulls.plumes_object.contains_point(p):
		return {"type": "plumes_locked", "id": "plumes"}
	var off := offerings.pick(p)
	if off != "":
		return {"type": "piece", "id": off}
	var placed_offering := offerings.placed_at(p)
	if placed_offering != "":
		return {"type": "offering_placed", "id": placed_offering}
	var w := ending.worn_at(p)
	if w != "":
		return {"type": "worn", "id": w}
	var e := ending.pick(p)
	if e != "":
		return {"type": "ending", "id": e}
	var m := mouth.pick(p)
	if m != "":
		return {"type": "mouth", "id": m}
	if not water.active and water.on_jar(p):   # from along the scroll: step up to the water
		return {"type": "water"}
	_bearer_rect = _descriptions.region_bounds($ArtworkLayers/goose_man_77/GooseBearerHit)
	if _bearer_rect.has_point(p):
		return {"type": "bearer", "rect": _bearer_rect}
	for id in slot:
		var piece: String = slot[id]
		if piece != "" and _pieces[piece].visible and _descriptions.sprite_bounds(_pieces[piece]).has_point(p):
			return {"type": "slot", "id": id, "rect": _descriptions.sprite_bounds(_pieces[piece])}
	for id in SLOTS:
		var r := _slot_hit_rect(id)
		if r.has_point(p):
			return {"type": "slot", "id": id, "rect": r}
	for h in hotspots:
		h.rect = _descriptions.region_bounds(_inspection_regions[h.id])
		if h.rect.has_point(p):
			return {"type": "hot", "spot": h, "rect": h.rect}
	for c in CAPTIONS:
		var r := _descriptions.region_bounds(_inspection_regions[c.id])
		if r.has_point(p):
			return {"type": "caption", "id": c.id, "spell": c.spell, "rect": r}
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
		"worn":
			return [ending.sprite_of(h.id)]
		"worn_adze":
			return [mouth.adze_object.sprite]
		"bearer_loaf":
			return [offerings._bearer_sprite]
		"goose_locked":
			return offerings.bearer_sprites()
		"offering_placed":
			return [offerings.objects[h.id].sprite]
		"plumes_locked":
			return [bulls.plumes_sprite()]
		"ending":   # a hidden piece glows; the empty place glows with what already stands there
			if h.id != "place":
				return [ending.sprite_of(h.id)]
			return [ending.place_rect()] + ending.placed.keys().map(func(nm): return ending.sprite_of(nm))
		"bearer":
			return [_bearer_rect] + offerings.bearer_sprites()
		"water":   # his forearm and jar
			return [water.arm_sprite()]
		"mouth":
			return [mouth.glow_target(h.id)]
		"bull":
			return [bulls.calf_sprite() if h.id == "calf" else bulls.plumes_sprite()]
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
			if PIECE_GLOW.has(h.spot.id):
				return [_pieces[PIECE_GLOW[h.spot.id]]]
			match h.spot.id:   # the bulls: sprites now (the sacrifice, in the strip, with the plumes while they sit on it)
				"calf":
					return [bulls.calf_sprite()]
				"plumed_ox":
					return [bulls.ox_sprite()] + ([bulls.plumes_sprite()] if bulls.crowned() else [])
				"sacrifice":
					return [_inspection_sprites[h.spot.id]] + ([] if bulls.crowned() else [bulls.plumes_sprite()])
			if HAUL_GLOW.has(h.spot.id):
				return HAUL_GLOW[h.spot.id].map(func(nm): return haul.sprite_of(nm)).filter(func(sp): return sp != null and sp.is_visible_in_tree())
			if h.spot == _table and solved.t3:   # rebuilt: the whole table glows, its offerings with it
				return [_inspection_sprites[h.spot.id]] + offerings.placed_sprites()
			if h.spot.id == "offering_stand":   # part for whole: the stand glows with all on it
				return [_inspection_sprites[h.spot.id]] + mouth.on_stand()
			if h.spot.id in SLEDGE_PARTS:   # its own part of the sledge's drawing
				var sprite := haul.sprite_of("haul_sledge")
				var r: Rect2 = _descriptions.region_bounds(_inspection_regions[h.spot.id])
				return [{"sprite": sprite, "region": sprite.global_transform.affine_inverse() * r}]
			if h.spot.id == "priest_with_jar":   # he is a sprite now, his arm with him
				return [water.priest_sprite(), water.arm_sprite()]
			return [_inspection_sprites[h.spot.id]] if _inspection_sprites.has(h.spot.id) else [h.spot.rect]
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
		# Static figures are separate scene sprites; use their flat reference for region glows.
		(g.texture as AtlasTexture).atlas = ILLUSTRATION
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
	var region: Area2D = $ArtworkLayers/standard_bearers_131.get_node(id)
	var bounds := _descriptions.region_bounds(region)
	if slot.get(id, "") != "":
		bounds = bounds.merge(_descriptions.sprite_bounds(_pieces[slot[id]]))
	return bounds


# ---------------------------------------------------------------- movement

## The whole scroll is open to walk.
func min_x() -> float:
	return 60.0 * unit


func max_x() -> float:
	return level.width - 60.0 * unit


func procession_moving() -> bool:
	return solved.t1 and solved.t2


## Where you walk to deal with what is at `r`, clicked at `p` (unless it has a place of its own to
## stand): the nearest point of it to where you are, its left or right edge; already in front of it,
## where you clicked (its middle, without a click).
func _reach(r: Rect2, p := Vector2.INF) -> float:
	var x := avatar.position.x
	if x >= r.position.x and x <= r.end.x:
		return r.get_center().x if p == Vector2.INF else clampf(p.x, r.position.x, r.end.x)
	return clampf(x, r.position.x, r.end.x)


## Walk toward x and run `then` on arrival.
func walk_then(x: float, then := Callable()) -> void:
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	avatar.walk_to(clampf(x, avatar.min_x, avatar.max_x), func():
		if then.is_valid():
			then.call())


# ---------------------------------------------------------------- the three bulls

## Step up to the three bulls: you stand right of the plumed ox and the camera holds all three.
## `h` is the figure clicked, recorded on arrival.
func enter_bulls(h := {}) -> void:
	if bulls.active or bulls.done:
		return
	if _hands_full():
		say_game("Scribe", _hands_message())
		return
	_set_hover({})
	walk_then(bulls.stand_x(), func():
		if not h.is_empty():
			_add_journal(h)
		avatar.stop()
		avatar.facing = -1
		bulls.enter())


func leave_bulls() -> void:
	if not bulls.active:
		return
	bulls.leave()
	_set_hover({})


## Each animal can be inspected; calf and plumes still use the same drag controls.
func _bull_subject_at(p: Vector2) -> String:
	if bulls.pick(p) == "plumes":
		return "plumed_ox" if bulls.crowned() else "sacrifice"
	for id in BULL_FIGURES:
		if _descriptions.region_bounds(_inspection_regions[id]).has_point(p):
			return id
	return ""


func _bulls_press(p: Vector2) -> void:
	if bulls.plumes_object.locked_in_place and bulls.plumes_object.contains_point(p):
		bulls.plumes_object.request_description()
		return
	var subject := _bull_subject_at(p)
	if subject != "":
		var h: Dictionary = hotspots.filter(func(spot): return spot.id == subject)[0]
		h.rect = _descriptions.region_bounds(_inspection_regions[subject])
		var content := _descriptions.line(subject, _description_variant(subject))
		say_game(content.speaker, content.text)
		_add_journal(h)
	var b := bulls.pick(p)
	if b != "":
		bulls.press(b, p)
		_set_hover({})


func _bulls_input(event: InputEvent) -> void:
	var p := get_global_mouse_position()
	if event is InputEventMouseMotion:
		if bulls.held != "":
			bulls.drag(p)
		else:
			var b := bulls.pick(p)
			var subject := _bull_subject_at(p)
			if b != "":
				_set_hover({"type": "bull", "id": b})
			elif subject != "":
				var h: Dictionary = hotspots.filter(func(spot): return spot.id == subject)[0]
				_set_hover({"type": "hot", "spot": h})
			else:
				_set_hover({})
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			_bulls_press(p)
		elif bulls.held != "":
			bulls.release(p)


# ---------------------------------------------------------------- the offering table scene

## Step up to the offering table: you stand just behind the lector and the camera holds on the
## table, from the man with the jar to the goose-bearer. `ask` has the lector show a piece at once.
func enter_table(ask := false) -> void:
	if in_table:
		if ask:
			record(_reader)
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
	_set_hover({"type": "hot", "spot": _reader, "rect": _reader.rect})
	if not solved.t3:
		say_game("Lector priest", PUZZLES.text("procession.offerings", "instructions"))


## Step away from the table (Esc, or walking off): what you hold goes back; nothing is lost.
func leave_table() -> void:
	if not in_table:
		return
	if offerings.holding() != "":
		offerings.put_back()
	_drag_from = Vector2.INF
	in_table = false
	_set_hover({})


## At the table: press-drag-release a piece to set it down: in its place, in the band above, back to the
## goose-bearer, or onto the floor.
## While rebuilding, the table itself is not something to point at.
func _table_pick(p: Vector2) -> Dictionary:
	var h := _pick(p)
	return {} if h.get("spot", {}) == _table and not solved.t3 else h


func _table_input(event: InputEvent) -> void:
	var p := get_global_mouse_position()
	if event is InputEventMouseMotion:
		if offerings.snap_held(p):
			_drag_from = Vector2.INF
		_set_hover(_table_pick(p))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var h := _table_pick(p)
			if h.get("type") == "hot" and h.spot == _reader:
				record(_reader)
				return
			if offerings.holding() != "":
				return
			match h.get("type", ""):
				"goose_locked":
					say_game("Goose-bearer", PUZZLES.text("procession.goose", "feedback", "goose_refuses"))
				"offering_placed":
					offerings.objects[h.id].request_description()
				"piece":
					_take_offering(h.id)
				"bearer_loaf":
					_act_bearer()
				"bearer":
					_describe_bearer()
				"hot":
					record(h.spot)
			if offerings.holding() != "":
				_drag_from = event.position
				if h.get("type") != "bearer_loaf":
					offerings.objects[offerings.holding()].request_description()
				_set_hover({})
		else:
			if offerings.holding() != "":
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
		say_game("Scribe", _hands_message())
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
		say_game("Scribe", _hands_message())
		return
	if offerings.holding() != "":
		say_game("Scribe", PUZZLES.message("interaction.already_carrying") % offerings.held_name())
		return
	offerings.take(id)


func _drop_offering(p: Vector2) -> void:
	match offerings.drop_at(p):
		"toppled":
			_tell_once("support", PUZZLES.text("procession.offerings", "feedback", "missing_support"))


func _describe_bearer() -> void:
	var key := "success_carrying" if offerings.bearer == "goose" else ("holding_loaf" if offerings.bearer != "" else "instructions_empty")
	say_game("Goose-bearer", PUZZLES.text("procession.goose", "feedback", key))


func _act_bearer() -> void:
	if held != "" and offerings.holding() == "":
		say_game("Scribe", PUZZLES.text("procession.goose", "feedback", "wrong_item") % _cap(NAMES[held]))
		return
	match offerings.bearer_act():
		"took":
			say_game("Goose-bearer", PUZZLES.text("procession.goose", "instructions"))
		"gave":
			say_game("Goose-bearer", PUZZLES.text("procession.goose", "success"))
		"swapped":
			say_game("Goose-bearer", PUZZLES.text("procession.goose", "feedback", "success_swapped"))
		"wrong":
			offerings.reject_held()
		"empty":
			say_game("Scribe", PUZZLES.text("procession.goose", "feedback", "instructions_empty"))
		"has_goose":
			say_game("Goose-bearer", PUZZLES.text("procession.goose", "feedback", "success_carrying"))


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
		say_game("Standard-bearers", PUZZLES.text("procession.standards", "instructions")))


func leave_standards() -> void:
	put_back()
	in_standards = false
	_set_hover({})


func act_slot(id: String) -> void:
	var s: Dictionary = SLOTS[id]
	var here: String = slot[id]
	if solved.t2:   # in order: they stay so
		say_game("Standard-bearers", PUZZLES.text("procession.standards", "success"))
		return
	if mouth.carrying() != "":
		say_game("Scribe", _hands_message())
		return
	if held == "":
		if here == "":
			say_game("Scribe", PUZZLES.text("procession.standards", "feedback", "empty_pole"))
			return
		held = here
		held_from = id
		slot[id] = ""
		standard_objects[held].hold(Transform2D(0.0, -_standard_grab))
		say_game("Scribe", PUZZLES.text("procession.standards", "feedback", "standard_taken") % [NAMES[here], s.label])
	else:
		if kind_of(held) != s.kind:
			say_game("Scribe", PUZZLES.text("procession.standards", "feedback", "wrong_pole") % [_cap(NAMES[held]), s.label])
			return
		slot[id] = held
		if here != "" and held_from != "":   # the one there goes where yours came from
			slot[held_from] = here
			say_game("Scribe", PUZZLES.text("procession.standards", "feedback", "standards_swapped") % [NAMES[held], s.label, NAMES[here], SLOTS[held_from].label])
		else:
			say_game("Scribe", PUZZLES.text("procession.standards", "feedback", "standard_placed") % [NAMES[held], s.label])
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
				_standard_grab = p - _pieces[slot[h.id]].position
				act_slot(h.id)
				if held != "":
					standard_objects[held].request_description()
				_set_hover({})
		elif held != "":
			_drop_standard(p)


## The standard (its top: the emblem on the pole) under the pointer.
func _standard_at(p: Vector2) -> Dictionary:
	for id in POLES:
		if slot[id] != "":
			var r := _descriptions.sprite_bounds(_pieces[slot[id]])
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
		say_game("Scribe", _hands_message())
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


## Release a dragged stand piece at its valid place; an invalid drop or Esc returns it to you.
func _stand_piece_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		ending.unhold()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ending.place_rect().has_point(get_global_mouse_position()):
			ending.set_down()
		else:
			ending.unhold()


## Off the rope (let go, or the sledge is home): you fade back in and walk again.
func _off_rope() -> void:
	_hauling = false
	avatar.rotation = 0.0
	avatar.set_process(true)
	if haul.instant:
		avatar.modulate.a = 1.0
	else:
		create_tween().tween_property(avatar, "modulate:a", 1.0, INTO_POSE)


## A piece of the offering stand: take it from where it lies hidden (it goes onto you), or set
## what you have at its place before Ra.
func act_ending(id: String) -> void:
	if id == "place":
		if ending.held != "":
			ending.set_down()
		else:
			_describe_object("stand", "stand")
	elif not ending.imprint_shown:   # not before the stela shows what they are for
		say_game(EndingStand.TAGS[id], PUZZLES.text("procession.offering_stand", "feedback", "not_ready_to_collect"))
	elif _hands_full():
		say_game("Scribe", _hands_message())
	else:
		ending.take(id)
	_set_hover({})


## `quiet`: no word said (a dragged standard let go away from the poles goes back without comment).
func put_back(quiet := false) -> void:
	if ending.held != "":
		ending.unhold()
		return
	if mouth.carrying() != "":
		mouth.put_back()
		say_game("Scribe", PUZZLES.message("interaction.put_back") % ("the adze" if mouth.phase == OpeningMouth.Phase.START else "the words"))
		return
	if held == "":
		return
	if held_from != "" and slot[held_from] == "":
		slot[held_from] = held
		if not quiet:
			say_game("Scribe", PUZZLES.message("interaction.put_back") % NAMES[held])
	else:
		return
	held = ""
	held_from = ""
	_check()
	_render()


## Every rite but the stand before Ra: hauling, standards, table, goose, water, mouth and bulls.
func rites_done() -> bool:
	return solved.t1 and solved.t2 and solved.t3 and solved.t4 and solved.t5 and solved.t6 and solved.t8


## Something is in your hands: a standard, an offering, the adze, the words or a piece of the stand.
func _hands_full() -> bool:
	return held != "" or offerings.holding() != "" or mouth.carrying() != "" or ending.held != ""


## The Opening of the Mouth: take the adze, touch it to the mummy, take the words it speaks, and
## set them at their imprint over Ra.
func _mouth_stand_x() -> float:
	return $pieces/opening_mouth/StandPosition.global_position.x


## Clear the mummy's face before entering the close view.
func enter_mouth() -> void:
	walk_then(_mouth_stand_x(), func():
		avatar.stop()
		avatar.facing = -1
		mouth.touch())


func act_mouth(id: String, p := Vector2.INF) -> void:
	match id:
		"adze", "words":
			if _hands_full():
				say_game("Scribe", _hands_message())
				return
			if id == "adze":
				walk_then(_reach(mouth.back_rect(), p), mouth.take_adze)
			else:
				walk_then(_reach(mouth.words_rect(), p), func():
					mouth.take_words()
					mouth.words_object.request_description())
		"mummy":
			_descriptions.show("anubis_and_the_mummy", hud, _description_variant("anubis_and_the_mummy"))
		"home":
			walk_then(_reach(mouth.home_rect(), p), mouth.place_words)
		"back":     # where the adze or the words were taken from: they go back there
			walk_then(_reach(mouth.back_rect(), p), put_back)
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
	solved.t8 = bulls.done
	var rites := rites_done()
	var were: bool = was.t1 and was.t2 and was.t3 and was.t4 and was.t5 and was.t6 and was.t8
	if solved.t1 and not was.t1:
		say_game("Ox-driver", PUZZLES.text("procession.haul", "success"))
		var o: Dictionary = level.sprites.ox
		var sl: Dictionary = level.sprites.haul_sledge
		_kick_dust(Rect2(o.x, 0, sl.x + sl.w - o.x, 0))
		_success([_pieces.ox] + ["haul_sledge", "haul_rope", "haul_hauler", "haul_driver", "haul_driver_arm"].map(haul.sprite_of))
		avatar.position.x = level.sprites.haul_hauler.x + level.sprites.haul_hauler.w + BESIDE * unit
		_off_rope()
	if solved.t2 and not was.t2:
		say_game("Standard-bearers", PUZZLES.text("procession.standards", "success"))
		_success(POLES.map(func(p): return _pieces[slot[p]]))
	if solved.t3 and not was.t3:
		_success([_table.rect] + offerings.placed_sprites())
	if solved.t4 and not was.t4:
		_success(offerings.bearer_sprites())
	if solved.t5 and not was.t5:
		_success([water.priest_sprite(), water.arm_sprite(), water.stream_sprite()])
	if solved.t6 and not was.t6:
		_success([mouth.glow_target("words"), mouth.glow_target("adze"), mouth.glow_target("mummy")])
	if solved.t8 and not was.t8:
		_success([bulls.calf_sprite(), bulls.ox_sprite(), bulls.plumes_sprite()])
	if solved.t7 and not was.t7:
		_success(EndingStand.PIECES.map(ending.sprite_of))
	if rites and not were:
		ending.show_imprint()     # the stela only shows the stand once everything else is right
	if rites and not were and not solved.t7:
		hud.say_later("Scribe", PUZZLES.message("procession.complete"), 1.6, "minigame")
	if solved.values().all(func(v): return v) and not was.values().all(func(v): return v):
		var generation := _generation
		get_tree().create_timer(1.2, false).timeout.connect(func():
			if generation == _generation:
				finish())


## Clicking a figure: record it in the journal, and run the figures that do something.
func record(h: Dictionary) -> void:
	if h.id == "ra_enthroned":
		ending.show_base_clue()
	if h == _lector:  # describe him as he reads out the signs; stand before him, facing him
		_add_journal(h)
		say_game(h.label, _descriptions.text(h.id) + " " + PUZZLES.text("procession.standards", "feedback", "speaking"))
		avatar.facing = 1
		recite()
		return
	if h == _table and solved.t3:
		say_game("Scribe", PUZZLES.text("procession.offerings", "success"))
		return
	if h == _reader and not solved.t3:  # he shows, in front of him, an offering that can go on now
		_add_journal(h)
		say_game("Lector priest", PUZZLES.text("procession.offerings", "feedback", "speaking"))
		offerings.speak()
		return
	_descriptions.inspect(h.id, hud, journal, _inspection_picture(h), hotspots.size(), _description_variant(h.id))


func _description_variant(id: String) -> String:
	match id:
		"anubis_and_the_mummy":
			return "unopened" if mouth.phase in [OpeningMouth.Phase.START, OpeningMouth.Phase.ADZE] else "default"
		"offering_table":
			return "default" if solved.t3 else "collapsed"
		"stela":
			return "default" if ending.imprint_shown else "blank"
		"calf":
			return "settled" if bulls.calf_turned() else "unsettled"
		"sacrifice", "plumed_ox":
			return "default" if bulls.done else "unresolved"
	return "default"


func _add_journal(h: Dictionary) -> void:
	_descriptions.remember(h.id, hud, journal, _inspection_picture(h), hotspots.size(), _description_variant(h.id))


func _inspection_picture(h: Dictionary) -> Texture2D:
	return _inspection_sprites[h.id].texture if _inspection_sprites.has(h.id) else _journal_picture(h.rect)


## The strip under `r`, with the figures that are sprites now (the hauling, the water priest,
## and the stream once it runs) drawn in as drawn.
func _journal_picture(r: Rect2) -> Texture2D:
	var overlays: Array = HaulSledge.PIECES + ["ox", "water_priest", "calf", "plumed_ox", "plumes", "mouth_mummy", "mouth_features"] + (["water_stream"] if water.done else [])
	overlays = overlays.filter(func(nm): return r.intersects(_drawn_rect(nm)))
	if overlays.is_empty():
		var tex := AtlasTexture.new()
		tex.atlas = ILLUSTRATION
		tex.region = r
		return tex
	if _strip_img == null:
		_strip_img = ILLUSTRATION.get_image()
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
	var folder := "animation" if SHEETS.has(nm) else "figures"
	var src: Image = load("res://assets/procession/%s/%s.png" % [folder, SHEETS.get(nm, nm)]).get_image()
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
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/procession/animation/%s.json" % SHEETS[nm]))


## Everything is in order: you walk to the adorer's place before Ra and kneel there, and the light
## takes the scene (see ending.gd). For now the level then goes back to the menu.
func finish() -> void:
	if finished:
		return
	finished = true
	_set_hover({})
	_render()
	say_game("Lector priest", PUZZLES.message("procession.kneel"))
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
		say_game("Scribe", text)


func _hands_message() -> String:
	var item: String = NAMES.get(held, "")
	if offerings.holding() != "":
		item = offerings.held_name()
	if mouth.carrying() != "":
		item = "the adze" if mouth.carrying() == "adze" else "the words"
	if ending.held != "":
		item = ending.held_name()
	return PUZZLES.message("interaction.hands_full") % item


func _show_hint(puzzle: String, phase := "", destination := "default") -> void:
	say("Hint", _hints.find(puzzle, destination) if phase == "" else _hints.advance(puzzle, phase))


func _stand_hint_phase() -> String:
	return "assemble" if EndingStand.PIECES.all(func(id): return id in ending.worn or ending.placed.has(id) or ending.held == id) else "collect"


func hint() -> void:
	if mouth.active and not solved.t6:
		_show_hint("procession.opening_mouth", "carve")
	elif haul.active and not solved.t1:
		_show_hint("procession.haul", "pull")
	elif (in_standards or (held != "" and kind_of(held) == "std")) and not solved.t2:
		_show_hint("procession.standards", "sort")
	elif in_table and not solved.t4 and (offerings.holding() == "goose" or solved.t3):
		_show_hint("procession.goose", "give_goose" if offerings.holding() == "goose" else ("find_goose" if offerings.bearer == "" else "return"))
	elif in_table and not solved.t3:
		_show_hint("procession.offerings", "build")
	elif bulls.active and not solved.t8:
		_show_hint("procession.bulls", "plumes" if bulls.calf_turned() else "calf")
	elif water.active and not solved.t5:
		_show_hint("procession.water", "pour")
	elif mouth.carrying() == "adze" and not solved.t6:
		_show_hint("procession.opening_mouth", "", "adze")
	elif not solved.t6 and mouth.phase in [OpeningMouth.Phase.SPOKEN, OpeningMouth.Phase.WORDS]:
		_show_hint("procession.opening_mouth", "words" if mouth.carrying() == "words" else "", "words")
	elif ending.imprint_shown and not solved.t7 and (not ending.worn.is_empty() or ending.held != "" or absf(avatar.position.x - ending.place_rect().get_center().x) <= 350.0 * unit):
		_show_hint("procession.offering_stand", _stand_hint_phase())
	else:
		# Find points to nearby unfinished work; otherwise retain the level's task order.
		var tasks := [
			{"id": "procession.haul", "done": solved.t1, "x": _authored.haul_driver.global_position.x},
			{"id": "procession.standards", "done": solved.t2, "x": (_slot_hit_rect("pole1").position.x + _slot_hit_rect("pole8").end.x) / 2.0},
			{"id": "procession.offerings", "done": solved.t3, "x": _table.rect.get_center().x},
			{"id": "procession.goose", "done": solved.t4, "x": _bearer_rect.get_center().x},
			{"id": "procession.water", "done": solved.t5, "x": water.priest_sprite().global_position.x},
			{"id": "procession.bulls", "done": solved.t8, "x": bulls.calf_sprite().global_position.x},
			{"id": "procession.opening_mouth", "done": solved.t6, "x": _authored.mouth_adze.global_position.x},
		]
		if ending.imprint_shown:
			tasks.append({"id": "procession.offering_stand", "done": solved.t7, "x": ending.place_rect().get_center().x})
		var first := ""
		var nearby := ""
		var distance := 450.0 * unit
		for task in tasks:
			if task.done:
				continue
			if first == "":
				first = task.id
			var gap: float = absf(avatar.position.x - task.x)
			if gap < distance:
				distance = gap
				nearby = task.id
		var chosen: String = nearby if nearby != "" else first
		if chosen == "":
			say("Hint", _hints.message("procession.complete"))
		else:
			var destination := "default"
			if chosen == "procession.goose" and offerings.bearer == "":
				destination = "empty"
			elif chosen == "procession.haul" and avatar.position.x < _authored.haul_driver.global_position.x:
				destination = "right"
			_show_hint(chosen, "", destination)


func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


func say_game(who: String, text: String) -> void:
	_last_said = text
	hud.say(who, text, "minigame")


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
	if bulls.active and Input.get_axis("ui_left", "ui_right") != 0.0:
		leave_bulls()
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
	if held != "":
		standard_objects[held].move_held(get_global_mouse_position())
	hud.update_held("", null, camera.zoom.x)
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
	if in_table or water.active or in_standards or haul.active or bulls.active:   # hold on the whole scene: the table, the water, the hauling, the bulls
		var v: Vector2 = _standards_view if in_standards else (water.view() if water.active else _haul_view() if haul.active else bulls.view() if bulls.active else Vector2(level.table.view[0], level.table.view[1]))
		z = clampf(minf(fit, vp.x / (v.y - v.x + 2.0 * SCENE_MARGIN)), 0.2 / unit, 2.4 / unit)
		target_x = (v.x + v.y) / 2.0
	var focus := "mouth" if mouth.active else "table" if in_table else "water" if water.active else "standards" if in_standards else "haul" if haul.active else "bulls" if bulls.active else ""
	if mouth.active:
		var face := mouth.face_view()
		z = minf((vp.y - top - bottom - 20.0) / face.size.y, vp.x / (face.size.x + 80.0))
		target_x = face.get_center().x
	if focus != _focus:
		var face_transition := focus == "mouth" or _focus == "mouth"
		_focus = focus
		_refocus = {"t": 0.0, "z": camera.zoom.x, "x": camera.position.x, "y": camera.position.y, "face": face_transition} if delta < 1.0 else {}
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
	if mouth.active:
		var face_y := mouth.face_view().get_center().y + (bottom - top) / 2.0 / z
		camera.position.y = lerpf(_refocus.y, face_y, smoothstep(0.0, REFOCUS, _refocus.t)) if not _refocus.is_empty() else face_y
	elif not _refocus.is_empty() and _refocus.face:
		var normal_y := VIEW_TOP + (vp.y / 2.0 - top) / z if FRAME_FROM_TOP else SCROLL_CAMERA.vertical_center(_view_height(), top, bottom, z, VIEW_TOP)
		camera.position.y = lerpf(_refocus.y, normal_y, smoothstep(0.0, REFOCUS, _refocus.t))
	elif FRAME_FROM_TOP:
		camera.position.y = VIEW_TOP + (vp.y / 2.0 - top) / z
	else:
		camera.position.y = SCROLL_CAMERA.vertical_center(_view_height(), top, bottom, z, VIEW_TOP)


## While hauling the camera holds still on the train and the road ahead of the ox, from the
## ox's nose to the hauler where he stands back at the start: the train comes up toward it.
func _haul_view() -> Vector2:
	var o: Dictionary = level.sprites.ox
	var h: Dictionary = level.sprites.haul_hauler
	return Vector2(o.x - HAUL_AHEAD * unit, h.x + h.w + HaulSledge.BACK)


## Rows the camera fits on screen: the strip and the visible text beneath it.
func _view_height() -> float:
	return level.get("view_height", level.height)


func _visible_rect() -> Rect2:
	return SCROLL_CAMERA.visible_rect(camera, get_viewport_rect().size)


# ---------------------------------------------------------------- drawing

func _render() -> void:
	for p in _pieces.values():
		p.visible = false
		p.z_index = 0
	if held != "":
		_pieces[held].visible = true
		_pieces[held].z_index = 10
		standard_objects[held].move_held(get_global_mouse_position())
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
		standard_objects[piece].set_to_loc(_pieces[piece].get_parent(), Transform2D(0.0, home.position + _seat(SLOTS[id].home) - _seat(piece)), 0)
		standard_objects[piece].place()
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
			for nm in EndingStand.PIECES:
				ending.take(nm)
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
		elif a == "--mouth" or a == "--open-mouth":   # dev: carve the face, or show its spoken words
			hud.dismiss_intro()
			mouth.take_adze()
			avatar.position.x = _mouth_stand_x()
			mouth.touch()
			if a == "--open-mouth":
				for stroke in mouth._curves.size():
					while mouth.active and not mouth.stroke_done(stroke):
						mouth.strike(mouth.next_chip(stroke))
			_update_camera(1.0)
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
		if h.get("type") in ["piece", "ending", "water"]:
			continue
		if h.get("type") != "hot" or h.spot != spot:
			missed.append(spot.label)
	expect.call(missed.is_empty(), "every region picked by a click at its centre %s" % [missed])
	_set_hover(_pick(_slot_hit_rect("pole1").get_center()))
	expect.call(_glows.size() == 16 and _glows[1].get_parent() == _pieces[slot.pole1], "a standard-bearer glows whole under the pointer: the man and his standard")
	_set_hover(_pick(hotspots[0].rect.get_center()))
	expect.call(_glows.size() == 1 and _glows[0].get_parent() == _inspection_sprites[hotspots[0].id], "a journal figure glows under the pointer")
	_set_hover({})
	expect.call(_glows.is_empty(), "nothing glows when the pointer leaves")
	var was := avatar.position.x
	var thing := Rect2(level.width / 2.0, 200.0, 100.0, 300.0)
	avatar.position.x = thing.position.x - 300.0
	var from_left := _reach(thing, thing.get_center())
	avatar.position.x = thing.end.x + 300.0
	var from_right := _reach(thing, thing.get_center())
	avatar.position.x = thing.position.x + 20.0
	var in_front := _reach(thing, thing.position + Vector2(70.0, 50.0))
	avatar.position.x = was
	expect.call(from_left == thing.position.x and from_right == thing.end.x and in_front == thing.position.x + 70.0,
		"clicking a thing walks you to its nearer edge, or, in front of it already, to where you clicked")
	var stand: Dictionary = hotspots.filter(func(h): return h.id == "offering_stand")[0]
	_set_hover(_pick(stand.rect.get_center()))
	expect.call(_glows.size() == 4 and _glows[0].get_parent() == _inspection_sprites[stand.id], "the adze's stand glows whole, with the rods, the foreleg and the adze")
	_set_hover(_pick(mouth.glow_target("adze").position + Vector2(10, 10)))
	expect.call(_glows.size() == 1 and _glows[0].get_parent() == mouth.glow_target("adze"), "the adze alone glows alone")
	for figure in PIECE_GLOW:   # pieces, not in the strip: their own drawings glow
		_set_hover(_pick(hotspots.filter(func(h): return h.id == figure)[0].rect.get_center()))
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
	expect.call(_pick(hauler.rect.get_center()).get("spot") == hauler, "the empty rope can be clicked")
	var rope := haul.sprite_of("haul_rope")
	var shook := false
	for i in 240:
		step.call(1.0 / 60.0)
		shook = shook or rope.rotation != 0.0
	expect.call(shook, "the empty rope shudders now and then")
	take_rope(hauler)
	expect.call(haul.active and is_equal_approx(haul.offset, HaulSledge.BACK), "taking up the rope sets the sledge back and opens the vignette")
	expect.call(avatar.modulate.a == 0.0 and haul.hauler_shown(), "you become the original hauler while holding the rope")
	expect.call(rope.rotation == 0.0, "held, the rope is still")
	var whip := haul.sprite_of("haul_driver_arm")
	step.call(0.002)
	expect.call(absf(whip.rotation + HaulSledge.STRIKE * HaulSledge.COUNT_SWING) < 0.02, "on the count the whip only flicks")
	step.call(haul.to_next_beat())
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
	expect.call(not mouth._imprint.visible and not mouth._words.visible, "the caption is empty before the face is finished")
	var h := _pick(Rect2(adze.x, adze.y, adze.w, adze.h).get_center())
	expect.call(h.get("type") == "mouth" and h.id == "adze", "the adze on the offering stand can be clicked")
	expect.call(_pick(mouth.mummy_rect().get_center()).get("type") != "mouth", "without the adze, the mummy is only a figure")
	act_mouth("adze")
	avatar.position.x = avatar._target
	avatar._process(0.0)
	expect.call(mouth.carrying() == "adze", "clicking the adze takes it up")
	expect.call(_pick(Rect2(adze.x, adze.y, adze.w, adze.h).get_center()).get("id") == "back", "with the adze in hand, its place on the stand can be clicked")
	put_back()
	expect.call(mouth.carrying() == "" and mouth._adze.position == Vector2(adze.x, adze.y), "clicking the stand puts the adze back")
	act_mouth("adze")
	avatar.position.x = avatar._target
	avatar._process(0.0)
	h = _pick(mouth.mummy_rect().get_center())
	expect.call(h.get("type") == "mouth" and h.id == "mummy", "with the adze in hand, the mummy can be touched")
	mouth.touch()
	expect.call(mouth.active and mouth.phase == OpeningMouth.Phase.ADZE and not mouth._words.visible, "touching the mummy starts carving, without releasing the words")
	expect.call(not avatar.keys, "carving holds the player still")
	_update_camera(1.0)
	expect.call(_focus == "mouth" and camera.zoom.x > 2.0, "carving brings the camera close to the mummy's face")
	var blank := mouth.face_view().position + Vector2(3, 3)
	expect.call(mouth.strike(mouth._feature_bounds[0].get_center()), "a strike within the mouth bounds advances carving")
	var progress: float = mouth._progress[0]
	mouth._process(2.0)
	expect.call(mouth._progress[0] == progress, "holding the pointer still never carves automatically")
	for i in 10:
		expect.call(not mouth.strike(blank), "a strike outside the features is ignored")
	expect.call(mouth.active and mouth._progress[0] == progress and not avatar.keys,
		"repeated misses preserve progress and keep the carving view active")
	mouth.leave()
	expect.call(not mouth.active and mouth._progress.all(func(v): return v == 0.0), "stepping away clears an unfinished face")
	mouth.touch()
	for stroke in [1, 0]:   # the eye, then the mouth (the beard is not carved)
		var guard := 0
		while mouth.active and not mouth.stroke_done(stroke) and guard < 100:
			mouth.strike(mouth.next_chip(stroke))
			guard += 1
		expect.call(mouth.stroke_done(stroke), "each face stroke can be completed in any order: %d" % stroke)
	expect.call(not mouth.active and avatar.keys, "finishing the face leaves the close view and restores walking")
	var final_image := mouth._features.texture.get_image()
	expect.call(final_image.get_data() == mouth._feature_image.get_data(), "the finished face restores every original feature pixel")
	expect.call(not mouth.strike(blank), "a closed carving game cannot receive another strike")
	var said := mouth.words_rect()
	expect.call(mouth.phase == OpeningMouth.Phase.SPOKEN and mouth._adze.position == Vector2(adze.x, adze.y), "the touch opens the mouth; the adze goes back on the stand")
	var band_free: bool = said.position.x > 850.0 and said.end.x <= 2172.0 and said.position.y >= 50.0 and said.end.y <= 180.0
	expect.call(said.size == home.size and band_free and said.end.x > mouth.mummy_rect().position.x, "the words sit whole in the empty band above the mummy")
	h = _pick(said.get_center())
	expect.call(h.get("type") == "mouth" and h.id == "words", "the spoken words can be taken")
	act_mouth("words")
	avatar.position.x = avatar._target
	avatar._process(0.0)
	expect.call(mouth.carrying() == "words" and not solved.t6, "taken up, the words are carried")
	expect.call(_pick(said.get_center()).get("id") == "back", "with the words in hand, their place above the mummy can be clicked")
	h = _pick(home.get_center())
	expect.call(h.get("type") == "mouth" and h.id == "home", "their imprint over Ra takes them")
	mouth.place_words()
	expect.call(solved.t6 and not mouth._imprint.visible and mouth.words_rect() == home, "the words stand over Ra as drawn")
	mouth.instant = false


## Set the three bulls right through the calls a drag makes.
func _autotest_bulls(expect: Callable) -> void:
	bulls.instant = true
	var half: float = sprite_rects.avatar.size.x / 2.0
	expect.call(bulls.stand_x() - half > bulls.ox_sprite().position.x and bulls.stand_x() + half < bulls.view().y,
		"the bulls' view takes in where you stand, right of the plumed ox")
	var calf := bulls.calf_sprite()
	var plumes := bulls.plumes_sprite()
	expect.call(not bulls.calf_turned() and not bulls.crowned(), "the calf faces the sacrifice and the plumes are on the bull at the block")
	var spot: Dictionary = hotspots.filter(func(h): return h.label == "Calf")[0]
	expect.call(_pick(spot.rect.get_center()).get("spot") == spot, "the calf can be clicked")
	bulls.enter()
	expect.call(bulls.active and _last_said == "Fix what is wrong!", "stepping up says only: fix what is wrong")
	var c := calf.global_position
	var w := calf.texture.get_width() * 0.5
	bulls.press(bulls.pick(c), c)
	bulls.drag(c + Vector2(w * 0.2, 0.0))
	bulls.release(c + Vector2(w * 0.2, 0.0))
	expect.call(not bulls.calf_turned(), "dragged short of halfway, the calf turns back to the block")
	bulls.press(bulls.pick(c), c)
	bulls.drag(c + Vector2(w * 0.8, 0.0))
	expect.call(calf.scale.x > 0.0 and calf.scale.x < 1.0, "dragged sideways, the calf turns about its middle")
	bulls.release(c + Vector2(w * 0.8, 0.0))
	expect.call(bulls.calf_turned() and calf.scale.x == 1.0 and not bulls.done, "past halfway it faces the plumed ox, as drawn")
	var p := plumes.global_position + plumes.texture.get_size() / 2.0
	bulls.press(bulls.pick(p), p)
	bulls.drag(p + Vector2(300.0, 40.0))
	bulls.release(p + Vector2(300.0, 40.0))
	expect.call(not bulls.crowned() and plumes.global_position == Vector2(level.bulls.wrong.x, level.bulls.wrong.y), "let go anywhere else, the plumes go back")
	var onto := p + (Vector2(level.bulls.right.x, level.bulls.right.y) - plumes.global_position) + Vector2(10.0, -8.0)
	bulls.press(bulls.pick(p), p)
	bulls.drag(onto)
	bulls.release(onto)
	expect.call(bulls.crowned() and plumes.global_position.is_equal_approx(Vector2(level.bulls.right.x, level.bulls.right.y)), "near his head, the plumes go on the plumed ox, where they are drawn")
	expect.call(bulls.done and solved.t8 and not bulls.active, "both set right, the bulls are done")
	expect.call(_success_glowing(bulls.ox_sprite()) and _success_glowing(calf), "and flash pale green")
	bulls.instant = false


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
	for nm in EndingStand.PIECES:
		act_ending(nm)
	var feet := avatar.global_transform * Transform2D(0.0, avatar.sprite.position)
	expect.call(ending.worn == ["stand", "sun", "lotus"] and EndingStand.PIECES.all(func(nm): return ending.sprite_of(nm).global_transform.is_equal_approx(feet * EndingStand.pose(nm))), "the pieces taken go onto you, as posed")
	expect.call(_pick(ending.sprite_of("sun").global_position).get("type") == "worn", "a piece on you can be clicked")
	ending.hold("sun")
	ending.hold("lotus")
	ending._process(0.0)
	expect.call(ending.held == "sun" and ending.sprite_of("sun").global_position == get_global_mouse_position(), "taken off you, it follows the pointer, one at a time")
	var r := ending.set_down()
	expect.call(r == "unsupported" and not ending.placed.has("sun") and "sun" in ending.worn and ending.held == "", "the sun disc cannot go on before the stand: it goes back onto you")
	ending.hold("lotus")
	put_back()
	expect.call("lotus" in ending.worn and ending.held == "", "let go elsewhere, it goes back onto you")
	var h := _pick(ending.place_rect().get_center())
	expect.call(h.get("type") == "ending" and h.id == "place", "the stand's place before Ra can be clicked")
	for nm in EndingStand.PIECES:
		ending.hold(nm)
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
	expect.call(not rites_done() and not ending.imprint_shown, "the stela waits for the three bulls too")
	_autotest_bulls(expect)
	expect.call(rites_done() and not finished, "all seven rites done; the level waits for the offering stand")
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
	expect.call(ending.worn.is_empty(), "the stand's pieces can't be taken before the stela shows them")
	expect.call(_last_said == "This might come in handy later, but you wouldn't want your hands full right now.", "a hidden piece says it may come in handy later")
