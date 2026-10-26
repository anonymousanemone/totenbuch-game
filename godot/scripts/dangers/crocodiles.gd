## Crocodiles encounter behavior and acceptance checks.
extends RefCounted

var game


func _init(level) -> void:
	game = level


# crocodiles. The vignette opens out across the whole screen (the caption banner stays; the text
# below drops away). The spear-bearer moves with the arrow keys (or WASD) and thrusts with Space.
# Crocodiles crawl in at different heights, each a copy of one of the four drawn ones. A thrust
# spears a crocodile its point comes down on, anywhere inside its outline or close by its snout;
# a crocodile that reaches the bearer, or gets past him, bites (his body flushes red). Some come red: those are turned back only by a thrust made while
# holding Shift (heka; the spear turns red). A plain thrust does nothing to a red one, and heka spent
# on an ordinary one loses the fight: it seizes the word of heka from the banner and makes off.
# In spell 31 they come from the left: the double line behind him stays where it is drawn, the
# vignette opens out to the left only, and he moves only up and down. In spell 32 (`both_sides`)
# they come from both sides, he stands in the middle and ← → turn him.
const CROC_REACH := 20.0        ## the point also counts this close to the snout (plate px)
const CROC_SAME_SPOT := 1.0     ## two from one side at nearly one height reach him at least this far apart (s)
const CROC_FRONT_OVERLAP := 0.15   ## how far (of their height) two front halves may overlap above and below
const CROC_GRACE := 5.0         ## the spear point counts this close outside a crocodile's outline (plate px)
const CROC_LANE := 70.0         ## spacing of the heights the crocodiles come at
const BEARER_SPEED := 260.0     ## how fast the bearer moves
const CROC_FORWARD := 30.0      ## in one-sided fights he stands this far in front of where he is drawn


func _crocs_start(e: Dictionary) -> void:
	game._arena_setup(e, e.get("both_sides", false), e.foes)
	var full: Rect2 = game.fight.full
	game.fight.copies = []
	game.fight.timer = 1.2
	# waves: the lesson, a break, then the red ones (or a single wave from `count`, `speed`, ...)
	if e.has("waves"):
		game.fight.waves = e.waves
	else:
		game.fight.waves = [{"count": e.count, "speed": e.speed, "interval": e.interval, "at_once": e.at_once, "red": e.get("red", 0.0)}]
	game.fight.wave = 0                  # a lost fight always starts again from the first wave
	game.fight.wave_killed = 0
	game.fight.wave_launched = 0
	game.fight.phase = ""
	game.fight.killed = 0
	for i in game.fight.wave:
		game.fight.killed += int(game.fight.waves[i].count)
	var w0: Dictionary = game.fight.waves[game.fight.wave]
	# the heka word flashes once red crocodiles can come (from the start, or after the first break)
	game.fight.heka_on = game.fight.wave > 0 or w0.get("red", 0.0) > 0.0 or true in w0.get("red_order", [])
	game.fight.nudged = false
	game.fight.health = game.CROC_HEALTH
	game.fight.clock = 0.0
	game.fight.last_arrival = -INF
	game.fight.told_back = false
	game.fight.tut = "thrust" if e.get("tutorial", false) and game.fight.wave == 0 else ""
	# the heights the snouts can come at: wherever the spear tip can reach
	var lo: float = game.fight.y_range.x + game.fight.tip.y
	var hi: float = game.fight.y_range.y + game.fight.tip.y
	var tallest := 0.0         # ...and low enough lanes still keep the crocodile inside the frame
	for f in e.foes:
		tallest = maxf(tallest, game.actors[f].get_meta("size").y)
	hi = minf(hi, full.end.y - 26.0 * game.unit - tallest * 0.78)
	game.fight.lanes = []
	var n = maxi(3, int((hi - lo) / (CROC_LANE * game.unit)) + 1)
	for i in n:
		game.fight.lanes.append(lerpf(lo, hi, float(i) / (n - 1)))
	# the four drawn crocodiles wait spread out on the left, at different heights
	game.fight.crocs = []
	var lanes: Array = game.fight.lanes.duplicate()
	lanes.shuffle()
	for i in e.foes.size():
		var a: Node2D = game.actors[e.foes[i]]
		var start = Vector2(full.position.x + (0.12 + 0.13 * i) * (game.fight.stand.x - full.position.x), 0.0)
		start.y = float(lanes[i % lanes.size()]) - _croc_head(a, 1).y
		game.fight.crocs.append({"node": a, "s": "wait", "home": a.get_meta("home"), "start": start, "speed": 0.0, "dir": 1, "red": false})
	game._arena_open()


## Where a crocodile's snout is, from its pivot (bottom centre); dir 1 = it faces right, -1 = left.
func _croc_head(a: Node2D, dir: int) -> Vector2:
	var size: Vector2 = a.get_meta("size")
	return Vector2(size.x * 0.46 * dir, -size.y * 0.78)


var _solids := {}        ## crocodile texture -> its outline filled in (Image, alpha = solid)


## Does the point `p` lie on crocodile `c`: inside its drawn outline (filled), or within CROC_GRACE?
func _on_croc(c: Dictionary, p: Vector2) -> bool:
	var sp: Sprite2D = game._picture(c.node)
	var solid := _solid_of(sp.texture)
	var q := sp.to_local(p) - sp.offset
	var w := solid.get_width()
	var h := solid.get_height()
	var g = CROC_GRACE * game.unit
	for o in [Vector2.ZERO, Vector2(g, 0), Vector2(-g, 0), Vector2(0, g), Vector2(0, -g)]:
		var x := int(q.x + o.x)
		var y := int(q.y + o.y)
		if sp.flip_h:
			x = w - 1 - x
		if x >= 0 and y >= 0 and x < w and y < h and solid.get_pixel(x, y).a > 0.5:
			return true
	return false


## A crocodile's silhouette: its ink, with everything the outline encloses filled in.
func _solid_of(tex: Texture2D) -> Image:
	if _solids.has(tex):
		return _solids[tex]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var ink := PackedByteArray()
	ink.resize(w * h)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.3:
				# a little thicker, so small gaps in the outline do not let the fill leak out
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var xx := x + dx
						var yy := y + dy
						if xx >= 0 and yy >= 0 and xx < w and yy < h:
							ink[yy * w + xx] = 1
	# flood the outside from the edges; whatever it cannot reach is the crocodile
	var outside := PackedByteArray()
	outside.resize(w * h)
	var todo: Array[int] = []
	for x in w:
		todo.append(x)
		todo.append((h - 1) * w + x)
	for y in h:
		todo.append(y * w)
		todo.append(y * w + w - 1)
	while not todo.is_empty():
		var i: int = todo.pop_back()
		if outside[i] == 1 or ink[i] == 1:
			continue
		outside[i] = 1
		var x := i % w
		var y := i / w
		if x > 0: todo.append(i - 1)
		if x < w - 1: todo.append(i + 1)
		if y > 0: todo.append(i - w)
		if y < h - 1: todo.append(i + w)
	var solid := Image.create(w, h, false, Image.FORMAT_LA8)
	for i in w * h:
		if outside[i] == 0:
			solid.set_pixel(i % w, i / w, Color(1, 1, 1, 1))
	_solids[tex] = solid
	return solid


func _snout(c: Dictionary) -> Vector2:
	return c.node.position + _croc_head(c.node, c.dir)


func _holding_heka() -> bool:
	return Input.is_key_pressed(KEY_SHIFT) or game.fight.get("force_heka", false)


func _crocs(dt: float) -> void:
	var e: Dictionary = game.fight.e
	if game.fight.open < 1.0 or game.fight.lost:
		return
	game.fight.clock += dt
	_move_bearer(_bot_move() if game.fight.get("bot", false) else _keys(), dt)
	if game.fight.thrust >= 0.0:
		game.fight.thrust += dt
		if not game.fight.struck and game.fight.thrust >= game.THRUST_TIME[0]:
			game.fight.struck = true
			_croc_strike()
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
	game.fight.red = maxf(0.0, game.fight.red - dt)
	game._place_bearer()
	if game.fight.lost:
		return
	# the lesson: thrust, then one slow crocodile
	match game.fight.tut:
		"ready":
			game.fight.tut = "first"
			game.say("Scribe", game._feedback_text("first_crocodile"))
			_croc_launch(e.first_speed)
		"":
			game.fight.timer -= dt
			var w: Dictionary = game.fight.waves[game.fight.wave]
			if game.fight.phase == "break":
				if game.fight.timer <= 0.0:
					_croc_next_wave()
			else:
				var crawling: int = game.fight.crocs.filter(func(c): return c.s == "crawl" or c.s == "back").size()
				if game.fight.timer <= 0.0 and crawling < w.at_once and game.fight.wave_launched < w.count:
					var ramped: float = w.speed * (1.0 + w.get("ramp", 0.0) * game.fight.wave_launched)
					game.fight.timer = w.interval if _croc_launch(ramped) else 0.15
	# crawl; a crocodile that reaches the bearer, or gets past him, bites
	var bearer: Rect2 = game.actor_rect(e.spear)
	for c in game.fight.crocs:
		if c.s != "crawl":
			continue
		var a: Node2D = c.node
		a.position.x += c.speed * game.unit * dt * c.dir
		a.rotation = sin(game._time * 14.0 + a.position.y) * 0.012
		var head := _snout(c)
		var size: Vector2 = a.get_meta("size")
		var level_with := a.position.y > bearer.position.y + bearer.size.y * 0.35 and a.position.y - size.y < bearer.end.y
		var at_him := false
		var past := false
		# past: in spell 31 its snout reaches the double line behind him; in spell 32 (no wall) its
		# whole body, tail and all, has crossed past him
		if c.dir > 0:
			at_him = level_with and head.x >= bearer.position.x + bearer.size.x * 0.45
			past = (a.position.x - size.x / 2.0 >= bearer.end.x) if game.fight.both else head.x >= game.fight.barrier
		else:
			at_him = level_with and head.x <= bearer.end.x - bearer.size.x * 0.45
			past = a.position.x + size.x / 2.0 <= bearer.position.x
		if at_him:
			_croc_bites(c)
		elif past:
			# once the heka word glows, one that slips past goes up for it; before that it just bites
			if game.fight.heka_on:
				_croc_eats_word(c)
				return
			_croc_bites(c)


## The arrow keys (or WASD); ← → only where he can turn.
func _keys() -> Vector2:
	var mv := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	mv.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if not game.fight.both:
		mv.x = 0.0
	mv.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	return mv


## Move (or, with foes on both sides, turn) the bearer.
func _move_bearer(mv: Vector2, dt: float) -> void:
	if game.fight.both and mv.x != 0.0:
		game.fight.facing = 1 if mv.x > 0.0 else -1
		mv.x = 0.0
	if mv != Vector2.ZERO:
		var p: Vector2 = game.fight.pos + mv.limit_length(1.0) * BEARER_SPEED * game.unit * dt
		p.x = clampf(p.x, game.fight.x_range.x, game.fight.x_range.y)
		p.y = clampf(p.y, game.fight.y_range.x, game.fight.y_range.y)
		game.fight.pos = p


## A thrust at its furthest: the snout nearest the spear tip, if close enough, is struck.
## Without heka only an ordinary crocodile turns; with heka only a red one does, and heka spent
## on an ordinary crocodile loses the fight.
func _croc_strike() -> void:
	var e: Dictionary = game.fight.e
	var tip0: Vector2 = game.fight.pos + game._tip_offset()
	var tip: Vector2 = tip0 + game._spear_dir() * game.CROC_THRUST * game.unit
	# the point, anywhere along its last stroke, must come down on a crocodile (inside its outline),
	# or close by its snout
	var best = null
	var best_d := INF
	for c in game.fight.crocs:
		if c.s != "crawl":
			continue
		var h := _snout(c)
		var on = Geometry2D.get_closest_point_to_segment(h, tip0, tip).distance_to(h) < CROC_REACH * game.unit
		for i in 5:
			if _on_croc(c, tip0.lerp(tip, i / 4.0)):
				on = true
				break
		# where the point is on two at once, the one the spear is fit for (heka or not) comes first
		var d := _snout(c).distance_to(tip) + (0.0 if c.red == _holding_heka() else 100000.0)
		if on and d < best_d:
			best_d = d
			best = c
	if best == null:
		return
	var heka := _holding_heka()
	if best.red and not heka:
		return                  # plain bronze does nothing to a red crocodile
	if heka and not best.red:
		_croc_steals(best)
		return
	best.s = "gone"
	game.fight.killed += 1
	game.fight.wave_killed += 1
	var a: Node2D = best.node
	a.rotation = 0.0
	game._picture(a).flip_h = best.dir > 0    # it turns round
	var t = game._fight_tween(a)
	t.tween_property(a, "position:x", a.position.x - 60.0 * game.unit * best.dir, 0.5)
	t.parallel().tween_property(a, "modulate:a", 0.0, 0.5)
	var w: Dictionary = game.fight.waves[game.fight.wave]
	var wave_done: bool = game.fight.wave_killed >= w.count
	if game.fight.tut == "first":
		game.fight.tut = ""
		game.fight.timer = 1.5
		if not wave_done:
			game.say("Scribe", game._feedback_text("first_strike"))
	elif not wave_done:
		game.say("Scribe", game._feedback_text("crocodile_defeated"))
	if wave_done:
		if game.fight.wave + 1 < game.fight.waves.size():
			_croc_break()
		else:
			game._won_if(true)


## Between waves: the crocodiles draw back, the heka word starts to flash, a breather.
func _croc_break() -> void:
	var e: Dictionary = game.fight.e
	game.fight.phase = "break"
	game.fight.timer = e.get("break", 5.0)
	game.fight.heka_on = true
	game.say("Scribe", game._feedback_text("heka_break"))


func _croc_next_wave() -> void:
	game.fight.wave += 1
	game.fight.phase = ""
	game.fight.wave_killed = 0
	game.fight.wave_launched = 0
	game.fight.timer = 0.3


func _croc_total() -> int:
	var n := 0
	for w in game.fight.waves:
		n += int(w.count)
	return n


## Heka thrust at an ordinary crocodile: it takes the word of heka and runs.
func _croc_steals(c: Dictionary) -> void:
	_croc_takes_word(c, game._feedback_text("heka_on_normal_crocodile"))


## A crocodile got past the bearer, once the heka word glows: it goes off with the word.
func _croc_eats_word(c: Dictionary) -> void:
	_croc_takes_word(c, game._feedback_text("crocodile_escaped"))


## Lost: the crocodile laughs (squashes up and down) and turns round, the heka word spins down from
## the banner into its jaws, the spear-bearer crumbles the moment it lands, and the crocodile carries
## the word off. Then the vignette closes and he is back on the scroll.
func _croc_takes_word(c: Dictionary, why: String) -> void:
	game.fight.lost = true
	var e: Dictionary = game.fight.e
	game.say("Scribe", why)
	c.s = "thief"
	var a: Node2D = c.node
	a.rotation = 0.0
	var size: Vector2 = a.get_meta("size")
	var words: Array = game._heka_words(e.id)
	var dir: int = -c.dir                       # the way it leaves
	var mouth := a.position + _croc_head(a, dir)
	var t = game._fight_tween()
	# it laughs
	for i in 4:
		t.tween_property(a, "scale", Vector2(1.06, 0.78), 0.1)
		t.tween_property(a, "scale", Vector2(0.96, 1.12), 0.1)
	t.tween_property(a, "scale", Vector2.ONE, 0.08)
	# it turns round
	t.tween_callback(func():
		c.dir = dir
		game._picture(a).flip_h = dir < 0)
	# the word spins down into its jaws
	for nm in words:
		var w: Node2D = game.actors[nm]
		w.modulate = game.RED_CROC
		t.parallel().tween_property(w, "position", mouth + Vector2(0.0, game.actor_rect(nm).size.y), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(w, "rotation", TAU * 2.0, 0.7)
	t.tween_callback(func(): game._disintegrate(e))     # the moment the word is in its jaws, he crumbles
	t.tween_interval(0.2)
	# and carries it off
	var away: float = (game.fight.full.position.x - size.x) if dir < 0 else (game.fight.full.end.x + size.x)
	var dx := away - a.position.x
	t.tween_property(a, "position:x", a.position.x + dx, 1.6)
	for nm in words:
		t.parallel().tween_property(game.actors[nm], "position:x", mouth.x + dx, 1.6)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "crocs" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


## Dev (`--croc-bot`): a stand-in player with a human's limits (sees a crocodile only REACT s after
## it sets off, moves at the bearer's speed), to check that a fight can be won.
const REACT := 0.35

func _bot_move() -> Vector2:
	var best = null
	var soon := INF
	for c in game.fight.crocs:
		if c.s != "crawl" or game.fight.clock - c.get("t0", game.fight.clock) < (float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else REACT):
			continue
		var eta: float = absf(game.fight.pos.x - _snout(c).x) / (c.speed * game.unit)
		if eta < soon:
			soon = eta
			best = c
	if best == null:
		return Vector2.ZERO
	var want_face := -int(best.dir)
	var mv = Vector2(float(want_face) if game.fight.both and game.fight.facing != want_face else 0.0, 0.0)
	var dy: float = _snout(best).y - (game.fight.pos.y + game.fight.tip.y)
	if absf(dy) > 4.0 * game.unit:
		mv.y = signf(dy)
	# strike when the snout is at the tip, with heka for a red one
	var tip: Vector2 = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit
	# (where the crocodile will be when the thrust lands: a little further in)
	var lands = tip - Vector2(best.dir * best.speed * game.unit * game.THRUST_TIME[0], 0.0)
	var near: bool = _snout(best).distance_to(tip) < CROC_REACH * 0.8 * game.unit + best.speed * game.unit * game.THRUST_TIME[0]
	if game.fight.facing == want_face and (near or _on_croc(best, lands - Vector2(best.dir * CROC_REACH * 0.5 * game.unit, 0.0))):
		game.fight.force_heka = best.red
		game._croc_thrust()
	if game.fight.thrust >= 0.0:
		mv.y = 0.0          # holds still while the spear goes in
	return mv


## The last bite: he crumbles away, and he is back on the scroll.
func _croc_dies(c: Dictionary) -> void:
	game.fight.lost = true
	var e: Dictionary = game.fight.e
	game.say("Scribe", game._hints.message("dangers.defeated"))
	c.s = "thief"
	game._disintegrate(e)
	var t = game._fight_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "crocs" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


func _croc_bites(c: Dictionary) -> void:
	game.fight.red = 0.8
	if game.fight.tut == "":
		game.fight.health -= 1
		if game.fight.health <= 0:
			game.bites += 1
			_croc_dies(c)
			return
	if c.red and not game.heka_known and not game.fight.nudged:
		game.fight.nudged = true
		game.say("Scribe", game._feedback_text("red_crocodile"))
		c.s = "back"
		_croc_send_back(c)
		game.bites += 1
		return
	game._bite("tutorial_bite" if game.fight.tut == "first" else "bitten")
	c.s = "back"
	_croc_send_back(c)


## A crocodile that bit slinks back to its own side and comes again at another height.
func _croc_send_back(c: Dictionary) -> void:
	var a: Node2D = c.node
	var lane: float = game.fight.lanes[game.rng.randi() % game.fight.lanes.size()]
	var half: float = a.get_meta("size").x / 2.0 + 10.0 * game.unit
	var x: float = (game.fight.full.position.x + half) if c.dir > 0 else (game.fight.full.end.x - half)
	var to := Vector2(x, lane - _croc_head(a, c.dir).y)
	var t = game._fight_tween(a)     # dies with the crocodile if the fight ends first
	t.tween_property(a, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): a.position = to)
	t.tween_property(a, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		if not game.fight.is_empty() and c.s == "back":
			c.s = "crawl")


## Send the next crocodile: one of the drawn ones still waiting (the last of a wave always is), else
## a copy of one of the four (from either side when the fight has crocodiles on both sides).
func _croc_launch(speed: float) -> bool:
	var e: Dictionary = game.fight.e
	var w: Dictionary = game.fight.waves[game.fight.wave]
	if game.fight.wave_launched >= w.count:
		return false
	var order: Array = w.get("red_order", [])
	var red: bool = order[game.fight.wave_launched] if game.fight.wave_launched < order.size() else game.rng.randf() < w.get("red", 0.0)
	var waiting: Array = game.fight.crocs.filter(func(c): return c.s == "wait")
	# the last of each wave is always one of the drawn crocodiles squatting on screen (so one is
	# kept back for each wave still to end); the others go first (never red). The very last of the
	# fight is the last crocodile there: every other drawn one has come before it, and it waits
	# until the rest are gone, so once it is turned back the screen is clear.
	var last: bool = game.fight.wave_launched == int(w.count) - 1
	var final: bool = game.fight.wave == game.fight.waves.size() - 1
	var keep_back: int = game.fight.waves.size() - game.fight.wave
	if last and final and game.fight.crocs.any(func(x): return x.s == "crawl" or x.s == "back"):
		return false
	if (last or (final and int(w.count) - game.fight.wave_launched <= waiting.size())) and not waiting.is_empty():
		red = false
	var c: Dictionary
	if not waiting.is_empty() and not red and (last or waiting.size() > keep_back):
		c = waiting[game.rng.randi() % waiting.size()]
	else:
		var from: Node2D = game.actors[e.foes[game.rng.randi() % e.foes.size()]]
		var size: Vector2 = from.get_meta("size")
		var a = game._make_actor(game._picture(from).texture, Rect2(Vector2.ZERO, size))
		var dir = -1 if game.fight.both and game.rng.randf() < 0.5 else 1
		game._picture(a).flip_h = dir < 0
		var busy: Array = game.fight.crocs.filter(func(x): return x.s == "crawl" and x.dir == dir).map(func(x): return _snout(x).y)
		var free: Array = game.fight.lanes.filter(func(y): return busy.all(func(b): return absf(b - y) > CROC_LANE * game.unit * 0.9))
		if free.is_empty():
			free = game.fight.lanes.duplicate()
		var half = size.x / 2.0 + 10.0 * game.unit
		c = {"node": a, "s": "wait", "home": Vector2.ZERO, "start": Vector2.ZERO, "speed": 0.0, "dir": dir, "red": red}
		# a lane where it keeps clear of the others (on the side it came up on); none: it waits
		for i in range(free.size() - 1, 0, -1):     # (shuffled with the fight's own seed)
			var j = game.rng.randi() % (i + 1)
			var tmp = free[i]
			free[i] = free[j]
			free[j] = tmp
		var placed := false
		for lane in free:
			a.position = Vector2((game.fight.full.position.x + half) if dir > 0 else (game.fight.full.end.x - half), lane - _croc_head(a, dir).y)
			if game._instant or _croc_clear(c, speed):
				placed = true
				break
		if not placed:
			a.queue_free()
			return false
		c.home = a.position
		c.start = a.position
		a.modulate = Color(game.RED_CROC if c.red else Color.WHITE, 0.0)
		game._fight_tween(a).tween_property(a, "modulate:a", 1.0, 0.4)
		game.fight.crocs.append(c)
		game.fight.copies.append(a)
		if dir < 0 and not game.fight.told_back:
			game.fight.told_back = true
			game.say("Scribe", game._feedback_text("behind_you"))
	# never two front halves on top of each other, nor two at one spot one just after the other
	if not game._instant and not _croc_clear(c, speed):
		if c.node in game.fight.copies:              # not yet: take the new one away again
			game.fight.copies.erase(c.node)
			game.fight.crocs.erase(c)
			c.node.queue_free()
		return false
	# keep the arrivals apart, so there is always time to turn, move and strike between two
	if w.has("min_gap") and not game._instant:
		var arrive: float = game.fight.clock + absf(game.fight.pos.x - _snout(c).x) / (speed * game.unit)
		if arrive < game.fight.last_arrival + w.min_gap:
			if c.node in game.fight.copies:          # not yet: take the new one away again
				game.fight.copies.erase(c.node)
				game.fight.crocs.erase(c)
				c.node.queue_free()
			return false
		game.fight.last_arrival = arrive
	game.fight.wave_launched += 1
	c.t0 = game.fight.clock
	c.s = "crawl"
	c.speed = speed
	return true


## Would crocodile `c`, setting off now at `speed`, keep clear of those already crawling? Their front
## halves (snout to middle) may never touch on the way in (a little overlap above and below is
## allowed), and two at nearly the same height reach him CROC_SAME_SPOT s apart. One coming from
## the other side counts as if it came from this side (mirrored about the bearer), so the two sides
## are kept as far apart as one.
func _croc_clear(c: Dictionary, speed: float) -> bool:
	var t_c = absf(game.fight.pos.x - _snout(c).x) / (speed * game.unit)
	for o in game.fight.crocs:
		if o == c or o.s != "crawl":
			continue
		var t_o: float = absf(game.fight.pos.x - _snout(o).x) / (o.speed * game.unit)
		if absf(_snout(o).y - _snout(c).y) < CROC_LANE * game.unit * 1.5 and absf(t_c - t_o) < CROC_SAME_SPOT:
			return false
		var o_pos: Vector2 = o.node.position
		if o.dir != c.dir:
			o_pos.x = 2.0 * game.fight.pos.x - o_pos.x
		var t := 0.0
		while t <= minf(t_c, t_o):
			var a = _croc_front(c, c.node.position + Vector2(c.dir * speed * game.unit * t, 0.0))
			var b = _croc_front(o, o_pos + Vector2(c.dir * o.speed * game.unit * t, 0.0), c.dir)
			if a.intersects(b):
				return false
			t += 0.1
	return true


## The front half of crocodile `c` (snout to middle) with its pivot at `pos`, trimmed a little above
## and below; `dir` the way it faces (0: its own).
func _croc_front(c: Dictionary, pos: Vector2, dir: int = 0) -> Rect2:
	if dir == 0:
		dir = c.dir
	var size: Vector2 = c.node.get_meta("size")
	var trim := size.y * CROC_FRONT_OVERLAP
	return Rect2(pos.x if dir > 0 else pos.x - size.x / 2.0, pos.y - size.y + trim, size.x / 2.0, size.y - 2.0 * trim)


func _crocs_click(_p: Vector2) -> void:
	game._feedback_once("controls", game._feedback_text("controls_both" if game.fight.both else "controls"))


func autotest(e: Dictionary, expect: Callable) -> void:
	var at_tip := func(c: Dictionary) -> void:   # put a snout at the spear tip
		c.s = "crawl"
		c.node.position = game.fight.pos + game._tip_offset() - _croc_head(c.node, c.dir)
	if e.get("tutorial", false):
		game._croc_thrust()
		game.fight.thrust = -1.0
		expect.call(game.fight.tut == "ready", e.id + " lesson: a thrust, then the first crocodile")
		_crocs(0.0)
		expect.call(game.fight.tut == "first", e.id + " lesson: the first crocodile comes")
		expect.call(not game.fight.heka_on, e.id + " the heka word does not flash during the lesson")
	# a snout far from the tip is not struck
	var far: Dictionary = game.fight.crocs.filter(func(c): return c.s == "crawl" or c.s == "wait")[0]
	far.s = "crawl"
	far.node.position = game.fight.pos + game._tip_offset() - _croc_head(far.node, far.dir) + Vector2(-400.0 * game.unit, 0.0)
	_croc_strike()
	expect.call(game.fight.killed == 0, e.id + " a crocodile out of reach is not struck")
	# one that reaches the bearer bites, and his body (not the spear) flushes red
	var b0 = game.bites
	far.node.position = game.fight.pos + game._tip_offset() - _croc_head(far.node, far.dir) + Vector2(200.0 * game.unit, 0.0)
	_crocs(0.0)
	game._place_bearer()
	expect.call(game.bites == b0 + 1 and game.fight.red > 0.0, e.id + " a crocodile that reaches him bites")
	expect.call(game.actors[e.spear].modulate != Color.WHITE and game.actors[e.spear + "_pole"].modulate == Color.WHITE, e.id + " the body flushes red, the spear does not")
	far.s = "crawl"
	var total := _croc_total()
	var breaks := 0
	var guard := 0
	while game.fight.killed < total and guard < 400:
		guard += 1
		if game.fight.phase == "break":
			breaks += 1
			expect.call(game.fight.heka_on, e.id + " the heka word flashes in the break")
			game.fight.timer = 0.0
			_crocs(0.0)
			continue
		var cs: Array = game.fight.crocs.filter(func(x): return x.s == "crawl")
		if cs.is_empty():
			_croc_launch(game.fight.waves[game.fight.wave].speed)
			continue
		game.fight.health = game.CROC_HEALTH
		var c: Dictionary = cs[0]
		game.fight.facing = -c.dir      # face it
		at_tip.call(c)
		game.fight.force_heka = c.red
		_croc_strike()
	game.fight.force_heka = false
	expect.call(game.fight.killed == total, e.id + " all %d crocodiles turned back" % total)
	if game.fight.waves.size() > 1:
		expect.call(breaks == game.fight.waves.size() - 1, e.id + " a break between the waves")
		expect.call(game.fight.crocs.any(func(x): return x.red), e.id + " red crocodiles in the second wave")
	var r: Dictionary = game.fight.crocs[-1]
	game._picture(r.node).flip_h = r.dir < 0   # (turned round when it was struck)
	game.fight.facing = -r.dir
	r.red = true
	at_tip.call(r)
	_croc_strike()
	expect.call(r.s == "crawl", e.id + " a plain thrust does nothing to a red crocodile")
	r.node.position += Vector2(0.0, r.node.get_meta("size").y * 1.2)
	game.fight.force_heka = true
	_croc_strike()
	expect.call(r.s == "crawl", e.id + " only the spear point strikes (the shaft over it does not)")
	r.node.position = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit \
		- Vector2(_croc_head(r.node, r.dir).x * 0.2, -r.node.get_meta("size").y * 0.4)
	expect.call(_on_croc(r, game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit), e.id + " the point on its body, back from the snout, is on it")
	at_tip.call(r)
	_croc_strike()
	expect.call(r.s == "gone", e.id + " a thrust with heka turns a red crocodile back")
	if e.get("both_sides", false):
		expect.call(game.fight.crocs.any(func(x): return x.dir < 0), e.id + " crocodiles come from the right as well")
	# one that slips past him goes up and eats the heka word: lost
	game.fight.force_heka = false
	r.red = false
	r.s = "crawl"
	var low: float = game.actor_rect(e.spear).end.y + r.node.get_meta("size").y + 60.0 * game.unit
	if game.fight.both:      # wholly past him, tail and all (only the snout past: not yet)
		var b = game.actor_rect(e.spear)
		var half: float = r.node.get_meta("size").x / 2.0
		r.node.position = Vector2(b.end.x + 5.0 - half * 0.9 if r.dir > 0 else b.position.x - 5.0 + half * 0.9, low)
		_crocs(0.0)
		expect.call(not game.fight.lost and r.s == "crawl", e.id + " no wall: a crocodile only half past him has not got away yet")
		r.node.position = Vector2(b.end.x + half + 5.0 if r.dir > 0 else b.position.x - half - 5.0, low)
	else:
		r.node.position = Vector2(game.fight.barrier + 5.0, low) - Vector2(_croc_head(r.node, r.dir).x, 0.0)
	_crocs(0.0)
	expect.call(game.fight.lost and r.s == "thief", e.id + " a crocodile that gets past eats the heka word")
	# heka on an ordinary crocodile loses too: it makes off with the word
	game.fight.lost = false
	game.fight.force_heka = true
	game.fight.facing = -r.dir
	r.s = "crawl"
	game._picture(r.node).flip_h = r.dir < 0
	at_tip.call(r)
	_croc_strike()
	expect.call(game.fight.lost and r.s == "thief", e.id + " heka on an ordinary crocodile loses the fight")
	game.fight.force_heka = false
	# three bites and he crumbles
	game.fight.lost = false
	game.fight.tut = ""
	game.fight.health = game.CROC_HEALTH
	for i in game.CROC_HEALTH:
		r.s = "crawl"
		_croc_bites(r)
	expect.call(game.fight.lost and game.fight.health <= 0, e.id + " the third bite ends the fight")
	for w in e.waves:
		expect.call(w.get("ramp", 0.0) > 0.0 and w.speed * (1.0 + w.ramp * (w.count - 1)) > w.speed, e.id + " the crocodiles get faster")
	if game.fight.both:
		# one from the right as close behind one from the left as one from the same side
		# would be: not clear (the other side counts as this side)
		var l: Dictionary = game.fight.crocs[0]
		var rr: Dictionary = game.fight.crocs[1]
		for c in game.fight.crocs:
			c.s = "gone"
		l.s = "crawl"
		l.dir = 1
		l.speed = 300.0
		var lane: float = game.fight.lanes[0]
		l.node.position = Vector2(game.fight.pos.x - 600.0 * game.unit, lane - _croc_head(l.node, 1).y)
		rr.dir = -1
		rr.node.position = Vector2(game.fight.pos.x + 600.0 * game.unit, lane - _croc_head(rr.node, -1).y)
		expect.call(not _croc_clear(rr, 300.0), e.id + " the other side counts as this side when spacing them")
		rr.node.position.x = game.fight.pos.x + 600.0 * game.unit + 2.0 * rr.node.get_meta("size").x
		expect.call(_croc_clear(rr, 300.0), e.id + " ...and one well behind is clear")
	# the last of a wave is one of the drawn crocodiles squatting on screen; before it, the
	# last one squatting is kept back for it
	game._crocs_cleanup()
	for n in game._box_actors(e):
		game._restore(n)
	game.fight = {}
	game.start_fight(e)
	expect.call(game.fight.wave == 0 and game.fight.killed == 0, e.id + " a fight taken up again starts from the first wave")
	game.fight.tut = ""
	game.fight.wave = game.fight.waves.size() - 1
	var lw: Dictionary = game.fight.waves[game.fight.wave]
	var squat: Array = game.fight.crocs.filter(func(x): return x.s == "wait")
	for i in range(1, squat.size()):
		squat[i].s = "gone"
	game.fight.wave_launched = 0
	_croc_launch(lw.speed)
	expect.call(squat[0].s == "wait", e.id + " the last drawn crocodile waits while others come")
	game.fight.wave_launched = int(lw.count) - 1
	_croc_launch(lw.speed)
	expect.call(squat[0].s == "wait", e.id + " the last of the fight waits until the others are gone")
	for c in game.fight.crocs:
		if c != squat[0]:
			c.s = "gone"
	_croc_launch(lw.speed)
	expect.call(squat[0].s == "crawl" and not squat[0].red, e.id + " the last of the fight is the drawn one squatting")
	# with as many drawn ones squatting as crocodiles still to come, they all come
	for c in game.fight.crocs:
		c.s = "gone"
	for c in squat:
		c.s = "wait"
	game.fight.wave_launched = int(lw.count) - squat.size()
	for i in squat.size():
		for c in game.fight.crocs:
			if c.s == "crawl":
				c.s = "gone"
		_croc_launch(lw.speed)
	expect.call(squat.all(func(c): return c.s == "crawl" or c.s == "gone"), e.id + " every drawn crocodile has come by the end of the fight")
