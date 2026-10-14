## Spells 31-42: dangers on the road (Lepsius, Todtenbuch pl. XVI-XIX).
##
## The scroll reads right to left. The player (the adoring deceased of spell 30) walks left
## through the vignettes. Each vignette with a creature is an encounter: walking into it
## turns the player into that vignette's spear-bearer, and the way on stays shut until the
## creature is overcome. Solving an encounter puts the vignette back as it is drawn on the plate.
## Positions come from assets/dangers/level.json, written by tools/cut_dangers300.py from the
## hand-made 300-dpi strip bod31-42.mdp. Distances below are in 200-dpi plate pixels and are
## multiplied by `unit` (level.json `scale`).
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const VIEW_TOP := 36.0   ## the row under the top register's upper rule: the title bar's band takes its place
const DATA_PATH := "res://assets/dangers/level.json"
const SHEET_PATH := "res://assets/dangers/spearers.json"   ## the spear-bearers' thrust (tools/spearer_sheet.py)
const CREEPING_SNAKE_STATE := preload("res://scripts/creeping_snake_state.gd")
const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const SHEET_TEX := "res://assets/dangers/spearers.png"
const ASSET := "res://assets/dangers/%s.png"
const BESIDE := 50.0
const FIGHTS := ["crocs", "lunge", "twin", "creep", "roach", "apep", "donkey", "sheaf"]
const ARENA_FIGHTS := ["crocs", "roach", "lunge", "creep", "twin", "apep", "sheaf"]   ## the vignette opens out across the screen
const CLICK_TO_FIGHT := "Click the creature to take up the spear."

const ENCOUNTERS := preload("res://scripts/danger_encounters.gd").ENCOUNTERS

const TASKS := [
	"Turn back the crocodiles (31–32)",
	"Spear the snakes and the beetle (33–37)",
	"Take the breath of life (38)",
	"Overcome Apep (39)",
	"Save the donkey from the snake (40)",
	"Bind the snake in the sheaf (41)",
	"Reach spell 42",
]

var level: Dictionary
var unit := 1.0          ## strip px per plate px at 200 dpi (level.json `scale`)
var ground := 248.0      ## the line the figures stand on (level.json `ground`)
var rects := {}          ## sprite name -> Rect2 as drawn on the plate
var sheet: Dictionary    ## spearers.json: cell size, poses, and per bearer its row, place in the cell, tip and dir
var _sheet_tex: Texture2D
var _filled := {}        ## bearer -> his poses filled with papyrus (spell 33), made once
var actors := {}         ## sprite name -> Node2D pivot at the sprite's bottom centre
var boxes := {}          ## encounter id -> Vector2(x0, x1)

var solved := {}         ## encounter id -> true
var seen := {}           ## encounter id -> intro already said
var items: Array[String] = []
var bites := 0
var finished := false
var journal: Array[String] = []
var current := {}        ## the first unsolved encounter (the next task; the way is never shut)
var fight := {}          ## state of the running fight, empty when walking
var rng := RandomNumberGenerator.new()

var _time := 0.0
var _roach_need := -1     ## dev: overrides the number of beetles when set (ROACH_NEED)
var _instant := false     ## the autotest skips the crocodile vignette's opening and closing
var _arena: Node2D        ## the opened-out crocodile vignette, between the strip and the actors
var _arena_cover: ColorRect
var _arena_lines: Node2D
var _text_cover: ColorRect     ## papyrus over the text below while it drops away
var _caption_covers: Array[ColorRect] = []   ## papyrus over the other vignettes' captions
var _text_drop: Sprite2D       ## the text below, widening and dropping away
var heka_known := false        ## the player has clicked a flashing heka sign
const FLESH_PATH := "res://assets/dangers/flesh.png"   ## the flesh sign that counts his health (supplied, not cut)
var _flesh_tex: Texture2D = _ink_from(load(FLESH_PATH)) if ResourceLoader.exists(FLESH_PATH) else null
var _told_unsolved := -10.0   ## when the end of the scroll last said what is still undone
var gate := {}           ## a "gate" encounter (spell 38): the way on past it stays shut while it or one before it is undone
var _bump_time := -10.0
var _heka_signs: Array = []      ## flattened once from level.heka
var _hover := []                ## the actors glowing under the pointer

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	var heka = level.get("heka", {})
	if heka is Dictionary:
		for words in heka.values():
			_heka_signs.append_array(words)
	unit = level.get("scale", 1.0)
	ground = level.ground
	avatar.speed *= unit
	avatar.bob_height *= unit
	for n in level.sprites:
		var s: Dictionary = level.sprites[n]
		rects[n] = Rect2(s.x, s.y, s.w, s.h)
	for b in level.boxes:
		boxes[b] = Vector2(level.boxes[b][0], level.boxes[b][1])
	for n in rects:
		if n == "avatar":
			continue
		actors[n] = _make_actor(load(ASSET % n), rects[n])
	# the spear-bearers come from one sprite sheet: the man as drawn with his spear in a pose, and over
	# him the spear alone in the same pose, shown only when it is tinted red for heka
	sheet = JSON.parse_string(FileAccess.get_file_as_string(SHEET_PATH))
	_sheet_tex = load(SHEET_TEX)
	if absf(float(sheet.reach) - CROC_THRUST * unit) > 0.5 or absf(float(sheet.back) - CROC_PREP * unit) > 0.5:
		push_warning("spearers.json reach/back do not match CROC_THRUST/CROC_PREP")
	for nm in sheet.bearers:
		var pole: String = nm + "_pole"
		if not actors.has(pole):
			actors[pole] = _make_actor(_sheet_tex, rects[nm])
		$Actors.move_child(actors[pole], actors[nm].get_index() + 1)
		for a in [actors[nm], actors[pole]]:
			var sp: Sprite2D = a.get_node("Sprite")
			var at := AtlasTexture.new()
			at.atlas = _sheet_tex
			sp.texture = at
			sp.position = -Vector2(rects[nm].size.x / 2.0 + float(sheet.bearers[nm].ox), rects[nm].size.y + float(sheet.bearers[nm].oy))
		_bearer_pose(nm, 0.0)
	overlay.draw.connect(_draw_overlay)
	_arena = Node2D.new()
	add_child(_arena)
	move_child(_arena, $Actors.get_index())
	_arena_cover = ColorRect.new()
	_arena_cover.material = $Papyrus.material
	_arena_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_arena_cover)
	for i in 2:
		var cc := ColorRect.new()
		cc.material = $Papyrus.material
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_arena.add_child(cc)
		_caption_covers.append(cc)
	_text_cover = ColorRect.new()
	_text_cover.material = $Papyrus.material
	_text_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_text_cover)
	_text_drop = Sprite2D.new()
	_text_drop.texture = AtlasTexture.new()
	(_text_drop.texture as AtlasTexture).atlas = $Strip.texture
	_arena.add_child(_text_drop)
	_arena_lines = Node2D.new()
	_arena.add_child(_arena_lines)
	_arena_lines.draw.connect(_draw_arena_lines)
	avatar.bumped.connect(_on_bumped)
	_arena.visible = false
	hud.setup(self, {
		"title": "Dangers on the Road",
		"subtitle": "Spells 31–42 · Lepsius, Todtenbuch, pl. XVI–XIX",
		"rites_heading": "SPELLS OF PROTECTION",
		"tasks": TASKS,
		"journal_hint": "Each creature you overcome is recorded here.",
		"intro_title": "Spells 31–42: Dangers on the Road",
		"intro_body": "Between the tomb and the hall of judgment the road is full of creatures: crocodiles that steal magic, snakes, a beetle, the serpent Apep, a snake that eats the donkey.\n\n"
			+ "The scroll reads [b]right to left[/b]. Click the papyrus to walk, or use [←] [→]. Click a creature to walk into its vignette and become its spear-bearer; the scribe tells you that creature's rule. Some vignettes open out across the whole scroll: there [space] thrusts the spear (hold [shift] for heka) and the arrow keys move or turn you. Elsewhere, click the creature to strike.\n\n"
			+ "[i]Every figure is cut directly from Lepsius's 1842 plates; nothing is redrawn.[/i]",
		"outro_title": "The road is clear",
		"bottom": 228.0,
		"task_size": 15,
	})
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.minimap_clicked.connect(func(x):
		if fight.is_empty():
			walk_then(x))
	reset()
	_maybe_run_cli()


func _make_actor(tex: Texture2D, r: Rect2) -> Node2D:
	var pivot := Node2D.new()
	pivot.position = Vector2(r.get_center().x, r.end.y)
	pivot.set_meta("home", pivot.position)
	pivot.set_meta("size", r.size)
	var s := Sprite2D.new()
	s.name = "Sprite"
	s.texture = tex
	s.centered = false
	s.position = Vector2(-r.size.x / 2.0, -r.size.y)
	pivot.add_child(s)
	$Actors.add_child(pivot)
	return pivot


func reset() -> void:
	if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
		_crocs_cleanup()
	heka_known = false
	solved.clear()
	seen.clear()
	items.clear()
	journal.clear()
	bites = 0
	finished = false
	fight = {}
	rng.seed = 30
	for n in actors:
		_restore(n)
		actors[n].visible = not n.begins_with("spear") and not n.begins_with("sheaf41_")   # the sheaf's pieces show only in its fight
	avatar.visible = true
	avatar.set_process(true)
	avatar.stop()
	avatar.position = Vector2(rects.avatar.get_center().x, ground)
	avatar.facing = -1
	hud.reset_view()
	say("Scribe", "The road to the hall of judgment begins here. Walk left, toward the crocodiles.")
	_refresh()
	_update_camera(1.0)


# ---------------------------------------------------------------- walking and gates

func _refresh() -> void:
	current = {}
	for e in ENCOUNTERS:
		if e.kind in ["note", "end"]:
			continue
		if not solved.has(e.id):
			current = e
			break
	# he walks through every vignette (a fight starts only on clicking its creature) and into a gate
	# vignette, but not on past it while it or one before it is still undone. The barrier is not drawn.
	gate = {}
	# TEMP (testing Apep): the gate at spell 38 is off, so the way on is always open
	#for e in ENCOUNTERS:
	#	if e.get("gate", false) and not current.is_empty() and ENCOUNTERS.find(current) <= ENCOUNTERS.find(e):
	#		gate = e
	#		break
	avatar.min_x = gate_x() + 20.0 * unit if not gate.is_empty() else 40.0 * unit
	avatar.max_x = level.width - 40.0 * unit
	var done := []
	for t in TASKS.size() - 1:
		var all := true
		for e in ENCOUNTERS:
			if e.get("task", -1) == t and not solved.has(e.id):
				all = false
		done.append(all)
	done.append(finished)
	hud.update_tasks(done)
	_update_hand()


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


## The unsolved "take" encounter whose item is at `p`, or {}.
func _take_at(p: Vector2) -> Dictionary:
	for e in ENCOUNTERS:
		if e.kind == "take" and not solved.has(e.id) and actor_rect(e.item).grow(12 * unit).has_point(p):
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
	say("Scribe", "The way on opens only once every danger up to the breath of life is overcome. Still to do: spell %s." % current.id.trim_prefix("e"))


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or finished:
		return
	if event.is_action_pressed("ui_cancel") and not fight.is_empty():   # Esc always steps out of a fight
		leave_fight()
		get_viewport().set_input_as_handled()
		return
	# Space thrusts in the fights that open out (holding Shift lends the thrust heka)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if not fight.is_empty() and fight.kind == "sheaf":
			_sheaf_act()                # ties the next band, or (once it is out) thrusts
		elif not fight.is_empty() and fight.kind in ARENA_FIGHTS:
			_croc_thrust()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		_set_hover(_hover_at(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if _heka_at(p) != "":
			heka_known = true
			say("Scribe", HEKA_TEXT)
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
		var t := _take_at(p)
		if not t.is_empty():
			var r := actor_rect(t.item)
			walk_then(r.end.x + BESIDE * unit, take.bind(t))
			return
		walk_then(p.x)


## What glows under the pointer (hit-tested by box): a target in a fight, or, walking, a creature
## (all of its encounter's) or an item to take.
func _hover_at(p: Vector2) -> Array:
	if not fight.is_empty():
		var h := _heka_at(p)          # in a fight the heka signs glow too (on the scroll they only flash)
		if h != "":
			return [h]
		for n in _targets():
			if actor_rect(n).grow(8 * unit).has_point(p):
				return [n]
		return []
	var f := _fight_at(p)
	if not f.is_empty():
		return _creatures(f)
	var t := _take_at(p)
	return [t.item] if not t.is_empty() else []


func _set_hover(names: Array) -> void:
	if names == _hover:
		return
	for n in _hover:
		_glow(n, false)
	_hover = names
	for n in _hover:
		_glow(n, true)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not names.is_empty() else Input.CURSOR_ARROW)


## A soft glow behind actor `n`'s drawing (made the first time it is wanted).
func _glow(n: String, on: bool) -> void:
	var sp := actors[n].get_node("Sprite") as Sprite2D
	var g := sp.get_node_or_null("Glow") as Sprite2D
	if g == null:
		if not on:
			return
		g = Sprite2D.new()
		g.name = "Glow"
		g.texture = sp.texture
		g.centered = false
		g.show_behind_parent = true
		var mat := ShaderMaterial.new()
		mat.shader = GLOW
		var tex := sp.texture
		if tex is AtlasTexture:
			var whole := Vector2((tex as AtlasTexture).atlas.get_size())
			var reg := (tex as AtlasTexture).region
			mat.set_shader_parameter("region", Vector4(reg.position.x / whole.x, reg.position.y / whole.y, reg.size.x / whole.x, reg.size.y / whole.y))
		mat.set_shader_parameter("strength", 0.0)
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


## The creatures you click to take up the spear against encounter `e`.
func _creatures(e: Dictionary) -> Array:
	return e.foes if e.has("foes") else [e.foe]


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
		"crocs", "roach", "lunge", "creep", "twin", "apep": return []
		"donkey": return [fight.foe, fight.donkey]
		"sheaf": return [SHEAF_STALKS] if fight.get("phase", "") == "bind" else []
	return [fight.foe]


func _process(delta: float) -> void:
	_time += delta
	if not finished and fight.is_empty():
		_check_position()
	if not fight.is_empty():
		_update_fight(delta)
	_update_camera(delta)
	hud.update_minimap(avatar.position.x, _visible_rect(), gate_x(), false)   # the barrier is not shown
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
	var ar := _arena_rect()
	if ar.has_area():
		_arena_cover.position = ar.position
		_arena_cover.size = ar.size
		_arena_lines.queue_redraw()


## Say each vignette's line once on arrival (a fight waits for a click on the creature), and end the level at spell
## 42 once everything before it is done.
func _check_position() -> void:
	var x := avatar.position.x
	for e in ENCOUNTERS:
		var s := span(e)
		if x < s.y - 20.0 * unit and x > s.x and not seen.has(e.id):
			seen[e.id] = true
			if not solved.has(e.id):
				say("Scribe", e.intro + (" " + CLICK_TO_FIGHT if e.kind in FIGHTS else ""))
	if x < span(ENCOUNTERS[-1]).y - 40.0 * unit:
		if current.is_empty():
			finish()
		elif _time - _told_unsolved > 6.0:
			_told_unsolved = _time
			say("Scribe", "Spell 42 waits until every danger behind you is overcome. Still to do: spell %s." % current.id.trim_prefix("e"))


func take(e: Dictionary) -> void:
	var a: Node2D = actors[e.item]
	var t := create_tween()
	t.tween_property(a, "position:y", a.position.y - 30.0 * unit, 0.35)
	t.parallel().tween_property(a, "modulate:a", 0.0, 0.35)
	t.tween_callback(func():
		a.visible = false
		a.modulate.a = 1.0)
	items.append(e.item)
	_solve(e)


func _solve(e: Dictionary) -> void:
	solved[e.id] = true
	say("Scribe", e.won)
	var pic: String = e.foes[0] if e.kind == "crocs" else e.get("foe", e.get("item", ""))
	var tex: Texture2D = load(ASSET % pic)
	journal.append(e.label)
	hud.add_journal_entry(e.label, e.note, tex, journal.size(), ENCOUNTERS.filter(func(x): return x.has("label")).size())
	_refresh()


func finish() -> void:
	if finished:
		return
	finished = true
	_refresh()
	say("Scribe", ENCOUNTERS[-1].intro + " That scene comes later, once the gods' figures are cut.")
	var body := "The crocodiles are turned back, the snakes and the beetle are speared, Apep is pinned and the donkey is saved.\n\n" \
		+ "You carry [b]the breath of life[/b].\n\n" \
		+ "Next: [b]spell 42[/b], each part of the body given to a god, and then the food, water and breath spells of Act III.\n\n" \
		+ "[i]Bites taken on the way: %d.[/i]" % bites
	get_tree().create_timer(1.2).timeout.connect(func(): hud.show_outro(body))


func hint() -> void:
	if finished:
		return
	if current.is_empty():
		say("Hint", "Walk left to the end of the scroll.")
	elif fight.is_empty() and not here().is_empty():
		say("Hint", CLICK_TO_FIGHT + " " + str(here().hint))
	elif fight.is_empty() and current.kind in FIGHTS:
		say("Hint", "Walk to spell %s and click the creature there. " % current.id.trim_prefix("e") + str(current.hint))
	else:
		say("Hint", current.hint)


func say(who: String, text: String) -> void:
	hud.say(who, text)


func _update_hand() -> void:
	if items.is_empty():
		hud.update_hand("", "", null)
		return
	var names := {"breath38": "the breath of life"}
	var label := " and ".join(items.map(func(i): return names[i]))
	hud.update_hand(items[-1], label, load(ASSET % items[-1]))
	hud.update_held("", null, 1.0)


# ---------------------------------------------------------------- fights

func start_fight(e: Dictionary) -> void:
	avatar.stop()
	avatar.visible = false
	avatar.set_process(false)
	actors[e.spear].visible = true
	_set_hover([])
	if not e.kind in ARENA_FIGHTS:
		_bearer_pose(e.spear, -CROC_PREP)      # in a fight the spear rests drawn back
	fight = {"kind": e.kind, "e": e, "t": 0.0, "hits": 0}
	match e.kind:
		"crocs":
			_crocs_start(e)
		"twin":
			_twin_start(e)
		"roach":
			_roach_start(e)
		"lunge":
			_lunge_start(e)
		"creep":
			_creep_start(e)
		"apep":
			_apep_start(e)
		"donkey":
			fight.foe = e.foe
			fight.donkey = e.donkey
			fight.speed = 1.4
		"sheaf":
			_sheaf_start(e)
	say("Scribe", e.intro)


func end_fight() -> void:
	if fight.kind in ARENA_FIGHTS:
		if not _instant and not fight.get("closing", false):
			_crocs_close()
			return
		_crocs_cleanup()
	var e: Dictionary = fight.e
	var spear: Rect2 = rects[e.spear]
	fight = {}
	for n in _box_actors(e):
		_restore(n)
		_flash(actors[n])
	avatar.position.x = spear.get_center().x
	avatar.visible = true
	avatar.set_process(true)
	_solve(e)


## Esc: step back out of the fight, not won. The vignette closes (as when a fight is lost), the
## creature and the bearer stand as drawn, and clicking the creature takes it up again.
func leave_fight() -> void:
	if fight.is_empty() or fight.get("closing", false):
		return
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
		say("Scribe", "You step back out of the vignette. Click the creature to take it up again.")
	if fight.kind in ARENA_FIGHTS and not _instant:
		_crocs_close(out)
	else:
		out.call()


func _box_actors(e: Dictionary) -> Array:
	var s := span(e)
	return actors.keys().filter(func(n): return actors[n].get_meta("home").x > s.x and actors[n].get_meta("home").x < s.y)


func _restore(n: String) -> void:
	var a: Node2D = actors[n]
	a.position = a.get_meta("home")
	a.rotation = 0.0
	a.scale = Vector2.ONE
	a.modulate = Color.WHITE
	(a.get_node("Sprite") as Sprite2D).flip_h = false
	if sheet.bearers.has(n.trim_suffix("_pole")):
		_bearer_pose(n.trim_suffix("_pole"), 0.0)


func _update_fight(dt: float) -> void:
	fight.t += dt
	match fight.kind:
		"crocs": _crocs(dt)
		"twin": _twin(dt)
		"creep": _creep(dt)
		"roach": _roach(dt)
		"lunge": _lunge(dt)
		"apep": _apep(dt)
		"donkey": _donkey(dt)
		"sheaf": _sheaf(dt)


func fight_click(p: Vector2) -> void:
	if not fight.kind in ARENA_FIGHTS:
		_thrust()
	match fight.kind:
		"crocs": _crocs_click(p)
		"twin": _twin_click(p)
		"creep": _creep_click(p)
		"roach": _roach_click(p)
		"lunge": _lunge_click(p)
		"apep": _apep_click(p)
		"donkey": _donkey_click(p)
		"sheaf": _sheaf_click(p)


## End the fight after a short beat, unless it already ended (the autotest ends it at once).
func _won_if(done: bool) -> void:
	if not done:
		return
	var id: String = fight.e.id
	get_tree().create_timer(0.5).timeout.connect(func():
		if not fight.is_empty() and fight.e.id == id:
			end_fight())


# crocodiles. The vignette opens out across the whole screen (the caption banner stays; the text
# below drops away). The spear-bearer moves with the arrow keys (or WASD) and thrusts with Space.
# Crocodiles crawl in at different heights, each a copy of one of the four drawn ones. A thrust
# only spears a snout at the spear tip; a crocodile that reaches the bearer, or gets past him,
# bites (his body flushes red). Some come red: those are turned back only by a thrust made while
# holding Shift (heka; the spear turns red). A plain thrust does nothing to a red one, and heka spent
# on an ordinary one loses the fight: it seizes the word of heka from the banner and makes off.
# In spell 31 they come from the left: the double line behind him stays where it is drawn, the
# vignette opens out to the left only, and he moves only up and down. In spell 32 (`both_sides`)
# they come from both sides, he stands in the middle and ← → turn him.
const CROC_OPEN := 0.8          ## seconds for the vignette to open out / close again
const CROC_PREP := 14.0 / 1.5   ## in a fight the spear rests drawn back (up its line) this far (spearers.json back)
const CROC_THRUST := 10.0       ## and then runs it out this far past where it is drawn (spearers.json reach)
const CROC_REACH := 20.0        ## the point also counts this close to the snout (plate px)
const CROC_SAME_SPOT := 1.0     ## two from one side at nearly one height reach him at least this far apart (s)
const CROC_FRONT_OVERLAP := 0.15   ## how far (of their height) two front halves may overlap above and below
const CROC_GRACE := 5.0         ## the spear point counts this close outside a crocodile's outline (plate px)
const CROC_LANE := 70.0         ## spacing of the heights the crocodiles come at
const BEARER_SPEED := 260.0     ## how fast the bearer moves
const CROC_HEALTH := 3           ## bites he can take; the last one and he crumbles (the fight starts over)
const CROC_FORWARD := 30.0      ## in one-sided fights he stands this far in front of where he is drawn
const THRUST_TIME := [0.07, 0.18]   ## from drawn back to the full strike, and back to drawn back
const THRUST_DOWN := 0.5        ## (Apep, the Merti snakes) the point strikes once this far into the full thrust
## Red is #B55B3C. The sprites are drawn in ink (46, 29, 16), so the modulate that turns ink into
## that red is the ratio of the two.
const RED_CROC := Color(181.0 / 46.0, 91.0 / 29.0, 60.0 / 16.0)   ## red crocodiles, heka word and spear
const HURT := RED_CROC                      ## the bearer's body when bitten
const DISSOLVE := preload("res://scripts/dissolve.gdshader")
const GLOW := preload("res://scripts/glow.gdshader")
const TEXT_DROP := 320.0        ## how far the text below drops while the vignette is open
const HEKA_TEXT := "Hold [shift] while striking to fight off the red crocodiles. Don't use heka on the regular crocodiles, or they'll make off with it!"


## The opened-out vignette both kinds of arena fight use (crocodiles, roach): the picture band
## widens across the whole screen and down past the text, which drops away; only this vignette's
## caption stays; everything else steps out of the way. `both`: he stands in the middle and can
## turn (else the double line behind him stays where it is drawn). `keep`: actors that stay.
## `view`: for a close fight, the rows to show (top, bottom) and the x to centre on; empty = the
## whole height of the scroll.
func _arena_setup(e: Dictionary, both: bool, keep: Array, view := {}) -> void:
	var s := span(e)
	var rules: Array = level.rules
	var band_top: float = rules[0][1]
	var vp := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var shown: float = view.y1 - view.y0 if not view.is_empty() else level.height
	var z: float = (vp.y - top - bottom - 10.0) / shown           # the whole height of the scroll, or `view`
	if view.has("z"):        # no closer than this, so the fight keeps its width
		z = minf(z, view.z)
	var vis_w: float = vp.x / z
	var cx := (s.x + s.y) / 2.0
	fight.panel = Rect2(s.x, band_top, s.y - s.x, ground - band_top)
	fight.both = both
	if not view.is_empty():
		fight.full = Rect2(view.x - vis_w / 2.0, band_top, vis_w, level.height - 24.0 * unit - band_top)
	elif both:
		fight.full = Rect2(cx - vis_w / 2.0, band_top, vis_w, level.height - 24.0 * unit - band_top)
	else:   # the double line on the right stays as drawn (s.y is its inner edge); it opens to the left
		var right: float = s.y + 20.0
		fight.full = Rect2(right - vis_w, band_top, vis_w, level.height - 24.0 * unit - band_top)
	var mid: float = (view.y0 + view.y1) / 2.0 if not view.is_empty() else level.height / 2.0
	fight.cam = {"z": z, "x": fight.full.get_center().x, "y": mid + (bottom - top) / 2.0 / z}
	fight.open = 0.0
	fight.thrust = -1.0
	fight.struck = false
	fight.red = 0.0
	fight.nag = -10.0
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
	fight.stand = Vector2(full.get_center().x if both else home.x - CROC_FORWARD * unit, ground)
	fight.x_range = Vector2(fight.stand.x, fight.stand.x)
	fight.pos = fight.stand                                       # bearer pivot, open
	fight.y_range = Vector2(band_top + size.y + 4.0 * unit, full.end.y - 26.0 * unit)
	var sp: Dictionary = sheet.bearers[e.spear]
	fight.tip = Vector2(sp.tip[0], sp.tip[1]) - home              # tip from the bearer's pivot, as drawn
	fight.dir = Vector2(sp.dir[0], sp.dir[1])
	# everything else on screen steps out of the way
	fight.hidden = []
	for nm in actors:
		if actors[nm].visible and not nm in keep and nm != e.spear and nm != e.spear + "_pole" and not nm in _heka_words(e.id):
			fight.hidden.append(nm)
	# the text below the frame widens and drops away to make room
	var text_top: float = rules[-1][1]
	var x0 := maxf(0.0, full.position.x)
	var x1 := minf(level.width, full.end.x)
	(_text_drop.texture as AtlasTexture).region = Rect2(x0, text_top, x1 - x0, level.height - text_top)
	fight.text_home = Vector2((x0 + x1) / 2.0, (text_top + level.height) / 2.0)
	# only this vignette's caption stays: the others on screen are covered (its own double lines stay)
	var cap: Array = level.get("caption", [rules[0][0] - 130.0, rules[0][0]])
	_caption_covers[0].position = Vector2(full.position.x - 100.0, cap[0])
	_caption_covers[0].size = Vector2(maxf(0.0, s.x - 20.0 - (full.position.x - 100.0)), cap[1] - cap[0])
	_caption_covers[1].position = Vector2(s.y + 20.0, cap[0])
	_caption_covers[1].size = Vector2(maxf(0.0, full.end.x + 100.0 - (s.y + 20.0)), cap[1] - cap[0])
	_text_cover.position = Vector2(full.position.x - 100.0, text_top)
	_text_cover.size = Vector2(full.size.x + 200.0, level.height - text_top + 100.0)
	_arena.visible = true
	actors[e.spear + "_pole"].visible = true


func _arena_open() -> void:
	if _instant:
		_croc_open(1.0)
	else:
		create_tween().tween_method(_croc_open, 0.0, 1.0, CROC_OPEN)


func _crocs_start(e: Dictionary) -> void:
	_arena_setup(e, e.get("both_sides", false), e.foes)
	var full: Rect2 = fight.full
	fight.copies = []
	fight.timer = 1.2
	# waves: the lesson, a break, then the red ones (or a single wave from `count`, `speed`, ...)
	if e.has("waves"):
		fight.waves = e.waves
	else:
		fight.waves = [{"count": e.count, "speed": e.speed, "interval": e.interval, "at_once": e.at_once, "red": e.get("red", 0.0)}]
	fight.wave = 0                  # a lost fight always starts again from the first wave
	fight.wave_killed = 0
	fight.wave_launched = 0
	fight.phase = ""
	fight.killed = 0
	for i in fight.wave:
		fight.killed += int(fight.waves[i].count)
	var w0: Dictionary = fight.waves[fight.wave]
	# the heka word flashes once red crocodiles can come (from the start, or after the first break)
	fight.heka_on = fight.wave > 0 or w0.get("red", 0.0) > 0.0 or true in w0.get("red_order", [])
	fight.nudged = false
	fight.health = CROC_HEALTH
	fight.clock = 0.0
	fight.last_arrival = -INF
	fight.moved = 0.0
	fight.told_back = false
	fight.tut = "thrust" if e.get("tutorial", false) and fight.wave == 0 else ""
	# the heights the snouts can come at: wherever the spear tip can reach
	var lo: float = fight.y_range.x + fight.tip.y
	var hi: float = fight.y_range.y + fight.tip.y
	var tallest := 0.0         # ...and low enough lanes still keep the crocodile inside the frame
	for f in e.foes:
		tallest = maxf(tallest, actors[f].get_meta("size").y)
	hi = minf(hi, full.end.y - 26.0 * unit - tallest * 0.78)
	fight.lanes = []
	var n := maxi(3, int((hi - lo) / (CROC_LANE * unit)) + 1)
	for i in n:
		fight.lanes.append(lerpf(lo, hi, float(i) / (n - 1)))
	# the four drawn crocodiles wait spread out on the left, at different heights
	fight.crocs = []
	var lanes: Array = fight.lanes.duplicate()
	lanes.shuffle()
	for i in e.foes.size():
		var a: Node2D = actors[e.foes[i]]
		var start := Vector2(full.position.x + (0.12 + 0.13 * i) * (fight.stand.x - full.position.x), 0.0)
		start.y = float(lanes[i % lanes.size()]) - _croc_head(a, 1).y
		fight.crocs.append({"node": a, "s": "wait", "home": a.get_meta("home"), "start": start, "speed": 0.0, "dir": 1, "red": false})
	_arena_open()


## Where a crocodile's snout is, from its pivot (bottom centre); dir 1 = it faces right, -1 = left.
func _croc_head(a: Node2D, dir: int) -> Vector2:
	var size: Vector2 = a.get_meta("size")
	return Vector2(size.x * 0.46 * dir, -size.y * 0.78)


var _solids := {}        ## crocodile texture -> its outline filled in (Image, alpha = solid)


## Does the point `p` lie on crocodile `c`: inside its drawn outline (filled), or within CROC_GRACE?
func _on_croc(c: Dictionary, p: Vector2) -> bool:
	var sp: Sprite2D = c.node.get_node("Sprite")
	var solid := _solid_of(sp.texture)
	var q := sp.to_local(p)
	var w := solid.get_width()
	var h := solid.get_height()
	var g := CROC_GRACE * unit
	for o in [Vector2.ZERO, Vector2(g, 0), Vector2(-g, 0), Vector2(0, g), Vector2(0, -g)]:
		var x := int(q.x + o.x)
		var y := int(q.y + o.y)
		if sp.flip_h:
			x = w - 1 - x
		if x >= 0 and y >= 0 and x < w and y < h and solid.get_pixel(x, y).a > 0.5:
			return true
	return false


## A crocodile's silhouette: its ink, with everything the outline encloses filled in.
func _solid_of(tex: Texture2D) -> Image:
	if _solids.has(tex):
		return _solids[tex]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var ink := PackedByteArray()
	ink.resize(w * h)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.3:
				# a little thicker, so small gaps in the outline do not let the fill leak out
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var xx := x + dx
						var yy := y + dy
						if xx >= 0 and yy >= 0 and xx < w and yy < h:
							ink[yy * w + xx] = 1
	# flood the outside from the edges; whatever it cannot reach is the crocodile
	var outside := PackedByteArray()
	outside.resize(w * h)
	var todo: Array[int] = []
	for x in w:
		todo.append(x)
		todo.append((h - 1) * w + x)
	for y in h:
		todo.append(y * w)
		todo.append(y * w + w - 1)
	while not todo.is_empty():
		var i: int = todo.pop_back()
		if outside[i] == 1 or ink[i] == 1:
			continue
		outside[i] = 1
		var x := i % w
		var y := i / w
		if x > 0: todo.append(i - 1)
		if x < w - 1: todo.append(i + 1)
		if y > 0: todo.append(i - w)
		if y < h - 1: todo.append(i + w)
	var solid := Image.create(w, h, false, Image.FORMAT_LA8)
	for i in w * h:
		if outside[i] == 0:
			solid.set_pixel(i % w, i / w, Color(1, 1, 1, 1))
	_solids[tex] = solid
	return solid


func _snout(c: Dictionary) -> Vector2:
	return c.node.position + _croc_head(c.node, c.dir)


## The spear tip and direction for the way the bearer faces (drawn facing left).
func _tip_offset() -> Vector2:
	return Vector2(fight.tip.x * -fight.facing, fight.tip.y)


func _spear_dir() -> Vector2:
	return Vector2(fight.dir.x * -fight.facing, fight.dir.y)


func _holding_heka() -> bool:
	return Input.is_key_pressed(KEY_SHIFT) or fight.get("force_heka", false)


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
			_roach_place(r0, r0.home_c.lerp(r0.c0, k))
		if fight.get("closing", false) and r0.gone:
			r0.node.modulate = Color(1, 1, 1, 1.0 - k)
		for a in fight.copies:                # the others (and a swarm) fade in and out
			if is_instance_valid(a):
				a.modulate.a = k * float(a.get_meta("alpha", 1.0))
	if fight.kind == "lunge":         # it draws back from where it is drawn to where it waits
		_lunge_place()
	if fight.kind == "creep":         # it slides off ahead of him
		_creep_place()
	if fight.kind == "twin":          # they turn to face him; the copy on his right fades in
		_twin_place()
	if fight.kind == "apep":
		_apep_place()
	if fight.kind == "sheaf":
		_sheaf_place()
	for nm in fight.hidden:
		actors[nm].modulate.a = 1.0 - k
	_text_drop.position = fight.text_home + Vector2(0.0, TEXT_DROP * unit * k * k)
	_text_drop.scale = Vector2(1.0 + 0.3 * k, 1.0)
	_text_drop.modulate.a = 1.0 - k
	for cc in _caption_covers:
		cc.modulate.a = k
	_place_bearer()


func _place_bearer() -> void:
	var e: Dictionary = fight.e
	for nm in [e.spear, e.spear + "_pole"]:
		var a: Node2D = actors[nm]
		a.position = a.get_meta("home").lerp(fight.pos, fight.open)
		(a.get_node("Sprite") as Sprite2D).flip_h = fight.facing > 0
	# the spear rests drawn back; a thrust runs it out past where it is drawn and draws it back again
	_bearer_pose(e.spear, _spear_out())
	# bitten: the body flushes red; heka: the spear is red (each on its own)
	actors[e.spear].modulate = Color.WHITE.lerp(HURT, clampf(fight.red / 0.8, 0.0, 1.0))
	var heka: bool = Input.is_key_pressed(KEY_SHIFT) and fight.open >= 1.0
	actors[e.spear + "_pole"].modulate = RED_CROC if heka else Color.WHITE
	actors[e.spear + "_pole"].get_node("Sprite").visible = heka


func _crocs(dt: float) -> void:
	var e: Dictionary = fight.e
	if fight.open < 1.0 or fight.lost:
		return
	fight.clock += dt
	# move (or, with crocodiles on both sides, turn) the bearer
	var mv := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	mv.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if not fight.both:
		mv.x = 0.0
	mv.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	if fight.get("bot", false):
		mv = _bot_move()
	if fight.both and mv.x != 0.0:
		fight.facing = 1 if mv.x > 0.0 else -1
		mv.x = 0.0
	if mv != Vector2.ZERO:
		var p: Vector2 = fight.pos + mv.limit_length(1.0) * BEARER_SPEED * unit * dt
		p.x = clampf(p.x, fight.x_range.x, fight.x_range.y)
		p.y = clampf(p.y, fight.y_range.x, fight.y_range.y)
		fight.moved += (p - fight.pos).length()
		fight.pos = p
	if fight.thrust >= 0.0:
		fight.thrust += dt
		if not fight.struck and fight.thrust >= THRUST_TIME[0]:
			fight.struck = true
			_croc_strike()
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
	fight.red = maxf(0.0, fight.red - dt)
	_place_bearer()
	if fight.lost:
		return
	# the lesson: thrust, move, then one slow crocodile
	match fight.tut:
		"move":
			if fight.moved > 60.0 * unit:
				fight.tut = "first"
				say("Scribe", "Here one comes. Meet its snout with the spear tip, and press [space] as they touch.")
				_croc_launch(e.first_speed)
		"":
			fight.timer -= dt
			var w: Dictionary = fight.waves[fight.wave]
			if fight.phase == "break":
				if fight.timer <= 0.0:
					_croc_next_wave()
			else:
				var crawling: int = fight.crocs.filter(func(c): return c.s == "crawl" or c.s == "back").size()
				if fight.timer <= 0.0 and crawling < w.at_once and fight.wave_launched < w.count:
					var ramped: float = w.speed * (1.0 + w.get("ramp", 0.0) * fight.wave_launched)
					fight.timer = w.interval if _croc_launch(ramped) else 0.15
	# crawl; a crocodile that reaches the bearer, or gets past him, bites
	var bearer := actor_rect(e.spear)
	for c in fight.crocs:
		if c.s != "crawl":
			continue
		var a: Node2D = c.node
		a.position.x += c.speed * unit * dt * c.dir
		a.rotation = sin(_time * 14.0 + a.position.y) * 0.012
		var head := _snout(c)
		var size: Vector2 = a.get_meta("size")
		var level_with := a.position.y > bearer.position.y + bearer.size.y * 0.35 and a.position.y - size.y < bearer.end.y
		var at_him := false
		var past := false
		# past: in spell 31 its snout reaches the double line behind him; in spell 32 (no wall) its
		# whole body, tail and all, has crossed past him
		if c.dir > 0:
			at_him = level_with and head.x >= bearer.position.x + bearer.size.x * 0.45
			past = (a.position.x - size.x / 2.0 >= bearer.end.x) if fight.both else head.x >= fight.barrier
		else:
			at_him = level_with and head.x <= bearer.end.x - bearer.size.x * 0.45
			past = a.position.x + size.x / 2.0 <= bearer.position.x
		if at_him:
			_croc_bites(c)
		elif past:
			# once the heka word glows, one that slips past goes up for it; before that it just bites
			if fight.heka_on:
				_croc_eats_word(c)
				return
			_croc_bites(c)


## A thrust at its furthest: the snout nearest the spear tip, if close enough, is struck.
## Without heka only an ordinary crocodile turns; with heka only a red one does, and heka spent
## on an ordinary crocodile loses the fight.
func _croc_strike() -> void:
	var e: Dictionary = fight.e
	var tip0: Vector2 = fight.pos + _tip_offset()
	var tip: Vector2 = tip0 + _spear_dir() * CROC_THRUST * unit
	# the point, anywhere along its last stroke, must come down on a crocodile (inside its outline),
	# or close by its snout
	var best = null
	var best_d := INF
	for c in fight.crocs:
		if c.s != "crawl":
			continue
		var h := _snout(c)
		var on := Geometry2D.get_closest_point_to_segment(h, tip0, tip).distance_to(h) < CROC_REACH * unit
		for i in 5:
			if _on_croc(c, tip0.lerp(tip, i / 4.0)):
				on = true
				break
		# where the point is on two at once, the one the spear is fit for (heka or not) comes first
		var d := _snout(c).distance_to(tip) + (0.0 if c.red == _holding_heka() else 100000.0)
		if on and d < best_d:
			best_d = d
			best = c
	if best == null:
		return
	var heka := _holding_heka()
	if best.red and not heka:
		return                  # plain bronze does nothing to a red crocodile
	if heka and not best.red:
		_croc_steals(best)
		return
	best.s = "gone"
	fight.killed += 1
	fight.wave_killed += 1
	var a: Node2D = best.node
	a.rotation = 0.0
	(a.get_node("Sprite") as Sprite2D).flip_h = best.dir > 0    # it turns round
	var t := a.create_tween()
	t.tween_property(a, "position:x", a.position.x - 60.0 * unit * best.dir, 0.5)
	t.parallel().tween_property(a, "modulate:a", 0.0, 0.5)
	var w: Dictionary = fight.waves[fight.wave]
	var wave_done: bool = fight.wave_killed >= w.count
	if fight.tut == "first":
		fight.tut = ""
		fight.timer = 1.5
		if not wave_done:
			say("Scribe", "Well struck. More are coming, at different heights.")
	elif not wave_done:
		say("Scribe", "The crocodile turns away.")
	if wave_done:
		if fight.wave + 1 < fight.waves.size():
			_croc_break()
		else:
			_won_if(true)


## Between waves: the crocodiles draw back, the heka word starts to flash, a breather.
func _croc_break() -> void:
	var e: Dictionary = fight.e
	fight.phase = "break"
	fight.timer = e.get("break", 5.0)
	fight.heka_on = true
	say("Scribe", "The crocodiles draw back. Above, signs begin to glow red.")


func _croc_next_wave() -> void:
	fight.wave += 1
	fight.phase = ""
	fight.wave_killed = 0
	fight.wave_launched = 0
	fight.timer = 0.3
	say("Scribe", "They come again.")


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


func _croc_total() -> int:
	var n := 0
	for w in fight.waves:
		n += int(w.count)
	return n


## Heka thrust at an ordinary crocodile: it takes the word of heka and runs.
func _croc_steals(c: Dictionary) -> void:
	_croc_takes_word(c, "Heka spent on an ordinary crocodile! It laughs, seizes the word of power and makes off with it.")


## A crocodile got past the bearer, once the heka word glows: it goes off with the word.
func _croc_eats_word(c: Dictionary) -> void:
	_croc_takes_word(c, "A crocodile slipped past you. It laughs, and the word of heka falls into its jaws.")


## Lost: the crocodile laughs (squashes up and down) and turns round, the heka word spins down from
## the banner into its jaws, the spear-bearer crumbles the moment it lands, and the crocodile carries
## the word off. Then the vignette closes and he is back on the scroll.
func _croc_takes_word(c: Dictionary, why: String) -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", why)
	c.s = "thief"
	var a: Node2D = c.node
	a.rotation = 0.0
	var size: Vector2 = a.get_meta("size")
	var words: Array = _heka_words(e.id)
	var dir: int = -c.dir                       # the way it leaves
	var mouth := a.position + _croc_head(a, dir)
	var t := create_tween()
	# it laughs
	for i in 4:
		t.tween_property(a, "scale", Vector2(1.06, 0.78), 0.1)
		t.tween_property(a, "scale", Vector2(0.96, 1.12), 0.1)
	t.tween_property(a, "scale", Vector2.ONE, 0.08)
	# it turns round
	t.tween_callback(func():
		c.dir = dir
		(a.get_node("Sprite") as Sprite2D).flip_h = dir < 0)
	# the word spins down into its jaws
	for nm in words:
		var w: Node2D = actors[nm]
		w.modulate = RED_CROC
		t.parallel().tween_property(w, "position", mouth + Vector2(0.0, actor_rect(nm).size.y), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(w, "rotation", TAU * 2.0, 0.7)
	t.tween_callback(func(): _disintegrate(e))     # the moment the word is in its jaws, he crumbles
	t.tween_interval(0.2)
	# and carries it off
	var away: float = (fight.full.position.x - size.x) if dir < 0 else (fight.full.end.x + size.x)
	var dx := away - a.position.x
	t.tween_property(a, "position:x", a.position.x + dx, 1.6)
	for nm in words:
		t.parallel().tween_property(actors[nm], "position:x", mouth.x + dx, 1.6)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "crocs" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


## Dev (`--croc-bot`): a stand-in player with a human's limits (sees a crocodile only REACT s after
## it sets off, moves at the bearer's speed), to check that a fight can be won.
const REACT := 0.35

func _bot_move() -> Vector2:
	var best = null
	var soon := INF
	for c in fight.crocs:
		if c.s != "crawl" or fight.clock - c.get("t0", fight.clock) < (float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else REACT):
			continue
		var eta: float = absf(fight.pos.x - _snout(c).x) / (c.speed * unit)
		if eta < soon:
			soon = eta
			best = c
	if best == null:
		return Vector2.ZERO
	var want_face := -int(best.dir)
	var mv := Vector2(float(want_face) if fight.both and fight.facing != want_face else 0.0, 0.0)
	var dy: float = _snout(best).y - (fight.pos.y + fight.tip.y)
	if absf(dy) > 4.0 * unit:
		mv.y = signf(dy)
	# strike when the snout is at the tip, with heka for a red one
	var tip: Vector2 = fight.pos + _tip_offset() + _spear_dir() * CROC_THRUST * unit
	# (where the crocodile will be when the thrust lands: a little further in)
	var lands := tip - Vector2(best.dir * best.speed * unit * THRUST_TIME[0], 0.0)
	var near: bool = _snout(best).distance_to(tip) < CROC_REACH * 0.8 * unit + best.speed * unit * THRUST_TIME[0]
	if fight.facing == want_face and (near or _on_croc(best, lands - Vector2(best.dir * CROC_REACH * 0.5 * unit, 0.0))):
		fight.force_heka = best.red
		_croc_thrust()
	if fight.thrust >= 0.0:
		mv.y = 0.0          # holds still while the spear goes in
	return mv


## The last bite: he crumbles away, and he is back on the scroll.
func _croc_dies(c: Dictionary) -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust.")
	c.s = "thief"
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "crocs" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


## The spear-bearer crumbles away (scripts/dissolve.gdshader).
func _disintegrate(e: Dictionary) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = DISSOLVE
	mat.set_shader_parameter("grain", 3.0 * unit)
	for nm in [e.spear, e.spear + "_pole"]:
		(actors[nm].get_node("Sprite") as Sprite2D).material = mat
	create_tween().tween_method(func(v: float): mat.set_shader_parameter("amount", v), 0.0, 1.05, 1.6)


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
		say("Scribe", "The fight is lost. Click the creature to take up the spear again."))


func _croc_bites(c: Dictionary) -> void:
	fight.red = 0.8
	if fight.tut == "":
		fight.health -= 1
		if fight.health <= 0:
			bites += 1
			_croc_dies(c)
			return
	if c.red and not heka_known and not fight.nudged:
		fight.nudged = true
		say("Scribe", "Bronze alone will not turn the red ones. The signs glowing above may tell you how.")
		c.s = "back"
		_croc_send_back(c)
		bites += 1
		return
	_bite("The crocodile reached you. Line the spear tip up with its snout, and strike as they touch." if fight.tut == "first"
		else "A crocodile reached you.")
	c.s = "back"
	_croc_send_back(c)


## A crocodile that bit slinks back to its own side and comes again at another height.
func _croc_send_back(c: Dictionary) -> void:
	var a: Node2D = c.node
	var lane: float = fight.lanes[rng.randi() % fight.lanes.size()]
	var half: float = a.get_meta("size").x / 2.0 + 10.0 * unit
	var x: float = (fight.full.position.x + half) if c.dir > 0 else (fight.full.end.x - half)
	var to := Vector2(x, lane - _croc_head(a, c.dir).y)
	var t := a.create_tween()     # dies with the crocodile if the fight ends first
	t.tween_property(a, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): a.position = to)
	t.tween_property(a, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		if not fight.is_empty() and c.s == "back":
			c.s = "crawl")


## Send the next crocodile: one of the drawn ones still waiting (the last of a wave always is), else
## a copy of one of the four (from either side when the fight has crocodiles on both sides).
func _croc_launch(speed: float) -> bool:
	var e: Dictionary = fight.e
	var w: Dictionary = fight.waves[fight.wave]
	if fight.wave_launched >= w.count:
		return false
	var order: Array = w.get("red_order", [])
	var red: bool = order[fight.wave_launched] if fight.wave_launched < order.size() else rng.randf() < w.get("red", 0.0)
	var waiting: Array = fight.crocs.filter(func(c): return c.s == "wait")
	# the last of each wave is always one of the drawn crocodiles squatting on screen (so one is
	# kept back for each wave still to end); the others go first (never red). The very last of the
	# fight is the last crocodile there: every other drawn one has come before it, and it waits
	# until the rest are gone, so once it is turned back the screen is clear.
	var last: bool = fight.wave_launched == int(w.count) - 1
	var final: bool = fight.wave == fight.waves.size() - 1
	var keep_back: int = fight.waves.size() - fight.wave
	if last and final and fight.crocs.any(func(x): return x.s == "crawl" or x.s == "back"):
		return false
	if (last or (final and int(w.count) - fight.wave_launched <= waiting.size())) and not waiting.is_empty():
		red = false
	var c: Dictionary
	if not waiting.is_empty() and not red and (last or waiting.size() > keep_back):
		c = waiting[rng.randi() % waiting.size()]
	else:
		var from: Node2D = actors[e.foes[rng.randi() % e.foes.size()]]
		var size: Vector2 = from.get_meta("size")
		var a := _make_actor((from.get_node("Sprite") as Sprite2D).texture, Rect2(Vector2.ZERO, size))
		var dir := -1 if fight.both and rng.randf() < 0.5 else 1
		(a.get_node("Sprite") as Sprite2D).flip_h = dir < 0
		var busy: Array = fight.crocs.filter(func(x): return x.s == "crawl" and x.dir == dir).map(func(x): return _snout(x).y)
		var free: Array = fight.lanes.filter(func(y): return busy.all(func(b): return absf(b - y) > CROC_LANE * unit * 0.9))
		if free.is_empty():
			free = fight.lanes.duplicate()
		var half := size.x / 2.0 + 10.0 * unit
		c = {"node": a, "s": "wait", "home": Vector2.ZERO, "start": Vector2.ZERO, "speed": 0.0, "dir": dir, "red": red}
		# a lane where it keeps clear of the others (on the side it came up on); none: it waits
		for i in range(free.size() - 1, 0, -1):     # (shuffled with the fight's own seed)
			var j := rng.randi() % (i + 1)
			var tmp = free[i]
			free[i] = free[j]
			free[j] = tmp
		var placed := false
		for lane in free:
			a.position = Vector2((fight.full.position.x + half) if dir > 0 else (fight.full.end.x - half), lane - _croc_head(a, dir).y)
			if _instant or _croc_clear(c, speed):
				placed = true
				break
		if not placed:
			a.queue_free()
			return false
		c.home = a.position
		c.start = a.position
		a.modulate = Color(RED_CROC if c.red else Color.WHITE, 0.0)
		a.create_tween().tween_property(a, "modulate:a", 1.0, 0.4)
		fight.crocs.append(c)
		fight.copies.append(a)
		if dir < 0 and not fight.told_back:
			fight.told_back = true
			say("Scribe", "One comes from behind! [←] [→] turn you to face either way.")
	# never two front halves on top of each other, nor two at one spot one just after the other
	if not _instant and not _croc_clear(c, speed):
		if c.node in fight.copies:              # not yet: take the new one away again
			fight.copies.erase(c.node)
			fight.crocs.erase(c)
			c.node.queue_free()
		return false
	# keep the arrivals apart, so there is always time to turn, move and strike between two
	if w.has("min_gap") and not _instant:
		var arrive: float = fight.clock + absf(fight.pos.x - _snout(c).x) / (speed * unit)
		if arrive < fight.last_arrival + w.min_gap:
			if c.node in fight.copies:          # not yet: take the new one away again
				fight.copies.erase(c.node)
				fight.crocs.erase(c)
				c.node.queue_free()
			return false
		fight.last_arrival = arrive
	fight.wave_launched += 1
	c.t0 = fight.clock
	c.s = "crawl"
	c.speed = speed
	return true


## Would crocodile `c`, setting off now at `speed`, keep clear of those already crawling? Their front
## halves (snout to middle) may never touch on the way in (a little overlap above and below is
## allowed), and two at nearly the same height reach him CROC_SAME_SPOT s apart. One coming from
## the other side counts as if it came from this side (mirrored about the bearer), so the two sides
## are kept as far apart as one.
func _croc_clear(c: Dictionary, speed: float) -> bool:
	var t_c := absf(fight.pos.x - _snout(c).x) / (speed * unit)
	for o in fight.crocs:
		if o == c or o.s != "crawl":
			continue
		var t_o: float = absf(fight.pos.x - _snout(o).x) / (o.speed * unit)
		if absf(_snout(o).y - _snout(c).y) < CROC_LANE * unit * 1.5 and absf(t_c - t_o) < CROC_SAME_SPOT:
			return false
		var o_pos: Vector2 = o.node.position
		if o.dir != c.dir:
			o_pos.x = 2.0 * fight.pos.x - o_pos.x
		var t := 0.0
		while t <= minf(t_c, t_o):
			var a := _croc_front(c, c.node.position + Vector2(c.dir * speed * unit * t, 0.0))
			var b := _croc_front(o, o_pos + Vector2(c.dir * o.speed * unit * t, 0.0), c.dir)
			if a.intersects(b):
				return false
			t += 0.1
	return true


## The front half of crocodile `c` (snout to middle) with its pivot at `pos`, trimmed a little above
## and below; `dir` the way it faces (0: its own).
func _croc_front(c: Dictionary, pos: Vector2, dir: int = 0) -> Rect2:
	if dir == 0:
		dir = c.dir
	var size: Vector2 = c.node.get_meta("size")
	var trim := size.y * CROC_FRONT_OVERLAP
	return Rect2(pos.x if dir > 0 else pos.x - size.x / 2.0, pos.y - size.y + trim, size.x / 2.0, size.y - 2.0 * trim)


func _croc_thrust() -> void:
	if fight.thrust >= 0.0 or fight.open < 1.0 or fight.lost:
		return
	fight.thrust = 0.0
	fight.struck = false
	fight.last_thrust = fight.get("clock", 0.0)
	if fight.tut == "thrust":
		fight.tut = "move"
		say("Scribe", "Good. Now move: [↑] [↓] (or [w] [s]) take you up and down.")


func _crocs_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "Press [space] to thrust the spear; [↑] [↓] (or [w] [s]) move you" + ("; [←] [→] turn you." if fight.both else "."))


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
	var t := create_tween()
	t.tween_method(_croc_open, 1.0, 0.0, CROC_OPEN)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
			if then.is_valid():
				then.call()
			else:
				end_fight())


func _crocs_cleanup() -> void:
	if fight.kind == "lunge":
		_lunge_undress()
	if fight.kind == "creep":
		_creep_undress()
	if fight.kind == "apep":
		_apep_undress()
	if fight.kind == "sheaf":
		_sheaf_undress()
	for nm in _all_heka():
		_restore(nm)
	for a in fight.get("copies", []):
		a.queue_free()
	if fight.has("dot") and is_instance_valid(fight.dot):
		fight.dot.queue_free()
	for nm in fight.hidden:
		actors[nm].modulate.a = 1.0
	for nm in [fight.e.spear, fight.e.spear + "_pole"]:
		(actors[nm].get_node("Sprite") as Sprite2D).flip_h = false
		(actors[nm].get_node("Sprite") as Sprite2D).material = null
	_arena.visible = false


## The opened-out vignette: papyrus over the picture band (and the text below), framed again.
func _arena_rect() -> Rect2:
	if fight.is_empty() or not fight.kind in ARENA_FIGHTS:
		return Rect2()
	var p: Rect2 = fight.panel
	var f: Rect2 = fight.full
	var k: float = fight.open
	return Rect2(p.position.lerp(f.position, k), p.size.lerp(f.size, k))


func _draw_arena_lines() -> void:
	var r := _arena_rect()
	if not r.has_area():
		return
	var ink := Color(46 / 255.0, 29 / 255.0, 16 / 255.0)
	var rules: Array = level.rules
	var t0: float = rules[0][0]
	var lw: float = rules[0][1] - rules[0][0]           # 6 px lines, 8 px apart
	var gap: float = lw + 8.0
	_arena_lines.draw_rect(Rect2(r.position.x, t0, r.size.x, lw), ink)
	for y in [r.end.y - lw, r.end.y - lw - gap]:
		_arena_lines.draw_rect(Rect2(r.position.x, y, r.size.x, lw), ink)
	for x in [r.position.x, r.position.x + gap, r.end.x - lw, r.end.x - lw - gap]:
		_arena_lines.draw_rect(Rect2(x, t0, lw, r.end.y - t0), ink)


# the two Merti snakes (spell 37). The vignette opens out, close up; he stands where he is drawn, the
# drawn snake on his left and a mirrored copy of it on his right, both facing him and coiled `rest`
# plate px further out than where they are drawn, out of reach, breathing. He cannot step: ← → turn
# him, Space thrusts on the side he faces. When neither is about to strike, after `idle` s one of the
# two snake signs in the caption flashes red (`warn` s; the left sign for the snake on his left):
# that snake squashes down (`crouch` s) and springs (`snap` s) at his foot, passing the spot where
# it is drawn, where his spear point comes down. A thrust facing it, its point down as the snake
# passes that spot (within `reach` plate px), strikes it; too early and the spear is already
# rising, too late and it is past and bites. A thrust at a snake still coiled: it sees the spear
# and springs at once. Struck `need` times, a snake falls where it is drawn; both fallen, the fight
# is won. `warn`, `crouch`, `snap` and `reach` go from the first value to the second over the
# strikes. Bitten CROC_HEALTH times, he crumbles and is back on the scroll.
const TWIN_FALL := 0.6          ## a snake struck for the last time sinks down (s)
const TWIN_BACK := 0.5          ## after biting or being struck, it slides back to where it waits (s)
const TWIN_BUSY := ["warn", "crouch", "snap", "bitten", "back", "pinned", "fall"]
const TWIN_BOT_AIM := 0.0       ## (--croc-bot) thrusts this long after the moment the autotest measures as best (s)


func _twin_start(e: Dictionary) -> void:
	var cap: Array = level.get("caption", [50.0, 180.0])
	var bearer: Node2D = actors[e.spear]
	_arena_setup(e, true, [e.foe] + e.signs, {"y0": float(cap[0]) - 12.0 * unit, "y1": ground + 24.0 * unit, "x": bearer.get_meta("home").x})
	fight.stand = bearer.get_meta("home")          # he stays where he is drawn: his point is on the snake
	fight.pos = fight.stand
	fight.health = CROC_HEALTH
	fight.clock = 0.0
	fight.last_thrust = -INF
	fight.pinned = false
	fight.idle = rng.randf_range(float(e.idle[0]), float(e.idle[1])) + 0.6
	var left: Node2D = actors[e.foe]
	var home: Vector2 = left.get_meta("home")
	var right := _make_actor((left.get_node("Sprite") as Sprite2D).texture, rects[e.foe])
	right.set_meta("home", Vector2(2.0 * fight.stand.x - home.x, home.y))   # mirrored about him
	right.position = right.get_meta("home")
	fight.copies = [right]
	fight.snakes = []
	for i in 2:
		fight.snakes.append({"node": [left, right][i], "side": [-1, 1][i], "glyph": actors[e.signs[i]], "hits": 0,
			"phase": "rest", "t": 0.0, "off": float(e.rest) * unit, "from": 0.0, "sx": 1.0, "sy": 1.0, "w": 0.0})
	_twin_place()
	_arena_open()


## Each snake as it is now: `off` px out from where it is drawn (as the vignette opens it draws back
## there and turns to face him; the copy fades in), squashed or writhing. The sign of the one about
## to strike flashes red, and stays red until it has struck (or been struck).
func _twin_place() -> void:
	var k: float = fight.open
	var pulse := 0.5 + 0.5 * sin(_time * 10.0)
	for s in fight.snakes:
		var a: Node2D = s.node
		a.position = a.get_meta("home") + Vector2(s.side * s.off * k, 0.0)
		a.scale = Vector2(lerpf(-1.0, 1.0, k) * s.side * s.sx * (1.0 + s.w), lerpf(1.0, s.sy, k) * (1.0 - s.w))
		if s.side > 0:
			a.modulate.a = k
		var glyph: Node2D = s.glyph
		match s.phase:
			"warn": glyph.modulate = Color.WHITE.lerp(RED_CROC, pulse)
			"crouch", "snap": glyph.modulate = RED_CROC
			_: glyph.modulate = Color.WHITE


func _twin_phase(s: Dictionary, p: String) -> void:
	s.phase = p
	s.t = 0.0


## How far along the fight is (0 at the first strike, 1 at the last), for the shrinking times.
func _twin_k() -> float:
	return clampf(float(fight.hits) / maxf(1.0, 2.0 * float(fight.e.need) - 1.0), 0.0, 1.0)


## One of `e[key]`'s two values, as far along as the fight is.
func _twin_tune(key: String) -> float:
	var v: Array = fight.e[key]
	return lerpf(float(v[0]), float(v[1]), _twin_k())


func _twin(dt: float) -> void:
	var e: Dictionary = fight.e
	if fight.open < 1.0 or fight.get("closing", false) or fight.lost:
		return
	fight.clock += dt
	var turn := Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if fight.get("bot", false):
		turn = _twin_bot()
	if turn != 0.0 and not fight.pinned:
		fight.facing = 1 if turn > 0.0 else -1
	# was the point down at any time during this frame (a slow frame may step right over it)?
	var down := false
	if fight.thrust >= 0.0 and not fight.pinned:
		var span := _thrust_down_span()
		down = fight.thrust <= span.y and fight.thrust + dt >= span.x
		fight.thrust += dt
		if not fight.struck and fight.thrust >= THRUST_TIME[0]:
			fight.struck = true
			_twin_provoke()
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
	fight.red = maxf(0.0, fight.red - dt)
	# when neither is busy, after a while one of them (still coiled) is about to strike
	if not fight.snakes.any(func(x): return x.phase in TWIN_BUSY):
		fight.idle -= dt
		if fight.idle <= 0.0:
			var up: Array = fight.snakes.filter(func(x): return x.phase == "rest")
			if not up.is_empty():
				_twin_phase(up[rng.randi() % up.size()], "warn")
			fight.idle = rng.randf_range(float(e.idle[0]), float(e.idle[1]))
	var rest := float(e.rest) * unit
	var reach := _twin_tune("reach") * unit
	var bite := float(e.bite) * unit
	var breathe := 1.0 + 0.018 * sin(fight.clock * TAU / 1.6)
	for s in fight.snakes:
		s.t += dt
		s.w = 0.0
		match s.phase:
			"rest", "warn":    # coiled out of reach, breathing; its sign flashes: it is about to strike
				s.off = rest
				s.sx = 2.0 - breathe
				s.sy = breathe
				if s.phase == "warn" and s.t >= _twin_tune("warn"):
					_twin_phase(s, "crouch")
					s.for = _twin_tune("crouch")
			"crouch":          # it squashes down
				var u := minf(s.t / float(s.for), 1.0)
				var k := u * u * (3.0 - 2.0 * u)
				s.sx = 1.0 + 0.10 * k
				s.sy = 1.0 - 0.18 * k
				if s.t >= float(s.for) + 0.1:
					_twin_phase(s, "snap")
					s.for = _twin_tune("snap")
					s.from = s.off
			"snap":            # and springs at his foot, past the spot where it is drawn
				var u := minf(s.t / float(s.for), 1.0)
				var was: float = s.off
				s.off = s.from + (-bite - s.from) * (1.0 - (1.0 - u) * (1.0 - u))
				s.sx = 1.10 + 0.06 * u
				s.sy = 0.82 + 0.12 * u
				if down and fight.facing == s.side and was >= -reach and s.off <= reach:
					_twin_caught(s)
				elif u >= 1.0:
					_twin_phase(s, "bitten")
					_twin_bites(s)
					if fight.lost:
						break
			"bitten":          # its head at his foot a moment
				if s.t >= 0.4:
					_twin_back(s)
			"back":            # back to where it waits
				var u := minf(s.t / TWIN_BACK, 1.0)
				var k := u * u * (3.0 - 2.0 * u)
				s.off = lerpf(s.from, rest, k)
				s.sx = lerpf(1.1, 1.0, k)
				s.sy = lerpf(0.94, 1.0, k)
				if u >= 1.0:
					_twin_phase(s, "rest")
			"pinned":          # held on the spear point, writhing
				s.w = 0.05 * sin(fight.clock * 40.0)
				if s.t >= ROACH_FREEZE:
					fight.pinned = false
					fight.struck = true
					fight.thrust = THRUST_TIME[0] + 0.001          # the spear draws back up
					if s.hits >= int(e.need):
						_twin_phase(s, "fall")
						s.from = s.off
					else:
						_twin_back(s)
			"fall":            # it sinks down where it is drawn, lying still
				var u := minf(s.t / TWIN_FALL, 1.0)
				s.off = lerpf(s.from, 0.0, u)
				s.sx = 1.0
				s.sy = lerpf(1.0, 0.35, u)
				if u >= 1.0:
					_twin_phase(s, "fallen")
					if fight.snakes.all(func(x): return x.phase == "fallen"):
						end_fight()
						return
	_twin_place()
	_place_bearer()


func _twin_back(s: Dictionary) -> void:
	s.from = s.off
	_twin_phase(s, "back")


func _twin_caught(s: Dictionary) -> void:
	s.hits += 1
	fight.hits += 1
	fight.pinned = true
	_hurt(s.node)
	_twin_phase(s, "pinned")
	_dev_shot("SHOT_ON_CATCH")
	say("Scribe", "Struck!" + (" It falls." if s.hits >= int(fight.e.need) else " It pulls free and coils again."))


## The spear at full thrust on the side he faces, with the snake there still coiled: it sees it and
## springs at once.
func _twin_provoke() -> void:
	var s: Dictionary = fight.snakes[0 if fight.facing < 0 else 1]
	if not s.phase in ["rest", "warn"]:
		return
	s.why = "It saw the spear and sprang. Wait for its sign to flash and for it to squash down; thrust as it springs."
	_twin_phase(s, "snap")
	s.for = _twin_tune("snap")
	s.from = s.off


func _twin_bites(s: Dictionary) -> void:
	_dev_shot("SHOT_ON_BITE")
	fight.red = 0.8
	fight.health -= 1
	bites += 1
	if fight.health <= 0:
		fight.lost = true
		var e: Dictionary = fight.e
		say("Scribe", "One bite too many: the spear-bearer crumbles to dust.")
		_disintegrate(e)
		var t := create_tween()
		t.tween_interval(2.0)
		t.tween_callback(func():
			if not fight.is_empty() and fight.kind == "twin" and fight.e.id == e.id and fight.lost:
				_arena_lost(e))
		return
	var why: String = s.get("why", "")
	s.erase("why")
	if why == "":
		if fight.facing != s.side:
			why = "It sprang from your other side. Turn to the snake whose sign flashes ([←] [→])."
		elif fight.clock - fight.last_thrust < float(s.for) + 0.4:
			why = "Too early or too late: thrust just as it springs past your spear point."
		else:
			why = "It sprang at you. When it squashes down, thrust as it springs."
	say("Scribe", why + " Bitten.")


func _twin_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "[←] [→] (or [a] [d]) turn you; [space] thrusts. Thrust as a snake springs at you.")


## Dev (`--croc-bot`): turns to the snake whose sign flashes and thrusts TWIN_BOT_AIM s after the
## middle of the window the autotest measures (with BOT_MISS it never thrusts, to see them bite).
func _twin_bot() -> float:
	for s in fight.snakes:
		if s.phase in ["warn", "crouch", "snap"]:
			if fight.facing != s.side:
				return float(s.side)
			if s.phase == "crouch" and not s.has("bot_at") and not OS.has_environment("BOT_MISS"):
				s.bot_at = fight.clock + float(s.for) + 0.1 + _twin_aim() + TWIN_BOT_AIM
			if s.has("bot_at") and fight.clock >= s.bot_at:
				s.erase("bot_at")
				_croc_thrust()
	return 0.0


## When to press Space (s from the start of the snap) to strike a springing snake: as it passes
## the spot where it is drawn, less the time the point takes to come down.
func _twin_aim() -> float:
	var rest := float(fight.e.rest)
	var bite := float(fight.e.bite)
	var u := 1.0 - sqrt(maxf(0.0, 1.0 - rest / (rest + bite)))      # the snap's ease-out reaches 0 here
	var span := _thrust_down_span()
	return u * _twin_tune("snap") - (span.x + span.y) / 2.0


## (autotest) The snake on side `side` squashing, Space pressed `tau` s from the start of its snap
## (facing it); true = struck. The other is kept quiet.
func _twin_try(side: int, tau: float) -> bool:
	var s: Dictionary = fight.snakes[0 if side < 0 else 1]
	var other: Dictionary = fight.snakes[1 if side < 0 else 0]
	var hits: int = s.hits
	fight.facing = side
	fight.thrust = -1.0
	fight.pinned = false
	fight.idle = 99.0
	if not other.phase in ["fall", "fallen"]:
		_twin_phase(other, "rest")
	s.off = float(fight.e.rest) * unit
	_twin_phase(s, "crouch")
	s.for = _twin_tune("crouch")
	var dt := 1.0 / 240.0
	var t: float = -(float(s.for) + 0.1)
	var pressed := false
	while t < 0.6:
		if not pressed and t >= tau:
			pressed = true
			_croc_thrust()
		_twin(dt)
		t += dt
		if s.hits > hits or s.phase == "bitten" or fight.lost:
			break
	return s.hits > hits


## (autotest) The span of press times (from the start of the snap) that strike; leaves no hit counted.
func _twin_window(side: int) -> Array:
	var s: Dictionary = fight.snakes[0 if side < 0 else 1]
	var lo := INF
	var hi := -INF
	var tau := -0.4
	while tau <= 0.4:
		fight.health = 99
		var hits: int = s.hits
		var all: int = fight.hits
		if _twin_try(side, tau):
			lo = minf(lo, tau)
			hi = maxf(hi, tau)
		s.hits = hits
		fight.hits = all
		fight.pinned = false
		tau += 0.005
	fight.health = CROC_HEALTH
	_twin_phase(s, "rest")
	return [lo, hi]


# the snake on the ground (spell 35): red light, green light. The vignette opens out (close up, as for
# spell 33) to the left; the snake slides off ahead of him and lies with its back to him. He creeps
# up along the ground (← or A; forward only, and no further than where his point is over its eye),
# and a thrust (Space) whose point comes down on its eye strikes it. A small red dot shows where the
# point will land. Now and then it lifts
# its head (the warning), turns it round to look at him, and turns away again. Moving or thrusting
# while it looks (after CREEP_GRACE): it lashes back at his foot. A thrust that lands off its eye
# (on the rest of its head, or short on the ground) strikes nothing, and it turns to look. Struck, it slides `flee` on; struck
# `need` times, it lies still; bitten CROC_HEALTH times, he crumbles and is back on the scroll.
const CREEP_REACH := 10.0       ## the point counts this close (along the ground) to its eye (plate px)
const CREEP_GRACE := 0.12       ## once it has turned to look, a move this soon is not seen (s)
const CREEP_TURN := 0.15        ## it turns its head round (s)
const CREEP_LIFT := 0.4         ## how far it lifts its head to look back (rad; the warning, under half that)
const CREEP_DOT := 1.5          ## the red dot where the spear point will come down (plate px)
const CREEP_SNAP := 0.18        ## its lash back at his foot (s)
const CREEP_SLIDE := 0.6        ## sliding back off ahead of him (s)


func _creep_start(e: Dictionary) -> void:
	# close up, from the caption banner to just under the ground; he stands near the right-hand
	# edge, the snake lies near the left-hand one
	var cap: Array = level.get("caption", [50.0, 180.0])
	var y0: float = float(cap[0]) - 12.0 * unit
	var y1: float = ground + 24.0 * unit
	var vp := get_viewport_rect().size
	var z: float = (vp.y - hud.top_height() - hud.bottom_height() - 10.0) / (y1 - y0)
	var right: float = rects[e.spear].end.x + 40.0 * unit
	# wide enough that the snake starts left of where it is drawn, with room to slide on as it is
	# struck (however tall the HUD leaves the picture)
	var foe: Node2D = actors[e.foe]
	var w: float = right - foe.get_meta("home").x + foe.get_meta("size").x / 2.0 + 40.0 * unit \
		+ float(e.flee) * unit * int(e.need)
	z = minf(z, vp.x / w)
	_arena_setup(e, false, [e.foe], {"y0": y0, "y1": y1, "x": right - vp.x / z / 2.0, "z": z})
	fight.stand = actors[e.spear].get_meta("home")
	fight.pos = fight.stand
	fight.health = CROC_HEALTH
	fight.clock = 0.0
	fight.last_thrust = -INF
	fight.pinned = false
	var a: Node2D = actors[e.foe]
	# the point must come down on its eye (from its pivot)
	var size: Vector2 = a.get_meta("size")
	fight.mark = Vector2(-size.x / 2.0, -size.y) + Vector2(float(e.eye[0]), float(e.eye[1]))
	_creep_dress(e)
	fight.snake = CREEPING_SNAKE_STATE.new(a)
	fight.snake.offset = _creep_edge_off() + float(e.flee) * unit * (int(e.need) - 1)   # room to slide on
	_creep_place()
	_arena_open()


## For this fight only: its head cut from its body, on a pivot of its own, so it can lift and turn.
func _creep_dress(e: Dictionary) -> void:
	var a: Node2D = actors[e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	fight.snake_plain = sp.texture
	var img := sp.texture.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var hr: Array = e.head_rect
	var r := Rect2i(int(hr[0]), int(hr[1]), int(hr[2]), int(hr[3]))
	img.fill_rect(r, Color(0, 0, 0, 0))
	sp.texture = ImageTexture.create_from_image(img)
	var neck := Vector2(float(e.head_pivot[0]), float(e.head_pivot[1]))
	fight.neck_at = sp.position + neck
	var pivot := Node2D.new()
	pivot.name = "Head"
	pivot.position = fight.neck_at
	var hs := Sprite2D.new()
	hs.texture = fight.snake_plain
	hs.centered = false
	hs.region_enabled = true
	hs.region_rect = Rect2(r)
	hs.position = Vector2(r.position) - neck
	pivot.add_child(hs)
	a.add_child(pivot)


## Undo _creep_dress.
func _creep_undress() -> void:
	if not fight.has("snake_plain"):
		return
	var a: Node2D = actors[fight.e.foe]
	(a.get_node("Sprite") as Sprite2D).texture = fight.snake_plain
	var head := a.get_node_or_null("Head")
	if head:
		a.remove_child(head)
		head.queue_free()


## Where the spear point comes down at the full thrust, and where its head is now.
func _creep_point() -> Vector2:
	return fight.pos + _tip_offset() + _spear_dir() * CROC_THRUST * unit


func _creep_head() -> Vector2:
	return fight.snake.node.position + fight.mark


## Is the spear point over its head (anywhere on it, not only the eye)?
func _creep_on_head() -> bool:
	var a: Node2D = fight.snake.node
	var hr: Array = fight.e.head_rect
	var x0: float = a.position.x - a.get_meta("size").x / 2.0 + float(hr[0])
	var x: float = _creep_point().x
	return x >= x0 and x <= x0 + float(hr[2])


func _creep_in_reach() -> bool:
	return absf(_creep_point().x - _creep_head().x) <= CREEP_REACH * unit


## Its offset from where it is drawn with its tail at the left-hand edge of the opened vignette.
func _creep_edge_off() -> float:
	var a: Node2D = actors[fight.e.foe]
	return fight.full.position.x + 40.0 * unit + a.get_meta("size").x / 2.0 - a.get_meta("home").x


func _creep_place() -> void:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	var a: Node2D = snake.node
	a.position = a.get_meta("home") + Vector2(snake.offset * fight.open, 0.0)
	a.scale = Vector2(1.0 + snake.wobble, 1.0 - snake.wobble)
	var head: Node2D = a.get_node_or_null("Head")
	if head:
		head.scale.x = snake.horizontal_scale
		head.rotation = snake.lift * snake.horizontal_scale
		head.position = fight.neck_at + Vector2(0.0, -snake.lift * 16.0 * unit)


func _creep_phase(p: String) -> void:
	fight.snake.phase = p
	fight.snake.elapsed = 0.0


func _creep(dt: float) -> void:
	var e: Dictionary = fight.e
	if fight.open < 1.0 or fight.get("closing", false) or fight.lost:
		return
	fight.clock += dt
	var mv := -float(Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A))
	if fight.get("bot", false):
		mv = _creep_bot()
	_creep_move(mv, dt)
	if fight.thrust >= 0.0 and not fight.pinned:
		fight.thrust += dt
		if not fight.struck and fight.thrust >= THRUST_TIME[0]:
			fight.struck = true
			_creep_strike()
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
	fight.red = maxf(0.0, fight.red - dt)
	var snake: CREEPING_SNAKE_STATE = fight.snake
	snake.elapsed += dt
	snake.wobble = 0.0
	match snake.phase:
		"away":            # its head down and turned away: he may move
			snake.lift = maxf(0.0, snake.lift - dt * 4.0)
			snake.horizontal_scale = 1.0
			if snake.elapsed >= snake.duration:
				snake.fake_warning = fight.hits > 0 and rng.randf() < float(e.fake)
				_creep_phase("tell")
		"tell":            # the warning: it lifts its head, trembling
			var dur := _creep_tell()
			snake.lift = CREEP_LIFT * 0.45 * minf(snake.elapsed / dur, 1.0) + 0.04 * sin(fight.clock * 50.0)
			if snake.elapsed >= dur:
				if snake.fake_warning:            # ...and lays it down again
					_creep_phase("away")
					snake.duration = rng.randf_range(float(e.away[0]), float(e.away[1]))
				else:
					_creep_phase("turn")
		"turn":            # and turns it round to look at him
			var u := minf(snake.elapsed / CREEP_TURN, 1.0)
			snake.horizontal_scale = lerpf(1.0, -1.0, u)
			snake.lift = lerpf(CREEP_LIFT * 0.45, CREEP_LIFT, u)
			if u >= 1.0:
				_creep_phase("watch")
				_dev_shot("SHOT_ON_WATCH")
				snake.duration = rng.randf_range(float(e.watch[0]), float(e.watch[1]))
		"watch":
			snake.horizontal_scale = -1.0
			snake.lift = CREEP_LIFT + 0.05 * sin(fight.clock * 3.0)
			if snake.elapsed >= snake.duration:
				_creep_phase("unturn")
		"unturn":          # it looks away again
			var u := minf(snake.elapsed / CREEP_TURN, 1.0)
			snake.horizontal_scale = lerpf(-1.0, 1.0, u)
			snake.lift = lerpf(CREEP_LIFT, 0.0, u)
			if u >= 1.0:
				_creep_phase("away")
				snake.duration = rng.randf_range(float(e.away[0]), float(e.away[1]))
		"strike":          # it lashes back at his foot
			var u := minf(snake.elapsed / CREEP_SNAP, 1.0)
			snake.offset = snake.slide_from + (snake.slide_to - snake.slide_from) * (1.0 - (1.0 - u) * (1.0 - u))
			if u >= 1.0:
				_creep_bites()
		"bitten":
			if snake.elapsed >= 0.4:
				_creep_slide(snake.return_offset)          # back to where it lay
		"slide":           # it slides off, its head turned away again
			var u := minf(snake.elapsed / CREEP_SLIDE, 1.0)
			var k := u * u * (3.0 - 2.0 * u)
			snake.offset = snake.slide_from + (snake.slide_to - snake.slide_from) * k
			snake.horizontal_scale = lerpf(snake.previous_scale, 1.0, k)
			snake.lift = lerpf(snake.previous_lift, 0.0, k)
			if u >= 1.0:
				_creep_phase("away")
				snake.duration = rng.randf_range(float(e.away[0]), float(e.away[1]))
		"pinned":          # held on the spear point, writhing
			snake.wobble = 0.05 * sin(fight.clock * 40.0)
			if snake.elapsed >= ROACH_FREEZE:
				fight.pinned = false
				fight.struck = true
				fight.thrust = THRUST_TIME[0] + 0.001          # the spear draws back up
				if fight.hits >= int(e.need):
					end_fight()
					return
				_creep_slide(maxf(_creep_edge_off(), snake.offset - float(e.flee) * unit))   # on toward the edge
	_creep_place()
	_place_bearer()


## He creeps forward along the ground (`mv` < 0), never past where the point lands on its head.
## Seen moving: it lashes back.
func _creep_move(mv: float, dt: float) -> void:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	if mv >= 0.0 or snake.phase in ["strike", "bitten", "pinned"]:
		return
	var lo: float = _creep_head().x - (_creep_point().x - fight.pos.x)
	var x: float = maxf(fight.pos.x - float(fight.e.creep) * unit * dt, minf(lo, fight.pos.x))
	if absf(x - fight.pos.x) < 0.01:
		return
	fight.pos.x = x
	if snake.phase == "watch" and snake.elapsed >= CREEP_GRACE:
		_creep_lash("It turned and saw you move.")


## The warning grows shorter with each strike.
func _creep_tell() -> float:
	var tell: Array = fight.e.tell
	var k := clampf(float(fight.hits) / maxf(1.0, float(fight.e.need) - 1.0), 0.0, 1.0)
	return lerpf(float(tell[0]), float(tell[1]), k)


## The spear point comes down.
func _creep_strike() -> void:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	if snake.phase in ["strike", "bitten", "pinned", "slide"]:
		return
	if snake.phase == "watch" and snake.elapsed >= CREEP_GRACE:
		_creep_lash("It saw the spear coming.")
		return
	if _creep_in_reach():
		fight.hits += 1
		fight.pinned = true
		_hurt(snake.node)
		_creep_phase("pinned")
		_dev_shot("SHOT_ON_CATCH")
		var left: int = int(fight.e.need) - fight.hits
		say("Scribe", "Struck!" + (" It pulls free and slides off ahead of you. %d more." % left if left > 0 else ""))
		return
	# off its eye: on its head, or short of it on the ground; either way it turns to look
	if _creep_on_head():
		say("Scribe", "That hit its head, but not the eye. Bring the red dot onto its eye before you thrust.")
	else:
		say("Scribe", "Short of its eye: the spear strikes the ground, and it hears.")
	if snake.phase in ["away", "tell"]:
		snake.lift = maxf(snake.lift, CREEP_LIFT * 0.45)
		_creep_phase("turn")


## It lashes round at his front foot.
func _creep_lash(why: String) -> void:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	snake.return_offset = snake.offset
	snake.slide_from = snake.offset
	snake.slide_to = fight.pos.x - fight.stand.x + 4.0 * unit      # its head, turned round, at his foot
	snake.horizontal_scale = -1.0
	snake.lift = CREEP_LIFT * 0.4
	snake.bite_reason = why
	_creep_phase("strike")


func _creep_bites() -> void:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	_creep_phase("bitten")
	_dev_shot("SHOT_ON_BITE")
	fight.red = 0.8
	fight.health -= 1
	bites += 1
	if fight.health <= 0:
		_creep_dies()
		return
	say("Scribe", snake.bite_reason + " Bitten. When its head lifts, let go of the keys and wait until it looks away again.")


## It slides to `to` (its offset from where it is drawn), its head turned away again.
func _creep_slide(to: float) -> void:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	snake.slide_from = snake.offset
	snake.slide_to = to
	snake.previous_scale = snake.horizontal_scale
	snake.previous_lift = snake.lift
	_creep_phase("slide")


## The last bite: he crumbles away, and he is back on the scroll.
func _creep_dies() -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust.")
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "creep" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


func _creep_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "[←] (or [a]) creeps toward it; [space] thrusts. Hold still while it looks back.")


## Dev (`--croc-bot`): creeps while its head is down, stops when it lifts, thrusts when in reach
## (with BOT_MISS it never stops, to see it look back and bite).
func _creep_bot() -> float:
	var snake: CREEPING_SNAKE_STATE = fight.snake
	if snake.phase != "away" and not (OS.has_environment("BOT_MISS") and snake.phase in ["tell", "turn", "watch"]):
		return 0.0
	if _creep_in_reach():
		_croc_thrust()
		return 0.0
	return -1.0


# the roach (spell 36). The vignette opens out as for the crocodiles. The bearer stands still in the
# middle: ← → turn him, Space thrusts. `count` beetles (the drawn one and copies) dart about very
# fast between resting spots; every `bait_every` darts each stops where the spear point can reach
# it on his left or right (sometimes, `fake`, just out of reach). Only the spear point at the full
# thrust catches one: on its body, or with `dot` only on a red dot on its back. A catch holds
# everything still for ROACH_FREEZE s; the pinned beetle is gone, and all of them pinned wins. A
# beetle that stops within reach and gets away again has passed the point: it reddens, and one that
# has passed `passes` times and gets away again is too many. They multiply until they fill the
# screen, the bearer crumbles, and he is back on the scroll.
const ROACH_FREEZE := 0.5      ## the pause after a catch, to show it
const ROACH_DOT := 8.0         ## radius of the red dot on its back (plate px), when `dot` is set
const ROACH_SWARM := 120       ## how many beetles fill the screen when the fight is lost


func _roach_start(e: Dictionary) -> void:
	_arena_setup(e, true, [e.foe])
	var full: Rect2 = fight.full
	# he stands in the middle of the opened vignette, his spear point at its middle height
	fight.stand = Vector2(full.get_center().x, full.get_center().y - fight.tip.y)
	fight.pos = fight.stand
	fight.hits = 0
	fight.need = int(e.count) if _roach_need < 0 else _roach_need
	fight.freeze = 0.0
	fight.clock = 0.0
	fight.copies = []
	fight.roaches = []
	var a: Node2D = actors[e.foe]
	var size: Vector2 = a.get_meta("size")
	var home_c: Vector2 = a.get_meta("home") + Vector2(0.0, -size.y / 2.0)
	# the drawn one waits a little way off to the left while the vignette opens; the others
	# (copies) fade in at other spots around him
	var spots := [Vector2(-260.0, 0.0), Vector2(300.0, -150.0), Vector2(220.0, 170.0), Vector2(-200.0, -180.0), Vector2(-320.0, 160.0)]
	for i in fight.need:
		var c0: Vector2 = fight.stand + Vector2(0.0, fight.tip.y) + spots[i % spots.size()] * unit
		var node := a
		if i > 0:
			node = _make_actor((a.get_node("Sprite") as Sprite2D).texture, Rect2(Vector2.ZERO, size))
			node.modulate.a = 0.0
			fight.copies.append(node)
		var r := {"node": node, "size": size, "home_c": home_c if i == 0 else c0, "c0": c0, "c": c0, "target": c0,
			"wait": 0.9 + 0.35 * i, "rest_from": 0.0, "leg": i, "darting": false, "rest": 0.0,
			"at_point": false, "passes": 0, "gone": false}
		fight.roaches.append(r)
		_roach_place(r, home_c if i == 0 else c0)
		if e.get("dot", false):
			var dot := Node2D.new()
			dot.position = Vector2(0.0, -size.y / 2.0)
			dot.draw.connect(func(): dot.draw_circle(Vector2.ZERO, ROACH_DOT * unit, Color(181 / 255.0, 91 / 255.0, 60 / 255.0)))
			node.add_child(dot)
			if i == 0:
				fight.dot = dot
	fight.roach = fight.roaches[0]
	_arena_open()


## Put beetle `r`'s body centre at `c` (its pivot is at the bottom centre, and it turns as it runs).
func _roach_place(r: Dictionary, c: Vector2) -> void:
	r.c = c
	r.node.position = c + Vector2(0.0, r.size.y / 2.0).rotated(r.node.rotation)


## Where the spear point is at the full thrust, facing `side` (-1 left, 1 right).
func _roach_spear_point(side: int) -> Vector2:
	return fight.pos + Vector2(fight.tip.x * -side, fight.tip.y) + Vector2(fight.dir.x * -side, fight.dir.y) * CROC_THRUST * unit


## Does a spear point at `p` touch beetle `r` (its body, or the dot when there is one)?
func _roach_touches(r: Dictionary, p: Vector2) -> bool:
	if fight.e.get("dot", false):
		return p.distance_to(r.c) <= ROACH_DOT * unit
	var q: Vector2 = (p - r.c).rotated(-r.node.rotation)
	var ax: float = r.size.x * 0.45
	var ay: float = r.size.y * 0.42
	return (q.x * q.x) / (ax * ax) + (q.y * q.y) / (ay * ay) <= 1.0


## The beetles still running.
func _roaches() -> Array:
	return fight.roaches.filter(func(r): return not r.gone)


## The next place beetle `r` runs to: every `bait_every` darts, by the spear point of one side or
## the other (a `fake` one stops just out of reach); otherwise anywhere around him. A beetle that
## leaves the spear point has passed it once more; past `passes` times, the fight is lost.
func _roach_next(r: Dictionary) -> void:
	var e: Dictionary = fight.e
	if r.at_point:
		r.at_point = false
		r.passes += 1
		var most: int = int(e.get("passes", 3))
		r.node.modulate = Color(Color.WHITE.lerp(RED_CROC, minf(1.0, float(r.passes) / most)), r.node.modulate.a)
		if r.passes > most:
			_roach_swarm(r)
			return
	r.leg += 1
	var full: Rect2 = fight.full
	var reach: float = ROACH_DOT * unit if e.get("dot", false) else r.size.y * 0.3
	if r.leg % int(e.bait_every) == 0:
		var side := -1 if rng.randf() < 0.5 else 1
		var p := _roach_spear_point(side)
		var off := Vector2.from_angle(rng.randf() * TAU)
		if rng.randf() < e.get("fake", 0.0):
			off *= reach * 2.2 + r.size.y * 0.5       # just out of reach
		else:
			off *= reach * rng.randf() * 0.6
			r.at_point = true
		r.target = p + off
		r.rest = rng.randf_range(e.bait_rest[0], e.bait_rest[1])
	else:
		var span_x: float = e.range * unit
		r.target = Vector2(
			clampf(fight.stand.x + rng.randf_range(-span_x, span_x), full.position.x + 80.0 * unit, full.end.x - 80.0 * unit),
			rng.randf_range(full.position.y + 40.0 * unit, full.end.y - 40.0 * unit))
		r.rest = rng.randf_range(e.rest[0], e.rest[1])
	r.darting = true


func _roach(dt: float) -> void:
	var e: Dictionary = fight.e
	if fight.open < 1.0 or fight.get("closing", false) or fight.lost:
		return
	fight.clock += dt
	# turn
	var turn := Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if fight.get("bot", false):
		turn = _roach_bot()
	if turn != 0.0:
		fight.facing = 1 if turn > 0.0 else -1
	# a catch: everything holds still, the spear thrust home, then the rest run again (or it is over)
	if fight.freeze > 0.0:
		fight.freeze -= dt
		var pinned: Dictionary = fight.pinned_roach
		pinned.node.rotation = sin(fight.clock * 40.0) * 0.08     # it wriggles on the spear
		_roach_place(pinned, pinned.c)
		if fight.freeze <= 0.0:
			fight.thrust = THRUST_TIME[0] + 0.001             # the spear draws back
			pinned.gone = true                                # and the pinned one is done for
			pinned.node.create_tween().tween_property(pinned.node, "modulate:a", 0.0, 0.3)
			if fight.hits >= fight.need:
				end_fight()
				return
		_place_bearer()
		return
	if fight.thrust >= 0.0:
		fight.thrust += dt
		if not fight.struck and fight.thrust >= THRUST_TIME[0]:
			fight.struck = true
			_roach_strike()
			if fight.freeze > 0.0:
				fight.thrust = THRUST_TIME[0]                 # held out while it is pinned
				_place_bearer()
				return
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
	_place_bearer()
	# each runs, rests, runs
	for r in _roaches():
		if r.darting:
			var d: Vector2 = r.target - r.c
			var step: float = e.dart * unit * dt
			if d.length() > 1.0:
				r.node.rotation = lerp_angle(r.node.rotation, d.angle(), minf(1.0, dt * 30.0))
			if d.length() <= step:
				_roach_place(r, r.target)
				r.darting = false
				r.wait = r.rest
				r.rest_from = fight.clock
			else:
				_roach_place(r, r.c + d.normalized() * step)
		else:
			r.wait -= dt
			r.node.rotation += sin(fight.clock * 23.0 + r.leg) * 0.004     # feelers twitching
			_roach_place(r, r.c)
			if r.wait <= 0.0:
				_roach_next(r)
				if fight.lost:
					return


func _roach_strike() -> void:
	var p := _roach_spear_point(fight.facing)
	var hit = null
	for r in _roaches():
		if _roach_touches(r, p):
			hit = r
			break
	if hit == null:
		return
	fight.hits += 1
	if fight.get("bot", false):
		print("ROACH caught at ", snappedf(fight.clock, 0.01), " s")
		if OS.has_environment("SHOT_ON_CATCH"):      # dev: a picture of the catch
			get_tree().create_timer(0.1).timeout.connect(func():
				get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_ON_CATCH")))
	fight.freeze = ROACH_FREEZE
	fight.pinned_roach = hit
	hit.darting = false
	hit.at_point = false
	hit.node.modulate = Color(RED_CROC, hit.node.modulate.a)
	var left: int = fight.need - fight.hits
	say("Scribe", "Pinned!" + (" %d more." % left if left > 0 else ""))


## Lost: beetle `r` got away from the spear point once too often. Beetles multiply from the ones
## still running until they fill the screen; the bearer crumbles; back on the scroll.
func _roach_swarm(r: Dictionary) -> void:
	var e: Dictionary = fight.e
	fight.lost = true
	say("Scribe", "A beetle got away from your spear once too often. They multiply until they fill the vignette.")
	var from: Array = _roaches().map(func(x): return x.c)
	var tex: Texture2D = (r.node.get_node("Sprite") as Sprite2D).texture
	var size: Vector2 = r.size
	var full: Rect2 = fight.full
	for i in ROACH_SWARM:
		var b := _make_actor(tex, Rect2(Vector2.ZERO, size))
		var c: Vector2 = from[i % from.size()]
		b.position = c + Vector2(0.0, size.y / 2.0)
		b.rotation = rng.randf() * TAU
		b.modulate = Color(Color.WHITE.lerp(RED_CROC, rng.randf_range(0.3, 1.0)), 0.0)
		fight.copies.append(b)
		var to := Vector2(rng.randf_range(full.position.x + 40.0 * unit, full.end.x - 40.0 * unit),
			rng.randf_range(full.position.y + 40.0 * unit, full.end.y - 20.0 * unit))
		var t := b.create_tween()
		t.tween_interval(i * 0.015)
		t.tween_property(b, "modulate:a", 1.0, 0.1)
		t.parallel().tween_property(b, "position", to, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var t := create_tween()
	t.tween_interval(ROACH_SWARM * 0.015 + 0.2)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "roach" and fight.e.id == e.id and fight.lost:
			_disintegrate(e))
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "roach" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


func _roach_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "Press [space] to thrust the spear; [←] [→] turn you. You cannot step.")


## Dev (`--croc-bot`): turns toward a beetle that has rested REACT s within reach, and thrusts.
func _roach_bot() -> float:
	var react: float = float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else REACT
	for r in _roaches():
		if r.darting or fight.clock - r.rest_from < react:
			continue
		var side := 1 if r.c.x > fight.pos.x else -1
		if _roach_touches(r, _roach_spear_point(side)):
			if side == fight.facing:
				_croc_thrust()
				return 0.0
			return float(side)
	return 0.0


# the lunging snake (spell 33). The vignette opens out as for the crocodiles; the bearer stays where
# he is drawn, his spear raised, and cannot move. The snake coils a little way off, out of reach,
# breathing (a faint squash up and down). Its tail waves: the warning. It squashes down, then
# springs, a fast snap: on the way it passes the very spot where it is drawn, and a thrust (Space)
# there brings the spear point down on the red mark on its body. At the end of the snap its head is
# at his front leg (its body behind his skirt): bitten. Too early and the spear is already coming
# back up when it springs; too late and it is past. Struck `need` times, it is overcome; bitten
# CROC_HEALTH times, he crumbles and the fight starts over.
const SNAKE_MARK := 7.0         ## radius of the red mark on its body (plate px), when `marks` does not say
const SNAKE_GRACE := 3.0        ## the spear point counts this close outside the mark (plate px)
const SNAKE_PAD := 40           ## room around the snake's picture for the tail to wave into (px)
const SNAKE_FIGURE := preload("res://scripts/figure.gdshader")
const SNAKE_TAIL := preload("res://scripts/snake_tail.gdshader")


func _lunge_start(e: Dictionary) -> void:
	# close up: from the caption banner to just under the ground, centred between him and the snake
	var cap: Array = level.get("caption", [50.0, 180.0])
	var mid_x: float = (actors[e.spear].get_meta("home").x + actors[e.foe].get_meta("home").x) / 2.0 - float(e.rest) * unit
	_arena_setup(e, false, [e.foe], {"y0": float(cap[0]) - 12.0 * unit, "y1": ground + 24.0 * unit, "x": mid_x})
	# he stays exactly where he is drawn: that is where the spear meets the mark
	var bearer: Node2D = actors[e.spear]
	fight.stand = bearer.get_meta("home")
	fight.pos = fight.stand
	fight.health = CROC_HEALTH
	fight.clock = 0.0
	fight.pinned = false
	fight.last_thrust = -INF
	_lunge_dress(e)
	var a: Node2D = actors[e.foe]
	var size: Vector2 = a.get_meta("size")
	var home: Vector2 = a.get_meta("home")
	# where the spear point comes down (at the full thrust) with the snake where it is drawn: the
	# nearest bit of its body there is the mark
	var point: Vector2 = fight.pos + _tip_offset() + _spear_dir() * CROC_THRUST * unit
	var mark: Vector2 = fight.snake_mark
	# the snap: from its resting place to its head at his front leg
	var head_x: float = home.x - size.x / 2.0 + float(e.head_tip[0])
	var leg_x: float = _front_leg_x(bearer, home.y - size.y + float(e.head_tip[1]))
	fight.snake = {"node": a, "phase": "idle", "t": 0.0, "idle_for": 1.6, "off": -float(e.rest) * unit,
		"rest": -float(e.rest) * unit, "lunge": leg_x - head_x, "sx": 1.0, "sy": 1.0, "amp": 0.0}
	if point.distance_to(home + mark) > 30.0 * unit:
		push_warning("spell 33: the spear point lands %.0f px from the snake's body" % point.distance_to(home + mark))
	_lunge_place()
	_arena_open()


## The leftmost ink of the bearer's body at height `y` (strip px): his front leg.
func _front_leg_x(bearer: Node2D, y: float) -> float:
	var img: Image = fight.bearer_plain.get_image()
	var top_left: Vector2 = bearer.get_meta("home") + fight.bearer_at
	var row := clampi(int(y - top_left.y), 0, img.get_height() - 1)
	for x in img.get_width():
		if img.get_pixel(x, row).a > 0.35:
			return top_left.x + x + 2.0
	return top_left.x


## For this fight only: the bearer is filled with papyrus (the snake's body passes behind his
## skirt), the snake gets room for its tail to wave, the red mark, and its head drawn in front of him.
func _lunge_dress(e: Dictionary) -> void:
	var bs: Sprite2D = actors[e.spear].get_node("Sprite")
	fight.bearer_plain = bs.texture
	fight.bearer_at = bs.position
	if not _filled.has(e.spear):          # each pose of his, filled (the spear's ends move)
		var frames := []
		for i in sheet.poses.size():
			frames.append(FIGURE_MASK.create_texture(_sheet_frame(e.spear, i, false), 2))
		_filled[e.spear] = frames
	bs.set_meta("filled", _filled[e.spear])
	bs.position -= Vector2(2, 2)
	_bearer_pose(e.spear, _spear_out())
	var fm := ShaderMaterial.new()
	fm.shader = SNAKE_FIGURE
	bs.material = fm
	var a: Node2D = actors[e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	fight.snake_plain = sp.texture
	fight.snake_at = sp.position
	var src := sp.texture.get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var P := SNAKE_PAD
	var img := Image.create(w + 2 * P, h + P, false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(0, 0, w, h), Vector2i(P, P))
	# the mark: where the spear point lands with the snake as drawn, on the nearest bit of body
	var home: Vector2 = a.get_meta("home")
	var point: Vector2 = fight.pos + _tip_offset() + _spear_dir() * CROC_THRUST * unit
	var q := point - (home + sp.position)            # in the picture's pixels
	var best := Vector2i(int(q.x), int(q.y))
	var best_d := INF
	for y in range(maxi(0, int(q.y) - 40), mini(h, int(q.y) + 41)):
		for x in range(maxi(0, int(q.x) - 40), mini(w, int(q.x) + 41)):
			if src.get_pixel(x, y).a > 0.35:
				var d := Vector2(x, y).distance_squared_to(q)
				if d < best_d:
					best_d = d
					best = Vector2i(x, y)
	fight.snake_mark = Vector2(best) + sp.position             # from its pivot
	fight.snake_img = img                                      # unmarked: the mark is painted per strike
	fight.snake_mark_px = best + Vector2i(P, P)
	sp.texture = ImageTexture.create_from_image(img)
	fight.snake_tex = sp.texture
	_lunge_mark()
	sp.position -= Vector2(P, P)
	var mat := ShaderMaterial.new()
	mat.shader = SNAKE_TAIL
	var base: Array = e.tail_base
	mat.set_shader_parameter("base", Vector2(float(base[0]) + P, float(base[1]) + P))
	mat.set_shader_parameter("tail_height", float(base[1]))
	sp.material = mat
	# its head, again, in front of him (the rest of it is behind his skirt)
	var hr: Array = e.head_rect
	var head := Sprite2D.new()
	head.name = "Head"
	head.texture = sp.texture
	head.centered = false
	head.region_enabled = true
	head.region_rect = Rect2(float(hr[0]) + P, float(hr[1]) + P, float(hr[2]), float(hr[3]))
	head.position = fight.snake_at + Vector2(float(hr[0]), float(hr[1]))
	head.z_index = 1
	a.add_child(head)


## The red mark's radius now (plate px): smaller with every strike (`marks`).
func _lunge_mark_r() -> float:
	var marks: Array = fight.e.get("marks", [SNAKE_MARK])
	return float(marks[mini(fight.hits, marks.size() - 1)])


## Paint the red mark onto the snake at its present size (its head shares the texture).
func _lunge_mark() -> void:
	var img: Image = fight.snake_img.duplicate()
	_paint_mark(img, fight.snake_mark_px, _lunge_mark_r() * unit)
	(fight.snake_tex as ImageTexture).update(img)


## The red mark: the body there (both outlines and between them) in red.
static func _paint_mark(img: Image, c: Vector2i, r: float) -> void:
	var red := Color(181 / 255.0, 91 / 255.0, 60 / 255.0)
	var k := 4                                       # closes the gap between the two outlines
	var R := int(ceil(r)) + k + 1
	var x0 := maxi(0, c.x - R)
	var y0 := maxi(0, c.y - R)
	var x1 := mini(img.get_width(), c.x + R + 1)
	var y1 := mini(img.get_height(), c.y + R + 1)
	var w := x1 - x0
	var h := y1 - y0
	var ink := PackedByteArray()
	ink.resize(w * h)
	for y in h:
		for x in w:
			ink[y * w + x] = 1 if img.get_pixel(x0 + x, y0 + y).a > 0.25 else 0
	var grown := PackedByteArray()
	grown.resize(w * h)
	for y in h:
		for x in w:
			if ink[y * w + x]:
				for dy in range(-k, k + 1):
					for dx in range(-k, k + 1):
						var xx := x + dx
						var yy := y + dy
						if xx >= 0 and yy >= 0 and xx < w and yy < h and dx * dx + dy * dy <= k * k:
							grown[yy * w + xx] = 1
	for y in h:
		for x in w:
			if Vector2(x0 + x, y0 + y).distance_to(Vector2(c)) > r or not grown[y * w + x]:
				continue
			var keep := true                         # eroded back: inside the closed shape
			for dy in range(-k, k + 1):
				for dx in range(-k, k + 1):
					var xx := x + dx
					var yy := y + dy
					if dx * dx + dy * dy <= k * k and (xx < 0 or yy < 0 or xx >= w or yy >= h or not grown[yy * w + xx]):
						keep = false
			if keep:
				img.set_pixel(x0 + x, y0 + y, red)


## Undo _lunge_dress.
func _lunge_undress() -> void:
	var e: Dictionary = fight.e
	if fight.has("bearer_plain"):
		var bs: Sprite2D = actors[e.spear].get_node("Sprite")
		bs.remove_meta("filled")
		bs.texture = fight.bearer_plain
		bs.position = fight.bearer_at
		bs.material = null
		_bearer_pose(e.spear, 0.0)
	if fight.has("snake_plain"):
		var a: Node2D = actors[e.foe]
		var sp: Sprite2D = a.get_node("Sprite")
		sp.texture = fight.snake_plain
		sp.position = fight.snake_at
		sp.material = null
		if a.has_node("Head"):
			var head := a.get_node("Head")
			a.remove_child(head)
			head.queue_free()


## Put the snake where it is (its offset from where it is drawn, its squash, its tail).
func _lunge_place() -> void:
	var sn: Dictionary = fight.snake
	var a: Node2D = sn.node
	var home: Vector2 = a.get_meta("home")
	a.position = home + Vector2(sn.off * fight.open, 0.0)
	a.scale = Vector2(sn.sx, sn.sy)
	var mat := (a.get_node("Sprite") as Sprite2D).material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("amp", sn.amp)
		mat.set_shader_parameter("phase", fight.clock * TAU * float(fight.e.wave_hz))


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
	var bs: Sprite2D = actors[nm].get_node("Sprite")
	if bs.has_meta("filled"):
		bs.texture = bs.get_meta("filled")[i]
	else:
		(bs.texture as AtlasTexture).region = Rect2(i * cw, row, cw, ch)
	var ps: Sprite2D = actors[nm + "_pole"].get_node("Sprite")
	(ps.texture as AtlasTexture).region = Rect2((i + sheet.poses.size()) * cw, row, cw, ch)


func _lunge(dt: float) -> void:
	var e: Dictionary = fight.e
	if fight.open < 1.0 or fight.get("closing", false) or fight.lost:
		return
	fight.clock += dt
	if fight.get("bot", false):
		_lunge_bot()
	if fight.thrust >= 0.0 and not fight.pinned:
		fight.thrust += dt
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
	fight.red = maxf(0.0, fight.red - dt)
	var sn: Dictionary = fight.snake
	sn.t += dt
	var breathe := 1.0 + 0.018 * sin(fight.clock * TAU / 1.6)
	match sn.phase:
		"idle":
			sn.off = sn.rest
			sn.sx = 2.0 - breathe
			sn.sy = breathe
			sn.amp = 0.0
			if sn.t >= sn.idle_for:
				_lunge_phase("wave")
		"wave":            # the warning
			var u: float = sn.t / float(e.wave)
			sn.sx = 2.0 - breathe
			sn.sy = breathe
			sn.amp = float(e.tail) * sin(PI * minf(u, 1.0))
			if u >= 1.0:
				sn.amp = 0.0
				_lunge_phase("crouch")
		"crouch":          # it squashes down
			var u := minf(sn.t / float(e.crouch), 1.0)
			var k := u * u * (3.0 - 2.0 * u)
			sn.sx = 1.0 + 0.10 * k
			sn.sy = 1.0 - 0.18 * k
			if sn.t >= float(e.crouch) + 0.1:
				_lunge_phase("snap")
		"snap":            # and springs
			var u := minf(sn.t / float(e.snap), 1.0)
			sn.off = sn.rest + (sn.lunge - sn.rest) * (1.0 - (1.0 - u) * (1.0 - u))
			sn.sx = 1.10 + 0.06 * u
			sn.sy = 0.82 + 0.12 * u
			if _lunge_on_mark():
				_lunge_caught()
			elif u >= 1.0:
				_lunge_bites()
		"bitten":          # its head at his leg a moment
			if sn.t >= 0.4:
				_lunge_phase("back")
		"back", "slink":   # back to where it waits
			var u := minf(sn.t / 0.5, 1.0)
			var k := u * u * (3.0 - 2.0 * u)
			sn.off = sn.get("from", sn.lunge) + (sn.rest - sn.get("from", sn.lunge)) * k
			sn.sx = lerpf(sn.get("sx0", 1.16), 1.0, k)
			sn.sy = lerpf(sn.get("sy0", 0.94), 1.0, k)
			if u >= 1.0:
				_lunge_phase("idle")
				sn.idle_for = rng.randf_range(float(e.idle[0]), float(e.idle[1]))
		"pinned":          # held on the spear point, wriggling
			sn.sx = 1.0 + 0.04 * sin(fight.clock * 40.0)
			sn.sy = 1.0 - 0.04 * sin(fight.clock * 40.0)
			if sn.t >= ROACH_FREEZE:
				fight.pinned = false
				fight.thrust = THRUST_TIME[0] + 0.001          # the spear draws back up
				if fight.hits >= int(e.need):
					end_fight()
					return
				sn.from = sn.off
				sn.sx0 = 1.0
				sn.sy0 = 1.0
				_lunge_phase("slink")
	_lunge_place()
	_place_bearer()


func _lunge_phase(p: String) -> void:
	fight.snake.phase = p
	fight.snake.t = 0.0


## Is the spear point, at or past where it is drawn, on the red mark?
func _lunge_on_mark() -> bool:
	var o := _spear_out()
	if o < 0.0:
		return false
	var sn: Dictionary = fight.snake
	var point: Vector2 = fight.pos + _tip_offset() + _spear_dir() * o * unit
	var mark: Vector2 = sn.node.position + fight.snake_mark * Vector2(sn.sx, sn.sy)
	return point.distance_to(mark) <= (_lunge_mark_r() + SNAKE_GRACE) * unit


func _lunge_caught() -> void:
	var e: Dictionary = fight.e
	fight.hits += 1
	fight.pinned = true
	_hurt(fight.snake.node)
	if fight.hits < int(e.need):
		_lunge_mark()                 # a smaller mark for the next strike
	_lunge_phase("pinned")
	_dev_shot("SHOT_ON_CATCH")
	var left: int = int(e.need) - fight.hits
	say("Scribe", "Struck!" + (" It pulls free and coils again. %d more." % left if left > 0 else ""))


func _lunge_bites() -> void:
	var e: Dictionary = fight.e
	var sn: Dictionary = fight.snake
	sn.off = sn.lunge
	sn.from = sn.lunge
	sn.sx0 = sn.sx
	sn.sy0 = sn.sy
	_lunge_phase("bitten")
	_dev_shot("SHOT_ON_BITE")
	fight.red = 0.8
	fight.health -= 1
	bites += 1
	if fight.health <= 0:
		_lunge_dies()
		return
	# why it got through: a thrust that came and went before it sprang, or one that came too late
	var since: float = fight.clock - fight.last_thrust
	if since < float(e.snap) + 0.6 and since > float(e.snap):
		say("Scribe", "Too early: your spear was already coming back up when it sprang. Wait for the snap.")
	elif since <= float(e.snap):
		say("Scribe", "Too late: it was past the point of your spear.")
	else:
		say("Scribe", "It bit you. When its tail waves and it squashes down, it is about to spring: thrust as it springs.")


## The last bite: he crumbles away, and he is back on the scroll.
func _lunge_dies() -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust.")
	_lunge_undress()
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "lunge" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


## (autotest) From the squash, press Space at `tau` s from the start of the snap; true = struck.
func _lunge_try(tau: float) -> bool:
	var e: Dictionary = fight.e
	var sn: Dictionary = fight.snake
	var hits: int = fight.hits
	fight.thrust = -1.0
	fight.pinned = false
	_lunge_phase("crouch")
	var dt := 1.0 / 240.0
	var t := -(float(e.crouch) + 0.1)
	var pressed := false
	while t < float(e.snap) + 0.4:
		if not pressed and t >= tau:
			pressed = true
			_croc_thrust()
		_lunge(dt)
		t += dt
		if fight.hits > hits or sn.phase == "bitten" or fight.lost:
			break
	return fight.hits > hits


## (autotest) The span of press times (from the start of the snap) that strike; leaves no hit counted.
func _lunge_window() -> Array:
	var lo := INF
	var hi := -INF
	var tau := -0.4
	while tau <= 0.3:
		fight.health = 99
		var hits: int = fight.hits
		if _lunge_try(tau):
			lo = minf(lo, tau)
			hi = maxf(hi, tau)
		fight.hits = hits
		fight.pinned = false
		tau += 0.005
	fight.health = CROC_HEALTH
	return [lo, hi]


## Dev: once per run, a picture of the screen to the path in environment variable `env`.
func _dev_shot(env: String) -> void:
	if OS.has_environment(env) and not has_meta(env):
		set_meta(env, true)
		get_tree().create_timer(0.1).timeout.connect(func():
			get_viewport().get_texture().get_image().save_png(OS.get_environment(env)))


func _lunge_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "Press [space] to thrust the spear, just as the snake springs. You cannot step.")


## Dev (`--croc-bot`): thrusts LUNGE_BOT_AIM s after the snap begins, give or take BOT_JITTER s.
func _lunge_bot() -> void:
	var sn: Dictionary = fight.snake
	if OS.has_environment("BOT_MISS"):      # dev: never thrusts (to see the bite)
		return
	if sn.phase == "crouch" and not fight.has("bot_at"):
		var jitter: float = float(OS.get_environment("BOT_JITTER")) if OS.has_environment("BOT_JITTER") else 0.03
		fight.bot_at = fight.clock + float(fight.e.crouch) + 0.1 + LUNGE_BOT_AIM + rng.randf_range(-jitter, jitter)
	if fight.has("bot_at") and fight.clock >= fight.bot_at:
		fight.erase("bot_at")
		_croc_thrust()

const LUNGE_BOT_AIM := -0.01    ## the middle of the window the autotest measures (s from the snap)


# Apep (spell 39). The vignette opens out, close up; the bearer stands where he is drawn, the point
# of his spear resting a little way up its line from Apep's neck, where the body folds back. Apep
# lies the whole width of the vignette. Now and then his tail lashes and a wave runs the length of
# him toward the fold (apep_wave.gdshader lifts the drawing); his head strains up as it comes. A
# thrust (Space) whose point is down on the fold as the crest reaches it presses the wave flat, and
# the barb rests a step further in; `need` waves and he lies still, the spear as drawn. A wave that
# gets past the point lifts his head out from under it: it rears, turns and bites the bearer's foot.
# Some waves (after the first `teach`) are feints: smaller, they die out in the drawn hump. A thrust
# on a still neck (nothing coming) works the barb loose a step. Bitten CROC_HEALTH times, he
# crumbles and is back on the scroll.
const APEP_WAVE := preload("res://scripts/apep_wave.gdshader")
const APEP_WAVES := 4           ## waves the shader can show at once
const APEP_PAD := 40            ## room above his picture for the waves and his head to rise into (px)
const APEP_FIRST := 1.4         ## the first wave comes this long after the vignette opens (s)
const APEP_FEINT := 0.7         ## a feint's height, of a real wave's
const APEP_PRESS := 0.12        ## a wave pressed down flattens out (s)
const APEP_HOLD := 0.3          ## the spear stays down on a wave pressed flat (s)
const APEP_EARLY := 0.35        ## a thrust this long (or less) before a wave would arrive is only early (s)
const APEP_STRAIN := 0.3        ## his head lifts up to this much as a crest comes under it (rad)
const APEP_LIFT := 0.7          ## a wave got past: his head rears this far (rad)
const APEP_REAR := 0.12         ## ...in this long (s)
const APEP_TURN := 0.1          ## turns round to the bearer's foot (s)
const APEP_SNAP := 35.0         ## and comes this far toward it (plate px)
const APEP_BACK := 0.35         ## and lies down again (s)
const APEP_BOT_LEAD := 0.05     ## (--croc-bot) thrusts this long before a crest reaches the point (s)


func _apep_start(e: Dictionary) -> void:
	# close up: from the caption banner to just under the ground, the whole vignette across
	var cap: Array = level.get("caption", [50.0, 180.0])
	var s := span(e)
	_arena_setup(e, false, [e.foe], {"y0": float(cap[0]) - 12.0 * unit, "y1": ground + 24.0 * unit, "x": (s.x + s.y) / 2.0})
	fight.stand = actors[e.spear].get_meta("home")
	fight.pos = fight.stand
	fight.health = CROC_HEALTH
	fight.clock = 0.0
	fight.pinned = false
	fight.hold = 0.0
	fight.last_thrust = -INF
	fight.waves = []
	fight.launched = 0
	fight.next = APEP_FIRST
	fight.last_arrival = -INF
	fight.last_feint = false
	fight.head = {"phase": "rest", "t": 0.0, "rot": 0.0, "rot0": 0.0, "sx": 1.0, "dx": 0.0}
	_apep_dress(e)
	# where the spear point comes down as drawn, in his picture's pixels
	var a: Node2D = actors[e.foe]
	var left: float = a.get_meta("home").x - a.get_meta("size").x / 2.0
	fight.point_x = (fight.pos + _tip_offset()).x - left
	_apep_place()
	_arena_open()


## For this fight only: room above him for the waves, the wave shader, and his head cut loose so it
## can rear (drawn again on its own, turning on its neck).
func _apep_dress(e: Dictionary) -> void:
	var a: Node2D = actors[e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	fight.apep_plain = sp.texture
	fight.apep_at = sp.position
	var src := sp.texture.get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var P := APEP_PAD
	var whole := Image.create(src.get_width(), src.get_height() + P, false, Image.FORMAT_RGBA8)
	whole.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(0, P))
	var hr: Array = e.head_rect
	var head_r := Rect2i(int(hr[0]), int(hr[1]) + P, int(hr[2]), int(hr[3]))
	var body := whole.duplicate()
	body.fill_rect(head_r, Color(0, 0, 0, 0))
	sp.texture = ImageTexture.create_from_image(body)
	sp.position -= Vector2(0, P)
	var mat := ShaderMaterial.new()
	mat.shader = APEP_WAVE
	sp.material = mat
	var pv: Array = e.head_pivot
	var pivot := Node2D.new()
	pivot.name = "HeadPivot"
	var head := Sprite2D.new()
	head.texture = ImageTexture.create_from_image(whole)
	head.centered = false
	head.region_enabled = true
	head.region_rect = Rect2(head_r)
	head.position = Vector2(float(hr[0]) - float(pv[0]), float(hr[1]) - float(pv[1]))
	pivot.add_child(head)
	a.add_child(pivot)


## Undo _apep_dress.
func _apep_undress() -> void:
	if not fight.has("apep_plain"):
		return
	var a: Node2D = actors[fight.e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	sp.texture = fight.apep_plain
	sp.position = fight.apep_at
	sp.material = null
	if a.has_node("HeadPivot"):
		var pivot := a.get_node("HeadPivot")
		a.remove_child(pivot)
		pivot.queue_free()
	fight.erase("apep_plain")


## How far the waves lift his body at `x` (his picture's pixels), as apep_wave.gdshader does.
func _apep_lift(x: float) -> float:
	var half := float(fight.e.width) * unit
	var h := 0.0
	for w in fight.waves:
		var d: float = (x - w.x) / half
		if absf(d) < 1.0:
			h += w.h * w.amp * 0.5 * (1.0 + cos(PI * d))
	return h


## Show the waves on him and his head where it is.
func _apep_place() -> void:
	if not fight.has("apep_plain"):
		return
	var e: Dictionary = fight.e
	var a: Node2D = actors[e.foe]
	var half := float(e.width) * unit
	var arr := PackedVector4Array()
	for i in APEP_WAVES:
		if i < fight.waves.size():
			var w: Dictionary = fight.waves[i]
			arr.append(Vector4(w.x, w.h * w.amp, half, 0.0))
		else:
			arr.append(Vector4.ZERO)
	((a.get_node("Sprite") as Sprite2D).material as ShaderMaterial).set_shader_parameter("waves", arr)
	var h: Dictionary = fight.head
	var pv := Vector2(float(e.head_pivot[0]), float(e.head_pivot[1]))
	var pivot: Node2D = a.get_node("HeadPivot")
	pivot.position = fight.apep_at + pv + Vector2(h.dx, -_apep_lift(pv.x))
	pivot.scale = Vector2(h.sx, 1.0)
	pivot.rotation = h.rot * (1.0 if h.sx >= 0.0 else -1.0)      # its snout up, whichever way it faces


## Send a wave off from his tail at `v` px/s (a feint dies out in the hump).
func _apep_launch(feint: bool, v: float) -> Dictionary:
	var w := {"x": 0.0, "v": v, "t": 0.0, "s": "lash", "feint": feint, "amp": 0.0,
		"h": float(fight.e.height) * unit * (APEP_FEINT if feint else 1.0)}
	fight.waves.append(w)
	return w


## The next wave, once it is due: faster and closer together as the barb goes in; never reaching the
## point within `min_gap` s of the one before.
func _apep_launch_due() -> void:
	if fight.clock < fight.next or fight.waves.size() >= APEP_WAVES:
		return
	var e: Dictionary = fight.e
	var k := clampf(float(fight.hits) / maxf(1.0, float(e.need) - 1.0), 0.0, 1.0)
	var v := lerpf(float(e.speed[0]), float(e.speed[1]), k) * unit
	var feint: bool = fight.launched >= int(e.teach) and not fight.last_feint and rng.randf() < float(e.feint)
	if not feint:
		var arrive: float = fight.clock + float(e.lash) + fight.point_x / v
		var wait: float = fight.last_arrival + float(e.min_gap) - arrive
		if wait > 0.0:
			fight.next = fight.clock + wait
			return
		fight.last_arrival = arrive
	_apep_launch(feint, v)
	fight.last_feint = feint
	fight.launched += 1
	fight.next = fight.clock + lerpf(float(e.gap[0]), float(e.gap[1]), k)


func _apep(dt: float) -> void:
	if fight.open < 1.0 or fight.get("closing", false) or fight.lost:
		return
	var e: Dictionary = fight.e
	fight.clock += dt
	if fight.get("bot", false):
		_apep_bot()
	fight.red = maxf(0.0, fight.red - dt)
	# was the point down at any time during this frame (a slow frame may step right over it)?
	fight.down = fight.pinned
	if fight.pinned:
		fight.hold -= dt
		if fight.hold <= 0.0:
			fight.pinned = false
			fight.thrust = THRUST_TIME[0] + 0.001          # the spear draws back up, to its new rest
			if fight.hits >= int(e.need):
				end_fight()
				return
	elif fight.thrust >= 0.0:
		var span := _thrust_down_span()
		fight.down = fight.thrust <= span.y and fight.thrust + dt >= span.x
		fight.thrust += dt
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
			if not fight.struck:
				_apep_jab()
	if fight.hits < int(e.need):
		_apep_launch_due()
	_apep_waves(dt)
	_apep_head(dt)
	_apep_place()
	_place_bearer()


## How close to the point a crest is pressed down (px): closer as the barb goes in.
func _apep_reach() -> float:
	var e: Dictionary = fight.e
	var k := clampf(float(fight.hits) / maxf(1.0, float(e.need) - 1.0), 0.0, 1.0)
	return lerpf(float(e.reach[0]), float(e.reach[1]), k) * unit


## The time into a thrust (s) from which, and until which, its point presses a wave down.
func _thrust_down_span() -> Vector2:
	var rest := _spear_rest()
	var deep := CROC_THRUST * THRUST_DOWN
	return Vector2(THRUST_TIME[0] * (deep - rest) / (CROC_THRUST - rest),
		THRUST_TIME[0] + THRUST_TIME[1] * (CROC_THRUST - deep) / (CROC_THRUST - rest))


func _apep_waves(dt: float) -> void:
	var e: Dictionary = fight.e
	var reach := _apep_reach()
	var px: float = fight.point_x
	var down: bool = fight.get("down", false)
	for w in fight.waves.duplicate():
		w.t += dt
		match w.s:
			"lash":            # the tail lashes
				w.amp = minf(w.t / float(e.lash), 1.0)
				if w.t >= float(e.lash):
					w.s = "run"
			"run", "past":
				var x0: float = w.x
				w.x += w.v * dt
				if w.feint:      # dies out in the hump
					w.amp = 1.0 - smoothstep(float(e.hump[0]), float(e.hump[1]), w.x)
					if w.x >= float(e.hump[1]):
						fight.waves.erase(w)
				elif w.s == "past":   # runs out round the fold
					w.amp = clampf(1.0 - (w.x - px - reach) / maxf(1.0, float(e.fold) - px - reach), 0.0, 1.0)
					if w.amp <= 0.0:
						fight.waves.erase(w)
				elif down and x0 <= px + reach and w.x >= px - reach:   # its crest passed under the point
					_apep_pressed(w)
				elif w.x > px + reach:
					w.s = "past"
					_apep_slip(w)
			"pressed":         # flattens under the spear
				w.amp -= dt / APEP_PRESS
				if w.amp <= 0.0:
					fight.waves.erase(w)


func _apep_pressed(w: Dictionary) -> void:
	var e: Dictionary = fight.e
	w.s = "pressed"
	fight.struck = true
	fight.hits += 1
	fight.pinned = true
	fight.hold = APEP_HOLD
	_hurt(actors[e.foe])
	_dev_shot("SHOT_ON_CATCH")
	if fight.hits >= int(e.need):
		for o in fight.waves:
			o.s = "pressed"
		say("Scribe", "Pressed down. Apep lies still.")
	else:
		say("Scribe", "Pressed down: the barb goes in a step.")


## A thrust that pressed nothing down: early for a wave on its way, or else on a still neck.
func _apep_jab() -> void:
	var px: float = fight.point_x
	var coming: bool = fight.waves.any(func(w): return not w.feint and w.s in ["lash", "run"] and px - w.x < w.v * APEP_EARLY)
	if coming:
		say("Scribe", "Too early: wait until the wave reaches your spear point.")
	elif fight.hits > 0:
		fight.hits -= 1
		say("Scribe", "The barb jars on a still neck and works loose a step. Thrust only as a wave reaches the point.")
	else:
		say("Scribe", "Nothing there to press down. Thrust only as a wave reaches the point.")


## A wave got past the point: his head rears out from under it, turns and bites.
func _apep_slip(w: Dictionary) -> void:
	_apep_head_phase("rear")
	var since: float = fight.clock - fight.last_thrust
	if since < APEP_EARLY + 2.0 * _apep_reach() / w.v:
		say("Scribe", "Too early: your spear came and went before the wave reached it.")
	else:
		say("Scribe", "The wave lifted his head from under your spear. When it reaches the point, thrust.")
	fight.next = maxf(fight.next, fight.clock + 0.6)


func _apep_head_phase(p: String) -> void:
	var h: Dictionary = fight.head
	h.phase = p
	h.t = 0.0
	h.rot0 = h.rot


func _apep_head(dt: float) -> void:
	var h: Dictionary = fight.head
	h.t += dt
	match h.phase:
		"rest":          # strains up as a crest comes under it
			var lift := _apep_lift(float(fight.e.head_pivot[0])) / (float(fight.e.height) * unit)
			h.rot = APEP_STRAIN * clampf(lift, 0.0, 1.0)
			h.sx = 1.0
			h.dx = 0.0
		"rear":
			var u := minf(h.t / APEP_REAR, 1.0)
			h.rot = lerpf(h.rot0, APEP_LIFT, u)
			if u >= 1.0:
				_apep_head_phase("turn")
		"turn":          # round to his foot
			var u := minf(h.t / APEP_TURN, 1.0)
			h.sx = lerpf(1.0, -1.0, u)
			h.dx = APEP_SNAP * unit * u
			if u >= 1.0:
				_apep_head_phase("bitten")
				_apep_bites()
		"bitten":
			if h.t >= 0.3:
				_apep_head_phase("back")
		"back":
			var u := minf(h.t / APEP_BACK, 1.0)
			var k := u * u * (3.0 - 2.0 * u)
			h.rot = lerpf(APEP_LIFT, 0.0, k)
			h.sx = lerpf(-1.0, 1.0, k)
			h.dx = lerpf(APEP_SNAP * unit, 0.0, k)
			if u >= 1.0:
				_apep_head_phase("rest")


func _apep_bites() -> void:
	_dev_shot("SHOT_ON_BITE")
	fight.red = 0.8
	fight.health -= 1
	bites += 1
	if fight.health <= 0:
		_apep_dies()


## The last bite: he crumbles away, and he is back on the scroll.
func _apep_dies() -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust.")
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "apep" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


func _apep_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "Press [space] to thrust the spear as a wave reaches its point. You cannot step.")


## Dev (`--croc-bot`): thrusts APEP_BOT_LEAD s before each real crest reaches the point.
func _apep_bot() -> void:
	if OS.has_environment("BOT_MISS") or fight.thrust >= 0.0 or fight.pinned:
		return
	for w in fight.waves:
		if not w.feint and w.s == "run" and (fight.point_x - w.x) / w.v <= APEP_BOT_LEAD:
			_croc_thrust()
			return


## (autotest) A wave at `v` px/s from the tail, Space pressed `tau` s from when its crest would reach
## the point (none if `tau` is INF); true = pressed down. Other waves are held back.
func _apep_try(tau: float, v: float, dt := 1.0 / 240.0) -> bool:
	fight.waves = []
	fight.next = INF
	fight.thrust = -1.0
	fight.pinned = false
	fight.struck = true
	_apep_head_phase("rest")
	var hits: int = fight.hits
	var w := _apep_launch(false, v)
	var arrive: float = float(fight.e.lash) + fight.point_x / v
	var t := 0.0
	var pressed := false
	while t < arrive + 0.5:
		if not pressed and t >= arrive + tau:
			pressed = true
			_croc_thrust()
		_apep(dt)
		t += dt
		if fight.hits > hits or w.s == "past" or fight.lost:
			break
	return fight.hits > hits


## (autotest) The span of press times (from the crest reaching the point) that press a wave at `v`
## down; leaves no hit counted.
func _apep_window(v: float) -> Array:
	var lo := INF
	var hi := -INF
	var tau := -0.4
	while tau <= 0.3:
		fight.health = 99
		var hits: int = fight.hits
		if _apep_try(tau, v):
			lo = minf(lo, tau)
			hi = maxf(hi, tau)
		fight.hits = hits
		tau += 0.005
	fight.health = CROC_HEALTH
	fight.waves = []
	fight.pinned = false
	_apep_head_phase("rest")
	return [lo, hi]


# the snake on the donkey: hit the snake, never the donkey
func _donkey_off() -> float:
	return (-50.0 + 50.0 * sin(fight.t * fight.speed)) * unit


func _donkey(_dt: float) -> void:
	var s: Node2D = actors[fight.foe]
	var off := _donkey_off()
	s.position = s.get_meta("home") + Vector2(off, off * 0.15)
	s.rotation = sin(_time * 6.0) * 0.08
	actors[fight.donkey].rotation = sin(_time * 1.7) * 0.012


func _donkey_click(p: Vector2) -> void:
	if actor_rect(fight.foe).grow(7 * unit).has_point(p):
		fight.hits += 1
		fight.speed += 0.7
		_hurt(actors[fight.foe])
		var need: int = fight.e.need
		if fight.hits < need:
			say("Scribe", "A hit. It slides faster now.")
		_won_if(fight.hits >= need)
	elif actor_rect(fight.donkey).has_point(p):
		fight.hits = maxi(0, fight.hits - 1)
		_shake(actors[fight.donkey])
		say("Scribe", "The donkey brays. Strike the snake, not the donkey.")


# the snake in the sheaf (spell 41). The vignette opens out close up; the bearer stands where he is
# drawn, his spear point resting by the top of the sheaf. The sheaf's four bands are undone (they
# show faintly) and its stalks splay apart; the snake has slipped inside. Where it is, the stalks
# stir (rustle.gdshader). Space, or a click on the sheaf, ties the lowest band still loose; tying
# takes `tie` s, and if the snake is at that band meanwhile it bites through the stalks at his hand
# and the band springs loose. A band tied pulls the stalks together below it, and the snake can
# never come below it again: each band leaves it less room, and it moves faster. Its head shows
# above the sheaf when it is at the top. Once the fourth band is tied it is forced out onto the top
# of the sheaf, coiled as drawn, its head at the point of his spear; it coils a moment, then strikes
# at his hand: a thrust before then pins it. Bitten CROC_HEALTH times, he crumbles.
const SHEAF_BANDS := ["sheaf41_band4", "sheaf41_band3", "sheaf41_band2", "sheaf41_band1"]   ## bottom to top: the order they are tied
const SHEAF_STALKS := "sheaf41_stalks"
const SHEAF_TOP := 4            ## the height above the top band: its head out over the sheaf
const SHEAF_LOOSE := 0.22       ## a band not yet tied shows this faint
const SHEAF_NEAR := 0.75        ## the snake is at a band while it is within this many heights of it
const SHEAF_PEEK := 0.55        ## at the top, this share of its coils shows above the sheaf
const SHEAF_PEEK_X := 0.55      ## the part of its picture that peeks out: from this share of its width
const SHEAF_RISE := 0.5         ## it comes out onto the top (s)
const SHEAF_SNAP := 0.14        ## its strike at his hand (s)
const SHEAF_LUNGE := 14.0       ## how far its head comes at him (plate px)
const SHEAF_DART := 0.35        ## a bite through the stalks: its head out at the band (s)
const SHEAF_LOCK := 0.5         ## after a bite, a band cannot be tied for this long (s)
const SHEAF_STIR := 3.0         ## the stalks' push where it rests (texture px) ...
const SHEAF_STIR_MOVING := 6.0  ## ... and where it is moving
const SHEAF_BOT_REACT := 0.25   ## (--croc-bot) ties this long after the stir settles above the band (s)
const RUSTLE := preload("res://scripts/rustle.gdshader")


func _sheaf_start(e: Dictionary) -> void:
	var cap: Array = level.get("caption", [50.0, 180.0])
	var mid_x: float = (actors[e.spear].get_meta("home").x + actors[e.bundle].get_meta("home").x) / 2.0
	_arena_setup(e, false, [e.foe] + SHEAF_BANDS + [SHEAF_STALKS], {"y0": float(cap[0]) - 12.0 * unit, "y1": ground + 24.0 * unit, "x": mid_x})
	fight.stand = actors[e.spear].get_meta("home")
	fight.pos = fight.stand
	fight.health = CROC_HEALTH
	fight.clock = 0.0
	fight.pinned = false
	fight.last_thrust = -INF
	fight.tied = 0
	fight.tie = -1.0              # s into tying the next band; -1 = not tying
	fight.lock = 0.0
	fight.phase = "bind"          # bind, rise, out, snap, bitten, pinned
	fight.pt = 0.0                # s in this phase
	fight.splay = 1.0 + float(e.splay)
	fight.dart = -1.0             # s into a bite through the stalks; -1 = none
	fight.dart_at = 0
	fight.told = {}
	# it starts at the lowest band, so a band tied at once is bitten: watch the stir first
	fight.sn = {"at": 0.0, "from": 0.0, "to": 0.0, "t": 0.0, "dur": 1.0, "moving": false, "feint": false, "settled": 0.0}
	_sheaf_dress(e)
	_sheaf_place()
	_arena_open()


## For this fight only: the pieces of the sheaf show instead of the bundle, the stalks can stir, and
## the snake can show part of itself (its head over the top, or rising out).
func _sheaf_dress(e: Dictionary) -> void:
	for n in SHEAF_BANDS + [SHEAF_STALKS]:
		actors[n].visible = true
	var mat := ShaderMaterial.new()
	mat.shader = RUSTLE
	(actors[SHEAF_STALKS].get_node("Sprite") as Sprite2D).material = mat
	var a: Node2D = actors[e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	fight.snake_at = sp.position
	var peek := Sprite2D.new()
	peek.name = "Peek"
	peek.texture = sp.texture
	peek.centered = false
	peek.region_enabled = true
	a.add_child(peek)


func _sheaf_undress() -> void:
	var e: Dictionary = fight.e
	for n in SHEAF_BANDS + [SHEAF_STALKS]:
		_restore(n)
		actors[n].visible = false
	(actors[SHEAF_STALKS].get_node("Sprite") as Sprite2D).material = null
	var a: Node2D = actors[e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	sp.region_enabled = false
	sp.visible = true
	if fight.has("snake_at"):
		sp.position = fight.snake_at
	if a.has_node("Peek"):
		var peek := a.get_node("Peek")
		a.remove_child(peek)
		peek.queue_free()


## Tuning value `key` for the bands tied so far: from its first value (no band) to its last (three).
func _sheaf_tune(key: String) -> float:
	var v: Array = fight.e[key]
	return lerpf(float(v[0]), float(v[1]), clampf(float(fight.tied) / 3.0, 0.0, 1.0))


## How long it stays at a height before moving on.
func _sheaf_dwell(at: float) -> float:
	var d: Array = fight.e.dwell
	var k := clampf(float(fight.tied) / 3.0, 0.0, 1.0)
	var lo := lerpf(float(d[0][0]), float(d[1][0]), k)
	var hi := lerpf(float(d[0][1]), float(d[1][1]), k)
	var t := rng.randf_range(lo, hi)
	if is_equal_approx(at, float(fight.tied)):
		t *= 1.0 + float(fight.e.linger)      # it lingers at the lowest it may go
	elif at >= SHEAF_TOP:
		t *= 0.7                              # its head is out only a moment
	return t


## Is the snake at band `j` (bottom band 0)?
func _sheaf_near(j: int) -> bool:
	return absf(fight.sn.at - float(j)) < SHEAF_NEAR


func _sheaf(dt: float) -> void:
	var e: Dictionary = fight.e
	if fight.open < 1.0 or fight.get("closing", false) or fight.lost:
		return
	fight.clock += dt
	fight.pt += dt
	if fight.get("bot", false):
		_sheaf_bot()
	if fight.thrust >= 0.0 and not fight.pinned:
		fight.thrust += dt
		if fight.thrust >= THRUST_TIME[0] + THRUST_TIME[1]:
			fight.thrust = -1.0
	fight.red = maxf(0.0, fight.red - dt)
	fight.lock = maxf(0.0, fight.lock - dt)
	var want := 1.0 + float(e.splay) * float(SHEAF_BANDS.size() - fight.tied) / float(SHEAF_BANDS.size())
	fight.splay = lerpf(fight.splay, want, 1.0 - exp(-8.0 * dt))
	if fight.dart >= 0.0:
		fight.dart += dt
		if fight.dart >= SHEAF_DART:
			fight.dart = -1.0
	match fight.phase:
		"bind":
			_sheaf_move(dt)
			if fight.tie >= 0.0:
				fight.tie += dt
				if _sheaf_near(fight.tied):
					_sheaf_bitten()
				elif fight.tie >= float(e.tie):
					_sheaf_tied()
		"rise":
			if fight.pt >= SHEAF_RISE:
				_sheaf_phase("out")
		"out":             # coiled on top, its head at the spear point; then it strikes
			if _sheaf_struck():
				return
			var coil: float = lerpf(float(e.coil[0]), float(e.coil[1]), float(CROC_HEALTH - fight.health) / float(CROC_HEALTH - 1))
			if fight.pt >= coil:
				_sheaf_phase("snap")
		"snap":
			if _sheaf_struck():
				return
			if fight.pt >= SHEAF_SNAP:
				_sheaf_bites()
		"bitten":
			if fight.pt >= 0.4:
				_sheaf_phase("out")
		"pinned":
			if fight.pt >= ROACH_FREEZE:
				fight.pinned = false
				fight.thrust = THRUST_TIME[0] + 0.001
				end_fight()
				return
	_sheaf_place()
	_place_bearer()


func _sheaf_phase(p: String) -> void:
	fight.phase = p
	fight.pt = 0.0


## The snake moves inside the sheaf: it stays at a height a while, then goes one up or down (never
## below the bands tied; up out of its head over the top). A feint goes halfway up and comes back.
func _sheaf_move(dt: float) -> void:
	var sn: Dictionary = fight.sn
	sn.t += dt
	if sn.moving:
		var u := minf(sn.t / sn.dur, 1.0)
		var k := u * u * (3.0 - 2.0 * u)
		if sn.feint:
			sn.at = sn.from + (sn.to - sn.from) * 0.5 * sin(PI * u)
		else:
			sn.at = lerpf(sn.from, sn.to, k)
		if u >= 1.0:
			sn.at = sn.from if sn.feint else sn.to
			sn.moving = false
			sn.t = 0.0
			sn.settled = 0.0
			sn.dur = _sheaf_dwell(sn.at)
		return
	sn.settled += dt
	if sn.t < sn.dur:
		return
	var lo := float(fight.tied)
	var hi := float(SHEAF_TOP)
	var to: float
	if sn.at <= lo:
		to = sn.at + 1.0
	elif sn.at >= hi:
		to = sn.at - 1.0
	else:
		to = sn.at - 1.0 if rng.randf() < 0.55 else sn.at + 1.0    # it keeps low when it can
	_sheaf_go(to, to > sn.at and fight.tied >= 1 and rng.randf() < float(fight.e.feint))


func _sheaf_go(to: float, feint := false) -> void:
	var sn: Dictionary = fight.sn
	sn.from = sn.at
	sn.to = clampf(to, float(fight.tied), float(SHEAF_TOP))
	sn.feint = feint
	sn.moving = true
	sn.t = 0.0
	sn.dur = _sheaf_tune("move")


## Space, or a click on the sheaf: tie the next band; once the snake is out, thrust.
func _sheaf_act() -> void:
	if fight.open < 1.0 or fight.lost or fight.get("closing", false):
		return
	if fight.phase == "bind":
		if fight.tie >= 0.0 or fight.lock > 0.0:
			return
		fight.tie = 0.0
	else:
		_croc_thrust()


## A band tied: the stalks below it pull together, and the snake can never come below it again.
func _sheaf_tied() -> void:
	fight.tie = -1.0
	fight.tied += 1
	_flash(actors[SHEAF_BANDS[fight.tied - 1]])
	var sn: Dictionary = fight.sn
	if sn.moving and sn.to < float(fight.tied):     # on its way down past the new band: it turns back
		_sheaf_go(float(fight.tied))
	if fight.tied >= SHEAF_BANDS.size():
		fight.sn.moving = false
		fight.sn.at = float(SHEAF_TOP)
		_sheaf_phase("rise")
		say("Scribe", "Bound tight, the sheaf forces the snake out on top.")
	elif not fight.told.has("tied"):
		fight.told.tied = true
		say("Scribe", "Tied. Below that band it has no room now.")


## Tied on the snake: it bites through the stalks at his hand, and the band springs loose.
func _sheaf_bitten() -> void:
	fight.tie = -1.0
	fight.lock = SHEAF_LOCK
	fight.dart = 0.0
	fight.dart_at = fight.tied
	_sheaf_hurt()
	if fight.lost:
		return
	if not fight.told.has("bitten"):
		fight.told.bitten = true
		say("Scribe", "It was at that band: it bites through the stalks, and the band springs loose. Tie only once the stir has settled above it.")
	if fight.sn.at < float(SHEAF_TOP) and not fight.sn.moving:
		fight.sn.t = fight.sn.dur - 0.3          # it draws back up soon after


## His spear point is out and the snake is on top (its head is at the point there): pinned.
func _sheaf_struck() -> bool:
	if fight.thrust < 0.0 or _spear_out() < 0.0:
		return false
	fight.hits = 1
	fight.pinned = true
	_hurt(actors[fight.e.foe])
	_sheaf_phase("pinned")
	say("Scribe", "Struck!")
	return true


## Its strike at his hand, out on top.
func _sheaf_bites() -> void:
	_sheaf_hurt()
	if fight.lost:
		return
	_sheaf_phase("bitten")
	say("Scribe", "It struck first. Thrust ([space]) as soon as it comes out, before it strikes.")


func _sheaf_hurt() -> void:
	fight.red = 0.8
	fight.health -= 1
	bites += 1
	var t := create_tween()
	for i in 6:
		t.tween_property(camera, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)) * unit, 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.05)
	if fight.health <= 0:
		_sheaf_dies()


func _sheaf_dies() -> void:
	fight.lost = true
	fight.tie = -1.0
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust.")
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "sheaf" and fight.e.id == e.id and fight.lost:
			_arena_lost(e))


## The height of band `at` (fractional between bands; SHEAF_TOP is the top of the stalks), strip px.
func _sheaf_y(at: float) -> float:
	var ys: Array = SHEAF_BANDS.map(func(n): return rects[n].get_center().y)
	ys.append(rects[SHEAF_STALKS].position.y)
	var i := clampi(floori(at), 0, ys.size() - 2)
	return lerpf(ys[i], ys[i + 1], clampf(at - i, 0.0, 1.0))


## Put the sheaf (splayed about its bottom tip, the bands tied or faint, the stalks stirring where
## the snake is) and the snake (hidden inside, its head over the top, rising out, or out) as they are.
func _sheaf_place() -> void:
	var e: Dictionary = fight.e
	var k: float = fight.open
	var st: Rect2 = rects[SHEAF_STALKS]
	var tip := Vector2(st.get_center().x, st.end.y)
	var sx: float = lerpf(1.0, fight.splay, k)
	var sn: Dictionary = fight.sn
	var binding: bool = fight.phase == "bind" and not fight.lost
	for i in SHEAF_BANDS.size() + 1:
		var n: String = SHEAF_BANDS[i] if i < SHEAF_BANDS.size() else SHEAF_STALKS
		var a: Node2D = actors[n]
		var home: Vector2 = a.get_meta("home")
		a.position = Vector2(tip.x + (home.x - tip.x) * sx, home.y)
		a.scale = Vector2(sx, 1.0)
		var shown := 1.0
		if i < SHEAF_BANDS.size() and i >= fight.tied:
			shown = SHEAF_LOOSE
			if i == fight.tied and fight.tie >= 0.0:
				shown = lerpf(SHEAF_LOOSE, 1.0, fight.tie / float(e.tie))
			if binding and absf(sn.at - float(i)) < 0.6:     # a loose band shivers with the stalks
				a.position.x += sin(fight.clock * 31.0) * 1.2 * unit
		a.modulate.a = shown * k
	var mat := (actors[SHEAF_STALKS].get_node("Sprite") as Sprite2D).material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("at", clampf((_sheaf_y(sn.at) - st.position.y) / st.size.y, 0.0, 1.0))
		mat.set_shader_parameter("amp", ((SHEAF_STIR_MOVING if sn.moving else SHEAF_STIR) * k) if binding else 0.0)
		mat.set_shader_parameter("phase", fight.clock * 23.0)
	# the snake: on the scroll (k = 0) as drawn; inside the sheaf only its head over the top shows
	var a: Node2D = actors[e.foe]
	var sp: Sprite2D = a.get_node("Sprite")
	var peek: Sprite2D = a.get_node_or_null("Peek")
	var size: Vector2 = a.get_meta("size")
	var top: float = float(e.top)
	a.position = a.get_meta("home")
	a.scale = Vector2.ONE
	sp.region_enabled = true
	match fight.phase:
		"bind":
			sp.visible = k < 1.0
			sp.region_rect = Rect2(0.0, 0.0, size.x, size.y)
			sp.position = fight.snake_at
			a.modulate.a = 1.0 - k if k < 1.0 else 1.0
			var r := clampf(sn.at - float(SHEAF_TOP - 1), 0.0, 1.0) * SHEAF_PEEK * top
			var y_base := top                                  # its coils rise out of the top of the sheaf ...
			if fight.dart >= 0.0:                              # ... or its head comes out at a band, at his hand
				r = sin(PI * fight.dart / SHEAF_DART) * 0.5 * top
				y_base = top + _sheaf_y(float(fight.dart_at)) - _sheaf_y(float(SHEAF_TOP))
			if peek:
				var x0 := SHEAF_PEEK_X * size.x
				peek.visible = r > 0.5 and k >= 1.0
				peek.region_rect = Rect2(x0, 0.0, size.x - x0, r)
				peek.position = fight.snake_at + Vector2(x0, y_base - r)
		"rise":
			if peek:
				peek.visible = false
			sp.visible = true
			a.modulate.a = 1.0
			var r := clampf(fight.pt / SHEAF_RISE, 0.0, 1.0) * size.y
			sp.region_rect = Rect2(0.0, 0.0, size.x, r)
			sp.position = fight.snake_at + Vector2(0.0, maxf(0.0, top - r))
		_:
			if peek:
				peek.visible = false
			sp.visible = true
			a.modulate.a = 1.0
			sp.region_rect = Rect2(0.0, 0.0, size.x, size.y)
			sp.position = fight.snake_at
			var lunge := 0.0
			match fight.phase:
				"snap":
					lunge = minf(fight.pt / SHEAF_SNAP, 1.0)
				"bitten":
					lunge = 1.0 - minf(fight.pt / 0.4, 1.0)
				"out":
					a.scale = Vector2(1.0, 1.0 + 0.02 * sin(fight.clock * TAU / 1.2))   # breathing
				"pinned":
					a.scale = Vector2(1.0 + 0.04 * sin(fight.clock * 40.0), 1.0 - 0.04 * sin(fight.clock * 40.0))
			a.position.x += SHEAF_LUNGE * unit * lunge


func _sheaf_click(p: Vector2) -> void:
	var on_sheaf := false
	for n in SHEAF_BANDS + [SHEAF_STALKS]:
		on_sheaf = on_sheaf or actor_rect(n).grow(10.0 * unit).has_point(p)
	if on_sheaf or fight.phase != "bind":
		_sheaf_act()


## Dev (`--croc-bot`, and the autotest's trials): ties SHEAF_BOT_REACT s (or BOT_REACT) after the
## stir has settled above the next band; out on top, thrusts that long after it comes out. With
## `careless`, it ties as soon as it can, wherever the snake is.
func _sheaf_bot() -> void:
	var react: float = fight.get("bot_react", float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else SHEAF_BOT_REACT)
	var sn: Dictionary = fight.sn
	match fight.phase:
		"bind":
			if fight.tie >= 0.0 or fight.lock > 0.0:
				return
			if fight.get("careless", false):
				if fight.pt - fight.get("bot_last", -1.0) >= 0.5:
					fight.bot_last = fight.pt
					_sheaf_act()
			elif not sn.moving and sn.at > float(fight.tied) + SHEAF_NEAR and sn.settled >= react:
				_sheaf_act()
		"out", "snap":
			if fight.pt >= react or fight.phase == "snap":
				_sheaf_act()


## (autotest) One whole fight against spell 41 played by the bot at reaction `react` (or careless),
## from random seed `seed`; true = won. Leaves the fight stepped out of.
func _sheaf_trial(e: Dictionary, react: float, careless: bool, seed: int) -> bool:
	var b0 := bites
	rng.seed = seed
	start_fight(e)
	fight.bot = true
	fight.bot_react = react
	fight.careless = careless
	var won := false
	var t := 0.0
	while t < 180.0:
		_sheaf(1.0 / 60.0)
		t += 1.0 / 60.0
		if fight.is_empty() or fight.lost:
			won = fight.is_empty()
			break
		if fight.pinned:
			won = true
			break
	if not fight.is_empty():
		leave_fight()
	solved.erase(e.id)
	journal.clear()
	bites = b0
	return won


func _bite(text: String) -> void:
	bites += 1
	say("Scribe", text)
	var t := create_tween()
	for i in 6:
		t.tween_property(camera, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)) * unit, 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.05)


## A thrust where he stands as drawn (the fights where the creature is clicked): his spear only.
func _thrust() -> void:
	var nm: String = fight.e.spear
	var total: float = THRUST_TIME[0] + THRUST_TIME[1]
	create_tween().tween_method(func(t: float): _bearer_pose(nm, _spear_at(t)), 0.0, total, total)


# ---------------------------------------------------------------- helpers

func actor_rect(n: String) -> Rect2:
	var a: Node2D = actors[n]
	var size: Vector2 = a.get_meta("size") * a.scale.abs()
	return Rect2(a.position.x - size.x / 2.0, a.position.y - size.y, size.x, size.y)


## Struck: it flushes red and fades back, as the bearer does when bitten.
func _hurt(n: CanvasItem) -> void:
	create_tween().tween_method(func(v: float): n.modulate = Color(Color.WHITE.lerp(HURT, v), n.modulate.a), 1.0, 0.0, 0.8)


func _flash(n: CanvasItem) -> void:
	var keep := n.modulate
	n.modulate = Color(1.8, 1.4, 0.6, keep.a)
	create_tween().tween_property(n, "modulate", keep, 0.8)


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
		# the opened-out vignette: zoom out to the whole height of the scroll
		var o: float = fight.open
		z = lerpf(z, fight.cam.z, o)
		camera.zoom = Vector2(z, z)
		focus = lerpf(focus, fight.cam.x, o)
		y = lerpf(y, fight.cam.y, o)
		k = 1.0
	camera.position.x = lerpf(camera.position.x, focus, k)
	camera.position.y = y


func _view_height() -> float:
	return level.get("view_height", level.height)


func _visible_rect() -> Rect2:
	return SCROLL_CAMERA.visible_rect(camera, get_viewport_rect().size)


func _draw_overlay() -> void:
	var ink := Color(0.18, 0.11, 0.06)
	if fight.is_empty():
		return
	match fight.kind:
		"creep":
			# where the spear point will come down: a small red dot
			if fight.open >= 1.0 and not fight.lost and not fight.pinned:
				overlay.draw_circle(_creep_point(), CREEP_DOT * unit, Color(181 / 255.0, 91 / 255.0, 60 / 255.0))
	# progress pips above the vignette
	var total := 0
	var got := 0
	match fight.kind:
		"crocs":
			total = _croc_total()
			got = fight.killed
		_:
			total = fight.get("need", fight.e.get("need", 0))
			got = fight.hits
	var sp := span(fight.e)
	if fight.kind in ARENA_FIGHTS:
		sp.y = _arena_rect().end.x
	if fight.kind in ["crocs", "lunge", "creep", "twin", "apep", "sheaf"]:
		# his health: flesh signs in red, top left inside the opened vignette; a lost one stays faint
		var ar := _arena_rect()
		var fs := Vector2(55.0, 68.0)       # on screen, about the size of a caption sign
		if _flesh_tex:
			fs = _flesh_tex.get_size() * (68.0 / _flesh_tex.get_size().y)
		var red := Color(181 / 255.0, 91 / 255.0, 60 / 255.0)
		for i in CROC_HEALTH:
			var at := Vector2(ar.position.x + 40.0 + i * (fs.x + 14.0), ar.position.y + 14.0)
			var a: float = (1.0 if i < fight.health else 0.22) * fight.open
			if _flesh_tex:
				# the picture as given, its dark ink turned red: shown through a red silhouette
				overlay.draw_texture_rect(_flesh_tex, Rect2(at, fs), false, Color(red, a))
			else:
				overlay.draw_circle(at + fs / 2.0, 14.0, Color(red, a))
	if fight.kind in ["lunge", "creep", "twin", "apep", "donkey", "sheaf"]:
		total = 0                      # the snakes show no count (Apep's is the barb going in)
	for i in total:
		var c := Vector2(sp.y - (20.0 + i * 16.0) * unit, 14.0 * unit)
		if fight.kind in ["lunge", "creep"]:      # close up: the top of the scroll is off screen; inside the vignette
			c.y = _arena_rect().position.y + 20.0 * unit
		if i < got:
			overlay.draw_circle(c, 5.0 * unit, Color(0.64, 0.2, 0.12))
		else:
			overlay.draw_arc(c, 5.0 * unit, 0.0, TAU, 16, Color(ink, 0.6), 1.5 * unit)


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
					seen[e.id] = true
					if e.kind == "take":
						actors[e.item].visible = false
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
				c.node.position = Vector2(fight.barrier - 40.0 * unit - _croc_head(c.node, 1).x, fight.y_range.y))
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


func _autotest() -> void:
	var fails: Array[String] = []   # lambdas capture locals by value, so collect into an array
	var expect := func(cond: bool, what: String):
		print(("PASS " if cond else "FAIL ") + what)
		if not cond:
			fails.append(what)
	var centre := func(n: String) -> Vector2: return actor_rect(n).get_center()
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
	expect.call(avatar.min_x > span(e38).x, "... and while the breath of life is not taken")
	expect.call(_take_at(actor_rect(e38.item).get_center()) == e38, "the breath of life can be taken before the way on opens")
	solved.clear()
	_refresh()

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
		match e.kind:
			"crocs":
				var at_tip := func(c: Dictionary) -> void:   # put a snout at the spear tip
					c.s = "crawl"
					c.node.position = fight.pos + _tip_offset() - _croc_head(c.node, c.dir)
				if e.get("tutorial", false):
					_croc_thrust()
					fight.thrust = -1.0
					expect.call(fight.tut == "move", e.id + " lesson: a thrust, then moving")
					fight.moved = 1000.0
					_crocs(0.0)
					expect.call(fight.tut == "first", e.id + " lesson: the first crocodile comes")
					expect.call(not fight.heka_on, e.id + " the heka word does not flash during the lesson")
				# a snout far from the tip is not struck
				var far: Dictionary = fight.crocs.filter(func(c): return c.s == "crawl" or c.s == "wait")[0]
				far.s = "crawl"
				far.node.position = fight.pos + _tip_offset() - _croc_head(far.node, far.dir) + Vector2(-400.0 * unit, 0.0)
				_croc_strike()
				expect.call(fight.killed == 0, e.id + " a crocodile out of reach is not struck")
				# one that reaches the bearer bites, and his body (not the spear) flushes red
				var b0 := bites
				far.node.position = fight.pos + _tip_offset() - _croc_head(far.node, far.dir) + Vector2(200.0 * unit, 0.0)
				_crocs(0.0)
				_place_bearer()
				expect.call(bites == b0 + 1 and fight.red > 0.0, e.id + " a crocodile that reaches him bites")
				expect.call(actors[e.spear].modulate != Color.WHITE and actors[e.spear + "_pole"].modulate == Color.WHITE, e.id + " the body flushes red, the spear does not")
				far.s = "crawl"
				var total := _croc_total()
				var breaks := 0
				var guard := 0
				while fight.killed < total and guard < 400:
					guard += 1
					if fight.phase == "break":
						breaks += 1
						expect.call(fight.heka_on, e.id + " the heka word flashes in the break")
						fight.timer = 0.0
						_crocs(0.0)
						continue
					var cs: Array = fight.crocs.filter(func(x): return x.s == "crawl")
					if cs.is_empty():
						_croc_launch(fight.waves[fight.wave].speed)
						continue
					fight.health = CROC_HEALTH
					var c: Dictionary = cs[0]
					fight.facing = -c.dir      # face it
					at_tip.call(c)
					fight.force_heka = c.red
					_croc_strike()
				fight.force_heka = false
				expect.call(fight.killed == total, e.id + " all %d crocodiles turned back" % total)
				if fight.waves.size() > 1:
					expect.call(breaks == fight.waves.size() - 1, e.id + " a break between the waves")
					expect.call(fight.crocs.any(func(x): return x.red), e.id + " red crocodiles in the second wave")
				var r: Dictionary = fight.crocs[-1]
				(r.node.get_node("Sprite") as Sprite2D).flip_h = r.dir < 0   # (turned round when it was struck)
				fight.facing = -r.dir
				r.red = true
				at_tip.call(r)
				_croc_strike()
				expect.call(r.s == "crawl", e.id + " a plain thrust does nothing to a red crocodile")
				r.node.position += Vector2(0.0, r.node.get_meta("size").y * 1.2)
				fight.force_heka = true
				_croc_strike()
				expect.call(r.s == "crawl", e.id + " only the spear point strikes (the shaft over it does not)")
				r.node.position = fight.pos + _tip_offset() + _spear_dir() * CROC_THRUST * unit \
					- Vector2(_croc_head(r.node, r.dir).x * 0.2, -r.node.get_meta("size").y * 0.4)
				expect.call(_on_croc(r, fight.pos + _tip_offset() + _spear_dir() * CROC_THRUST * unit), e.id + " the point on its body, back from the snout, is on it")
				at_tip.call(r)
				_croc_strike()
				expect.call(r.s == "gone", e.id + " a thrust with heka turns a red crocodile back")
				if e.get("both_sides", false):
					expect.call(fight.crocs.any(func(x): return x.dir < 0), e.id + " crocodiles come from the right as well")
				# one that slips past him goes up and eats the heka word: lost
				fight.force_heka = false
				r.red = false
				r.s = "crawl"
				var low: float = actor_rect(e.spear).end.y + r.node.get_meta("size").y + 60.0 * unit
				if fight.both:      # wholly past him, tail and all (only the snout past: not yet)
					var b := actor_rect(e.spear)
					var half: float = r.node.get_meta("size").x / 2.0
					r.node.position = Vector2(b.end.x + 5.0 - half * 0.9 if r.dir > 0 else b.position.x - 5.0 + half * 0.9, low)
					_crocs(0.0)
					expect.call(not fight.lost and r.s == "crawl", e.id + " no wall: a crocodile only half past him has not got away yet")
					r.node.position = Vector2(b.end.x + half + 5.0 if r.dir > 0 else b.position.x - half - 5.0, low)
				else:
					r.node.position = Vector2(fight.barrier + 5.0, low) - Vector2(_croc_head(r.node, r.dir).x, 0.0)
				_crocs(0.0)
				expect.call(fight.lost and r.s == "thief", e.id + " a crocodile that gets past eats the heka word")
				# heka on an ordinary crocodile loses too: it makes off with the word
				fight.lost = false
				fight.force_heka = true
				fight.facing = -r.dir
				r.s = "crawl"
				(r.node.get_node("Sprite") as Sprite2D).flip_h = r.dir < 0
				at_tip.call(r)
				_croc_strike()
				expect.call(fight.lost and r.s == "thief", e.id + " heka on an ordinary crocodile loses the fight")
				fight.force_heka = false
				# three bites and he crumbles
				fight.lost = false
				fight.tut = ""
				fight.health = CROC_HEALTH
				for i in CROC_HEALTH:
					r.s = "crawl"
					_croc_bites(r)
				expect.call(fight.lost and fight.health <= 0, e.id + " the third bite ends the fight")
				for w in e.waves:
					expect.call(w.get("ramp", 0.0) > 0.0 and w.speed * (1.0 + w.ramp * (w.count - 1)) > w.speed, e.id + " the crocodiles get faster")
				if fight.both:
					# one from the right as close behind one from the left as one from the same side
					# would be: not clear (the other side counts as this side)
					var l: Dictionary = fight.crocs[0]
					var rr: Dictionary = fight.crocs[1]
					for c in fight.crocs:
						c.s = "gone"
					l.s = "crawl"
					l.dir = 1
					l.speed = 300.0
					var lane: float = fight.lanes[0]
					l.node.position = Vector2(fight.pos.x - 600.0 * unit, lane - _croc_head(l.node, 1).y)
					rr.dir = -1
					rr.node.position = Vector2(fight.pos.x + 600.0 * unit, lane - _croc_head(rr.node, -1).y)
					expect.call(not _croc_clear(rr, 300.0), e.id + " the other side counts as this side when spacing them")
					rr.node.position.x = fight.pos.x + 600.0 * unit + 2.0 * rr.node.get_meta("size").x
					expect.call(_croc_clear(rr, 300.0), e.id + " ...and one well behind is clear")
				# the last of a wave is one of the drawn crocodiles squatting on screen; before it, the
				# last one squatting is kept back for it
				_crocs_cleanup()
				for n in _box_actors(e):
					_restore(n)
				fight = {}
				start_fight(e)
				expect.call(fight.wave == 0 and fight.killed == 0, e.id + " a fight taken up again starts from the first wave")
				fight.tut = ""
				fight.wave = fight.waves.size() - 1
				var lw: Dictionary = fight.waves[fight.wave]
				var squat: Array = fight.crocs.filter(func(x): return x.s == "wait")
				for i in range(1, squat.size()):
					squat[i].s = "gone"
				fight.wave_launched = 0
				_croc_launch(lw.speed)
				expect.call(squat[0].s == "wait", e.id + " the last drawn crocodile waits while others come")
				fight.wave_launched = int(lw.count) - 1
				_croc_launch(lw.speed)
				expect.call(squat[0].s == "wait", e.id + " the last of the fight waits until the others are gone")
				for c in fight.crocs:
					if c != squat[0]:
						c.s = "gone"
				_croc_launch(lw.speed)
				expect.call(squat[0].s == "crawl" and not squat[0].red, e.id + " the last of the fight is the drawn one squatting")
				# with as many drawn ones squatting as crocodiles still to come, they all come
				for c in fight.crocs:
					c.s = "gone"
				for c in squat:
					c.s = "wait"
				fight.wave_launched = int(lw.count) - squat.size()
				for i in squat.size():
					for c in fight.crocs:
						if c.s == "crawl":
							c.s = "gone"
					_croc_launch(lw.speed)
				expect.call(squat.all(func(c): return c.s == "crawl" or c.s == "gone"), e.id + " every drawn crocodile has come by the end of the fight")
			"twin":
				var L: Dictionary = fight.snakes[0]
				var R: Dictionary = fight.snakes[1]
				var need := int(e.need)
				expect.call(absf((L.node.position.x - fight.pos.x) + (R.node.position.x - fight.pos.x)) < 1.0, e.id + " a snake on either side of him, mirrored")
				expect.call(L.glyph.position.x < R.glyph.position.x and L.glyph.modulate.a == 1.0 and R.glyph.modulate.a == 1.0, e.id + " the two snake signs, left and right, stay in view as the vignette opens")
				_twin(0.0)
				expect.call(L.node.scale.x < 0.0 and R.node.scale.x > 0.0, e.id + " both turned to face him (the drawn one flipped)")
				expect.call(L.off >= float(e.rest) * unit and absf(L.node.position.x - L.node.get_meta("home").x) >= float(e.rest) * unit - 0.5, e.id + " they wait well out from where they are drawn")
				# the one about to strike: its sign flashes red, it squashes and springs
				fight.idle = 99.0
				_twin_phase(R, "warn")
				_time = PI / 20.0           # the top of the flash
				_twin_place()
				expect.call(R.glyph.modulate.r > 1.5 and L.glyph.modulate == Color.WHITE, e.id + " the sign of the snake about to strike flashes red")
				_twin(_twin_tune("warn") + 0.01)
				expect.call(R.phase == "crouch", e.id + " ...then that snake squashes down")
				_twin_phase(R, "rest")
				# the window: Space at `tau` s from the start of the snap, facing it (sim at 240 fps)
				var good: Array = _twin_window(1)
				print("spell 37 window: %.3f .. %.3f s from the start of the snap (%.0f ms; bot aims at %.3f)" % [good[0], good[1], (good[1] - good[0]) * 1000.0, _twin_aim()])
				expect.call(good[1] - good[0] >= 0.06, e.id + " a window of at least 60 ms to strike in")
				expect.call(_twin_aim() >= good[0] and _twin_aim() <= good[1], e.id + " the bot's aim is inside the window")
				fight.health = 99
				expect.call(not _twin_try(1, -0.35), e.id + " a thrust well before it springs is too early")
				expect.call(not _twin_try(1, 0.3), e.id + " a thrust after it is past is too late")
				expect.call(R.phase == "bitten" and R.off < 0.0, e.id + " at the end of its spring it is past where it is drawn, at his foot")
				_twin(0.41)
				_twin(TWIN_BACK + 0.01)
				expect.call(R.phase == "rest", e.id + " it slides back to where it waits")
				# facing the other way, the thrust strikes nothing and it bites
				fight.health = CROC_HEALTH
				var mid: float = (good[0] + good[1]) / 2.0
				fight.facing = -1
				_twin_phase(R, "crouch")
				R.for = 0.0
				_twin(0.11)
				var t := 0.0
				while R.phase == "snap" and t < 1.0:
					if t >= mid and fight.thrust < 0.0 and not fight.struck:
						_croc_thrust()
					_twin(1.0 / 240.0)
					t += 1.0 / 240.0
				expect.call(R.hits == 0 and fight.health == CROC_HEALTH - 1, e.id + " a thrust the other way strikes nothing, and the snake bites")
				_twin_phase(R, "rest")
				R.off = float(e.rest) * unit
				# a thrust at a snake still coiled: it springs at once
				fight.facing = -1
				fight.thrust = -1.0
				_twin_phase(L, "rest")
				_croc_thrust()
				while fight.thrust >= 0.0 and fight.thrust < THRUST_TIME[0]:
					_twin(1.0 / 240.0)
				expect.call(L.phase == "snap", e.id + " a thrust at a coiled snake: it sees the spear and springs")
				for i in 240:
					_twin(1.0 / 240.0)
				expect.call(L.hits == 0, e.id + " ...out of the spear's way, and bites")
				_twin(0.41)
				_twin(TWIN_BACK + 0.01)
				fight.thrust = -1.0
				# struck `need` times, a snake falls where it is drawn, and only the other strikes after
				for i in need:
					fight.health = CROC_HEALTH
					expect.call(_twin_try(-1, (_twin_window(-1)[0] + _twin_window(-1)[1]) / 2.0), e.id + " struck as it springs (%d)" % (i + 1))
					_twin(ROACH_FREEZE + 0.01)
					if i < need - 1:
						_twin(TWIN_BACK + 0.01)
				_twin(TWIN_FALL + 0.01)
				expect.call(L.phase == "fallen" and absf(L.node.position.x - L.node.get_meta("home").x) < 1.0 and not fight.is_empty(), e.id + " struck %d times, a snake falls where it is drawn" % need)
				var last: Array = _twin_window(1)
				print("spell 37 last window: %.0f ms" % ((last[1] - last[0]) * 1000.0))
				expect.call(last[1] - last[0] < good[1] - good[0] and last[1] - last[0] >= 0.04, e.id + " the window grows shorter with each strike, and can still be struck")
				fight.idle = 0.0
				_twin(0.0)
				expect.call(R.phase == "warn", e.id + " only the snake still coiled strikes")
				fight.health = 1
				_twin_try(1, -0.35)
				expect.call(fight.lost, e.id + " the third bite and he crumbles")
				fight.lost = false
			"creep":
				var snake: CREEPING_SNAKE_STATE = fight.snake
				var x0: float = fight.pos.x
				expect.call(not _creep_in_reach(), e.id + " the snake lies out of reach")
				_creep_move(1.0, 0.5)
				expect.call(fight.pos.x == x0, e.id + " he cannot step back")
				_creep_strike()
				expect.call(fight.hits == 0 and snake.phase == "turn", e.id + " a thrust short of its head strikes the ground, and it turns")
				_creep_phase("away")
				_creep_move(-1.0, 0.2)
				expect.call(fight.pos.x < x0 and snake.phase == "away", e.id + " he creeps up while it looks away")
				_creep_move(-1.0, 60.0)
				expect.call(_creep_in_reach(), e.id + " he stops with the point over its eye")
				# on its head but off the eye: nothing
				var at_eye: float = fight.pos.x
				fight.pos.x = at_eye + (float(e.head_rect[0]) + float(e.head_rect[2]) - float(e.eye[0]) - 2.0)
				expect.call(_creep_on_head() and not _creep_in_reach(), e.id + " the back of its head is on its head, off the eye")
				_creep_phase("away")
				snake.duration = 99.0
				_creep_strike()
				expect.call(fight.hits == 0, e.id + " a thrust on its head but off the eye strikes nothing")
				fight.pos.x = at_eye
				_creep_phase("away")
				# moving while it looks: it lashes back and bites
				_creep_phase("watch")
				snake.elapsed = CREEP_GRACE + 0.01
				snake.duration = 99.0
				fight.pos.x += 5.0 * unit
				var b0 := bites
				_creep_move(-1.0, 0.05)
				expect.call(snake.phase == "strike", e.id + " moving while it looks: it lashes back")
				_creep(CREEP_SNAP + 0.01)
				expect.call(bites == b0 + 1 and fight.health == CROC_HEALTH - 1, e.id + " ...and bites")
				# a thrust while it looks: it lashes back too
				_creep_phase("watch")
				snake.elapsed = CREEP_GRACE + 0.01
				_creep_strike()
				expect.call(snake.phase == "strike" and fight.hits == 0, e.id + " a thrust while it looks: it lashes back")
				snake.offset = _creep_edge_off() + float(e.flee) * unit * (int(e.need) - 1)
				for i in int(e.need) - 1:
					fight.health = CROC_HEALTH
					_creep_phase("away")
					snake.duration = 99.0
					_creep_move(-1.0, 60.0)
					_creep_strike()
					expect.call(fight.hits == i + 1 and snake.phase == "pinned", e.id + " the point on its head strikes it (%d)" % (i + 1))
					_creep(ROACH_FREEZE + 0.01)
					_creep(CREEP_SLIDE + 0.01)
					expect.call(snake.phase == "away" and not _creep_in_reach(), e.id + " struck, it slides on out of reach (%d)" % (i + 1))
				expect.call(snake.offset >= _creep_edge_off() - 0.01, e.id + " it stays inside the vignette")
				fight.health = 1
				_creep_phase("watch")
				snake.elapsed = CREEP_GRACE + 0.01
				_creep_strike()
				_creep(CREEP_SNAP + 0.01)
				expect.call(fight.lost, e.id + " the third bite and he crumbles")
				fight.lost = false
			"lunge":
				var sn: Dictionary = fight.snake
				fight.thrust = THRUST_TIME[0]
				expect.call(not _lunge_on_mark(), e.id + " the coiled snake is out of the spear's reach")
				fight.thrust = -1.0
				# the window: press Space at `tau` s from the start of the snap (sim at 240 fps)
				var good: Array = _lunge_window()
				print("spell 33 window: %.3f .. %.3f s from the start of the snap (%.0f ms)" % [good[0], good[1], (good[1] - good[0]) * 1000.0])
				expect.call(good[1] - good[0] >= 0.06, e.id + " a window of at least 60 ms to strike in")
				expect.call(not _lunge_try(-0.3), e.id + " a thrust well before it springs is too early (bitten)")
				expect.call(not _lunge_try(0.25), e.id + " a thrust after it is past is too late (bitten)")
				expect.call(sn.off > 0.0 and sn.phase == "bitten", e.id + " at full lunge its head is past the drawn spot, at his leg")
				for i in int(e.need) - 1:
					fight.health = CROC_HEALTH
					expect.call(_lunge_try((good[0] + good[1]) / 2.0), e.id + " struck in the middle of the window (%d)" % (i + 1))
					_lunge(ROACH_FREEZE + 0.01)
				expect.call(fight.hits == int(e.need) - 1 and fight.is_empty() == false, e.id + " each strike counts; it coils again")
				var last: Array = _lunge_window()
				print("spell 33 last window: %.0f ms" % ((last[1] - last[0]) * 1000.0))
				expect.call(_lunge_mark_r() < float(e.marks[0]) and last[1] - last[0] < good[1] - good[0], e.id + " the mark (and the moment to strike) grows smaller each strike")
				expect.call(last[1] - last[0] >= 0.03, e.id + " the last mark can still be struck")
				fight.health = 1
				_lunge_try(-0.3)
				expect.call(fight.lost, e.id + " the third bite and he crumbles")
				fight.lost = false
			"roach":
				expect.call(fight.roaches.size() == int(e.count), e.id + " %d beetles" % int(e.count))
				var r: Dictionary = fight.roach
				# a point that misses does nothing; a point on a beetle pins it
				for x in fight.roaches:
					x.darting = false
					_roach_place(x, fight.full.position + Vector2(10.0, 10.0) * unit)
				_roach_place(r, _roach_spear_point(fight.facing) + Vector2(0.0, r.size.y * 2.0))
				_roach_strike()
				expect.call(fight.hits == 0, e.id + " a thrust that misses the beetles does nothing")
				for i in fight.roaches.size():
					var b: Dictionary = fight.roaches[i]
					fight.freeze = 0.0
					fight.facing = 1
					_roach_place(b, _roach_spear_point(-1))
					_roach_strike()
					expect.call(fight.hits == i, e.id + " only the side he faces counts")
					fight.facing = -1
					_roach_strike()
					expect.call(fight.hits == i + 1 and fight.freeze > 0.0 and fight.pinned_roach == b, e.id + " the spear point pins one, and all holds still")
					b.gone = true
					_roach_place(b, fight.full.position)
				expect.call(fight.hits == fight.need, e.id + " every beetle must be pinned")
				# their darts stop by the spear point every few runs
				for x in fight.roaches:
					x.gone = false
					x.passes = -100          # (no losing here)
				var near := 0
				for i in 12:
					r.at_point = false
					_roach_next(r)
					if _roach_touches(r, _roach_spear_point(-1)) or _roach_touches(r, _roach_spear_point(1)) or r.target.distance_to(_roach_spear_point(-1)) < r.size.y or r.target.distance_to(_roach_spear_point(1)) < r.size.y:
						near += 1
				expect.call(near >= 3, e.id + " it often stops by the spear point")
				# one that gets away from the spear point reddens; past `passes` times, the fight is lost
				r.passes = 0
				r.node.modulate = Color.WHITE
				r.at_point = true
				_roach_next(r)
				expect.call(r.passes == 1 and r.node.modulate.r > 1.5 and not fight.lost, e.id + " a beetle that gets away reddens")
				r.passes = int(e.passes)
				r.at_point = true
				_roach_next(r)
				expect.call(fight.lost and fight.copies.size() >= ROACH_SWARM, e.id + " away once too often: they swarm, lost")
				fight.lost = false
				fight.hits = fight.need
			"apep":
				var need := int(e.need)
				var slow: float = float(e.speed[0]) * unit
				var fast: float = float(e.speed[1]) * unit
				expect.call(fight.waves.is_empty() and _spear_out() < 0.0, e.id + " the barb rests drawn back from his neck")
				expect.call(fight.point_x > float(e.hump[1]) and fight.point_x < float(e.fold), e.id + " the spear point is on the fold, past the hump")
				# the window: press Space at `tau` s from the crest reaching the point (sim at 240 fps)
				var good: Array = _apep_window(slow)
				print("spell 39 window: %.3f .. %.3f s from the crest reaching the point (%.0f ms)" % [good[0], good[1], (good[1] - good[0]) * 1000.0])
				expect.call(good[1] - good[0] >= 0.08, e.id + " a window of at least 80 ms for the first waves")
				fight.health = 99
				expect.call(not _apep_try(-0.4, slow), e.id + " a thrust well before the wave arrives misses it")
				expect.call(not _apep_try(0.25, slow), e.id + " a thrust after the wave is past misses it")
				# a wave that gets past: his head rears, turns and bites
				fight.health = CROC_HEALTH
				var b0 := bites
				_apep_try(INF, slow)
				expect.call(fight.head.phase == "rear", e.id + " a wave past the point lifts his head out from under it")
				for i in 15:
					_apep(0.02)
				expect.call(bites == b0 + 1 and fight.health == CROC_HEALTH - 1 and fight.red > 0.0, e.id + " ...and he bites the bearer")
				for i in 45:
					_apep(0.02)
				expect.call(fight.head.phase == "rest", e.id + " ...and lies down again")
				# his head strains up as a crest comes under it
				fight.waves = []
				var hw := _apep_launch(false, slow)
				hw.s = "run"
				hw.amp = 1.0
				hw.x = float(e.head_pivot[0])
				_apep_head(0.0)
				expect.call(fight.head.rot > APEP_STRAIN * 0.9, e.id + " his head lifts as a wave comes under it")
				# a feint dies out in the hump, short of the point: no bite
				fight.waves = []
				var h0: int = fight.health
				var fw := _apep_launch(true, slow)
				for i in 600:
					_apep(1.0 / 120.0)
					if not fw in fight.waves:
						break
				expect.call(not fw in fight.waves and fw.x < fight.point_x and fight.health == h0, e.id + " a feint dies out in the hump, short of the point")
				# a thrust on a still neck works the barb loose a step
				fight.waves = []
				fight.hits = 2
				_croc_thrust()
				_apep(THRUST_TIME[0] + THRUST_TIME[1] + 0.01)
				expect.call(fight.hits == 1, e.id + " a thrust on a still neck works the barb loose a step")
				fight.hits = 0
				# each wave pressed down drives the barb a step in, the waves coming faster
				var mid: float = (good[0] + good[1]) / 2.0
				var rest0 := _spear_rest()
				for i in need - 1:
					fight.health = CROC_HEALTH
					var v := lerpf(slow, fast, float(i) / float(need - 1))
					expect.call(_apep_try(mid, v), e.id + " a wave pressed down (%d)" % (i + 1))
					_apep(APEP_HOLD + 0.01)
				expect.call(fight.hits == need - 1 and not fight.is_empty(), e.id + " each wave pressed counts")
				expect.call(_spear_rest() > rest0 and _spear_rest() < 0.0, e.id + " the barb rests further in with each")
				expect.call(_apep_try(mid, slow, 1.0 / 15.0), e.id + " a thrust in time presses the wave down even at 15 frames a second")
				fight.hits -= 1
				_apep(APEP_HOLD + 0.01)
				var last: Array = _apep_window(fast)
				print("spell 39 fastest window: %.0f ms" % ((last[1] - last[0]) * 1000.0))
				expect.call(last[1] - last[0] >= 0.05 and last[1] - last[0] < good[1] - good[0], e.id + " the last wave is the hardest, and can still be pressed down")
				# the waves come by themselves, faster and closer together, never two at the point at once
				fight.waves = []
				fight.last_arrival = -INF
				var arrivals := []
				for i in 40:           # asked for a wave every 0.1 s
					var before: int = fight.launched
					fight.last_feint = true
					fight.waves = []
					fight.next = fight.clock
					_apep_launch_due()
					if fight.launched > before:
						arrivals.append(fight.last_arrival)
					fight.clock += 0.1
				var gaps_ok := true
				for i in range(1, arrivals.size()):
					gaps_ok = gaps_ok and arrivals[i] - arrivals[i - 1] >= float(e.min_gap) - 0.001
				expect.call(gaps_ok and arrivals.size() >= 3, e.id + " waves reach the point at least min_gap apart")
				fight.waves = []
				fight.next = INF
				# the third bite and he crumbles
				fight.health = 1
				_apep_try(INF, slow)
				for i in 30:
					_apep(0.02)
				expect.call(fight.lost, e.id + " the third bite and he crumbles")
				fight.lost = false
			"donkey":
				fight_click(Vector2(actor_rect(e.donkey).position.x + 20.0 * unit, actor_rect(e.donkey).end.y - 20.0 * unit))
				expect.call(fight.hits == 0, e.id + " striking the donkey scores nothing")
				for i in e.need:
					_donkey(0.0)
					fight_click(centre.call(e.foe))
			"sheaf":
				var sn: Dictionary = fight.sn
				var band := func(i: int) -> Node2D: return actors[SHEAF_BANDS[i]]
				expect.call(actors[SHEAF_STALKS].visible and actors[e.bundle].modulate.a < 0.01, e.id + " the sheaf comes apart into stalks and bands; the bundle steps aside")
				expect.call(SHEAF_BANDS.all(func(n): return actors[n].modulate.a < 0.3) and actors[SHEAF_STALKS].scale.x > 1.2, e.id + " its bands are undone (faint) and its stalks splay")
				expect.call(not (actors[e.foe].get_node("Sprite") as Sprite2D).visible, e.id + " the snake is hidden inside")
				_sheaf(0.0)
				var mat := (actors[SHEAF_STALKS].get_node("Sprite") as Sprite2D).material as ShaderMaterial
				var low: float = (_sheaf_y(0.0) - rects[SHEAF_STALKS].position.y) / rects[SHEAF_STALKS].size.y
				expect.call(mat.get_shader_parameter("amp") > 0.0 and is_equal_approx(mat.get_shader_parameter("at"), low), e.id + " the stalks stir at the bottom band, where it starts")
				# tied on the snake: it bites, the band springs loose
				sn.dur = 99.0
				_sheaf_act()
				_sheaf(0.05)
				expect.call(fight.health == CROC_HEALTH - 1 and fight.tied == 0 and fight.tie < 0.0 and fight.lock > 0.0, e.id + " a band tied on the snake: bitten, and the band springs loose")
				_sheaf_act()
				expect.call(fight.tie < 0.0, e.id + " ...and cannot be tied again at once")
				_sheaf(SHEAF_LOCK + 0.01)
				# tied with the snake above it: it holds, and it can never come below it again
				sn.moving = false
				sn.at = 2.0
				sn.t = 0.0
				sn.dur = 99.0
				_sheaf_act()
				_sheaf(float(e.tie) + 0.02)
				expect.call(fight.tied == 1 and band.call(0).modulate.a > 0.99, e.id + " a band tied above the snake holds")
				_sheaf_go(0.0)
				expect.call(sn.to == 1.0, e.id + " it cannot go below a band tied")
				# a snake coming down onto the band while it is tied bites too
				sn.moving = false
				sn.at = 2.0
				sn.t = 0.0
				sn.dur = 0.05
				var h0: int = fight.health
				_sheaf_act()
				for i in 30:
					_sheaf(0.01)
					if fight.health < h0:
						break
					if not sn.moving and sn.at > 1.5:   # make sure it heads down onto band 1
						sn.t = 99.0
						rng.seed = 2
				expect.call(fight.health < h0 or fight.tied == 2, e.id + " a tie is safe only if it stays above the band throughout")
				fight.health = CROC_HEALTH
				# its head peeks out at the top
				sn.moving = false
				sn.at = float(SHEAF_TOP)
				_sheaf_place()
				expect.call((actors[e.foe].get_node("Peek") as Sprite2D).visible, e.id + " at the top its coils show over the sheaf")
				# bind the rest with the snake at the top: forced out, onto the spear
				while fight.tied < SHEAF_BANDS.size():
					sn.moving = false
					sn.at = float(SHEAF_TOP)
					sn.t = 0.0
					sn.dur = 99.0
					fight.lock = 0.0
					_sheaf_act()
					_sheaf(float(e.tie) + 0.02)
				expect.call(fight.phase == "rise" and SHEAF_BANDS.all(func(n): return actors[n].modulate.a > 0.99), e.id + " four bands tied: the snake is forced out on top")
				_sheaf(SHEAF_RISE + 0.01)
				expect.call(fight.phase == "out" and actors[e.foe].position == actors[e.foe].get_meta("home"), e.id + " out on top, coiled as drawn")
				expect.call(absf(actors[SHEAF_STALKS].scale.x - 1.0) < 0.05, e.id + " bound, the stalks stand as drawn")
				# too slow: it strikes his hand
				h0 = fight.health
				for i in int((float(e.coil[0]) + SHEAF_SNAP + 0.05) * 60.0):
					_sheaf(1.0 / 60.0)
				expect.call(fight.health == h0 - 1 and fight.phase == "bitten", e.id + " too slow: it strikes his hand")
				_sheaf(0.41)
				_croc_thrust()
				_sheaf(THRUST_TIME[0] + 0.01)
				expect.call(fight.pinned and fight.hits == 1, e.id + " a thrust while it is out pins it")
				# the third bite and he crumbles
				leave_fight()
				start_fight(e)
				fight.health = 1
				fight.sn.dur = 99.0
				_sheaf_act()
				_sheaf(0.05)
				expect.call(fight.lost, e.id + " the third bite and he crumbles")
				fight.lost = false
				leave_fight()
				# the difficulty: whole fights played by a stand-in player
				var rate := func(react: float, careless: bool) -> float:
					var won := 0
					for i in 40:
						if _sheaf_trial(e, react, careless, 1000 + i):
							won += 1
					return won / 40.0
				if OS.has_environment("SHEAF_CURVE"):      # dev: the whole curve
					for r in [0.25, 0.35, 0.45, 0.55, 0.65]:
						print("spell 41 curve: react %.2f s -> %d%% won" % [r, rate.call(r, false) * 100])
				var quick: float = rate.call(0.35, false)
				var slow: float = rate.call(0.6, false)
				var careless: float = rate.call(0.0, true)
				print("spell 41 wins: tying 0.35 s after the stir settles %d%%, 0.6 s after %d%%, blindly %d%%" % [quick * 100, slow * 100, careless * 100])
				expect.call(quick >= 0.9, e.id + " an attentive player (0.35 s) wins nearly every fight")
				expect.call(slow <= 0.5, e.id + " a slow one (0.6 s) loses at least half")
				expect.call(careless <= 0.1, e.id + " tying blindly loses")
				start_fight(e)
				fight.pinned = true
		end_fight()  # the real game waits half a second first
		expect.call(solved.has(e.id), e.id + " overcome")

	expect.call(current.is_empty(), "every danger before spell 42 is overcome")
	avatar.position.x = span(ENCOUNTERS[-1]).y - 50.0 * unit
	_check_position()
	expect.call(finished, "level finished at spell 42")
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
