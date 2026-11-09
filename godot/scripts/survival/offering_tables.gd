## Spells 52 and 53: the seated man at his altar. In 52 excrement falls and he keeps it off the loaves
## with his hand; in 53 loaves and excrement fall and he catches the loaves in his cup, and each flies
## to its drawn place on the table. [←] [→] move his hand along a level line: the arm bends and
## stretches at the elbow (the hand of 53 stays level), and once it is straight he leans in and his
## torso stretches a little (lean.gdshader). Excrement on the loaves (52) or in the cup (53) costs a
## flesh sign; with the last one the game is lost and a was-sceptre with it, and with none left he dies.
extends RefCounted

const LEAN := preload("res://scripts/survival/lean.gdshader")
const FLESH_PATH := "res://assets/dangers/figures/flesh.png"
const FLESH := 3                 ## flesh signs (lives) per game
const FALL_SPEED := 160.0        ## strip px/s
const FALL_EVERY := 1.2          ## s between pieces
const FALL_FROM := 190.0         ## strip y they start from (the top of the picture band)
const COVER_NEED := 8            ## 52: pieces kept off the loaves to finish
const FILTH_SHARE := 0.2         ## 53: share of excrement among what falls ...
const FILTH_STEP := 0.1          ## ... raised by this for each part that drops past him
const HAND_SPEED := 150.0        ## strip px/s his hand moves along its line
const RETRACT := 50.0            ## his hand comes in this far from where it is drawn (strip px)
const LEAN_MAX := 0.4            ## rad he leans at most ...
const STRETCH_MAX := 14.0        ## ... and his torso stretches (strip px), once his arm is straight
const ARM_HALF := 7.0            ## 52: half the arm's thickness that keeps a piece off
const FILTH_TINT := Color(0.45, 0.13, 0.08)   ## excrement, dark red
const THIGH := Vector2(1.0, 0.12)  ## along his lap, from the hip
const FLESH_GAP := 6.0           ## strip px between the flesh signs ...
const FLESH_LIFT := 8.0          ## ... and from them to the top of his head
## 53: what is heaped on the table, in the order it is caught (from the bottom up)
const PARTS := ["spell53_loaf1", "spell53_loaf2", "spell53_loaf3", "spell53_loaf4", "spell53_loaf5",
	"spell53_loaf6", "spell53_loaf7", "spell53_whisp1", "spell53_whisp2", "spell53_whisp3",
	"spell53_whisp4", "spell53_whisp5"]

var game
var rigs := {}                   ## 52, 53 -> the arm's nodes and its pose as drawn
var g := {}                      ## the game being played (empty when none)
var _flesh_tex: Texture2D
var _filth_tex: Texture2D          ## the excrement sign as white ink, tinted FILTH_TINT
var _flesh: Array[Sprite2D] = []


func _init(level) -> void:
	game = level


func setup() -> void:
	for sp in [52, 53]:
		var root: Node2D = game.get_node("Figures/Spell%d" % sp)
		var r := {"sp": sp, "root": root, "hips": root.get_node("Hips"), "chest": root.get_node("Hips/Chest"),
			"shoulder": root.get_node("Hips/Chest/Shoulder"), "elbow": root.get_node("Hips/Chest/Shoulder/Elbow"),
			"body": game.figures["spell%d_seated_man" % sp], "head": game.pieces["spell%d_head" % sp]}
		r.eff = r.elbow.get_node("Tip") if sp == 52 else r.elbow.get_node("Wrist")
		r.wrist = r.elbow.get_node_or_null("Wrist")
		r.H = r.hips.global_position
		r.S0 = r.shoulder.global_position
		r.E0 = r.elbow.global_position
		r.T0 = r.eff.global_position
		r.L1 = r.S0.distance_to(r.E0)
		r.L2 = r.E0.distance_to(r.T0)
		r.a1 = (r.E0 - r.S0).angle()
		r.a2 = (r.T0 - r.E0).angle()
		r.bend = signf(wrapf(r.a1 - (r.T0 - r.S0).angle(), -PI, PI))
		r.spine = (r.S0 - r.H).normalized()
		r.head_at = r.head.position
		var S1: Vector2 = _shoulder_at(r, 1.0)
		var reach: float = (r.L1 + r.L2) * 0.999
		r.x_min = r.T0.x - RETRACT
		r.x_max = S1.x + sqrt(maxf(0.0, reach * reach - (r.T0.y - S1.y) * (r.T0.y - S1.y)))
		var mat := ShaderMaterial.new()
		mat.shader = LEAN
		var body: Sprite2D = r.body
		mat.set_shader_parameter("hip", r.H - body.global_position)
		mat.set_shader_parameter("thigh", THIGH.normalized())
		mat.set_shader_parameter("spine", r.spine)
		mat.set_shader_parameter("spine_len", r.S0.distance_to(r.H))
		r.mat = mat
		rigs[sp] = r
	# 52: where excrement lands on the loaves, as far as his hand can keep it off
	var altar: Dictionary = game.level.pieces.spell52_altar
	var reach: float = rigs[52].x_max + ARM_HALF + _filth_radius()
	rigs[52].loaves = Vector2(altar.x + 8.0, minf(altar.x + altar.w - 8.0, reach))
	rigs[52].loaves_top = float(altar.y) + 4.0
	_flesh_tex = _white_ink(load(FLESH_PATH))
	_filth_tex = _white_ink(game.pieces.spell52_excrement.texture)
	for i in FLESH:
		var s := Sprite2D.new()
		s.texture = _flesh_tex
		s.modulate = UI.DANGER
		s.z_index = 6
		s.visible = false
		game.add_child(s)
		_flesh.append(s)


## A sign as white ink (its darkness as alpha), to be tinted.
static func _white_ink(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(1, 1, 1, c.a * (1.0 - c.get_luminance())))
	return ImageTexture.create_from_image(img)


## As at the start of the level: the chairs empty, 53's table bare (or as drawn once solved).
func reset() -> void:
	_clear_falling()
	g = {}
	for f in _flesh:
		f.visible = false
	for sp in rigs:
		var r: Dictionary = rigs[sp]
		var shown: bool = game._solved.has(sp)
		r.body.material = r.mat
		for n in [r.body, r.hips]:
			n.visible = shown
			n.modulate = Color.WHITE
		for s in r.hips.find_children("*", "Sprite2D", true, false):
			s.material = null
			s.modulate = Color.WHITE
		r.head.position = r.head_at
		r.head.rotation = 0.0
		pose(r, r.T0.x)
	for key in PARTS:
		game.pieces[key].visible = game._solved.has(53)
		game.pieces[key].modulate = Color.WHITE


# ---------------------------------------------------------------- the arm

## His shoulder (strip px) when he leans in and stretches by share `u`.
func _shoulder_at(r: Dictionary, u: float) -> Vector2:
	return r.H + (r.S0 - r.H + r.spine * STRETCH_MAX * u).rotated(LEAN_MAX * u)


## His hand (52: fingertip; 53: wrist) at `x` on its level line: lean in only as far as the arm needs.
func pose(r: Dictionary, x: float) -> void:
	var T := Vector2(clampf(x, r.x_min, r.x_max), r.T0.y)
	var reach: float = (r.L1 + r.L2) * 0.999
	var u := 0.0
	if T.distance_to(_shoulder_at(r, 0.0)) > reach:
		var lo := 0.0
		var hi := 1.0
		for i in 14:
			var mid := (lo + hi) / 2.0
			if T.distance_to(_shoulder_at(r, mid)) > reach:
				lo = mid
			else:
				hi = mid
		u = hi
	r.u = u
	var lean := LEAN_MAX * u
	r.hips.rotation = lean
	r.chest.position = r.spine * STRETCH_MAX * u
	r.mat.set_shader_parameter("lean", lean)
	r.mat.set_shader_parameter("stretch", STRETCH_MAX * u)
	var S := _shoulder_at(r, u)
	var d := T - S
	var dl := clampf(d.length(), absf(r.L1 - r.L2) + 0.01, reach)
	var a := acos(clampf((r.L1 * r.L1 + dl * dl - r.L2 * r.L2) / (2.0 * r.L1 * dl), -1.0, 1.0))
	var e_ang: float = d.angle() + r.bend * a
	var E: Vector2 = S + Vector2.from_angle(e_ang) * r.L1
	var g1: float = e_ang - r.a1
	var g2: float = (T - E).angle() - r.a2
	r.shoulder.rotation = g1 - lean
	r.elbow.rotation = g2 - g1
	if r.wrist:
		r.wrist.rotation = -g2           # his hand, and the cup in it, stay level
	r.x = T.x


# ---------------------------------------------------------------- playing

## He takes his seat (the avatar fades into the seated man) and the game begins.
func start(sp: int) -> void:
	var r: Dictionary = rigs[sp]
	game.mode = game.Mode.TABLE
	game.avatar.keys = false
	game.avatar.stop()
	g = {"sp": sp, "playing": false}
	game.widen.open(sp)
	pose(r, r.T0.x)
	var t: Tween = game.create_tween()
	t.tween_property(game.avatar, "modulate:a", 0.0, 0.4)
	for n in [r.body, r.hips]:
		n.visible = true
		n.modulate.a = 0.0
		t.parallel().tween_property(n, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		game.avatar.visible = false
		_begin(sp))
	game.hud.say("Scribe", game._hints.message("survival.cover52" if sp == 52 else "survival.catch53"), "minigame")


## A fresh game at the seat: all flesh signs, nothing falling, 53's table bare.
func _begin(sp: int) -> void:
	_clear_falling()
	g = {"sp": sp, "playing": true, "flesh": FLESH, "timer": 0.5, "blocked": 0, "missed": 0, "placed": []}
	if sp == 53:
		for key in PARTS:
			game.pieces[key].visible = false
	_show_flesh()


func process(delta: float) -> void:
	if g.is_empty():
		return
	var r: Dictionary = rigs[g.sp]
	if g.playing:
		pose(r, r.x + Input.get_axis("ui_left", "ui_right") * HAND_SPEED * delta)
		g.timer -= delta
		if g.timer <= 0.0 and _wants_more():
			g.timer = FALL_EVERY
			_drop()
	_fall(delta)
	_place_flesh()
	if g.playing and _done() and g.falling_count == 0:
		_win()


func _wants_more() -> bool:
	if g.sp == 52:
		return g.blocked + _falling().size() < COVER_NEED
	return g.placed.size() < PARTS.size()


func _done() -> bool:
	return g.blocked >= COVER_NEED if g.sp == 52 else g.placed.size() == PARTS.size()


func _falling() -> Array:
	return g.get("falling", [])


## One more piece falls: 52 only excrement, over the loaves; 53 excrement or the next part still
## wanted, within reach of his cup.
func _drop() -> void:
	var r: Dictionary = rigs[g.sp]
	var kind := "filth"
	var x: float
	if g.sp == 52:
		x = randf_range(r.loaves.x, r.loaves.y)
	else:
		var falling: Array = _falling().map(func(f): return f.kind)
		var wanted: Array = PARTS.filter(func(k): return not k in g.placed and not k in falling)
		if not wanted.is_empty() and randf() >= FILTH_SHARE + FILTH_STEP * g.missed:
			kind = wanted[0]
		var cup := _cup_offset(r)
		x = randf_range(r.x_min, r.x_max) + cup
	var s := Sprite2D.new()
	s.texture = game.pieces[kind].texture if kind != "filth" else _filth_tex
	s.position = Vector2(x, FALL_FROM)
	s.z_index = 3
	if kind == "filth":
		s.modulate = FILTH_TINT
	game.get_node("Figures/Spell%d" % g.sp).add_child(s)
	if not g.has("falling"):
		g.falling = []
	g.falling.append({"sprite": s, "kind": kind, "done": false})


## 53: from his wrist to the middle of his cup, along x.
func _cup_offset(r: Dictionary) -> float:
	var hand: Sprite2D = game.pieces.spell53_hand
	return (hand.global_position.x + hand.texture.get_width() / 2.0) - r.eff.global_position.x


func _fall(delta: float) -> void:
	var r: Dictionary = rigs[g.sp]
	var count := 0
	for f in _falling().duplicate():
		if f.done:
			g.falling.erase(f)      # its sprite fades out on its own
			continue
		count += 1
		var s: Sprite2D = f.sprite
		s.position.y += FALL_SPEED * delta
		var half := s.texture.get_size() / 2.0
		if g.sp == 52:
			var c := s.global_position
			var S: Vector2 = r.shoulder.global_position
			var E: Vector2 = r.elbow.global_position
			var T: Vector2 = r.eff.global_position
			var pr := _filth_radius()
			var near := minf(_to_segment(c, S, E), _to_segment(c, E, T))
			if g.playing and near < ARM_HALF + pr:
				f.done = true
				g.blocked += 1
				_fade(f, 0.25)
			elif s.position.y + half.y >= r.loaves_top:
				f.done = true
				_fade(f, 0.8)
				_hurt()
		else:
			var hand: Sprite2D = game.pieces.spell53_hand
			var cup := Rect2(hand.global_position, hand.texture.get_size()).grow(4.0)
			var bottom := s.global_position + Vector2(0.0, half.y)
			if g.playing and cup.has_point(bottom):
				f.done = true
				if f.kind == "filth":
					_fade(f, 0.6)
					_hurt()
				else:
					_place(f)
			elif s.position.y - half.y > float(game.level.ground):
				f.done = true
				if f.kind != "filth":
					g.missed += 1
				_fade(f, 0.2)
	g.falling_count = count


## How near the arm a piece of excrement must come to be kept off (besides ARM_HALF).
func _filth_radius() -> float:
	var size: Vector2 = game.pieces.spell52_excrement.texture.get_size()
	return minf(size.x, size.y) / 2.0 * 0.8


static func _to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## 53: a caught part flies from the cup to its drawn place on the table.
func _place(f: Dictionary) -> void:
	var s: Sprite2D = f.sprite
	var piece: Sprite2D = game.pieces[f.kind]
	var to := piece.global_position + piece.texture.get_size() / 2.0
	g.placed.append(f.kind)
	var t: Tween = s.create_tween()
	t.tween_property(s, "global_position", to, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		piece.visible = true
		piece.modulate = Color.WHITE
		s.queue_free())


func _fade(f: Dictionary, after: float) -> void:
	var s: Sprite2D = f.sprite
	var t: Tween = s.create_tween()
	t.tween_interval(after)
	t.tween_property(s, "modulate:a", 0.0, 0.3)
	t.tween_callback(s.queue_free)


func _clear_falling() -> void:
	for f in _falling():
		if is_instance_valid(f.sprite):
			f.sprite.queue_free()
	if not g.is_empty():
		g.falling = []
		g.falling_count = 0


# ---------------------------------------------------------------- flesh, losing, winning

func _hurt() -> void:
	if not g.playing:
		return
	g.flesh -= 1
	var r: Dictionary = rigs[g.sp]
	var t: Tween = r.body.create_tween()
	t.tween_property(r.body, "modulate", UI.INK_TINT, 0.15)
	t.tween_property(r.body, "modulate", Color.WHITE, 0.4)
	_show_flesh()
	if g.flesh <= 0:
		_lose()


func _show_flesh() -> void:
	for i in _flesh.size():
		_flesh[i].visible = not g.is_empty() and i < int(g.get("flesh", 0))


## Above his head, one sign for each flesh left, the rest closed up.
func _place_flesh() -> void:
	var n := int(g.get("flesh", 0))
	if n <= 0:
		return
	var head: Sprite2D = rigs[g.sp].head
	var top := head.global_position + Vector2(head.texture.get_width() / 2.0, 0.0)
	var fs := _flesh_tex.get_size()
	var left := top.x - (n * fs.x + (n - 1) * FLESH_GAP) / 2.0 + fs.x / 2.0
	for i in n:
		_flesh[i].position = Vector2(left + i * (fs.x + FLESH_GAP), top.y - FLESH_LIFT - fs.y / 2.0)


## The last flesh sign: the game is lost, and a was-sceptre with it; it starts again. With none left
## he dies at his seat.
func _lose() -> void:
	g.playing = false
	var sp: int = g.sp
	for f in _falling():
		if not f.done:
			f.done = true
			_fade(f, 0.0)
	if game._lose_sceptre():
		game.hud.say("Scribe", game._hints.message("survival.table_lost"))
		var run: int = game._run
		game.get_tree().create_timer(1.6).timeout.connect(func():
			if run == game._run and not g.is_empty() and g.sp == sp:
				_begin(sp))
	else:
		_die(sp)


## His head falls from his shoulders, excrement rains down, and he crumbles; then back to the start.
func _die(sp: int) -> void:
	var r: Dictionary = rigs[sp]
	game.mode = game.Mode.SCENE
	for f in _flesh:
		f.visible = false
	var run: int = game._run
	var t: Tween = game.create_tween()
	t.tween_property(r.head, "position:y", r.head.position.y + 60.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(r.head, "rotation", -1.4, 0.5)
	t.tween_callback(func():
		for i in 10:
			g.timer = 0.0
			_drop()
			g.falling[-1].sprite.position.y -= i * 40.0)
	t.tween_interval(0.8)
	t.tween_callback(func():
		for s in [r.body] + r.hips.find_children("*", "Sprite2D", true, false):
			game._crumble(s))
	t.tween_interval(1.9)
	t.tween_callback(func():
		if run != game._run:
			return
		game.hud.say("Scribe", game._hints.message("survival.died"))
		game._after_death())


## Done: nothing more falls; his hand goes back to where it is drawn and he stands up beside his
## chair. The seated man stays, as drawn.
func _win() -> void:
	var sp: int = g.sp
	var r: Dictionary = rigs[sp]
	g.playing = false
	game._solved[sp] = true
	game.mode = game.Mode.SCENE
	for f in _flesh:
		f.visible = false
	var t: Tween = game.create_tween()
	t.tween_method(func(x: float): pose(r, x), r.x, r.T0.x, 0.4)
	t.tween_callback(func():
		UI.success_flash(game.pieces["spell52_altar" if sp == 52 else "spell53_offering_table"])
		g = {}
		game.hud.say("Scribe", game._hints.message("survival.covered52" if sp == 52 else "survival.heaped53"))
		_stand_up(sp))


## [esc]: he gets up; the game is not kept.
func leave() -> void:
	if g.is_empty():
		return
	var sp: int = g.sp
	var r: Dictionary = rigs[sp]
	g.playing = false
	_clear_falling()
	g = {}
	for f in _flesh:
		f.visible = false
	game.mode = game.Mode.SCENE
	pose(r, r.T0.x)
	var t: Tween = game.create_tween()
	for n in [r.body, r.hips]:
		t.parallel().tween_property(n, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		r.body.visible = false
		r.hips.visible = false
		if sp == 53:
			for key in PARTS:
				game.pieces[key].visible = false
		_stand_up(sp))


func _stand_up(sp: int) -> void:
	game.widen.close()
	game._stand_at(float(game.level.pieces["spell%d_chair" % sp].x) - game.HALF)
