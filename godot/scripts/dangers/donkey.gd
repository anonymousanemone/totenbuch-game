## Donkey encounter behavior and acceptance checks.
extends RefCounted

var game
var _filled: Texture2D     ## the donkey filled with papyrus (made once), so the bearer passes behind it


func _init(level) -> void:
	game = level




# the Eater of the Ass (spell 40). The vignette opens out close up; the snake lies on the donkey's
# back as drawn, its front at the rump, and the bearer stands where he is drawn, behind the donkey
# (it is filled with papyrus), his spear point just up its line from the snake's front. The snake
# crawls along the back, between the rump and the withers, turning now and then; [←] [→] step the
# bearer along with it, on the same slant, so his point always rests over the back. Now and then it
# stops, its coils tighten, and it lifts its front up the spear's line (lift_end.gdshader): a thrust
# then, with his point at it, strikes it, and it darts away along the back. Not struck, it lowers
# its head again, one time in three biting the donkey first (in hard mode, see hard(), every time).
# Later some lifts are only half: a thrust then goes into the donkey, as does any thrust while its
# head is down or away from his point, and the donkey flicks its tail. A bite or the spear costs the
# donkey a flesh sign; the third and the snake laughs, and he crumbles with the donkey. Struck
# `need` times, it falls.
const DONKEY_UP_MIN := 0.6       ## its head is clear of the back once lifted this far (of `lift`)
const DONKEY_HALF := 0.45        ## a half lift goes only this far
const DONKEY_RISE := 0.1         ## its front lifts (s) ...
const DONKEY_FALL := 0.15        ## ... and comes down again (s)
const DONKEY_FLICK := [0.07, 0.11]   ## the tail flicks up in irritation, and down again (s), twice ...
const DONKEY_FLICK_ANGLE := -0.7     ## ... this far (rad)
const DONKEY_BITE := 0.14        ## its bite into the donkey's back (s)
const DONKEY_BITE_CHANCE := 1.0 / 3.0   ## a lift not struck ends in a bite this often (in hard mode always)
const DONKEY_PAD := 24           ## room round the snake's picture for its front to lift into (px)
const DONKEY_DART := 3.0         ## struck, it darts away this many times as fast as it crawls
const DONKEY_TURN := 0.25        ## it crawls at least this share of the back before it turns
const DONKEY_WOBBLE := 0.03      ## its loops heave as it crawls
const DONKEY_BOT_REACT := 0.25   ## (--croc-bot) thrusts this long after its head is clear (s)
const DONKEY_UP_JITTER := [0.8, 1.25]   ## each lift lasts `up` s times a share in this range
const LIFT_END := preload("res://scripts/dangers/lift_end.gdshader")
const FIGURE := preload("res://scripts/figure.gdshader")


func _donkey_start(e: Dictionary) -> void:
	var mid_x: float = (game.actors[e.spear].get_meta("home").x + game.actors[e.donkey].get_meta("home").x) / 2.0
	game._arena_setup(e, false, [e.foe, e.donkey, e.tail], {"y1": game.ground + 40.0 * game.unit, "x": mid_x})
	game.fight.stand = game.actors[e.spear].get_meta("home")
	game.fight.pos = game.fight.stand
	game.fight.clock = 0.0
	game.fight.pinned = false
	game.fight.last_thrust = -INF
	game.fight.donkey_health = game.CROC_HEALTH
	game.fight.phase = "crawl"        # crawl, warn, up, bite, pinned
	game.fight.pt = 0.0
	game.fight.lift = 0.0             # 0 = its head down on the back, 1 = lifted the whole `lift`
	game.fight.half = false           # this lift goes only DONKEY_HALF
	game.fight.up_k = 1.0
	game.fight.back = Vector2(float(e.back[0]), float(e.back[1]))   # from the rump to the withers (strip px)
	game.fight.at = 0.0               # the snake along the back: 0 as drawn, 1 at the withers
	game.fight.step = 0.0             # the bearer, likewise
	game.fight.to = _donkey_turn_to(0.0)
	game.fight.dart = false
	game.fight.lift_in = _donkey_lift_gap()
	game.fight.flick = -1.0           # s into the tail's flick; -1 = none
	_donkey_dress(e)
	_donkey_place()
	game._arena_open()


## Tuning value `key` for the strikes so far: from its first value (none) to its last.
func _donkey_tune(key: String) -> float:
	var v: Array = game.fight.e[key]
	return lerpf(float(v[0]), float(v[1]), clampf(float(game.fight.hits) / float(int(game.fight.e.need) - 1), 0.0, 1.0))


## How long it crawls before it next lifts its head (s).
func _donkey_lift_gap() -> float:
	return _donkey_tune("lift_every") * game.rng.randf_range(0.7, 1.3)


## How fast it crawls (share of the back per s); in hard mode `hard_speed` times as fast.
func _donkey_speed() -> float:
	var v: float = _donkey_tune("crawl") * game.unit / game.fight.back.length()
	return v * float(game.fight.e.hard_speed) if game.hard() else v


## Where it crawls to next from `from`: anywhere along the back at least DONKEY_TURN away.
func _donkey_turn_to(from: float) -> float:
	var lo := maxf(0.0, from - DONKEY_TURN)
	var hi := minf(1.0, from + DONKEY_TURN)
	var r: float = game.rng.randf() * (lo + 1.0 - hi)
	return r if r < lo else hi + (r - lo)


## For this fight only: the donkey is filled with papyrus (he stands behind it), and the snake, in
## front of it, gets room round its picture and the shader that lifts its front.
func _donkey_dress(e: Dictionary) -> void:
	var ds: Sprite2D = game._picture(game.actors[e.donkey])
	game.fight.donkey_plain = ds.texture
	game.fight.donkey_at = ds.offset
	if _filled == null:
		_filled = game.FIGURE_MASK.create_texture(ds.texture, 2)
	ds.texture = _filled
	ds.offset -= Vector2(2, 2)
	var fm := ShaderMaterial.new()
	fm.shader = FIGURE
	ds.material = fm
	game.actors[e.foe].z_index = 1
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
	_donkey_unfill()
	game.actors[e.foe].z_index = 0
	if game.fight.has("snake_plain"):
		var sp: Sprite2D = game._picture(game.actors[e.foe])
		sp.texture = game.fight.snake_plain
		sp.offset = game.fight.snake_at
		sp.material = null
	for n in [e.donkey, e.tail]:       # crumbled if it was eaten
		game._picture(game.actors[n]).material = null


## The donkey as drawn again (not filled).
func _donkey_unfill() -> void:
	if game.fight.has("donkey_plain"):
		var ds: Sprite2D = game._picture(game.actors[game.fight.e.donkey])
		ds.texture = game.fight.donkey_plain
		ds.offset = game.fight.donkey_at
		ds.material = null
		game.fight.erase("donkey_plain")


## Where its head is, up the spear's line from where the point rests on it as drawn (plate px).
func _donkey_head_o() -> float:
	return -float(game.fight.e.lift) * game.fight.lift


## His point is at its head: they are this close along the back.
func _donkey_near() -> bool:
	return absf(game.fight.step - game.fight.at) * game.fight.back.length() <= float(game.fight.e.reach) * game.unit


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
	elif game.fight.thrust < 0.0:       # he steps only with his spear back
		_donkey_walk(dt)
	if game.fight.flick >= 0.0:
		game.fight.flick += dt
		if game.fight.flick >= 2.0 * (DONKEY_FLICK[0] + DONKEY_FLICK[1]):
			game.fight.flick = -1.0
	match game.fight.phase:
		"crawl":           # along the back, its head down
			game.fight.lift = maxf(0.0, game.fight.lift - dt / DONKEY_FALL)
			_donkey_crawl(dt)
			if not game.fight.dart:
				game.fight.lift_in -= dt
				if game.fight.lift_in <= 0.0:
					_donkey_phase("warn")
		"warn":            # it stops, and its coils tighten
			if game.fight.pt >= _donkey_tune("warn"):
				game.fight.half = game.rng.randf() < _donkey_tune("half")
				game.fight.up_k = game.rng.randf_range(DONKEY_UP_JITTER[0], DONKEY_UP_JITTER[1])
				_donkey_phase("up")
		"up":              # its head up
			game.fight.lift = minf(DONKEY_HALF if game.fight.half else 1.0, game.fight.lift + dt / DONKEY_RISE)
			if game.fight.pt >= DONKEY_RISE + _donkey_tune("up") * game.fight.up_k:
				if not game.fight.half and (game.hard() or game.rng.randf() < DONKEY_BITE_CHANCE):
					_donkey_phase("bite")
				else:
					_donkey_rest()
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
						game._life_cycle()
					else:
						game.end_fight()
						return
				game.fight.lift = 1.0
				# it darts away from his point
				game.fight.to = game.rng.randf_range(0.0, 0.2) if game.fight.step > 0.5 else game.rng.randf_range(0.8, 1.0)
				game.fight.dart = true
				_donkey_rest()
	_donkey_place()
	game._place_bearer()


func _donkey_phase(p: String) -> void:
	game.fight.phase = p
	game.fight.pt = 0.0


## Its head down again, it crawls on.
func _donkey_rest() -> void:
	game.fight.lift_in = _donkey_lift_gap()
	_donkey_phase("crawl")


## It crawls toward where it is going, and then turns for somewhere else.
func _donkey_crawl(dt: float) -> void:
	var v: float = _donkey_speed() * (DONKEY_DART if game.fight.dart else 1.0)
	game.fight.at = move_toward(game.fight.at, game.fight.to, v * dt)
	if game.fight.at == game.fight.to:
		game.fight.dart = false
		game.fight.to = _donkey_turn_to(game.fight.at)


## [←] [→] (or the bot): he steps along the back, toward the withers or the rump.
func _donkey_walk(dt: float) -> void:
	var axis: float
	if game.fight.get("bot", false):
		axis = game.fight.get("bot_axis", 0.0)
	else:
		axis = Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var v: float = float(game.fight.e.walk) * game.unit / game.fight.back.length()
	game.fight.step = clampf(game.fight.step - clampf(axis, -1.0, 1.0) * v * dt, 0.0, 1.0)


## How far up the tail is now (rad): two quick flicks.
func _donkey_tail_angle() -> float:
	var t: float = game.fight.flick
	if t < 0.0:
		return 0.0
	t = fmod(t, DONKEY_FLICK[0] + DONKEY_FLICK[1])
	var up: float = DONKEY_FLICK[0]
	var u: float = t / up if t < up else 1.0 - (t - up) / DONKEY_FLICK[1]
	return DONKEY_FLICK_ANGLE * sin(PI / 2.0 * clampf(u, 0.0, 1.0))


## The thrust running out: it meets the snake's head if that is up off the back at his point, else
## it goes on into the donkey.
func _donkey_point() -> void:
	var o = game._spear_out()
	if game.fight.lift >= DONKEY_UP_MIN and _donkey_near() and o >= _donkey_head_o() - 1.0:
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
	game._hurt(game.actors[e.foe])
	_donkey_phase("pinned")
	game._dev_shot("SHOT_ON_CATCH")


## The point went into the donkey: it flicks its tail, and loses a flesh sign.
func _donkey_speared() -> void:
	game.fight.flick = 0.0
	_donkey_wounded("life_donkey_speared" if game.endless() else "donkey_speared")


## The snake bites the donkey: a flesh sign lost.
func _donkey_bitten() -> void:
	_donkey_rest()
	_donkey_wounded("donkey_bitten")


## The donkey hurt (by the snake or the spear): a flesh sign lost, unless life holds (the ankh);
## the third and it is eaten. `say`: what the scribe says (once a fight).
func _donkey_wounded(say: String) -> void:
	var e: Dictionary = game.fight.e
	if not game._life_mistake():
		game.fight.donkey_health -= 1
	game._shake(game.actors[e.donkey])
	game._hurt(game.actors[e.donkey])
	if game.fight.donkey_health <= 0:
		_donkey_eaten()
	else:
		game._feedback_once(say, game._feedback_text(say))


## Lost: the snake laughs (squashes up and down) on the donkey's back, and the donkey and the
## spear-bearer crumble together. Then he is back on the scroll.
func _donkey_eaten() -> void:
	var e: Dictionary = game.fight.e
	game.fight.lost = true
	game.say("Scribe", game._feedback_text("donkey_eaten"))
	var sn: Node2D = game.actors[e.foe]
	var t = game._fight_tween()
	for i in 4:
		t.tween_property(sn, "scale", Vector2(1.06, 0.78), 0.1)
		t.tween_property(sn, "scale", Vector2(0.96, 1.12), 0.1)
	t.tween_property(sn, "scale", Vector2.ONE, 0.08)
	t.tween_callback(func():
		_donkey_unfill()
		var mat := ShaderMaterial.new()
		mat.shader = game.DISSOLVE
		mat.set_shader_parameter("grain", 3.0 * game.unit)
		for n in [e.donkey, e.tail]:
			game._picture(game.actors[n]).material = mat
		game._fight_tween().tween_method(func(v: float): mat.set_shader_parameter("amount", v), 0.0, 1.05, 1.6)
		game._disintegrate(e))
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
	# the snake along the back, and the bearer behind the donkey on the same slant
	var sn: Node2D = game.actors[e.foe]
	sn.position = sn.get_meta("home") + game.fight.back * game.fight.at * k
	game.fight.pos = game.fight.stand + game.fight.back * game.fight.step
	# its front lifts up the spear's line, or dips into the back as it bites
	var sp: Sprite2D = game._picture(sn)
	var mat := sp.material as ShaderMaterial
	var up: float = game.fight.lift
	if game.fight.phase == "bite":
		up = -0.25 * sin(PI * minf(game.fight.pt / DONKEY_BITE, 1.0))
	if mat:
		mat.set_shader_parameter("lift", -Vector2(game.fight.dir.x, game.fight.dir.y) * float(e.lift) * game.unit * up * k)
	sn.scale = Vector2.ONE
	match game.fight.phase:
		"crawl":     # its loops heave as it goes
			if game.fight.at != game.fight.to:
				sn.scale = Vector2(1.0, 1.0 + DONKEY_WOBBLE * sin(game.fight.clock * TAU * 3.0))
		"warn":      # its coils tighten
			var u = minf(game.fight.pt / _donkey_tune("warn"), 1.0)
			sn.scale = Vector2(1.0 + 0.04 * u, 1.0 - 0.1 * u)
		"pinned":
			sn.scale = Vector2(1.0 + 0.04 * sin(game.fight.clock * 40.0), 1.0 - 0.04 * sin(game.fight.clock * 40.0))


func _donkey_click(_p: Vector2) -> void:
	if game._time - game.fight.nag > 4.0:
		game.fight.nag = game._time
		game.say("Scribe", game._feedback_text("controls"))


## Dev (`--croc-bot`, and the autotest's trials): steps toward the snake, and thrusts
## DONKEY_BOT_REACT s (or BOT_REACT) after its head is clear of the back at his point. With
## `bot_still` it never steps; with `careless` it thrusts as soon as the head starts up.
func _donkey_bot() -> void:
	var react: float = game.fight.get("bot_react", float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else DONKEY_BOT_REACT)
	var d: float = (game.fight.at - game.fight.step) * game.fight.back.length()
	game.fight.bot_axis = 0.0 if game.fight.get("bot_still", false) or absf(d) < 3.0 else (-1.0 if d > 0.0 else 1.0)
	if game.fight.thrust >= 0.0:
		return
	var ready: bool = game.fight.lift > 0.2 if game.fight.get("careless", false) else game.fight.lift >= DONKEY_UP_MIN
	if game.fight.phase == "up" and ready and _donkey_near():
		if not game.fight.has("bot_seen"):
			game.fight.bot_seen = game.fight.clock
		if game.fight.clock - game.fight.bot_seen >= react:
			game.fight.erase("bot_seen")
			game._croc_thrust()
	else:
		game.fight.erase("bot_seen")


## (autotest) One whole fight against spell 40 played by the bot at reaction `react` (`still`: it
## never steps; `careless`: it thrusts at any lift), in hard mode or not, from random seed `seed`;
## true = won. Leaves the fight stepped out of.
func _donkey_trial(e: Dictionary, react: float, still: bool, careless: bool, hard: bool, seed: int) -> bool:
	var items0: Array[String] = game.items.duplicate()
	game.items.assign([] if hard else ["sail38"])
	game.rng.seed = seed
	game.start_fight(e)
	game.fight.bot = true
	game.fight.bot_react = react
	game.fight.bot_still = still
	game.fight.careless = careless
	var won := false
	var t := 0.0
	while t < 120.0:
		_donkey(1.0 / 60.0)
		t += 1.0 / 60.0
		if game.fight.is_empty() or game.fight.lost:
			won = game.fight.is_empty()
			break
		if game.fight.pinned and game.fight.hits >= int(e.need):
			won = true
			break
	if not game.fight.is_empty():
		game.leave_fight()
	game.solved.erase(e.id)
	game.journal.clear()
	game.items.assign(items0)
	return won


func autotest(e: Dictionary, expect: Callable) -> void:
	var step := func(t: float) -> void:
		while t > 0.0 and not game.fight.is_empty() and not game.fight.lost:
			_donkey(minf(t, 1.0 / 60.0))
			t -= 1.0 / 60.0
	var sn: Node2D = game.actors[e.foe]
	var bearer: Node2D = game.actors[e.spear]
	# hold it still, its head down, at `u` along the back
	var hold := func(u: float) -> void:
		game.fight.at = u
		game.fight.to = u
		game.fight.lift = 0.0
		game.fight.lift_in = 99.0
		_donkey_phase("crawl")
	# lift its head now (`half`: only partway), to stay up a while
	var lift := func(half: bool) -> void:
		game.fight.lift_in = 0.0
		step.call(1.0 / 60.0)
		game.fight.pt = 99.0
		step.call(1.0 / 60.0)
		game.fight.half = half
		game.fight.up_k = 10.0
		step.call(DONKEY_RISE + 0.05)
	var thrust := func() -> void:
		game._croc_thrust()
		step.call(game.THRUST_TIME[0] + 0.02)
	expect.call(game.fight.phase == "crawl" and game.fight.donkey_health == game.CROC_HEALTH, e.id + " it crawls on the donkey's back; the donkey has three flesh signs")
	expect.call(game._picture(game.actors[e.donkey]).material != null and sn.z_index > game.actors[e.donkey].z_index, e.id + " the donkey is filled (he stands behind it), the snake on it in front")
	# it crawls along the back
	hold.call(0.0)
	game.fight.to = 1.0
	var p0: Vector2 = sn.position
	step.call(0.5)
	var moved: Vector2 = sn.position - p0
	expect.call(game.fight.at > 0.0 and absf(moved.normalized().dot(game.fight.back.normalized())) > 0.99, e.id + " it crawls along the line of the back")
	# [←] steps him toward the withers, on the same slant
	hold.call(0.5)
	game.fight.bot = true
	game.fight.bot_still = true
	game.fight.bot_axis = -1.0
	var b0: Vector2 = game.fight.pos
	_donkey_walk(0.3)
	_donkey_place()
	var walked: Vector2 = game.fight.pos - b0
	expect.call(game.fight.step > 0.0 and walked.x < 0.0 and absf(walked.normalized().dot(game.fight.back.normalized())) > 0.99, e.id + " [←] steps him along the back, on its slant")
	game.fight.bot = false
	game.fight.step = 0.5
	# it stops, and its coils tighten; then its head comes up
	hold.call(0.5)
	game.fight.to = 1.0
	game.fight.lift_in = 0.0
	step.call(1.0 / 60.0)
	var at0: float = game.fight.at
	step.call(_donkey_tune("warn") * 0.5)
	expect.call(game.fight.phase == "warn" and game.fight.at == at0 and sn.scale.y < 1.0, e.id + " it stops, and its coils tighten")
	step.call(_donkey_tune("warn") * 0.5 + DONKEY_RISE + 0.03)
	expect.call(game.fight.phase == "up" and game.fight.lift >= DONKEY_UP_MIN, e.id + " ... then it lifts its head")
	# a thrust at it: struck, and it darts away from his point
	game.fight.half = false
	game.fight.up_k = 10.0
	game.fight.lift = 1.0
	thrust.call()
	expect.call(game.fight.hits == 1 and game.fight.donkey_health == game.CROC_HEALTH, e.id + " a thrust while its head is up at his point strikes it")
	step.call(game.ROACH_FREEZE + 0.05)
	expect.call(game.fight.dart and absf(game.fight.to - game.fight.step) >= 0.3, e.id + " ... and it darts away along the back")
	# a thrust while its head is down: into the donkey, which flicks its tail
	hold.call(0.5)
	game.fight.step = 0.5
	step.call(0.3)
	thrust.call()
	expect.call(game.fight.donkey_health == game.CROC_HEALTH - 1 and not game.fight.lost, e.id + " a thrust while its head is down goes into the donkey: a flesh sign lost")
	step.call(DONKEY_FLICK[0] - 0.02)
	expect.call(game.actors[e.tail].rotation < -0.3, e.id + " ... and the donkey flicks its tail")
	step.call(0.5)
	# its head up, but away from his point: into the donkey
	hold.call(0.9)
	game.fight.step = 0.2
	lift.call(false)
	thrust.call()
	expect.call(game.fight.donkey_health == game.CROC_HEALTH - 2 and game.fight.hits == 1, e.id + " its head up away from his point: the thrust goes into the donkey")
	game.fight.donkey_health = game.CROC_HEALTH
	step.call(0.5)
	# a half lift: into the donkey
	hold.call(0.5)
	game.fight.step = 0.5
	lift.call(true)
	expect.call(game.fight.lift < DONKEY_UP_MIN and game.fight.lift > 0.0, e.id + " a half lift: its head only partway up")
	thrust.call()
	expect.call(game.fight.donkey_health == game.CROC_HEALTH - 1 and game.fight.hits == 1, e.id + " ... and a thrust then goes into the donkey")
	game.fight.donkey_health = game.CROC_HEALTH
	step.call(0.5)
	# not struck: with the breath of life it bites one time in three, in hard mode every time
	var bites := func() -> int:
		var n := 0
		for i in 60:
			game.fight.donkey_health = game.CROC_HEALTH
			hold.call(0.5)
			game.fight.step = 0.0
			lift.call(false)
			game.fight.pt = 99.0
			step.call(DONKEY_BITE + 0.05)
			n += 1 if game.fight.donkey_health < game.CROC_HEALTH else 0
		return n
	var easy_bites: int = bites.call()
	game.items.erase("sail38")
	var hard_bites: int = bites.call()
	game.items.append("sail38")
	expect.call(easy_bites >= 10 and easy_bites <= 30, e.id + " with the breath of life a lift not struck bites about one time in three (%d of 60)" % easy_bites)
	expect.call(hard_bites == 60, e.id + " in hard mode a lift not struck always bites")
	# the third wound: the snake laughs, and he crumbles with the donkey
	game.fight.donkey_health = 1
	hold.call(0.5)
	game.fight.step = 0.0
	thrust.call()
	expect.call(game.fight.lost and game.fight.donkey_health == 0, e.id + " the third wound and the donkey is lost")
	game.fight.lost = false
	game.leave_fight()
	# three strikes, each as it lifts its head at his point
	game.start_fight(e)
	for i in int(e.need):
		hold.call(0.4)
		game.fight.step = 0.4
		lift.call(false)
		thrust.call()
		if i < int(e.need) - 1:
			step.call(game.ROACH_FREEZE + 0.05)
	expect.call(game.fight.hits == int(e.need), e.id + " struck three times as it lifted its head")
	game.leave_fight()
	var rate := func(react: float, still: bool, careless: bool, hard: bool) -> float:
		var won := 0
		for i in 40:
			if _donkey_trial(e, react, still, careless, hard, 2000 + i):
				won += 1
		return won / 40.0
	if OS.has_environment("DONKEY_CURVE"):     # dev: the whole curve
		for r in [0.15, 0.25, 0.35, 0.45, 0.55]:
			print("spell 40 curve: react %.2f s -> %d%% won, hard %d%%" % [r, rate.call(r, false, false, false) * 100, rate.call(r, false, false, true) * 100])
	var keen: float = rate.call(0.25, false, false, false)
	var keen_hard: float = rate.call(0.25, false, false, true)
	var slow_hard: float = rate.call(0.5, false, false, true)
	var still: float = rate.call(0.25, true, false, true)
	var careless: float = rate.call(0.0, false, true, false)
	print("spell 40 wins: tracking, striking 0.25 s after its head is up %d%% (hard %d%%), 0.5 s after (hard) %d%%; standing still (hard) %d%%; striking at any lift %d%%" % [keen * 100, keen_hard * 100, slow_hard * 100, still * 100, careless * 100])
	expect.call(keen >= 0.9 and keen_hard >= 0.9, e.id + " an attentive player (0.25 s) wins nearly every fight")
	expect.call(slow_hard <= 0.5, e.id + " in hard mode a slow one (0.5 s) loses at least half")
	expect.call(still <= 0.2, e.id + " not following it along the back loses")
	expect.call(careless <= 0.35, e.id + " striking at every lift (half ones too) mostly loses")
	game.start_fight(e)
	game.fight.hits = int(e.need)
