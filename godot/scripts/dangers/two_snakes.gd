## Two snakes encounter behavior and acceptance checks.
extends RefCounted

var game


func _init(level) -> void:
	game = level




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
	var bearer: Node2D = game.actors[e.spear]
	game._arena_setup(e, true, [e.foe] + e.signs, {"y1": game.ground + 24.0 * game.unit, "x": bearer.get_meta("home").x})
	game.fight.stand = bearer.get_meta("home")          # he stays where he is drawn: his point is on the snake
	game.fight.pos = game.fight.stand
	game.fight.health = game.CROC_HEALTH
	game.fight.clock = 0.0
	game.fight.last_thrust = -INF
	game.fight.pinned = false
	game.fight.idle = game.rng.randf_range(float(e.idle[0]), float(e.idle[1])) + 0.6
	var left: Node2D = game.actors[e.foe]
	var home: Vector2 = left.get_meta("home")
	var right = game._make_actor(game._picture(left).texture, game.rects[e.foe])
	right.set_meta("home", Vector2(2.0 * game.fight.stand.x - home.x, home.y))   # mirrored about him
	right.position = right.get_meta("home")
	game.fight.copies = [right]
	game.fight.snakes = []
	for i in 2:
		game.fight.snakes.append({"node": [left, right][i], "side": [-1, 1][i], "glyph": game.actors[e.signs[i]], "hits": 0,
			"phase": "rest", "t": 0.0, "off": float(e.rest) * game.unit, "from": 0.0, "sx": 1.0, "sy": 1.0, "w": 0.0})
	_twin_place()
	game._arena_open()


## Each snake as it is now: `off` px out from where it is drawn (as the vignette opens it draws back
## there and turns to face him; the copy fades in), squashed or writhing. The sign of the one about
## to strike flashes red, and stays red until it has struck (or been struck).
func _twin_place() -> void:
	var k: float = game.fight.open
	var pulse = 0.5 + 0.5 * sin(game._time * 10.0)
	for s in game.fight.snakes:
		var a: Node2D = s.node
		a.position = a.get_meta("home") + Vector2(s.side * s.off * k, 0.0)
		a.scale = Vector2(lerpf(-1.0, 1.0, k) * s.side * s.sx * (1.0 + s.w), lerpf(1.0, s.sy, k) * (1.0 - s.w))
		if s.side > 0:
			a.modulate.a = k
		var glyph: Node2D = s.glyph
		match s.phase:
			"warn": glyph.modulate = Color.WHITE.lerp(game.RED_CROC, pulse)
			"crouch", "snap": glyph.modulate = game.RED_CROC
			_: glyph.modulate = Color.WHITE


func _twin_phase(s: Dictionary, p: String) -> void:
	s.phase = p
	s.t = 0.0


## How far along the fight is (0 at the first strike, 1 at the last), for the shrinking times.
func _twin_k() -> float:
	return clampf(float(game.fight.hits) / maxf(1.0, 2.0 * float(game.fight.e.need) - 1.0), 0.0, 1.0)


## One of `e[key]`'s two values, as far along as the fight is.
func _twin_tune(key: String) -> float:
	var v: Array = game.fight.e[key]
	return lerpf(float(v[0]), float(v[1]), _twin_k())


func _twin(dt: float) -> void:
	var e: Dictionary = game.fight.e
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	game.fight.clock += dt
	var turn := Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if game.fight.get("bot", false):
		turn = _twin_bot()
	if turn != 0.0 and not game.fight.pinned:
		game.fight.facing = 1 if turn > 0.0 else -1
	# was the point down at any time during this frame (a slow frame may step right over it)?
	var down := false
	if game.fight.thrust >= 0.0 and not game.fight.pinned:
		var span = game._thrust_down_span()
		down = game.fight.thrust <= span.y and game.fight.thrust + dt >= span.x
		game.fight.thrust += dt
		if not game.fight.struck and game.fight.thrust >= game.THRUST_TIME[0]:
			game.fight.struck = true
			_twin_provoke()
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
	game.fight.red = maxf(0.0, game.fight.red - dt)
	# when neither is busy, after a while one of them (still coiled) is about to strike
	if not game.fight.snakes.any(func(x): return x.phase in TWIN_BUSY):
		game.fight.idle -= dt
		if game.fight.idle <= 0.0:
			var up: Array = game.fight.snakes.filter(func(x): return x.phase == "rest")
			if not up.is_empty():
				_twin_phase(up[game.rng.randi() % up.size()], "warn")
			game.fight.idle = game.rng.randf_range(float(e.idle[0]), float(e.idle[1]))
	var rest = float(e.rest) * game.unit
	var reach = _twin_tune("reach") * game.unit
	var bite = float(e.bite) * game.unit
	var breathe = 1.0 + 0.018 * sin(game.fight.clock * TAU / 1.6)
	for s in game.fight.snakes:
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
				if down and game.fight.facing == s.side and was >= -reach and s.off <= reach:
					_twin_caught(s)
				elif u >= 1.0:
					_twin_phase(s, "bitten")
					_twin_bites(s)
					if game.fight.lost:
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
				s.w = 0.05 * sin(game.fight.clock * 40.0)
				if s.t >= game.ROACH_FREEZE:
					game.fight.pinned = false
					game.fight.struck = true
					game.fight.thrust = game.THRUST_TIME[0] + 0.001          # the spear draws back up
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
					if game.fight.snakes.all(func(x): return x.phase == "fallen"):
						game.end_fight()
						return
	_twin_place()
	game._place_bearer()


func _twin_back(s: Dictionary) -> void:
	s.from = s.off
	_twin_phase(s, "back")


func _twin_caught(s: Dictionary) -> void:
	s.hits += 1
	game.fight.hits += 1
	game.fight.pinned = true
	game._hurt(s.node)
	_twin_phase(s, "pinned")
	game._dev_shot("SHOT_ON_CATCH")
	game.say("Scribe", game._feedback_text("struck_final" if s.hits >= int(game.fight.e.need) else "struck_partial"))


## The spear at full thrust on the side he faces, with the snake there still coiled: it sees it and
## springs at once.
func _twin_provoke() -> void:
	var s: Dictionary = game.fight.snakes[0 if game.fight.facing < 0 else 1]
	if not s.phase in ["rest", "warn"]:
		return
	s.why = game._feedback_text("provoked")
	_twin_phase(s, "snap")
	s.for = _twin_tune("snap")
	s.from = s.off


func _twin_bites(s: Dictionary) -> void:
	game._dev_shot("SHOT_ON_BITE")
	game.fight.red = 0.8
	game.fight.health -= 1
	game.bites += 1
	if game.fight.health <= 0:
		game.fight.lost = true
		var e: Dictionary = game.fight.e
		game.say("Scribe", game._hints.message("dangers.defeated"))
		game._disintegrate(e)
		var t = game._fight_tween()
		t.tween_interval(2.0)
		t.tween_callback(func():
			if not game.fight.is_empty() and game.fight.kind == "twin" and game.fight.e.id == e.id and game.fight.lost:
				game._arena_lost(e))
		return
	var why: String = s.get("why", "")
	s.erase("why")
	if why == "":
		if game.fight.facing != s.side:
			why = game._feedback_text("wrong_direction")
		elif game.fight.clock - game.fight.last_thrust < float(s.for) + 0.4:
			why = game._feedback_text("mistimed_thrust")
		else:
			why = game._feedback_text("bite_advice")
	game._feedback_once(why, game._feedback_text("bitten") % why)


func _twin_click(_p: Vector2) -> void:
	game._feedback_once("controls", game._feedback_text("controls"))


## Dev (`--croc-bot`): turns to the snake whose sign flashes and thrusts TWIN_BOT_AIM s after the
## middle of the window the autotest measures (with BOT_MISS it never thrusts, to see them bite).
func _twin_bot() -> float:
	for s in game.fight.snakes:
		if s.phase in ["warn", "crouch", "snap"]:
			if game.fight.facing != s.side:
				return float(s.side)
			if s.phase == "crouch" and not s.has("bot_at") and not OS.has_environment("BOT_MISS"):
				s.bot_at = game.fight.clock + float(s.for) + 0.1 + _twin_aim() + TWIN_BOT_AIM
			if s.has("bot_at") and game.fight.clock >= s.bot_at:
				s.erase("bot_at")
				game._croc_thrust()
	return 0.0


## When to press Space (s from the start of the snap) to strike a springing snake: as it passes
## the spot where it is drawn, less the time the point takes to come down.
func _twin_aim() -> float:
	var rest = float(game.fight.e.rest)
	var bite = float(game.fight.e.bite)
	var u := 1.0 - sqrt(maxf(0.0, 1.0 - rest / (rest + bite)))      # the snap's ease-out reaches 0 here
	var span = game._thrust_down_span()
	return u * _twin_tune("snap") - (span.x + span.y) / 2.0


## (autotest) The snake on side `side` squashing, Space pressed `tau` s from the start of its snap
## (facing it); true = struck. The other is kept quiet.
func _twin_try(side: int, tau: float) -> bool:
	var s: Dictionary = game.fight.snakes[0 if side < 0 else 1]
	var other: Dictionary = game.fight.snakes[1 if side < 0 else 0]
	var hits: int = s.hits
	game.fight.facing = side
	game.fight.thrust = -1.0
	game.fight.pinned = false
	game.fight.idle = 99.0
	if not other.phase in ["fall", "fallen"]:
		_twin_phase(other, "rest")
	s.off = float(game.fight.e.rest) * game.unit
	_twin_phase(s, "crouch")
	s.for = _twin_tune("crouch")
	var dt := 1.0 / 240.0
	var t: float = -(float(s.for) + 0.1)
	var pressed := false
	while t < 0.6:
		if not pressed and t >= tau:
			pressed = true
			game._croc_thrust()
		_twin(dt)
		t += dt
		if s.hits > hits or s.phase == "bitten" or game.fight.lost:
			break
	return s.hits > hits


## (autotest) The span of press times (from the start of the snap) that strike; leaves no hit counted.
func _twin_window(side: int) -> Array:
	var s: Dictionary = game.fight.snakes[0 if side < 0 else 1]
	var lo := INF
	var hi := -INF
	var tau := -0.4
	while tau <= 0.4:
		game.fight.health = 99
		var hits: int = s.hits
		var all: int = game.fight.hits
		if _twin_try(side, tau):
			lo = minf(lo, tau)
			hi = maxf(hi, tau)
		s.hits = hits
		game.fight.hits = all
		game.fight.pinned = false
		tau += 0.005
	game.fight.health = game.CROC_HEALTH
	_twin_phase(s, "rest")
	return [lo, hi]


func autotest(e: Dictionary, expect: Callable) -> void:
	var L: Dictionary = game.fight.snakes[0]
	var R: Dictionary = game.fight.snakes[1]
	var need := int(e.need)
	expect.call(absf((L.node.position.x - game.fight.pos.x) + (R.node.position.x - game.fight.pos.x)) < 1.0, e.id + " a snake on either side of him, mirrored")
	expect.call(L.glyph.position.x < R.glyph.position.x and L.glyph.modulate.a == 1.0 and R.glyph.modulate.a == 1.0, e.id + " the two snake signs, left and right, stay in view as the vignette opens")
	_twin(0.0)
	expect.call(L.node.scale.x < 0.0 and R.node.scale.x > 0.0, e.id + " both turned to face him (the drawn one flipped)")
	expect.call(L.off >= float(e.rest) * game.unit and absf(L.node.position.x - L.node.get_meta("home").x) >= float(e.rest) * game.unit - 0.5, e.id + " they wait well out from where they are drawn")
	# the one about to strike: its sign flashes red, it squashes and springs
	game.fight.idle = 99.0
	_twin_phase(R, "warn")
	game._time = PI / 20.0           # the top of the flash
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
	game.fight.health = 99
	expect.call(not _twin_try(1, -0.35), e.id + " a thrust well before it springs is too early")
	expect.call(not _twin_try(1, 0.3), e.id + " a thrust after it is past is too late")
	expect.call(R.phase == "bitten" and R.off < 0.0, e.id + " at the end of its spring it is past where it is drawn, at his foot")
	_twin(0.41)
	_twin(TWIN_BACK + 0.01)
	expect.call(R.phase == "rest", e.id + " it slides back to where it waits")
	# facing the other way, the thrust strikes nothing and it bites
	game.fight.health = game.CROC_HEALTH
	var mid: float = (good[0] + good[1]) / 2.0
	game.fight.facing = -1
	_twin_phase(R, "crouch")
	R.for = 0.0
	_twin(0.11)
	var t := 0.0
	while R.phase == "snap" and t < 1.0:
		if t >= mid and game.fight.thrust < 0.0 and not game.fight.struck:
			game._croc_thrust()
		_twin(1.0 / 240.0)
		t += 1.0 / 240.0
	expect.call(R.hits == 0 and game.fight.health == game.CROC_HEALTH - 1, e.id + " a thrust the other way strikes nothing, and the snake bites")
	_twin_phase(R, "rest")
	R.off = float(e.rest) * game.unit
	# a thrust at a snake still coiled: it springs at once
	game.fight.facing = -1
	game.fight.thrust = -1.0
	_twin_phase(L, "rest")
	game._croc_thrust()
	while game.fight.thrust >= 0.0 and game.fight.thrust < game.THRUST_TIME[0]:
		_twin(1.0 / 240.0)
	expect.call(L.phase == "snap", e.id + " a thrust at a coiled snake: it sees the spear and springs")
	for i in 240:
		_twin(1.0 / 240.0)
	expect.call(L.hits == 0, e.id + " ...out of the spear's way, and bites")
	_twin(0.41)
	_twin(TWIN_BACK + 0.01)
	game.fight.thrust = -1.0
	# struck `need` times, a snake falls where it is drawn, and only the other strikes after
	for i in need:
		game.fight.health = game.CROC_HEALTH
		expect.call(_twin_try(-1, (_twin_window(-1)[0] + _twin_window(-1)[1]) / 2.0), e.id + " struck as it springs (%d)" % (i + 1))
		_twin(game.ROACH_FREEZE + 0.01)
		if i < need - 1:
			_twin(TWIN_BACK + 0.01)
	_twin(TWIN_FALL + 0.01)
	expect.call(L.phase == "fallen" and absf(L.node.position.x - L.node.get_meta("home").x) < 1.0 and not game.fight.is_empty(), e.id + " struck %d times, a snake falls where it is drawn" % need)
	var last: Array = _twin_window(1)
	print("spell 37 last window: %.0f ms" % ((last[1] - last[0]) * 1000.0))
	expect.call(last[1] - last[0] < good[1] - good[0] and last[1] - last[0] >= 0.04, e.id + " the window grows shorter with each strike, and can still be struck")
	game.fight.idle = 0.0
	_twin(0.0)
	expect.call(R.phase == "warn", e.id + " only the snake still coiled strikes")
	game.fight.health = 1
	_twin_try(1, -0.35)
	expect.call(game.fight.lost, e.id + " the third bite and he crumbles")
	game.fight.lost = false
