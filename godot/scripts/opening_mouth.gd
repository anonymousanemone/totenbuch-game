## The Opening of the Mouth (plates V-VI, spell 15): touch the adze to the mummy's mouth, and
## carry the words it speaks to their place over Ra.
##
## With the adze, finish the mouth, eye and beard a chip at a time. Three nicks disturb
## the mummy and reset the face; the original word-carrying sequence follows success.
## Face pixels are cut into mouth/features; paths and positions come from level.json.
class_name OpeningMouth
extends Node2D

signal said(who: String, text: String)
signal changed

enum Phase { START, ADZE, SPOKEN, WORDS, DONE }

const IMPRINT := UI.PREVIEW   ## the words' imprint over Ra: faint and reddish, like the stela's
const BALL := 44.0            ## strip px across: the words as they leave the mouth
const RISE := 0.6             ## s for the ball to rise out of the mouth ...
const UNROLL := 0.9           ## ... and to unroll into the line of signs
const DROP_PAD := 40.0        ## strip px round the imprint that still take the line
const CHIP_STEP := 3.0
const CHIP_TOLERANCE := 4.0
const MAX_NICKS := 3
const CARVING_SCALE := 0.35   ## keep the carried handle clear of the small face
const ADZE_GRIP := Vector2(6.0, 8.0)   ## where on the adze the pointer holds it: at the blade

var active := false
var _features: Sprite2D
var _body: Sprite2D
var _body_home := Vector2.ZERO
var _feature_texture: Texture2D
var _feature_image: Image
var _feature_origin := Vector2.ZERO
var _face_view := Rect2()
var _curves: Array[Curve2D] = []
var _progress: Array[float] = []
var _pixel_stroke := PackedInt32Array()
var _pixel_along := PackedFloat32Array()
var _nicks: Array[Vector2] = []
var _time := 0.0
var phase := Phase.START
var instant := false          ## the autotest: no animation
var _adze: Sprite2D
var _props: Array             ## the rest of what lies on the stand with the adze: two rods and a foreleg
var _words: Sprite2D          ## centred, so it can grow from a ball
var _imprint: Sprite2D
var _adze_home := Rect2()
var _words_home := Rect2()
var _spoken := Vector2.ZERO   ## the words' centre above the mummy
var _mouth := Vector2.ZERO
var _mummy := Rect2()
var _tween: Tween


func setup(level: Dictionary, nodes: Dictionary) -> void:
	var m: Dictionary = level.mouth
	_mouth = Vector2(m.mouth[0], m.mouth[1])
	_mummy = Rect2(m.mummy.x, m.mummy.y, m.mummy.w, m.mummy.h)
	_adze = nodes.mouth_adze
	_props = [nodes.mouth_column, nodes.mouth_spoon]
	_words = nodes.mouth_words
	_imprint = nodes.words_imprint
	_adze_home = Rect2(_adze.position, _adze.texture.get_size())
	_words_home = Rect2(_words.position - _words.texture.get_size() / 2.0, _words.texture.get_size())
	_spoken = Vector2(m.speak_right - _words_home.size.x / 2.0, _words_home.get_center().y)
	_setup_face(level, nodes)


func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	active = false
	phase = Phase.START
	_body.position = _body_home
	_clear_face()
	_adze.position = _adze_home.position
	_adze.scale = Vector2.ONE
	_adze.self_modulate.a = 1.0
	_adze.visible = true
	_words.visible = false
	_words.scale = Vector2.ONE
	_words.modulate.a = 1.0
	_imprint.visible = false


func done() -> bool:
	return phase == Phase.DONE


## What is carried: "adze", "words" or "".
func carrying() -> String:
	match phase:
		Phase.ADZE:
			return "adze"
		Phase.WORDS:
			return "words"
	return ""


func carried_name() -> String:
	return {"adze": "the adze", "words": "the words"}.get(carrying(), "")


func carried_texture() -> Texture2D:
	return _adze.texture if phase == Phase.ADZE else _words.texture if phase == Phase.WORDS else null


## Under the pointer: "adze" on the stand, "mummy" with the adze in hand, "words" above the
## mummy, "home" (the imprint over Ra) with the words in hand; else "".
func pick(p: Vector2) -> String:
	match phase:
		Phase.START:
			if _adze_home.grow(8.0).has_point(p):
				return "adze"
		Phase.ADZE:
			if _mummy.has_point(p):
				return "mummy"
			if back_rect().has_point(p):
				return "back"
		Phase.SPOKEN:
			if words_rect().grow(6.0).has_point(p) and not (_tween and _tween.is_running()):
				return "words"
		Phase.WORDS:
			if home_rect().has_point(p):
				return "home"
			if back_rect().has_point(p):
				return "back"
	return ""


## Where the words are now (world px).
func words_rect() -> Rect2:
	var size := _words.texture.get_size() * _words.scale
	return Rect2(_words.position - size / 2.0, size)


## Where what you carry was taken from: the adze's place on the stand, or the words' above the mummy.
func back_rect() -> Rect2:
	if phase == Phase.WORDS:
		var size := _words.texture.get_size()
		return Rect2(_spoken - size / 2.0, size).grow(6.0)
	return _adze_home.grow(8.0)


## Where the words go: their imprint over Ra, and a margin round it.
func home_rect() -> Rect2:
	return _words_home.grow(DROP_PAD)


func mummy_rect() -> Rect2:
	return _mummy


## What lies on the stand now (it glows with the stand): the rods and the foreleg, and the adze
## unless it is in your hand.
func on_stand() -> Array:
	return _props + ([] if phase == Phase.ADZE else [_adze])


## The drawing to glow for a pick.
func glow_target(id: String):
	match id:
		"adze":
			return _adze
		"words":
			return _words
		"home":
			return _imprint
		"mummy":
			return _mummy
		"back":     # the carried piece lights up over its own place
			return _words if phase == Phase.WORDS else _adze
	return null


func take_adze() -> void:
	if phase != Phase.START:
		return
	phase = Phase.ADZE
	said.emit("Scribe", "You take the adze from the offering stand: a hooked blade on a long handle.")
	changed.emit()


func take_words() -> void:
	if phase != Phase.SPOKEN or (_tween and _tween.is_running()):
		return
	phase = Phase.WORDS
	_words.scale = Vector2.ONE
	said.emit("Scribe", "You take up the words.")
	changed.emit()


## The adze goes back on the stand, the words back above the mummy.
func put_back() -> void:
	match phase:
		Phase.ADZE:
			phase = Phase.START
			_adze.position = _adze_home.position
		Phase.WORDS:
			phase = Phase.SPOKEN
			_words.position = _spoken
		_:
			return
	changed.emit()


## Bring the adze to the mummy and enter the face-carving view.
func touch() -> void:
	if phase != Phase.ADZE or active or (_tween and _tween.is_running()):
		return
	active = true
	_clear_face()
	said.emit("Anubis", "Help me finish his face. Click along each red stroke, following the faint next chip. Three nicks disturb him. [esc] steps away.")
	changed.emit()


func _speak() -> void:
	active = false
	phase = Phase.SPOKEN
	_imprint.visible = true
	_adze.position = _adze_home.position
	_adze.scale = Vector2.ONE
	_adze.self_modulate.a = 1.0
	_words.visible = true
	said.emit("Scribe", "You touch the adze to the mummy's mouth. Its mouth opens, and words come out.")
	changed.emit()
	var size := _words.texture.get_size()
	var ball := Vector2(BALL / size.x, BALL / size.y)
	if instant:
		_words.position = _spoken
		_words.scale = Vector2.ONE
		return
	_words.position = _mouth
	_words.scale = ball * 0.3
	_words.modulate.a = 0.0
	var up := Vector2(_mouth.x, lerpf(_mouth.y, _spoken.y, 0.6))
	_tween = create_tween()
	_tween.tween_property(_words, "modulate:a", 1.0, RISE * 0.4)
	_tween.parallel().tween_property(_words, "scale", ball, RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_words, "position", up, RISE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_words, "position", _spoken, UNROLL).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_property(_words, "scale:y", 1.0, UNROLL * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_words, "scale:x", 1.0, UNROLL).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)


## The words set at their imprint over Ra: the caption as drawn.
func place_words() -> void:
	if phase != Phase.WORDS:
		return
	phase = Phase.DONE
	_words.position = _words_home.get_center()
	_words.scale = Vector2.ONE
	_imprint.visible = false
	said.emit("Scribe", "The words stand over Ra again, as they are written.")
	changed.emit()


func _process(_delta: float) -> void:
	_time += _delta
	if active:
		queue_redraw()
	# what is carried follows the pointer: the adze held at its blade, the words by their middle
	var p := get_global_mouse_position()
	_adze.z_index = 10 if phase == Phase.ADZE else 0     # what you carry comes to the front
	_adze.scale = Vector2.ONE * (CARVING_SCALE if active else 1.0)
	_adze.self_modulate.a = 0.65 if active else 1.0
	_words.z_index = 10 if phase == Phase.WORDS else 0
	match phase:
		Phase.ADZE:
			_adze.position = p - ADZE_GRIP * _adze.scale
		Phase.WORDS:
			_words.position = p


func _setup_face(level: Dictionary, nodes: Dictionary) -> void:
	_body = nodes.mouth_mummy
	_body_home = _body.position
	_mummy = Rect2(_body_home, _body.texture.get_size())
	var source_mummy: Dictionary = level.mouth.mummy
	_mouth += _body_home - Vector2(source_mummy.x, source_mummy.y)
	_features = nodes.mouth_features
	_feature_texture = _features.texture
	_feature_image = _feature_texture.get_image()
	if _feature_image.is_compressed():
		_feature_image.decompress()
	_feature_origin = _features.global_position
	var data: Dictionary = level.sprites.mouth_features
	var offset := _feature_origin - Vector2(data.x, data.y)
	var view: Dictionary = level.mouth.face_view
	_face_view = Rect2(Vector2(view.x, view.y) + offset, Vector2(view.w, view.h))
	for stroke in level.mouth.strokes:
		var curve := Curve2D.new()
		curve.bake_interval = 0.5
		for point in stroke.points:
			curve.add_point(Vector2(point[0], point[1]) + offset)
		_curves.append(curve)
		_progress.append(0.0)
	var width := _feature_image.get_width()
	_pixel_stroke.resize(width * _feature_image.get_height())
	_pixel_along.resize(_pixel_stroke.size())
	for y in _feature_image.get_height():
		for x in width:
			var point := _feature_origin + Vector2(x + 0.5, y + 0.5)
			var best := INF
			for i in _curves.size():
				var distance := point.distance_squared_to(_curves[i].get_closest_point(point))
				if distance < best:
					best = distance
					_pixel_stroke[y * width + x] = i
					_pixel_along[y * width + x] = _curves[i].get_closest_offset(point)


func face_view() -> Rect2:
	return _face_view


func next_chip(stroke: int) -> Vector2:
	return _curves[stroke].sample_baked(minf(_progress[stroke] + CHIP_STEP, _curves[stroke].get_baked_length()))


func stroke_done(stroke: int) -> bool:
	return _progress[stroke] >= _curves[stroke].get_baked_length()


## Each accepted click advances one chip on one stroke; holding/dragging never advances it.
func strike(point: Vector2) -> bool:
	if not active:
		return false
	var chosen := -1
	var nearest := CHIP_TOLERANCE * CHIP_TOLERANCE
	for i in _curves.size():
		if stroke_done(i):
			continue
		var distance := point.distance_squared_to(next_chip(i))
		if distance <= nearest:
			chosen = i
			nearest = distance
	if chosen < 0:
		_nicks.append(point)
		queue_redraw()
		if _nicks.size() >= MAX_NICKS:
			_fail()
		elif _nicks.size() == 1:
			said.emit("Anubis", "A nick. Strike just ahead of the last chip, on the red line.")
		return false
	_progress[chosen] = minf(_progress[chosen] + CHIP_STEP, _curves[chosen].get_baked_length())
	_refresh_face()
	if _progress.size() == _curves.size() and range(_curves.size()).all(stroke_done):
		_nicks.clear()
		_speak()
	queue_redraw()
	return true


func leave() -> void:
	if not active:
		return
	active = false
	_clear_face()
	said.emit("Anubis", "We can try his face again when you are ready.")
	changed.emit()


func _clear_face() -> void:
	_progress.fill(0.0)
	_nicks.clear()
	_refresh_face()
	queue_redraw()


func _refresh_face() -> void:
	var image := _feature_image.duplicate() as Image
	for y in image.get_height():
		for x in image.get_width():
			var pixel := y * image.get_width() + x
			var stroke := _pixel_stroke[pixel]
			if not stroke_done(stroke) and (_progress[stroke] == 0.0 or _pixel_along[pixel] > _progress[stroke]):
				image.set_pixel(x, y, image.get_pixel(x, y) * IMPRINT)
	_features.texture = ImageTexture.create_from_image(image)


func _fail() -> void:
	active = false
	_progress.fill(0.0)
	_refresh_face()
	said.emit("Anubis", "He stirs. Steady now. The face must be begun again.")
	changed.emit()
	if instant:
		_nicks.clear()
		_body.position = _body_home
		return
	_tween = create_tween()
	for shift in [Vector2(2, -1), Vector2(-2, 0), Vector2(1, 0), Vector2.ZERO]:
		_tween.tween_property(_body, "position", _body_home + shift, 0.08)
	_tween.tween_callback(func():
		_nicks.clear()
		queue_redraw())


func _draw() -> void:
	for point in _nicks:
		draw_circle(point, 0.9, UI.INK)
	if active:
		for i in _curves.size():
			if not stroke_done(i):
				draw_circle(next_chip(i), 1.5, Color(UI.INK * IMPRINT, 0.3 + 0.12 * sin(_time * 3.0)))
