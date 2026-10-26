## Lunging snake encounter behavior and acceptance checks.
extends RefCounted

var game
var _filled := {}        ## bearer -> his poses filled with papyrus (spell 33), made once


func _init(level) -> void:
	game = level




# the lunging snake (spell 33). The vignette opens out as for the crocodiles; the bearer stays where
# he is drawn, his spear raised, and cannot move. The snake coils a little way off, out of reach,
# breathing (a faint squash up and down). Its tail waves: the warning. It squashes down, then
# springs, a fast snap: on the way it passes the very spot where it is drawn, and a thrust (Space)
# there brings the spear point down on the red mark on its body. At the end of the snap its head is
# at his front leg (its body behind his skirt): bitten. Too early and the spear is already coming
# back up when it springs; too late and it is past. Struck `need` times, it is overcome; bitten
# CROC_HEALTH times, he crumbles and the fight starts over.
const SNAKE_MARK := 7.0         ## radius of the red mark on its body (plate px), when `marks` does not say
const SNAKE_MARK_OFFSET := Vector2i(0, -3)  ## shift the patch and strike-zone centre in image pixels
const SNAKE_GRACE := 3.0        ## the spear point counts this close outside the mark (plate px)
const SNAKE_PAD := 40           ## room around the snake's picture for the tail to wave into (px)
const SNAKE_FIGURE := preload("res://scripts/figure.gdshader")
const SNAKE_TAIL := preload("res://scripts/dangers/snake_tail.gdshader")


func _lunge_start(e: Dictionary) -> void:
	# close up: from the caption banner to just under the ground, centred between him and the snake
	var mid_x: float = (game.actors[e.spear].get_meta("home").x + game.actors[e.foe].get_meta("home").x) / 2.0 - float(e.rest) * game.unit
	game._arena_setup(e, false, [e.foe], {"y1": game.ground + 24.0 * game.unit, "x": mid_x})
	# he stays exactly where he is drawn: that is where the spear meets the mark
	var bearer: Node2D = game.actors[e.spear]
	game.fight.stand = bearer.get_meta("home")
	game.fight.pos = game.fight.stand
	game.fight.health = game.CROC_HEALTH
	game.fight.clock = 0.0
	game.fight.pinned = false
	game.fight.last_thrust = -INF
	_lunge_dress(e)
	var a: Node2D = game.actors[e.foe]
	var size: Vector2 = a.get_meta("size")
	var home: Vector2 = a.get_meta("home")
	# where the spear point comes down (at the full thrust) with the snake where it is drawn: the
	# nearest bit of its body there is the mark
	var point: Vector2 = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit
	var mark: Vector2 = game.fight.snake_mark
	# the snap: from its resting place to its head at his front leg
	var head_x: float = home.x - size.x / 2.0 + float(e.head_tip[0])
	var leg_x: float = _front_leg_x(bearer, home.y - size.y + float(e.head_tip[1]))
	game.fight.snake = {"node": a, "phase": "idle", "t": 0.0, "idle_for": 1.6, "off": -float(e.rest) * game.unit,
		"rest": -float(e.rest) * game.unit, "lunge": leg_x - head_x, "sx": 1.0, "sy": 1.0, "amp": 0.0}
	if point.distance_to(home + mark) > 30.0 * game.unit:
		push_warning("spell 33: the spear point lands %.0f px from the snake's body" % point.distance_to(home + mark))
	_lunge_place()
	game._arena_open()


## The leftmost ink of the bearer's body at height `y` (strip px): his front leg.
func _front_leg_x(bearer: Node2D, y: float) -> float:
	var img: Image = game.fight.bearer_plain.get_image()
	var top_left: Vector2 = bearer.get_meta("home") + game.fight.bearer_at
	var row := clampi(int(y - top_left.y), 0, img.get_height() - 1)
	for x in img.get_width():
		if img.get_pixel(x, row).a > 0.35:
			return top_left.x + x + 2.0
	return top_left.x


## For this fight only: the bearer is filled with papyrus (the snake's body passes behind his
## skirt), the snake gets room for its tail to wave, the red mark, and its head drawn in front of him.
func _lunge_dress(e: Dictionary) -> void:
	var bs: Sprite2D = game._picture(game.actors[e.spear])
	game.fight.bearer_plain = bs.texture
	game.fight.bearer_at = bs.offset
	if not _filled.has(e.spear):          # each pose of his, filled (the spear's ends move)
		var frames := []
		for i in game.sheet.poses.size():
			frames.append(game.FIGURE_MASK.create_texture(game._sheet_frame(e.spear, i, false), 2))
		_filled[e.spear] = frames
	bs.set_meta("filled", _filled[e.spear])
	bs.offset -= Vector2(2, 2)
	game._bearer_pose(e.spear, game._spear_out())
	var fm := ShaderMaterial.new()
	fm.shader = SNAKE_FIGURE
	bs.material = fm
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	game.fight.snake_plain = sp.texture
	game.fight.snake_at = sp.offset
	var src := sp.texture.get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var P := SNAKE_PAD
	var img := Image.create(w + 2 * P, h + P, false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(0, 0, w, h), Vector2i(P, P))
	# the mark: where the spear point lands with the snake as drawn, on the nearest bit of body
	var home: Vector2 = a.get_meta("home")
	var point: Vector2 = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit
	var q := point - (home + sp.offset)            # in the picture's pixels
	var best := Vector2i(int(q.x), int(q.y))
	var best_d := INF
	for y in range(maxi(0, int(q.y) - 40), mini(h, int(q.y) + 41)):
		for x in range(maxi(0, int(q.x) - 40), mini(w, int(q.x) + 41)):
			if src.get_pixel(x, y).a > 0.35:
				var d := Vector2(x, y).distance_squared_to(q)
				if d < best_d:
					best_d = d
					best = Vector2i(x, y)
	best += SNAKE_MARK_OFFSET
	game.fight.snake_mark = Vector2(best) + sp.offset             # from its pivot
	game.fight.snake_img = img                                      # unmarked: the mark is painted per strike
	game.fight.snake_mark_px = best + Vector2i(P, P)
	sp.texture = ImageTexture.create_from_image(img)
	game.fight.snake_tex = sp.texture
	_lunge_mark()
	sp.offset -= Vector2(P, P)
	var mat := ShaderMaterial.new()
	mat.shader = SNAKE_TAIL
	var base: Array = e.tail_base
	mat.set_shader_parameter("base", Vector2(float(base[0]) + P, float(base[1]) + P))
	mat.set_shader_parameter("tail_height", float(base[1]))
	sp.material = mat
	# its head, again, in front of him (the rest of it is behind his skirt)
	var hr: Array = e.head_rect
	var head := Sprite2D.new()
	head.name = "Head"
	head.texture = sp.texture
	head.centered = false
	head.region_enabled = true
	head.region_rect = Rect2(float(hr[0]) + P, float(hr[1]) + P, float(hr[2]), float(hr[3]))
	head.position = game.fight.snake_at + Vector2(float(hr[0]), float(hr[1]))
	head.z_index = 1
	a.add_child(head)


## The red mark's radius now (plate px): smaller with every strike (`marks`).
func _lunge_mark_r() -> float:
	var marks: Array = game.fight.e.get("marks", [SNAKE_MARK])
	return float(marks[mini(game.fight.hits, marks.size() - 1)])


## The red patch fills the body beneath its original ink outline.
static func _paint_mark(img: Image, c: Vector2i, r: float) -> void:
	var red := UI.DANGER
	var k := 4                                       # closes the gap between the two outlines
	var R := int(ceil(r)) + k + 1
	var x0 := maxi(0, c.x - R)
	var y0 := maxi(0, c.y - R)
	var x1 := mini(img.get_width(), c.x + R + 1)
	var y1 := mini(img.get_height(), c.y + R + 1)
	var w := x1 - x0
	var h := y1 - y0
	var ink := PackedByteArray()
	ink.resize(w * h)
	for y in h:
		for x in w:
			ink[y * w + x] = 1 if img.get_pixel(x0 + x, y0 + y).a > 0.25 else 0
	var grown := PackedByteArray()
	grown.resize(w * h)
	for y in h:
		for x in w:
			if ink[y * w + x]:
				for dy in range(-k, k + 1):
					for dx in range(-k, k + 1):
						var xx := x + dx
						var yy := y + dy
						if xx >= 0 and yy >= 0 and xx < w and yy < h and dx * dx + dy * dy <= k * k:
							grown[yy * w + xx] = 1
	for y in h:
		for x in w:
			if Vector2(x0 + x, y0 + y).distance_to(Vector2(c)) > r or not grown[y * w + x]:
				continue
			var keep := true                         # eroded back: inside the closed shape
			for dy in range(-k, k + 1):
				for dx in range(-k, k + 1):
					var xx := x + dx
					var yy := y + dy
					if dx * dx + dy * dy <= k * k and (xx < 0 or yy < 0 or xx >= w or yy >= h or not grown[yy * w + xx]):
						keep = false
			if keep:
				img.set_pixel(x0 + x, y0 + y, red.blend(img.get_pixel(x0 + x, y0 + y)))


## Paint the red mark onto the snake at its present size (its head shares the texture).
func _lunge_mark() -> void:
	var img: Image = game.fight.snake_img.duplicate()
	_paint_mark(img, game.fight.snake_mark_px, _lunge_mark_r() * game.unit)
	(game.fight.snake_tex as ImageTexture).update(img)


## Undo _lunge_dress.
func _lunge_undress() -> void:
	var e: Dictionary = game.fight.e
	if game.fight.has("bearer_plain"):
		var bs: Sprite2D = game._picture(game.actors[e.spear])
		bs.remove_meta("filled")
		bs.texture = game.fight.bearer_plain
		bs.offset = game.fight.bearer_at
		bs.material = null
		game._bearer_pose(e.spear, 0.0)
	if game.fight.has("snake_plain"):
		var a: Node2D = game.actors[e.foe]
		var sp: Sprite2D = game._picture(a)
		sp.texture = game.fight.snake_plain
		sp.offset = game.fight.snake_at
		sp.material = null
		if a.has_node("Head"):
			var head := a.get_node("Head")
			a.remove_child(head)
			head.queue_free()


## Put the snake where it is (its offset from where it is drawn, its squash, its tail).
func _lunge_place() -> void:
	var sn: Dictionary = game.fight.snake
	var a: Node2D = sn.node
	var home: Vector2 = a.get_meta("home")
	a.position = home + Vector2(sn.off * game.fight.open, 0.0)
	a.scale = Vector2(sn.sx, sn.sy)
	var mat = game._picture(a).material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("amp", sn.amp)
		mat.set_shader_parameter("phase", game.fight.clock * TAU * float(game.fight.e.wave_hz))


func _lunge(dt: float) -> void:
	var e: Dictionary = game.fight.e
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	game.fight.clock += dt
	if game.fight.get("bot", false):
		_lunge_bot()
	if game.fight.thrust >= 0.0 and not game.fight.pinned:
		game.fight.thrust += dt
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
	game.fight.red = maxf(0.0, game.fight.red - dt)
	var sn: Dictionary = game.fight.snake
	sn.t += dt
	var breathe = 1.0 + 0.018 * sin(game.fight.clock * TAU / 1.6)
	match sn.phase:
		"idle":
			sn.off = sn.rest
			sn.sx = 2.0 - breathe
			sn.sy = breathe
			sn.amp = 0.0
			if sn.t >= sn.idle_for:
				_lunge_phase("wave")
		"wave":            # the warning
			var u: float = sn.t / float(e.wave)
			sn.sx = 2.0 - breathe
			sn.sy = breathe
			sn.amp = float(e.tail) * sin(PI * minf(u, 1.0))
			if u >= 1.0:
				sn.amp = 0.0
				_lunge_phase("crouch")
		"crouch":          # it squashes down
			var u := minf(sn.t / float(e.crouch), 1.0)
			var k := u * u * (3.0 - 2.0 * u)
			sn.sx = 1.0 + 0.10 * k
			sn.sy = 1.0 - 0.18 * k
			if sn.t >= float(e.crouch) + 0.1:
				_lunge_phase("snap")
		"snap":            # and springs
			var u := minf(sn.t / float(e.snap), 1.0)
			sn.off = sn.rest + (sn.lunge - sn.rest) * (1.0 - (1.0 - u) * (1.0 - u))
			sn.sx = 1.10 + 0.06 * u
			sn.sy = 0.82 + 0.12 * u
			if _lunge_on_mark():
				_lunge_caught()
			elif u >= 1.0:
				_lunge_bites()
		"bitten":          # its head at his leg a moment
			if sn.t >= 0.4:
				_lunge_phase("back")
		"back", "slink":   # back to where it waits
			var u := minf(sn.t / 0.5, 1.0)
			var k := u * u * (3.0 - 2.0 * u)
			sn.off = sn.get("from", sn.lunge) + (sn.rest - sn.get("from", sn.lunge)) * k
			sn.sx = lerpf(sn.get("sx0", 1.16), 1.0, k)
			sn.sy = lerpf(sn.get("sy0", 0.94), 1.0, k)
			if u >= 1.0:
				_lunge_phase("idle")
				sn.idle_for = game.rng.randf_range(float(e.idle[0]), float(e.idle[1]))
		"pinned":          # held on the spear point, wriggling
			sn.sx = 1.0 + 0.04 * sin(game.fight.clock * 40.0)
			sn.sy = 1.0 - 0.04 * sin(game.fight.clock * 40.0)
			if sn.t >= game.ROACH_FREEZE:
				game.fight.pinned = false
				game.fight.thrust = game.THRUST_TIME[0] + 0.001          # the spear draws back up
				if game.fight.hits >= int(e.need):
					game.end_fight()
					return
				sn.from = sn.off
				sn.sx0 = 1.0
				sn.sy0 = 1.0
				_lunge_phase("slink")
	_lunge_place()
	game._place_bearer()


func _lunge_phase(p: String) -> void:
	game.fight.snake.phase = p
	game.fight.snake.t = 0.0


## Is the spear point, at or past where it is drawn, on the red mark?
func _lunge_on_mark() -> bool:
	var o = game._spear_out()
	if o < 0.0:
		return false
	var sn: Dictionary = game.fight.snake
	var point: Vector2 = game.fight.pos + game._tip_offset() + game._spear_dir() * o * game.unit
	var mark: Vector2 = sn.node.position + game.fight.snake_mark * Vector2(sn.sx, sn.sy)
	return point.distance_to(mark) <= (_lunge_mark_r() + SNAKE_GRACE) * game.unit


func _lunge_caught() -> void:
	var e: Dictionary = game.fight.e
	game.fight.hits += 1
	game.fight.pinned = true
	game._hurt(game.fight.snake.node)
	if game.fight.hits < int(e.need):
		_lunge_mark()                 # a smaller mark for the next strike
	_lunge_phase("pinned")
	game._dev_shot("SHOT_ON_CATCH")


func _lunge_bites() -> void:
	var e: Dictionary = game.fight.e
	var sn: Dictionary = game.fight.snake
	sn.off = sn.lunge
	sn.from = sn.lunge
	sn.sx0 = sn.sx
	sn.sy0 = sn.sy
	_lunge_phase("bitten")
	game._dev_shot("SHOT_ON_BITE")
	game.fight.red = 0.8
	game.fight.health -= 1
	game.bites += 1
	game._damage_shake()
	if game.fight.health <= 0:
		_lunge_dies()
		return
	# why it got through: a thrust that came and went before it sprang, or one that came too late
	var since: float = game.fight.clock - game.fight.last_thrust
	if since < float(e.snap) + 0.6 and since > float(e.snap):
		game._feedback_once("Too early", game._feedback_text("too_early"))
	elif since <= float(e.snap):
		game._feedback_once("Too late", game._feedback_text("too_late"))
	else:
		game._feedback_once("Watch its tail", game._feedback_text("bite_advice"))


## The last bite: he crumbles away, and he is back on the scroll.
func _lunge_dies() -> void:
	game.fight.lost = true
	var e: Dictionary = game.fight.e
	game.say("Scribe", game._hints.message("dangers.defeated"))
	_lunge_undress()
	game._disintegrate(e)
	var t = game._fight_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "lunge" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))


## (autotest) From the squash, press Space at `tau` s from the start of the snap; true = struck.
func _lunge_try(tau: float) -> bool:
	var e: Dictionary = game.fight.e
	var sn: Dictionary = game.fight.snake
	var hits: int = game.fight.hits
	game.fight.thrust = -1.0
	game.fight.pinned = false
	_lunge_phase("crouch")
	var dt := 1.0 / 240.0
	var t := -(float(e.crouch) + 0.1)
	var pressed := false
	while t < float(e.snap) + 0.4:
		if not pressed and t >= tau:
			pressed = true
			game._croc_thrust()
		_lunge(dt)
		t += dt
		if game.fight.hits > hits or sn.phase == "bitten" or game.fight.lost:
			break
	return game.fight.hits > hits


## (autotest) The span of press times (from the start of the snap) that strike; leaves no hit counted.
func _lunge_window() -> Array:
	var lo := INF
	var hi := -INF
	var tau := -0.4
	while tau <= 0.3:
		game.fight.health = 99
		var hits: int = game.fight.hits
		if _lunge_try(tau):
			lo = minf(lo, tau)
			hi = maxf(hi, tau)
		game.fight.hits = hits
		game.fight.pinned = false
		tau += 0.005
	game.fight.health = game.CROC_HEALTH
	return [lo, hi]


func _lunge_click(_p: Vector2) -> void:
	game._feedback_once("controls", game._feedback_text("controls"))


## Dev (`--croc-bot`): thrusts LUNGE_BOT_AIM s after the snap begins, give or take BOT_JITTER s.
func _lunge_bot() -> void:
	var sn: Dictionary = game.fight.snake
	if OS.has_environment("BOT_MISS"):      # dev: never thrusts (to see the bite)
		return
	if sn.phase == "crouch" and not game.fight.has("bot_at"):
		var jitter: float = float(OS.get_environment("BOT_JITTER")) if OS.has_environment("BOT_JITTER") else 0.03
		game.fight.bot_at = game.fight.clock + float(game.fight.e.crouch) + 0.1 + LUNGE_BOT_AIM + game.rng.randf_range(-jitter, jitter)
	if game.fight.has("bot_at") and game.fight.clock >= game.fight.bot_at:
		game.fight.erase("bot_at")
		game._croc_thrust()

const LUNGE_BOT_AIM := -0.01    ## the middle of the window the autotest measures (s from the snap)


func autotest(e: Dictionary, expect: Callable) -> void:
	var source: Image = game.fight.snake_img
	for radius in e.marks:
		var marked: Image = source.duplicate()
		_paint_mark(marked, game.fight.snake_mark_px, float(radius) * game.unit)
		var outline_kept := true
		var fill_added := false
		for y in source.get_height():
			for x in source.get_width():
				var original := source.get_pixel(x, y)
				var painted := marked.get_pixel(x, y)
				if original.a == 1.0:
					outline_kept = outline_kept and painted == original
				elif original.a == 0.0 and painted.a > 0.0:
					fill_added = true
		expect.call(outline_kept and fill_added, e.id + " red patch fills behind the original outline at radius %.0f" % radius)
	var sn: Dictionary = game.fight.snake
	game.fight.thrust = game.THRUST_TIME[0]
	expect.call(not _lunge_on_mark(), e.id + " the coiled snake is out of the spear's reach")
	game.fight.thrust = -1.0
	# the window: press Space at `tau` s from the start of the snap (sim at 240 fps)
	var good: Array = _lunge_window()
	print("spell 33 window: %.3f .. %.3f s from the start of the snap (%.0f ms)" % [good[0], good[1], (good[1] - good[0]) * 1000.0])
	expect.call(good[1] - good[0] >= 0.06, e.id + " a window of at least 60 ms to strike in")
	expect.call(not _lunge_try(-0.3), e.id + " a thrust well before it springs is too early (bitten)")
	expect.call(not _lunge_try(0.25), e.id + " a thrust after it is past is too late (bitten)")
	expect.call(sn.off > 0.0 and sn.phase == "bitten", e.id + " at full lunge its head is past the drawn spot, at his leg")
	for i in int(e.need) - 1:
		game.fight.health = game.CROC_HEALTH
		expect.call(_lunge_try((good[0] + good[1]) / 2.0), e.id + " struck in the middle of the window (%d)" % (i + 1))
		_lunge(game.ROACH_FREEZE + 0.01)
	expect.call(game.fight.hits == int(e.need) - 1 and game.fight.is_empty() == false, e.id + " each strike counts; it coils again")
	var last: Array = _lunge_window()
	print("spell 33 last window: %.0f ms" % ((last[1] - last[0]) * 1000.0))
	expect.call(_lunge_mark_r() < float(e.marks[0]) and last[1] - last[0] < good[1] - good[0], e.id + " the mark (and the moment to strike) grows smaller each strike")
	expect.call(last[1] - last[0] >= 0.03, e.id + " the last mark can still be struck")
	game.fight.health = 1
	_lunge_try(-0.3)
	expect.call(game.fight.lost, e.id + " the third bite and he crumbles")
	game.fight.lost = false
