## Spell 110: the Field of Offerings (Lepsius, Todtenbuch pl. XLI).
##
## The whole page is one picture: three registers framed by water. The camera shows one register
## at a time; clicking another register walks you to this register's crossing point and over.
## World coordinates are pixels of the 300-dpi sheet (assets/field/strip.png); positions come from
## assets/field/level.json, written by tools/cut_sheets300.py.
##
##   middle: work the field in the order the register runs (right to left): plough, sow, reap,
##           thresh; the grain heaps rise and you can take grain;
##   top:    the gods' offering table is bare; feed them, and the boat takes you across;
##   bottom: of the two snake boats only the one with oars sails, to the landing stairs.
extends Node2D

const DATA_PATH := "res://assets/field/level.json"
const ART := "res://assets/field/%s.png"
const BESIDE := 70.0
const HOVER := Color(0.64, 0.2, 0.12, 0.55)   ## only for `--show-hits`
const INK := Color(0.18, 0.11, 0.06)

## Farming stages, in the order the middle register is read.
const STAGES := ["ploughed", "sown", "grown", "reaped", "threshed"]

var level: Dictionary
var unit := 1.8
var regs := {}
var reg := "top"
var rects := {}
var hotspots: Array = []

# state
var stage := 0               ## how many of STAGES are done
var fed := false
var top_crossed := false
var sailed := false
var held := ""
var finished := false
var journal: Array[String] = []
var _hint_step := {}

var _pieces := {}
var _grow := {}              ## piece -> 0..1, drawn growing up from its base line
var _hover := {}
var _time := 0.0
var _busy := false           ## a crossing or ride is playing
var _show_hits := false

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	unit = level.scale
	regs = level.registers
	avatar.speed *= unit
	avatar.bob_height *= unit
	$Papyrus.size = Vector2(level.width + 4000.0, level.height + 1600.0)
	for n in level.sprites:
		var s: Dictionary = level.sprites[n]
		rects[n] = Rect2(s.x, s.y, s.w, s.h)
	for h in level.hotspots:
		hotspots.append({"rect": Rect2(h.x, h.y, h.w, h.h), "label": h.label, "note": h.note, "region": h.region})
	for n in level.sprites:
		if n == "avatar":
			continue
		var sp := Sprite2D.new()
		sp.texture = load(ART % n)
		sp.centered = false
		$Pieces.add_child(sp)
		_pieces[n] = sp

	overlay.draw.connect(_draw_overlay)
	avatar.bumped.connect(_on_bumped)
	hud.setup(self, {
		"title": "The Field of Offerings",
		"subtitle": "Spell 110 · Lepsius, Todtenbuch, pl. XLI",
		"rites_heading": "IN THE FIELD",
		"tasks": [
			"Work the field",
			"Feed the gods of the field",
			"Cross by the boat",
			"Sail to the landing",
		],
		"journal_hint": "Click figures in the field to record them here.",
		"intro_title": "Spell 110: The Field of Offerings",
		"intro_body": "The Field of Offerings lies inside a frame of water, in three bands. Here the dead plough, sow and reap for ever, and the gods are fed from the harvest.\n\n"
			+ "Click the papyrus to walk, or use ← →. Click another band to cross over to it. Click figures to look at them; some things can be set going, and some carried.\n\n"
			+ "Each band reads [b]right to left[/b], like the scroll.",
		"outro_title": "You reach the landing",
		"bottom": 200.0,
		"task_size": 15,
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	hud.minimap_clicked.connect(func(x): walk_then(x))
	reset()
	_maybe_run_cli()


func reset() -> void:
	stage = 0
	fed = false
	top_crossed = false
	sailed = false
	held = ""
	finished = false
	_busy = false
	journal.clear()
	_hint_step.clear()
	for n in _pieces:
		var sp: Sprite2D = _pieces[n]
		sp.position = rects[n].position
		sp.rotation = 0.0
		sp.flip_h = false
		sp.modulate = Color.WHITE
		sp.visible = true
		sp.region_enabled = false
	_grow = {"grain": 0.0, "heap1": 0.0, "heap2": 0.0, "seed": 0.0}
	_pieces.food.visible = false
	reg = "top"
	avatar.visible = true
	avatar.stop()
	avatar.position = Vector2(regs.top.door, regs.top.ground)
	avatar.facing = -1
	hud.reset_view()
	say("Scribe", "You have come into the Field of Offerings. The gods of the field sit before an empty table. Walk left and look around.")
	_render()
	_update_camera(1.0)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		put_back()
	elif event is InputEventMouseMotion:
		var h := _pick(get_global_mouse_position())
		if h != _hover:
			_hover = h
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if h else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		var other := _region_at(p.y)
		if other != "" and other != reg:
			cross_to(other)
			return
		var h := _pick(p)
		if h.is_empty():
			walk_then(p.x)
		else:
			walk_then(h.rect.get_center().x + BESIDE * unit, use.bind(h))


func _region_at(y: float) -> String:
	for k in regs:
		if y >= regs[k].y0 and y <= regs[k].y1:
			return k
	return ""


func _pick(p: Vector2) -> Dictionary:
	if _region_at(p.y) != reg:
		return {}
	for n in _active_pieces():
		var r := _piece_rect(n)
		if r.has_point(p):
			return {"type": "piece", "id": n, "rect": r}
	for h in hotspots:
		if h.region == reg and h.rect.has_point(p):
			return {"type": "hot", "spot": h, "rect": h.rect}
	return {}


func _piece_rect(n: String) -> Rect2:
	return Rect2(_pieces[n].position, rects[n].size)


func _active_pieces() -> Array:
	match reg:
		"middle":
			var out := ["plough", "sower", "reaper1", "reaper2", "thresher"]
			if stage >= STAGES.size():
				out += ["heap1", "heap2"]
			return out
		"top":
			return ["boat"]
		"bottom":
			return ["boat_stairs", "boat_oars"] if not sailed else []
	return []


func use(h: Dictionary) -> void:
	if h.type == "piece":
		match h.id:
			"plough": work(0, "plough")
			"sower": work(1, "sower")
			"reaper1", "reaper2": work(3, h.id)
			"thresher": work(4, "thresher")
			"heap1", "heap2": take_grain()
			"boat": cross_by_boat()
			"boat_stairs": say("Scribe", "This boat has stairs on its deck but no oars. It will not move.")
			"boat_oars": sail()
	else:
		record(h.spot)


# ---------------------------------------------------------------- movement

func _bounds() -> Vector2:
	var r: Dictionary = regs[reg]
	var lo: float = r.x0
	var hi: float = r.x1
	if reg == "top":
		if top_crossed:
			hi = rects.boat.position.x - 20.0 * unit
		else:
			lo = level.walls.boat + 40.0 * unit
	elif reg == "bottom":
		if sailed:
			lo = 3460.0
		else:
			hi = level.walls.channel
	return Vector2(lo, hi)


func _door() -> float:
	if reg == "top" and top_crossed:
		return regs.top.x0 + 60.0
	return regs[reg].door


func walk_then(x: float, then := Callable()) -> void:
	var b := _bounds()
	avatar.min_x = b.x
	avatar.max_x = b.y
	var tx := clampf(x, b.x, b.y)
	avatar.walk_to(tx, func():
		if absf(tx - x) > 140.0 * unit:
			_blocked(x < tx)
		elif then.is_valid():
			then.call())


func _on_bumped() -> void:
	_blocked(true)


func _blocked(left: bool) -> void:
	if reg == "top" and not top_crossed and left:
		say("Scribe", "The boat lies across the way. Its rower waits.")
	elif reg == "bottom" and not sailed and not left:
		say("Scribe", "Water curls across the field here. You need a boat.")


## Walk to this band's crossing point, then appear at the other band's.
func cross_to(target: String) -> void:
	if reg == "bottom" and sailed:
		say("Scribe", "You have reached the landing. There is no going back.")
		return
	_busy = true
	avatar.min_x = -1.0e9
	avatar.max_x = 1.0e9
	avatar.walk_to(_door(), func():
		var t := create_tween()
		t.tween_property(avatar, "modulate:a", 0.0, 0.3)
		t.tween_callback(func():
			reg = target
			avatar.position = Vector2(_door(), regs[reg].ground)
			_update_camera(1.0)
			_arrive_text())
		t.tween_property(avatar, "modulate:a", 1.0, 0.3)
		t.tween_callback(func(): _busy = false))


func _arrive_text() -> void:
	match reg:
		"middle":
			say("Scribe", "The middle band is the field itself. Its ox stands idle and the ground is bare." if stage == 0 else "You wade across to the field.")
		"top":
			say("Scribe", "You wade back to the upper band.")
		"bottom":
			say("Scribe", "You come out at the far end of the lowest band, among the waterways. Two boats with snake prows lie here.")


# ---------------------------------------------------------------- the field

const NOT_READY := [
	"The ground is hard. It has not been ploughed.",
	"Nothing has been sown.",
	"The grain has not grown yet.",
	"There is nothing cut to thresh.",
	"",
]


func work(step: int, who: String) -> void:
	if step < stage or (step == 3 and stage > 3):
		say("Scribe", "That work is done.")
		return
	if step > stage:
		say("Scribe", NOT_READY[stage])
		return
	match step:
		0:
			say("Ploughman", "He raises his stick and the ox leans into the plough. The earth turns over behind them.")
		1:
			say("Sower", "He swings the seed out of his bag in a long arc over the ploughed ground.")
			_grow_to("seed", 1.0, 1.4)
			get_tree().create_timer(2.0).timeout.connect(func():
				stage = 3   # the grain grows by itself
				_grow_to("grain", 1.0, 2.6)
				say("Scribe", "The grain comes up, taller than a man.")
				_render())
		3:
			say("Reapers", "The sickles flash. The tall grain falls in armfuls.")
			_grow_to("grain", 0.16, 1.2)
		4:
			say("Thresher", "The ox treads the cut grain on the threshing floor, round and round. The chaff blows off, and the grain is heaped up.")
			_grow_to("heap1", 1.0, 2.0, 0.8)
			_grow_to("heap2", 1.0, 2.0, 1.4)
	stage = maxi(stage, step + 1) if step != 1 else 2
	_render()


func _grow_to(n: String, v: float, secs: float, delay := 0.0) -> void:
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_method(func(x): _grow[n] = x, _grow[n], v, secs).set_trans(Tween.TRANS_SINE)


func take_grain() -> void:
	if held != "":
		say("Scribe", "Your hands are full.")
		return
	held = "grain"
	say("Scribe", "You fill your arms with grain from the heap.")
	_render()


func put_back() -> void:
	if held == "":
		return
	held = ""
	say("Scribe", "You let the grain fall.")
	_render()


# ---------------------------------------------------------------- the gods and the boats

func record(h: Dictionary) -> void:
	if h.label == "Offering table" and held == "grain" and not fed:
		fed = true
		held = ""
		_pieces.food.visible = true
		_flash(_pieces.food)
		say("Gods of the Field", "Bread and grain are heaped on the table. The three gods are fed, and the rower in the boat takes up his oar.")
		_add_journal(h)
		_render()
		return
	var text: String = h.note
	match h.label:
		"Offering table":
			text = "The table is heaped with offerings." if fed else "The gods' table is bare."
		"Gods of the Field":
			if not fed:
				text += " Their table is empty."
		"Hetep":
			if stage < STAGES.size():
				text += " His field lies unworked."
		"The landing stairs":
			if not sailed:
				text = "Stairs rise out of the water at the far side of the channels, out of reach."
	say(h.label, text)
	_add_journal(h)


func cross_by_boat() -> void:
	if not fed:
		say("Rower", "The rower sits with his oar across his knees. He will not row while the gods of the field go hungry.")
		return
	_busy = true
	var boat: Sprite2D = _pieces.boat
	var home: Vector2 = rects.boat.position
	var to_left := not top_crossed
	var t := create_tween()
	t.tween_property(avatar, "modulate:a", 0.0, 0.25)
	t.tween_property(boat, "position", home + Vector2((-1.0 if to_left else 1.0) * 60.0 * unit, 0), 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func():
		top_crossed = to_left
		avatar.position.x = home.x - 50.0 * unit if to_left else level.walls.boat + 70.0 * unit)
	t.tween_property(boat, "position", home, 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(avatar, "modulate:a", 1.0, 0.25)
	t.tween_callback(func():
		_busy = false
		say("Rower", "He rows you over and sets you down on the far side." if to_left else "He rows you back.")
		_render())


func sail() -> void:
	if sailed:
		return
	if not fed:
		say("Scribe", "The oars hang still. Nothing in the field moves until the gods of the field have eaten.")
		return
	_busy = true
	var boat: Sprite2D = _pieces.boat_oars
	var t := create_tween()
	t.tween_property(avatar, "modulate:a", 0.0, 0.25)
	t.tween_property(boat, "position", rects.boat_oars.position + Vector2(1350.0, 0), 4.0).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(boat, "modulate:a", 0.0, 1.0).set_delay(3.0)
	t.tween_callback(func():
		sailed = true
		avatar.position.x = 3540.0)
	t.tween_property(avatar, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		_busy = false
		_render()
		finish())


func finish() -> void:
	if finished:
		return
	finished = true
	_render()
	say("Scribe", "The boat with oars carries you through the channels to the landing stairs.")
	var body := "The field is worked, the gods are fed, and the boat has brought you to the landing at the end of the Field of Offerings.\n\n" \
		+ "Next: [b]the gates and portals (144–147)[/b], and then the Hall of the Two Truths.\n\n" \
		+ "[i]Journal: %d of %d figures recorded.[/i]" % [journal.size(), _journal_total()]
	get_tree().create_timer(1.2).timeout.connect(func(): hud.show_outro(body))


func _add_journal(h: Dictionary) -> void:
	if h.label in journal:
		return
	journal.append(h.label)
	var tex := AtlasTexture.new()
	tex.atlas = $Strip.texture
	tex.region = h.rect
	hud.add_journal_entry(h.label, h.note, tex, journal.size(), _journal_total())


func _journal_total() -> int:
	var seen := {}
	for h in hotspots:
		seen[h.label] = true
	return seen.size()


func hint() -> void:
	var task := ""
	var lines: Array = []
	if stage < STAGES.size():
		task = "farm"
		lines = ["The gods need food, and food comes from the field: the middle band.",
			"The middle band shows a year of work, right to left. Start at its right-hand end.",
			["Click the ploughman with his ox.", "Click the sower.", "Wait for the grain to grow.", "Click a reaper.", "Click the ox on the threshing floor."][stage]]
		if reg != "middle":
			lines[0] = "Click the middle band to cross over to the field."
	elif not fed:
		task = "feed"
		lines = ["The grain heaps are full.", "Take grain from a heap and carry it to the gods' table in the top band.",
			"In the top band, click the offering table in front of the three seated gods while you hold grain."]
	elif not top_crossed and not sailed:
		task = "boat"
		lines = ["The rower in the top band will take you now.", "Click the boat in the top band."]
	else:
		task = "sail"
		lines = ["The lowest band has two boats with snake prows.", "Only a boat with oars can sail. Click it."]
	var i: int = _hint_step.get(task + str(stage), 0)
	say("Hint", lines[mini(i, lines.size() - 1)])
	_hint_step[task + str(stage)] = i + 1


func say(who: String, text: String) -> void:
	hud.say(who, text)


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	_time += delta
	if not _busy:
		var b := _bounds()
		avatar.min_x = b.x
		avatar.max_x = b.y
	_animate()
	_update_camera(delta)
	hud.update_minimap(avatar.position.x, _visible_rect(), 0.0, false)
	hud.update_held(held, _grain_icon() if held != "" else null, camera.zoom.x)
	overlay.queue_redraw()


func _animate() -> void:
	# plough: the team heaves forward and eases back
	var pl: Sprite2D = _pieces.plough
	if stage >= 1:
		var k := sin(_time * 2.2)
		pl.position = rects.plough.position + Vector2(-6.0 * unit * maxf(k, 0.0), -absf(sin(_time * 4.4)) * 1.5 * unit)
	# sower bobs as he throws; the seed arc is drawn out from the hand, over and over
	if stage >= 1 and stage < 4:
		_pieces.sower.position = rects.sower.position + Vector2(0, -absf(sin(_time * 3.0)) * 2.0 * unit)
	_draw_seed()
	if stage >= 4:
		_draw_stubble()
	else:
		_draw_growing("grain")
	_draw_growing("heap1")
	_draw_growing("heap2")
	# reapers swing while there is standing grain to cut, and after
	for n in ["reaper1", "reaper2"]:
		var sp: Sprite2D = _pieces[n]
		if stage >= 4:
			var ph := 0.0 if n == "reaper1" else 1.3
			sp.position = rects[n].position + Vector2(sin(_time * 5.0 + ph) * 3.0 * unit, 0)
		else:
			sp.position = rects[n].position
	# thresher: the ox treads back and forth across the floor
	var th: Sprite2D = _pieces.thresher
	if stage >= 5:
		th.position = rects.thresher.position + Vector2(sin(_time * 0.9) * 14.0 * unit, -absf(sin(_time * 3.6)) * 1.2 * unit)
	# the boat with oars rocks on the water
	if not sailed and not _busy:
		_pieces.boat_oars.position.y = rects.boat_oars.position.y + sin(_time * 1.3) * 2.0 * unit
		_pieces.boat_stairs.position.y = rects.boat_stairs.position.y + sin(_time * 1.1 + 1.0) * 1.5 * unit


func _draw_seed() -> void:
	var sp: Sprite2D = _pieces.seed
	var v: float = _grow.seed
	if v <= 0.0:
		sp.visible = false
		return
	sp.visible = true
	sp.region_enabled = true
	var h: float = rects.seed.size.y
	# the arc falls from the top: reveal it downward, then fall again while sowing lasts
	var f := v if stage >= 3 else fmod(_time * 0.7, 1.0)
	sp.region_rect = Rect2(0, 0, rects.seed.size.x, maxf(1.0, h * f))
	sp.modulate.a = 1.0 if stage < 4 else 0.0


func _draw_growing(n: String) -> void:
	var sp: Sprite2D = _pieces[n]
	var v: float = _grow[n]
	sp.visible = v > 0.01
	sp.scale.y = maxf(v, 0.01)
	sp.position.y = rects[n].position.y + rects[n].size.y * (1.0 - sp.scale.y)


## After reaping only the stubble stands: the lowest part of the stalks, uncut.
func _draw_stubble() -> void:
	var sp: Sprite2D = _pieces.grain
	var v: float = _grow.grain       # 1 -> STUBBLE while the reapers cut
	var h: float = rects.grain.size.y
	sp.visible = true
	sp.scale.y = 1.0
	sp.region_enabled = true
	sp.region_rect = Rect2(0, h * (1.0 - v), rects.grain.size.x, h * v)
	sp.position.y = rects.grain.position.y + h * (1.0 - v)


func _grain_icon() -> Texture2D:
	return _pieces.heap2.texture


func _update_camera(delta: float) -> void:
	var r: Dictionary = regs[reg]
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var view_h: float = r.y1 - r.y0
	var z := clampf(minf((vp.y - top - bottom - 10.0) / view_h, vp.x / (1000.0 * unit)), 0.1, 3.0)
	camera.zoom = Vector2(z, z)
	var vis_w := vp.x / z
	var target_x := avatar.position.x - vis_w * 0.05
	target_x = clampf(target_x, vis_w / 2.0, maxf(vis_w / 2.0, level.width - vis_w / 2.0))
	var k := 1.0 if delta >= 1.0 else 1.0 - pow(0.001, delta)
	camera.position.x = lerpf(camera.position.x, target_x, k)
	var ty: float = (r.y0 + r.y1) / 2.0 + (bottom - top) / 2.0 / z
	camera.position.y = ty if delta >= 1.0 else lerpf(camera.position.y, ty, k)
	avatar.position.y = r.ground


func _visible_rect() -> Rect2:
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)


func _render() -> void:
	hud.update_tasks([stage >= STAGES.size(), fed, top_crossed or sailed, sailed])
	hud.update_hand(held, "grain" if held != "" else "", _grain_icon() if held != "" else null)


func _draw_overlay() -> void:
	if not _show_hits:
		return
	for n in _active_pieces():
		overlay.draw_rect(_piece_rect(n), Color(0.3, 0.42, 0.16, 0.7), false, 3.0)
	for h in hotspots:
		if h.region == reg:
			overlay.draw_rect(h.rect, HOVER, false, 3.0)


func _flash(node: CanvasItem) -> void:
	var t := create_tween()
	node.modulate = Color(1.8, 1.4, 0.6)
	t.tween_property(node, "modulate", Color.WHITE, 1.0)


# ---------------------------------------------------------------- command line

## `--autotest`, `--reg=middle`, `--at=X`, `--skip=N` (N tasks done), `--stage=N`,
## `--show-hits`, `--screenshot=path.png`.
func _maybe_run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_autotest()
		return
	for a in args:
		if a.begins_with("--reg="):
			reg = a.trim_prefix("--reg=")
			avatar.position = Vector2(regs[reg].door, regs[reg].ground)
		elif a.begins_with("--stage="):
			_set_stage(a.trim_prefix("--stage=").to_int())
		elif a.begins_with("--skip="):
			var n := a.trim_prefix("--skip=").to_int()
			_set_stage(5)
			if n >= 2:
				fed = true
				_pieces.food.visible = true
			if n >= 3:
				top_crossed = true
		elif a.begins_with("--at="):
			avatar.position.x = a.trim_prefix("--at=").to_float()
		elif a == "--show-hits":
			_show_hits = true
		elif a == "--bare":   # dev: background only
			$Strip.visible = false
			$Pieces.visible = false
	_render()
	_update_camera(1.0)
	for a in args:
		if a.begins_with("--screenshot="):
			hud.dismiss_intro()
			for i in 90:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


func _set_stage(n: int) -> void:
	stage = n
	_grow.seed = 1.0 if n >= 2 else 0.0
	_grow.grain = 0.0 if n < 3 else (1.0 if n == 3 else 0.16)
	_grow.heap1 = 1.0 if n >= 5 else 0.0
	_grow.heap2 = _grow.heap1


func _spot(label: String, region: String) -> Dictionary:
	for h in hotspots:
		if h.label == label and h.region == region:
			return h
	return {}


func _autotest() -> void:
	var fails: Array[String] = []   # lambdas capture locals by value, so collect into an array
	var expect := func(cond: bool, what: String):
		print(("PASS " if cond else "FAIL ") + what)
		if not cond:
			fails.append(what)
	var missed: Array[String] = []
	for r in regs:
		reg = r
		for h in hotspots:
			if h.region == r and _pick(h.rect.get_center()).is_empty():
				missed.append(h.label)
	reg = "top"
	expect.call(missed.is_empty(), "every region answers a click at its centre %s" % [missed])
	expect.call(_bounds().x > rects.boat.position.x, "the boat bars the top band at the start")
	cross_by_boat()
	expect.call(not top_crossed and not _busy, "the rower will not row for hungry gods")
	reg = "middle"
	work(1, "sower")
	expect.call(stage == 0, "cannot sow unploughed ground")
	work(0, "plough")
	work(1, "sower")
	expect.call(stage == 2, "ploughed and sown")
	await get_tree().create_timer(2.3).timeout
	expect.call(stage == 3, "the grain grows by itself")
	work(4, "thresher")
	expect.call(stage == 3, "cannot thresh standing grain")
	work(3, "reaper1")
	work(4, "thresher")
	expect.call(stage == 5, "reaped and threshed")
	take_grain()
	expect.call(held == "grain", "grain taken from the heap")
	reg = "bottom"
	sail()
	expect.call(not sailed and not _busy, "the oared boat waits for the gods to be fed")
	reg = "top"
	record(_spot("Offering table", "top"))
	expect.call(fed and held == "", "the gods are fed")
	cross_by_boat()
	await get_tree().create_timer(3.4).timeout
	expect.call(top_crossed, "the boat takes you across")
	reg = "bottom"
	use({"type": "piece", "id": "boat_stairs"})
	expect.call(not sailed, "the boat without oars stays")
	sail()
	await get_tree().create_timer(5.2).timeout
	expect.call(sailed and finished, "sailed to the landing")
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
