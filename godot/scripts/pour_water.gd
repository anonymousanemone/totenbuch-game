## Pouring the purifying water (plate V, spell 15): tip the priest's jar until the water runs
## along the drawn line over Anubis and the mummy.
##
## The priest raises a round jar over a kneeling woman; the wavy line from its spout, arching
## over Anubis holding the mummy upright and down to their base, is the stream. At the start his
## arm is raised further, the jar upright, and there is no stream: only a faint dotted ghost of
## the line. Press on the jar and drag to turn his forearm about the elbow. Within WINDOW of the
## tilt as drawn the water runs along the line and the line draws itself in, but only while the
## jar is held steady. Too shallow and it only drips; too steep and it gushes out, falls short
## and splashes on the woman's raised hands. Not pouring along the line, the drawn part dries
## back a little, never below KEEP of the furthest it reached. Let go and the arm rises back to
## upright. Once the whole line is drawn the jar settles where it is drawn: the plate as drawn.
##
## The arm (forearm, hand and jar) and the stream are the sprites water_arm and water_stream,
## with the stream's path beside it (water_path), cut by tools/cut_procession300.py; positions
## (`water` in level.json) are strip pixels.
class_name PourWater
extends Node2D

signal said(who: String, text: String)
signal finished

enum Flow { NONE, DRIP, POUR, GUSH }

const START_TILT := 0.45      ## rad the arm starts raised past where it is drawn: the jar upright
const LOW := -0.55            ## the furthest the jar can be tipped (rad from as drawn) ...
const HIGH := 0.6             ## ... and raised
const WINDOW := 0.12          ## rad either side of the drawn tilt in which the water runs along the line
const DRIP_FROM := 0.32       ## above the window and below this the jar only drips
const FLOW_RATE := 0.16       ## share of the line drawn per second while pouring steadily
const STEADY := 1.2           ## rad/s: turned faster than this, the water slops and the line doesn't grow
const TURN := 4.0             ## rad/s the arm follows your drag at most (the jar is heavy)
const TREMBLE := 0.03         ## rad: the full jar trembles in your hand while you hold it
const DRY := 0.06             ## share of the line that dries back per second while not pouring along it
const KEEP := 0.6             ## ... never below this share of the furthest it reached
const RISE := 2.0             ## 1/s: let go and the arm rises back toward upright
const SETTLE := 0.7           ## s for the jar to settle where it is drawn once the line is whole
const GRIP_PAD := 22.0        ## strip px round the jar and forearm that take a press
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
var gripping := false
var steady := true            ## the jar held still enough for the line to grow
var _want := START_TILT       ## where your drag puts the arm (before the tremble and the TURN limit)
var _grip_angle := 0.0        ## the pointer's angle about the elbow when gripped ...
var _grip_tilt := 0.0         ## ... and the arm's turn then
var _fixed := false           ## held at a turn by hold_at(), not by the pointer
var _time := 0.0
var _drip_clock := 0.0
var _gush_clock := 0.0
var _drops: Array = []        ## {pos, vel, life, kind}: falling ("fall") or splashing ("splash")
var _runs: Array = []         ## shares along the drawn line of drops running down it
var _told := {}
var _elbow := Vector2.ZERO
var _spout := Vector2.ZERO    ## the spout as drawn
var _hands := Vector2.ZERO
var _arm: Node2D              ## pivot at the elbow
var _arm_sprite: Sprite2D
var _stream: Sprite2D
var _along: PackedVector2Array = []   ## points along the drawn line from the spout (world px)
var _view := Vector2.ZERO
var _stand := 0.0
var _tween: Tween


func setup(level: Dictionary, art: String) -> void:
	var w: Dictionary = level.water
	_elbow = Vector2(w.elbow[0], w.elbow[1])
	_spout = Vector2(w.spout[0], w.spout[1])
	_hands = Vector2(w.hands[0], w.hands[1])
	_view = Vector2(w.view[0], w.view[1])
	_stand = w.stand
	var s: Dictionary = level.sprites.water_stream
	_stream = Sprite2D.new()
	_stream.texture = load(art % "water_stream")
	_stream.centered = false
	_stream.position = Vector2(s.x, s.y)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var path_tex: Texture2D = load(art % "water_path")
	mat.set_shader_parameter("path", path_tex)
	_stream.material = mat
	add_child(_stream)
	for p in w.line:
		_along.append(Vector2(p[0], p[1]))
	var a: Dictionary = level.sprites.water_arm
	_arm = Node2D.new()
	_arm.position = _elbow
	_arm_sprite = Sprite2D.new()
	_arm_sprite.texture = load(art % "water_arm")
	_arm_sprite.centered = false
	_arm_sprite.position = Vector2(a.x, a.y) - _elbow
	_arm.add_child(_arm_sprite)
	add_child(_arm)


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
	gripping = false
	_fixed = false
	steady = true
	_drops.clear()
	_runs.clear()
	_told.clear()
	_place()


## Step up to the water: the camera holds on it (see the level), and the first time the scribe
## says what is wrong.
func enter() -> void:
	if done:
		return
	active = true
	_once("enter", "Scribe", "The priest's jar is upright and no water runs. Press on the jar and drag to tip it, and hold it where the water runs along the line.")


## Step away: let go of the jar; what is drawn of the line dries back a little, no further.
func leave() -> void:
	release()
	active = false


## The scene's extent on the strip (from, to) and where you stand in it.
func view() -> Vector2:
	return _view


func stand_x() -> float:
	return _stand


## A press here takes hold of the jar.
func can_grip(p: Vector2) -> bool:
	return not done and arm_rect().grow(GRIP_PAD).has_point(p)


## The jar and forearm where they are now (world px).
func arm_rect() -> Rect2:
	var size := _arm_sprite.texture.get_size()
	return _arm_sprite.get_global_transform() * Rect2(Vector2.ZERO, size)


func arm_sprite() -> Sprite2D:
	return _arm_sprite


func stream_sprite() -> Sprite2D:
	return _stream


func grip(p: Vector2) -> bool:
	if not active or done or not can_grip(p):
		return false
	gripping = true
	_fixed = false
	_grip_angle = (p - _elbow).angle()
	_grip_tilt = tilt
	_want = tilt
	return true


## The pointer moves while you hold the jar: the arm turns as far as it has gone round the elbow.
func drag(p: Vector2) -> void:
	if not gripping or _fixed:
		return
	_want = clampf(_grip_tilt + wrapf((p - _elbow).angle() - _grip_angle, -PI, PI), LOW, HIGH)


func release() -> void:
	gripping = false
	_fixed = false


## Hold the arm at a turn, as a steady drag would (the autotest).
func hold_at(t: float) -> void:
	gripping = true
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
		var target := _want
		if gripping:
			target += TREMBLE * sin(_time * 4.3) * (0.6 + 0.4 * sin(_time * 1.7))
		else:
			target = lerpf(tilt, START_TILT, 1.0 - exp(-RISE * delta))
			_want = target
		var before := tilt
		tilt = clampf(move_toward(tilt, target, TURN * delta), LOW, HIGH)
		steady = absf(tilt - before) / maxf(delta, 1e-4) <= STEADY
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
			if steady:
				progress = minf(1.0, progress + FLOW_RATE * delta)
				best = maxf(best, progress)
				if _runs.size() < 6 and randf() < delta * 5.0:
					_runs.append(0.0)
				if progress >= 1.0:
					_complete()
					return
				if progress > 0.15:
					_once("pour", "Scribe", "The water runs along the line. Hold the jar steady.")
			else:
				_dry(delta)
				_once("slop", "Scribe", "The water slops over the rim. Hold the jar still.")
		Flow.DRIP:
			_dry(delta)
			_drip_clock -= delta
			if _drip_clock <= 0.0:
				_drip_clock = 0.35
				_drops.append({"pos": spout(), "vel": Vector2(randf_range(-10.0, 0.0), 0.0), "life": 2.0, "kind": "fall"})
			_once("drip", "Scribe", "Too shallow: the jar only drips. Tip it further.")
		Flow.GUSH:
			_dry(delta)
			_gush_clock -= delta
			while _gush_clock <= 0.0:
				_gush_clock += 0.03
				var sp := spout()
				var t := 0.5    # s to fall onto her hands
				var v := Vector2((_hands.x - sp.x) / t, (_hands.y - sp.y - 0.5 * GRAVITY * t * t) / t)
				_drops.append({"pos": sp, "vel": v + Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0)), "life": 1.5, "kind": "fall"})
			_once("gush", "Scribe", "Too steep: the water gushes out and falls short, onto the woman's raised hands.")
		_:
			_dry(delta)


func _dry(delta: float) -> void:
	progress = maxf(best * KEEP, progress - DRY * delta)


func _complete() -> void:
	done = true
	active = false
	gripping = false
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
	said.emit("Scribe", "The water arches over Anubis and the mummy and runs down to their base, as it is drawn.")
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
	if flow == Flow.POUR and steady:
		for i in _runs.size():
			_runs[i] += delta * 0.9
	_runs = _runs.filter(func(r): return r < progress)


func _place() -> void:
	if _arm == null:
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
