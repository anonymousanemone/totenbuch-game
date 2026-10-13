## Spell 125: the Hall of the Two Truths and the Weighing of the Heart (Lepsius, pl. L).
##
## World coordinates are pixels of the 300-dpi sheet (assets/hall/strip.png); positions come from
## assets/hall/level.json, written by tools/cut_sheets300.py.
##
## You come in at the right carrying your heart. Ma'at lets you into the hall. Set the heart on
## the balance: it sinks, and Ammit rises. Declare yourself innocent before each of the 42 judges
## in the frieze; with each declaration the heart rises a little. When the beam is level the
## baboon on the post nods, Thoth can write the verdict, and Horus leads you to Osiris.
extends Node2D

const DATA_PATH := "res://assets/hall/level.json"
const ART := "res://assets/hall/%s.png"
const BESIDE := 70.0
const HOVER := Color(0.64, 0.2, 0.12, 0.55)
const INK := Color(0.18, 0.11, 0.06)
const PIVOT := Vector2(3782, 990)       ## top of the balance post (sheet px, after the crop)
const BEAM_ENDS := Vector2(3055, 4212)  ## x of the hooks the pans hang from
const MAX_TILT := 0.1                   ## radians, heart side down, before any declaration
const NEEDED := 42                      ## declarations needed to level the beam

## The negative confession: one declaration for each judge.
const DECLARATIONS := [
	"I have not done wrong.", "I have not robbed with violence.", "I have not stolen.",
	"I have not killed men.", "I have not cheated the grain measure.", "I have not taken the offerings of the gods.",
	"I have not told lies.", "I have not taken food by force.", "I have not caused weeping.",
	"I have not dealt deceitfully.", "I have not acted with guile.", "I have not laid waste ploughed land.",
	"I have not been an eavesdropper.", "I have not set my mouth in motion against anyone.", "I have not been angry without cause.",
	"I have not defiled another's wife.", "I have not polluted myself.", "I have not struck fear into anyone.",
	"I have not transgressed.", "I have not been hot of speech.", "I have not been deaf to words of truth.",
	"I have not stirred up strife.", "I have not made anyone weep.", "I have not been lustful.",
	"I have not eaten my heart in vain regret.", "I have not been quarrelsome.", "I have not been hasty of heart.",
	"I have not multiplied words beyond what was right.", "I have not done harm or ill.", "I have not cursed the king.",
	"I have not fouled the water.", "I have not spoken scornfully.", "I have not cursed a god.",
	"I have not been boastful.", "I have not taken more than my due.", "I have not taken what is not mine.",
	"I have not despised the god of my town.", "I have not stolen bread from the dead.", "I have not taken milk from the mouths of children.",
	"I have not driven cattle from their pasture.", "I have not dammed running water.", "I have not put out a fire when it should burn.",
]

var level: Dictionary
var unit := 5.9
var ground := 2035.0
var rects := {}
var hotspots: Array = []
var judges: Array[String] = []

# state
var maat_ok := false
var heart_placed := false
var declared := {}            ## judge -> true
var verdict := false
var finished := false
var held := "heart"
var journal: Array[String] = []
var _hint_step := {}

var _pieces := {}
var _hover := {}
var _time := 0.0
var _tilt := 0.0
var _ammit_up := 0.0
var _lunge := 0.0
var _show_hits := false
var _busy := false

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	unit = level.scale
	ground = level.ground
	avatar.speed *= unit
	avatar.bob_height *= unit
	$Papyrus.size = Vector2(level.width + 4000.0, level.height + 1600.0)
	for n in level.sprites:
		var s: Dictionary = level.sprites[n]
		rects[n] = Rect2(s.x, s.y, s.w, s.h)
		if n.begins_with("judge"):
			judges.append(n)
	judges.sort()
	for h in level.hotspots:
		hotspots.append({"rect": Rect2(h.x, h.y, h.w, h.h), "label": h.label, "note": h.note})
	# draw order: pans behind the beam, heart on its pan
	for n in ["pan_l", "pan_r", "beam", "heart", "baboon", "ammit", "thoth", "crookfig", "maat", "shai"] + judges:
		var sp := Sprite2D.new()
		sp.texture = load(ART % n)
		sp.centered = false
		$Pieces.add_child(sp)
		_pieces[n] = sp
	# the beam turns about the top of the post
	var beam: Sprite2D = _pieces.beam
	beam.offset = rects.beam.position - PIVOT
	beam.position = PIVOT

	overlay.draw.connect(_draw_overlay)
	avatar.bumped.connect(func(): _blocked())
	hud.setup(self, {
		"title": "The Weighing of the Heart",
		"subtitle": "Spell 125 · Lepsius, Todtenbuch, pl. L",
		"rites_heading": "IN THE HALL OF THE TWO TRUTHS",
		"tasks": [
			"Be let into the hall",
			"Set your heart on the balance",
			"Declare yourself before the 42 judges",
			"Have the verdict written",
			"Come before Osiris",
		],
		"journal_hint": "Click figures in the hall to record them here.",
		"intro_title": "Spell 125: The Hall of the Two Truths",
		"intro_body": "This is the end of the road. In the hall of Osiris your heart is weighed against Ma'at, truth and right order. Forty-two judges sit above the hall, one for each wrong you must deny. Ammit, the Devourer, waits for a heart that is heavy.\n\n"
			+ "You carry your heart. The scroll reads [b]right to left[/b]: walk in, click figures to look at them and to act.",
		"outro_title": "True of voice",
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
	maat_ok = false
	heart_placed = false
	declared.clear()
	verdict = false
	finished = false
	held = "heart"
	_busy = false
	_tilt = 0.0
	_ammit_up = 0.0
	_lunge = 0.0
	journal.clear()
	_hint_step.clear()
	for n in _pieces:
		if n == "beam":
			continue
		_pieces[n].position = rects[n].position
		_pieces[n].rotation = 0.0
		_pieces[n].modulate = Color.WHITE
	_pieces.beam.rotation = 0.0
	avatar.stop()
	avatar.position = Vector2(rects.avatar.get_center().x, ground)
	avatar.facing = -1
	hud.reset_view()
	say("Scribe", "You stand at the door of the Hall of the Two Truths, your heart in your hands. Ma'at stands before you.")
	_render()
	_update_camera(1.0)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or _busy:
		return
	if event is InputEventMouseMotion:
		var h := _pick(get_global_mouse_position())
		if h != _hover:
			_hover = h
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if h else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		var h := _pick(p)
		if h.is_empty():
			walk_then(p.x)
		elif h.get("id", "").begins_with("judge"):
			declare(h.id)   # the judges sit high above: answer them from where you stand
		else:
			walk_then(h.rect.get_center().x + BESIDE * unit, use.bind(h))


func _pick(p: Vector2) -> Dictionary:
	for n in _active_pieces():
		var r := _piece_rect(n)
		if r.has_point(p):
			return {"type": "piece", "id": n, "rect": r}
	for h in hotspots:
		if h.rect.has_point(p):
			return {"type": "hot", "spot": h, "rect": h.rect}
	return {}


func _piece_rect(n: String) -> Rect2:
	var sp: Sprite2D = _pieces[n]
	return Rect2(sp.position, rects[n].size)


func _active_pieces() -> Array:
	return ["maat", "pan_r", "pan_l", "crookfig", "thoth", "ammit", "baboon", "shai"] + judges


func use(h: Dictionary) -> void:
	if h.type == "hot":
		record(h.spot)
		return
	match h.id:
		"maat": speak_to_maat()
		"pan_r", "pan_l": place_heart()
		"thoth": ask_thoth()
		"ammit": say("Ammit", "Part crocodile, part lion, part hippopotamus. She watches the balance and waits." if not verdict else "Ammit settles back on her pedestal, hungry.")
		"baboon": say("Baboon", "The baboon of Thoth sits on the post and watches the beam." + (" It nods: the beam is level." if _level_now() else ""))
		"shai": say("Scribe", "A small figure under the pan reaches up to it, as if it could hold the heart's side up or pull it down.")
		"crookfig": say("Scribe", "A tiny figure crouches on a shepherd's crook before Thoth.")


# ---------------------------------------------------------------- movement

func min_x() -> float:
	if not maat_ok:
		return level.walls.maat + 70.0 * unit
	if not verdict:
		return level.walls.thoth + 70.0 * unit
	return 400.0


func walk_then(x: float, then := Callable()) -> void:
	avatar.min_x = min_x()
	avatar.max_x = level.width - 300.0
	var tx := clampf(x, avatar.min_x, avatar.max_x)
	avatar.walk_to(tx, func():
		if tx - x > 140.0 * unit:
			_blocked()
		elif then.is_valid():
			then.call())


func _blocked() -> void:
	if not maat_ok:
		say("Scribe", "Ma'at stands in the doorway, tall as the hall. You cannot walk past her without a word.")
	elif not verdict:
		say("Scribe", "Thoth stands with his palette in the way. Nothing passes him unwritten.")


# ---------------------------------------------------------------- the rite

func speak_to_maat() -> void:
	if maat_ok:
		say("Ma'at", "The feather on her head stirs. The balance is behind her.")
		return
	maat_ok = true
	_flash(_pieces.maat)
	say("Ma'at", "\"Come in. Your heart will be weighed against me.\" She steps aside, and the hall opens.")
	_render()


func place_heart() -> void:
	if heart_placed:
		if _level_now():
			say("Scribe", "The beam hangs level: the heart weighs no more than the figure of truth on the other pan.")
		else:
			say("Scribe", "The heart's pan hangs low. %d judges are still waiting." % (NEEDED - declared.size()))
		return
	if not maat_ok:
		say("Scribe", "Ma'at stands in the way.")
		return
	heart_placed = true
	held = ""
	say("Scribe", "You set your heart on the right-hand pan. The beam tips and the heart sinks: it weighs against you. On her pedestal, Ammit lifts her head.")
	_render()


func declare(judge: String) -> void:
	if not heart_placed:
		say("Judge", "The judge looks down at your empty pan. \"First let your heart be weighed.\"")
		return
	if declared.has(judge):
		say("Judge", "This judge has heard you already.")
		_nod(judge)
		return
	var line: String = DECLARATIONS[declared.size() % DECLARATIONS.size()]
	declared[judge] = true
	_nod(judge)
	_pieces[judge].modulate = Color(1.0, 0.85, 0.55)
	var left := NEEDED - declared.size()
	if left > 0:
		say("You, before judge %d" % (judges.find(judge) + 1), "\"%s\" The heart rises a little. (%d still to answer.)" % [line, left])
	else:
		say("You, before the last judge", "\"%s\" The beam comes level. On the post, the baboon of Thoth nods." % line)
		_flash(_pieces.baboon)
	_render()


func _nod(judge: String) -> void:
	var sp: Sprite2D = _pieces[judge]
	var t := create_tween()
	t.tween_property(sp, "position:y", rects[judge].position.y + 8.0, 0.15)
	t.tween_property(sp, "position:y", rects[judge].position.y, 0.25)


func _level_now() -> bool:
	return heart_placed and declared.size() >= NEEDED


func ask_thoth() -> void:
	if verdict:
		say("Thoth", "It is written. Go to Osiris.")
		return
	if not _level_now():
		_lunge = 1.0
		say("Thoth", "Thoth lifts his pen and does not write. Ammit lunges toward the balance and is held back." if heart_placed else "Thoth waits. There is nothing on the balance to judge.")
		return
	verdict = true
	_busy = true
	var th: Sprite2D = _pieces.thoth
	var t := create_tween()
	for i in 3:
		t.tween_property(th, "position:y", rects.thoth.position.y - 6.0, 0.18)
		t.tween_property(th, "position:y", rects.thoth.position.y, 0.18)
	t.tween_callback(func():
		_busy = false
		say("Thoth", "He writes on his palette: the heart is weighed and found true. You are true of voice. Horus will lead you to Osiris.")
		_render())


func record(h: Dictionary) -> void:
	if h.label == "Osiris":
		_add_journal(h)
		if verdict:
			finish()
		else:
			say("Osiris", "Osiris sits silent until the verdict is written.")
		return
	var text: String = h.note
	if h.label == "The balance" and heart_placed:
		text += " The beam is level." if _level_now() else " The heart's pan hangs low."
	say(h.label, text)
	_add_journal(h)


func finish() -> void:
	if finished:
		return
	finished = true
	_render()
	say("Osiris", "\"Let him go forth, true of voice. Let bread and beer be given him, and a place in the Field of Offerings.\"")
	var body := "Your heart has been weighed against Ma'at and found level. The judges heard you, Thoth wrote the verdict, and Osiris receives you.\n\n" \
		+ "This is the end of the journey through the Book of the Dead.\n\n" \
		+ "[i]Journal: %d of %d figures recorded.[/i]" % [journal.size(), hotspots.size()]
	get_tree().create_timer(1.2).timeout.connect(func(): hud.show_outro(body))


func _add_journal(h: Dictionary) -> void:
	if h.label in journal:
		return
	journal.append(h.label)
	var tex := AtlasTexture.new()
	tex.atlas = $Strip.texture
	tex.region = h.rect
	hud.add_journal_entry(h.label, h.note, tex, journal.size(), hotspots.size())


func hint() -> void:
	var task := ""
	var lines: Array = []
	if not maat_ok:
		task = "maat"; lines = ["Ma'at, with the feather on her head, blocks the door.", "Click Ma'at."]
	elif not heart_placed:
		task = "heart"; lines = ["You are carrying your heart. Where is it weighed?", "Click the right-hand pan of the balance."]
	elif not _level_now():
		task = "judges"; lines = ["The heart is too heavy. Who must hear you?", "The 42 judges sit in a row high above the hall.", "Click each of the judges in the frieze at the top. Every one must hear you."]
	elif not verdict:
		task = "thoth"; lines = ["The beam is level. Who writes the verdict?", "Click Thoth, the ibis-headed god with the palette."]
	else:
		task = "osiris"; lines = ["Walk on to the end of the hall.", "Click Osiris on his throne."]
	var i: int = _hint_step.get(task, 0)
	say("Hint", lines[mini(i, lines.size() - 1)])
	_hint_step[task] = i + 1


func say(who: String, text: String) -> void:
	hud.say(who, text)


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	_time += delta
	avatar.min_x = min_x()
	avatar.max_x = level.width - 300.0
	var target := 0.0
	if heart_placed:
		target = MAX_TILT * (1.0 - float(declared.size()) / NEEDED)
	_tilt = lerpf(_tilt, target, 1.0 - pow(0.02, delta))
	var sway := sin(_time * 1.6) * 0.006 * (1.0 if heart_placed and not _level_now() else 0.25)
	var a := _tilt + sway
	_pieces.beam.rotation = a
	var dl := (BEAM_ENDS.x - PIVOT.x) * sin(a)
	var dr := (BEAM_ENDS.y - PIVOT.x) * sin(a)
	_pieces.pan_l.position = rects.pan_l.position + Vector2(0, dl)
	_pieces.pan_r.position = rects.pan_r.position + Vector2(0, dr)
	_pieces.heart.visible = heart_placed
	_pieces.heart.position = rects.heart.position + Vector2(0, dr)
	# Ammit rises while the heart sinks, and lunges when Thoth refuses
	var want := 1.0 if heart_placed and not _level_now() else 0.0
	_ammit_up = lerpf(_ammit_up, want, 1.0 - pow(0.1, delta))
	_lunge = maxf(0.0, _lunge - delta * 1.4)
	var am: Sprite2D = _pieces.ammit
	am.position = rects.ammit.position + Vector2(sin(_lunge * PI) * 160.0, -40.0 * _ammit_up - absf(sin(_time * 6.0)) * 6.0 * _ammit_up)
	# the baboon on the post nods once the beam is level
	var bb: Sprite2D = _pieces.baboon
	bb.position = rects.baboon.position + Vector2(0, (absf(sin(_time * 3.0)) * 5.0 if _level_now() and not verdict else 0.0))
	_update_camera(delta)
	hud.update_minimap(avatar.position.x, _visible_rect(), min_x(), not verdict)
	hud.update_held(held, _pieces.heart.texture if held != "" else null, camera.zoom.x)
	overlay.queue_redraw()


func _update_camera(delta: float) -> void:
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var z := clampf(minf((vp.y - top - bottom - 10.0) / level.height, vp.x / (1000.0 * unit)), 0.05, 2.0)
	camera.zoom = Vector2(z, z)
	var vis_w := vp.x / z
	var target_x := avatar.position.x - vis_w * 0.05
	target_x = clampf(target_x, vis_w / 2.0, maxf(vis_w / 2.0, level.width - vis_w / 2.0))
	var k := 1.0 if delta >= 1.0 else 1.0 - pow(0.001, delta)
	camera.position.x = lerpf(camera.position.x, target_x, k)
	camera.position.y = level.height / 2.0 + (bottom - top) / 2.0 / z


func _visible_rect() -> Rect2:
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)


func _render() -> void:
	hud.update_tasks([maat_ok, heart_placed, _level_now(), verdict, finished])
	hud.update_hand(held, "your heart" if held != "" else "", _pieces.heart.texture if held != "" else null)


func _draw_overlay() -> void:
	if _show_hits:
		for n in _active_pieces():
			overlay.draw_rect(_piece_rect(n), Color(0.3, 0.42, 0.16, 0.7), false, 6.0)
		for h in hotspots:
			overlay.draw_rect(h.rect, HOVER, false, 6.0)
	var w := min_x() - 70.0 * unit
	if not verdict:
		var y := 1100.0
		while y < ground:
			overlay.draw_line(Vector2(w, y), Vector2(w, y + 8.0 * unit), Color(INK, 0.4), 4.0 * unit)
			y += 16.0 * unit


func _flash(node: CanvasItem) -> void:
	var t := create_tween()
	node.modulate = Color(1.8, 1.4, 0.6)
	t.tween_property(node, "modulate", Color.WHITE, 1.0)


# ---------------------------------------------------------------- command line

## `--autotest`, `--at=X`, `--skip=N` (N tasks done), `--declared=N`, `--show-hits`,
## `--screenshot=path.png`.
func _maybe_run_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		_autotest()
		return
	for a in args:
		if a.begins_with("--skip="):
			var n := a.trim_prefix("--skip=").to_int()
			maat_ok = n >= 1
			if n >= 2:
				heart_placed = true
				held = ""
			if n >= 3:
				for j in judges:
					declared[j] = true
			verdict = n >= 4
		elif a.begins_with("--declared="):
			for i in a.trim_prefix("--declared=").to_int():
				declared[judges[i]] = true
		elif a.begins_with("--at="):
			avatar.position.x = a.trim_prefix("--at=").to_float()
		elif a == "--show-hits":
			_show_hits = true
	_render()
	_update_camera(1.0)
	for a in args:
		if a.begins_with("--screenshot="):
			hud.dismiss_intro()
			for i in 90:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(a.trim_prefix("--screenshot="))
			get_tree().quit()


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
	var missed: Array[String] = []
	for n in _active_pieces():
		if _pick(_piece_rect(n).get_center()).get("id", "") != n:
			missed.append(n)
	expect.call(judges.size() == 42, "42 judges in the frieze")
	expect.call(missed.is_empty(), "every piece answers a click at its centre %s" % [missed])
	expect.call(min_x() > rects.maat.position.x, "Ma'at bars the door at the start")
	place_heart()
	expect.call(not heart_placed, "no weighing before Ma'at lets you in")
	speak_to_maat()
	declare(judges[0])
	expect.call(declared.is_empty(), "the judges wait for the heart to be on the balance")
	place_heart()
	expect.call(heart_placed and held == "", "heart on the balance")
	await get_tree().create_timer(1.0).timeout
	expect.call(_tilt > 0.05, "the heart's pan sinks")
	ask_thoth()
	expect.call(not verdict, "Thoth will not write while the heart sinks")
	for j in judges:
		declare(j)
	declare(judges[3])
	expect.call(declared.size() == 42 and _level_now(), "all 42 judges answered: the beam is level")
	await get_tree().create_timer(1.5).timeout
	expect.call(absf(_tilt) < 0.01, "the beam comes level")
	record(_spot("Osiris"))
	expect.call(not finished, "Osiris waits for the verdict")
	ask_thoth()
	await get_tree().create_timer(1.3).timeout
	expect.call(verdict and min_x() < rects.thoth.position.x, "the verdict is written and the way opens")
	record(_spot("Osiris"))
	expect.call(finished, "received by Osiris")
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
