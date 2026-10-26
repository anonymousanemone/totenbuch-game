## Apep encounter behavior and acceptance checks.
extends RefCounted

var game
var strike: Dictionary     ## apep_strike.json: the cell, where the drawing sits in it, the joint, the frame the flip ends


func _init(level) -> void:
	game = level
	strike = JSON.parse_string(FileAccess.get_file_as_string(STRIKE_PATH))




# Apep (spell 39). The vignette opens out, close up, with room behind the bearer (Apep and he slide
# left together if it wants more). The point of his spear rests a little way up its line from Apep's neck,
# where the body folds back. Now and then Apep's tail lashes and a wave runs the length of him
# toward the fold (apep_wave.gdshader lifts the drawing); his head strains up as it comes. There
# are three sizes, and the lash shows which. A medium wave is pressed flat by a thrust (Space) whose
# point is down on the fold as the crest reaches it, and the barb rests a step further in; `need`
# and he lies still, the spear as drawn. A small one is a feint: it runs under the point and does
# nothing, but a thrust on it (or on a still neck) works the barb loose a step. A large one cannot be
# pressed: [→] hops the bearer back out of reach of its bite (he stays back until [←] hops him
# forward again). A medium or large wave that gets past the point while he is at the fold lifts
# Apep's head out from under it: it rears, turns and bites the bearer's foot. In hard mode (see
# hard()) a medium wave let past from back there makes Apep advance a step toward him, and each
# wave pressed down pushes him back half a step; once there is no room left to hop back before the
# double line behind him, the large ones can only be taken. Bitten CROC_HEALTH times, he crumbles
# and is back on the scroll.
const APEP_WAVE := preload("res://scripts/dangers/apep_wave.gdshader")
const APEP_WAVES := 4           ## waves the shader can show at once
const APEP_PAD := 40            ## room above his picture for the waves and his head to rise into (px)
const APEP_FIRST := 1.4         ## the first wave comes this long after the vignette opens (s)
const APEP_SIZE := {"small": [0.45, 0.8, 1.0], "medium": [1.0, 1.0, 1.0], "large": [2.0, 1.5, 1.5]}   ## height, width, lash, of a medium's
const APEP_PRESS := 0.12        ## a wave pressed down flattens out (s)
const APEP_HOLD := 0.3          ## the spear stays down on a wave pressed flat (s)
const APEP_EARLY := 0.35        ## a thrust this long (or less) before a wave would arrive is only early (s)
const STRIKE := preload("res://assets/dangers/animation/apep_strike.png")        ## his front flipping over and striking (tools/apep_strike.py)
const STRIKE_BODY := preload("res://assets/dangers/animation/apep_strike_body.png")   ## the drawing without his front
const STRIKE_PATH := "res://assets/dangers/animation/apep_strike.json"
const APEP_STRAIN := 1.0        ## his head lifts up to this far into the rear (frames) as a crest comes under it
const APEP_REAR := 0.12         ## ...in this long (s)
const APEP_TURN := 0.1          ## turns round to the bearer's foot (s)
const APEP_BACK := 0.35         ## and lies down again (s)
const APEP_HOP := 0.1           ## the bearer hops back, or forward again (s)
const APEP_SLIDE := 80.0        ## Apep slides forward or back (plate px/s)
const APEP_MARGIN := 6.0        ## shifted left, his tail stops this far short of the double line (plate px)
const APEP_BOT_LEAD := 0.05     ## (--croc-bot) thrusts this long before a crest reaches the point (s)


func _apep_start(e: Dictionary) -> void:
	# close up: from the caption banner to just under the ground, the whole vignette across and room
	# behind him to hop back and for Apep to advance `room` times
	var s = game.span(e)
	var room: float = (float(e.dodge) + float(e.room) * float(e.advance)) * game.unit
	var wide: float = game.get_viewport_rect().size.x / (s.y - s.x + room)
	game._arena_setup(e, false, [e.foe], {"y1": game.ground + 24.0 * game.unit, "x": (s.x + s.y) / 2.0, "z": wide})
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
	game.fight.last_kind = ""         # the last medium or large wave sent
	game.fight.last_small = false
	game.fight.head = {"phase": "rest", "t": 0.0, "f": 0.0, "f0": 0.0, "miss": false}
	game.fight.stance = "strike"      # strike (at the fold) or dodge (hopped back)
	game.fight.hop = 0.0              # how far back he is now (px)
	game.fight.adv = 0.0              # how far Apep has advanced toward him (px) ...
	game.fight.adv_to = 0.0           # ... and is sliding to
	_apep_dress(e)
	# where the spear point comes down as drawn, in his picture's pixels
	var a: Node2D = game.actors[e.foe]
	var left: float = a.get_meta("home").x - a.get_meta("size").x / 2.0
	game.fight.point_x = (game.fight.pos + game._tip_offset()).x - left
	# both slide left as the vignette opens, as far as that room wants (Apep's tail no nearer the
	# double line than APEP_MARGIN)
	game.fight.back_reach = game.rects[e.spear].end.x - game.fight.stand.x     # his rear foot, from his pivot
	var room0: float = game.fight.barrier - (game.fight.stand.x + game.fight.back_reach)
	var slack: float = left - (game.fight.full.position.x + 20.0 + APEP_MARGIN * game.unit)
	game.fight.shift = clampf(room - room0, 0.0, maxf(0.0, slack))
	_apep_place()
	game._arena_open()


## Tuning value `key`: in hard mode from `hard` where it has one.
func _apep_e(key: String):
	var e: Dictionary = game.fight.e
	return e.hard.get(key, e[key]) if game.hard() else e[key]


## How far the barb is in, 0 to 1: the tuples go from the first value to the second.
func _apep_k() -> float:
	return clampf(float(game.fight.hits) / maxf(1.0, float(game.fight.e.need) - 1.0), 0.0, 1.0)


## For this fight only: his body without his front, with room above it for the waves and the wave
## shader; his front drawn from the strike sheet (as drawn, until he rears).
func _apep_dress(e: Dictionary) -> void:
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	game.fight.apep_plain = sp.texture
	game.fight.apep_at = sp.offset
	var src := STRIKE_BODY.get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var P := APEP_PAD
	var body := Image.create(src.get_width(), src.get_height() + P, false, Image.FORMAT_RGBA8)
	body.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(0, P))
	sp.texture = ImageTexture.create_from_image(body)
	sp.offset -= Vector2(0, P)
	var mat := ShaderMaterial.new()
	mat.shader = APEP_WAVE
	sp.material = mat
	var front := Sprite2D.new()
	front.name = "Front"
	front.centered = false
	var at := AtlasTexture.new()
	at.atlas = STRIKE
	front.texture = at
	a.add_child(front)


## Undo _apep_dress.
func _apep_undress() -> void:
	if not game.fight.has("apep_plain"):
		return
	var a: Node2D = game.actors[game.fight.e.foe]
	var sp: Sprite2D = game._picture(a)
	sp.texture = game.fight.apep_plain
	sp.offset = game.fight.apep_at
	sp.material = null
	if a.has_node("Front"):
		var front := a.get_node("Front")
		a.remove_child(front)
		front.queue_free()
	game.fight.erase("apep_plain")


## How far the waves lift his body at `x` (his picture's pixels), as apep_wave.gdshader does.
func _apep_lift(x: float) -> float:
	var h := 0.0
	for w in game.fight.waves:
		var d: float = (x - w.x) / w.half
		if absf(d) < 1.0:
			h += w.h * w.amp * 0.5 * (1.0 + cos(PI * d))
	return h


## Show the waves on him and his head where it is; Apep and the bearer where they are along the ground.
func _apep_place() -> void:
	if not game.fight.has("apep_plain"):
		return
	var e: Dictionary = game.fight.e
	var a: Node2D = game.actors[e.foe]
	var k: float = game.fight.open
	a.position = a.get_meta("home") + Vector2((game.fight.adv - game.fight.shift) * k, 0.0)
	game.fight.pos = game.fight.stand + Vector2(game.fight.adv - game.fight.shift + game.fight.hop, 0.0)
	var arr := PackedVector4Array()
	for i in APEP_WAVES:
		if i < game.fight.waves.size():
			var w: Dictionary = game.fight.waves[i]
			arr.append(Vector4(w.x, w.h * w.amp, w.half, 0.0))
		else:
			arr.append(Vector4.ZERO)
	(game._picture(a).material as ShaderMaterial).set_shader_parameter("waves", arr)
	# his front: its frame of the strike sheet, lifted with the body where it leaves it
	var h: Dictionary = game.fight.head
	var cell := Vector2(float(strike.cell[0]), float(strike.cell[1]))
	var front: Sprite2D = a.get_node("Front")
	var i := clampi(roundi(h.f), 0, int(strike.frames) - 1)
	(front.texture as AtlasTexture).region = Rect2(Vector2(i * cell.x, 0.0), cell)
	front.position = game.fight.apep_at - Vector2(float(strike.drawn_at[0]), float(strike.drawn_at[1])) \
		+ Vector2(0.0, -_apep_lift(float(strike.joint[0])))


## Send a wave off from his tail at `v` px/s: `kind` small, medium or large.
func _apep_launch(kind: String, v: float) -> Dictionary:
	var e: Dictionary = game.fight.e
	var sz: Array = APEP_SIZE[kind]
	var w := {"x": 0.0, "v": v, "t": 0.0, "s": "lash", "kind": kind, "amp": 0.0,
		"h": float(e.height) * game.unit * float(sz[0]), "half": float(e.width) * game.unit * float(sz[1]),
		"lash": float(e.lash) * float(sz[2])}
	game.fight.waves.append(w)
	return w


## The waves on his body now (not yet past the point or pressed down).
func _apep_on_body() -> int:
	return game.fight.waves.filter(func(w): return w.s in ["lash", "run"]).size()


## The next wave's size: medium while he is being taught, then now and then a small or a large one
## (never two small ones running).
func _apep_kind() -> String:
	var e: Dictionary = game.fight.e
	if game.fight.launched < int(e.teach):
		return "medium"
	var r: float = game.rng.randf()
	if r < float(e.small) and not game.fight.last_small:
		return "small"
	if r < float(e.small) + float(e.large):
		return "large"
	return "medium"


## The next wave, once it is due: faster and closer together as the barb goes in; at most `most` on
## his body at once; a medium or large one never reaching the point within `min_gap` s of the one
## before, or `switch_gap` s if it wants the other answer (strike, or hop back).
func _apep_launch_due() -> void:
	if game.fight.clock < game.fight.next or _apep_on_body() >= int(_apep_e("most")) or game.fight.waves.size() >= APEP_WAVES:
		return
	var e: Dictionary = game.fight.e
	var k := _apep_k()
	var sp: Array = _apep_e("speed")
	var v = lerpf(float(sp[0]), float(sp[1]), k) * game.unit
	var kind := _apep_kind()
	if kind != "small":
		var arrive: float = game.fight.clock + float(e.lash) * float(APEP_SIZE[kind][2]) + game.fight.point_x / v
		var gap: float = float(_apep_e("min_gap") if kind == game.fight.last_kind or game.fight.last_kind == "" else _apep_e("switch_gap"))
		var wait: float = game.fight.last_arrival + gap - arrive
		if wait > 0.0:
			game.fight.next = game.fight.clock + wait
			return
		game.fight.last_arrival = arrive
		game.fight.last_kind = kind
	_apep_launch(kind, v)
	game.fight.last_small = kind == "small"
	game.fight.launched += 1
	var g: Array = _apep_e("gap")
	game.fight.next = game.fight.clock + lerpf(float(g[0]), float(g[1]), k)


func _apep(dt: float) -> void:
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	var e: Dictionary = game.fight.e
	game.fight.clock += dt
	if game.fight.get("bot", false):
		_apep_bot()
	game.fight.red = maxf(0.0, game.fight.red - dt)
	# was the point down at any time during this frame (a slow frame may step right over it)?
	# Only at the fold: hopped back, his thrust falls short.
	game.fight.down = game.fight.pinned
	if game.fight.pinned:
		game.fight.hold -= dt
		if game.fight.hold <= 0.0:
			game.fight.pinned = false
			game.fight.thrust = game.THRUST_TIME[0] + 0.001          # the spear draws back up, to its new rest
			if game.fight.hits >= int(e.need):
				if game.endless():
					game.fight.hits = 0
					game._life_cycle()
				else:
					game.end_fight()
					return
	elif game.fight.thrust >= 0.0:
		var span = game._thrust_down_span()
		game.fight.down = _apep_at_fold() and game.fight.thrust <= span.y and game.fight.thrust + dt >= span.x
		game.fight.thrust += dt
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
			if not game.fight.struck and _apep_at_fold():
				_apep_jab()
	var dodge: float = float(e.dodge) * game.unit
	game.fight.hop = move_toward(game.fight.hop, dodge if game.fight.stance == "dodge" else 0.0, dodge / APEP_HOP * dt)
	game.fight.adv = move_toward(game.fight.adv, game.fight.adv_to, APEP_SLIDE * game.unit * dt)
	if game.fight.hits < int(e.need):
		_apep_launch_due()
	_apep_waves(dt)
	_apep_head(dt)
	_apep_place()
	game._place_bearer()


## He is at the fold (not hopped back, nor on his way).
func _apep_at_fold() -> bool:
	return game.fight.stance == "strike" and game.fight.hop == 0.0


## There is room behind him to hop back, with Apep advanced as far as he is going.
func _apep_can_dodge() -> bool:
	var x: float = game.fight.stand.x + game.fight.adv_to - game.fight.shift + float(game.fight.e.dodge) * game.unit
	return x + game.fight.back_reach <= game.fight.barrier


## [→] (1): he hops back out of reach, if there is room; [←] (-1): forward to the fold again. Not
## while his spear is out.
func _apep_step(d: int) -> void:
	if game.fight.open < 1.0 or game.fight.lost or game.fight.get("closing", false):
		return
	if game.fight.thrust >= 0.0 or game.fight.pinned:
		return
	if d > 0 and game.fight.stance == "strike":
		if _apep_can_dodge():
			game.fight.stance = "dodge"
		else:
			game._feedback_once("at_wall", game._feedback_text("at_wall"))
	elif d < 0:
		game.fight.stance = "strike"


## How close to the point a crest is pressed down (px): closer as the barb goes in.
func _apep_reach() -> float:
	var e: Dictionary = game.fight.e
	return lerpf(float(e.reach[0]), float(e.reach[1]), _apep_k()) * game.unit


func _apep_waves(dt: float) -> void:
	var e: Dictionary = game.fight.e
	var reach := _apep_reach()
	var px: float = game.fight.point_x
	var down: bool = game.fight.get("down", false)
	for w in game.fight.waves.duplicate():
		w.t += dt
		match w.s:
			"lash":            # the tail lashes
				w.amp = minf(w.t / w.lash, 1.0)
				if w.t >= w.lash:
					w.s = "run"
			"run", "past":
				var x0: float = w.x
				w.x += w.v * dt
				if w.s == "past":   # runs out round the fold
					w.amp = clampf(1.0 - (w.x - px - reach) / maxf(1.0, float(e.fold) - px - reach), 0.0, 1.0)
					if w.amp <= 0.0:
						game.fight.waves.erase(w)
				elif w.kind == "medium" and down and x0 <= px + reach and w.x >= px - reach:   # its crest passed under the point
					_apep_pressed(w)
				elif w.x > px + reach:
					w.s = "past"
					_apep_passed(w)
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
	if game.hard():            # he is pushed back half a step
		game.fight.adv_to = maxf(0.0, game.fight.adv_to - float(e.advance) * game.unit / 2.0)
	game._hurt(game.actors[e.foe])
	game._dev_shot("SHOT_ON_CATCH")
	if game.fight.hits >= int(e.need):
		for o in game.fight.waves:
			o.s = "pressed"


## A thrust at the fold that pressed nothing down: early for a wave on its way, or else on a still
## neck (or a small wave).
func _apep_jab() -> void:
	var px: float = game.fight.point_x
	var coming: bool = game.fight.waves.any(func(w): return w.kind == "medium" and w.s in ["lash", "run"] and px - w.x < w.v * APEP_EARLY)
	if coming:
		game._feedback_once("Too early", game._feedback_text("too_early"))
	elif game.fight.hits > 0:
		game.fight.hits -= 1
		game._feedback_once("The barb slipped back", game._feedback_text("barb_slipped"))
	else:
		game._feedback_once("Wait for a wave to reach the spear point", game._feedback_text("no_wave"))


## A wave got past the point. A small one does nothing. A medium or large one lifts his head out
## from under it to bite (it misses if he has hopped back); in hard mode a medium one let past from
## back there makes Apep advance.
func _apep_passed(w: Dictionary) -> void:
	if w.kind == "small":
		return
	var back: bool = game.fight.stance == "dodge"
	if back and w.kind == "medium" and game.hard():
		_apep_advance()
	if back:
		_apep_slip(w)
		return
	if w.kind == "large":
		game._feedback_once("large_wave", game._feedback_text("large_wave"))
		_apep_slip(w)
		return
	var since: float = game.fight.clock - game.fight.last_thrust
	if since < APEP_EARLY + 2.0 * _apep_reach() / w.v:
		game._feedback_once("Too early", game._feedback_text("missed_wave"))
	else:
		game._feedback_once("The wave got through", game._feedback_text("wave_passed"))
	_apep_slip(w)


## His head flips over from under the point and strikes straight ahead, at where he stands now
## (hopped back, it will snap at nothing).
func _apep_slip(_w: Dictionary) -> void:
	game.fight.head.miss = game.fight.stance == "dodge"
	_apep_head_phase("rear")
	game.fight.next = maxf(game.fight.next, game.fight.clock + 0.6)


## (hard mode) Apep slides a step nearer; if that leaves no room to hop back, he is pushed forward
## to the fold.
func _apep_advance() -> void:
	game.fight.adv_to += float(game.fight.e.advance) * game.unit
	game._feedback_once("advanced", game._feedback_text("advanced"))
	if not _apep_can_dodge():
		game.fight.stance = "strike"
		game._feedback_once("at_wall", game._feedback_text("at_wall"))


func _apep_head_phase(p: String) -> void:
	var h: Dictionary = game.fight.head
	h.phase = p
	h.t = 0.0
	h.f0 = h.f


## His head along the strike sheet (`f`, frames): up a little as a crest comes under it; flipped over,
## straightened out and biting; and back down the same way.
func _apep_head(dt: float) -> void:
	var h: Dictionary = game.fight.head
	var marks: Dictionary = strike.marks.strike
	var last: float = float(strike.frames) - 1.0
	h.t += dt
	match h.phase:
		"rest":          # strains up as a crest comes under it
			var lift = _apep_lift(float(strike.joint[0])) / (float(game.fight.e.height) * game.unit)
			h.f = APEP_STRAIN * clampf(lift, 0.0, 1.0)
		"rear":
			var u := minf(h.t / APEP_REAR, 1.0)
			h.f = lerpf(h.f0, float(marks.reared), u)
			if u >= 1.0:
				_apep_head_phase("turn")
		"turn":          # straight out at him
			var u := minf(h.t / APEP_TURN, 1.0)
			h.f = lerpf(float(marks.reared), last, u)
			if u >= 1.0:
				_apep_head_phase("bitten")
				if game.fight.head.miss:       # he had hopped back: it snaps at nothing
					game._feedback_once("dodged", game._feedback_text("dodged"))
				else:
					_apep_bites()
		"bitten":
			if h.t >= 0.3:
				_apep_head_phase("back")
		"back":
			var u := minf(h.t / APEP_BACK, 1.0)
			h.f = lerpf(last, 0.0, u * u * (3.0 - 2.0 * u))
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


## When wave `w` reaches the point (s from now).
func _apep_due(w: Dictionary) -> float:
	return maxf(0.0, w.lash - w.t if w.s == "lash" else 0.0) + (game.fight.point_x - w.x) / w.v


## Dev (`--croc-bot`, and the autotest's trials): hops back for a large wave and forward for any
## other, and thrusts APEP_BOT_LEAD s before each medium crest reaches the point. `bot_style`
## "strike" never hops back; "dodge" stays back and never thrusts.
func _apep_bot() -> void:
	if OS.has_environment("BOT_MISS"):
		return
	var style: String = game.fight.get("bot_style", "read")
	var coming: Array = game.fight.waves.filter(func(w): return w.s in ["lash", "run"])
	coming.sort_custom(func(a, b): return _apep_due(a) < _apep_due(b))
	var want := "strike"
	if style == "dodge" or (style == "read" and not coming.is_empty() and coming[0].kind == "large"):
		want = "dodge"
	if want != game.fight.stance:
		_apep_step(1 if want == "dodge" else -1)
	if style == "dodge" or game.fight.thrust >= 0.0 or game.fight.pinned or not _apep_at_fold():
		return
	for w in coming:
		if w.kind == "medium" and w.s == "run" and _apep_due(w) <= APEP_BOT_LEAD:
			game._croc_thrust()
			return


## (autotest) A wave of `kind` at `v` px/s from the tail, Space pressed `tau` s from when its crest
## would reach the point (none if `tau` is INF); true = pressed down. Other waves are held back.
func _apep_try(tau: float, v: float, dt := 1.0 / 240.0, kind := "medium") -> bool:
	game.fight.waves = []
	game.fight.next = INF
	game.fight.thrust = -1.0
	game.fight.pinned = false
	game.fight.struck = true
	_apep_head_phase("rest")
	var hits: int = game.fight.hits
	var w := _apep_launch(kind, v)
	var arrive: float = w.lash + game.fight.point_x / v
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


## (autotest) One whole fight against spell 39 played by the bot in `style`, in hard mode or not,
## from random seed `seed`: "won", "lost" or "" (neither, in 150 s). Leaves the fight stepped out of.
func _apep_trial(e: Dictionary, style: String, hard: bool, seed: int) -> String:
	var b0 = game.bites
	var items0: Array[String] = game.items.duplicate()
	game.items.assign([] if hard else ["sail38"])
	game.rng.seed = seed
	game.start_fight(e)
	game.fight.bot = true
	game.fight.bot_style = style
	var out := ""
	var t := 0.0
	while t < 150.0:
		_apep(1.0 / 60.0)
		t += 1.0 / 60.0
		if game.fight.is_empty() or (game.fight.pinned and game.fight.hits >= int(e.need)):
			out = "won"
			break
		if game.fight.lost:
			out = "lost"
			break
	if not game.fight.is_empty():
		game.leave_fight()
	game.solved.erase(e.id)
	game.journal.clear()
	game.bites = b0
	game.items.assign(items0)
	return out


func autotest(e: Dictionary, expect: Callable) -> void:
	var need := int(e.need)
	var slow: float = float(e.speed[0]) * game.unit
	var fast: float = float(e.speed[1]) * game.unit
	var step := func(t: float) -> void:
		while t > 0.0 and not game.fight.lost:
			_apep(minf(t, 1.0 / 120.0))
			t -= 1.0 / 120.0
	expect.call(game.fight.waves.is_empty() and game._spear_out() < 0.0, e.id + " the barb rests drawn back from his neck")
	expect.call(game.fight.point_x > 0.0 and game.fight.point_x < float(e.fold), e.id + " the spear point is on the fold")
	# opened out, Apep and the bearer have slid left together, leaving room behind him
	var a: Node2D = game.actors[e.foe]
	var room: float = game.fight.barrier - (game.fight.pos.x + game.fight.back_reach)
	print("spell 39 room behind him: %.0f px (hop back %.0f, advance %.0f)" % [room, float(e.dodge) * game.unit, float(e.advance) * game.unit])
	expect.call(is_equal_approx(a.position.x - a.get_meta("home").x, game.fight.pos.x - game.fight.stand.x) and a.position.x <= a.get_meta("home").x, e.id + " Apep and the bearer slide left together as it opens, if at all")
	expect.call(room >= (float(e.dodge) + float(e.room) * float(e.advance)) * game.unit - 0.5, e.id + " ...leaving room to hop back and for Apep to advance %d times" % int(e.room))
	expect.call(game.fight.full.position.x <= game.span(e).x, e.id + " ...the whole vignette in view")
	# the window: press Space at `tau` s from the crest reaching the point (sim at 240 fps)
	var good: Array = _apep_window(slow)
	print("spell 39 window: %.3f .. %.3f s from the crest reaching the point (%.0f ms)" % [good[0], good[1], (good[1] - good[0]) * 1000.0])
	expect.call(good[1] - good[0] >= 0.08, e.id + " a window of at least 80 ms for the first waves")
	game.fight.health = 99
	expect.call(not _apep_try(-0.4, slow), e.id + " a thrust well before the wave arrives misses it")
	expect.call(not _apep_try(0.25, slow), e.id + " a thrust after the wave is past misses it")
	# a medium wave that gets past: his head rears, turns and bites
	game.fight.health = game.CROC_HEALTH
	var b0 = game.bites
	_apep_try(INF, slow)
	expect.call(game.fight.head.phase == "rear", e.id + " a medium wave past the point lifts his head out from under it")
	step.call(0.3)
	expect.call(game.bites == b0 + 1 and game.fight.health == game.CROC_HEALTH - 1 and game.fight.red > 0.0, e.id + " ...and he bites the bearer")
	step.call(0.9)
	expect.call(game.fight.head.phase == "rest", e.id + " ...and lies down again")
	game.fight.health = game.CROC_HEALTH
	# his head strains up as a crest comes under it
	game.fight.waves = []
	var hw := _apep_launch("medium", slow)
	hw.s = "run"
	hw.amp = 1.0
	hw.x = float(strike.joint[0])
	_apep_head(0.0)
	expect.call(game.fight.head.f > APEP_STRAIN * 0.9, e.id + " his head lifts as a wave comes under it")
	# his front comes from the strike sheet: as drawn at rest, and all the frames in a strike
	var front: Sprite2D = a.get_node("Front")
	expect.call(a.get_node_or_null("HeadPivot") == null and front.texture is AtlasTexture, e.id + " his front is drawn from the strike sheet, not a head cut loose")
	game.fight.waves = []
	_apep_head_phase("rest")
	_apep_head(0.0)
	_apep_place()
	expect.call((front.texture as AtlasTexture).region.position == Vector2.ZERO, e.id + " ...lying as drawn")
	var seen := {}
	game.fight.health = 99
	game.fight.head.miss = false
	_apep_slip({"kind": "medium"})
	for i in 120:
		_apep_head(1.0 / 120.0)
		_apep_place()
		seen[int((front.texture as AtlasTexture).region.position.x / float(strike.cell[0]))] = true
	expect.call(seen.size() >= int(strike.frames) - 2 and game.fight.head.phase == "rest", e.id + " ...every frame on the way through a strike, and back to as drawn (%d of %d)" % [seen.size(), int(strike.frames)])
	game.fight.health = game.CROC_HEALTH
	# the three sizes, and the lash shows which
	var sm := _apep_launch("small", slow)
	var md := _apep_launch("medium", slow)
	var lg := _apep_launch("large", slow)
	expect.call(sm.h < md.h and md.h < lg.h and lg.lash > md.lash, e.id + " small, medium and large waves, the large one lashed longer")
	# a small wave is a feint to the end: it runs under the point, no bite; a thrust on it loosens the barb
	b0 = game.bites
	_apep_try(INF, slow, 1.0 / 240.0, "small")
	step.call(0.8)
	expect.call(game.bites == b0 and game.fight.head.phase == "rest", e.id + " a small wave runs all the way under the point, and does nothing")
	game.fight.hits = 2
	_apep_try(0.0, slow, 1.0 / 240.0, "small")
	step.call(0.3)
	expect.call(game.fight.hits == 1, e.id + " ...but a thrust on it works the barb loose a step")
	game.fight.hits = 0
	# a large wave cannot be pressed down: at the fold it bites
	b0 = game.bites
	expect.call(not _apep_try(0.0, slow, 1.0 / 240.0, "large"), e.id + " a large wave cannot be pressed down")
	step.call(0.4)
	expect.call(game.bites == b0 + 1, e.id + " ...and at the fold it bites")
	step.call(0.9)
	game.fight.health = game.CROC_HEALTH
	# [→] hops him back, in one hop; he stays back until [←]
	var x0: float = game.fight.pos.x
	_apep_step(1)
	step.call(APEP_HOP * 0.5)
	expect.call(game.fight.pos.x > x0 and game.fight.pos.x < x0 + float(e.dodge) * game.unit, e.id + " [→] hops him back ...")
	step.call(APEP_HOP)
	expect.call(is_equal_approx(game.fight.pos.x, x0 + float(e.dodge) * game.unit), e.id + " ...one hop's length")
	step.call(1.0)
	expect.call(game.fight.stance == "dodge", e.id + " ...and he stays back")
	# hopped back: a large wave snaps at nothing; a thrust falls short
	b0 = game.bites
	game.fight.hits = 2
	_apep_try(0.0, slow, 1.0 / 240.0, "large")
	step.call(0.8)
	expect.call(game.bites == b0 and game.fight.hits == 2, e.id + " hopped back, a large wave snaps at nothing, and his thrust falls short")
	# with the breath of life, a medium one let past from back there does nothing
	_apep_try(INF, slow)
	step.call(0.8)
	expect.call(game.bites == b0 and game.fight.adv_to == 0.0, e.id + " with the breath of life, a medium wave let past from back there does nothing")
	# in hard mode it makes Apep advance, and his stances with him; a small one still does nothing
	game.items.erase("sail38")
	var hard_ok: bool = game.hard()
	_apep_try(INF, slow, 1.0 / 240.0, "small")
	step.call(0.8)
	expect.call(hard_ok and game.fight.adv_to == 0.0, e.id + " in hard mode a small wave let past from back there does nothing")
	var back0: float = game.fight.pos.x
	_apep_try(INF, slow)
	step.call(0.8)
	var adv: float = float(e.advance) * game.unit
	expect.call(game.bites == b0 and is_equal_approx(game.fight.adv, adv) and is_equal_approx(game.fight.pos.x, back0 + adv) and is_equal_approx(a.position.x, a.get_meta("home").x - game.fight.shift + adv),
		e.id + " in hard mode a medium wave let past from back there: no bite, but Apep advances, and his stances with him")
	# a wave pressed down pushes him back half a step
	_apep_step(-1)
	step.call(APEP_HOP + 0.01)
	expect.call(_apep_try((good[0] + good[1]) / 2.0, slow), e.id + " (a wave pressed down)")
	step.call(1.0)
	expect.call(is_equal_approx(game.fight.adv, adv / 2.0), e.id + " in hard mode a wave pressed down pushes Apep back half a step")
	game.fight.hits = 0
	# no further back than where he started
	for i in 3:
		_apep_pressed({"s": "run"})
		game.fight.pinned = false
	expect.call(game.fight.adv_to == 0.0, e.id + " ...never further back than where he started")
	game.fight.hits = 0
	# advanced to where there is no room to hop back: [→] does nothing, and back there he is pushed forward
	_apep_step(1)
	step.call(APEP_HOP + 0.01)
	var n := 0
	while _apep_can_dodge() and n < 50:
		_apep_advance()
		n += 1
	step.call(3.0)
	expect.call(n > 0 and game.fight.stance == "strike" and game.fight.hop == 0.0, e.id + " advanced to the wall, he is pushed forward to the fold")
	_apep_step(1)
	step.call(APEP_HOP + 0.01)
	expect.call(game.fight.stance == "strike" and game.fight.pos.x + game.fight.back_reach <= game.fight.barrier + 0.5, e.id + " ...[→] no longer hops him back, and he stays inside the double line")
	game.items.append("sail38")
	game.leave_fight()
	game.start_fight(e)
	game.fight.open = 1.0
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
	# the waves come by themselves: medium and large ones never too close at the point (further
	# apart if they want different answers), at most `most` on his body at once
	for hard in [false, true]:
		if hard:
			game.items.erase("sail38")
		game.fight.waves = []
		game.fight.last_arrival = -INF
		game.fight.last_kind = ""
		game.fight.launched = int(e.teach)
		var arrivals := []
		for i in 80:           # asked for a wave every 0.1 s
			var before: int = game.fight.launched
			game.fight.waves = []
			game.fight.next = game.fight.clock
			_apep_launch_due()
			if game.fight.launched > before and game.fight.waves[0].kind != "small":
				arrivals.append([game.fight.last_arrival, game.fight.waves[0].kind])
			game.fight.clock += 0.1
		var gaps_ok := true
		for i in range(1, arrivals.size()):
			var gap: float = float(_apep_e("min_gap") if arrivals[i][1] == arrivals[i - 1][1] else _apep_e("switch_gap"))
			gaps_ok = gaps_ok and arrivals[i][0] - arrivals[i - 1][0] >= gap - 0.001
		expect.call(gaps_ok and arrivals.size() >= 3, e.id + " waves reach the point far enough apart%s" % (" (hard)" if hard else ""))
		game.fight.waves = []
		game.fight.health = 99
		var most := 0
		for i in 1200:
			game.fight.next = minf(game.fight.next, game.fight.clock)
			_apep(1.0 / 60.0)
			most = maxi(most, _apep_on_body())
		expect.call(most <= int(_apep_e("most")) and most >= 2, e.id + " at most %d waves on his body at once%s (%d)" % [int(_apep_e("most")), " (hard)" if hard else "", most])
		game.fight.waves = []
		game.fight.next = INF
		game.fight.health = game.CROC_HEALTH
		game.fight.hits = 0
		game.fight.adv = 0.0
		game.fight.adv_to = 0.0
		if hard:
			game.items.append("sail38")
	# the third bite and he crumbles
	game.fight.health = 1
	_apep_try(INF, slow)
	step.call(0.6)
	expect.call(game.fight.lost, e.id + " the third bite and he crumbles")
	game.fight.lost = false
	game.leave_fight()
	# whole fights played by a stand-in player
	var rate := func(style: String, hard: bool, want: String) -> float:
		var got := 0
		for i in 30:
			if _apep_trial(e, style, hard, 3000 + i) == want:
				got += 1
		return got / 30.0
	var read_easy: float = rate.call("read", false, "won")
	var read_hard: float = rate.call("read", true, "won")
	var strike_lost: float = rate.call("strike", true, "lost")
	var dodge_lost: float = rate.call("dodge", true, "lost")
	var dodge_easy: float = rate.call("dodge", false, "")
	print("spell 39: reading the waves wins %d%% (hard %d%%); never hopping back loses %d%% (hard); always back loses %d%% (hard), and with the breath neither wins nor loses %d%%" % [read_easy * 100, read_hard * 100, strike_lost * 100, dodge_lost * 100, dodge_easy * 100])
	expect.call(read_easy >= 0.9 and read_hard >= 0.9, e.id + " reading each wave (strike, let pass, hop back) wins nearly every fight")
	expect.call(strike_lost >= 0.7, e.id + " never hopping back, the large waves bite: mostly lost")
	expect.call(dodge_lost >= 0.8, e.id + " in hard mode always hopping back, Apep advances to the wall: lost")
	expect.call(dodge_easy == 1.0, e.id + " with the breath, staying back is never bitten, and never wins")
	game.start_fight(e)
