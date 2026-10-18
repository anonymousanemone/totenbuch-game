## The three bulls (plates III-IV, spells 1-15): fix what is wrong.
##
## Step up and the camera holds all three at once: the bull bound at the block (the sacrifice, in
## the strip), the calf, and the plumed ox. Two things are wrong, and nothing says which unless you
## ask for a hint. The calf faces the sacrifice, watching what is coming to it: drag it sideways and
## it turns about its own middle; let go past halfway and it faces the plumed ox, its back to the
## block, as drawn (short of halfway it turns back). While it faces the block it shies now and then.
## And the plumes (the disc and plumes) sit on the bull at the block, the plumed ox walking bare: drag
## them onto his head (no outline shows where); let go anywhere else and they go back. Either can
## come first. With both set right the plumed ox lowers his head to the calf.
##
## The plumed ox and the plumes are the sprites plumed_ox and plumes, cut by
## tools/cut_procession300.py --bulls from the `bulls` folder of art/procession1-15.mdp; where the
## plumes sit on his head and on the sacrifice is `bulls` in level.json (the scene's `plumes_place`
## marks the first). The calf is the sprite calf. Positions are strip pixels.
class_name ThreeBulls
extends Node2D

const PUZZLES := preload("res://scripts/puzzles.gd")

signal said(who: String, text: String)
signal finished

const SNAP := 60.0            ## strip px from their place on his head that the plumes still go on
const SHY_EVERY := Vector2(1.2, 2.6)   ## s between the calf's starts while it faces the block
const SHY := 0.35             ## s a start lasts
const BOW := 0.06             ## rad the plumed ox lowers his head ...
const BOW_TIME := 0.7         ## ... over this long, and raises it again
const MARGIN := 40.0          ## strip px of papyrus either side of the scene

var active := false           ## stepped up: the camera holds on the scene
var done := false
var instant := false          ## the autotest: no waiting
var held := ""                ## "calf" or "plumes" while it is dragged
var _calf: Sprite2D           ## centred: it turns about its own middle (scale.x: 1 faces the plumed ox, as drawn)
var _ox: Sprite2D             ## his pivot at his hind hooves, so he bows from there
var _plumes: Sprite2D
var _right := Vector2.ZERO    ## the plumes' top-left on his head (world)
var _wrong := Vector2.ZERO    ## ... and on the sacrifice
var _view := Vector2.ZERO
var _stand := 0.0
var _grab := Vector2.ZERO     ## the pointer's offset from the plumes' top-left, or where a calf drag began
var _turn_from := -1.0
var _shy_in := 0.0
var _shy_t := 0.0
var _told := {}


func setup(level: Dictionary, nodes: Dictionary) -> void:
	_calf = nodes.calf
	_ox = nodes.plumed_ox
	_plumes = nodes.plumes
	_right = (nodes.plumes_place as Node2D).position
	_wrong = Vector2(level.bulls.wrong.x, level.bulls.wrong.y)
	var sacrifice: Dictionary = level.hotspots.filter(func(h): return h.id == "sacrifice")[0]
	var ox_end: float = _ox.position.x + _ox.offset.x + _ox.texture.get_width()
	var half: float = level.sprites.avatar.w / 2.0
	_stand = ox_end + MARGIN + half
	# from the sacrifice to you, standing right of the plumed ox: all of it in view
	_view = Vector2(sacrifice.x - MARGIN, _stand + half + MARGIN)


func reset() -> void:
	active = false
	done = false
	held = ""
	_told.clear()
	_calf.scale = Vector2(-1.0, 1.0)      # facing the block
	_calf.rotation = 0.0
	_ox.rotation = 0.0
	_set_plumes_on(false)
	_shy_in = SHY_EVERY.x


## The scene's extent on the strip (from, to), you included, and where you stand to it (right of
## the plumed ox).
func view() -> Vector2:
	return _view


func stand_x() -> float:
	return _stand


func calf_turned() -> bool:
	return _calf.scale.x > 0.0


func crowned() -> bool:
	return _plumes.get_parent() == _ox


func calf_sprite() -> Sprite2D:
	return _calf


func ox_sprite() -> Sprite2D:
	return _ox


func plumes_sprite() -> Sprite2D:
	return _plumes


## Show instructions every time the player steps up.
func enter() -> void:
	if done:
		return
	active = true
	said.emit("Scribe", PUZZLES.text("procession.bulls", "instructions"))


func leave() -> void:
	if held != "":
		release(Vector2.INF)
	active = false


## Under the pointer: "calf" or "plumes" (only while stepped up, and not yet put right), else "".
func pick(p: Vector2) -> String:
	if not active or done:
		return ""
	if _rect(_plumes).grow(8.0).has_point(p):
		return "plumes"
	if _rect(_calf).grow(8.0).has_point(p):
		return "calf"
	return ""


## Take hold of the calf or the plumes at `p`.
func press(what: String, p: Vector2) -> void:
	held = what
	if what == "plumes":
		if crowned():     # taken off his head again, from where they sit
			var at := _plumes.global_position
			_set_plumes_on(false)
			_plumes.global_position = at
		_grab = p - _plumes.global_position
		_plumes.z_index = 10
	else:
		_grab = p
		_turn_from = _calf.scale.x


## The pointer moves with something held.
func drag(p: Vector2) -> void:
	match held:
		"plumes":
			_plumes.global_position = p - _grab
		"calf":   # sideways turns it about its middle: across half its width turns it right round
			var w := _calf.texture.get_width() * 0.5
			_calf.scale.x = clampf(_turn_from + 2.0 * (p.x - _grab.x) / w, -1.0, 1.0)


## Let go at `p` (Vector2.INF: stepping away).
func release(p: Vector2) -> void:
	var what := held
	held = ""
	match what:
		"plumes":
			_plumes.z_index = 0
			var at := p - _grab
			var on := p != Vector2.INF and at.distance_to(_right) <= SNAP
			_set_plumes_on(on)
			if on:
				_once("crowned", "Scribe", "The disc and plumes sit on the living ox again.")
		"calf":
			_calf.scale.x = 1.0 if _calf.scale.x > 0.0 and p != Vector2.INF else _turn_from
			if calf_turned():
				_once("turned", "Scribe", "The calf turns its back on the block and settles.")
	_check()


func _set_plumes_on(on: bool) -> void:
	if on:
		if _plumes.get_parent() != _ox:
			_plumes.reparent(_ox, false)
		_plumes.transform = Transform2D(0.0, _right - _ox.position)
	else:
		if _plumes.get_parent() != self:
			_plumes.reparent(self, false)
		_plumes.transform = Transform2D(0.0, _wrong)


func _check() -> void:
	if done or not (calf_turned() and crowned()):
		return
	done = true
	active = false
	said.emit("Scribe", PUZZLES.text("procession.bulls", "success"))
	if not instant:
		var t := create_tween()
		t.tween_property(_ox, "rotation", -BOW, BOW_TIME).set_trans(Tween.TRANS_SINE)
		t.tween_property(_ox, "rotation", 0.0, BOW_TIME).set_trans(Tween.TRANS_SINE)
	finished.emit()


func _process(delta: float) -> void:
	# facing the block, the calf starts now and then: a quick shudder back from it
	if not calf_turned() and held != "calf" and not done:
		_shy_in -= delta
		if _shy_in <= 0.0:
			_shy_in = randf_range(SHY_EVERY.x, SHY_EVERY.y)
			_shy_t = SHY
	if _shy_t > 0.0:
		_shy_t = maxf(0.0, _shy_t - delta)
		_calf.rotation = 0.06 * sin(_shy_t * 40.0) * (_shy_t / SHY)
	elif held != "calf":
		_calf.rotation = 0.0


## The box round a sprite's drawing where it is now (world px).
func _rect(sp: Sprite2D) -> Rect2:
	var size := sp.texture.get_size()
	var local := Rect2(-size / 2.0, size) if sp.centered else Rect2(sp.offset, size)
	return sp.get_global_transform() * local


func _once(key: String, who: String, text: String) -> void:
	if _told.has(key):
		return
	_told[key] = true
	said.emit(who, text)
