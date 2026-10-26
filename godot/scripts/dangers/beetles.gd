## Beetles encounter behavior and acceptance checks.
extends RefCounted

const CROCODILES := preload("res://scripts/dangers/crocodiles.gd")

var game


func _init(level) -> void:
	game = level


# the roach (spell 36). The vignette opens out as for the crocodiles. The bearer stands still in the
# middle: ← → turn him, Space thrusts. `count` beetles (the drawn one and copies) dart about very
# fast between resting spots; every `bait_every` darts each stops where the spear point can reach
# it on his left or right (sometimes, `fake`, just out of reach). Only the spear point at the full
# thrust catches one on its body. A catch holds
# everything still for ROACH_FREEZE s; the pinned beetle is gone, and all of them pinned wins. A
# beetle that stops within reach and gets away again has passed the point: it reddens, and one that
# has passed `passes` times and gets away again is too many. They multiply until they fill the
# screen, the bearer crumbles, and he is back on the scroll.
const ROACH_SWARM := 120       ## how many beetles fill the screen when the fight is lost


func _roach_start(e: Dictionary) -> void:
	game._arena_setup(e, true, [e.foe])
	var full: Rect2 = game.fight.full
	# he stands in the middle of the opened vignette, his spear point at its middle height
	game.fight.stand = Vector2(full.get_center().x, full.get_center().y - game.fight.tip.y)
	game.fight.pos = game.fight.stand
	game.fight.hits = 0
	game.fight.need = int(e.count) if game._roach_need < 0 else game._roach_need
	game.fight.freeze = 0.0
	game.fight.clock = 0.0
	game.fight.copies = []
	game.fight.roaches = []
	var a: Node2D = game.actors[e.foe]
	var size: Vector2 = a.get_meta("size")
	var home_c: Vector2 = a.get_meta("home") + Vector2(0.0, -size.y / 2.0)
	# the drawn one waits a little way off to the left while the vignette opens; the others
	# (copies) fade in at other spots around him
	var spots := [Vector2(-260.0, 0.0), Vector2(300.0, -150.0), Vector2(220.0, 170.0), Vector2(-200.0, -180.0), Vector2(-320.0, 160.0)]
	for i in game.fight.need:
		var c0: Vector2 = game.fight.stand + Vector2(0.0, game.fight.tip.y) + spots[i % spots.size()] * game.unit
		var node := a
		if i > 0:
			node = game._make_actor(game._picture(a).texture, Rect2(Vector2.ZERO, size))
			node.modulate.a = 0.0
			game.fight.copies.append(node)
		var r := {"node": node, "size": size, "home_c": home_c if i == 0 else c0, "c0": c0, "c": c0, "target": c0,
			"wait": 0.9 + 0.35 * i, "rest_from": 0.0, "leg": i, "darting": false, "rest": 0.0,
			"at_point": false, "passes": 0, "gone": false}
		game.fight.roaches.append(r)
		_roach_place(r, home_c if i == 0 else c0)
	game.fight.roach = game.fight.roaches[0]
	game._arena_open()


## Put beetle `r`'s body centre at `c` (its pivot is at the bottom centre, and it turns as it runs).
func _roach_place(r: Dictionary, c: Vector2) -> void:
	r.c = c
	r.node.position = c + Vector2(0.0, r.size.y / 2.0).rotated(r.node.rotation)


## Where the spear point is at the full thrust, facing `side` (-1 left, 1 right).
func _roach_spear_point(side: int) -> Vector2:
	return game.fight.pos + Vector2(game.fight.tip.x * -side, game.fight.tip.y) + Vector2(game.fight.dir.x * -side, game.fight.dir.y) * game.CROC_THRUST * game.unit


## Does a spear point at `p` touch beetle `r`'s body?
func _roach_touches(r: Dictionary, p: Vector2) -> bool:
	var q: Vector2 = (p - r.c).rotated(-r.node.rotation)
	var ax: float = r.size.x * 0.45
	var ay: float = r.size.y * 0.42
	return (q.x * q.x) / (ax * ax) + (q.y * q.y) / (ay * ay) <= 1.0


## The beetles still running.
func _roaches() -> Array:
	return game.fight.roaches.filter(func(r): return not r.gone)


## The next place beetle `r` runs to: every `bait_every` darts, by the spear point of one side or
## the other (a `fake` one stops just out of reach); otherwise anywhere around him. A beetle that
## leaves the spear point has passed it once more; past `passes` times, the fight is lost.
func _roach_next(r: Dictionary) -> void:
	var e: Dictionary = game.fight.e
	if r.at_point:
		r.at_point = false
		r.passes += 1
		var most: int = int(e.get("passes", 3))
		r.node.modulate = Color(Color.WHITE.lerp(game.RED_CROC, minf(1.0, float(r.passes) / most)), r.node.modulate.a)
		if r.passes > most:
			_roach_swarm(r)
			return
	r.leg += 1
	var full: Rect2 = game.fight.full
	var reach: float = r.size.y * 0.3
	if r.leg % int(e.bait_every) == 0:
		var side = -1 if game.rng.randf() < 0.5 else 1
		var p := _roach_spear_point(side)
		var off = Vector2.from_angle(game.rng.randf() * TAU)
		if game.rng.randf() < e.get("fake", 0.0):
			off *= reach * 2.2 + r.size.y * 0.5       # just out of reach
		else:
			off *= reach * game.rng.randf() * 0.6
			r.at_point = true
		r.target = p + off
		r.rest = game.rng.randf_range(e.bait_rest[0], e.bait_rest[1])
	else:
		var span_x: float = e.range * game.unit
		r.target = Vector2(
			clampf(game.fight.stand.x + game.rng.randf_range(-span_x, span_x), full.position.x + 80.0 * game.unit, full.end.x - 80.0 * game.unit),
			game.rng.randf_range(full.position.y + 40.0 * game.unit, full.end.y - 40.0 * game.unit))
		r.rest = game.rng.randf_range(e.rest[0], e.rest[1])
	r.darting = true


func _roach(dt: float) -> void:
	var e: Dictionary = game.fight.e
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	game.fight.clock += dt
	# turn
	var turn := Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if game.fight.get("bot", false):
		turn = _roach_bot()
	if turn != 0.0:
		game.fight.facing = 1 if turn > 0.0 else -1
	# a catch: everything holds still, the spear thrust home, then the rest run again (or it is over)
	if game.fight.freeze > 0.0:
		game.fight.freeze -= dt
		var pinned: Dictionary = game.fight.pinned_roach
		pinned.node.rotation = sin(game.fight.clock * 40.0) * 0.08     # it wriggles on the spear
		_roach_place(pinned, pinned.c)
		if game.fight.freeze <= 0.0:
			game.fight.thrust = game.THRUST_TIME[0] + 0.001             # the spear draws back
			pinned.gone = true                                # and the pinned one is done for
			game._fight_tween(pinned.node).tween_property(pinned.node, "modulate:a", 0.0, 0.3)
			if game.fight.hits >= game.fight.need:
				game.end_fight()
				return
		game._place_bearer()
		return
	if game.fight.thrust >= 0.0:
		game.fight.thrust += dt
		if not game.fight.struck and game.fight.thrust >= game.THRUST_TIME[0]:
			game.fight.struck = true
			_roach_strike()
			if game.fight.freeze > 0.0:
				game.fight.thrust = game.THRUST_TIME[0]                 # held out while it is pinned
				game._place_bearer()
				return
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
	game._place_bearer()
	# each runs, rests, runs
	for r in _roaches():
		if r.darting:
			var d: Vector2 = r.target - r.c
			var step: float = e.dart * game.unit * dt
			if d.length() > 1.0:
				r.node.rotation = lerp_angle(r.node.rotation, d.angle(), minf(1.0, dt * 30.0))
			if d.length() <= step:
				_roach_place(r, r.target)
				r.darting = false
				r.wait = r.rest
				r.rest_from = game.fight.clock
			else:
				_roach_place(r, r.c + d.normalized() * step)
		else:
			r.wait -= dt
			r.node.rotation += sin(game.fight.clock * 23.0 + r.leg) * 0.004     # feelers twitching
			_roach_place(r, r.c)
			if r.wait <= 0.0:
				_roach_next(r)
				if game.fight.lost:
					return


func _roach_strike() -> void:
	var p = _roach_spear_point(game.fight.facing)
	var hit = null
	for r in _roaches():
		if _roach_touches(r, p):
			hit = r
			break
	if hit == null:
		return
	game.fight.hits += 1
	if game.fight.get("bot", false):
		print("ROACH caught at ", snappedf(game.fight.clock, 0.01), " s")
		if OS.has_environment("SHOT_ON_CATCH"):      # dev: a picture of the catch
			game.get_tree().create_timer(0.1).timeout.connect(func():
				game.get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_ON_CATCH")))
	game.fight.freeze = game.ROACH_FREEZE
	game.fight.pinned_roach = hit
	hit.darting = false
	hit.at_point = false
	hit.node.modulate = Color(game.RED_CROC, hit.node.modulate.a)


## Lost: beetle `r` got away from the spear point once too often. Beetles multiply from the ones
## still running until they fill the screen; the bearer crumbles; back on the scroll.
func _roach_swarm(r: Dictionary) -> void:
	var e: Dictionary = game.fight.e
	game.fight.lost = true
	game.say("Scribe", game._feedback_text("swarm"))
	var from: Array = _roaches().map(func(x): return x.c)
	var tex: Texture2D = game._picture(r.node).texture
	var size: Vector2 = r.size
	var full: Rect2 = game.fight.full
	for i in ROACH_SWARM:
		var b = game._make_actor(tex, Rect2(Vector2.ZERO, size))
		var c: Vector2 = from[i % from.size()]
		b.position = c + Vector2(0.0, size.y / 2.0)
		b.rotation = game.rng.randf() * TAU
		b.modulate = Color(Color.WHITE.lerp(game.RED_CROC, game.rng.randf_range(0.3, 1.0)), 0.0)
		game.fight.copies.append(b)
		var to = Vector2(game.rng.randf_range(full.position.x + 40.0 * game.unit, full.end.x - 40.0 * game.unit),
			game.rng.randf_range(full.position.y + 40.0 * game.unit, full.end.y - 20.0 * game.unit))
		var t = game._fight_tween(b)
		t.tween_interval(i * 0.015)
		t.tween_property(b, "modulate:a", 1.0, 0.1)
		t.parallel().tween_property(b, "position", to, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var t = game._fight_tween()
	t.tween_interval(ROACH_SWARM * 0.015 + 0.2)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "roach" and game.fight.e.id == e.id and game.fight.lost:
			game._disintegrate(e))
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "roach" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


func _roach_click(_p: Vector2) -> void:
	game._feedback_once("controls", game._feedback_text("controls"))


## Dev (`--croc-bot`): turns toward a beetle that has rested REACT s within reach, and thrusts.
func _roach_bot() -> float:
	var react: float = float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else CROCODILES.REACT
	for r in _roaches():
		if r.darting or game.fight.clock - r.rest_from < react:
			continue
		var side = 1 if r.c.x > game.fight.pos.x else -1
		if _roach_touches(r, _roach_spear_point(side)):
			if side == game.fight.facing:
				game._croc_thrust()
				return 0.0
			return float(side)
	return 0.0


func autotest(e: Dictionary, expect: Callable) -> void:
	expect.call(game.fight.roaches.size() == int(e.count), e.id + " %d beetles" % int(e.count))
	var r: Dictionary = game.fight.roach
	# a point that misses does nothing; a point on a beetle pins it
	for x in game.fight.roaches:
		x.darting = false
		_roach_place(x, game.fight.full.position + Vector2(10.0, 10.0) * game.unit)
	_roach_place(r, _roach_spear_point(game.fight.facing) + Vector2(0.0, r.size.y * 2.0))
	_roach_strike()
	expect.call(game.fight.hits == 0, e.id + " a thrust that misses the beetles does nothing")
	for i in game.fight.roaches.size():
		var b: Dictionary = game.fight.roaches[i]
		game.fight.freeze = 0.0
		game.fight.facing = 1
		_roach_place(b, _roach_spear_point(-1))
		_roach_strike()
		expect.call(game.fight.hits == i, e.id + " only the side he faces counts")
		game.fight.facing = -1
		_roach_strike()
		expect.call(game.fight.hits == i + 1 and game.fight.freeze > 0.0 and game.fight.pinned_roach == b, e.id + " the spear point pins one, and all holds still")
		b.gone = true
		_roach_place(b, game.fight.full.position)
	expect.call(game.fight.hits == game.fight.need, e.id + " every beetle must be pinned")
	# their darts stop by the spear point every few runs
	for x in game.fight.roaches:
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
	expect.call(r.passes == 1 and r.node.modulate.r > 1.5 and not game.fight.lost, e.id + " a beetle that gets away reddens")
	r.passes = int(e.passes)
	r.at_point = true
	_roach_next(r)
	expect.call(game.fight.lost and game.fight.copies.size() >= ROACH_SWARM, e.id + " away once too often: they swarm, lost")
	game.fight.lost = false
	game.fight.hits = game.fight.need
