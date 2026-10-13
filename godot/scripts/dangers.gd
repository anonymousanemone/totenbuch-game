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

const DATA_PATH := "res://assets/dangers/level.json"
const ASSET := "res://assets/dangers/%s.png"
const BESIDE := 50.0
const APEP_SLICES := 5
const FIGHTS := ["crocs", "lunge", "rear", "slither", "roach", "apep", "donkey", "pop"]
const ARENA_FIGHTS := ["crocs", "roach", "lunge"]   ## the vignette opens out across the screen
const CLICK_TO_FIGHT := "Click the creature to take up the spear."

## Encounters in play order. `boxes` are vignette frames from level.json; `spear` is the
## vignette's spear-bearer, who stands in for the player during the fight.
const ENCOUNTERS := [
	# crocodiles: `count` is how many must be turned back in all (the four drawn ones, then copies
	# of them); `speed` in plate px per second; `at_once` how many crawl at the same time; `red` the
	# chance that a crocodile comes red (only a thrust made while holding Shift turns those back; heka on
	# an ordinary one loses the fight); `both_sides` they come from left and right, and he turns
	{"id": "e31", "boxes": ["e31"], "kind": "crocs", "spear": "spear31", "task": 0, "tutorial": true,
		"foes": ["c31a", "c31b", "c31c", "c31d"], "first_speed": 120.0, "break": 6.0,
		# `waves` instead of one count: the lesson, a break while the heka word starts to flash, then
		# a wave with red ones (`red_order`: which launches come red, in order). Losing (heka on an
		# ordinary crocodile) starts again from the wave after the last break.
		"waves": [
			{"count": 3, "speed": 160.0, "interval": 3.0, "at_once": 1},
			{"count": 6, "speed": 190.0, "interval": 2.2, "at_once": 2, "red_order": [false, true, false, true, true, false]},
		],
		"intro": "Spell 31: crocodiles come to take your magic. The vignette opens out, and you are its spear-bearer; Space then thrusts the spear.",
		"hint": "Move up or down (↑ ↓ or W S) until the spear tip is level with the coming snout, and press Space as they touch.",
		"won": "The crocodiles turn away.",
		"label": "Crocodiles of spell 31", "note": "They come to take the magic of the deceased. Turned back with the spear."},
	{"id": "e32", "boxes": ["e32"], "kind": "crocs", "spear": "spear32", "task": 0,
		"foes": ["c32a", "c32b", "c32c", "c32d"], "both_sides": true,
		# harder than 31 and losable, but always possible: each crocodile is `ramp` faster than the
		# one before (210 -> about 420), and none reaches him within `min_gap` s of the one before
		"waves": [{"count": 14, "speed": 210.0, "ramp": 0.077, "interval": 0.8, "at_once": 2, "red": 0.35, "min_gap": 0.9}],
		"intro": "Spell 32: crocodiles from the four quarters of the sky, from both sides now, faster and two at a time. ← → turn you to face either way; ↑ ↓ move you.",
		"hint": "Turn to face the nearer crocodile (← →), bring the spear tip level with its snout (↑ ↓), then Space.",
		"won": "The crocodiles of the four quarters are turned back.",
		"label": "Crocodiles of spell 32", "note": "One for each quarter of the sky. Turned back two at a time."},
	# the lunging snake: it waits `rest` back from where it is drawn (out of reach) for `idle` s,
	# waves its tail (`wave` s, `tail` rad, `wave_hz`), squashes down (`crouch` s) and springs
	# (`snap` s) to his front leg. `head_tip`, `head_rect`, `tail_base`: in its picture's pixels.
	{"id": "e33", "boxes": ["e33"], "kind": "lunge", "spear": "spear33", "task": 1,
		"foe": "snake33", "need": 3, "rest": 33.0, "idle": [1.2, 2.4], "wave": 1.4, "tail": 0.26, "wave_hz": 2.2,
		"crouch": 0.35, "snap": 0.16, "head_tip": [122, 218], "head_rect": [68, 205, 58, 25], "tail_base": [28, 172],
		"intro": "Spell 33: a snake coils just out of reach of your spear. When its tail waves, it is about to spring. Press Space as it springs, so the spear point comes down on the red mark. Three times.",
		"hint": "Watch the tail wave, then the squash: thrust (Space) the moment it springs. Too early and your spear is already coming back up.",
		"won": "The snake falls.",
		"label": "The lunging snake", "note": "Spell 33, against a snake. Struck three times as it sprang."},
	{"id": "e35", "boxes": ["e35"], "kind": "slither", "spear": "spear35", "task": 1,
		"foe": "snake35", "need": 2,
		"intro": "Spell 35: a snake slides along the ground, in and out of the spear's reach.",
		"hint": "Click the snake when it slides up to the spear tip.",
		"won": "The snake on the ground lies still.",
		"label": "The snake on the ground", "note": "Spell 35. Struck twice when it came within reach."},
	# the roach: caught `need` times by the spear point; it darts at `dart` (plate px/s), rests
	# `rest` s, and every `bait_every` darts stops by the spear point for `bait_rest` s (a `fake`
	# share of those just out of reach), within `range` either side of him; `dot`: only a red dot
	# on its back counts
	{"id": "e36", "boxes": ["e36"], "kind": "roach", "spear": "spear36", "task": 1,
		"foe": "beetle36", "need": 1, "dart": 1100.0, "rest": [0.15, 0.5], "bait_every": 2,
		"bait_rest": [0.35, 0.75], "fake": 0.3, "range": 480.0, "dot": false,
		"intro": "Spell 36: the Apshai beetle, quicker than the eye. The vignette opens out. You cannot step: ← → turn you, and Space thrusts. Only the point of the spear, thrust out, catches it.",
		"hint": "Watch where it stops. When it pauses at the point of your spear, turn to it and thrust.",
		"won": "The beetle is pinned.",
		"label": "The Apshai beetle", "note": "Spell 36. Pinned with the point of the spear."},
	{"id": "e37", "boxes": ["e37"], "kind": "rear", "spear": "spear37", "task": 1,
		"foe": "snake37", "need": 2, "coil": 0.9, "rise": 0.35, "window": 0.55,
		"intro": "Spell 37: the two Merti snakes, coiled together. They rear up and strike. Hit them twice while they stand at full height.",
		"hint": "Click the moment they stand fully upright.",
		"won": "The two Merti snakes fall.",
		"label": "The two Merti snakes", "note": "Spell 37. They rear quicker; struck twice at full height."},
	{"id": "e38", "boxes": ["e38"], "kind": "take", "item": "breath38", "task": 2, "gate": true,
		"intro": "Spell 38, for living on air. He holds out the ankh and the sail, the signs of life and breath.",
		"hint": "Click the ankh and sail he holds out.",
		"won": "You take the breath of life. The sail sign returns in later scenes.",
		"label": "The breath of life", "note": "Spell 38, for living on air. The ankh and sail taken from his hand."},
	{"id": "e39", "boxes": ["e39"], "kind": "apep", "spear": "spear39", "task": 3,
		"foe": "apep", "raise": 1.0,
		"intro": "Spell 39: Apep, the great serpent, stretches across the ground. One coil at a time rises. Strike the coil that rises, and only that one.",
		"hint": "Wait for a coil to lift, then click it. Striking a coil that lies flat lets a wounded coil heal.",
		"won": "Apep is pinned to the ground.",
		"label": "Apep", "note": "Spell 39, repelling Apep. Each coil struck as it rose."},
	{"id": "e40", "boxes": ["e40"], "kind": "donkey", "spear": "spear40", "task": 4,
		"foe": "snake40", "donkey": "donkey40", "need": 3,
		"intro": "Spell 40: the Eater of the Ass, a snake on the donkey's back. Strike the snake three times. Do not strike the donkey.",
		"hint": "The snake slides along the donkey's back. Click the snake itself; a miss hits the donkey.",
		"won": "The snake falls from the donkey's back.",
		"label": "The Eater of the Ass", "note": "Spell 40. Struck three times; the donkey spared."},
	{"id": "e41", "boxes": ["e41"], "kind": "pop", "spear": "spear41", "task": 5,
		"foe": "heads41", "bundle": "bundle41", "need": 3,
		"intro": "Spell 41: heads rise from the bundle of reeds and sink again. Strike them while they are up.",
		"hint": "Click the heads while they show above the reeds.",
		"won": "Nothing rises from the reeds any more.",
		"label": "The heads in the reeds", "note": "Spell 41. Struck three times as they rose."},
	{"id": "e42", "boxes": ["e42"], "kind": "end",
		"intro": "Spell 42 is a list, not a picture: each part of the body is given to a god."},
]

const TASKS := [
	"Turn back the crocodiles (31–32)",
	"Spear the snakes and the beetle (33–37)",
	"Take the breath of life (38)",
	"Overcome Apep (39)",
	"Save the donkey from the snake (40)",
	"Strike the heads in the reeds (41)",
	"Reach spell 42",
]

var level: Dictionary
var unit := 1.0          ## strip px per plate px at 200 dpi (level.json `scale`)
var ground := 248.0      ## the line the figures stand on (level.json `ground`)
var rects := {}          ## sprite name -> Rect2 as drawn on the plate
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
var _roach_need := -1     ## dev: overrides the roach's `need` when set (ROACH_NEED)
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
var _croc_checkpoint := {}     ## crocodile encounter id -> the wave a lost fight starts again from
var _told_unsolved := -10.0   ## when the end of the scroll last said what is still undone
var gate := {}           ## a "gate" encounter (spell 38) not to be entered while one before it is undone
var _bump_time := -10.0
var _hover := []                ## the actors glowing under the pointer

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD
@onready var overlay: Node2D = $Overlay


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
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
		if n == "avatar" or n == "apep":
			continue
		actors[n] = _make_actor(load(ASSET % n), rects[n])
	# Apep is cut into coils so one can rise at a time
	var apep_tex: Texture2D = load(ASSET % "apep")
	var r: Rect2 = rects.apep
	var w := r.size.x / APEP_SLICES
	for i in APEP_SLICES:
		var at := AtlasTexture.new()
		at.atlas = apep_tex
		at.region = Rect2(i * w, 0, w, r.size.y)
		actors["apep%d" % i] = _make_actor(at, Rect2(r.position.x + i * w, r.position.y, w, r.size.y))

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
			+ "The scroll reads [b]right to left[/b]. Click the papyrus to walk, or use ← →. Click a creature to walk into its vignette and become its spear-bearer; the scribe tells you that creature's rule. Some vignettes open out across the whole scroll: there [b]Space[/b] thrusts the spear (hold [b]Shift[/b] for heka) and the arrow keys move or turn you. Elsewhere, click the creature to strike.\n\n"
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
	_croc_checkpoint.clear()
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
		actors[n].visible = not n.begins_with("spear")
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
	# he walks through every vignette (a fight starts only on clicking its creature), except into a gate vignette
	# while one before it is still undone
	gate = {}
	for e in ENCOUNTERS:
		if e.get("gate", false) and not current.is_empty() and ENCOUNTERS.find(current) < ENCOUNTERS.find(e):
			gate = e
			break
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
		if e.kind == "take" and not solved.has(e.id) and e != gate and actor_rect(e.item).grow(12 * unit).has_point(p):
			return e
	return {}


## The right-hand edge of the gate vignette, which he cannot pass into yet (0 when open).
func gate_x() -> float:
	return span(gate).y if not gate.is_empty() else 0.0


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
	say("Scribe", "The breath of life is given only once every danger before it is overcome. Still to do: spell %s." % current.id.trim_prefix("e"))


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking() or finished:
		return
	# Space thrusts in the fights that open out (holding Shift lends the thrust heka)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if not fight.is_empty() and fight.kind in ARENA_FIGHTS:
			_croc_thrust()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		_set_hover(_hover_at(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		for nm in _all_heka():
			if actors[nm].modulate.a > 0.5 and actor_rect(nm).grow(6 * unit).has_point(p):
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
		sp.add_child(g)
	var t := create_tween()
	t.tween_method(func(v: float): (g.material as ShaderMaterial).set_shader_parameter("strength", v),
		(g.material as ShaderMaterial).get_shader_parameter("strength"), 1.0 if on else 0.0, 0.15)


## The creatures you click to take up the spear against encounter `e`.
func _creatures(e: Dictionary) -> Array:
	if e.kind == "apep":
		return range(APEP_SLICES).map(func(i): return "apep%d" % i)
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
		"crocs", "roach", "lunge": return []
		"apep": return range(APEP_SLICES).map(func(i): return "apep%d" % i)
		"donkey": return [fight.foe, fight.donkey]
		"pop": return [fight.foe, fight.bundle]
	return [fight.foe]


func _process(delta: float) -> void:
	_time += delta
	if not finished and fight.is_empty():
		_check_position()
	if not fight.is_empty():
		_update_fight(delta)
	_update_camera(delta)
	hud.update_minimap(avatar.position.x, _visible_rect(), gate_x(), not gate.is_empty())
	overlay.queue_redraw()
	if not fight.is_empty() and fight.kind == "crocs":
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
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
	fight = {"kind": e.kind, "e": e, "t": 0.0, "hits": 0}
	match e.kind:
		"crocs":
			_crocs_start(e)
		"rear":
			fight.foe = e.foe
			fight.phase = "coiled"
		"roach":
			_roach_start(e)
		"lunge":
			_lunge_start(e)
		"slither":
			fight.foe = e.foe
			fight.spot = 0
			fight.step = 0
			fight.planted = -1
		"apep":
			fight.foe = "apep"
			fight.raised = -1
			fight.pinned = []
			for i in APEP_SLICES:
				fight.pinned.append(false)
		"donkey":
			fight.foe = e.foe
			fight.donkey = e.donkey
			fight.speed = 1.4
		"pop":
			fight.foe = e.foe
			fight.bundle = e.bundle
			fight.up = false
			fight.wait = 0.9
			actors[e.foe].modulate.a = 0.0
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


func _update_fight(dt: float) -> void:
	fight.t += dt
	match fight.kind:
		"crocs": _crocs(dt)
		"rear": _rear(dt)
		"slither": _slither(dt)
		"roach": _roach(dt)
		"lunge": _lunge(dt)
		"apep": _apep(dt)
		"donkey": _donkey(dt)
		"pop": _pop(dt)


func fight_click(p: Vector2) -> void:
	if not fight.kind in ARENA_FIGHTS:
		_thrust()
	match fight.kind:
		"crocs": _crocs_click(p)
		"rear": _rear_click(p)
		"slither": _slither_click(p)
		"roach": _roach_click(p)
		"lunge": _lunge_click(p)
		"apep": _apep_click(p)
		"donkey": _donkey_click(p)
		"pop": _pop_click(p)


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
const CROC_PREP := 16.0         ## the spear rests drawn back (raised) this far along its line
const CROC_THRUST := 10.0       ## a thrust reaches this far past the spear's drawn position
const CROC_REACH := 20.0        ## the point also counts this close to the snout (plate px)
const CROC_SAME_SPOT := 1.0     ## two from one side at nearly one height reach him at least this far apart (s)
const CROC_FRONT_OVERLAP := 0.15   ## how far (of their height) two front halves may overlap above and below
const CROC_GRACE := 5.0         ## the spear point counts this close outside a crocodile's outline (plate px)
const CROC_LANE := 70.0         ## spacing of the heights the crocodiles come at
const BEARER_SPEED := 260.0     ## how fast the bearer moves
const CROC_HEALTH := 3           ## bites he can take; the last one and he crumbles (the fight starts over)
const CROC_FORWARD := 30.0      ## in one-sided fights he stands this far in front of where he is drawn
const THRUST_TIME := [0.07, 0.18]   ## out, back
## Red is #B55B3C. The sprites are drawn in ink (46, 29, 16), so the modulate that turns ink into
## that red is the ratio of the two.
const RED_CROC := Color(181.0 / 46.0, 91.0 / 29.0, 60.0 / 16.0)   ## red crocodiles, heka word and spear
const HURT := RED_CROC                      ## the bearer's body when bitten
const DISSOLVE := preload("res://scripts/dissolve.gdshader")
const GLOW := preload("res://scripts/glow.gdshader")
const TEXT_DROP := 320.0        ## how far the text below drops while the vignette is open
const HEKA_TEXT := "Heka: the magic of the gods; these signs name it. Hold Shift as you thrust (Space), and the spear carries heka: it turns back a red crocodile. Never use it on an ordinary one: that one would seize the word and make off with it."


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
	var sp: Dictionary = level.spears[e.spear]
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
	fight.wave = _croc_checkpoint.get(e.id, 0)
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
	if fight.kind == "roach" and not fight.roach.darting:
		_roach_place(fight.roach.home_c.lerp(fight.roach.c0, k))
	if fight.kind == "lunge":         # it draws back from where it is drawn to where it waits
		_lunge_place()
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
	# the spear rests drawn back; a thrust runs it out past its drawn position and back
	var o := _spear_out()
	actors[e.spear + "_pole"].position += _spear_dir() * o * unit * fight.open
	# bitten: the body flushes red; heka: the spear is red (each on its own)
	actors[e.spear].modulate = Color.WHITE.lerp(HURT, clampf(fight.red / 0.8, 0.0, 1.0))
	actors[e.spear + "_pole"].modulate = RED_CROC if Input.is_key_pressed(KEY_SHIFT) and fight.open >= 1.0 else Color.WHITE


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
				say("Scribe", "Here one comes. Meet its snout with the spear tip, and press Space as they touch.")
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
	_croc_checkpoint[e.id] = fight.wave + 1
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


func _all_heka() -> Array:
	var out := []
	var h = level.get("heka", {})
	for id in (h if h is Dictionary else {}):
		out.append_array(h[id])
	return out


func _croc_total() -> int:
	var n := 0
	for w in fight.waves:
		n += int(w.count)
	return n


## Heka thrust at an ordinary crocodile: it takes the word of heka from the banner and runs.
func _croc_steals(c: Dictionary) -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "Heka spent on an ordinary crocodile! It seizes the word of power and makes off with it. The crocodiles are not turned back: begin again.")
	c.s = "thief"
	var a: Node2D = c.node
	a.rotation = 0.0
	c.dir = -c.dir
	(a.get_node("Sprite") as Sprite2D).flip_h = c.dir < 0
	var away: float = (fight.full.position.x - 200.0 * unit) if c.dir < 0 else (fight.full.end.x + 200.0 * unit)
	var dx := away - a.position.x
	var t := create_tween()
	for nm in _heka_words(e.id):        # the word flies down into its jaws
		var w: Node2D = actors[nm]
		t.parallel().tween_property(w, "position", _snout(c) + Vector2(0.0, actor_rect(nm).size.y), 0.5)
		w.modulate = RED_CROC
	t.tween_callback(func(): _disintegrate(e))     # the moment the word is in its jaws, he crumbles
	t.tween_interval(0.2)
	t.tween_property(a, "position:x", a.position.x + dx, 1.4)
	for nm in _heka_words(e.id):
		t.parallel().tween_property(actors[nm], "position:x", _snout(c).x + dx, 1.4)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "crocs" and fight.e.id == e.id and fight.lost:
			_crocs_close(func(): _crocs_restart(e)))


## A crocodile got past the bearer to the wall: it laughs (squashes up and down), the heka word
## tumbles down from the banner onto its back, it turns round and leaves with it, and the
## spear-bearer crumbles away. Lost.
func _croc_eats_word(c: Dictionary) -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "A crocodile slipped past you to the wall. It laughs, and the word of heka falls to it. Begin again.")
	c.s = "thief"
	var a: Node2D = c.node
	a.rotation = 0.0
	var size: Vector2 = a.get_meta("size")
	var words: Array = _heka_words(e.id)
	var t := create_tween()
	# it laughs
	for i in 4:
		t.tween_property(a, "scale", Vector2(1.06, 0.78), 0.1)
		t.tween_property(a, "scale", Vector2(0.96, 1.12), 0.1)
	t.tween_property(a, "scale", Vector2.ONE, 0.08)
	# the word tumbles down onto its back
	var back := a.position + Vector2(0.0, -size.y * 0.8)
	for nm in words:
		var w: Node2D = actors[nm]
		w.modulate = RED_CROC
		t.parallel().tween_property(w, "position", back, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(w, "rotation", TAU * 1.5, 0.7)
	for nm in words:      # a little bounce as it lands
		t.parallel().tween_property(actors[nm], "position:y", back.y - 14.0 * unit, 0.1).set_delay(0.7)
		t.parallel().tween_property(actors[nm], "position:y", back.y, 0.1).set_delay(0.8)
	t.tween_callback(func(): _disintegrate(e))     # the moment the word lands, he crumbles
	t.tween_interval(0.3)
	# it turns round and leaves with it
	t.tween_callback(func():
		c.dir = -c.dir
		(a.get_node("Sprite") as Sprite2D).flip_h = c.dir < 0)
	var away: float = (fight.full.position.x - size.x) if c.dir > 0 else (fight.full.end.x + size.x)
	var dx := away - a.position.x
	t.tween_property(a, "position:x", a.position.x + dx, 2.0)
	for nm in words:
		t.parallel().tween_property(actors[nm], "position:x", back.x + dx, 2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "crocs" and fight.e.id == e.id and fight.lost:
			_crocs_close(func(): _crocs_restart(e)))


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


## The last bite: he crumbles away and the fight starts over.
func _croc_dies(c: Dictionary) -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust. Begin again.")
	c.s = "thief"
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "crocs" and fight.e.id == e.id and fight.lost:
			_crocs_close(func(): _crocs_restart(e)))


## The spear-bearer crumbles away (scripts/dissolve.gdshader).
func _disintegrate(e: Dictionary) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = DISSOLVE
	mat.set_shader_parameter("grain", 3.0 * unit)
	for nm in [e.spear, e.spear + "_pole"]:
		(actors[nm].get_node("Sprite") as Sprite2D).material = mat
	create_tween().tween_method(func(v: float): mat.set_shader_parameter("amount", v), 0.0, 1.05, 1.6)


func _crocs_restart(e: Dictionary) -> void:
	_crocs_cleanup()
	for n in _box_actors(e):
		_restore(n)
	fight = {}
	start_fight(e)
	say("Scribe", "Begin again from where the crocodiles came back. The red signs above still glow.")


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


## Send the next crocodile: one of the drawn ones still waiting, else a copy of one of the four
## (from either side when the fight has crocodiles on both sides).
func _croc_launch(speed: float) -> bool:
	var e: Dictionary = fight.e
	var w: Dictionary = fight.waves[fight.wave]
	if fight.wave_launched >= w.count:
		return false
	var order: Array = w.get("red_order", [])
	var red: bool = order[fight.wave_launched] if fight.wave_launched < order.size() else rng.randf() < w.get("red", 0.0)
	var waiting: Array = fight.crocs.filter(func(c): return c.s == "wait")
	var c: Dictionary
	if not waiting.is_empty() and not red:       # the drawn crocodiles first (never red)
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
			say("Scribe", "One comes from behind! ← → turn you to face either way.")
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
## allowed), and two from the same side at nearly the same height reach him CROC_SAME_SPOT s apart.
func _croc_clear(c: Dictionary, speed: float) -> bool:
	var t_c := absf(fight.pos.x - _snout(c).x) / (speed * unit)
	for o in fight.crocs:
		if o == c or o.s != "crawl":
			continue
		var t_o: float = absf(fight.pos.x - _snout(o).x) / (o.speed * unit)
		if o.dir == c.dir and absf(_snout(o).y - _snout(c).y) < CROC_LANE * unit * 1.5 and absf(t_c - t_o) < CROC_SAME_SPOT:
			return false
		var t := 0.0
		while t <= minf(t_c, t_o):
			var a := _croc_front(c, c.node.position + Vector2(c.dir * speed * unit * t, 0.0))
			var b := _croc_front(o, o.node.position + Vector2(o.dir * o.speed * unit * t, 0.0))
			if a.intersects(b):
				return false
			t += 0.1
	return true


## The front half of crocodile `c` (snout to middle) with its pivot at `pos`, trimmed a little above
## and below.
func _croc_front(c: Dictionary, pos: Vector2) -> Rect2:
	var size: Vector2 = c.node.get_meta("size")
	var trim := size.y * CROC_FRONT_OVERLAP
	return Rect2(pos.x if c.dir > 0 else pos.x - size.x / 2.0, pos.y - size.y + trim, size.x / 2.0, size.y - 2.0 * trim)


func _croc_thrust() -> void:
	if fight.thrust >= 0.0 or fight.open < 1.0 or fight.lost:
		return
	fight.thrust = 0.0
	fight.struck = false
	fight.last_thrust = fight.get("clock", 0.0)
	if fight.tut == "thrust":
		fight.tut = "move"
		say("Scribe", "Good. Now move: ↑ ↓ (or W S) take you up and down.")


func _crocs_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "Press Space to thrust the spear; ↑ ↓ (or W S) move you" + ("; ← → turn you." if fight.both else "."))


## Close the vignette again, then finish the fight (or whatever `then` does).
func _crocs_close(then := Callable()) -> void:
	fight.closing = true
	for c in fight.get("crocs", []):
		if c.s != "thief":
			c.s = "gone"
	if fight.kind == "roach":       # it runs back to where it is drawn as the vignette closes
		fight.roach.darting = false
		fight.roach.c0 = fight.roach.c
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


# rearing snakes: strike only at full height
func _rear(dt: float) -> void:
	var e: Dictionary = fight.e
	var a: Node2D = actors[fight.foe]
	var dur := {"coiled": e.coil, "rising": e.rise, "reared": e.window, "strike": 0.3, "down": 0.6}
	if fight.t >= dur[fight.phase]:
		fight.t = 0.0
		if fight.phase == "strike":
			_bite("The snake strikes and draws back. Hit it while it stands upright.")
		fight.phase = {"coiled": "rising", "rising": "reared", "reared": "strike", "strike": "coiled", "down": "coiled"}[fight.phase]
	var k: float = fight.t / dur[fight.phase]
	a.position.x = a.get_meta("home").x
	a.rotation = 0.0
	match fight.phase:
		"coiled", "down": a.scale.y = 0.45
		"rising": a.scale.y = lerpf(0.45, 1.0, k)
		"reared":
			a.scale.y = 1.0
			a.rotation = sin(fight.t * 9.0) * 0.04
		"strike":
			a.scale.y = 1.0
			a.position.x += 28.0 * unit * sin(k * PI)


func _rear_click(p: Vector2) -> void:
	if not actor_rect(fight.foe).grow(14 * unit).has_point(p):
		return
	if fight.phase == "reared":
		fight.hits += 1
		_flash(actors[fight.foe])
		var need: int = fight.e.need
		if fight.hits >= need:
			fight.phase = "down"
			_won_if(true)
		else:
			say("Scribe", "A hit. Once more when it rears again.")
			fight.phase = "down"
		fight.t = 0.0
	elif fight.phase in ["coiled", "rising"]:
		say("Scribe", "Too early: it is still coiled. Wait until it stands at full height.")
		fight.phase = "coiled"
		fight.t = 0.0


# snake on the ground: strike when it slides up to the spear tip
func _slither_off() -> float:
	return (-85.0 + 85.0 * sin(fight.t * (1.5 + 0.4 * fight.hits))) * unit


func _slither(_dt: float) -> void:
	var a: Node2D = actors[fight.foe]
	a.position.x = a.get_meta("home").x + _slither_off()


func _slither_click(p: Vector2) -> void:
	if not actor_rect(fight.foe).grow(10 * unit).has_point(p):
		return
	if _slither_off() > -30.0 * unit:
		fight.hits += 1
		_flash(actors[fight.foe])
		fight.t = -PI / 2.0 / 1.5  # thrown back to the far end of its slide
		var need: int = fight.e.need
		if fight.hits < need:
			say("Scribe", "A hit. It slides away; wait for it to come back.")
		_won_if(fight.hits >= need)
	else:
		say("Scribe", "Out of reach. Wait until it slides up to the spear tip.")


# the roach (spell 36). The vignette opens out as for the crocodiles. The bearer stands still in the
# middle: ← → turn him, Space thrusts. The roach darts about very fast between resting spots; every
# `bait_every` darts it stops where the spear point can reach it (sometimes, `fake`, just out of
# reach). Only the spear point at the full thrust catches it: on its body, or with `dot` only on a
# red dot on its back. A catch holds everything still for ROACH_FREEZE s, then it runs again until
# it has been caught `need` times.
const ROACH_FREEZE := 0.5      ## the pause after a catch, to show it
const ROACH_DOT := 8.0         ## radius of the red dot on its back (plate px), when `dot` is set


func _roach_start(e: Dictionary) -> void:
	_arena_setup(e, true, [e.foe])
	var full: Rect2 = fight.full
	# he stands in the middle of the opened vignette, his spear point at its middle height
	fight.stand = Vector2(full.get_center().x, full.get_center().y - fight.tip.y)
	fight.pos = fight.stand
	fight.hits = 0
	fight.need = e.need if _roach_need < 0 else _roach_need
	fight.freeze = 0.0
	fight.clock = 0.0
	var a: Node2D = actors[e.foe]
	var size: Vector2 = a.get_meta("size")
	var home_c: Vector2 = a.get_meta("home") + Vector2(0.0, -size.y / 2.0)
	# it waits a little way off to the left while the vignette opens
	var c0: Vector2 = fight.stand + Vector2(-260.0 * unit, fight.tip.y)
	fight.roach = {"node": a, "size": size, "home_c": home_c, "c0": c0, "c": home_c, "target": c0,
		"wait": 0.9, "rest_from": 0.0, "leg": 0, "darting": false}
	if e.get("dot", false):
		var dot := Node2D.new()
		dot.position = Vector2(0.0, -size.y / 2.0)
		dot.draw.connect(func(): dot.draw_circle(Vector2.ZERO, ROACH_DOT * unit, Color(181 / 255.0, 91 / 255.0, 60 / 255.0)))
		a.add_child(dot)
		fight.dot = dot
	_arena_open()


## Put the roach's body centre at `c` (its pivot is at the bottom centre, and it turns as it runs).
func _roach_place(c: Vector2) -> void:
	var r: Dictionary = fight.roach
	r.c = c
	r.node.position = c + Vector2(0.0, r.size.y / 2.0).rotated(r.node.rotation)


## Where the spear point is at the full thrust, facing `side` (-1 left, 1 right).
func _roach_spear_point(side: int) -> Vector2:
	return fight.pos + Vector2(fight.tip.x * -side, fight.tip.y) + Vector2(fight.dir.x * -side, fight.dir.y) * CROC_THRUST * unit


## Does a spear point at `p` touch the roach (its body, or the dot when there is one)?
func _roach_touches(p: Vector2) -> bool:
	var r: Dictionary = fight.roach
	if fight.e.get("dot", false):
		return p.distance_to(r.c) <= ROACH_DOT * unit
	var q: Vector2 = (p - r.c).rotated(-r.node.rotation)
	var ax: float = r.size.x * 0.45
	var ay: float = r.size.y * 0.42
	return (q.x * q.x) / (ax * ax) + (q.y * q.y) / (ay * ay) <= 1.0


## The next place it runs to: every `bait_every` darts, by the spear point of one side or the other
## (a `fake` one stops just out of reach); otherwise anywhere around him.
func _roach_next() -> void:
	var e: Dictionary = fight.e
	var r: Dictionary = fight.roach
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
	if fight.open < 1.0 or fight.get("closing", false):
		return
	fight.clock += dt
	var r: Dictionary = fight.roach
	# turn
	var turn := Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if fight.get("bot", false):
		turn = _roach_bot()
	if turn != 0.0:
		fight.facing = 1 if turn > 0.0 else -1
	# a catch: everything holds still, the spear thrust home, then it runs again (or it is over)
	if fight.freeze > 0.0:
		fight.freeze -= dt
		r.node.rotation = sin(fight.clock * 40.0) * 0.08     # it wriggles on the spear
		_roach_place(r.c)
		if fight.freeze <= 0.0:
			fight.thrust = THRUST_TIME[0] + 0.001             # the spear draws back
			if fight.hits >= fight.need:
				end_fight()
				return
			r.node.modulate = Color.WHITE
			r.wait = 0.0
			r.leg = 0                                         # it runs off somewhere else first
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
	# run, rest, run
	if r.darting:
		var d: Vector2 = r.target - r.c
		var step: float = e.dart * unit * dt
		if d.length() > 1.0:
			r.node.rotation = lerp_angle(r.node.rotation, d.angle(), minf(1.0, dt * 30.0))
		if d.length() <= step:
			_roach_place(r.target)
			r.darting = false
			r.wait = r.rest
			r.rest_from = fight.clock
		else:
			_roach_place(r.c + d.normalized() * step)
	else:
		r.wait -= dt
		r.node.rotation += sin(fight.clock * 23.0) * 0.004     # feelers twitching
		_roach_place(r.c)
		if r.wait <= 0.0:
			_roach_next()


func _roach_strike() -> void:
	var e: Dictionary = fight.e
	if not _roach_touches(_roach_spear_point(fight.facing)):
		return
	fight.hits += 1
	if fight.get("bot", false):
		print("ROACH caught at ", snappedf(fight.clock, 0.01), " s")
		if OS.has_environment("SHOT_ON_CATCH"):      # dev: a picture of the catch
			get_tree().create_timer(0.1).timeout.connect(func():
				get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_ON_CATCH")))
	fight.freeze = ROACH_FREEZE
	fight.roach.darting = false
	fight.roach.node.modulate = RED_CROC
	var left: int = fight.need - fight.hits
	say("Scribe", "Pinned!" + (" It wriggles free. %d more." % left if left > 0 else ""))


func _roach_click(_p: Vector2) -> void:
	if _time - fight.nag > 4.0:
		fight.nag = _time
		say("Scribe", "Press Space to thrust the spear; ← → turn you. You cannot step.")


## Dev (`--croc-bot`): turns toward the roach and thrusts once it has rested REACT s within reach.
func _roach_bot() -> float:
	var r: Dictionary = fight.roach
	var react: float = float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else REACT
	var side := 1 if r.c.x > fight.pos.x else -1
	if not r.darting and fight.clock - r.rest_from >= react and side == fight.facing and _roach_touches(_roach_spear_point(side)):
		_croc_thrust()
	return float(side) if side != fight.facing else 0.0


# Apep: strike only the coil that rises
# the lunging snake (spell 33). The vignette opens out as for the crocodiles; the bearer stays where
# he is drawn, his spear raised, and cannot move. The snake coils a little way off, out of reach,
# breathing (a faint squash up and down). Its tail waves: the warning. It squashes down, then
# springs, a fast snap: on the way it passes the very spot where it is drawn, and a thrust (Space)
# there brings the spear point down on the red mark on its body. At the end of the snap its head is
# at his front leg (its body behind his skirt): bitten. Too early and the spear is already coming
# back up when it springs; too late and it is past. Struck `need` times, it is overcome; bitten
# CROC_HEALTH times, he crumbles and the fight starts over.
const SNAKE_MARK := 7.0         ## radius of the red mark on its body (plate px)
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
	var size: Vector2 = bearer.get_meta("size")
	var top_left: Vector2 = bearer.get_meta("home") - Vector2(size.x / 2.0, size.y)
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
	bs.texture = avatar.call("_figure_texture", bs.texture, 2)
	bs.position -= Vector2(2, 2)
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
	_paint_mark(img, best + Vector2i(P, P), SNAKE_MARK * unit)
	sp.texture = ImageTexture.create_from_image(img)
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
		bs.texture = fight.bearer_plain
		bs.position = fight.bearer_at
		bs.material = null
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


## How far along its line the spear point is now: -CROC_PREP raised (at rest) .. CROC_THRUST.
func _spear_out() -> float:
	if fight.get("pinned", false):
		return CROC_THRUST
	if fight.thrust < 0.0:
		return -CROC_PREP
	var t: float = fight.thrust
	if t < THRUST_TIME[0]:
		return lerpf(-CROC_PREP, CROC_THRUST, t / THRUST_TIME[0])
	return lerpf(CROC_THRUST, -CROC_PREP, minf((t - THRUST_TIME[0]) / THRUST_TIME[1], 1.0))


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
	return point.distance_to(mark) <= (SNAKE_MARK + SNAKE_GRACE) * unit


func _lunge_caught() -> void:
	var e: Dictionary = fight.e
	fight.hits += 1
	fight.pinned = true
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


## The last bite: he crumbles away and the fight starts over.
func _lunge_dies() -> void:
	fight.lost = true
	var e: Dictionary = fight.e
	say("Scribe", "One bite too many: the spear-bearer crumbles to dust. Begin again.")
	_lunge_undress()
	_disintegrate(e)
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not fight.is_empty() and fight.kind == "lunge" and fight.e.id == e.id and fight.lost:
			_crocs_close(func():
				_crocs_cleanup()
				for n in _box_actors(e):
					_restore(n)
				fight = {}
				start_fight(e)
				say("Scribe", "Begin again.")))


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
		say("Scribe", "Press Space to thrust the spear, just as the snake springs. You cannot step.")


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


# apep
func _apep(dt: float) -> void:
	if fight.t >= fight.e.raise or fight.raised == -1:
		fight.t = 0.0
		var free := range(APEP_SLICES).filter(func(i): return not fight.pinned[i] and i != fight.raised)
		fight.raised = free[rng.randi() % free.size()] if not free.is_empty() else -1
	for i in APEP_SLICES:
		var a: Node2D = actors["apep%d" % i]
		var home: Vector2 = a.get_meta("home")
		a.position.y = home.y + (0.0 if fight.pinned[i] else sin(_time * 4.0 + i * 0.9) * 2.0 * unit)
		if i == fight.raised:
			a.position.y -= 12.0 * unit
			a.rotation = sin(_time * 10.0) * 0.05
		else:
			a.rotation = 0.0


func _apep_click(p: Vector2) -> void:
	for i in APEP_SLICES:
		var r := actor_rect("apep%d" % i)
		if not Rect2(r.position.x, r.position.y - 16.0 * unit, r.size.x, r.size.y + 30.0 * unit).has_point(p):
			continue
		if i == fight.raised:
			fight.pinned[i] = true
			fight.raised = -1
			actors["apep%d" % i].modulate = Color(0.75, 0.55, 0.45)
			var left: int = fight.pinned.count(false)
			say("Scribe", "The coil is pinned." + (" %d left." % left if left else ""))
			_won_if(left == 0)
		elif fight.pinned[i]:
			say("Scribe", "That coil is already pinned.")
		else:
			var hurt := range(APEP_SLICES).filter(func(j): return fight.pinned[j])
			if not hurt.is_empty():
				var j: int = hurt[rng.randi() % hurt.size()]
				fight.pinned[j] = false
				actors["apep%d" % j].modulate = Color.WHITE
				say("Scribe", "That coil lay flat. Apep twists, and a pinned coil works free.")
			else:
				say("Scribe", "That coil lies flat. Strike the one that rises.")
		return


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
		_flash(actors[fight.foe])
		var need: int = fight.e.need
		if fight.hits < need:
			say("Scribe", "A hit. It slides faster now.")
		_won_if(fight.hits >= need)
	elif actor_rect(fight.donkey).has_point(p):
		fight.hits = maxi(0, fight.hits - 1)
		_shake(actors[fight.donkey])
		say("Scribe", "The donkey brays. Strike the snake, not the donkey.")


# heads in the reeds: strike while they show
func _pop(_dt: float) -> void:
	var a: Node2D = actors[fight.foe]
	var home: Vector2 = a.get_meta("home")
	if fight.t >= fight.wait:
		fight.t = 0.0
		fight.up = not fight.up
		var need: int = fight.e.need
		fight.wait = (1.1 - 0.15 * fight.hits) if fight.up else rng.randf_range(0.7, 1.6)
		var t := create_tween()
		t.tween_property(a, "position:y", home.y if fight.up else home.y + 18.0 * unit, 0.12)
		t.parallel().tween_property(a, "modulate:a", 1.0 if fight.up else 0.0, 0.12)
		if fight.hits >= need:
			fight.wait = 999.0


func _pop_click(p: Vector2) -> void:
	var r := actor_rect(fight.foe).grow(10 * unit)
	if fight.up and r.has_point(p):
		fight.hits += 1
		fight.up = false
		fight.t = 0.0
		var a: Node2D = actors[fight.foe]
		var t := create_tween()
		t.tween_property(a, "modulate:a", 0.0, 0.12)
		t.parallel().tween_property(a, "position:y", a.get_meta("home").y + 18.0 * unit, 0.12)
		var need: int = fight.e.need
		if fight.hits < need:
			say("Scribe", "A hit. They sink back.")
		_won_if(fight.hits >= need)
	elif r.has_point(p) or actor_rect(fight.bundle).has_point(p):
		say("Scribe", "Nothing shows yet. Wait for them to rise.")


func _bite(text: String) -> void:
	bites += 1
	say("Scribe", text)
	var t := create_tween()
	for i in 6:
		t.tween_property(camera, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)) * unit, 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.05)


func _thrust() -> void:
	var a: Node2D = actors[fight.e.spear]
	var home: Vector2 = a.get_meta("home")
	var t := create_tween()
	t.tween_property(a, "position", home + Vector2(-14, 5) * unit, 0.07)
	t.tween_property(a, "position", home, 0.12)


# ---------------------------------------------------------------- helpers

func actor_rect(n: String) -> Rect2:
	var a: Node2D = actors[n]
	var size: Vector2 = a.get_meta("size") * a.scale.abs()
	return Rect2(a.position.x - size.x / 2.0, a.position.y - size.y, size.x, size.y)


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
	var z := clampf(minf((vp.y - top - bottom - 10.0) / _view_height(), vp.x / (1000.0 * unit)), 0.4 / unit, 2.4 / unit)
	camera.zoom = Vector2(z, z)
	var vis_w: float = vp.x / z
	var focus := avatar.position.x - vis_w * 0.05
	if not fight.is_empty():
		var s := span(fight.e)
		focus = (s.x + s.y) / 2.0
	focus = clampf(focus, vis_w / 2.0, maxf(vis_w / 2.0, level.width - vis_w / 2.0))
	var k := 1.0 if delta >= 1.0 else 1.0 - pow(0.002, delta)
	var y := _view_height() / 2.0 + (bottom - top) / 2.0 / z
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
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)


func _draw_overlay() -> void:
	var ink := Color(0.18, 0.11, 0.06)
	if not gate.is_empty() and fight.is_empty():
		var x := gate_x()
		var y: float = level.get("frame_top", 0.0)
		while y < ground:
			overlay.draw_line(Vector2(x, y), Vector2(x, y + 8.0 * unit), Color(ink, 0.55), 6.0 * unit)
			y += 16.0 * unit
	if fight.is_empty():
		return
	match fight.kind:
		"slither":
			if _slither_off() > -30.0 * unit:
				var r := actor_rect(fight.foe)
				overlay.draw_set_transform(Vector2(r.end.x - 20.0 * unit, ground + 4.0 * unit), 0.0, Vector2(1.0, 0.35))
				overlay.draw_arc(Vector2.ZERO, 26.0 * unit, 0.0, TAU, 32, Color(0.64, 0.2, 0.12, 0.6), 2.0 * unit)
				overlay.draw_set_transform(Vector2.ZERO)
	# progress pips above the vignette
	var total := 0
	var got := 0
	match fight.kind:
		"crocs":
			total = _croc_total()
			got = fight.killed
		"apep":
			total = APEP_SLICES
			got = fight.pinned.count(true)
		_:
			total = fight.get("need", fight.e.get("need", 0))
			got = fight.hits
	var sp := span(fight.e)
	if fight.kind in ARENA_FIGHTS:
		sp.y = _arena_rect().end.x
	if fight.kind in ["crocs", "lunge"]:
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
	for i in total:
		var c := Vector2(sp.y - (20.0 + i * 16.0) * unit, 14.0 * unit)
		if fight.kind == "lunge":      # close up: the top of the scroll is off screen; inside the vignette
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
	var e38: Dictionary = ENCOUNTERS.filter(func(x): return x.id == "e38")[0]
	expect.call(avatar.min_x < span(ENCOUNTERS[0]).x and avatar.min_x > span(e38).y, "the way is open past unsolved vignettes, up to spell 38")
	for e in ENCOUNTERS:     # all but spell 37 done: 38 is still shut
		if e.id == "e37":
			break
		solved[e.id] = true
	_refresh()
	expect.call(avatar.min_x > span(e38).y, "spell 38 shut while spell 37 is undone")
	solved.clear()
	_refresh()

	for e in ENCOUNTERS:
		if e.kind == "take":
			expect.call(avatar.min_x < span(e).y, e.id + " open once the dangers before it are overcome")
			take(e)
			expect.call(solved.has(e.id), e.id + " item taken")
			continue
		if not e.kind in FIGHTS:
			continue
		avatar.position.x = span(e).y - 100.0 * unit
		_check_position()
		start_fight(e)
		expect.call(fight.get("e", {}).get("id", "") == e.id, e.id + " fight starts on clicking the creature")
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
				if fight.waves.size() > 1:
					expect.call(_croc_checkpoint.get(e.id, 0) == fight.waves.size() - 1, e.id + " a lost fight starts again from the last wave")
				# three bites and he crumbles
				fight.lost = false
				fight.tut = ""
				fight.health = CROC_HEALTH
				for i in CROC_HEALTH:
					r.s = "crawl"
					_croc_bites(r)
				expect.call(fight.lost and fight.health <= 0, e.id + " the third bite ends the fight")
				if e.waves[0].has("ramp"):
					var w0: Dictionary = e.waves[0]
					expect.call(w0.speed * (1.0 + w0.ramp * (w0.count - 1)) > e.waves[0].speed * 1.5, e.id + " the crocodiles get faster")
			"rear":
				fight.phase = "coiled"
				fight_click(centre.call(e.foe))
				expect.call(fight.hits == 0, e.id + " a coiled snake can't be struck")
				for i in e.need:
					fight.phase = "reared"
					fight.t = 0.0
					fight_click(centre.call(e.foe))
			"slither":
				for i in e.need:
					fight.t = PI / 2.0 / (1.5 + 0.4 * fight.hits)
					_slither(0.0)
					fight_click(centre.call(e.foe))
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
				fight.health = 1
				_lunge_try(-0.3)
				expect.call(fight.lost, e.id + " the third bite and he crumbles")
				fight.lost = false
			"roach":
				var r: Dictionary = fight.roach
				# a point that misses does nothing; a point on the roach pins it
				r.darting = false
				_roach_place(_roach_spear_point(fight.facing) + Vector2(0.0, r.size.y * 2.0))
				_roach_strike()
				expect.call(fight.hits == 0, e.id + " a thrust that misses the roach does nothing")
				for i in e.need:
					fight.freeze = 0.0
					fight.facing = 1
					_roach_place(_roach_spear_point(-1))
					_roach_strike()
					expect.call(fight.hits == i, e.id + " only the side he faces counts")
					fight.facing = -1
					_roach_strike()
					expect.call(fight.hits == i + 1 and fight.freeze > 0.0, e.id + " the spear point pins it, and all holds still")
				# its darts stop by the spear point every few runs
				var near := 0
				for i in 12:
					_roach_next()
					if _roach_touches(_roach_spear_point(-1)) or _roach_touches(_roach_spear_point(1)) or r.target.distance_to(_roach_spear_point(-1)) < r.size.y or r.target.distance_to(_roach_spear_point(1)) < r.size.y:
						near += 1
				expect.call(near >= 3, e.id + " it often stops by the spear point")
			"apep":
				for i in APEP_SLICES:
					fight.raised = i
					_apep(0.0)
					fight.raised = i
					fight_click(centre.call("apep%d" % i))
			"donkey":
				fight_click(Vector2(actor_rect(e.donkey).position.x + 20.0 * unit, actor_rect(e.donkey).end.y - 20.0 * unit))
				expect.call(fight.hits == 0, e.id + " striking the donkey scores nothing")
				for i in e.need:
					_donkey(0.0)
					fight_click(centre.call(e.foe))
			"pop":
				for i in e.need:
					fight.up = true
					fight_click(centre.call(e.foe))
		end_fight()  # the real game waits half a second first
		expect.call(solved.has(e.id), e.id + " overcome")

	expect.call(current.is_empty(), "every danger before spell 42 is overcome")
	avatar.position.x = span(ENCOUNTERS[-1]).y - 50.0 * unit
	_check_position()
	expect.call(finished, "level finished at spell 42")
	print("AUTOTEST ", "OK" if fails.is_empty() else "FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
