## Snakes on the ground (spell 35) behavior and acceptance checks.
extends RefCounted

var game


func _init(level) -> void:
	game = level
	turn = JSON.parse_string(FileAccess.get_file_as_string(TURN_PATH))
	strike = JSON.parse_string(FileAccess.get_file_as_string(STRIKE_PATH))


# the snakes on the ground (spell 35), fought like the crocodiles of spell 32: the vignette opens out
# across the screen and he stands in the middle; ← → turn him, ↑ ↓ move him, Space thrusts. The drawn
# snake comes alive (creeping, its head raised: the first frame of TURN) and moves off to rest a way
# from him; more slither in from the edges and stop (never more than `at_once` resting, and never more
# than are still to be speared). One at a time, a resting snake shakes its tail (the only warning) and
# darts at him along its row. The spear point anywhere on a snake spears it: everything stops, its head
# is pinned under the point, and frame for frame it turns its head back and lies as drawn (TURN) while
# he presses the spear on down (STRIKE); it lies so a moment, and is gone. A snake that touches any part
# of him bites, then slinks back
# to rest somewhere else; one that misses him (he is off its row) slips past, turns and rests on the
# far side (those no longer count toward `at_once`). Bitten CROC_HEALTH times: snakes come in from
# everywhere, bite him all over, and he crumbles.
const SNAKE_PAD := 16           ## room around the picture for the tail to shake into (px)
const SNAKE_GAP := 20.0         ## resting snakes keep at least this far apart (plate px)
const SWARM_ANGLE := 15.0       ## the losing swarm comes in at most this steeply (degrees)
const SWARM_ROW := 14.0         ## ...one snake on each side for every this much of his height (plate px)
const SNAKE_TAIL := preload("res://scripts/dangers/snake_tail.gdshader")
const TURN := preload("res://assets/dangers/animation/snake35_turn_over.png")    ## creeping, then pinned (tools/snake35_turn_over.py)
const TURN_PATH := "res://assets/dangers/animation/snake35_turn_over.json"
const STRIKE := preload("res://assets/dangers/animation/spear35_strike.png")     ## the bearer pinning it (tools/spearer35_strike.py)
const STRIKE_PATH := "res://assets/dangers/animation/spear35_strike.json"
const PIN_FRAME := 0.08         ## each frame of the pinning (s)
const PIN_HOLD := 0.35          ## then it lies pinned as drawn this long (s)
const PIN_FADE := 0.4           ## and fades (s)

var turn: Dictionary     ## snake35_turn_over.json: the cell, the head's place in each frame, the creeping frame's box and points
var strike: Dictionary   ## spear35_strike.json: the cell, and `along`: where the snake lies to be pinned (strip px)

var _ink := {}           ## texture -> its inked pixels, every third (for touching him)
var _sheets := {}        ## the bearer's sheet texture -> its Image


func _creep_start(e: Dictionary) -> void:
	game._arena_setup(e, true, [e.foe])
	game.fight.health = game.CROC_HEALTH
	game.fight.clock = 0.0
	game.fight.copies = []
	game.fight.timer = float(e.first)            # until the first tail shakes
	game.fight.enter_timer = 0.0
	_creep_dress(e)
	var a: Node2D = game.actors[e.foe]
	var size: Vector2 = a.get_meta("size")
	var full: Rect2 = game.fight.full
	# the heights the snakes come at (their heads lead): wherever the spear point reaches at the
	# full thrust, with the whole snake inside the frame
	var front_y: float = _front(a, 1).y
	var point_y: float = game.fight.tip.y + game._spear_dir().y * game.CROC_THRUST * game.unit
	var lo: float = maxf(game.fight.y_range.x + point_y, full.position.y + size.y + front_y)
	var hi: float = minf(game.fight.y_range.y + point_y, full.end.y - 26.0 * game.unit + front_y)
	game.fight.lanes = []
	var n = maxi(3, int((hi - lo) / (game.CROCODILES.CROC_LANE * game.unit)) + 1)
	for i in n:
		game.fight.lanes.append(lerpf(lo, hi, float(i) / (n - 1)))
	# the drawn snake turns to face him and moves off to rest a way from him
	var c := {"node": a, "s": "wait", "dir": 1 if a.get_meta("home").x < game.fight.stand.x else -1,
		"slipped": false, "t": 0.0, "home": a.get_meta("home")}
	game._picture(a).flip_h = c.dir < 0
	c.at = _rest_spot(c)
	c.start = c.at
	game.fight.crocs = [c]
	game._arena_open()


## For this fight only: the snake creeps (TURN's first frame, facing right), with room for its tail to
## shake, and the tail shader.
func _creep_dress(e: Dictionary) -> void:
	var a: Node2D = game.actors[e.foe]
	var sp: Sprite2D = game._picture(a)
	game.fight.snake_plain = sp.texture
	game.fight.snake_at = sp.offset
	game.fight.snake_size = a.get_meta("size")
	var box: Array = turn.creep.box
	var sheet_img := TURN.get_image()
	if sheet_img.is_compressed():
		sheet_img.decompress()
	sheet_img.convert(Image.FORMAT_RGBA8)
	var src := sheet_img.get_region(Rect2i(int(box[0]), int(box[1]), int(box[2]), int(box[3])))
	game.fight.creep_tex = ImageTexture.create_from_image(src)
	a.set_meta("size", Vector2(src.get_size()))
	sp.offset = -Vector2(src.get_width() / 2.0, src.get_height())
	var P := SNAKE_PAD
	var img := Image.create(src.get_width() + 2 * P, src.get_height() + 2 * P, false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(P, P))
	game.fight.snake_tex = ImageTexture.create_from_image(img)
	_wear(sp)


## A snake's picture (the drawn one, or a copy) in the padded texture, with its own tail shader.
func _wear(sp: Sprite2D) -> void:
	var P := Vector2(SNAKE_PAD, SNAKE_PAD)
	sp.texture = game.fight.snake_tex
	sp.offset -= P
	var base := Vector2(float(turn.creep.tail_base[0]), float(turn.creep.tail_base[1]))
	var tail := Vector2(float(turn.creep.tail_tip[0]), float(turn.creep.tail_tip[1])) - base
	var mat := ShaderMaterial.new()
	mat.shader = SNAKE_TAIL
	mat.set_shader_parameter("base", base + P)
	mat.set_shader_parameter("axis", tail.normalized())
	mat.set_shader_parameter("tail_height", tail.length())
	sp.material = mat


## Undo _creep_dress (and a pinning cut short).
func _creep_undress() -> void:
	if not game.fight.has("snake_plain"):
		return
	var a: Node2D = game.actors[game.fight.e.foe]
	var sp: Sprite2D = game._picture(a)
	sp.texture = game.fight.snake_plain
	sp.offset = game.fight.snake_at
	sp.material = null
	a.set_meta("size", game.fight.snake_size)
	(game._picture(game.actors[game.fight.e.spear]).texture as AtlasTexture).atlas = game._sheet_tex
	game.fight.erase("pin")


## Its front (the raised head's tip, leading as it comes), from its pivot; `dir` 1 = it faces right
## (as it creeps, unflipped), -1 = left.
func _front(a: Node2D, dir: int) -> Vector2:
	var size: Vector2 = a.get_meta("size")
	var tip: Array = turn.creep.front
	return Vector2((float(tip[0]) - size.x / 2.0) * dir, float(tip[1]) - size.y)


func _rect_at(c: Dictionary, p: Vector2) -> Rect2:
	var size: Vector2 = c.node.get_meta("size")
	return Rect2(p.x - size.x / 2.0, p.y - size.y, size.x, size.y)


## Somewhere to rest on its side of him: `rest` from him, at one of the heights, clear of the others
## (if there is room; `c.clear` says).
func _rest_spot(c: Dictionary) -> Vector2:
	var e: Dictionary = game.fight.e
	var a: Node2D = c.node
	var half: float = a.get_meta("size").x / 2.0
	var full: Rect2 = game.fight.full
	var spot := Vector2.ZERO
	for i in 20:
		var lane: float = game.fight.lanes[game.rng.randi() % game.fight.lanes.size()]
		var gap: float = game.rng.randf_range(float(e.rest[0]), float(e.rest[1])) * game.unit + half
		var x := clampf(game.fight.pos.x - c.dir * gap, full.position.x + half, full.end.x - half)
		spot = Vector2(x, lane - _front(a, c.dir).y)
		var r := _rect_at(c, spot).grow(SNAKE_GAP * game.unit)
		c.clear = _snakes().all(func(o): return o == c or o.s == "gone" or not r.intersects(_rect_at(o, o.at)))
		if c.clear:
			break
	return spot


func _snakes() -> Array:
	return game.fight.get("crocs", [])


func _creep(dt: float) -> void:
	var e: Dictionary = game.fight.e
	if game.fight.open < 1.0 or game.fight.get("closing", false) or game.fight.lost:
		return
	game.fight.clock += dt
	if game.fight.has("pin"):          # a snake is being pinned: everything waits
		_pin(dt)
		return
	game.crocodiles._move_bearer(_bot_move() if game.fight.get("bot", false) else game.crocodiles._keys(), dt)
	if game.fight.thrust >= 0.0:
		game.fight.thrust += dt
		if not game.fight.struck and game.fight.thrust >= game.THRUST_TIME[0]:
			game.fight.struck = true
			_creep_strike()
			if game.fight.has("pin"):    # it is pinned: he is shown pinning it from now on
				return
		if game.fight.thrust >= game.THRUST_TIME[0] + game.THRUST_TIME[1]:
			game.fight.thrust = -1.0
	game.fight.red = maxf(0.0, game.fight.red - dt)
	game._place_bearer()
	if game.fight.lost or game.fight.is_empty():
		return
	for c in _snakes():
		if c.s == "wait":
			c.s = "rest"
	# more slither in, one at a time
	game.fight.enter_timer -= dt
	var resting: int = _snakes().filter(func(c): return c.s != "gone" and not c.slipped).size()
	var alive: int = _snakes().filter(func(c): return c.s != "gone").size()
	if game.fight.enter_timer <= 0.0 and resting < int(e.at_once) and alive < int(e.need) - game.fight.hits:
		_enter()
		game.fight.enter_timer = float(e.enter_gap)
	# one at a time: a resting snake shakes its tail
	if not _snakes().any(func(c): return c.s in ["shake", "dart"]):
		game.fight.timer -= dt
		var idle: Array = _snakes().filter(func(c): return c.s == "rest")
		if game.fight.timer <= 0.0 and not idle.is_empty():
			var c: Dictionary = idle[game.rng.randi() % idle.size()]
			c.s = "shake"
			c.t = 0.0
	for c in _snakes():
		c.t += dt
		var a: Node2D = c.node
		var amp := 0.0
		match c.s:
			"enter", "slip":           # slithering to where it will rest
				var speed: float = float(e.slither if c.s == "enter" else e.speed) * game.unit
				a.position.x += c.dir * speed * dt
				a.rotation = sin(game._time * 14.0 + a.position.y) * 0.012
				if (c.at.x - a.position.x) * c.dir <= 0.0:
					a.position.x = c.at.x
					a.rotation = 0.0
					if c.s == "slip":    # it turns round to face him again
						c.dir = -c.dir
						game._picture(a).flip_h = c.dir < 0
					c.s = "rest"
			"shake":                   # the warning
				var u: float = c.t / float(e.shake)
				amp = float(e.tail) * sin(PI * minf(u, 1.0))
				if u >= 1.0:
					c.s = "dart"
					c.t = 0.0
			"dart":
				a.position.x += c.dir * float(e.speed) * game.unit * dt
				a.rotation = sin(game._time * 14.0 + a.position.y) * 0.012
				if _touches(c):
					_creep_bites(c)
					if game.fight.lost:
						return
				elif _past(c):
					_slips(c)
		var mat := game._picture(a).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("amp", amp)
			mat.set_shader_parameter("phase", game.fight.clock * TAU * float(e.wave_hz))


## A new snake slithers in from the edge on one side, to rest there.
func _enter() -> void:
	var src: Node2D = game.actors[game.fight.e.foe]
	var size: Vector2 = src.get_meta("size")
	var a = game._make_actor(game.fight.creep_tex, Rect2(Vector2.ZERO, size))
	_wear(a)
	var c := {"node": a, "s": "enter", "dir": 1 if game.rng.randf() < 0.5 else -1, "slipped": false, "t": 0.0}
	c.at = _rest_spot(c)
	if not c.clear:                  # no room on that side: the other
		c.dir = -c.dir
		c.at = _rest_spot(c)
	game._picture(a).flip_h = c.dir < 0
	var full: Rect2 = game.fight.full
	a.position = Vector2((full.position.x - size.x / 2.0) if c.dir > 0 else (full.end.x + size.x / 2.0), c.at.y)
	game.fight.crocs.append(c)
	game.fight.copies.append(a)


## An attack is over (speared, bitten or slipped past): the next tail shakes `next` s from now.
func _attack_over() -> void:
	var next: Array = game.fight.e.next
	game.fight.timer = game.rng.randf_range(float(next[0]), float(next[1]))


## Has it gone wholly past him, tail and all?
func _past(c: Dictionary) -> bool:
	var b: Rect2 = game.actor_rect(game.fight.e.spear)
	var half: float = c.node.get_meta("size").x / 2.0
	return c.node.position.x - half >= b.end.x if c.dir > 0 else c.node.position.x + half <= b.position.x


## Does its drawing touch his (any part of him: his inked pixels, as he stands now)?
func _touches(c: Dictionary) -> bool:
	var bearer: Node2D = game.actors[game.fight.e.spear]
	if not _rect_at(c, c.node.position).intersects(game.actor_rect(game.fight.e.spear)):
		return false
	var bs: Sprite2D = game._picture(bearer)
	var atlas := bs.texture as AtlasTexture
	if not _sheets.has(atlas.atlas):
		var img := atlas.atlas.get_image()
		if img.is_compressed():
			img.decompress()
		_sheets[atlas.atlas] = img
	var sheet: Image = _sheets[atlas.atlas]
	var region := Rect2i(atlas.region)
	var sp: Sprite2D = game._picture(c.node)
	var w := sp.texture.get_width()
	var to_him := bs.get_global_transform().affine_inverse() * sp.get_global_transform()
	for p in _ink_of(sp.texture):
		var q: Vector2 = to_him * (sp.offset + Vector2(w - 1 - p.x if sp.flip_h else p.x, p.y)) - bs.offset
		var x := int(q.x)
		if bs.flip_h:
			x = region.size.x - 1 - x
		var y := int(q.y)
		if x >= 0 and y >= 0 and x < region.size.x and y < region.size.y and sheet.get_pixel(region.position.x + x, region.position.y + y).a > 0.5:
			return true
	return false


func _ink_of(tex: Texture2D) -> Array:
	if not _ink.has(tex):
		var img := tex.get_image()
		var pts := []
		for y in range(0, img.get_height(), 3):
			for x in range(0, img.get_width(), 3):
				if img.get_pixel(x, y).a > 0.5:
					pts.append(Vector2(x, y))
		_ink[tex] = pts
	return _ink[tex]


## A thrust at its furthest: the point, anywhere along its last stroke, on a snake spears it.
func _creep_strike() -> void:
	var tip0: Vector2 = game.fight.pos + game._tip_offset()
	var tip: Vector2 = tip0 + game._spear_dir() * game.CROC_THRUST * game.unit
	var best = null
	var best_d := INF
	for c in _snakes():
		if not c.s in ["rest", "shake", "dart", "enter", "slip"]:
			continue
		for i in 5:
			if game.crocodiles._on_croc(c, tip0.lerp(tip, i / 4.0)):
				var d: float = c.node.position.distance_to(tip)
				if d < best_d:
					best_d = d
					best = c
				break
	if best != null:
		_speared(best)


## Speared: everything waits while its head is pinned under the point. It lies as it is drawn from
## him, moved `along` the spear's line so that its head is under the point at the full strike, facing
## the way he does; then _pin plays it turning its head back, and him pressing on, frame for frame.
func _speared(c: Dictionary) -> void:
	var e: Dictionary = game.fight.e
	game.fight.pin = {"c": c, "t": 0.0, "attacking": c.s in ["shake", "dart"]}
	c.s = "pinned"
	game.fight.hits += 1
	game.fight.thrust = -1.0
	var a: Node2D = c.node
	a.rotation = 0.0
	a.modulate.a = 1.0
	var sp: Sprite2D = game._picture(a)
	sp.material = null
	var at := AtlasTexture.new()
	at.atlas = TURN
	sp.texture = at
	var face: int = game.fight.facing                  # -1: he faces left, as drawn
	sp.flip_h = face > 0
	var rel: Vector2 = game.actors[e.foe].get_meta("home") - game.actors[e.spear].get_meta("home")
	a.position = game.fight.pos + Vector2(rel.x * -face, rel.y) + game._spear_dir() * float(strike.along)
	var drawn: Vector2 = game.fight.snake_size
	var o := -Vector2(drawn.x / 2.0, drawn.y) - Vector2(float(turn.drawn_at[0]), float(turn.drawn_at[1]))
	if face > 0:
		o.x = -o.x - float(turn.cell[0])
	sp.offset = o
	(game._picture(game.actors[e.spear]).texture as AtlasTexture).atlas = STRIKE
	game._picture(game.actors[e.spear + "_pole"]).visible = false
	_pin_frame(1)
	var left: int = int(e.need) - game.fight.hits
	game.say("Scribe", game._feedback_text("struck_more") % left if left > 0 else game._feedback_text("struck"))


## Frame `k` of the pinning: the snake (TURN) and him (STRIKE).
func _pin_frame(k: int) -> void:
	var tw: float = turn.cell[0]
	var th: float = turn.cell[1]
	(game._picture(game.fight.pin.c.node).texture as AtlasTexture).region = Rect2(k * tw, 0.0, tw, th)
	var cw: float = strike.cell[0]
	var ch: float = strike.cell[1]
	(game._picture(game.actors[game.fight.e.spear]).texture as AtlasTexture).region = Rect2(k * cw, 0.0, cw, ch)


## The pinning goes on: a frame every PIN_FRAME, the last held PIN_HOLD; then the snake fades, his
## spear draws back from the strike, and the fight goes on (or is won).
func _pin(dt: float) -> void:
	var p: Dictionary = game.fight.pin
	p.t += dt
	var n: int = int(turn.frames)
	_pin_frame(mini(1 + int(p.t / PIN_FRAME), n - 1))
	if p.t < (n - 2) * PIN_FRAME + PIN_HOLD:
		return
	var c: Dictionary = p.c
	game.fight.erase("pin")
	c.s = "gone"
	(game._picture(game.actors[game.fight.e.spear]).texture as AtlasTexture).atlas = game._sheet_tex
	game.fight.thrust = game.THRUST_TIME[0]
	game.fight.struck = true
	game._fight_tween(c.node).tween_property(c.node, "modulate:a", 0.0, PIN_FADE)
	if p.attacking:
		_attack_over()
	game._won_if(game.fight.hits >= int(game.fight.e.need))


## It touched him: a bite. It slinks back to rest somewhere else on its side.
func _creep_bites(c: Dictionary) -> void:
	game.fight.red = 0.8
	game.fight.health -= 1
	if game.fight.health <= 0:
		game.bites += 1
		_creep_dies()
		return
	game._bite(game._feedback_text("bitten"))
	_attack_over()
	c.s = "back"
	var a: Node2D = c.node
	a.rotation = 0.0
	var to := _rest_spot(c)
	c.at = to
	var t = game._fight_tween(a)     # dies with the snake if the fight ends first
	t.tween_property(a, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): a.position = to)
	t.tween_property(a, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		if not game.fight.is_empty() and c.s == "back":
			c.s = "rest")


## It missed him: it slips past, and rests on the far side (no longer counted toward `at_once`).
func _slips(c: Dictionary) -> void:
	_attack_over()
	c.s = "slip"
	c.slipped = true
	var half: float = c.node.get_meta("size").x / 2.0
	var full: Rect2 = game.fight.full
	var x: float = 2.0 * game.fight.pos.x - c.at.x        # as far beyond him as it rested before him
	c.at = Vector2(clampf(x, full.position.x + half, full.end.x - half), c.node.position.y)
	game._feedback_once("slipped", game._feedback_text("slipped"))


## The last bite: snakes come in from everywhere and bite him all over; he crumbles, and he is
## back on the scroll.
func _creep_dies() -> void:
	game.fight.lost = true
	var e: Dictionary = game.fight.e
	game.say("Scribe", game._hints.message("dangers.defeated"))
	for c in _snakes():
		var mat := game._picture(c.node).material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("amp", 0.0)
	var src: Node2D = game.actors[e.foe]
	var size: Vector2 = src.get_meta("size")
	var full: Rect2 = game.fight.full
	var t = game._fight_tween()
	var moves := []
	for target in _his_edges():
		var dir: int = target.dir
		var a = game._make_actor(game.fight.creep_tex, Rect2(Vector2.ZERO, size))
		_wear(a)
		game._picture(a).flip_h = dir < 0
		game.fight.copies.append(a)
		# where it starts: off to his side, coming in no more than SWARM_ANGLE from level
		var ang := deg_to_rad(game.rng.randf_range(-SWARM_ANGLE, SWARM_ANGLE))
		var dist: float = game.rng.randf_range(0.25, 0.9) * full.size.x / 2.0
		var lead := _front(a, dir)
		var end: Vector2 = target.at - lead
		var start := Vector2(clampf(end.x - dir * dist, full.position.x + size.x / 2.0, full.end.x - size.x / 2.0), 0.0)
		start.y = clampf(end.y - absf(end.x - start.x) * tan(ang), full.position.y + size.y, full.end.y)   # (only ever less steep)
		var v := end - start
		a.rotation = dir * atan2(v.y, absf(v.x))
		end = target.at - lead.rotated(a.rotation)      # its head (turned with it) touches him
		a.position = start
		a.modulate.a = 0.0
		t.parallel().tween_property(a, "modulate:a", 1.0, 0.4)
		moves.append([a, end, start.distance_to(end) / (float(e.speed) * game.unit)])
	t.tween_interval(0.3)
	for i in moves.size():
		var m: Array = moves[i]
		(t.tween_property(m[0], "position", m[1], m[2]) if i == 0 else t.parallel().tween_property(m[0], "position", m[1], m[2])) \
			.set_delay(game.rng.randf_range(0.0, 0.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): game._disintegrate(e))
	t.tween_interval(2.0)
	t.tween_callback(func():
		if not game.fight.is_empty() and game.fight.kind == "creep" and game.fight.e.id == e.id and game.fight.lost:
			game._arena_lost(e))
	game.fight.swarm = moves.map(func(m): return m[0])


## Points all down both sides of him (his outermost ink, every SWARM_ROW of his height), each with
## the side a snake comes from: [{"at", "dir"}].
func _his_edges() -> Array:
	var bs: Sprite2D = game._picture(game.actors[game.fight.e.spear])
	var atlas := bs.texture as AtlasTexture
	var img := atlas.get_image()
	if img.is_compressed():
		img.decompress()
	var out := []
	var y := 0.0
	while y < img.get_height():
		var xs := []
		for x in img.get_width():
			if img.get_pixel(x, int(y)).a > 0.5:
				xs.append(x)
		if not xs.is_empty():
			for side in [[xs[0], 1], [xs[-1], -1]]:
				var x: float = side[0]
				if bs.flip_h:
					x = img.get_width() - 1 - x
				out.append({"at": bs.get_global_transform() * (bs.offset + Vector2(x, y)), "dir": side[1]})
		y += SWARM_ROW * game.unit
	return out


func _creep_click(_p: Vector2) -> void:
	game._feedback_once("controls", game._feedback_text("controls"))


## Dev (`--croc-bot`): a stand-in player who sees a tail shake only REACT s after it starts, then
## moves to its row, faces it, and thrusts as it comes into reach. (BOT_REACT above `shake`: one who
## ignores the tails and waits for the dart.)
func _bot_move() -> Vector2:
	var c = null
	for o in _snakes():
		if o.s in ["shake", "dart"]:
			c = o
	var react: float = float(OS.get_environment("BOT_REACT")) if OS.has_environment("BOT_REACT") else game.crocodiles.REACT
	if c == null or c.t + (float(game.fight.e.shake) if c.s == "dart" else 0.0) < react:
		return Vector2.ZERO
	var want_face := -int(c.dir)
	var mv := Vector2(float(want_face) if game.fight.facing != want_face else 0.0, 0.0)
	var front: Vector2 = c.node.position + _front(c.node, c.dir)
	var tip: Vector2 = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit
	var dy: float = front.y - tip.y
	if absf(dy) > 3.0 * game.unit:
		mv.y = signf(dy)
	var speed: float = float(game.fight.e.speed) * game.unit
	# (where the point is on it when the thrust lands: it comes a little further first)
	if c.s == "dart" and game.fight.facing == want_face \
			and game.crocodiles._on_croc(c, tip - Vector2(c.dir * speed * game.THRUST_TIME[0], 0.0)):
		game._croc_thrust()
	if game.fight.thrust >= 0.0:
		mv.y = 0.0
	return mv


func autotest(e: Dictionary, expect: Callable) -> void:
	var drawn: Dictionary = _snakes()[0]
	expect.call(absf(drawn.node.position.x - game.fight.pos.x) >= float(e.rest[0]) * game.unit, e.id + " the drawn snake rests a way from him")
	expect.call(drawn.s == "rest" and (drawn.node.position.x < game.fight.pos.x) == (drawn.dir > 0), e.id + " ...facing him")
	# they slither in, never more than `at_once`
	game.fight.timer = 99.0
	for i in 400:
		_creep(0.05)
	var resting: Array = _snakes().filter(func(c): return c.s != "gone" and not c.slipped)
	expect.call(resting.size() == int(e.at_once), e.id + " snakes slither in, %d at most" % int(e.at_once))
	expect.call(resting.all(func(c): return c.s == "rest"), e.id + " ...and stop to rest")
	expect.call(resting.all(func(c): return absf(c.node.position.x - game.fight.pos.x) > float(e.rest[0]) * game.unit), e.id + " ...out of reach")
	# one shakes its tail, then darts; nothing else moves meanwhile
	game.fight.timer = 0.0
	_creep(0.01)
	var shaking: Array = _snakes().filter(func(c): return c.s == "shake")
	expect.call(shaking.size() == 1, e.id + " one snake at a time shakes its tail")
	var c: Dictionary = shaking[0]
	var mat := game._picture(c.node).material as ShaderMaterial
	_creep(float(e.shake) / 2.0)
	expect.call(absf(mat.get_shader_parameter("amp")) > 0.0, e.id + " ...its tail shakes")
	_creep(float(e.shake) / 2.0 + 0.01)
	expect.call(c.s == "dart" and _snakes().filter(func(o): return o.s in ["shake", "dart"]).size() == 1, e.id + " ...then it darts, alone")
	# on his row it bites, and slinks back to rest
	game.fight.facing = c.dir             # facing away: no strike
	game.fight.pos.y = clampf(c.node.position.y + _front(c.node, c.dir).y - game.fight.tip.y, game.fight.y_range.x, game.fight.y_range.y)
	game._place_bearer()
	var b0 = game.bites
	for i in 400:
		_creep(0.01)
		if c.s != "dart":
			break
	expect.call(c.s == "back" and game.bites == b0 + 1 and game.fight.health == game.CROC_HEALTH - 1, e.id + " touching him, it bites")
	game._kill_fight_tweens()
	c.s = "rest"
	c.node.position = c.at
	c.node.modulate.a = 1.0
	# off his row it slips past, turns and rests on the far side, and no longer counts
	c.s = "dart"
	var dir0: int = c.dir
	game.fight.pos.y = game.fight.y_range.y if c.node.position.y < (game.fight.y_range.x + game.fight.y_range.y) / 2.0 else game.fight.y_range.x
	game._place_bearer()
	for i in 1000:
		_creep(0.01)
		if c.s == "rest":
			break
	expect.call(c.s == "rest" and c.slipped and c.dir == -dir0 and (c.node.position.x - game.fight.pos.x) * dir0 > 0.0, e.id + " missing him, it slips past and rests on the far side, facing him")
	expect.call(game.fight.health == game.CROC_HEALTH - 1, e.id + " ...without a bite")
	game.fight.timer = 99.0
	for i in 40:
		_creep(0.05)
	resting = _snakes().filter(func(o): return o.s != "gone" and not o.slipped)
	expect.call(resting.size() == int(e.at_once), e.id + " one that slipped past does not count: another slithers in")
	# the point on a darting snake spears it
	var d: Dictionary = resting[0]
	d.s = "dart"
	game.fight.facing = -d.dir
	d.node.position = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit - _front(d.node, d.dir) \
		+ Vector2(d.dir * 4.0 * game.unit, 0.0)
	_creep_strike()
	var bs: Sprite2D = game._picture(game.actors[e.spear])
	expect.call(d.s == "pinned" and game.fight.hits == 1, e.id + " the spear point on a snake spears it")
	var sp: Sprite2D = game._picture(d.node)
	var pin := Vector2(float(turn.pins[1][0]), float(turn.pins[1][1]))
	if sp.flip_h:
		pin.x = float(turn.cell[0]) - pin.x
	var point: Vector2 = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit
	expect.call(sp.to_global(sp.offset + pin).distance_to(point) < 16.0 and (bs.texture as AtlasTexture).atlas == STRIKE,
		e.id + " ...its head pinned under the point, he pressing on")
	var at0: Vector2 = d.node.position
	for i in 10:
		_creep(0.05)
	expect.call(d.s == "pinned" and d.node.position == at0, e.id + " ...everything waits while it turns its head back")
	for i in 40:
		_creep(0.05)
	expect.call(d.s == "gone" and not game.fight.has("pin") and (bs.texture as AtlasTexture).atlas == game._sheet_tex,
		e.id + " ...then it is gone, and he draws his spear back")
	game._kill_fight_tweens()
	# never more than are still to be speared
	game.fight.hits = int(e.need) - 1
	var last: Dictionary = _snakes().filter(func(o): return o.s != "gone")[0]
	for o in _snakes():
		if o != last:
			o.s = "gone"
	last.s = "rest"
	for i in 40:
		_creep(0.05)
	expect.call(_snakes().filter(func(o): return o.s != "gone").size() == 1, e.id + " no more come in than are still to be speared")
	last.s = "dart"
	game.fight.facing = -last.dir
	last.node.position = game.fight.pos + game._tip_offset() + game._spear_dir() * game.CROC_THRUST * game.unit - _front(last.node, last.dir) \
		+ Vector2(last.dir * 4.0 * game.unit, 0.0)
	_creep_strike()
	expect.call(game.fight.hits == int(e.need), e.id + " %d speared wins" % int(e.need))
	# the last bite: snakes from everywhere, none steeper than SWARM_ANGLE, touching him all down both sides
	game.fight.health = 1
	_creep_bites(_snakes()[0])
	var swarm: Array = game.fight.swarm
	expect.call(game.fight.lost and swarm.size() >= 10, e.id + " the last bite: snakes come from everywhere (%d)" % swarm.size())
	expect.call(swarm.all(func(a): return absf(a.rotation) <= deg_to_rad(SWARM_ANGLE) + 0.001), e.id + " ...none steeper than %d degrees" % int(SWARM_ANGLE))
	var edges := _his_edges()
	var ys: Array = edges.map(func(p): return p.at.y)
	var b: Rect2 = game.actor_rect(e.spear)
	expect.call(ys.min() < b.position.y + b.size.y * 0.25 and ys.max() > b.end.y - b.size.y * 0.25 and edges.any(func(p): return p.dir > 0) and edges.any(func(p): return p.dir < 0),
		e.id + " ...biting him from head to foot, on both sides")
	game._kill_fight_tweens()
	game.fight.lost = false
	game.fight.health = game.CROC_HEALTH
