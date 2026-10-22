## Apep encounter behavior and acceptance checks.
extends RefCounted

var game


func _init(level) -> void:
	game = level




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
const APEP_WAVE := preload("res://scripts/dangers/apep_wave.gdshader")
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
	var s = game.span(e)
	game._arena_setup(e, false, [e.foe], {"y1": game.ground + 24.0 * game.unit, "x": (s.x + s.y) / 2.0})
	game.fight.stand = game.actors[e.spear].get_meta("home")
	game.fight.pos = game.fight.stand
	game.fight.health = game.CROC_HEALTH
	game.fight.clock = 0.0
	game.fight.pinned = false
	game.fight.hold = 0.0
	game.fight.last_thrust = -INF
	game.fight.waves = []
	game.fight.launched = 0
	game.fight.next = APEP_FIRST
	game.fight.last_arrival = -INF
	game.fight.last_feint = false
	game.fight.head = {"phase": "rest", "t": 0.0, "rot": 0.0, "rot0": 0.0, "sx": 1.0, "dx": 0.0}
	_apep_dress(e)
	# where the spear point comes down as drawn, in his picture's pixels
	var a: Node2D = game.actors[e.foe]
	var left: float = a.get_meta("home").x - a.get_meta("size").x / 2.0
	game.fight.point_x = (game.fight.pos + game._tip_offset()).x - left
	_apep_place()
	game._arena_open()


## For this fight only: room above him for the waves, the wave shader, and his head cut loose so it
## can rear (drawn again on its own, turning on its neck).
func _apep_dress(e: Dictionary) -> void:
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	game.fight.apep_plain = sp.texture
	game.fight.apep_at = sp.offset
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
	sp.offset -= Vector2(0, P)
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
	if not game.fight.has("apep_plain"):
		return
	var a: Node2D = game.actors[game.fight.e.foe]
	var sp: Sprite2D = game._picture(a)
	sp.texture = game.fight.apep_plain
	sp.offset = game.fight.apep_at
	sp.material = null
	if a.has_node("HeadPivot"):
		var pivot := a.get_node("HeadPivot")
		a.remove_child(pivot)
		pivot.queue_free()
	game.fight.erase("apep_plain")


## How far the waves lift his body at `x` (his picture's pixels), as apep_wave.gdshader does.
func _apep_lift(x: float) -> float:
	var half = float(game.fight.e.width) * game.unit
	var h := 0.0
	for w in game.fight.waves:
		var d: float = (x - w.x) / half
		if absf(d) < 1.0:
			h += w.h * w.amp * 0.5 * (1.0 + cos(PI * d))
	return h


## Show the waves on him and his head where it is.
func _apep_place() -> void:
	if not game.fight.has("apep_plain"):
		return
	var e: Dictionary = game.fight.e
	var a: Node2D = game.actors[e.foe]
	var half = float(e.width) * game.unit
	var arr := PackedVector4Array()
	for i in APEP_WAVES:
		if i < game.fight.waves.size():
			var w: Dictionary = game.fight.waves[i]
			arr.append(Vector4(w.x, w.h * w.amp, half, 0.0))
		else:
			arr.append(Vector4.ZERO)
	(game._picture(a).material as ShaderMaterial).set_shader_parameter("waves", arr)
	var h: Dictionary = game.fight.head
	var pv := Vector2(float(e.head_pivot[0]), float(e.head_pivot[1]))
	var pivot: Node2D = a.get_node("HeadPivot")
	pivot.position = game.fight.apep_at + pv + Vector2(h.dx, -_apep_lift(pv.x))
	pivot.scale = Vector2(h.sx, 1.0)
	pivot.rotation = h.rot * (1.0 if h.sx >= 0.0 else -1.0)      # its snout up, whichever way it faces


## Send a wave off from his tail at `v` px/s (a feint dies out in the hump).
func _apep_launch(feint: bool, v: float) -> Dictionary:
	var w := {"x": 0.0, "v": v, "t": 0.0, "s": "lash", "feint": feint, "amp": 0.0,
		"h": float(game.fight.e.height) * game.unit * (APEP_FEINT if feint else 1.0)}
	game.fight.waves.append(w)
	return w


## The next wave, once it is due: faster and closer together as the barb goes in; never reaching the
## point within `min_gap` s of the one before.
func _apep_launch_due() -> void:
	if game.fight.clock < game.fight.next or game.fight.waves.size() >= APEP_WAVES:
		return
	var e: Dictionary = game.fight.e
	var k = clampf(float(game.fight.hits) / maxf(1.0, float(e.need) - 1.0), 0.0, 1.0)
	var v = lerpf(float(e.speed[0]), float(e.speed[1]), k) * game.unit
	var feint: bool = game.fight.launched >= int(e.teach) and not game.fight.last_feint and game.rng.randf() < float(e.feint)
	if not feint:
		var arrive: float = game.fight.clock + float(e.lash) + game.fight.point_x / v
		var wait: float = game.fight.last_arrival + float(e.min_gap) - arrive
		if wait > 0.0:
			game.fight.next = game.fight.clock + wait
			return
		game.fight.last_arrival = arrive
	_apep_launch(feint, v)
	game.fight.last_feint = feint
	game.fight.launched += 1
	game.fight.next = game.fight.clock + lerpf(float(e.gap[0]), float(e.gap[1]), k)


func _apep(dt: float) -> void:
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	var e: Dictionary = game.fight.e
	game.fight.clock += dt
	if game.fight.get("bot", false):
		_apep_bot()
	game.fight.red = maxf(0.0, game.fight.red - dt)
	# was the point down at any time during this frame (a slow frame may step right over it)?
	game.fight.down = game.fight.pinned
	if game.fight.pinned:
		game.fight.hold -= dt
		if game.fight.hold <= 0.0:
			game.fight.pinned = false
			game.fight.thrust = game.THRUST_TIME[0] + 0.001          # the spear draws back up, to its new rest
			if game.fight.hits >= int(e.need):
				if game.endless():
					game.fight.hits = 0
				else:
					game.end_fight()
					return
	elif game.fight.thrust >= 0.0:
		var span = game._thrust_down_span()
		game.fight.down = game.fight.thrust <= span.y and game.fight.thrust + dt >= span.x
		game.fight.thrust += dt
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
			if not game.fight.struck:
				_apep_jab()
	if game.fight.hits < int(e.need):
		_apep_launch_due()
	_apep_waves(dt)
	_apep_head(dt)
	_apep_place()
	game._place_bearer()


## How close to the point a crest is pressed down (px): closer as the barb goes in.
func _apep_reach() -> float:
	var e: Dictionary = game.fight.e
	var k = clampf(float(game.fight.hits) / maxf(1.0, float(e.need) - 1.0), 0.0, 1.0)
	return lerpf(float(e.reach[0]), float(e.reach[1]), k) * game.unit


func _apep_waves(dt: float) -> void:
	var e: Dictionary = game.fight.e
	var reach := _apep_reach()
	var px: float = game.fight.point_x
	var down: bool = game.fight.get("down", false)
	for w in game.fight.waves.duplicate():
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
						game.fight.waves.erase(w)
				elif w.s == "past":   # runs out round the fold
					w.amp = clampf(1.0 - (w.x - px - reach) / maxf(1.0, float(e.fold) - px - reach), 0.0, 1.0)
					if w.amp <= 0.0:
						game.fight.waves.erase(w)
				elif down and x0 <= px + reach and w.x >= px - reach:   # its crest passed under the point
					_apep_pressed(w)
				elif w.x > px + reach:
					w.s = "past"
					_apep_slip(w)
			"pressed":         # flattens under the spear
				w.amp -= dt / APEP_PRESS
				if w.amp <= 0.0:
					game.fight.waves.erase(w)


func _apep_pressed(w: Dictionary) -> void:
	var e: Dictionary = game.fight.e
	w.s = "pressed"
	game.fight.struck = true
	game.fight.hits += 1
	game._life_hit()
	game.fight.pinned = true
	game.fight.hold = APEP_HOLD
	game._hurt(game.actors[e.foe])
	game._dev_shot("SHOT_ON_CATCH")
	if game.fight.hits >= int(e.need):
		for o in game.fight.waves:
			o.s = "pressed"
		game.say("Scribe", game._feedback_text("life_hit" if game.endless() else "apep_defeated"))
	else:
		game.say("Scribe", game._feedback_text("barb_advanced"))


## A thrust that pressed nothing down: early for a wave on its way, or else on a still neck.
func _apep_jab() -> void:
	var px: float = game.fight.point_x
	var coming: bool = game.fight.waves.any(func(w): return not w.feint and w.s in ["lash", "run"] and px - w.x < w.v * APEP_EARLY)
	if coming:
		game._feedback_once("Too early", game._feedback_text("too_early"))
	elif game.fight.hits > 0:
		game.fight.hits -= 1
		game._feedback_once("The barb slipped back", game._feedback_text("barb_slipped"))
	else:
		game._feedback_once("Wait for a wave to reach the spear point", game._feedback_text("no_wave"))


## A wave got past the point: his head rears out from under it, turns and bites.
func _apep_slip(w: Dictionary) -> void:
	_apep_head_phase("rear")
	var since: float = game.fight.clock - game.fight.last_thrust
	if since < APEP_EARLY + 2.0 * _apep_reach() / w.v:
		game._feedback_once("Too early", game._feedback_text("missed_wave"))
	else:
		game._feedback_once("The wave got through", game._feedback_text("wave_passed"))
	game.fight.next = maxf(game.fight.next, game.fight.clock + 0.6)


func _apep_head_phase(p: String) -> void:
	var h: Dictionary = game.fight.head
	h.phase = p
	h.t = 0.0
	h.rot0 = h.rot


func _apep_head(dt: float) -> void:
	var h: Dictionary = game.fight.head
	h.t += dt
	match h.phase:
		"rest":          # strains up as a crest comes under it
			var lift = _apep_lift(float(game.fight.e.head_pivot[0])) / (float(game.fight.e.height) * game.unit)
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
			h.dx = APEP_SNAP * game.unit * u
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
			h.dx = lerpf(APEP_SNAP * game.unit, 0.0, k)
			if u >= 1.0:
				_apep_head_phase("rest")


func _apep_bites() -> void:
	game._dev_shot("SHOT_ON_BITE")
	game.fight.red = 0.8
	if not game._life_mistake():
		game.fight.health -= 1
	game.bites += 1
	game._damage_shake()
	if game.fight.health <= 0:
		_apep_dies()


## The last bite: he crumbles away, and he is back on the scroll.
func _apep_dies() -> void:
	game.fight.lost = true
	var e: Dictionary = game.fight.e
	game.say("Scribe", game._hints.message("dangers.defeated"))
	game._disintegrate(e)
	var t = game._fight_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "apep" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


func _apep_click(_p: Vector2) -> void:
	game._feedback_once("controls", game._feedback_text("controls"))


## Dev (`--croc-bot`): thrusts APEP_BOT_LEAD s before each real crest reaches the point.
func _apep_bot() -> void:
	if OS.has_environment("BOT_MISS") or game.fight.thrust >= 0.0 or game.fight.pinned:
		return
	for w in game.fight.waves:
		if not w.feint and w.s == "run" and (game.fight.point_x - w.x) / w.v <= APEP_BOT_LEAD:
			game._croc_thrust()
			return


## (autotest) A wave at `v` px/s from the tail, Space pressed `tau` s from when its crest would reach
## the point (none if `tau` is INF); true = pressed down. Other waves are held back.
func _apep_try(tau: float, v: float, dt := 1.0 / 240.0) -> bool:
	game.fight.waves = []
	game.fight.next = INF
	game.fight.thrust = -1.0
	game.fight.pinned = false
	game.fight.struck = true
	_apep_head_phase("rest")
	var hits: int = game.fight.hits
	var w := _apep_launch(false, v)
	var arrive: float = float(game.fight.e.lash) + game.fight.point_x / v
	var t := 0.0
	var pressed := false
	while t < arrive + 0.5:
		if not pressed and t >= arrive + tau:
			pressed = true
			game._croc_thrust()
		_apep(dt)
		t += dt
		if game.fight.hits > hits or w.s == "past" or game.fight.lost:
			break
	return game.fight.hits > hits


## (autotest) The span of press times (from the crest reaching the point) that press a wave at `v`
## down; leaves no hit counted.
func _apep_window(v: float) -> Array:
	var lo := INF
	var hi := -INF
	var tau := -0.4
	while tau <= 0.3:
		game.fight.health = 99
		var hits: int = game.fight.hits
		if _apep_try(tau, v):
			lo = minf(lo, tau)
			hi = maxf(hi, tau)
		game.fight.hits = hits
		tau += 0.005
	game.fight.health = game.CROC_HEALTH
	game.fight.waves = []
	game.fight.pinned = false
	_apep_head_phase("rest")
	return [lo, hi]


func autotest(e: Dictionary, expect: Callable) -> void:
	var need := int(e.need)
	var slow: float = float(e.speed[0]) * game.unit
	var fast: float = float(e.speed[1]) * game.unit
	expect.call(game.fight.waves.is_empty() and game._spear_out() < 0.0, e.id + " the barb rests drawn back from his neck")
	expect.call(game.fight.point_x > float(e.hump[1]) and game.fight.point_x < float(e.fold), e.id + " the spear point is on the fold, past the hump")
	# the window: press Space at `tau` s from the crest reaching the point (sim at 240 fps)
	var good: Array = _apep_window(slow)
	print("spell 39 window: %.3f .. %.3f s from the crest reaching the point (%.0f ms)" % [good[0], good[1], (good[1] - good[0]) * 1000.0])
	expect.call(good[1] - good[0] >= 0.08, e.id + " a window of at least 80 ms for the first waves")
	game.fight.health = 99
	expect.call(not _apep_try(-0.4, slow), e.id + " a thrust well before the wave arrives misses it")
	expect.call(not _apep_try(0.25, slow), e.id + " a thrust after the wave is past misses it")
	# a wave that gets past: his head rears, turns and bites
	game.fight.health = game.CROC_HEALTH
	var b0 = game.bites
	_apep_try(INF, slow)
	expect.call(game.fight.head.phase == "rear", e.id + " a wave past the point lifts his head out from under it")
	for i in 15:
		_apep(0.02)
	expect.call(game.bites == b0 + 1 and game.fight.health == game.CROC_HEALTH - 1 and game.fight.red > 0.0, e.id + " ...and he bites the bearer")
	for i in 45:
		_apep(0.02)
	expect.call(game.fight.head.phase == "rest", e.id + " ...and lies down again")
	# his head strains up as a crest comes under it
	game.fight.waves = []
	var hw := _apep_launch(false, slow)
	hw.s = "run"
	hw.amp = 1.0
	hw.x = float(e.head_pivot[0])
	_apep_head(0.0)
	expect.call(game.fight.head.rot > APEP_STRAIN * 0.9, e.id + " his head lifts as a wave comes under it")
	# a feint dies out in the hump, short of the point: no bite
	game.fight.waves = []
	var h0: int = game.fight.health
	var fw := _apep_launch(true, slow)
	for i in 600:
		_apep(1.0 / 120.0)
		if not fw in game.fight.waves:
			break
	expect.call(not fw in game.fight.waves and fw.x < game.fight.point_x and game.fight.health == h0, e.id + " a feint dies out in the hump, short of the point")
	# a thrust on a still neck works the barb loose a step
	game.fight.waves = []
	game.fight.hits = 2
	game._croc_thrust()
	_apep(game.THRUST_TIME[0] + game.THRUST_TIME[1] + 0.01)
	expect.call(game.fight.hits == 1, e.id + " a thrust on a still neck works the barb loose a step")
	game.fight.hits = 0
	# each wave pressed down drives the barb a step in, the waves coming faster
	var mid: float = (good[0] + good[1]) / 2.0
	var rest0 = game._spear_rest()
	for i in need - 1:
		game.fight.health = game.CROC_HEALTH
		var v := lerpf(slow, fast, float(i) / float(need - 1))
		expect.call(_apep_try(mid, v), e.id + " a wave pressed down (%d)" % (i + 1))
		_apep(APEP_HOLD + 0.01)
	expect.call(game.fight.hits == need - 1 and not game.fight.is_empty(), e.id + " each wave pressed counts")
	expect.call(game._spear_rest() > rest0 and game._spear_rest() < 0.0, e.id + " the barb rests further in with each")
	expect.call(_apep_try(mid, slow, 1.0 / 15.0), e.id + " a thrust in time presses the wave down even at 15 frames a second")
	game.fight.hits -= 1
	_apep(APEP_HOLD + 0.01)
	var last: Array = _apep_window(fast)
	print("spell 39 fastest window: %.0f ms" % ((last[1] - last[0]) * 1000.0))
	expect.call(last[1] - last[0] >= 0.05 and last[1] - last[0] < good[1] - good[0], e.id + " the last wave is the hardest, and can still be pressed down")
	# the waves come by themselves, faster and closer together, never two at the point at once
	game.fight.waves = []
	game.fight.last_arrival = -INF
	var arrivals := []
	for i in 40:           # asked for a wave every 0.1 s
		var before: int = game.fight.launched
		game.fight.last_feint = true
		game.fight.waves = []
		game.fight.next = game.fight.clock
		_apep_launch_due()
		if game.fight.launched > before:
			arrivals.append(game.fight.last_arrival)
		game.fight.clock += 0.1
	var gaps_ok := true
	for i in range(1, arrivals.size()):
		gaps_ok = gaps_ok and arrivals[i] - arrivals[i - 1] >= float(e.min_gap) - 0.001
	expect.call(gaps_ok and arrivals.size() >= 3, e.id + " waves reach the point at least min_gap apart")
	game.fight.waves = []
	game.fight.next = INF
	# the third bite and he crumbles
	game.fight.health = 1
	_apep_try(INF, slow)
	for i in 30:
		_apep(0.02)
	expect.call(game.fight.lost, e.id + " the third bite and he crumbles")
	game.fight.lost = false
