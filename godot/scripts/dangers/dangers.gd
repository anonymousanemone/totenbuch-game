## Spells 31-42: dangers on the road (Lepsius, Todtenbuch pl. XVI-XIX).
##
## The scroll reads right to left. The player (the adoring deceased of spell 30) walks left
## through the vignettes. Each vignette with a creature is an encounter: walking into it
## offers its introduction; clicking a creature takes its spear-bearer’s place and starts
## the fight. Space thrusts. The spell-38 gate waits until the preceding dangers are overcome. Solving an encounter puts the vignette back as it is drawn on the plate.
## Positions come from assets/dangers/level.json, written by tools/cut_dangers300.py from the
## hand-made 300-dpi strip bod31-42.mdp. Distances below are in 200-dpi plate pixels and are
## multiplied by `unit` (level.json `scale`).
## Combat behavior lives in the per-minigame scripts; this scene owns shared state,
## walking, taking the breath of life, progression, and arena presentation.
extends Node2D

const CROCODILES := preload("res://scripts/dangers/crocodiles.gd")
const TWO_SNAKES := preload("res://scripts/dangers/two_snakes.gd")
const CREEPING_SNAKE := preload("res://scripts/dangers/creeping_snake.gd")
const BEETLES := preload("res://scripts/dangers/beetles.gd")
const LUNGING_SNAKE := preload("res://scripts/dangers/lunging_snake.gd")
const APEP := preload("res://scripts/dangers/apep.gd")
const DONKEY := preload("res://scripts/dangers/donkey.gd")
const SHEAF := preload("res://scripts/dangers/sheaf.gd")

var crocodiles = CROCODILES.new(self)
var two_snakes = TWO_SNAKES.new(self)
var creeping_snake = CREEPING_SNAKE.new(self)
var beetles = BEETLES.new(self)
var lunging_snake = LUNGING_SNAKE.new(self)
var apep = APEP.new(self)
var donkey = DONKEY.new(self)
var sheaf = SHEAF.new(self)


const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const VIEW_TOP := 36.0   ## the row under the top register's upper rule: the title bar's band takes its place
const DATA_PATH := "res://assets/dangers/level.json"
const SHEET_PATH := "res://assets/dangers/spearers.json"   ## the spear-bearers' thrust (tools/spearer_sheet.py)
const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const SHEET_TEX := "res://assets/dangers/animation/spearers.png"
const ASSET := "res://assets/dangers/figures/%s.png"
const AFTER_CHOICE := ["e39", "e40", "e41"]
const LIFE_GAME_CLUE := 60.0       ## active seconds in one encounter, across visits
const LIFE_TOTAL_CLUE := 120.0     ## active seconds across all three encounters
const LIFE_FLASH := 0.8
const BESIDE := 50.0
const FIGHTS := ["crocs", "lunge", "twin", "creep", "roach", "apep", "donkey", "sheaf"]
const ARENA_FIGHTS := ["crocs", "roach", "lunge", "creep", "twin", "apep", "donkey", "sheaf"]   ## the vignette opens out across the screen
## Debug: true opens the road, so you can walk past spell 38 with dangers still undone (also
## `-- --open-road` on the command line). Keep it false for play.
const DEBUG_OPEN_ROAD := true

const ENCOUNTERS := preload("res://scripts/dangers/danger_encounters.gd").ENCOUNTERS
const GLOW := UI.Glow.DANGER

var level: Dictionary
var unit := 1.0          ## strip px per plate px at 200 dpi (level.json `scale`)
var ground := 248.0      ## the line the figures stand on (level.json `ground`)
var rects := {}          ## sprite name -> Rect2 as drawn on the plate
var sheet: Dictionary    ## spearers.json: cell size, poses, and per bearer its row, place in the cell, tip and dir
var _sheet_tex: Texture2D
var actors := {}         ## sprite name -> Node2D pivot at the sprite's bottom centre
var boxes := {}          ## encounter id -> Vector2(x0, x1)

var _caption_regions := {}
var _descriptions = preload("res://scripts/descriptions.gd").new("dangers")
var _hints = preload("res://scripts/puzzles.gd").new()
var solved := {}         ## encounter id -> true
var _section := ""       ## the encounter whose vignette you are walking through
var objects := {}
var _object_press: MoveableObject
var _object_press_screen := Vector2.ZERO
var _object_dragging := false

var items: Array[String] = []
var bites := 0
var finished := false
var journal: Array[String] = []
var _life_scores := {}
var _life_times := {}
var _life_total := 0.0
var _life_clue_given := false
var _life_clue_hold := 0.0
var current := {}        ## first unsolved encounter; spell 38 gates progress beyond it
var fight := {}          ## state of the running fight, empty when walking
var rng := RandomNumberGenerator.new()

var _time := 0.0
var _roach_need := -1     ## dev: overrides the number of beetles when set (ROACH_NEED)
var _instant := false     ## the autotest skips the crocodile vignette's opening and closing
var _arena: Node2D        ## the opened-out crocodile vignette, between the strip and the actors
var _arena_cover: ColorRect
var _arena_lines: Node2D
var _band_cover: ColorRect    ## papyrus over the caption band inside the fight's frame
var _caption_art: Sprite2D    ## the fight's caption, drawn again where the frame shows it
var _strip_img: Image         ## the strip, read once to find where a caption's ink lies
var heka_known := false        ## the player has clicked a flashing heka sign
const FLESH_PATH := "res://assets/dangers/figures/flesh.png"   ## the flesh sign that counts his health (supplied, not cut)
const FLESH_GAP := 6.0          ## strip px between signs, drawn at their native asset size
var _flesh_tex: Texture2D = _ink_from(load(FLESH_PATH)) if ResourceLoader.exists(FLESH_PATH) else null
var _told_unsolved := -10.0   ## when the end of the scroll last said what is still undone
var gate := {}           ## a "gate" encounter (spell 38): the way on past it stays shut while it or one before it is undone
var _bump_time := -10.0
var _heka_signs: Array = []      ## flattened once from level.heka
var _session := 0
var _fight_tweens: Array[Tween] = []
var _hover := []                ## the actors glowing under the pointer
var _caption := {}              ## the encounter whose caption glows under the pointer
var _caption_glow: Sprite2D

@onready var avatar: Node2D = $Avatar
@onready var _item_poses := {"ankh38": $Avatar/CarryAnkh, "sail38": $Avatar/CarryBreath}
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay
## The column of signs between spells 41 and 40 (the papyrus and the strip's ink there, drawn
## again over him): walking on, he passes behind it. Hidden while a fight is open.
@onready var column: Node2D = $Column


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	for region in $CaptionRegions.get_children():
		_caption_regions[region.get_meta("registry_id")] = region
	var heka = level.get("heka", {})
	if heka is Dictionary:
		for words in heka.values():
			_heka_signs.append_array(words)
	unit = level.get("scale", 1.0)
	ground = level.ground
	avatar.speed *= unit
	avatar.bob_height *= unit
	# Scene transforms own placement; registry.json owns descriptions, level.json source-art data.
	for actor in $actors.find_children("*", "Node2D", true, false):
		if not actor.has_meta("actor_id"):
			continue
		var id: String = actor.get_meta("actor_id")
		assert(not actors.has(id), "Duplicate Dangers actor ID: " + id)
		actors[id] = actor
		actor.set_meta("home", actor.position)
		var size: Vector2 = actor.get_meta("size")
		rects[id] = Rect2(actor.position - Vector2(size.x / 2.0, size.y), size)
	for id in _item_poses:
		var item := MoveableObject.new()
		add_child(item)
		item.setup(id, _picture(actors[id]))
		item.carriable = true
		item.description_requested.connect(_describe_item)
		objects[id] = item
	var avatar_size: Vector2 = avatar.get_meta("size")
	rects.avatar = Rect2(avatar.position - Vector2(avatar_size.x / 2.0, avatar_size.y), avatar_size)
	for b in level.boxes:
		boxes[b] = Vector2(level.boxes[b][0], level.boxes[b][1])
	# the spear-bearers come from one sprite sheet: the man as drawn with his spear in a pose, and over
	# him the spear alone in the same pose, shown only when it is tinted red for heka
	sheet = JSON.parse_string(FileAccess.get_file_as_string(SHEET_PATH))
	_sheet_tex = load(SHEET_TEX)
	if absf(float(sheet.reach) - CROC_THRUST * unit) > 0.5 or absf(float(sheet.back) - CROC_PREP * unit) > 0.5:
		push_warning("spearers.json reach/back do not match CROC_THRUST/CROC_PREP")
	for nm in sheet.bearers:
		var pole: String = nm + "_pole"
		actors[nm].get_parent().move_child(actors[pole], actors[nm].get_index() + 1)
		for a in [actors[nm], actors[pole]]:
			var sp: Sprite2D = _picture(a)
			var at := AtlasTexture.new()
			at.atlas = _sheet_tex
			sp.texture = at
		_bearer_pose(nm, 0.0)
	overlay.draw.connect(_draw_overlay)
	_arena = Node2D.new()
	add_child(_arena)
	move_child(_arena, $actors.get_index())
	_arena_cover = ColorRect.new()
	_arena_cover.material = $Papyrus.material
	_arena_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_arena_cover)
	_band_cover = ColorRect.new()
	_band_cover.material = $Papyrus.material
	_band_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_band_cover)
	_caption_art = Sprite2D.new()
	_caption_art.centered = false
	_caption_art.texture = AtlasTexture.new()
	(_caption_art.texture as AtlasTexture).atlas = $Strip.texture
	_arena.add_child(_caption_art)
	_arena_lines = Node2D.new()
	_arena.add_child(_arena_lines)
	_arena_lines.draw.connect(_draw_arena_lines)
	avatar.bumped.connect(_on_bumped)
	_arena.visible = false
	hud.setup(self, {
		"title": "Dangers on the Road",
		"journal_hint": "Each creature you overcome is recorded here.",
		"intro_title": "Spells 31–42: Dangers on the Road",
		"intro_body": "Crocodiles, snakes, beetles, and Apep guard the road. Turn them back and take the breath of life.\n\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Click a creature to learn its rule and take up the spear. [esc] leaves a fight.",
		"outro_title": "The road is clear",
	})
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	reset()
	_maybe_run_cli()


## Temporary copies spawned during fights; permanent actors live in the scene.
func _make_actor(tex: Texture2D, r: Rect2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.position = Vector2(r.get_center().x, r.end.y)
	sprite.set_meta("home", sprite.position)
	sprite.set_meta("size", r.size)
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-r.size.x / 2.0, -r.size.y)
	$actors.add_child(sprite)
	return sprite


## Multipart creatures keep a separate drawing so heads can move or hide independently.
func _picture(actor: Node2D) -> Sprite2D:
	return actor as Sprite2D if actor is Sprite2D else actor.get_node("sprite") as Sprite2D


func reset() -> void:
	_hints.reset()
	_kill_fight_tweens()
	_session += 1
	if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
		_crocs_cleanup()
	heka_known = false
	solved.clear()
	_section = ""
	_object_press = null
	_object_dragging = false
	for item in objects.values():
		item.reset()
	items.clear()
	journal.clear()
	_life_scores.clear()
	_life_times.clear()
	_life_total = 0.0
	_life_clue_given = false
	_life_clue_hold = 0.0
	bites = 0
	finished = false
	fight = {}
	rng.seed = 30
	for n in actors:
		_restore(n)
		if n in _item_poses:
			actors[n].z_index = 0
		actors[n].visible = not n.begins_with("spear") and not n.begins_with("sheaf41_")   # the sheaf's pieces show only in its fight
	avatar.visible = true
	avatar.set_process(true)
	avatar.stop()
	avatar.position = Vector2(rects.avatar.get_center().x, ground)
	avatar.facing = -1
	hud.reset_view()
	hud.say("Scribe", _hints.message("dangers.start"))
	_refresh()
	_update_camera(1.0)


# ---------------------------------------------------------------- walking and gates

func _refresh() -> void:
	current = {}
	for e in ENCOUNTERS:
		if e.kind in ["take", "note", "end"]:
			continue
		if not solved.has(e.id):
			current = e
			break
	# he walks through every vignette (a fight starts only on clicking its creature) and into a gate
	# vignette, but not on past it while it or one before it is still undone. The barrier is not drawn.
	gate = {}
	var args := OS.get_cmdline_user_args()
	var open_road := (DEBUG_OPEN_ROAD or "--open-road" in args) and not "--autotest" in args   # the tests check the real road
	for e in ENCOUNTERS:
		if e.get("gate", false) and not open_road and not current.is_empty() and ENCOUNTERS.find(current) <= ENCOUNTERS.find(e):
			gate = e
			break
	avatar.min_x = gate_x() + 20.0 * unit if not gate.is_empty() else 40.0 * unit
	avatar.max_x = level.width - 40.0 * unit


func span(e: Dictionary) -> Vector2:
	var a := INF
	var b := -INF
	for id in e.boxes:
		a = minf(a, boxes[id].x)
		b = maxf(b, boxes[id].y)
	return Vector2(a, b)


## The unsolved encounter of `kinds` whose vignette he stands in, or {}.
func here(kinds: Array = FIGHTS) -> Dictionary:
	var x := avatar.position.x
	for e in ENCOUNTERS:
		if e.kind in kinds and not solved.has(e.id):
			var s := span(e)
			if x > s.x and x < s.y:
				return e
	return {}


## The item at `p` that can be taken (of an unsolved "take" encounter; the nearest, where two are
## close together), or "".
func _item_at(p: Vector2) -> String:
	var best := ""
	for e in ENCOUNTERS:
		if e.kind == "take" and not solved.has(e.id):
			for it in e.items:
				var r := actor_rect(it)
				if r.grow(12 * unit).has_point(p) and (best == "" or r.get_center().distance_to(p) < actor_rect(best).get_center().distance_to(p)):
					best = it
	return best


## The "take" encounter an item belongs to.
func _taking(item: String) -> Dictionary:
	for e in ENCOUNTERS:
		if e.kind == "take" and item in e.items:
			return e
	return {}


## The far (left-hand) edge of the gate vignette, which he cannot pass yet (0 when open).
func gate_x() -> float:
	return span(gate).x if not gate.is_empty() else 0.0


func walk_then(x: float, then := Callable()) -> void:
	var tx := clampf(x, avatar.min_x, avatar.max_x)
	avatar.walk_to(tx, func():
		if tx - x > 120.0 * unit:
			_blocked()
		elif then.is_valid():
			then.call())


func _on_bumped() -> void:
	_blocked()


func _blocked() -> void:
	if gate.is_empty() or _time - _bump_time < 2.5:
		return
	_bump_time = _time
	say("Scribe", _hints.message("dangers.blocked") % current.id.trim_prefix("e"))


func _describe_item(object_id: String, description_key: String) -> void:
	if _descriptions.entries.has(description_key):
		_descriptions.show(description_key, hud)
	else:
		# Individual item descriptions are not currently in the registry.
		var label: String = {"ankh38": "Ankh", "sail38": "Breath"}[object_id]
		say(label, label)


func _carried_item_input(event: InputEvent) -> bool:
	if _object_press != null:
		if event.is_action_pressed("ui_cancel"):
			_object_press.cancel_hold()
			_object_press = null
			_object_dragging = false
			return true
		if event is InputEventMouseMotion:
			if not _object_dragging and event.position.distance_to(_object_press_screen) > 8.0:
				_object_press.hold()
				_object_dragging = true
				_object_press.request_description()
			if _object_dragging:
				_object_press.move_held(get_global_mouse_position())
			return true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				_object_press.cancel_hold()
				_object_press = null
				_object_dragging = false
			return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for id in items:
			if objects[id].contains_point(get_global_mouse_position()):
				_object_press = objects[id]
				_object_press_screen = event.position
				_object_dragging = false
				_object_press.request_description()
				return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or finished:
		return
	if event.is_action_pressed("ui_cancel") and not fight.is_empty():   # Esc always steps out of a fight
		leave_fight()
		get_viewport().set_input_as_handled()
		return
	if fight.is_empty() and _carried_item_input(event):
		return
	# Space thrusts in the fights that open out (holding Shift lends the thrust heka)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if not fight.is_empty() and fight.kind == "sheaf":
			sheaf._sheaf_act()                # strikes at the band he leans to
		elif not fight.is_empty() and fight.kind in ARENA_FIGHTS:
			_croc_thrust()
		elif not fight.is_empty() and fight.kind == "donkey":
			donkey._donkey_click(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return
	# [↑] [↓] lean spell 41's bearer to the band above or below
	if not fight.is_empty() and fight.kind == "sheaf" and (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")):
		sheaf._sheaf_aim(-1 if event.is_action_pressed("ui_up") else 1)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var at := get_global_mouse_position()
		_set_hover(_hover_at(at))
		_set_caption_hover(_caption_at(at) if fight.is_empty() and _hover.is_empty() else {})
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not (_hover.is_empty() and _caption.is_empty()) else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if _heka_at(p) != "":
			heka_known = true
			say("Scribe", _hints.message("dangers.heka_controls"))
			return
		if not fight.is_empty():
			fight_click(p)
			return
		var f := _fight_at(p)
		if not f.is_empty():
			# step into its vignette, then take up the spear
			var s := span(f)
			walk_then(clampf(avatar.position.x, s.x + 40.0 * unit, s.y - 40.0 * unit), func():
				if fight.is_empty():
					_set_hover([])
					start_fight(f))
			return
		var it := _item_at(p)
		if it != "":
			walk_then(actor_rect(it).end.x + BESIDE * unit, take.bind(_taking(it), it))
			return
		var c := _caption_at(p)
		if not c.is_empty():
			_descriptions.show("caption_" + c.id, hud)
			return
		var subject := _inspection_at(p)
		if subject != "":
			var bounds := actor_rect(subject)
			var destination := p.x if avatar.position.x >= bounds.position.x and avatar.position.x <= bounds.end.x else clampf(avatar.position.x, bounds.position.x, bounds.end.x)
			walk_then(destination, _record_actor.bind(subject))
			return
		walk_then(p.x)


func _inspection_at(point: Vector2) -> String:
	var names: Array = actors.keys()
	names.reverse()
	for name in names:
		var actor: Node2D = actors[name]
		if actor.has_meta("registry_id") and actor.is_visible_in_tree() and _descriptions.hit(_picture(actor), point):
			return name
	return ""


func _record_actor(name: String) -> void:
	var id: String = actors[name].get_meta("registry_id")
	_descriptions.inspect(id, hud, journal, _picture(actors[name]).texture, _descriptions.journal_total(), "settled" if solved.has(id) else "default")
	if _life_scores.has(id):
		_sync_life_score(id)


## What glows under the pointer (hit-tested by box): a heka word; a target in a fight, or, walking, a
## creature (all of its encounter's) or an item to take.
func _hover_at(p: Vector2) -> Array:
	var h := _heka_at(p)              # part for whole: a heka word glows alone; the rest of its caption, the whole
	if h != "":
		return [h]
	if not fight.is_empty():
		for n in _targets():
			if actor_rect(n).grow(8 * unit).has_point(p):
				return [n]
		return []
	var f := _fight_at(p)
	if not f.is_empty():
		return _creatures(f)
	var it := _item_at(p)
	if it != "":
		return [it]
	var subject := _inspection_at(p)
	return [subject] if subject != "" else []


func _set_hover(names: Array) -> void:
	if names == _hover:
		return
	for n in _hover:
		_glow(n, false)
	_hover = names
	for n in _hover:
		_glow(n, true)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not names.is_empty() else Input.CURSOR_ARROW)


## The spell whose caption, in the top register, is under the pointer (its heka signs are their own).
func _caption_at(p: Vector2) -> Dictionary:
	if _heka_at(p) != "":
		return {}
	for e in ENCOUNTERS:
		if e.has("caption") and _caption_rect(e).has_point(p):
			return e
	return {}


func _caption_rect(e: Dictionary) -> Rect2:
	return _descriptions.region_bounds(_caption_regions["caption_" + e.id])


## A caption glows like the creatures: the strip's drawing in its frame, and those of its signs
## that are sprites of their own (the heka words, spell 37's snake signs).
func _set_caption_hover(e: Dictionary) -> void:
	if e == _caption:
		return
	if not _caption.is_empty():
		var g := _caption_glow
		var t := create_tween()
		t.tween_method(func(v: float): (g.material as ShaderMaterial).set_shader_parameter("strength", v), 1.0, 0.0, 0.15)
		t.tween_callback(g.queue_free)
		for n in _caption_signs(_caption):
			_glow(n, false)
	_caption = e
	if not e.is_empty():
		var g := UI.part_glow($Strip, _caption_rect(e), GLOW)
		_caption_glow = g
		create_tween().tween_method(func(v: float): (g.material as ShaderMaterial).set_shader_parameter("strength", v), 0.0, 1.0, 0.15)
		for n in _caption_signs(e):
			_glow(n, true)


func _caption_signs(e: Dictionary) -> Array:
	return _caption_signs_in(_caption_rect(e))


func _caption_signs_in(cell: Rect2) -> Array:
	var r := cell.grow(4.0)
	return actors.keys().filter(func(n): return r.encloses(actor_rect(n)))


## A soft glow behind actor `n`'s drawing (made the first time it is wanted).
func _glow(n: String, on: bool) -> void:
	var sp := _picture(actors[n])
	var g := sp.get_node_or_null("Glow") as Sprite2D
	if g == null:
		if not on:
			return
		g = Sprite2D.new()
		g.name = "Glow"
		g.texture = sp.texture
		g.centered = sp.centered
		g.offset = sp.offset
		g.flip_h = sp.flip_h
		g.show_behind_parent = true
		var mat := UI.glow_material(sp.texture, GLOW)
		g.material = mat
		g.visible = false
		sp.add_child(g)
	# Re-entering during a fade replaces the previous tween instead of racing it.
	var previous: Tween = g.get_meta("fade") if g.has_meta("fade") else null
	if previous and previous.is_valid():
		previous.kill()
	if on:
		g.visible = true
	var t := create_tween()
	g.set_meta("fade", t)
	t.tween_method(func(v: float): (g.material as ShaderMaterial).set_shader_parameter("strength", v),
		(g.material as ShaderMaterial).get_shader_parameter("strength"), 1.0 if on else 0.0, 0.15)
	if not on:
		t.tween_callback(g.hide)


## The creatures you click to take up the spear against encounter `e`, with what the creature is
## drawn on (they glow together): the donkey and its tail under spell 40's snake, spell 41's sheaf.
func _creatures(e: Dictionary) -> Array:
	var out: Array = e.foes if e.has("foes") else [e.foe]
	for k in ["donkey", "tail", "bundle"]:
		if e.get(k) is String and actors.has(e[k]):   # (spell 33's `tail` is a timing)
			out.append(e[k])
	return out


## The unsolved fight (on this side of the gate) whose creature is at `p`, or {}.
func _fight_at(p: Vector2) -> Dictionary:
	for e in ENCOUNTERS:
		if not e.kind in FIGHTS or solved.has(e.id) or span(e).y <= gate_x():
			continue
		for n in _creatures(e):
			if actors[n].visible and actors[n].modulate.a > 0.1 and actor_rect(n).grow(8 * unit).has_point(p):
				return e
	return {}


func _targets() -> Array:
	match fight.kind:
		"crocs", "roach", "lunge", "creep", "twin", "apep", "sheaf": return []
		"donkey": return [fight.e.foe]
	return []


func _process(delta: float) -> void:
	_time += delta
	if not finished and fight.is_empty():
		_check_position()
	if not fight.is_empty():
		_update_fight(delta)
	_follow_items()
	column.visible = fight.is_empty()
	_update_camera(delta)
	overlay.queue_redraw()
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	if fight.is_empty():
		# on the scroll the heka signs always flash red; clicking one tells what they are for
		for nm in _all_heka():
			actors[nm].modulate = Color(Color.WHITE.lerp(RED_CROC, pulse), actors[nm].modulate.a)
	elif fight.kind == "crocs":
		if not fight.lost:
			for nm in _heka_words(fight.e.id):
				actors[nm].modulate = Color.WHITE.lerp(RED_CROC, pulse * fight.open) if fight.get("heka_on", false) else Color.WHITE
	if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
		_place_frame()


## Say a vignette's line each time you walk into it while its danger is still there (a fight waits
## for a click on the creature), and end the level at spell 42 once everything before it is done.
func _check_position() -> void:
	var x := avatar.position.x
	var here_now := ""
	for e in ENCOUNTERS:
		var s := span(e)
		if x < s.y - 20.0 * unit and x > s.x:
			here_now = e.id
			if here_now != _section and not solved.has(e.id):
				say("Scribe", (_hints.message("dangers.end") if e.kind == "end" else _descriptions.line(e.id, "default", true).text) + (" " + _hints.message("dangers.click_to_fight") if e.kind in FIGHTS else ""))
			break
	_section = here_now
	if x < span(ENCOUNTERS[-1]).y - 40.0 * unit:
		if current.is_empty():
			finish()
		elif _time - _told_unsolved > 6.0:
			_told_unsolved = _time
			say("Scribe", _hints.message("dangers.unfinished") % current.id.trim_prefix("e"))


## Take `item` from encounter `e` (the first of its items if none is named); only one is taken, the
## others stay where they are drawn.
func take(e: Dictionary, item := "") -> void:
	if solved.has(e.id):
		return
	if item == "":
		item = e.items[0]
	items.append(item)
	objects[item].wear(avatar, _item_poses[item].transform)
	_follow_items()
	_solve(e, item)


## Signs sit on the walking figure at their authored poses, mirrored and bobbing with him.
func _follow_items() -> void:
	for item in items:
		var object: MoveableObject = objects[item]
		if object.state == MoveableObject.State.WORLD:
			object.wear(avatar, _item_poses[item].transform)
		object.follow()
		if object.state == MoveableObject.State.HELD:
			object.move_held(get_global_mouse_position())
		object.sprite.visible = avatar.visible


## `item`: what was taken (its picture goes in the Journal, and `won` may say per item).
func _solve(e: Dictionary, item := "") -> void:
	solved[e.id] = true
	say("Scribe", (_hints.text("dangers." + e.id, "feedback", "success_" + item) if item != "" else _hints.text("dangers." + e.id, "success")))
	var pic: String = e.foes[0] if e.kind == "crocs" else e.get("foe", item)
	var tex: Texture2D = load(ASSET % pic)
	_descriptions.remember(e.id, hud, journal, tex, _descriptions.journal_total(), "settled")
	_refresh()


func finish() -> void:
	if finished or "ankh38" in items:
		return
	finished = true
	_refresh()
	say("Scribe", _hints.message("dangers.finished" if "sail38" in items else "dangers.finished_without_breath"))
	var body := _hints.message("dangers.outro" if "sail38" in items else "dangers.outro_without_breath")
	var revision: int = _session
	get_tree().create_timer(1.2, false).timeout.connect(func():
		if revision == _session and finished:
			hud.show_outro(body))


func hint() -> void:
	if finished:
		return
	if not fight.is_empty() and not solved.has(fight.e.id):
		var phase := "fight"
		if fight.kind == "crocs" and fight.get("heka_on", false):
			phase = "heka"
		say("Hint", _hints.advance("dangers." + fight.e.id, phase))
		return
	var nearby := here(FIGHTS + ["take"])
	if not nearby.is_empty():
		say("Hint", _hints.advance("dangers." + nearby.id, "choose") if nearby.kind == "take" else _hints.find("dangers." + nearby.id, "nearby"))
		return
	# Resolve unfinished work from current state, including when a later vignette is solved first.
	for encounter in ENCOUNTERS:
		if encounter.kind in FIGHTS + ["take"] and not solved.has(encounter.id):
			say("Hint", _hints.find("dangers." + encounter.id, "right" if avatar.position.x < span(encounter).x else "default"))
			return
	say("Hint", _hints.message("dangers.complete"))


## In a fight, what the scribe would say is said under the danger's name (`tag`).
func say(who: String, text: String) -> void:
	if _life_clue_hold > 0.0 and who == "Scribe":
		return
	if who == "Scribe" and not fight.is_empty():
		who = fight.e.get("tag", who)
	hud.say(who, text, "minigame")


# ---------------------------------------------------------------- fights

func _fight_tween(node: Node = null) -> Tween:
	var tween := (node if node else self).create_tween()
	_fight_tweens = _fight_tweens.filter(func(t): return t.is_valid())
	_fight_tweens.append(tween)
	return tween


func _kill_fight_tweens() -> void:
	for tween in _fight_tweens:
		if tween.is_valid():
			tween.kill()
	_fight_tweens.clear()
	camera.offset = Vector2.ZERO


func start_fight(e: Dictionary) -> void:
	_kill_fight_tweens()
	_session += 1
	avatar.stop()
	avatar.visible = false
	_follow_items()
	avatar.set_process(false)
	actors[e.spear].visible = true
	_set_hover([])
	_set_caption_hover({})
	if not e.kind in ARENA_FIGHTS:
		_bearer_pose(e.spear, -CROC_PREP)      # in a fight the spear rests drawn back
	fight = {"kind": e.kind, "e": e, "t": 0.0, "hits": 0, "ankh_flash": 0.0}
	match e.kind:
		"crocs":
			crocodiles._crocs_start(e)
		"twin":
			two_snakes._twin_start(e)
		"roach":
			beetles._roach_start(e)
		"lunge":
			lunging_snake._lunge_start(e)
		"creep":
			creeping_snake._creep_start(e)
		"apep":
			apep._apep_start(e)
		"donkey":
			donkey._donkey_start(e)
		"sheaf":
			sheaf._sheaf_start(e)
	if endless():
		_life_scores.get_or_add(e.id, 0)
		_sync_life_score(e.id)
	say("Scribe", _hints.text("dangers." + e.id, "instructions"))


func end_fight() -> void:
	if endless():
		return
	if fight.kind in ARENA_FIGHTS:
		if not _instant and not fight.get("closing", false):
			_crocs_close()
			return
		_crocs_cleanup()
	_kill_fight_tweens()
	var e: Dictionary = fight.e
	var spear: Rect2 = rects[e.spear]
	fight = {}
	for n in _box_actors(e):
		_restore(n)
		UI.success_flash(_picture(actors[n]))
	avatar.position.x = spear.get_center().x
	avatar.visible = true
	avatar.set_process(true)
	_solve(e)


## Esc: step back out of the fight, not won. The vignette closes (as when a fight is lost), the
## creature and the bearer stand as drawn, and clicking the creature takes it up again.
func leave_fight() -> void:
	if fight.is_empty() or fight.get("closing", false):
		return
	_kill_fight_tweens()
	_life_clue_hold = 0.0
	var e: Dictionary = fight.e
	var out := func():
		if fight.kind in ARENA_FIGHTS:
			_crocs_cleanup()
		for n in _box_actors(e):
			_restore(n)
		for n in [e.spear, e.spear + "_pole"]:
			if actors.has(n):
				actors[n].visible = false
		fight = {}
		avatar.position.x = rects[e.spear].get_center().x
		avatar.visible = true
		avatar.set_process(true)
		say("Scribe", _hints.message("dangers.left_fight"))
	if fight.kind in ARENA_FIGHTS and not _instant:
		_crocs_close(out)
	else:
		out.call()


func _box_actors(e: Dictionary) -> Array:
	var s := span(e)
	return actors.keys().filter(func(n): return actors[n].get_meta("home").x > s.x and actors[n].get_meta("home").x < s.y)


func _restore(n: String) -> void:
	var a: Node2D = actors[n]
	for key in ["hurt_tween", "success_flash"]:
		if a.has_meta(key):
			var tween: Tween = a.get_meta(key)
			if tween and tween.is_valid():
				tween.kill()
			a.remove_meta(key)
	if a.has_meta("resting_color"):
		a.remove_meta("resting_color")
	a.position = a.get_meta("home")
	a.rotation = 0.0
	a.scale = Vector2.ONE
	a.modulate = Color.WHITE
	_picture(a).flip_h = false
	if sheet.bearers.has(n.trim_suffix("_pole")):
		_bearer_pose(n.trim_suffix("_pole"), 0.0)


func _feedback_text(key: String) -> String:
	return _hints.text("dangers." + fight.e.id, "feedback", key)

func _feedback_once(key: String, text: String) -> void:
	var told: Dictionary = fight.get("feedback", {})
	if not told.has(key):
		told[key] = true
		fight.feedback = told
		say("Scribe", text)


func _update_fight(dt: float) -> void:
	_life_clue_hold = maxf(0.0, _life_clue_hold - dt)
	fight.ankh_flash = maxf(0.0, float(fight.get("ankh_flash", 0.0)) - dt)
	fight.t += dt
	match fight.kind:
		"crocs": crocodiles._crocs(dt)
		"twin": two_snakes._twin(dt)
		"creep": creeping_snake._creep(dt)
		"roach": beetles._roach(dt)
		"lunge": lunging_snake._lunge(dt)
		"apep": apep._apep(dt)
		"donkey": donkey._donkey(dt)
		"sheaf": sheaf._sheaf(dt)
	_tick_life(dt)


func fight_click(p: Vector2) -> void:
	if not fight.kind in ARENA_FIGHTS:
		_thrust()
	match fight.kind:
		"crocs": crocodiles._crocs_click(p)
		"twin": two_snakes._twin_click(p)
		"creep": creeping_snake._creep_click(p)
		"roach": beetles._roach_click(p)
		"lunge": lunging_snake._lunge_click(p)
		"apep": apep._apep_click(p)
		"donkey": donkey._donkey_click(p)


## End the fight after a short beat, unless it already ended (the autotest ends it at once).
func _won_if(done: bool) -> void:
	if not done:
		return
	var id: String = fight.e.id
	var session := _session
	get_tree().create_timer(0.5, false).timeout.connect(func():
		if session == _session and not fight.is_empty() and fight.e.id == id:
			end_fight())


# Shared arena, spear, and damage settings.
const CROC_OPEN := 0.8          ## seconds for the vignette to open out / close again
const CROC_PREP := 14.0 / 1.5   ## in a fight the spear rests drawn back (up its line) this far (spearers.json back)
const CROC_THRUST := 10.0       ## and then runs it out this far past where it is drawn (spearers.json reach)
const CROC_HEALTH := 3           ## bites he can take; the last one and he crumbles (the fight starts over)
const THRUST_TIME := [0.07, 0.18]   ## from drawn back to the full strike, and back to drawn back
const THRUST_DOWN := 0.5        ## (Apep, the Merti snakes) the point strikes once this far into the full thrust
## Red is #B55B3C. The sprites are drawn in ink (46, 29, 16), so the modulate that turns ink into
## that red is the ratio of the two.
const RED_CROC := UI.INK_TINT   ## red crocodiles, heka word and spear
const HURT := RED_CROC                      ## the bearer's body when bitten
const DISSOLVE := preload("res://scripts/dangers/dissolve.gdshader")
const FRAME_GAP := 8.0          ## between the two lines of a double line, as drawn (plate px)


## The opened-out vignette every fight uses: its frame (the double lines round the picture and the
## caption band) moves out to the edges of the screen, the lines keeping the thickness they have
## while walking; the caption moves to the middle of the band, at the size it has while walking
## (the wide fights, crocodiles and beetles, zoom out and it shrinks with them).
## Everything else steps out of the way. The frame is worked out on the screen
## (`fight.frame0`, as drawn, to `fight.frame1`, opened out) and drawn into the world each frame
## (_place_frame). `both`: he stands in the middle and can turn (else the double line behind him
## stays where it is drawn). `keep`: actors that stay. `view`: for a close fight, the lowest row
## to show (`y1`) and the x to centre on (`x`, or the right-hand edge, `right`), and at most `z`
## zoom; empty = a wide fight, the whole height of the scroll.
func _arena_setup(e: Dictionary, both: bool, keep: Array, view := {}) -> void:
	var s := span(e)
	var rules: Array = level.rules
	var band_top: float = rules[0][1]
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var cap: Array = level.get("caption", [50.0, 180.0])
	var lw: float = rules[0][1] - rules[0][0]
	# the frame on the screen: as drawn, under the camera you walk with ...
	var z0 := camera.zoom.x
	var c0 := camera.position
	var on0 := func(p: Vector2) -> Vector2: return (p - c0) * z0 + vp / 2.0
	fight.cam0 = {"z": z0, "x": c0.x, "y": c0.y}
	fight.line = lw * z0                                          # every line keeps its walking thickness
	fight.gap = (lw + FRAME_GAP) * z0                             # from one of a double line to the other
	var top_y: float = on0.call(Vector2(0.0, float(cap[0]) - lw)).y   # the band's top line stays put
	var bot_y: float = vp.y - bottom - hud.tag_reach() - 4.0      # clear of the speaker's tag
	var wide := view.is_empty()
	# ... and opened out, with the zoom that fits the picture between the band and the bottom
	var z: float
	var rule_y: float
	if wide:     # the whole height of the scroll (the caption shrinks with it)
		z = (vp.y - top - bottom - 10.0) / level.height
		rule_y = top_y + fight.line + (float(cap[1]) - float(cap[0])) * z
	else:        # close: the caption as while walking; the picture down to `y1`
		rule_y = on0.call(Vector2(0.0, float(cap[1]))).y
		z = (bot_y - fight.line - fight.gap - rule_y - fight.line) / (float(view.y1) - band_top)
		if view.has("z"):        # no closer than this, so the fight keeps its width
			z = minf(z, view.z)
	var vis_w: float = vp.x / z
	var cx := (s.x + s.y) / 2.0
	var cell := _caption_rect(e).grow_individual(-2.0, 0.0, -2.0, 0.0)   # (not the edge of the lines beside it)
	var ink := _caption_ink(cell)
	var s1: float = z if wide else z0
	fight.frame0 = {"l": on0.call(Vector2(s.x - 2.0 * lw - FRAME_GAP, 0.0)).x, "r": on0.call(Vector2(s.y + 2.0 * lw + FRAME_GAP, 0.0)).x,
		"top": top_y, "rule": on0.call(Vector2(0.0, float(cap[1]))).y, "bot": on0.call(Vector2(0.0, rules[-1][1])).y,
		"cap": on0.call(cell.position), "s": z0}
	fight.frame1 = {"l": 0.0, "r": vp.x, "top": top_y, "rule": rule_y, "bot": bot_y,
		"cap": Vector2(vp.x / 2.0 - ((ink.x + ink.y) / 2.0 - cell.position.x) * s1, top_y + fight.line), "s": s1}
	(_caption_art.texture as AtlasTexture).region = cell
	fight.cell = cell
	fight.signs = _caption_signs(e)
	fight.both = both
	if not wide:
		var vx: float = view.right - vis_w / 2.0 if view.has("right") else view.x
		fight.full = Rect2(vx - vis_w / 2.0, band_top, vis_w, level.height - 24.0 * unit - band_top)
	elif both:
		fight.full = Rect2(cx - vis_w / 2.0, band_top, vis_w, level.height - 24.0 * unit - band_top)
	else:   # the double line on the right stays as drawn (s.y is its inner edge); it opens to the left
		var right: float = s.y + 20.0
		fight.full = Rect2(right - vis_w, band_top, vis_w, level.height - 24.0 * unit - band_top)
	# the picture's top row (under the band's rule) sits just under the frame's rule
	fight.cam = {"z": z, "x": fight.full.get_center().x, "y": band_top - (rule_y + fight.line - vp.y / 2.0) / z}
	fight.open = 0.0
	fight.thrust = -1.0
	fight.struck = false
	fight.red = 0.0
	fight.lost = false
	fight.tut = ""
	fight.facing = -1               # -1 = left, as drawn; 1 = right
	# the bearer: where he stands once the vignette is open, and how far he may move
	var bearer: Node2D = actors[e.spear]
	var home: Vector2 = bearer.get_meta("home")
	var size: Vector2 = bearer.get_meta("size")
	var full: Rect2 = fight.full
	fight.barrier = full.end.x - 20.0                             # inner edge of the double line
	# he keeps his place across the vignette (in the middle when he can turn, where he is drawn
	# otherwise) and moves only up and down
	fight.stand = Vector2(full.get_center().x if both else home.x - CROCODILES.CROC_FORWARD * unit, ground)
	fight.x_range = Vector2(fight.stand.x, fight.stand.x)
	fight.pos = fight.stand                                       # bearer pivot, open
	fight.y_range = Vector2(band_top + size.y + 4.0 * unit, full.end.y - 26.0 * unit)
	var sp: Dictionary = sheet.bearers[e.spear]
	fight.tip = Vector2(sp.tip[0], sp.tip[1]) - home              # tip from the bearer's pivot, as drawn
	fight.dir = Vector2(sp.dir[0], sp.dir[1])
	# everything else on screen steps out of the way
	fight.hidden = []
	for nm in actors:
		if actors[nm].visible and not nm in items and not nm in keep and nm != e.spear and nm != e.spear + "_pole" and not nm in _heka_words(e.id):
			fight.hidden.append(nm)
	_arena.visible = true
	actors[e.spear + "_pole"].visible = true


func _arena_open() -> void:
	if _instant:
		_croc_open(1.0)
	else:
		_fight_tween().tween_method(_croc_open, 0.0, 1.0, CROC_OPEN)


## The spear tip and direction for the way the bearer faces (drawn facing left).
func _tip_offset() -> Vector2:
	return Vector2(fight.tip.x * -fight.facing, fight.tip.y)


func _spear_dir() -> Vector2:
	return Vector2(fight.dir.x * -fight.facing, fight.dir.y)


func _croc_open(k: float) -> void:
	if fight.is_empty() or not fight.kind in ARENA_FIGHTS:
		return
	fight.open = k
	for c in fight.get("crocs", []):
		if c.s == "wait":
			c.node.position = c.home.lerp(c.start, k)
	if fight.kind == "roach":
		var r0: Dictionary = fight.roach      # the drawn one runs out from (and back to) where it is drawn
		if not r0.darting:
			beetles._roach_place(r0, r0.home_c.lerp(r0.c0, k))
		if fight.get("closing", false) and r0.gone:
			r0.node.modulate = Color(1, 1, 1, 1.0 - k)
		for a in fight.copies:                # the others (and a swarm) fade in and out
			if is_instance_valid(a):
				a.modulate.a = k * float(a.get_meta("alpha", 1.0))
	if fight.kind == "lunge":         # it draws back from where it is drawn to where it waits
		lunging_snake._lunge_place()
	if fight.kind == "twin":          # they turn to face him; the copy on his right fades in
		two_snakes._twin_place()
	if fight.kind == "apep":
		apep._apep_place()
	if fight.kind == "sheaf":
		sheaf._sheaf_place()
	if fight.kind == "donkey":
		donkey._donkey_place()
	for nm in fight.hidden:
		actors[nm].modulate.a = 1.0 - k
	_place_bearer()


func _place_bearer() -> void:
	var e: Dictionary = fight.e
	for nm in [e.spear, e.spear + "_pole"]:
		var a: Node2D = actors[nm]
		a.position = a.get_meta("home").lerp(fight.pos, fight.open)
		_picture(a).flip_h = fight.facing > 0
	# the spear rests drawn back; a thrust runs it out past where it is drawn and draws it back again
	if fight.kind == "sheaf":
		sheaf._sheaf_pose(_spear_out())     # he leans in to the band (spell 41's own sheets)
	else:
		_bearer_pose(e.spear, _spear_out())
	# bitten: the body flushes red; heka: the spear is red (each on its own)
	actors[e.spear].modulate = Color.WHITE.lerp(HURT, clampf(fight.red / 0.8, 0.0, 1.0))
	var heka: bool = Input.is_key_pressed(KEY_SHIFT) and fight.open >= 1.0
	actors[e.spear + "_pole"].modulate = RED_CROC if heka else Color.WHITE
	_picture(actors[e.spear + "_pole"]).visible = heka


## A picture as ink: its darkness becomes opacity (a white background drops away, a transparent
## one stays), so it can be shown in any colour.
static func _ink_from(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(1, 1, 1, (1.0 - c.get_luminance()) * c.a))
	return ImageTexture.create_from_image(img)


## Only post-choice encounters read these modes. Apep and the donkey retain easy tuning
## until their `hard_ready` scaffolding is enabled in danger_encounters.gd.
func hard() -> bool:
	return not fight.is_empty() and fight.e.id in AFTER_CHOICE and not "sail38" in items and fight.e.get("hard_ready", false)


func endless() -> bool:
	return not fight.is_empty() and fight.e.id in AFTER_CHOICE and "ankh38" in items


## A damaging mistake flashes the ankh instead of consuming health or ending the fight.
func _life_mistake() -> bool:
	if not endless():
		return false
	fight.ankh_flash = LIFE_FLASH
	return true


## Count successful actions, independently of each encounter's repeating progress cycle.
func _life_hit() -> void:
	if not endless():
		return
	var id: String = fight.e.id
	_life_scores[id] = int(_life_scores.get(id, 0)) + 1
	_sync_life_score(id)


func _sync_life_score(id: String) -> void:
	if id not in journal:
		journal.append(id)
	var e: Dictionary = ENCOUNTERS.filter(func(entry): return entry.id == id)[0]
	var note := _descriptions.text(id) + "\n\n" + _hints.text("dangers." + id, "feedback", "life_score") % int(_life_scores[id])
	hud.add_journal_entry(_descriptions.entries[id].name, note, load(ASSET % e.foe), journal.size(), _descriptions.journal_total(), id)


func _tick_life(dt: float) -> void:
	if not endless() or fight.open < 1.0 or fight.get("closing", false) or hud.is_blocking() or get_tree().paused:
		return
	var id: String = fight.e.id
	_life_times[id] = float(_life_times.get(id, 0.0)) + dt
	_life_total += dt
	if not _life_clue_given and (_life_times[id] >= LIFE_GAME_CLUE or _life_total >= LIFE_TOTAL_CLUE):
		_life_clue_given = true
		say("Scribe", _hints.message("dangers.life_clue"))
		_life_clue_hold = 6.0


## The heka signs in the caption of encounter `id` (cut by tools/cut_dangers300.py, one set per vignette).
func _heka_words(id: String) -> Array:
	var h = level.get("heka", {})
	return h.get(id, []) if h is Dictionary else h


## The heka sign showing at `p`, or "".
func _heka_at(p: Vector2) -> String:
	for nm in _all_heka():
		if actors[nm].visible and actors[nm].modulate.a > 0.5 and actor_rect(nm).grow(6 * unit).has_point(p):
			return nm
	return ""


func _all_heka() -> Array:
	return _heka_signs


## The spear-bearer crumbles away (scripts/dangers/dissolve.gdshader).
func _disintegrate(e: Dictionary) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = DISSOLVE
	mat.set_shader_parameter("grain", 3.0 * unit)
	for nm in [e.spear, e.spear + "_pole"]:
		_picture(actors[nm]).material = mat
	_fight_tween().tween_method(func(v: float): mat.set_shader_parameter("amount", v), 0.0, 1.05, 1.6)


## A lost arena fight: the vignette closes and he stands in it again on the scroll, the fight not
## won. Clicking the creature takes it up again, from the first wave.
func _arena_lost(e: Dictionary) -> void:
	_crocs_close(func():
		_crocs_cleanup()
		for n in _box_actors(e):
			_restore(n)
		for n in [e.spear, e.spear + "_pole"]:    # he appears as drawn only once it is won
			if actors.has(n):
				actors[n].visible = false
		fight = {}
		avatar.position.x = rects[e.spear].get_center().x
		avatar.visible = true
		avatar.set_process(true)
		say("Scribe", _hints.message("dangers.retry")))


func _croc_thrust() -> void:
	if fight.thrust >= 0.0 or fight.open < 1.0 or fight.lost:
		return
	fight.thrust = 0.0
	fight.struck = false
	fight.last_thrust = fight.get("clock", 0.0)
	if fight.tut == "thrust":
		fight.tut = "move"
		say("Scribe", _feedback_text("movement_lesson"))


## Close the vignette again, then finish the fight (or whatever `then` does).
func _crocs_close(then := Callable()) -> void:
	fight.closing = true
	for c in fight.get("crocs", []):
		if c.s != "thief":
			c.s = "gone"
	if fight.kind == "roach":       # the drawn one runs back to where it is drawn as the vignette closes
		fight.roach.darting = false
		fight.roach.c0 = fight.roach.c
		for a in fight.copies:
			if is_instance_valid(a):
				a.set_meta("alpha", a.modulate.a)
	fight.pos = fight.stand
	fight.facing = -1
	var t := _fight_tween()
	t.tween_method(_croc_open, 1.0, 0.0, CROC_OPEN)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
			if then.is_valid():
				then.call()
			else:
				end_fight())


func _crocs_cleanup() -> void:
	_kill_fight_tweens()
	if fight.kind == "lunge":
		lunging_snake._lunge_undress()
	if fight.kind == "creep":
		creeping_snake._creep_undress()
	if fight.kind == "apep":
		apep._apep_undress()
	if fight.kind == "sheaf":
		sheaf._sheaf_undress()
	if fight.kind == "donkey":
		donkey._donkey_undress()
	for nm in _all_heka() + fight.get("signs", []):
		_restore(nm)
	for a in fight.get("copies", []):
		a.queue_free()
	for nm in fight.hidden:
		actors[nm].modulate.a = 1.0
	for nm in [fight.e.spear, fight.e.spear + "_pole"]:
		_picture(actors[nm]).flip_h = false
		_picture(actors[nm]).material = null
	_arena.visible = false


## The fight's frame on the screen now: from as drawn (open 0) to the edges of the screen (open 1),
## easing as the camera does. l, r: its outer edges; top: the band's top line; rule: the line under
## the caption; bot: the bottom of the lower bottom line; cap, s: the caption's top-left and scale.
func _frame_now() -> Dictionary:
	var a: Dictionary = fight.frame0
	var b: Dictionary = fight.frame1
	var o: float = smoothstep(0.0, 1.0, fight.open)
	var out := {}
	for key in a:
		out[key] = lerp(a[key], b[key], o)
	return out


## A rect on the screen, in the world under the camera now.
func _to_world(r: Rect2) -> Rect2:
	var vp := get_viewport_rect().size
	var z := camera.zoom.x
	return Rect2(camera.position + (r.position - vp / 2.0) / z, r.size / z)


## The opened-out vignette in the world: inside its frame, under the caption band.
func _arena_rect() -> Rect2:
	if fight.is_empty() or not fight.kind in ARENA_FIGHTS:
		return Rect2()
	var f := _frame_now()
	var side: float = fight.gap + fight.line
	return _to_world(Rect2(f.l + side, f.rule + fight.line, f.r - f.l - 2.0 * side, f.bot - side - f.rule - fight.line))


## Draw the fight's frame where it is now: papyrus inside it (over the band and the picture), the
## caption (and its signs that are sprites) where the band shows it, and the lines redrawn.
func _place_frame() -> void:
	var f := _frame_now()
	var side: float = fight.gap + fight.line
	# (from the top of the screen: what lies above the band's line is covered too)
	var band := _to_world(Rect2(f.l, 0.0, f.r - f.l, f.rule))
	_band_cover.position = band.position
	_band_cover.size = band.size
	var ar := _arena_rect()
	_arena_cover.position = ar.position
	_arena_cover.size = ar.size
	var at := _to_world(Rect2(f.cap, Vector2.ZERO)).position
	var k: float = f.s / camera.zoom.x
	_caption_art.position = at
	_caption_art.scale = Vector2(k, k)
	if not (fight.kind == "crocs" and fight.lost):   # (a crocodile carries the heka word off)
		var cell: Rect2 = fight.cell
		for nm in fight.signs:
			var a: Node2D = actors[nm]
			a.position = at + (a.get_meta("home") - cell.position) * k
			a.scale = Vector2(k, k)
	_arena_lines.queue_redraw()


func _draw_arena_lines() -> void:
	if fight.is_empty() or not fight.kind in ARENA_FIGHTS:
		return
	var f := _frame_now()
	var lw: float = fight.line
	var gap: float = fight.gap
	var w: float = f.r - f.l
	var rects := [Rect2(f.l, f.top, w, lw), Rect2(f.l, f.rule, w, lw), Rect2(f.l, f.bot - lw, w, lw), Rect2(f.l, f.bot - lw - gap, w, lw)]
	for x in [f.l, f.l + gap, f.r - lw, f.r - lw - gap]:
		rects.append(Rect2(x, f.top, lw, f.bot - f.top))
	for r in rects:
		_arena_lines.draw_rect(_to_world(r), UI.INK)


## Where a caption's ink lies across its cell (strip x, from, to): it is centred by that.
func _caption_ink(cell: Rect2) -> Vector2:
	if _strip_img == null:
		_strip_img = $Strip.texture.get_image()
		if _strip_img.is_compressed():
			_strip_img.decompress()
	var x0 := int(cell.end.x)
	var x1 := int(cell.position.x)
	for x in range(int(cell.position.x), int(cell.end.x)):
		for y in range(int(cell.position.y) + 2, int(cell.end.y) - 2, 2):
			if _strip_img.get_pixel(x, y).a > 0.4:
				x0 = mini(x0, x)
				x1 = maxi(x1, x + 1)
				break
	for nm in _caption_signs_in(cell):      # signs that are sprites of their own are not in the strip
		var r := actor_rect(nm)
		x0 = mini(x0, int(r.position.x))
		x1 = maxi(x1, int(r.end.x))
	return Vector2(x0, x1) if x1 > x0 else Vector2(cell.position.x, cell.end.x)


const ROACH_FREEZE := 0.5      ## the pause after a catch, to show it


## How far along its line the spear point is now (plate px; 0 as drawn): held out while pinned;
## at rest drawn back, drawn back as the vignette opens out (and put back as drawn as it closes).
func _spear_out() -> float:
	if fight.get("pinned", false):
		return CROC_THRUST
	var rest := _spear_rest()
	if fight.thrust < 0.0:
		return rest * float(fight.get("open", 1.0))
	return _spear_at(fight.thrust, rest)


## Where the spear point rests in a fight (plate px along its line): drawn back; against Apep, a step
## further in with every wave pressed down, as drawn once he lies still.
func _spear_rest() -> float:
	if fight.get("kind", "") == "apep":
		return -CROC_PREP * (1.0 - float(fight.hits) / float(fight.e.need))
	return -CROC_PREP


## The spear point `t` s into a thrust. In a fight it rests drawn back (up its line, or `rest`); a
## thrust only runs it out, to CROC_THRUST past where it is drawn at THRUST_TIME[0], then draws it
## back again.
static func _spear_at(t: float, rest := -CROC_PREP) -> float:
	if t < 0.0:
		return rest
	if t < THRUST_TIME[0]:
		return lerpf(rest, CROC_THRUST, t / THRUST_TIME[0])
	return lerpf(CROC_THRUST, rest, minf((t - THRUST_TIME[0]) / THRUST_TIME[1], 1.0))


## One cell of the sprite sheet: bearer `nm` in pose `i`, the figure or (`spear`) his spear alone.
func _sheet_frame(nm: String, i: int, spear: bool) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = _sheet_tex
	var cw: float = sheet.cell[0]
	var ch: float = sheet.cell[1]
	at.region = Rect2((i + (sheet.poses.size() if spear else 0)) * cw, float(sheet.bearers[nm].row) * ch, cw, ch)
	return at


## Show bearer `nm` with his spear point `o` plate px along its line from where it is drawn: the
## nearest pose in the sheet (drawn back is sheet.back, the full strike sheet.reach, in strip px).
func _bearer_pose(nm: String, o: float) -> void:
	var s := o * unit
	var p: float = s / float(sheet.back) if s < 0.0 else s / float(sheet.reach)
	var i := 0
	for k in sheet.poses.size():
		if absf(float(sheet.poses[k]) - p) < absf(float(sheet.poses[i]) - p):
			i = k
	var cw: float = sheet.cell[0]
	var ch: float = sheet.cell[1]
	var row: float = float(sheet.bearers[nm].row) * ch
	var bs: Sprite2D = _picture(actors[nm])
	if bs.has_meta("filled"):
		bs.texture = bs.get_meta("filled")[i]
	else:
		(bs.texture as AtlasTexture).region = Rect2(i * cw, row, cw, ch)
	var ps: Sprite2D = _picture(actors[nm + "_pole"])
	(ps.texture as AtlasTexture).region = Rect2((i + sheet.poses.size()) * cw, row, cw, ch)


## Dev: once per run, a picture of the screen to the path in environment variable `env`.
func _dev_shot(env: String) -> void:
	if OS.has_environment(env) and not has_meta(env):
		set_meta(env, true)
		get_tree().create_timer(0.1).timeout.connect(func():
			get_viewport().get_texture().get_image().save_png(OS.get_environment(env)))


## The time into a thrust (s) from which, and until which, its point presses a wave down.
func _thrust_down_span() -> Vector2:
	var rest := _spear_rest()
	var deep := CROC_THRUST * THRUST_DOWN
	return Vector2(THRUST_TIME[0] * (deep - rest) / (CROC_THRUST - rest),
		THRUST_TIME[0] + THRUST_TIME[1] * (CROC_THRUST - deep) / (CROC_THRUST - rest))


func _bite(text: String) -> void:
	bites += 1
	say("Scribe", text)
	var t := _fight_tween()
	for i in 6:
		t.tween_property(camera, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)) * unit, 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.05)


## A thrust where he stands as drawn (the fights where the creature is clicked): his spear only.
func _thrust() -> void:
	var nm: String = fight.e.spear
	var total: float = THRUST_TIME[0] + THRUST_TIME[1]
	_fight_tween().tween_method(func(t: float): _bearer_pose(nm, _spear_at(t)), 0.0, total, total)


# ---------------------------------------------------------------- helpers

func actor_rect(n: String) -> Rect2:
	var a: Node2D = actors[n]
	var size: Vector2 = a.get_meta("size") * a.scale.abs()
	return Rect2(a.position.x - size.x / 2.0, a.position.y - size.y, size.x, size.y)


## Struck: it flushes red and fades back, as the bearer does when bitten.
func _hurt(n: CanvasItem) -> void:
	var previous: Tween = n.get_meta("hurt_tween") if n.has_meta("hurt_tween") else null
	if previous and previous.is_valid():
		previous.kill()
	var tween := n.create_tween()
	n.set_meta("hurt_tween", tween)
	tween.tween_method(func(v: float):
		if is_instance_valid(n) and not n.is_queued_for_deletion():
			n.modulate = Color(Color.WHITE.lerp(HURT, v), n.modulate.a), 1.0, 0.0, 0.8)


func _flash(n: CanvasItem) -> void:
	UI.flash(n)


func _shake(n: Node2D) -> void:
	var t := create_tween()
	for i in 4:
		t.tween_property(n, "rotation", 0.04 if i % 2 == 0 else -0.04, 0.05)
	t.tween_property(n, "rotation", 0.0, 0.05)


func _update_camera(delta: float) -> void:
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var z := SCROLL_CAMERA.fit_zoom(vp, top, bottom, _view_height(), unit, 0.4 / unit, 2.4 / unit, VIEW_TOP)
	camera.zoom = Vector2(z, z)
	var vis_w: float = vp.x / z
	var focus := avatar.position.x - vis_w * 0.05
	if not fight.is_empty():
		var s := span(fight.e)
		focus = (s.x + s.y) / 2.0
	focus = SCROLL_CAMERA.clamp_horizontal(focus, vis_w, level.width)
	var k := SCROLL_CAMERA.smoothing(delta, 0.002)
	var y := SCROLL_CAMERA.vertical_center(_view_height(), top, bottom, z, VIEW_TOP)
	if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
		# the opened-out vignette: from the camera you walked with to the fight's (easing in and out)
		var o: float = smoothstep(0.0, 1.0, fight.open)
		z = lerpf(fight.cam0.z, fight.cam.z, o)
		camera.zoom = Vector2(z, z)
		focus = lerpf(fight.cam0.x, fight.cam.x, o)
		y = lerpf(fight.cam0.y, fight.cam.y, o)
		k = 1.0
	camera.position.x = lerpf(camera.position.x, focus, k)
	camera.position.y = y


func _view_height() -> float:
	return level.get("view_height", level.height)


func _visible_rect() -> Rect2:
	return SCROLL_CAMERA.visible_rect(camera, get_viewport_rect().size)


func _draw_overlay() -> void:
	if fight.is_empty():
		return
	if fight.kind in ["crocs", "lunge", "creep", "twin", "apep", "sheaf", "donkey"]:
		_draw_flesh_health()


# ---------------------------------------------------------------- command line

## `-- --autotest` plays every encounter through the same click handlers the player uses.
## `-- --skip=N --at=X --screenshot=path.png` marks the first N blocking encounters solved,
## puts the avatar at X, saves a frame after start-up and quits.
func _maybe_run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_autotest()
		return
	for a in args:
		if a.begins_with("--skip="):
			var n := a.trim_prefix("--skip=").to_int()
			for e in ENCOUNTERS:
				if n > 0 and not e.kind in ["note", "end"]:
					solved[e.id] = true
					if e.kind == "take":
						items.append(e.items[0])
					else:
						actors[e.spear].visible = true
					n -= 1
			_refresh()
		elif a.begins_with("--at="):
			avatar.position.x = a.trim_prefix("--at=").to_float()
			_update_camera(1.0)
	for a in args:   # dev: another random seed (the roach's and crocodiles' paths)
		if a.begins_with("--seed="):
			rng.seed = a.trim_prefix("--seed=").to_int()
	if OS.has_environment("ROACH_NEED"):   # dev: try the roach fight with another number of catches
		_roach_need = OS.get_environment("ROACH_NEED").to_int()
	if "--croc-bot" in args:   # dev: let the stand-in player fight the next crocodile vignette
		hud.dismiss_intro()
		Engine.time_scale = 2.0
		get_tree().create_timer(0.5).timeout.connect(func():   # take up the spear where he stands
			if not here().is_empty():
				start_fight(here()))
		var on_start := func():
			if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
				fight.bot = true
				fight.tut = ""
		get_tree().create_timer(3.0).timeout.connect(on_start)
		var tries := [0, ""]       # attempts, the encounter being fought
		var watch := Timer.new()
		watch.wait_time = 0.5
		add_child(watch)
		watch.timeout.connect(func():
			if fight.is_empty() and tries[1] != "" and not solved.has(tries[1]) and not here().is_empty():
				start_fight(here())       # lost: click the creature again, as a player would
			if not fight.is_empty() and fight.kind in ARENA_FIGHTS and not fight.get("bot", false):
				fight.bot = true          # a (re)started fight: play it
				fight.tut = ""
				tries[0] += 1
				tries[1] = fight.e.id
			if (tries[1] != "" and solved.has(tries[1])) or _time > 400.0:
				print("BOT ", tries[1], " won" if solved.has(tries[1]) else " gave up", " after ", tries[0], " tries, bites ", bites, ", ", int(_time), " s")
				get_tree().quit())
		watch.start()
	if "--croc-eat" in args:   # dev: once the crocodile vignette is open, one slips past for the word
		get_tree().create_timer(1.2).timeout.connect(func():
			if not fight.is_empty() and fight.kind == "crocs":
				fight.heka_on = true
				fight.tut = ""
				var c: Dictionary = fight.crocs[0]
				c.s = "crawl"
				c.speed = 200.0
				c.node.position = Vector2(fight.barrier - 40.0 * unit - crocodiles._croc_head(c.node, 1).x, fight.y_range.y))
	for a in args:
		if a.begins_with("--screenshot="):
			hud.dismiss_intro()
			var wait := 90 if "--wait" in args else 30
			for b in args:
				if b.begins_with("--frames="):
					wait = b.trim_prefix("--frames=").to_int()
			for i in wait:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


func _draw_flesh_health() -> void:
	if endless():
		var image: Texture2D = _picture(actors.ankh38).texture
		var size := image.get_size()
		var at := _arena_rect().position + Vector2(40.0, 14.0)
		var flash := float(fight.get("ankh_flash", 0.0))
		var tint := Color.WHITE.lerp(RED_CROC, flash / LIFE_FLASH)
		overlay.draw_texture_rect(image, Rect2(at, size), false, Color(tint, fight.open))
		return
	# his health (against the Eater of the Ass, the donkey's): flesh signs in red, top left inside
	# the opened vignette; a lost one stays faint
	var health: int = int(fight.get("donkey_health", fight.get("health", 0)))
	var ar := _arena_rect()
	var fs := _flesh_tex.get_size() if _flesh_tex else Vector2(28.0, 28.0)
	for i in CROC_HEALTH:
		var at := Vector2(ar.position.x + 40.0 + i * (fs.x + FLESH_GAP), ar.position.y + 14.0)
		var a: float = (1.0 if i < health else 0.22) * fight.open
		if _flesh_tex:
			# the picture as given, its dark ink turned red: shown through a red silhouette
			overlay.draw_texture_rect(_flesh_tex, Rect2(at, fs), false, Color(UI.DANGER, a))
		else:
			overlay.draw_circle(at + fs / 2.0, fs.y / 2.0, Color(UI.DANGER, a))


func _autotest() -> void:
	hud.dismiss_intro()
	var fails: Array[String] = []   # lambdas capture locals by value, so collect into an array
	var expect := func(cond: bool, what: String):
		print(("PASS " if cond else "FAIL ") + what)
		if not cond:
			fails.append(what)
	_instant = true

	avatar.position.x = span(ENCOUNTERS[0]).y - 100.0 * unit
	_check_position()
	expect.call(fight.is_empty(), "walking into a vignette does not start its fight")
	# on the scroll the heka signs flash red, and clicking one explains them
	if not _all_heka().is_empty():
		var hw: String = _all_heka()[0]
		_time = PI / 10.0           # the top of the pulse
		_process(0.0)
		expect.call(actors[hw].modulate.r > 1.5, "the heka signs flash red on the scroll")
		expect.call(_heka_at(actor_rect(hw).get_center()) == hw, "a heka sign on the scroll can be clicked")
	var e38: Dictionary = ENCOUNTERS.filter(func(x): return x.id == "e38")[0]
	expect.call(avatar.min_x < span(ENCOUNTERS[0]).x and avatar.min_x > span(e38).x and avatar.min_x < span(e38).y, "the way is open past unsolved vignettes and into spell 38, not past it")
	for e in ENCOUNTERS:     # all but spell 37 done: 38 is still shut
		if e.id == "e37":
			break
		solved[e.id] = true
	_refresh()
	expect.call(avatar.min_x > span(e38).x, "the way past spell 38 shut while spell 37 is undone")
	solved["e37"] = true
	_refresh()
	expect.call(avatar.min_x < span(e38).x, "the choice is optional once the earlier dangers are overcome")
	expect.call(_item_at(actor_rect("sail38").get_center()) == "sail38" and _item_at(actor_rect("ankh38").get_center()) == "ankh38",
		"the sail and the ankh can each be taken, before the way on opens")
	take(e38, "ankh38")
	expect.call(solved.has("e38") and items == ["ankh38"] and actors.sail38.visible and _item_at(actor_rect("sail38").get_center()) == "",
		"only one sign is taken: the other stays in his hand and can no longer be taken")
	reset()

	for e in ENCOUNTERS:
		if e.kind == "take":
			take(e)
			expect.call(solved.has(e.id), e.id + " item taken")
			expect.call(avatar.min_x < span(e).x, e.id + ": the way on opens once it and the dangers before it are done")
			continue
		if not e.kind in FIGHTS:
			continue
		avatar.position.x = span(e).y - 100.0 * unit
		_check_position()
		start_fight(e)
		expect.call(fight.get("e", {}).get("id", "") == e.id, e.id + " fight starts on clicking the creature")
		leave_fight()
		expect.call(fight.is_empty() and not solved.has(e.id) and avatar.visible, e.id + " Esc steps out of the fight, not won")
		start_fight(e)
		_update_fight(0.1)
		expect.call(fight.t > 0.0, e.id + " the fight runs from the click, no Space needed to begin")
		match e.kind:
			"crocs": crocodiles.autotest(e, expect)
			"twin": two_snakes.autotest(e, expect)
			"creep": creeping_snake.autotest(e, expect)
			"roach": beetles.autotest(e, expect)
			"lunge": lunging_snake.autotest(e, expect)
			"apep": apep.autotest(e, expect)
			"donkey": donkey.autotest(e, expect)
			"sheaf": sheaf.autotest(e, expect)
		end_fight()  # the real game waits half a second first
		expect.call(solved.has(e.id), e.id + " overcome")
		var flashed: Array = _box_actors(e).map(func(n): return _picture(actors[n]).get_children().any(func(c): return c.material is ShaderMaterial and (c.material as ShaderMaterial).get_shader_parameter("level") == UI.Glow.SUCCESS))
		expect.call(not flashed.is_empty() and flashed.all(func(f): return f), e.id + " won: its figures flash pale green")

	expect.call(current.is_empty(), "every danger before spell 42 is overcome")
	avatar.position.x = span(ENCOUNTERS[-1]).y - 50.0 * unit
	_check_position()
	expect.call(finished, "level finished at spell 42")
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
