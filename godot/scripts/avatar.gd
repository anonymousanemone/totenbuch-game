## The deceased, cut from the head of plate I. Walks along the ground line toward a target
## (click) or under keyboard control, and calls back on arrival.
extends Node2D

signal bumped  ## pushed against the left limit with the keyboard

var speed := 300.0          ## world px per second
var bob_height := 5.0
const BOB_RATE := 9.0

var min_x := 0.0
var max_x := 1.0e9
var facing := -1            ## -1 = left (direction of the procession), 1 = right
var drawn_facing := -1      ## which way the sprite faces as drawn

var _target = null          ## float or null
var _on_arrive := Callable()
var _walk_time := 0.0

## The figure is drawn opaque, filled with the papyrus (figure.gdshader).
const FIGURE_SHADER := preload("res://scripts/figure.gdshader")

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	var pad := 2
	sprite.texture = _figure_texture(sprite.texture, pad)
	var mat := ShaderMaterial.new()
	mat.shader = FIGURE_SHADER
	sprite.material = mat
	# origin at the feet, so flipping and bobbing pivot on the ground line
	sprite.centered = true
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + pad)


## Repacks the line drawing for figure.gdshader, with `pad` empty pixels all round for the halo:
## R = ink, G = inside the figure's outline. Inside = everything the outside can't reach, after
## small gaps in the outline are sealed (so a broken stroke doesn't let the outside leak in).
func _figure_texture(tex: Texture2D, pad: int) -> ImageTexture:
	var src := tex.get_image()
	if src.is_compressed():
		src.decompress()
	var w := src.get_width() + 2 * pad
	var h := src.get_height() + 2 * pad
	var ink := PackedByteArray()
	ink.resize(w * h)
	for y in src.get_height():
		for x in src.get_width():
			ink[(y + pad) * w + x + pad] = int(src.get_pixel(x, y).a * 255.0)
	var seal := maxi(2, roundi(src.get_height() / 120.0))
	var wall := _dilate(_threshold(ink, 64), w, h, seal)
	# flood the outside from the border
	var outside := PackedByteArray()
	outside.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x)
		stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w)
		stack.append(y * w + w - 1)
	while not stack.is_empty():
		var i: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if outside[i] or wall[i]:
			continue
		outside[i] = 1
		var x := i % w
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if i >= w: stack.append(i - w)
		if i < w * (h - 1): stack.append(i + w)
	# undo the sealing's fattening of the outline (inside = not outside, shrunk back by `seal`)
	var inside := PackedByteArray()
	inside.resize(w * h)
	for i in w * h:
		inside[i] = 0 if outside[i] else 1
	inside = _erode(inside, w, h, seal)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var i := y * w + x
			var on := inside[i] or ink[i] > 64
			out.set_pixel(x, y, Color(ink[i] / 255.0, 1.0 if on else 0.0, 0.0, 1.0))
	return ImageTexture.create_from_image(out)


func _threshold(a: PackedByteArray, t: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(a.size())
	for i in a.size():
		out[i] = 1 if a[i] > t else 0
	return out


## Square max filter of radius r, done as a row pass then a column pass with running counts.
func _dilate(a: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	return _box(_box(a, w, h, r, true, false), w, h, r, false, false)


func _erode(a: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	return _box(_box(a, w, h, r, true, true), w, h, r, false, true)


func _box(a: PackedByteArray, w: int, h: int, r: int, rows: bool, all: bool) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(a.size())
	var n := w if rows else h        # length of a line
	var lines := h if rows else w
	var step := 1 if rows else w
	for l in lines:
		var start := l * w if rows else l
		var count := 0                # set pixels in the window
		for k in mini(r, n - 1) + 1:
			count += a[start + k * step]
		for k in n:
			var size := mini(k + r, n - 1) - maxi(k - r, 0) + 1
			out[start + k * step] = (1 if count == size else 0) if all else (1 if count > 0 else 0)
			if k + r + 1 < n:
				count += a[start + (k + r + 1) * step]
			if k - r >= 0:
				count -= a[start + (k - r) * step]
	return out


func walk_to(x: float, on_arrive := Callable()) -> void:
	_target = clampf(x, min_x, max_x)
	_on_arrive = on_arrive


func stop() -> void:
	_target = null
	_on_arrive = Callable()


func is_walking() -> bool:
	return _target != null


func _process(delta: float) -> void:
	var moving := false
	var axis := Input.get_axis("ui_left", "ui_right")
	if axis != 0.0:
		stop()
		position.x = clampf(position.x + axis * speed * delta, min_x, max_x)
		facing = 1 if axis > 0.0 else -1
		moving = true
		if axis < 0.0 and position.x <= min_x + 0.5:
			bumped.emit()
	elif _target != null:
		var d: float = _target - position.x
		if absf(d) < 4.0:
			position.x = _target
			var cb := _on_arrive
			stop()
			if cb.is_valid():
				cb.call()
		else:
			facing = 1 if d > 0.0 else -1
			position.x += signf(d) * minf(absf(d), speed * delta)
			moving = true

	if moving:
		_walk_time += delta
	# mirror the figure when it walks the other way from how it is drawn
	sprite.flip_h = facing != drawn_facing
	sprite.position.y = -absf(sin(_walk_time * BOB_RATE)) * bob_height if moving else 0.0
