## The collapsed offering table of plate IV (spells 1-15): rebuild the heap piece by piece.
##
## The loose pieces lie on the floor between the two pairs of bouquets as physics bodies, at any
## angle. A piece snaps back into its place, upright, only when everything it rests on is already
## there (`rests_on`, worked out by tools/cut_procession300.py); set down too early it topples
## and falls back to the floor. The palm frond lies in the empty band above the picture and goes
## on last; any piece can be laid in that band too, out of the way, and taken up again.
## The goose-bearer beside the lector holds a loaf from the heap; his goose lies among the
## fallen offerings. With neither in his arms, the clothes they cover show. Positions are strip
## pixels; the pieces come from level.json `table`.
class_name OfferingTable
extends Node2D

signal changed

const SNAP := 45.0           ## how near its place a piece must be set down to go in
const GHOST_ALPHA := 0.18    ## the faint outline of the held piece's place (0 = none)
const SPEAK_FADE_IN := 0.3   ## the lector beside the table shows a piece that can go on now
const SPEAK_HOLD := 2.5
const SPEAK_FADE_OUT := 0.6
const SEED := 7              ## the same scatter every time
const PIECE_LAYER := 2       ## loose pieces collide with each other and the floor, nothing else

var pieces := {}             ## id -> {rect, kind, name, rests_on, hull}
var placed := {}             ## id -> true
var bearer := ""             ## what the goose-bearer holds: a table piece id, "goose" or ""
var floor_x := Vector2.ZERO  ## the floor between the bouquets (x from, x to)
var view := Vector2.ZERO     ## the table scene (x from, x to)
var header := Vector2(50.0, 178.0)  ## the empty band above the picture (rows), where pieces can lie
var ground := 526.0

var _held := ""              ## what the player carries: a table piece id, "goose" or ""
var _held_from := ""         ## "floor", "parked" or "bearer"
var _parked := {}            ## id -> Sprite2D: pieces lying in the band above
var _last_park := {}         ## id -> where it last lay there (centre)
var _tex := {}               ## id -> Texture2D (and "goose")
var _img := {}               ## id -> Image, for clicking on the ink only
var _goose_rect: Rect2
var _clothes_rect: Rect2
var _speech: Rect2
var _speak_i := 0
var _speak_tween: Tween

var _placed_layer: Node2D
var _bodies: Node2D
var _parked_layer: Node2D
var _bearer_sprite: Sprite2D
var _clothes: Sprite2D
var _held_sprite: Sprite2D
var _ghost: Sprite2D
var _speak: Sprite2D


func setup(table: Dictionary, goose: Rect2, clothes: Rect2, ground_y: float, art: String) -> void:
	ground = ground_y
	floor_x = Vector2(table.floor[0], table.floor[1])
	_goose_rect = goose
	_clothes_rect = clothes
	var s: Dictionary = table.speech
	_speech = Rect2(s.x, s.y, s.w, s.h)
	view = Vector2(table.view[0], table.view[1]) if table.has("view") else floor_x
	if table.has("header"):
		header = Vector2(table.header[0], table.header[1])
	for id in table.pieces:
		var p: Dictionary = table.pieces[id]
		var hull := PackedVector2Array()
		for i in range(0, p.hull.size(), 2):
			hull.append(Vector2(p.hull[i], p.hull[i + 1]))
		pieces[id] = {"rect": Rect2(p.x, p.y, p.w, p.h), "kind": p.kind, "name": p.name,
			"rests_on": p.rests_on, "hull": hull}
		_tex[id] = load(art % id)
	_tex.goose = load(art % "goose")
	_tex.clothes = load(art % "clothes")
	for id in _tex:
		_img[id] = _tex[id].get_image()
	for id in pieces:   # the frond lies in the band above at first
		if pieces[id].kind == "frond" and table.has("frond_rest"):
			_last_park[id] = Vector2(table.frond_rest.x, table.frond_rest.y) + _tex[id].get_size() / 2.0

	_placed_layer = Node2D.new()
	add_child(_placed_layer)
	_bodies = Node2D.new()
	add_child(_bodies)
	_build_floor()
	_ghost = _sprite("", false)
	_ghost.modulate.a = GHOST_ALPHA
	_parked_layer = Node2D.new()
	add_child(_parked_layer)
	_clothes = _sprite("clothes", false)
	_clothes.position = _clothes_rect.position
	_bearer_sprite = _sprite("", true)
	_speak = _sprite("", true)
	_held_sprite = _sprite("", true)
	_held_sprite.z_index = 10   # what you pick up comes to the front of everything


func reset() -> void:
	for c in _placed_layer.get_children():
		c.queue_free()
	for b in _bodies.get_children():
		b.queue_free()
	for c in _parked_layer.get_children():
		c.queue_free()
	_parked.clear()
	placed.clear()
	_let_go()
	_speak_i = 0
	_stop_speaking()
	bearer = ""
	var loose: Array = []
	for id in pieces:
		match pieces[id].kind:
			"held": bearer = id
			"loose": loose.append(id)
	loose.append("goose")
	# drop them from a little above the floor, a few at a time, and let them settle
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var per_row := 6
	for i in loose.size():
		var x := lerpf(floor_x.x + 50.0, floor_x.y - 50.0, (float(i % per_row) + rng.randf_range(0.1, 0.9)) / per_row)
		var y := ground - 60.0 - 110.0 * floorf(i / float(per_row))
		_spawn(loose[i], Vector2(x, y), rng.randf_range(-PI, PI))
	for id in pieces:
		if pieces[id].kind == "frond":
			_park(id, _last_park.get(id, Vector2(lerpf(view.x, view.y, 0.5), header.y)))
	_show_bearer()
	changed.emit()


# ---------------------------------------------------------------- rules

## Everything this piece rests on is already in place (the frond goes on last).
func can_place(id: String) -> bool:
	if pieces[id].kind == "frond":
		return pieces.keys().all(func(o): return o == id or placed.has(o))
	return pieces[id].rests_on.all(func(o): return placed.has(o))


func complete() -> bool:
	return placed.size() == pieces.size()


func goose_returned() -> bool:
	return bearer == "goose"


## Pieces that could go on now, lowest first.
func stackable() -> Array:
	var out: Array = pieces.keys().filter(func(id): return not placed.has(id) and can_place(id))
	out.sort_custom(func(a, b): return pieces[a].rect.end.y > pieces[b].rect.end.y \
		or (pieces[a].rect.end.y == pieces[b].rect.end.y and pieces[a].rect.position.x < pieces[b].rect.position.x))
	return out


## The drawing of a loose piece (or the frond) as it lies now, for the hover glow.
func sprite_of(id: String) -> Sprite2D:
	for b in _bodies.get_children():
		if b.get_meta("id") == id and not b.is_queued_for_deletion():
			return b.get_child(0)
	if _parked.has(id) and not _parked[id].is_queued_for_deletion():
		return _parked[id]
	return null


## What the goose-bearer has in his arms (or the clothes they leave bare), for the hover glow.
func bearer_sprites() -> Array:
	return [_bearer_sprite, _clothes].filter(func(s): return s.visible)


## His clothes show only with nothing in his arms.
func clothes_showing() -> bool:
	return _clothes.visible


## Where the piece in hand was taken from: "floor", "parked" or "bearer".
func held_from() -> String:
	return _held_from


func holding() -> String:
	return _held


func held_texture() -> Texture2D:
	return _tex.get(_held)


func held_name() -> String:
	return name_of(_held)


func name_of(id: String) -> String:
	if id == "goose":
		return "the goose"
	if id == "" or not pieces.has(id):
		return ""
	match pieces[id].kind:
		"frond": return "the palm frond"
		"held": return "the loaf"
	return "an offering"


## Where a piece set down here would land: the floor between the bouquets, below the frame.
func in_zone(p: Vector2) -> bool:
	return p.x >= floor_x.x and p.x <= floor_x.y and p.y < ground and p.y > 0.0


# ---------------------------------------------------------------- the player's hands

## The loose piece (or the frond) under the pointer, topmost first.
func pick(p: Vector2) -> String:
	var bodies := _bodies.get_children()
	for i in range(bodies.size() - 1, -1, -1):
		var b: RigidBody2D = bodies[i]
		if b.is_queued_for_deletion():
			continue
		if _ink_at(b.get_meta("id"), b.to_local(p) + _tex[b.get_meta("id")].get_size() / 2.0):
			return b.get_meta("id")
	var lying := _parked_layer.get_children()
	for i in range(lying.size() - 1, -1, -1):
		var s: Sprite2D = lying[i]
		if not s.is_queued_for_deletion() and _ink_at(s.get_meta("id"), p - s.position + s.texture.get_size() / 2.0):
			return s.get_meta("id")
	return ""


func take(id: String) -> void:
	for b in _bodies.get_children():
		if b.get_meta("id") == id and not b.is_queued_for_deletion():
			var from: String = b.get_meta("from", "floor")
			_last_park[id] = b.position
			b.queue_free()
			_hold(id, from)
			return
	if _parked.has(id):
		_parked[id].queue_free()
		_parked.erase(id)
		_hold(id, "parked")


## In the empty band above the picture, over the table scene: a piece can be laid there.
func in_header(p: Vector2) -> bool:
	return p.y >= header.x and p.y <= header.y and p.x >= view.x and p.x <= view.y


## Lay the carried piece in the band above, upright where it is let go, out of the way.
func park(p: Vector2) -> void:
	var id := _held
	if id == "":
		return
	_let_go()
	_park(id, p)
	changed.emit()


## Set the carried piece down at p: into its place, toppling off, or onto the floor.
func drop_at(p: Vector2) -> String:
	var id := _held
	if id == "":
		return ""
	_let_go()
	if id != "goose" and p.distance_to(pieces[id].rect.get_center()) <= SNAP:
		if can_place(id):
			_place(id)
			return "placed"
		_fall(id, pieces[id].rect.get_center(), true)
		return "toppled"
	_fall(id, p, false)
	return "dropped"


## Esc: back where it came from.
func put_back() -> void:
	var id := _held
	var from := _held_from
	if id == "":
		return
	_let_go()
	if from == "bearer" and bearer == "":
		bearer = id
		_show_bearer()
	elif from == "parked":
		_park(id, _last_park[id])
	else:
		_fall(id, Vector2(lerpf(floor_x.x, floor_x.y, 0.5), ground - 200.0), false)
	changed.emit()


## The goose-bearer: take the loaf from him, or give him back his goose (taking the loaf).
## Returns what happened: "took", "gave", "swapped", "full", "wrong", "empty", "has_goose".
func bearer_act() -> String:
	if _held == "":
		if bearer == "":
			return "empty"
		if bearer == "goose":
			return "has_goose"
		var loaf := bearer
		bearer = ""
		_show_bearer()
		_hold(loaf, "bearer")
		return "took"
	if _held != "goose":
		return "wrong"
	_let_go()
	var had := bearer
	bearer = "goose"
	_show_bearer()
	if had != "":
		_hold(had, "bearer")
		return "swapped"
	changed.emit()
	return "gave"


## The lector beside the table shows, in front of him, one piece that can go on now; asked
## again he shows the next. False when there is nothing left to stack.
func speak() -> bool:
	var can := stackable()
	if can.is_empty():
		return false
	var id: String = can[_speak_i % can.size()]
	_speak_i += 1
	_stop_speaking()
	var size: Vector2 = _tex[id].get_size()
	var s := minf(1.0, minf(_speech.size.x / size.x, _speech.size.y / size.y))
	_speak.texture = _tex[id]
	_speak.scale = Vector2(s, s)
	_speak.position = _speech.get_center()
	_speak.modulate.a = 0.0
	_speak.visible = true
	_speak.set_meta("id", id)
	_speak_tween = create_tween()
	_speak_tween.tween_property(_speak, "modulate:a", 1.0, SPEAK_FADE_IN)
	_speak_tween.tween_interval(SPEAK_HOLD)
	_speak_tween.tween_property(_speak, "modulate:a", 0.0, SPEAK_FADE_OUT)
	_speak_tween.tween_callback(func(): _speak.visible = false)
	return true


## What the lector is showing now ("" when nothing).
func speaking() -> String:
	return _speak.get_meta("id", "") if _speak.visible else ""


func _process(_delta: float) -> void:
	if _held != "":
		_held_sprite.position = get_global_mouse_position()


# ---------------------------------------------------------------- internals

func _hold(id: String, from: String) -> void:
	_held = id
	_held_from = from
	_held_sprite.texture = _tex[id]
	_held_sprite.position = get_global_mouse_position()
	_held_sprite.visible = true
	if id != "goose":
		_ghost.texture = _tex[id]
		_ghost.position = pieces[id].rect.position
		_ghost.visible = GHOST_ALPHA > 0.0
	changed.emit()


func _let_go() -> void:
	_held = ""
	_held_from = ""
	_held_sprite.visible = false
	_ghost.visible = false


func _place(id: String) -> void:
	placed[id] = true
	var s := _sprite(id, false, _placed_layer)
	s.position = pieces[id].rect.position
	s.modulate = Color(1.8, 1.4, 0.6)
	create_tween().tween_property(s, "modulate", Color.WHITE, 0.8)
	changed.emit()


## Into the physics: the frond goes back to its place above, everything else falls.
func _fall(id: String, at: Vector2, topple: bool) -> void:
	var half: float = _tex[id].get_size().x / 2.0
	at.x = clampf(at.x, floor_x.x + minf(half, 60.0), floor_x.y - minf(half, 60.0))
	at.y = minf(at.y, ground - 20.0)
	var b := _spawn(id, at, 0.0)
	if topple:  # it slides off the side it overhangs and turns over
		var side := -1.0 if randf() < 0.5 else 1.0
		b.linear_velocity = Vector2(side * 70.0, -20.0)
		b.angular_velocity = side * 2.5
	changed.emit()


func _spawn(id: String, at: Vector2, rot: float) -> RigidBody2D:
	var b := RigidBody2D.new()
	b.set_meta("id", id)
	b.collision_layer = PIECE_LAYER
	b.collision_mask = PIECE_LAYER | 4
	b.position = at
	b.rotation = rot
	var mat := PhysicsMaterial.new()
	mat.friction = 0.9
	mat.bounce = 0.05
	b.physics_material_override = mat
	b.angular_damp = 1.5
	var sprite := Sprite2D.new()
	sprite.texture = _tex[id]
	b.add_child(sprite)
	var shape := CollisionPolygon2D.new()
	var size: Vector2 = _tex[id].get_size()
	var hull: PackedVector2Array = pieces[id].hull if pieces.has(id) else PackedVector2Array()
	if hull.size() < 3:
		hull = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	var centred := PackedVector2Array()
	for v in hull:
		centred.append(v - size / 2.0)
	shape.polygon = centred
	b.add_child(shape)
	_bodies.add_child(b)
	return b


func _build_floor() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = PIECE_LAYER
	body.collision_mask = 0
	add_child(body)
	var w := floor_x.y - floor_x.x
	for r in [
		Rect2(floor_x.x - 40.0, ground, w + 80.0, 60.0),        # the floor
		Rect2(floor_x.x - 40.0, -600.0, 40.0, ground + 660.0),   # the bouquets on the left ...
		Rect2(floor_x.y, -600.0, 40.0, ground + 660.0),          # ... and on the right
	]:
		var c := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		c.shape = shape
		c.position = r.get_center()
		body.add_child(c)

	# Only a piece in the player's hands can pass through this register.
	var platform := StaticBody2D.new()
	platform.collision_layer = 4
	platform.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shelf := RectangleShape2D.new()
	shelf.size = Vector2(view.y - view.x, 8.0)
	collision.shape = shelf
	collision.position = Vector2((view.x + view.y) / 2.0, header.y + 4.0)
	platform.add_child(collision)
	add_child(platform)


func _park(id: String, at: Vector2) -> void:
	var half: Vector2 = _tex[id].get_size() / 2.0
	var c := at
	c.x = clampf(c.x, view.x + half.x, maxf(view.x + half.x, view.y - half.x))
	c.y = clampf(c.y, header.x + half.y, maxf(header.x + half.y, header.y - half.y))
	var body := _spawn(id, c, 0.0)
	body.set_meta("from", "parked")
	_last_park[id] = c


func _show_bearer() -> void:
	_clothes.visible = bearer == ""
	_bearer_sprite.visible = bearer != ""
	if bearer != "":
		_bearer_sprite.texture = _tex[bearer]
		_bearer_sprite.position = _goose_rect.get_center()
		if bearer != "goose":  # a loaf sits in his hands, where the goose's body is (not its neck)
			var w: float = _tex[bearer].get_size().x
			_bearer_sprite.position.x = _goose_rect.end.x - w / 2.0 - 10.0


func _stop_speaking() -> void:
	if _speak_tween and _speak_tween.is_valid():
		_speak_tween.kill()
	if _speak:
		_speak.visible = false


func _sprite(id: String, centred: bool, parent: Node = self) -> Sprite2D:
	var s := Sprite2D.new()
	if id != "":
		s.texture = _tex[id]
	s.centered = centred
	s.visible = id != ""
	parent.add_child(s)
	return s


## Is there ink at this pixel of the piece's picture (its own top-left frame)?
func _ink_at(id: String, local: Vector2) -> bool:
	var img: Image = _img[id]
	var x := int(local.x)
	var y := int(local.y)
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	# a little slack round thin strokes: any ink within 3 px
	for dy in range(-3, 4, 3):
		for dx in range(-3, 4, 3):
			var xx := clampi(x + dx, 0, img.get_width() - 1)
			var yy := clampi(y + dy, 0, img.get_height() - 1)
			if img.get_pixel(xx, yy).a > 0.2:
				return true
	return false
