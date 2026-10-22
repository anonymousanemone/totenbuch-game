## The Opening of the Mouth (plates V-VI, spell 15): touch the adze to the mummy's mouth, and
## carry the words it speaks to their place over Ra.
##
## With the adze, finish the mouth and the eye a chip at a time. The adze is held by the end of its
## handle; a click brings it down a little (it turns about the pointer) and chips where the tip of its
## blade is. Strikes anywhere within either feature advance it; misses leave progress alone.
## The original word-carrying sequence follows success. Face pixels are cut into mouth/features;
## the beard stays as drawn. Reveal paths and positions come from level.json.
class_name OpeningMouth
extends Node2D

const PUZZLES := preload("res://scripts/puzzles.gd")

signal said(who: String, text: String)
signal changed

enum Phase { START, ADZE, SPOKEN, WORDS, DONE }

const IMPRINT := UI.PREVIEW   ## the words' imprint over Ra: faint and reddish, like the stela's
const BALL := 44.0            ## strip px across: the words as they leave the mouth
const RISE := 0.6             ## s for the ball to rise out of the mouth ...
const UNROLL := 0.9           ## ... and to unroll into the line of signs
const DROP_PAD := 40.0        ## strip px round the imprint that still take the line
const CHIP_STEP := 3.0
const CARVING_SCALE := 0.5   ## keep the carried handle clear of the small face
const ADZE_GRIP := Vector2(83.0, 37.0)  ## where on the adze the pointer holds it: the end of its handle
const ADZE_TIP := Vector2(4.0, 27.0)    ## the tip of its blade, where it chips
const SWING := 0.08           ## rad the adze comes down about the pointer on a click ...
const SWING_TIME := 0.12      ## ... and goes back up, over this long
const FAR := 4.0              ## face pixels further than this from both strokes are not carved

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
var _feature_bounds: Array[Rect2] = []
var _swing := 0.0             ## how far down the adze is now (0..1)
var phase := Phase.START
var instant := false          ## the autotest: no animation
var _avatar: Node2D
var _adze: Sprite2D
var _props: Array             ## the rest of what lies on the stand with the adze: two rods and a foreleg
var _words: Sprite2D          ## centred, so it can grow from a ball
var _imprint: Sprite2D
var _adze_home := Rect2()
var adze_object: MoveableObject
var words_object: MoveableObject

var _adze_home_transform := Transform2D.IDENTITY
var _adze_carry_pose := Transform2D.IDENTITY
var _words_home := Rect2()
var _spoken := Vector2.ZERO   ## the words' centre above the mummy
var _mouth := Vector2.ZERO
var _mummy := Rect2()
var _tween: Tween


func setup(level: Dictionary, nodes: Dictionary, avatar: Node2D) -> void:
	_avatar = avatar
	var m: Dictionary = level.mouth
	_mouth = Vector2(m.mouth[0], m.mouth[1])
	_mummy = Rect2(m.mummy.x, m.mummy.y, m.mummy.w, m.mummy.h)
	_adze = nodes.mouth_adze
	_props = [nodes.mouth_column, nodes.mouth_spoon]
	_words = nodes.mouth_words
	_imprint = nodes.words_imprint
	_adze_home = Rect2(_adze.position, _adze.texture.get_size())
	_adze_home_transform = _adze.transform
	_adze_carry_pose = (_avatar.get_node("CarryAdze") as Marker2D).transform
	_words_home = Rect2(_words.position - _words.texture.get_size() / 2.0, _words.texture.get_size())
	_spoken = Vector2(m.speak_right - _words_home.size.x / 2.0, _words_home.get_center().y)
	adze_object = MoveableObject.new()
	add_child(adze_object)
	adze_object.setup("mouth_adze", _adze)
	adze_object.carriable = true
	words_object = MoveableObject.new()
	add_child(words_object)
	words_object.setup("mouth_words", _words)
	words_object.transport_mode = MoveableObject.TransportMode.CLICK_FOLLOW
	words_object.from_loc_transform.origin = _spoken
	words_object.set_to_loc(_words.get_parent(), Transform2D(0.0, _words_home.get_center()), 0)
	_setup_face(level, nodes)


func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	adze_object.reset()
	words_object.reset()
	active = false
	phase = Phase.START
	_body.position = _body_home
	_clear_face()
	_adze.transform = _adze_home_transform
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
	adze_object.wear(_avatar, _adze_carry_pose)
	said.emit("Scribe", PUZZLES.text("procession.opening_mouth", "feedback", "adze_taken"))
	changed.emit()


func take_words() -> void:
	if phase != Phase.SPOKEN or (_tween and _tween.is_running()):
		return
	phase = Phase.WORDS
	words_object.hold()
	_words.scale = Vector2.ONE
	said.emit("Scribe", PUZZLES.text("procession.opening_mouth", "feedback", "words_taken"))
	changed.emit()


## The adze goes back on the stand, the words back above the mummy.
func put_back() -> void:
	match phase:
		Phase.ADZE:
			adze_object.reset()
			phase = Phase.START
			_adze.transform = _adze_home_transform
			_adze.self_modulate.a = 1.0
		Phase.WORDS:
			words_object.reset()
			phase = Phase.SPOKEN
			_words.position = _spoken
		_:
			return
	changed.emit()


## Bring the adze to the mummy and enter the face-carving view.
func touch() -> void:
	if phase != Phase.ADZE or active or (_tween and _tween.is_running()):
		return
	adze_object.interaction_mode = MoveableObject.InteractionMode.TOOL_USE
	active = true
	_clear_face()
	said.emit("Anubis", PUZZLES.text("procession.opening_mouth", "instructions"))
	changed.emit()


func _speak() -> void:
	active = false
	phase = Phase.SPOKEN
	adze_object.reset()
	_imprint.visible = true
	_adze.transform = _adze_home_transform
	_adze.self_modulate.a = 1.0
	_words.visible = true
	said.emit("Scribe", PUZZLES.text("procession.opening_mouth", "feedback", "success_opened"))
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
	words_object.place()
	words_object.lock_in_place()
	_words.position = _words_home.get_center()
	_words.scale = Vector2.ONE
	_imprint.visible = false
	said.emit("Scribe", PUZZLES.text("procession.opening_mouth", "success"))
	changed.emit()


func _process(_delta: float) -> void:
	# The adze sits on the player until carving; words keep following the pointer.
	var p := get_global_mouse_position()
	_adze.z_index = 10 if phase == Phase.ADZE else 0     # what you carry comes to the front
	_adze.scale = Vector2.ONE * (CARVING_SCALE if active else 1.0)
	_adze.self_modulate.a = 0.65 if active else 1.0
	_words.z_index = 10 if phase == Phase.WORDS else 0
	_swing = maxf(0.0, _swing - _delta / SWING_TIME)
	match phase:
		Phase.ADZE:
			if active:   # held by its handle: it turns about the pointer as it comes down
				_adze.rotation = -SWING * sin(_swing * PI)
				_adze.position = p - (ADZE_GRIP * _adze.scale).rotated(_adze.rotation)
			else:
				adze_object.follow()
		Phase.WORDS:
			words_object.move_held(p)


func _setup_face(level: Dictionary, nodes: Dictionary) -> void:
	_body = nodes.mouth_mummy
	_body_home = _body.position
	_mummy = preload("res://scripts/descriptions.gd").sprite_bounds(_body)
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
			var best := FAR * FAR
			_pixel_stroke[y * width + x] = -1      # not part of either stroke: stays as drawn
			for i in _curves.size():
				var distance := point.distance_squared_to(_curves[i].get_closest_point(point))
				if distance <= best:
					best = distance
					_pixel_stroke[y * width + x] = i
					_pixel_along[y * width + x] = _curves[i].get_closest_offset(point)

	# Bounds come from the actual cutout pixels assigned to each feature, not a moving target.
	for i in _curves.size():
		var bounds := Rect2(_curves[i].get_point_position(0), Vector2.ZERO)
		for y in _feature_image.get_height():
			for x in width:
				if _pixel_stroke[y * width + x] == i and _feature_image.get_pixel(x, y).a > 0.0:
					var point := _feature_origin + Vector2(x, y)
					bounds = bounds.expand(point).expand(point + Vector2.ONE)
		_feature_bounds.append(bounds)


func face_view() -> Rect2:
	return _face_view


## Where the visible blade tip is when the handle is held at the pointer.
func tip_at(p: Vector2) -> Vector2:
	return p + ((ADZE_TIP - ADZE_GRIP) * (CARVING_SCALE if active else 1.0)).rotated(_adze.rotation)


## A click while carving: the adze comes down a little about the pointer and chips at its tip.
func chop(p: Vector2) -> bool:
	_swing = 1.0
	return strike(tip_at(p))


func next_chip(stroke: int) -> Vector2:
	return _curves[stroke].sample_baked(minf(_progress[stroke] + CHIP_STEP, _curves[stroke].get_baked_length()))


func stroke_done(stroke: int) -> bool:
	return _progress[stroke] >= _curves[stroke].get_baked_length()


## Each accepted click advances one chip on one stroke; holding/dragging never advances it.
func strike(point: Vector2) -> bool:
	if not active:
		return false
	var chosen := -1
	for i in _feature_bounds.size():
		if not stroke_done(i) and _feature_bounds[i].has_point(point):
			chosen = i
			break
	if chosen < 0:
		return false
	_progress[chosen] = minf(_progress[chosen] + CHIP_STEP, _curves[chosen].get_baked_length())
	_refresh_face()
	if _progress.size() == _curves.size() and range(_curves.size()).all(stroke_done):
		_speak()
	return true


func leave() -> void:
	if not active:
		return
	active = false
	adze_object.interaction_mode = MoveableObject.InteractionMode.TRANSPORT
	adze_object.follow()
	_clear_face()
	said.emit("Anubis", PUZZLES.text("procession.opening_mouth", "feedback", "left_carving"))
	changed.emit()


func _clear_face() -> void:
	_progress.fill(0.0)
	_refresh_face()


func _refresh_face() -> void:
	var image := _feature_image.duplicate() as Image
	for y in image.get_height():
		for x in image.get_width():
			var pixel := y * image.get_width() + x
			var stroke := _pixel_stroke[pixel]
			if stroke >= 0 and not stroke_done(stroke) and (_progress[stroke] == 0.0 or _pixel_along[pixel] > _progress[stroke]):
				image.set_pixel(x, y, image.get_pixel(x, y) * IMPRINT)
	_features.texture = ImageTexture.create_from_image(image)
