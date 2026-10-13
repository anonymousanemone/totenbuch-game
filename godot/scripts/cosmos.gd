## Spell 17: the long cosmological strip (Lepsius, Todtenbuch pl. VII-XI).
##
## World coordinates are pixels of the cleaned 300-dpi strip (assets/cosmos/strip.png, from the
## hand-assembled bod17-21), which reads right to left. Positions come from
## assets/cosmos/level.json, written by tools/cut_cosmos300.py.
##
## Four things are wrong in the night world, each fixed with what the strip itself shows:
##   1. the two lions of the horizon face each other and shut the sun in: turn them back to back;
##   2. the ba has stayed behind at the head of the strip: bring it to the mummy on its bier;
##   3. a snake creeps at the persea tree: let the cat strike when its head is under the knife;
##   4. the god in Ra's boat has no sun: carry the risen sun to him.
## Then come before Osiris.
extends Node2D

const DATA_PATH := "res://assets/cosmos/level.json"
const ART := "res://assets/cosmos/%s.png"
const BESIDE := 70.0          ## stand just behind (right of) what you interact with
const HOVER := Color(0.64, 0.2, 0.12, 0.55)   ## only for `--show-hits`
const INK := Color(0.18, 0.11, 0.06)

## Where a carried piece is accepted, by journal label, and how it sits there.
const PLACE := {"ba": "The mummy on the lion bier", "sun": "Ra's boat of the day"}
const NAMES := {"ba": "the ba", "sun": "the sun"}
const ROOF := Vector2(11850, 524)   ## the ba waits at the head of the strip, where the deceased was drawn (bottom centre)

const SNAKE_PERIOD := 2.6     ## seconds for the snake to creep in and draw back
const SNAKE_REACH := 70.0     ## how far back it draws (plate px; scaled by `unit`)
const STRIKE_WINDOW := 9.0    ## the head must be this close to the knife (plate px)
const HITS_NEEDED := 2

var level: Dictionary
var ground := 524.0
var unit := 1.5
var rects := {}               ## piece -> Rect2 where it is drawn on the strip
var hotspots: Array = []      ## [{rect, label, note}]
var walls := {}

# state
var lions_out := {"lion_l": false, "lion_r": false}   ## true = facing outward, as drawn
var sun_state := "hidden"     ## hidden, risen, held, placed
var ba_state := "away"        ## away, held, placed
var snake_hits := 0
var snake_cut := false
var held := ""
var finished := false
var journal: Array[String] = []
var _hint_step := {}

var _pieces := {}             ## name -> Sprite2D
var _hover := {}
var _time := 0.0
var _snake_t := 0.0
var _cat_busy := false
var _bump_time := -10.0
var _show_hits := false
var _sun_risen_pos := Vector2.ZERO

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	ground = level.ground
	unit = level.get("scale", 1.0)
	avatar.speed *= unit
	avatar.bob_height *= unit
	avatar.drawn_facing = 1   # the deceased at the head of this strip faces right
	$Papyrus.size = Vector2(level.width + 4000.0, level.height + 1600.0)
	walls = level.walls
	for n in level.sprites:
		var s: Dictionary = level.sprites[n]
		rects[n] = Rect2(s.x, s.y, s.w, s.h)
	for h in level.hotspots:
		hotspots.append({"rect": Rect2(h.x, h.y, h.w, h.h), "label": h.label, "note": h.note})
	# draw order: the sun rises from behind the horizon sign
	for n in ["sun", "horizon", "lion_l", "lion_r", "ba", "snake", "cat", "baboons"]:
		var sp := Sprite2D.new()
		sp.texture = load(ART % n)
		sp.centered = false
		$Pieces.add_child(sp)
		_pieces[n] = sp
	var hz: Rect2 = rects.horizon
	_sun_risen_pos = Vector2(hz.get_center().x - rects.sun.size.x / 2.0, hz.position.y - rects.sun.size.y - 6.0 * unit)

	overlay.draw.connect(_draw_overlay)
	avatar.bumped.connect(_on_bumped)
	hud.setup(self, {
		"title": "The Night Journey",
		"subtitle": "Spell 17 · Lepsius, Todtenbuch, pl. VII–XI",
		"rites_heading": "BEFORE THE DAWN",
		"tasks": [
			"Open the horizon",
			"Return the ba to the body",
			"Help the cat at the persea tree",
			"Give Ra his sun",
			"Come before Osiris",
		],
		"journal_hint": "Click figures in the scroll to record them here.",
		"intro_title": "Spell 17: The Night Journey",
		"intro_body": "Spell 17 sets out the whole night world in one long strip: the senet game, the lions of the horizon, the mummy on its bier, the cat at the persea tree, the boats of the sun, and Osiris on his throne.\n\n"
			+ "Something is out of place in each of them, and the sun cannot rise until they are set right.\n\n"
			+ "The scroll reads [b]right to left[/b]. Click the papyrus to walk, or use ← →. Click figures to look at them and record them in your journal. Some things can be picked up and carried. Esc puts a carried thing back.",
		"outro_title": "The sun is reborn",
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
	lions_out = {"lion_l": false, "lion_r": false}
	sun_state = "hidden"
	ba_state = "away"
	snake_hits = 0
	snake_cut = false
	held = ""
	finished = false
	journal.clear()
	_hint_step.clear()
	_cat_busy = false
	for n in _pieces:
		var sp: Sprite2D = _pieces[n]
		sp.position = rects[n].position
		sp.rotation = 0.0
		sp.scale = Vector2.ONE
		sp.modulate = Color.WHITE
		sp.visible = true
	for c in $Pieces.get_children():
		if c.has_meta("half"):
			c.queue_free()
	avatar.stop()
	avatar.position = Vector2(level.start_x, ground)
	avatar.facing = -1
	hud.reset_view()
	say("Scribe", "It is night. The strip ahead is the whole of the other world, and nothing in it is quite as it should be. Walk left and look.")
	_render()
	_update_camera(1.0)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking():
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
		var h := _pick(p)
		if h.is_empty():
			walk_then(p.x)
		else:
			walk_then(h.rect.get_center().x + BESIDE * unit, use.bind(h))


## What is under the pointer: a piece that does something, then a journal region.
func _pick(p: Vector2) -> Dictionary:
	for n in _active_pieces():
		var r := Rect2(_pieces[n].position, rects[n].size)
		if r.has_point(p):
			return {"type": "piece", "id": n, "rect": r}
	for h in hotspots:
		if h.rect.has_point(p):
			return {"type": "hot", "spot": h, "rect": h.rect}
	return {}


func _active_pieces() -> Array:
	var out := ["lion_l", "lion_r"]
	if sun_state == "risen":
		out.append("sun")
	if ba_state == "away":
		out.append("ba")
	if not snake_cut:
		out += ["cat", "snake"]
	return out


func use(h: Dictionary) -> void:
	if h.type == "piece":
		match h.id:
			"lion_l", "lion_r":
				turn_lion(h.id)
			"sun", "ba":
				take(h.id)
			"cat", "snake":
				strike()
	else:
		record(h.spot)


# ---------------------------------------------------------------- movement and barriers

func wall_x() -> float:
	if not horizon_open():
		return walls.horizon
	if not snake_cut:
		return walls.snake
	if sun_state != "placed":
		return walls.boat
	return -1.0


func min_x() -> float:
	var w := wall_x()
	return 60.0 * unit if w < 0.0 else w + 70.0 * unit


func max_x() -> float:
	return level.width - 60.0 * unit


func walk_then(x: float, then := Callable()) -> void:
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	var tx := clampf(x, avatar.min_x, avatar.max_x)
	avatar.walk_to(tx, func():
		if tx - x > 140.0 * unit:
			_blocked()
		elif then.is_valid():
			then.call())


func _on_bumped() -> void:
	if _time - _bump_time > 2.5:
		_bump_time = _time
		_blocked()


func _blocked() -> void:
	if not horizon_open():
		say("Scribe", "The way ends at the horizon. The two lions sit nose to nose, and between them the sun is shut in.")
	elif not snake_cut:
		say("Scribe", "A snake lies across the path at the persea tree. You cannot step over it.")
	else:
		say("Scribe", "Ra's boat lies dark across the way. It will not move without its sun.")


# ---------------------------------------------------------------- the four tasks

func horizon_open() -> bool:
	return lions_out.lion_l and lions_out.lion_r


## 1. The lions of yesterday and tomorrow sit back to back. Turned inward, they hold the sun.
func turn_lion(id: String) -> void:
	if horizon_open():
		say("Scribe", "The lion looks away from the horizon, as it should.")
		return
	lions_out[id] = not lions_out[id]
	var sp: Sprite2D = _pieces[id]
	var t := create_tween()
	t.tween_property(sp, "scale:x", 0.05, 0.18)
	t.tween_callback(_render)
	t.tween_property(sp, "scale:x", 1.0, 0.18)
	if horizon_open():
		say("Scribe", "Back to back now: one lion looks to yesterday, the other to tomorrow. Between them the horizon opens, and the sun climbs out of it.")
		_rise_sun()
	elif lions_out[id]:
		say("Scribe", "The lion turns its head away from the horizon.")
	else:
		say("Scribe", "The lion turns to face the horizon again.")


func _rise_sun() -> void:
	sun_state = "risen"
	var sp: Sprite2D = _pieces.sun
	sp.visible = true
	sp.position = Vector2(_sun_risen_pos.x, rects.horizon.position.y + 30.0 * unit)
	sp.modulate.a = 0.0
	sp.set_meta("rising", true)
	var t := create_tween().set_parallel()
	t.tween_property(sp, "position", _sun_risen_pos, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(sp, "modulate:a", 1.0, 1.2)
	t.chain().tween_callback(func(): sp.remove_meta("rising"))
	_check()


## 2 and 4. Carried things: the ba and the sun.
func take(id: String) -> void:
	if held != "":
		say("Scribe", "Your hands are full.")
		return
	held = id
	if id == "sun":
		sun_state = "held"
		say("Scribe", "You lift the sun from the horizon. It is lighter than it looks.")
	else:
		ba_state = "held"
		say("Ba", "The bird with a human head lets you carry it. It keeps looking back, the way you came.")
	_render()


func put_back() -> void:
	if held == "sun":
		sun_state = "risen"
		_pieces.sun.position = _sun_risen_pos
		say("Scribe", "You set the sun back above the horizon.")
	elif held == "ba":
		ba_state = "away"
		say("Scribe", "The ba flies back to the head of the strip.")
	else:
		return
	held = ""
	_render()


func _offer(spot: Dictionary) -> bool:
	if held == "" or spot.label != PLACE[held]:
		return false
	if held == "ba":
		ba_state = "placed"
		held = ""
		say("Ba", "The ba settles beside the bier, at the mummy's head. Body and soul are together again.")
		_flash(_pieces.ba)
	elif held == "sun":
		sun_state = "placed"
		held = ""
		say("Scribe", "You set the sun on the god's head. The baboons raise their hands to it, and the boat of the day begins to move.")
		_flash(_pieces.sun)
	_render()
	_check()
	return true


## 3. The cat cuts the snake at the persea tree, if the head is under the knife.
func snake_offset() -> float:
	## 0 = head under the cat's knife; negative = drawn back (left).
	var p := fmod(_snake_t, SNAKE_PERIOD) / SNAKE_PERIOD
	var k := 0.5 - 0.5 * cos(p * TAU)          # 0 -> 1 -> 0
	return -SNAKE_REACH * unit * (1.0 - k) + 4.0 * unit * k


func strike() -> void:
	if snake_cut or _cat_busy:
		return
	if held != "":
		say("Scribe", "The cat ignores %s." % NAMES[held])
		return
	_cat_busy = true
	var hit := absf(snake_offset()) < STRIKE_WINDOW * unit
	var cat: Sprite2D = _pieces.cat
	var t := create_tween()
	t.tween_property(cat, "position", rects.cat.position + Vector2(-10.0 * unit, 3.0 * unit), 0.08)
	t.tween_property(cat, "position", rects.cat.position, 0.25)
	t.tween_callback(func(): _cat_busy = false)
	if hit:
		snake_hits += 1
		_flash(_pieces.snake)
		if snake_hits >= HITS_NEEDED:
			_cut_snake()
			say("Cat", "The knife comes down on the snake's neck. It does not move again.")
		else:
			_snake_t = 0.0   # it recoils and starts again from the back
			say("Cat", "The knife bites. The snake jerks back, then creeps in again.")
	else:
		say("Cat", "The cat strikes at nothing. The snake's head was not under the knife.")
	_check()


func _cut_snake() -> void:
	snake_cut = true
	var sp: Sprite2D = _pieces.snake
	sp.position = rects.snake.position
	sp.visible = false
	var w: float = rects.snake.size.x
	var cut := w * 0.78
	for i in 2:
		var half := Sprite2D.new()
		var tex := AtlasTexture.new()
		tex.atlas = sp.texture
		tex.region = Rect2(0, 0, cut, rects.snake.size.y) if i == 0 else Rect2(cut, 0, w - cut, rects.snake.size.y)
		half.texture = tex
		half.centered = false
		half.position = rects.snake.position + Vector2(0 if i == 0 else cut, 0)
		half.set_meta("half", true)
		$Pieces.add_child(half)
		var t := create_tween().set_parallel()
		t.tween_property(half, "position:x", half.position.x + (-6.0 if i == 0 else 8.0) * unit, 0.4)
		t.tween_property(half, "rotation", -0.03 if i == 0 else 0.08, 0.4)
		t.tween_property(half, "modulate", Color(1, 1, 1, 0.75), 0.8)


func _check() -> void:
	_render()


## Clicking a figure: record it in the journal; carried things are offered to it.
func record(h: Dictionary) -> void:
	if held != "":
		if _offer(h):
			_add_journal(h)
			return
		say("Scribe", "You hold %s. Nothing here takes it." % NAMES[held])
		_add_journal(h)
		return
	if h.label == "Osiris enthroned":
		_add_journal(h)
		if _all_done():
			finish()
		else:
			say("Osiris", "Osiris looks past you, toward the dark end of the strip. Something there is still undone.")
		return
	var text: String = h.note
	match h.label:
		"The mummy on the lion bier":
			if ba_state != "placed":
				text += " Its head lies alone: nothing keeps watch beside it."
		"Ra's boat of the day":
			if sun_state != "placed":
				text = "The god sits in his boat with nothing on his head. The baboons before him raise their hands to empty air."
	say(h.label, text)
	_add_journal(h)


func _all_done() -> bool:
	return horizon_open() and ba_state == "placed" and snake_cut and sun_state == "placed"


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


func finish() -> void:
	if finished:
		return
	finished = true
	_render()
	say("Osiris", "The night is crossed. Go out by day.")
	var body := "The lions look to yesterday and tomorrow, the ba keeps watch by the body, the snake is cut at the persea tree, and Ra's boat carries the sun.\n\n" \
		+ "Next: [b]the councils of spell 18[/b], where the deceased is declared true of voice before each company of gods.\n\n" \
		+ "[i]Journal: %d of %d figures recorded.[/i]" % [journal.size(), _journal_total()]
	get_tree().create_timer(0.9).timeout.connect(func(): hud.show_outro(body))


## Each press says a little more about the first unfinished task.
func hint() -> void:
	var task := ""
	var lines: Array = []
	if not horizon_open():
		task = "horizon"
		lines = ["The way stops at the horizon, between the two lions.",
			"The two lions are yesterday and tomorrow. Which way should they look?",
			"Click each lion to turn it. They should sit back to back, looking away from the horizon."]
	elif sun_state == "risen" and ba_state != "placed" and held == "":
		task = "sun_or_ba"
		lines = ["The sun has risen out of the horizon. It can be carried.",
			"Someone further on is waiting for a sun to wear.",
			"Take the sun with you to Ra's boat in plate X."]
	elif ba_state != "placed":
		task = "ba"
		lines = ["Look at the mummy on the lion bier. What is missing beside it?",
			"A bird with a human head is the ba. One was waiting where you started.",
			"The ba stands at the head of the strip, behind the senet booth. Carry it to the mummy on the bier."]
	elif not snake_cut:
		task = "snake"
		lines = ["Watch the snake at the persea tree. It creeps in and draws back.",
			"The cat holds a knife. It can only cut what is under it.",
			"Click the cat when the snake's head is right under its knife (twice)."]
	elif sun_state != "placed":
		task = "sun"
		lines = ["The god in Ra's boat in plate X has nothing on his head.",
			"The sun you raised at the horizon belongs to him.",
			"Carry the sun from the horizon and give it to Ra's boat."]
	else:
		task = "osiris"
		lines = ["Walk to the end of the strip.", "Osiris sits enthroned near the far left. Click him."]
	var i: int = _hint_step.get(task, 0)
	say("Hint", lines[mini(i, lines.size() - 1)])
	_hint_step[task] = i + 1


func say(who: String, text: String) -> void:
	hud.say(who, text)


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	_time += delta
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	if not snake_cut:
		_snake_t += delta
		_pieces.snake.position = rects.snake.position + Vector2(snake_offset(), 0)
	if sun_state == "placed":  # the baboons adore
		var b: Sprite2D = _pieces.baboons
		b.position = rects.baboons.position + Vector2(0, -absf(sin(_time * 2.2)) * 4.0 * unit)
	if sun_state == "risen":   # the risen sun hangs above the horizon, breathing a little
		var sp: Sprite2D = _pieces.sun
		if not sp.has_meta("rising"):
			sp.position.y = _sun_risen_pos.y + sin(_time * 1.5) * 2.0 * unit
	_update_camera(delta)
	var w := wall_x()
	hud.update_minimap(avatar.position.x, _visible_rect(), w, w >= 0.0)
	hud.update_held(held, _pieces[held].texture if held != "" else null, camera.zoom.x)
	overlay.queue_redraw()


func _view_height() -> float:
	return level.get("view_height", level.height)


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


func _visible_rect() -> Rect2:
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)


func _render() -> void:
	_pieces.lion_l.flip_h = not lions_out.lion_l
	_pieces.lion_r.flip_h = not lions_out.lion_r
	_pieces.sun.visible = sun_state in ["risen", "placed"]
	if sun_state == "placed":
		_pieces.sun.position = rects.sun.position
	_pieces.ba.visible = ba_state != "held"
	if ba_state == "away":
		_pieces.ba.position = ROOF - Vector2(rects.ba.size.x / 2.0, rects.ba.size.y)
	elif ba_state == "placed":
		_pieces.ba.position = rects.ba.position
	hud.update_tasks([horizon_open(), ba_state == "placed", snake_cut, sun_state == "placed", finished])
	hud.update_hand(held, NAMES.get(held, ""), _pieces[held].texture if held != "" else null)


func _draw_overlay() -> void:
	if _show_hits:
		for n in _active_pieces():
			overlay.draw_rect(Rect2(_pieces[n].position, rects[n].size), Color(0.3, 0.42, 0.16, 0.7), false, 3.0)
		for h in hotspots:
			overlay.draw_rect(h.rect, HOVER, false, 3.0)
	var w := wall_x()
	if w >= 0.0:
		var y := 190.0
		while y < ground:
			overlay.draw_line(Vector2(w, y), Vector2(w, y + 8.0 * unit), Color(INK, 0.45), 6.0 * unit)
			y += 16.0 * unit


func _flash(node: CanvasItem) -> void:
	var t := create_tween()
	node.modulate = Color(1.8, 1.4, 0.6)
	t.tween_property(node, "modulate", Color.WHITE, 1.0)


# ---------------------------------------------------------------- command line

## `-- --autotest` plays the level through the same rules the player uses.
## `--at=X` starts the avatar at X, `--skip=N` solves the first N tasks,
## `--show-hits` outlines click regions, `--screenshot=path.png` saves a frame and quits.
func _maybe_run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_autotest()
		return
	for a in args:
		if a.begins_with("--skip="):
			_skip(a.trim_prefix("--skip=").to_int())
		elif a.begins_with("--at="):
			avatar.position.x = a.trim_prefix("--at=").to_float()
			_update_camera(1.0)
		elif a == "--show-hits":
			_show_hits = true
	for a in args:
		if a.begins_with("--screenshot="):
			hud.dismiss_intro()
			for i in 40:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


func _skip(n: int) -> void:
	if n >= 1:
		lions_out = {"lion_l": true, "lion_r": true}
		sun_state = "risen"
		_pieces.sun.position = _sun_risen_pos
	if n >= 2:
		ba_state = "placed"
	if n >= 3:
		_cut_snake()
	if n >= 4:
		sun_state = "placed"
	_render()


func _spot(label: String) -> Dictionary:
	for h in hotspots:
		if h.label == label:
			return h
	return {}


func _autotest() -> void:
	var fails: Array[String] = []   # lambdas capture locals by value, so collect into an array
	var expect := func(cond: bool, what: String):
		print(("PASS " if cond else "FAIL ") + what)
		if not cond:
			fails.append(what)
	# every journal region and piece answers a click at its centre
	var missed: Array[String] = []
	for h in hotspots:
		var p: Vector2 = h.rect.get_center()
		var got := _pick(p)
		if got.is_empty():
			missed.append(h.label)
	for n in _active_pieces():
		var got := _pick(Rect2(_pieces[n].position, rects[n].size).get_center())
		if got.get("id", "") != n:
			missed.append(n)
	expect.call(missed.is_empty(), "every region answers a click at its centre %s" % [missed])
	expect.call(min_x() > walls.horizon, "the horizon blocks the way at the start")
	turn_lion("lion_l")
	expect.call(not horizon_open(), "one lion turned is not enough")
	turn_lion("lion_r")
	expect.call(horizon_open() and sun_state == "risen", "both lions back to back: the sun rises")
	expect.call(min_x() > walls.snake and min_x() < walls.horizon, "the way opens as far as the snake")
	take("sun")
	record(_spot("The mummy on the lion bier"))
	expect.call(held == "sun", "the bier does not take the sun")
	put_back()
	expect.call(held == "" and sun_state == "risen", "Esc puts the sun back")
	take("ba")
	record(_spot("The mummy on the lion bier"))
	expect.call(ba_state == "placed", "the ba returned to the body")
	_snake_t = 0.0   # drawn back
	strike()
	expect.call(snake_hits == 0, "a strike at the wrong moment misses")
	for i in HITS_NEEDED:
		_cat_busy = false
		_snake_t = SNAKE_PERIOD / 2.0   # head under the knife
		strike()
	expect.call(snake_cut, "the cat cuts the snake")
	record(_spot("Osiris enthroned"))
	expect.call(not finished, "Osiris waits while Ra has no sun")
	take("sun")
	record(_spot("Ra's boat of the day"))
	expect.call(sun_state == "placed", "the sun given to Ra")
	expect.call(wall_x() < 0.0, "all barriers open")
	record(_spot("Osiris enthroned"))
	expect.call(finished, "level finished before Osiris")
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
