## The Opening of the Mouth (plates V-VI, spell 15): touch the adze to the mummy's mouth, and
## carry the words it speaks to their place over Ra.
##
## The adze lies on the offering stand by the obelisks (the hooked blade, third from the top).
## The caption over Ra, the lotus stand and the kneeler is gone from the picture: only a faint
## imprint of it shows. Click the adze and it follows the pointer; click the mummy with it and the
## adze goes back on the stand, and the words come out of the mummy's mouth as a small ball that
## rises and unrolls into the line of signs, sitting in the empty caption band above the mummy.
## Take the line and set it at its imprint over Ra: the caption as drawn. There is no game in the
## touch itself yet (see ideas.md, "Open the mouth (the adze)").
##
## The adze and the words are the sprites mouth_adze and mouth_words, cut by
## tools/cut_procession300.py; positions (`mouth` in level.json) are strip pixels.
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
const ADZE_GRIP := Vector2(6.0, 8.0)   ## where on the adze the pointer holds it: at the blade

var phase := Phase.START
var instant := false          ## the autotest: no animation
var _adze: Sprite2D
var _words: Sprite2D          ## centred, so it can grow from a ball
var _imprint: Sprite2D
var _adze_home := Rect2()
var _words_home := Rect2()
var _spoken := Vector2.ZERO   ## the words' centre above the mummy
var _mouth := Vector2.ZERO
var _mummy := Rect2()
var _tween: Tween


func setup(level: Dictionary, art: String) -> void:
	var m: Dictionary = level.mouth
	_mouth = Vector2(m.mouth[0], m.mouth[1])
	_mummy = Rect2(m.mummy.x, m.mummy.y, m.mummy.w, m.mummy.h)
	var a: Dictionary = level.sprites.mouth_adze
	var w: Dictionary = level.sprites.mouth_words
	_adze_home = Rect2(a.x, a.y, a.w, a.h)
	_words_home = Rect2(w.x, w.y, w.w, w.h)
	_spoken = Vector2(m.speak_right - w.w / 2.0, _words_home.get_center().y)
	_imprint = Sprite2D.new()
	_imprint.texture = load(art % "mouth_words")
	_imprint.position = _words_home.get_center()
	_imprint.modulate = IMPRINT
	add_child(_imprint)
	_words = Sprite2D.new()
	_words.texture = _imprint.texture
	add_child(_words)
	_adze = Sprite2D.new()
	_adze.texture = load(art % "mouth_adze")
	_adze.centered = false
	add_child(_adze)


func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	phase = Phase.START
	_adze.position = _adze_home.position
	_adze.visible = true
	_words.visible = false
	_words.scale = Vector2.ONE
	_words.modulate.a = 1.0
	_imprint.visible = true


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
	if phase != Phase.SPOKEN:
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


## The adze touches the mummy's mouth: the adze goes back on the stand, and the words come out of
## the mouth as a ball that rises and unrolls into their line above the mummy.
func touch() -> void:
	if phase != Phase.ADZE:
		return
	phase = Phase.SPOKEN
	_adze.position = _adze_home.position
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
	# what is carried follows the pointer: the adze held at its blade, the words by their middle
	var p := get_global_mouse_position()
	_adze.z_index = 10 if phase == Phase.ADZE else 0     # what you carry comes to the front
	_words.z_index = 10 if phase == Phase.WORDS else 0
	match phase:
		Phase.ADZE:
			_adze.position = p - ADZE_GRIP
		Phase.WORDS:
			_words.position = p
