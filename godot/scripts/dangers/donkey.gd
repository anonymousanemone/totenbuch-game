## Donkey encounter behavior and acceptance checks.
extends RefCounted

var game


func _init(level) -> void:
	game = level




# the Eater of the Ass (spell 40). The vignette opens out close up; the bearer stands where he is
# drawn, his spear point resting just up its line from the snake's front, which lies on the
# donkey's back with its head in it. A thrust while its head is down goes into the donkey: he
# crumbles at once. Now and then the donkey swishes its tail (tail40 turns about its root), and the
# snake lifts its front up the spear's line to snap at it (lift_end.gdshader): a thrust while it is
# up meets its head. After the first strike some swishes are only flicks, and it does not look up.
# Left alone, its coils tighten and it bites the donkey (the flesh signs count the donkey's health);
# the third bite and the donkey is eaten, and he is back on the scroll. Struck `need` times, it falls.
const DONKEY_UP_MIN := 0.6       ## its head is clear of the back once lifted this far (of `lift`)
const DONKEY_RISE := 0.1         ## its front lifts (s) ...
const DONKEY_FALL := 0.15        ## ... and comes down again (s)
const DONKEY_SWISH := [0.25, 0.35]   ## the tail goes up, and down again (s)
const DONKEY_SWISH_ANGLE := -1.0     ## how far it goes up (rad)
const DONKEY_FLICK_ANGLE := -0.35    ## a flick
const DONKEY_SNAP_AFTER := 0.12  ## the snake looks up this long after the swish begins (s)
const DONKEY_BITE := 0.14        ## its bite into the donkey's back (s)
const DONKEY_PAD := 24           ## room round the snake's picture for its front to lift into (px)
const DONKEY_BOT_REACT := 0.25   ## (--croc-bot) thrusts this long after its head is clear (s)
const DONKEY_UP_JITTER := [0.8, 1.25]   ## each look up lasts `up` s times a share in this range
const DONKEY_FAIR := 1.3         ## a bite this close and no look up since the last: the donkey swishes now (s)
const LIFT_END := preload("res://scripts/dangers/lift_end.gdshader")


func _donkey_start(e: Dictionary) -> void:
	var mid_x: float = (game.actors[e.spear].get_meta("home").x + game.actors[e.donkey].get_meta("home").x) / 2.0
	game._arena_setup(e, false, [e.foe, e.donkey, e.tail], {"y1": game.ground + 40.0 * game.unit, "x": mid_x})
	game.fight.stand = game.actors[e.spear].get_meta("home")
	game.fight.pos = game.fight.stand
	game.fight.clock = 0.0
	game.fight.pinned = false
	game.fight.last_thrust = -INF
	game.fight.donkey_health = game.CROC_HEALTH
	game.fight.phase = "latched"      # latched, up, warn, bite, pinned
	game.fight.pt = 0.0
	game.fight.lift = 0.0             # 0 = its head down in the donkey, 1 = lifted the whole `lift`
	game.fight.bite_in = _donkey_tune("bite_every")
	game.fight.offered = false        # it has looked up since the last strike or bite (each bite gets a chance first)
	game.fight.up_k = 1.0
	game.fight.swish = {"t": -1.0, "angle": 0.0, "real": false, "next": game.rng.randf_range(float(e.swish_gap[0]), float(e.swish_gap[1]))}
	game.fight.told = {}
	_donkey_dress(e)
	_donkey_place()
	game._arena_open()


## Tuning value `key` for the strikes so far: from its first value (none) to its last.
func _donkey_tune(key: String) -> float:
	var v: Array = game.fight.e[key]
	return lerpf(float(v[0]), float(v[1]), clampf(float(game.fight.hits) / float(int(game.fight.e.need) - 1), 0.0, 1.0))


## For this fight only: the snake gets room round its picture and the shader that lifts its front.
func _donkey_dress(e: Dictionary) -> void:
	var sp: Sprite2D = game._picture(game.actors[e.foe])
	game.fight.snake_plain = sp.texture
	game.fight.snake_at = sp.offset
	var src := sp.texture.get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var P := DONKEY_PAD
	var img := Image.create(src.get_width() + 2 * P, src.get_height() + 2 * P, false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(P, P))
	sp.texture = ImageTexture.create_from_image(img)
	sp.offset -= Vector2(P, P)
	var mat := ShaderMaterial.new()
	mat.shader = LIFT_END
	mat.set_shader_parameter("from_x", float(e.lift_from) + P)
	mat.set_shader_parameter("to_x", float(e.lift_to) + P)
	sp.material = mat


func _donkey_undress() -> void:
	var e: Dictionary = game.fight.e
	if game.fight.has("snake_plain"):
		var sp: Sprite2D = game._picture(game.actors[e.foe])
		sp.texture = game.fight.snake_plain
		sp.offset = game.fight.snake_at
		sp.material = null
	for n in [e.donkey, e.tail]:       # crumbled if it was eaten
		game._picture(game.actors[n]).material = null


## Where its head is, up the spear's line from where the point rests on it as drawn (plate px).
func _donkey_head_o() -> float:
	return -float(game.fight.e.lift) * game.fight.lift


func _donkey(dt: float) -> void:
	var e: Dictionary = game.fight.e
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	game.fight.clock += dt
	game.fight.pt += dt
	if game.fight.get("bot", false):
		_donkey_bot()
	if game.fight.thrust >= 0.0 and not game.fight.pinned:
		game.fight.thrust += dt
		if not game.fight.struck:
			_donkey_point()
			if game.fight.lost:
				return
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
	_donkey_tail(dt)
	match game.fight.phase:
		"latched":         # its head in the donkey's back; the bite comes nearer
			game.fight.lift = maxf(0.0, game.fight.lift - dt / DONKEY_FALL)
			game.fight.bite_in -= dt
			if game.fight.bite_in <= 0.0:
				_donkey_phase("warn")
		"up":              # snapping at the tail
			game.fight.lift = minf(1.0, game.fight.lift + dt / DONKEY_RISE)
			if game.fight.pt >= DONKEY_RISE + _donkey_tune("up") * game.fight.up_k:
				_donkey_phase("latched")
		"warn":            # its coils tighten
			if game.fight.pt >= float(e.warn):
				_donkey_phase("bite")
		"bite":            # and it bites the donkey
			if game.fight.pt >= DONKEY_BITE:
				_donkey_bitten()
				if game.fight.lost:
					return
		"pinned":
			if game.fight.pt >= game.ROACH_FREEZE:
				game.fight.pinned = false
				game.fight.thrust = game.THRUST_TIME[0] + 0.001
				if game.fight.hits >= int(e.need):
					if game.endless():
						game.fight.hits = 0
					else:
						game.end_fight()
						return
				game.fight.lift = 1.0
				_donkey_phase("latched")
	_donkey_place()
	game._place_bearer()


func _donkey_phase(p: String) -> void:
	game.fight.phase = p
	game.fight.pt = 0.0


## The donkey's tail: now and then it swishes up and down again (sometimes, after the first
## strike, only a flick); the snake looks up at a real swish, if its head is down and not biting.
func _donkey_tail(dt: float) -> void:
	var sw: Dictionary = game.fight.swish
	var e: Dictionary = game.fight.e
	if sw.t < 0.0:
		sw.next -= dt
		# never a bite without a chance first: a bite near and no look up since the last, it swishes now
		var owed: bool = game.fight.phase == "latched" and not game.fight.offered and game.fight.bite_in < DONKEY_FAIR
		if sw.next <= 0.0 or owed:
			sw.t = 0.0
			sw.real = owed or game.fight.hits == 0 or game.rng.randf() >= float(e.flick)
			sw.angle = DONKEY_SWISH_ANGLE if sw.real else DONKEY_FLICK_ANGLE
			sw.looked = false
		return
	sw.t += dt
	if sw.real and not sw.looked and sw.t >= DONKEY_SNAP_AFTER:
		sw.looked = true
		if game.fight.phase == "latched":
			_donkey_phase("up")
			game.fight.offered = true
			game.fight.up_k = game.rng.randf_range(DONKEY_UP_JITTER[0], DONKEY_UP_JITTER[1])
	if sw.t >= DONKEY_SWISH[0] + DONKEY_SWISH[1]:
		sw.t = -1.0
		sw.next = game.rng.randf_range(float(e.swish_gap[0]), float(e.swish_gap[1]))


## How far up the tail is now (rad).
func _donkey_tail_angle() -> float:
	var sw: Dictionary = game.fight.swish
	if sw.t < 0.0:
		return 0.0
	var up: float = DONKEY_SWISH[0]
	var u: float = sw.t / up if sw.t < up else 1.0 - (sw.t - up) / DONKEY_SWISH[1]
	return sw.angle * sin(PI / 2.0 * clampf(u, 0.0, 1.0))


## The thrust running out: it meets the snake's head if that is up off the back, else it goes on
## into the donkey.
func _donkey_point() -> void:
	var o = game._spear_out()
	if game.fight.lift >= DONKEY_UP_MIN and o >= _donkey_head_o() - 1.0:
		game.fight.struck = true
		_donkey_struck()
	elif o >= -1.0:
		game.fight.struck = true
		_donkey_speared()


func _donkey_struck() -> void:
	var e: Dictionary = game.fight.e
	game.fight.hits += 1
	game._life_hit()
	game.fight.pinned = true
	game.fight.bite_in = _donkey_tune("bite_every")        # struck, it lets go of the donkey a while
	game.fight.offered = false
	game._hurt(game.actors[e.foe])
	_donkey_phase("pinned")
	game._dev_shot("SHOT_ON_CATCH")
	if game.endless():
		game.say("Scribe", game._feedback_text("life_hit"))
		return
	var left: int = int(e.need) - game.fight.hits
	game.say("Scribe", (game._feedback_text("struck_more") % left if left > 0 else game._feedback_text("struck")))


## The point went into the donkey: he crumbles at once.
func _donkey_speared() -> void:
	var e: Dictionary = game.fight.e
	if game._life_mistake():
		game._shake(game.actors[e.donkey])
		game._hurt(game.actors[e.donkey])
		game.fight.bite_in = _donkey_tune("bite_every")
		game.fight.offered = false
		_donkey_phase("latched")
		game.say("Scribe", game._feedback_text("life_donkey_speared"))
		return
	game.fight.lost = true
	game._shake(game.actors[e.donkey])
	game._hurt(game.actors[e.donkey])
	game.say("Scribe", game._feedback_text("donkey_speared"))
	game._disintegrate(e)
	_donkey_lost_later(e)


## The snake bites the donkey: a flesh sign lost; the third and it is eaten.
func _donkey_bitten() -> void:
	var e: Dictionary = game.fight.e
	if not game._life_mistake():
		game.fight.donkey_health -= 1
	game._shake(game.actors[e.donkey])
	game._hurt(game.actors[e.donkey])
	game.fight.bite_in = _donkey_tune("bite_every")
	game.fight.offered = false
	_donkey_phase("latched")
	if game.fight.donkey_health <= 0:
		game.fight.lost = true
		game.say("Scribe", game._feedback_text("donkey_eaten"))
		var mat := ShaderMaterial.new()
		mat.shader = game.DISSOLVE
		mat.set_shader_parameter("grain", 3.0 * game.unit)
		for n in [e.donkey, e.tail, e.foe]:
			game._picture(game.actors[n]).material = mat
		game.create_tween().tween_method(func(v: float): mat.set_shader_parameter("amount", v), 0.0, 1.05, 1.6)
		_donkey_lost_later(e)
		return
	if not game.fight.told.has("bite"):
		game.fight.told.bite = true
		game.say("Scribe", game._feedback_text("donkey_bitten"))


func _donkey_lost_later(e: Dictionary) -> void:
	var t = game.create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "donkey" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


func _donkey_place() -> void:
	var e: Dictionary = game.fight.e
	var k: float = game.fight.open
	# the tail turns about its root
	var tail: Node2D = game.actors[e.tail]
	var root := Vector2(float(e.tail_root[0]), float(e.tail_root[1]))
	var ang := _donkey_tail_angle() * k
	tail.rotation = ang
	tail.position = root + (tail.get_meta("home") - root).rotated(ang)
	# the snake's front lifts up the spear's line, or dips into the back as it bites
	var sp: Sprite2D = game._picture(game.actors[e.foe])
	var mat := sp.material as ShaderMaterial
	var up: float = game.fight.lift
	if game.fight.phase == "bite":
		up = -0.25 * sin(PI * minf(game.fight.pt / DONKEY_BITE, 1.0))
	if mat:
		mat.set_shader_parameter("lift", -Vector2(game.fight.dir.x, game.fight.dir.y) * float(e.lift) * game.unit * up * k)
	var sn: Node2D = game.actors[e.foe]
	sn.scale = Vector2.ONE
	if game.fight.phase == "warn":       # its coils tighten
		var u = minf(game.fight.pt / float(e.warn), 1.0)
		sn.scale = Vector2(1.0 + 0.04 * u, 1.0 - 0.1 * u)
	elif game.fight.phase == "pinned":
		sn.scale = Vector2(1.0 + 0.04 * sin(game.fight.clock * 40.0), 1.0 - 0.04 * sin(game.fight.clock * 40.0))


func _donkey_click(_p: Vector2) -> void:
	if game._time - game.fight.nag > 4.0:
		game.fight.nag = game._time
		game.say("Scribe", game._feedback_text("controls"))


## Dev (`--croc-bot`, and the autotest's trials): thrusts DONKEY_BOT_REACT s (or BOT_REACT) after
## its head is clear of the back. With `tail_watcher`, it thrusts that long after any swish begins,
## whatever the snake does.
func _donkey_bot() -> void:
	var react: float = game.fight.get("bot_react", float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else DONKEY_BOT_REACT)
	if game.fight.thrust >= 0.0:
		return
	if game.fight.get("tail_watcher", false):
		var sw: Dictionary = game.fight.swish
		if sw.t >= react and sw.t - react < 0.02:
			game._croc_thrust()
		return
	if game.fight.phase == "up" and game.fight.lift >= DONKEY_UP_MIN:
		if not game.fight.has("bot_seen"):
			game.fight.bot_seen = game.fight.clock
		if game.fight.clock - game.fight.bot_seen >= react:
			game.fight.erase("bot_seen")
			game._croc_thrust()
	else:
		game.fight.erase("bot_seen")


## (autotest) One whole fight against spell 40 played by the bot; true = won.
func _donkey_trial(e: Dictionary, react: float, tail_watcher: bool, seed: int) -> bool:
	game.rng.seed = seed
	game.start_fight(e)
	game.fight.bot = true
	game.fight.bot_react = react
	game.fight.tail_watcher = tail_watcher
	var won := false
	var t := 0.0
	while t < 120.0:
		_donkey(1.0 / 60.0)
		t += 1.0 / 60.0
		if game.fight.is_empty():
			won = true
			break
		if game.fight.lost:
			break
		if game.fight.pinned and game.fight.hits >= int(e.need):
			won = true
			break
	if not game.fight.is_empty():
		game.leave_fight()
	game.solved.erase(e.id)
	game.journal.clear()
	return won


func autotest(e: Dictionary, expect: Callable) -> void:
	var step := func(t: float) -> void:
		while t > 0.0 and not game.fight.is_empty() and not game.fight.lost:
			_donkey(minf(t, 1.0 / 60.0))
			t -= 1.0 / 60.0
	var swish := func(real: bool) -> void:      # the donkey swishes (or flicks) its tail now
		game.fight.swish.next = 0.0
		game.fight.swish.t = -1.0
		_donkey_tail(0.0)
		game.fight.swish.real = real
		game.fight.swish.angle = DONKEY_SWISH_ANGLE if real else DONKEY_FLICK_ANGLE
	expect.call(game.fight.phase == "latched" and game.fight.lift == 0.0 and game.fight.donkey_health == game.CROC_HEALTH, e.id + " its head is down in the donkey's back; the donkey has three flesh signs")
	# a thrust while its head is down goes into the donkey: he crumbles at once
	game._croc_thrust()
	step.call(game.THRUST_TIME[0] + 0.02)
	expect.call(game.fight.lost and game.fight.hits == 0, e.id + " a thrust while its head is down strikes the donkey: lost at once")
	game.fight.lost = false
	game.leave_fight()
	game.start_fight(e)
	game.fight.bite_in = 99.0
	# a swish: the tail goes up, and the snake lifts its head to it
	swish.call(true)
	step.call(DONKEY_SWISH[0])
	expect.call(game.actors[e.tail].rotation < -0.5, e.id + " the donkey swishes its tail")
	expect.call(game.fight.phase == "up" and game.fight.lift >= DONKEY_UP_MIN, e.id + " the snake lifts its head to snap at the tail")
	game._croc_thrust()
	step.call(game.THRUST_TIME[0] + 0.02)
	expect.call(game.fight.hits == 1 and not game.fight.lost, e.id + " a thrust while its head is up strikes it")
	step.call(game.ROACH_FREEZE + 0.5)
	# after the first strike, a flick: it does not look up
	swish.call(false)
	step.call(DONKEY_SWISH[0] + DONKEY_SWISH[1])
	expect.call(game.fight.phase == "latched" and game.fight.lift < DONKEY_UP_MIN, e.id + " a flick of the tail: it does not look up")
	# left alone, it bites the donkey; the third bite and the donkey is eaten
	game.fight.swish.next = 99.0
	game.fight.bite_in = 0.01
	step.call(float(e.warn) + DONKEY_BITE + 0.05)
	expect.call(game.fight.donkey_health == game.CROC_HEALTH - 1 and not game.fight.lost, e.id + " left alone, it bites the donkey: a flesh sign lost")
	expect.call(game.fight.bite_in > 3.0, e.id + " ...and the next bite is a while off")
	for i in 2:
		game.fight.bite_in = 0.01
		step.call(float(e.warn) + DONKEY_BITE + 0.05)
	expect.call(game.fight.lost and game.fight.donkey_health == 0, e.id + " the third bite and the donkey is eaten: lost")
	game.fight.lost = false
	game.leave_fight()
	# three strikes, each as it looks up at the tail
	game.start_fight(e)
	game.fight.bite_in = 99.0
	for i in int(e.need):
		game.fight.swish.next = 99.0
		swish.call(true)
		step.call(DONKEY_SWISH[0])
		game._croc_thrust()
		step.call(game.THRUST_TIME[0] + 0.02)
		if i < int(e.need) - 1:
			step.call(game.ROACH_FREEZE + 0.5)
			game.fight.bite_in = 99.0
	expect.call(game.fight.hits == int(e.need), e.id + " struck three times as it looked up")
	game.leave_fight()
	var rate := func(react: float, watcher: bool) -> float:
		var won := 0
		for i in 40:
			if _donkey_trial(e, react, watcher, 2000 + i):
				won += 1
		return won / 40.0
	if OS.has_environment("DONKEY_CURVE"):     # dev: the whole curve
		for r in [0.2, 0.3, 0.4, 0.5, 0.6]:
			print("spell 40 curve: react %.2f s -> %d%% won" % [r, rate.call(r, false) * 100])
	var keen: float = rate.call(0.3, false)
	var slow: float = rate.call(0.55, false)
	var watcher: float = rate.call(0.25, true)
	print("spell 40 wins: striking 0.3 s after its head is up %d%%, 0.55 s after %d%%, on every swish of the tail %d%%" % [keen * 100, slow * 100, watcher * 100])
	expect.call(keen >= 0.9, e.id + " an attentive player (0.3 s) wins nearly every fight")
	expect.call(slow <= 0.5, e.id + " a slow one (0.55 s) loses at least half")
	expect.call(watcher <= 0.35, e.id + " striking at every swish (not watching the head) mostly loses")
	game.start_fight(e)
	game.fight.hits = int(e.need)
