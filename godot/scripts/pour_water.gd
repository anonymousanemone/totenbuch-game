## Pouring the purifying water (plate V, spell 15): tip the priest's jar until the water runs
## along the drawn line over Anubis and the mummy.
##
## The priest raises a round jar over a kneeling woman; the wavy line from its spout, arching
## over Anubis holding the mummy upright and down to their base, is the stream. At the start his
## arm is raised further, the jar upright, and there is no stream: only a faint dotted ghost of
## the line. Once you stand at the water his tired arm droops, tipping the jar further, pulled
## down harder or softer at random; holding Space pushes it up. The arm has weight: it keeps
## swinging after a push or a pull, so it is never still by itself. Within WINDOW
## of the tilt as drawn the water runs along the line and the line draws itself in. Too high and
## it only drips; drooped too far and it gushes out, falls short and splashes on the woman's
## raised hands. Not pouring along the line, the drawn part dries back a little, never below KEEP
## of the furthest it reached. Once the whole line is drawn the jar settles where it is drawn.
##
## The priest is his body and his forearm with the jar (water_priest_body, water_priest_arm, from
## tools/arm_sheets.py --parts): the arm is a child of the body, placed at the elbow (drawn on
## both), and turns about it by the tilt. The stream is the sprite water_stream, with its path
## beside it (water_path), cut by tools/cut_procession300.py; positions (`water` in level.json)
## are strip pixels.
class_name PourWater
extends Node2D

const PUZZLES := preload("res://scripts/puzzles.gd")

signal said(who: String, text: String)
signal finished

enum Flow { NONE, DRIP, POUR, GUSH }

const START_TILT := 0.45      ## rad the arm starts raised past where it is drawn: the jar upright
const LOW := -0.55            ## the furthest the jar can be tipped (rad from as drawn) ...
const HIGH := 0.6             ## ... and raised
const WINDOW := 0.09          ## rad either side of the drawn tilt in which the water runs along the line
const DRIP_FROM := 0.32       ## above the window and below this the jar only drips
const FLOW_RATE := 0.16       ## share of the line drawn per second while pouring along it
const DROOP := Vector2(0.5, 2.0)        ## rad/s² the arm is pulled down: a new pull, at random between these, ...
const DROOP_EVERY := Vector2(0.3, 1.0)  ## ... every so many s (also at random)
const LIFT := 3.0             ## rad/s² holding Space pushes the arm up (against the droop)
const DAMP := 1.2             ## 1/s the arm's swing dies away by itself
const TURN := 4.0             ## rad/s the arm turns at most to a held tilt (hold_at)
const DRY := 0.06             ## share of the line that dries back per second while not pouring along it
const KEEP := 0.6             ## ... never below this share of the furthest it reached
const SETTLE := 0.7           ## s for the jar to settle where it is drawn once the line is whole
const JAR_PAD := 22.0         ## strip px round the jar and forearm that take a click
const GRAVITY := 900.0        ## strip px/s² for falling drops
const INK := UI.INK
const SHADER := preload("res://scripts/water.gdshader")

var active := false           ## at the water: the camera holds on it and you work the jar
var instant := false          ## the autotest: settle at once
var done := false             ## the whole line is drawn
var tilt := START_TILT        ## the arm's turn from where it is drawn (rad, + raises the jar)
var progress := 0.0           ## share of the line drawn, from the spout
var best := 0.0               ## the furthest it has reached
var flow := Flow.NONE
var raising := false          ## Space is held: the arm lifts
var rng := RandomNumberGenerator.new()   ## the droop (randomize()d each time you step up)
var _spin := 0.0              ## rad/s the arm is swinging now (+ raises the jar)
var _droop := 0.0             ## rad/s² the arm is pulled down now ...
var _droop_left := 0.0        ## ... for this many s more
var _want := START_TILT       ## the tilt held by hold_at()
var _fixed := false           ## held at a turn by hold_at() (the autotest), not by the droop
var _time := 0.0
var _drip_clock := 0.0
var _gush_clock := 0.0
var _drops: Array = []        ## {pos, vel, life, kind}: falling ("fall") or splashing ("splash")
var _runs: Array = []         ## shares along the drawn line of drops running down it
var _told := {}
var _elbow := Vector2.ZERO    ## where his arm joins his body: it turns about it
var _spout := Vector2.ZERO    ## the spout as drawn
var _hands := Vector2.ZERO
var _priest: Sprite2D
var _arm: Sprite2D            ## his forearm and jar, a child of his body at the elbow
var _arm_rect := Rect2()      ## the forearm and jar as drawn
var _stream: Sprite2D
var _along: PackedVector2Array = []   ## points along the drawn line from the spout (world px)
var _view := Vector2.ZERO
var _stand := 0.0
var _tween: Tween


func setup(level: Dictionary, art: String, nodes: Dictionary) -> void:
	var w: Dictionary = level.water
	_spout = Vector2(w.spout[0], w.spout[1])
	_hands = Vector2(w.hands[0], w.hands[1])
	_view = Vector2(w.view[0], w.view[1])
	_stand = w.stand
	_stream = nodes.water_stream
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var path_tex: Texture2D = load(art % "water_path")
	mat.set_shader_parameter("path", path_tex)
	_stream.material = mat
	for p in w.line:
		_along.append(Vector2(p[0], p[1]))
	_priest = nodes.water_priest
	_arm = nodes.water_priest_arm
	_elbow = _priest.position + _arm.position
	_arm_rect = Rect2(_elbow + _arm.offset, _arm.texture.get_size())


func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	active = false
	done = false
	tilt = START_TILT
	_want = START_TILT
	progress = 0.0
	best = 0.0
	flow = Flow.NONE
	raising = false
	_fixed = false
	_spin = 0.0
	_droop_left = 0.0
	_drops.clear()
	_runs.clear()
	_told.clear()
	_place()


## Step up to the water: the camera holds on it and instructions appear on every entry.
func enter() -> void:
	if done:
		return
	active = true
	rng.randomize()
	_spin = 0.0
	_droop_left = 0.0
	said.emit("Priest with jar", PUZZLES.text("procession.water", "instructions"))


## Step away: what is drawn of the line dries back a little, no further.
func leave() -> void:
	raising = false
	_fixed = false
	active = false


## The scene's extent on the strip (from, to) and where you stand in it.
func view() -> Vector2:
	return _view


func stand_x() -> float:
	return _stand


## The jar is here (a click on it steps up to the water).
func on_jar(p: Vector2) -> bool:
	return not done and arm_rect().grow(JAR_PAD).has_point(p)


## The jar and forearm where they are now (world px).
func arm_rect() -> Rect2:
	return Transform2D(tilt, _elbow) * Transform2D(0.0, -_elbow) * _arm_rect


func priest_sprite() -> Sprite2D:
	return _priest


func arm_sprite() -> Sprite2D:
	return _arm


func stream_sprite() -> Sprite2D:
	return _stream


## Hold the arm at a turn, whatever the droop (the autotest, and `--pour`).
func hold_at(t: float) -> void:
	_fixed = true
	_want = clampf(t, LOW, HIGH)


## Where the water leaves the jar now.
func spout() -> Vector2:
	return _elbow + (_spout - _elbow).rotated(tilt)


## How the water leaves the jar at a turn: dripping, along the line, or gushing.
static func flow_at(t: float) -> Flow:
	if absf(t) <= WINDOW:
		return Flow.POUR
	if t < -WINDOW:
		return Flow.GUSH
	if t < DRIP_FROM:
		return Flow.DRIP
	return Flow.NONE


func _process(delta: float) -> void:
	_time += delta
	if active and not done:
		if _fixed:
			tilt = clampf(move_toward(tilt, _want, TURN * delta), LOW, HIGH)
		else:
			_droop_left -= delta
			if _droop_left <= 0.0:   # his arm tires again: a new droop, at random
				_droop = rng.randf_range(DROOP.x, DROOP.y)
				_droop_left = rng.randf_range(DROOP_EVERY.x, DROOP_EVERY.y)
			_spin = (_spin + ((LIFT if raising else 0.0) - _droop) * delta) * exp(-DAMP * delta)
			tilt += _spin * delta
			if tilt <= LOW or tilt >= HIGH:   # as far as it goes: the swing stops there
				tilt = clampf(tilt, LOW, HIGH)
				_spin = 0.0
		_flow(delta)
	elif not done:
		flow = Flow.NONE
		progress = maxf(best * KEEP, progress - DRY * delta)
	_move_drops(delta)
	_place()
	queue_redraw()


func _flow(delta: float) -> void:
	flow = flow_at(tilt)
	match flow:
		Flow.POUR:
			progress = minf(1.0, progress + FLOW_RATE * delta)
			best = maxf(best, progress)
			if _runs.size() < 6 and randf() < delta * 5.0:
				_runs.append(0.0)
			if progress >= 1.0:
				_complete()
				return
			if progress > 0.15:
				_once("pour", "Scribe", "The water runs along the line. Keep it there.")
		Flow.DRIP:
			_dry(delta)
			_drip_clock -= delta
			if _drip_clock <= 0.0:
				_drip_clock = 0.35
				_drops.append({"pos": spout(), "vel": Vector2(randf_range(-10.0, 0.0), 0.0), "life": 2.0, "kind": "fall"})
			_once("drip", "Scribe", "Too high: the jar only drips. Let it sink a little.")
		Flow.GUSH:
			_dry(delta)
			_gush_clock -= delta
			while _gush_clock <= 0.0:
				_gush_clock += 0.03
				var sp := spout()
				var t := 0.5    # s to fall onto her hands
				var v := Vector2((_hands.x - sp.x) / t, (_hands.y - sp.y - 0.5 * GRAVITY * t * t) / t)
				_drops.append({"pos": sp, "vel": v + Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0)), "life": 1.5, "kind": "fall"})
			_once("gush", "Scribe", "His arm droops too far: the water gushes out onto the woman's raised hands. Hold [space] to lift the jar.")
		_:
			_dry(delta)


func _dry(delta: float) -> void:
	progress = maxf(best * KEEP, progress - DRY * delta)


func _complete() -> void:
	done = true
	active = false
	raising = false
	flow = Flow.NONE
	progress = 1.0
	best = 1.0
	_runs.clear()
	if instant:
		tilt = 0.0
		_place()
	else:
		_tween = create_tween()
		_tween.tween_property(self, "tilt", 0.0, SETTLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	said.emit("Scribe", PUZZLES.text("procession.water", "success"))
	finished.emit()


func _move_drops(delta: float) -> void:
	var ground := _elbow.y + 208.0      # the ground line under the scene
	var fresh: Array = []
	for d in _drops:
		var vel: Vector2 = d.vel + Vector2(0.0, GRAVITY * delta)
		var pos: Vector2 = d.pos + vel * delta
		d.vel = vel
		d.pos = pos
		d.life -= delta
		if d.kind == "fall":
			# a drop falls onto the woman's raised hands, or onto the ground
			var floor_y := _hands.y if absf(pos.x - _hands.x) < 22.0 else ground
			if pos.y >= floor_y and vel.y > 0.0:
				d.life = 0.0
				for i in 3:
					fresh.append({"pos": Vector2(pos.x, floor_y), "vel": Vector2(randf_range(-60.0, 60.0), randf_range(-140.0, -60.0)), "life": 0.35, "kind": "splash"})
	_drops = _drops.filter(func(d): return d.life > 0.0) + fresh
	if flow == Flow.POUR:
		for i in _runs.size():
			_runs[i] += delta * 0.9
	_runs = _runs.filter(func(r): return r < progress)


func _place() -> void:
	if _priest == null:
		return
	_arm.rotation = tilt
	(_stream.material as ShaderMaterial).set_shader_parameter("reveal", progress)


## The point on the drawn line a share of the way along it.
func point_at(share: float) -> Vector2:
	var f := clampf(share, 0.0, 1.0) * (_along.size() - 1)
	var i := mini(floori(f), _along.size() - 2)
	return _along[i].lerp(_along[i + 1], f - i)


func _draw() -> void:
	for d in _drops:
		var r := 2.2 if d.kind == "fall" else 1.4
		draw_circle(d.pos, r, Color(INK, clampf(d.life * 3.0, 0.0, 0.85)))
	if flow == Flow.POUR and active:
		# the water leaving the spout joins the drawn line where it begins
		var from := spout()
		var to := point_at(0.0)
		for i in 4:
			var k := fposmod(_time * 2.5 + i * 0.25, 1.0)
			draw_circle(from.lerp(to, k), 1.8, Color(INK, 0.8))
		for r in _runs:
			draw_circle(point_at(r), 2.4, Color(INK, 0.9))


func _once(key: String, who: String, text: String) -> void:
	if _told.has(key):
		return
	_told[key] = true
	said.emit(who, text)
