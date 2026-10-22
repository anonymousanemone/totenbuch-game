## Sheaf encounter behavior and acceptance checks.
extends RefCounted

var game
var lean: Dictionary     ## spear41_lean.json: the bearer leaning in to each band (tools/spearer_lean.py)


func _init(level) -> void:
	game = level
	lean = JSON.parse_string(FileAccess.get_file_as_string(LEAN_PATH))




# the snake in the sheaf (spell 41). The vignette opens out close up; the bearer stands where he is
# drawn, his spear point resting over the top band of the sheaf, which stands bound as drawn. The
# snake is inside, on top of one of the four bands: that band shivers, and the stalks stir above it;
# on top of the top band it is out, coiled as drawn. [↑] [↓] lean him in to the band above or below
# (his spear point rests over it), and Space strikes there. On the snake it is struck, and slips
# away to another band; above it the spear stops just before it, below it the spear slips past, and
# either way he is bitten. Left alone it moves on after `window` s; in hard mode (the breath of life
# not taken at spell 38) it bites first. Struck `need` times, the last always on top of the top
# band, it is pinned there. Bitten CROC_HEALTH times, he crumbles.
const SHEAF_BANDS := ["sheaf41_band1", "sheaf41_band2", "sheaf41_band3", "sheaf41_band4"]   ## top to bottom
const SHEAF_STALKS := "sheaf41_stalks"
const LEAN_PATH := "res://assets/dangers/animation/spear41_lean.json"
const LEAN_TEX := preload("res://assets/dangers/animation/spear41_lean.png")          ## a row per band: poses, then the spear alone
const STEPS_TEX := preload("res://assets/dangers/animation/spear41_lean_steps.png")   ## the in-betweens, drawn back, then the spear alone
const SHEAF_LEAN := 0.12        ## he leans from one band to the next (s)
const SHEAF_SHIVER := 1.2       ## the band the snake is on shivers this far (plate px)
const SHEAF_PEEK_X := 0.55      ## the part of its picture that comes out at a band: from this share of its width
const SHEAF_RISE := 0.25        ## it comes out onto the top, or sinks back in (s)
const SHEAF_LUNGE := 14.0       ## out on top, how far its head comes at him when it bites (plate px)
const SHEAF_DART := 0.35        ## a bite: its head out at the band, or at him from the top (s)
const SHEAF_STIR := 3.0         ## the stalks' push above the band it is on (texture px)
const SHEAF_BOT_REACT := 0.35   ## (--croc-bot) leans to the band and strikes this long after it starts to shiver (s)
const RUSTLE := preload("res://scripts/dangers/rustle.gdshader")


func _sheaf_start(e: Dictionary) -> void:
	var mid_x: float = (game.actors[e.spear].get_meta("home").x + game.actors[e.bundle].get_meta("home").x) / 2.0
	game._arena_setup(e, false, [e.foe] + SHEAF_BANDS + [SHEAF_STALKS], {"y1": game.ground + 24.0 * game.unit, "x": mid_x})
	game.fight.stand = game.actors[e.spear].get_meta("home")
	game.fight.pos = game.fight.stand
	game.fight.health = game.CROC_HEALTH
	game.fight.clock = 0.0
	game.fight.pinned = false
	game.fight.last_thrust = -INF
	game.fight.phase = "hunt"          # hunt, pinned
	game.fight.pt = 0.0                # s in this phase
	game.fight.aim = 0                 # the band he leans to (0 the top)
	game.fight.lean = 0.0              # where he leans now (between bands on the way)
	game.fight.queued = false          # Space while leaning: he strikes once he is there
	game.fight.strike = 0              # the band the thrust under way is aimed at
	game.fight.show = 1.0              # how much of the snake shows on top
	game.fight.dart = -1.0             # s into a bite; -1 = none
	game.fight.dart_at = 0
	game.fight.told = {}
	# `at`: the band it is on (-1 between bands, unseen); `t` s there, moving on at `dur`
	game.fight.sn = {"at": -1, "prev": -1, "t": 0.0, "dur": _sheaf_gap()}
	_sheaf_dress(e)
	_sheaf_place()
	game._arena_open()


## For this fight only: the pieces of the sheaf show instead of the bundle, the stalks can stir, the
## snake can show part of itself (rising out on top, or its head out at a band), and the bearer
## comes from the lean sheets.
func _sheaf_dress(e: Dictionary) -> void:
	for n in SHEAF_BANDS + [SHEAF_STALKS]:
		game.actors[n].visible = true
	var mat := ShaderMaterial.new()
	mat.shader = RUSTLE
	game._picture(game.actors[SHEAF_STALKS]).material = mat
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	game.fight.snake_at = sp.offset
	var peek := Sprite2D.new()
	peek.name = "Peek"
	peek.texture = sp.texture
	peek.centered = false
	peek.region_enabled = true
	a.add_child(peek)


func _sheaf_undress() -> void:
	var e: Dictionary = game.fight.e
	for n in SHEAF_BANDS + [SHEAF_STALKS]:
		game._restore(n)
		game.actors[n].visible = false
	game._picture(game.actors[SHEAF_STALKS]).material = null
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	sp.region_enabled = false
	sp.visible = true
	if game.fight.has("snake_at"):
		sp.offset = game.fight.snake_at
	if a.has_node("Peek"):
		var peek := a.get_node("Peek")
		a.remove_child(peek)
		peek.queue_free()
	for nm in [e.spear, e.spear + "_pole"]:
		(game._picture(game.actors[nm]).texture as AtlasTexture).atlas = game._sheet_tex
	game._bearer_pose(e.spear, 0.0)


## Tuning value `key` for the strikes so far: from its first value (none) to its last (the last strike).
func _sheaf_tune(key: String) -> float:
	var v: Array = game.fight.e[key]
	return lerpf(float(v[0]), float(v[1]), clampf(float(game.fight.hits) / float(int(game.fight.e.need) - 1), 0.0, 1.0))


## How long it is unseen between one band and the next.
func _sheaf_gap() -> float:
	var g: Array = game.fight.e.gap
	return game.rng.randf_range(float(g[0]), float(g[1]))


func _sheaf(dt: float) -> void:
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	game.fight.clock += dt
	game.fight.pt += dt
	if game.fight.get("bot", false):
		_sheaf_bot()
	game.fight.red = maxf(0.0, game.fight.red - dt)
	if game.fight.dart >= 0.0:
		game.fight.dart += dt
		if game.fight.dart >= SHEAF_DART:
			game.fight.dart = -1.0
	var sn: Dictionary = game.fight.sn
	var on_top: bool = sn.at == 0 or game.fight.phase == "pinned" or (game.fight.dart >= 0.0 and game.fight.dart_at == 0)
	game.fight.show = move_toward(game.fight.show, 1.0 if on_top else 0.0, dt / SHEAF_RISE)
	match game.fight.phase:
		"hunt":
			if game.fight.thrust >= 0.0:
				game.fight.thrust += dt
				if not game.fight.struck and game.fight.thrust >= game.THRUST_TIME[0]:
					game.fight.struck = true
					_sheaf_strike()
				if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
					game.fight.thrust = -1.0
			else:          # he leans only with his spear back
				game.fight.lean = move_toward(game.fight.lean, float(game.fight.aim), dt / SHEAF_LEAN)
				if game.fight.queued and game.fight.lean == float(game.fight.aim):
					game.fight.queued = false
					_sheaf_thrust()
			if game.fight.phase == "hunt" and not game.fight.lost:
				_sheaf_move(dt)
		"pinned":
			if game.fight.pt >= game.ROACH_FREEZE:
				game.fight.pinned = false
				game.fight.thrust = game.THRUST_TIME[0] + 0.001
				if game.endless():
					game.fight.hits = 0
					_sheaf_phase("hunt")
					_sheaf_leave()
				else:
					game.end_fight()
					return
	_sheaf_place()
	game._place_bearer()


func _sheaf_phase(p: String) -> void:
	game.fight.phase = p
	game.fight.pt = 0.0


## It stays on a band `dur` s, then moves on (in hard mode it bites first); unseen a moment, it
## comes to another band, at random, but the last strike is always on top of the top one.
func _sheaf_move(dt: float) -> void:
	var sn: Dictionary = game.fight.sn
	sn.t += dt
	if sn.t < sn.dur:
		return
	if sn.at < 0:
		var to := 0
		if game.fight.hits < int(game.fight.e.need) - 1:
			var others := range(SHEAF_BANDS.size()).filter(func(i): return i != sn.prev)
			to = others[game.rng.randi() % others.size()]
		sn.at = to
		sn.t = 0.0
		sn.dur = _sheaf_tune("window")
	elif game.hard():
		_sheaf_bitten("late")
	else:
		_sheaf_leave()


## It slips away from its band, unseen until the next.
func _sheaf_leave() -> void:
	var sn: Dictionary = game.fight.sn
	sn.prev = sn.at
	sn.at = -1
	sn.t = 0.0
	sn.dur = _sheaf_gap()


## [↑] (-1) or [↓] (1): he leans to the band above or below.
func _sheaf_aim(d: int) -> void:
	if game.fight.open < 1.0 or game.fight.lost or game.fight.get("closing", false) or game.fight.phase != "hunt":
		return
	game.fight.aim = clampi(game.fight.aim + d, 0, SHEAF_BANDS.size() - 1)


## Space: strike at the band he leans to (once he is there, if he is still leaning).
func _sheaf_act() -> void:
	if game.fight.open < 1.0 or game.fight.lost or game.fight.get("closing", false) or game.fight.phase != "hunt":
		return
	if game.fight.thrust >= 0.0:
		return
	if game.fight.lean != float(game.fight.aim):
		game.fight.queued = true
		return
	_sheaf_thrust()


func _sheaf_thrust() -> void:
	game.fight.strike = game.fight.aim
	game._croc_thrust()


## The spear is out at the band he struck: on the snake, struck; above it or below it, bitten.
## Between bands (it is moving, unseen) it meets nothing.
func _sheaf_strike() -> void:
	var at: int = game.fight.sn.at
	if at < 0:
		return
	if game.fight.strike == at:
		_sheaf_hit()
	else:
		_sheaf_bitten("short" if game.fight.strike < at else "past")


func _sheaf_hit() -> void:
	var e: Dictionary = game.fight.e
	var at: int = game.fight.sn.at
	game.fight.hits += 1
	game._life_hit()
	if game.fight.hits >= int(e.need):
		game.fight.pinned = true
		game._hurt(game.actors[e.foe])
		_sheaf_phase("pinned")
		game._dev_shot("SHOT_ON_CATCH")
		game.say("Scribe", game._feedback_text("life_hit" if game.endless() else "struck"))
		return
	game._hurt(game.actors[e.foe] if at == 0 else game.actors[SHEAF_BANDS[at]])
	_sheaf_leave()
	if not game.fight.told.has("hit"):
		game.fight.told.hit = true
		game.say("Scribe", game._feedback_text("hit"))


## It bites at his hand from the band it is on (`why`: short, past, or late), then moves on.
func _sheaf_bitten(why: String) -> void:
	game.fight.dart = 0.0
	game.fight.dart_at = game.fight.sn.at
	_sheaf_hurt()
	if game.fight.lost:
		return
	game.say("Scribe", game._feedback_text(why))
	_sheaf_leave()


func _sheaf_hurt() -> void:
	game.fight.red = 0.8
	if not game._life_mistake():
		game.fight.health -= 1
	game.bites += 1
	var t = game._fight_tween()
	for i in 6:
		t.tween_property(game.camera, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)) * game.unit, 0.04)
	t.tween_property(game.camera, "offset", Vector2.ZERO, 0.05)
	if game.fight.health <= 0:
		_sheaf_dies()


func _sheaf_dies() -> void:
	game.fight.lost = true
	game.fight.queued = false
	var e: Dictionary = game.fight.e
	game.say("Scribe", game._hints.message("dangers.defeated"))
	game._disintegrate(e)
	var t = game._fight_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "sheaf" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


## The middle of band `i`, strip y.
func _band_y(i: int) -> float:
	return game.rects[SHEAF_BANDS[i]].get_center().y


## The bearer as he leans now, his spear point `o` plate px along its line from where it is drawn:
## at a band, the nearest pose in its row of the lean sheet; on the way between, the nearest in-between.
func _sheaf_pose(o: float) -> void:
	var nm: String = game.fight.e.spear
	var cw: float = lean.cell[0]
	var ch: float = lean.cell[1]
	var s: float = o * game.unit
	var p: float = s / float(lean.back) if s < 0.0 else s / float(lean.reach)
	var i := 0
	for k in lean.poses.size():
		if absf(float(lean.poses[k]) - p) < absf(float(lean.poses[i]) - p):
			i = k
	var fig := game._picture(game.actors[nm]).texture as AtlasTexture
	var pole := game._picture(game.actors[nm + "_pole"]).texture as AtlasTexture
	var lam: float = game.fight.lean
	var band := roundi(lam)
	if absf(lam - band) < 0.01:
		fig.atlas = LEAN_TEX
		pole.atlas = LEAN_TEX
		fig.region = Rect2(i * cw, band * ch, cw, ch)
		pole.region = Rect2((i + lean.poses.size()) * cw, band * ch, cw, ch)
		return
	var j := 0
	for k in lean.between.size():
		if absf(float(lean.between[k]) - lam) < absf(float(lean.between[j]) - lam):
			j = k
	fig.atlas = STEPS_TEX
	pole.atlas = STEPS_TEX
	fig.region = Rect2(j * cw, 0.0, cw, ch)
	pole.region = Rect2((j + lean.between.size()) * cw, 0.0, cw, ch)


## Put the sheaf (bound as drawn; the band the snake is on shivering, the stalks stirring above it)
## and the snake (out on top, rising or sinking, or unseen but for its head when it bites at a band).
func _sheaf_place() -> void:
	var e: Dictionary = game.fight.e
	var k: float = game.fight.open
	var st: Rect2 = game.rects[SHEAF_STALKS]
	var sn: Dictionary = game.fight.sn
	var hunting: bool = game.fight.phase == "hunt" and not game.fight.lost
	for n in SHEAF_BANDS + [SHEAF_STALKS]:
		var a: Node2D = game.actors[n]
		a.position = a.get_meta("home")
		a.modulate.a = k
	if hunting and sn.at >= 0:
		game.actors[SHEAF_BANDS[sn.at]].position.x += sin(game.fight.clock * 31.0) * SHEAF_SHIVER * game.unit
	var mat = game._picture(game.actors[SHEAF_STALKS]).material as ShaderMaterial
	if mat:
		var above: float = st.position.y if sn.at <= 0 else _band_y(sn.at - 1)
		var y: float = (above + _band_y(maxi(sn.at, 0))) / 2.0
		mat.set_shader_parameter("at", clampf((y - st.position.y) / st.size.y, 0.0, 1.0))
		mat.set_shader_parameter("amp", SHEAF_STIR * k if hunting and sn.at > 0 else 0.0)
		mat.set_shader_parameter("phase", game.fight.clock * 23.0)
	# the snake: as drawn on top while the vignette opens and closes; inside, unseen
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	var peek: Sprite2D = a.get_node_or_null("Peek")
	var size: Vector2 = a.get_meta("size")
	var top: float = float(e.top)
	a.position = a.get_meta("home")
	a.scale = Vector2.ONE
	a.modulate.a = 1.0
	var r: float = (1.0 - k * (1.0 - game.fight.show)) * size.y
	sp.region_enabled = true
	sp.visible = r > 0.5
	sp.region_rect = Rect2(0.0, 0.0, size.x, r)
	sp.offset = game.fight.snake_at + Vector2(0.0, maxf(0.0, top - r))
	var dart: float = sin(PI * game.fight.dart / SHEAF_DART) if game.fight.dart >= 0.0 else 0.0
	if peek:          # a bite from inside: its head out at the band, at his hand
		var pr := dart * 0.5 * top if game.fight.dart_at > 0 else 0.0
		var x0 := SHEAF_PEEK_X * size.x
		peek.visible = pr > 0.5 and k >= 1.0
		peek.region_rect = Rect2(x0, 0.0, size.x - x0, pr)
		peek.position = game.fight.snake_at + Vector2(x0, top + _band_y(game.fight.dart_at) - st.position.y - pr)
	if game.fight.phase == "pinned":
		a.scale = Vector2(1.0 + 0.04 * sin(game.fight.clock * 40.0), 1.0 - 0.04 * sin(game.fight.clock * 40.0))
	elif game.fight.dart_at == 0:     # a bite from the top: its head comes at him
		a.position.x += SHEAF_LUNGE * game.unit * dart
	if hunting and sn.at == 0 and dart == 0.0:
		a.scale = Vector2(1.0, 1.0 + 0.02 * sin(game.fight.clock * TAU / 1.2))   # breathing


## Dev (`--croc-bot`, and the autotest's trials): SHEAF_BOT_REACT s (or BOT_REACT) after a band
## starts to shiver, leans to it and strikes. With `careless`, strikes a band at random every 0.5 s.
func _sheaf_bot() -> void:
	var react: float = game.fight.get("bot_react", float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else SHEAF_BOT_REACT)
	var sn: Dictionary = game.fight.sn
	if game.fight.phase != "hunt" or game.fight.thrust >= 0.0 or game.fight.queued:
		return
	if game.fight.get("careless", false):
		if game.fight.pt - game.fight.get("bot_last", -1.0) >= 0.5:
			game.fight.bot_last = game.fight.pt
			game.fight.aim = game.rng.randi() % SHEAF_BANDS.size()
			_sheaf_act()
	elif sn.at >= 0 and sn.t >= react:
		game.fight.aim = sn.at
		_sheaf_act()


## (autotest) One whole fight against spell 41 played by the bot at reaction `react` (or careless),
## in hard mode or not, from random seed `seed`; true = won. Leaves the fight stepped out of.
func _sheaf_trial(e: Dictionary, react: float, careless: bool, hard: bool, seed: int) -> bool:
	var b0 = game.bites
	var items0: Array[String] = game.items.duplicate()
	game.items.assign([] if hard else ["sail38"])
	game.rng.seed = seed
	game.start_fight(e)
	game.fight.bot = true
	game.fight.bot_react = react
	game.fight.careless = careless
	var won := false
	var t := 0.0
	while t < 180.0:
		_sheaf(1.0 / 60.0)
		t += 1.0 / 60.0
		if game.fight.is_empty() or game.fight.lost:
			won = game.fight.is_empty()
			break
		if game.fight.pinned:
			won = true
			break
	if not game.fight.is_empty():
		game.leave_fight()
	game.solved.erase(e.id)
	game.journal.clear()
	game.bites = b0
	game.items.assign(items0)
	return won


func autotest(e: Dictionary, expect: Callable) -> void:
	var sn: Dictionary = game.fight.sn
	var band = func(i: int) -> Node2D: return game.actors[SHEAF_BANDS[i]]
	var fig = func() -> AtlasTexture: return game._picture(game.actors[e.spear]).texture as AtlasTexture
	var snake: Sprite2D = game._picture(game.actors[e.foe])
	# put it on band `i`, to stay there
	var put = func(i: int) -> void:
		var s: Dictionary = game.fight.sn
		s.at = i
		s.t = 0.0
		s.dur = 99.0
	# lean to band `i` and strike; returns once the spear is out
	var strike = func(i: int) -> void:
		game.fight.aim = i
		game.fight.lean = float(i)
		_sheaf_act()
		_sheaf(game.THRUST_TIME[0] + 0.01)
	sn.dur = 99.0       # unseen between bands until put on one
	expect.call(game.actors[SHEAF_STALKS].visible and game.actors[e.bundle].modulate.a < 0.01, e.id + " the sheaf comes apart into stalks and bands; the bundle steps aside")
	expect.call(SHEAF_BANDS.all(func(n): return game.actors[n].modulate.a > 0.99) and game.actors[SHEAF_STALKS].scale.x == 1.0, e.id + " its bands are bound, as drawn")
	expect.call(fig.call().atlas == LEAN_TEX and fig.call().region.position.y == 0.0, e.id + " he leans to the top band, as drawn")
	# [↑] [↓] lean him band by band, the in-betweens on the way
	for i in 5:
		_sheaf_aim(1)
	expect.call(game.fight.aim == 3, e.id + " [↓] leans him band by band, no further than the bottom one")
	_sheaf(SHEAF_LEAN * 0.5)
	expect.call(fig.call().atlas == STEPS_TEX, e.id + " on the way between bands he is drawn leaning between them")
	_sheaf(SHEAF_LEAN * 3.0)
	expect.call(game.fight.lean == 3.0 and fig.call().atlas == LEAN_TEX and fig.call().region.position.y == 3.0 * float(lean.cell[1]), e.id + " ... and at the bottom band in its row of the sheet")
	_sheaf_aim(-1)
	_sheaf_act()
	expect.call(game.fight.queued and game.fight.thrust < 0.0, e.id + " Space while he leans: he strikes once he is there")
	_sheaf(SHEAF_LEAN + 0.01)
	expect.call(game.fight.thrust >= 0.0 and game.fight.strike == 2, e.id + " ... at the band he leaned to")
	_sheaf(1.0)
	# the band it is on shivers, and the stalks stir above it; inside it is unseen
	put.call(2)
	game.fight.show = 0.0
	game.fight.clock = 0.05
	_sheaf_place()
	var mat = game._picture(game.actors[SHEAF_STALKS]).material as ShaderMaterial
	var y: float = (mat.get_shader_parameter("at") * game.rects[SHEAF_STALKS].size.y) + game.rects[SHEAF_STALKS].position.y
	expect.call(band.call(2).position.x != band.call(2).get_meta("home").x and band.call(1).position.x == band.call(1).get_meta("home").x, e.id + " the band it is on shivers, the others not")
	expect.call(mat.get_shader_parameter("amp") > 0.0 and y > _band_y(1) and y < _band_y(2), e.id + " the stalks stir above that band")
	expect.call(not snake.visible, e.id + " inside the sheaf it is unseen")
	# the wrong band: the spear stops short of it or slips past it, and he is bitten
	var h0: int = game.fight.health
	strike.call(0)
	expect.call(game.fight.health == h0 - 1 and game.hud._text == game._feedback_text("short"), e.id + " a band above it: the spear stops just before it, bitten")
	expect.call((game.actors[e.foe].get_node("Peek") as Sprite2D).visible or game.fight.dart >= 0.0, e.id + " ... its head comes out at that band")
	game.fight.health = game.CROC_HEALTH
	_sheaf(1.0)
	put.call(1)
	strike.call(3)
	expect.call(game.fight.health == game.CROC_HEALTH - 1 and game.hud._text == game._feedback_text("past"), e.id + " a band below it: the spear slips past, bitten")
	game.fight.health = game.CROC_HEALTH
	_sheaf(1.0)
	# the right band: struck, and it slips away to another band
	put.call(1)
	strike.call(1)
	expect.call(game.fight.hits == 1 and game.fight.health == game.CROC_HEALTH and sn.at == -1, e.id + " the band it is on: struck, and it slips away")
	sn.dur = 0.0
	_sheaf(0.01)
	expect.call(sn.at >= 0 and sn.at != 1, e.id + " ... and comes to another band")
	# on top of the top band it is out, coiled as drawn
	_sheaf(1.0)
	put.call(0)
	_sheaf(SHEAF_RISE + 0.01)
	expect.call(snake.visible and snake.region_rect.size.y == game.actors[e.foe].get_meta("size").y, e.id + " on top of the top band it is out, as drawn")
	# left alone: it moves on, and only in hard mode bites first
	sn.dur = 0.05
	_sheaf(0.1)
	expect.call(game.fight.health == game.CROC_HEALTH and sn.at == -1, e.id + " with the breath of life, left alone it moves on without a bite")
	game.items.erase("sail38")
	put.call(2)
	sn.dur = 0.05
	_sheaf(0.1)
	expect.call(game.fight.health == game.CROC_HEALTH - 1 and game.hud._text == game._feedback_text("late"), e.id + " in hard mode, left alone it bites")
	game.items.append("sail38")
	game.fight.health = game.CROC_HEALTH
	# the last strike is always on top of the top band, and pins it there
	game.fight.hits = int(e.need) - 1
	var tops := 0
	for i in 8:
		sn.at = -1
		sn.prev = 0 if i % 2 else 2
		sn.t = 99.0
		_sheaf(0.01)
		tops += 1 if sn.at == 0 else 0
	expect.call(tops == 8, e.id + " the last strike is always on top of the top band")
	put.call(0)
	_sheaf(SHEAF_LEAN * 3.0)
	strike.call(0)
	expect.call(game.fight.pinned and game.fight.phase == "pinned" and game.fight.hits == int(e.need), e.id + " the last strike pins it on top")
	# the third bite and he crumbles
	game.leave_fight()
	game.start_fight(e)
	game.fight.health = 1
	put.call(2)
	strike.call(3)
	expect.call(game.fight.lost, e.id + " the third bite and he crumbles")
	game.fight.lost = false
	game.leave_fight()
	# the difficulty: whole fights played by a stand-in player
	var rate := func(react: float, careless: bool, hard: bool) -> float:
		var won := 0
		for i in 40:
			if _sheaf_trial(e, react, careless, hard, 1000 + i):
				won += 1
		return won / 40.0
	if OS.has_environment("SHEAF_CURVE"):      # dev: the whole curve, in hard mode
		for r in [0.25, 0.35, 0.45, 0.55, 0.65, 0.75]:
			print("spell 41 curve (hard): react %.2f s -> %d%% won" % [r, rate.call(r, false, true) * 100])
	var quick: float = rate.call(0.35, false, true)
	var slow: float = rate.call(0.65, false, true)
	var careless: float = rate.call(0.0, true, true)
	var gentle: float = rate.call(0.35, false, false)
	print("spell 41 wins: hard, striking 0.35 s after the shiver %d%%, 0.65 s after %d%%, blindly %d%%; with the breath of life %d%%" % [quick * 100, slow * 100, careless * 100, gentle * 100])
	expect.call(quick >= 0.9 and gentle >= 0.9, e.id + " an attentive player (0.35 s) wins nearly every fight")
	expect.call(slow <= 0.5, e.id + " in hard mode a slow one (0.65 s) loses at least half")
	expect.call(careless <= 0.1, e.id + " striking blindly loses")
	game.start_fight(e)
	game.fight.pinned = true
