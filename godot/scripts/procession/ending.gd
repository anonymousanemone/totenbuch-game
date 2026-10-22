## The end of spell 15 (plate VI): set the offering stand up again before Ra, and kneel to him.
##
## The stand, the sun disc on it and the lotus bending over it are the layers of the `sprites`
## folder of art/procession1-15.mdp, cut out of the picture by tools/cut_procession300.py. They lie
## hidden along the scroll (`ending.hide` in level.json): the stand inside the canopy frame behind
## the women mourners (pl. I), the sun disc between the legs of the creature on the mummy's bier
## (pl. II; it rides with the sledge), the lotus on the second offering pile (pl. V). Once the
## other rites are done (`show_imprint`) the stela by the tomb shows a faint imprint of the three as
## they stand; until then its face is blank. A piece found is worn: it goes onto you, posed as in
## WORN (the stand held before you, the sun disc on your head, the lotus over your shoulder),
## mirrored as you turn. Take one off you (drag it) and it
## follows the pointer, one at a time; let go of it on its place before Ra and it goes on there,
## anywhere else and it goes back onto you. Each goes on only once what it rests on is there: the
## stand, then the sun, then the lotus. The kneeling adorer before Ra is absent until the player
## kneels in his place; then light pours from Ra's disc and the new sun and floods the screen
## (`ended`).
class_name EndingStand
extends Node2D

const PUZZLES := preload("res://scripts/puzzles.gd")

signal said(who: String, text: String)
signal changed
signal ended

const PIECES := ["stand", "sun", "lotus"]
const RESTS_ON := {"stand": "", "sun": "stand", "lotus": "sun"}
const NAMES := {"stand": "the offering stand", "sun": "the sun disc", "lotus": "the lotus"}
## Who speaks for a piece (the tag over what is said about it).
const TAGS := {"stand": "Offering stand", "sun": "Sun disc", "lotus": "Lotus"}
const IMPRINT := UI.PREVIEW   ## the imprint on the stela: faint and reddish
const IMPRINT_FADE := 1.5    ## s for the imprint to go once the stand stands
const KNEEL := 0.8           ## s for you to sink into the adorer's place
const RAYS := 1.6            ## s for the light to spread from the two suns ...
const FLOOD := 0.9           ## ... and to fill the screen
const LIGHT := preload("res://scripts/procession/light.gdshader")
## Where each piece sits on you, from your feet (strip px, you facing left as drawn): its centre,
## turn (rad), scale and whether it is mirrored. Posed in the editor on a copy of the avatar
## (2026-10-15).
const WORN := {
	"stand": {"at": Vector2(-36.0, -172.0), "turn": 0.0, "scale": 1.0, "flip": false},
	"sun": {"at": Vector2(32.0, -314.0), "turn": 0.0, "scale": 1.0, "flip": false},
	"lotus": {"at": Vector2(66.0, -235.0), "turn": 0.5323, "scale": 1.0, "flip": true},
}

var objects := {}

var worn: Array[String] = []      ## found, on you, not yet at its place
var held := ""                    ## the piece taken off you, following the pointer
var placed := {}                  ## piece -> true once at its place
var kneeling := false
var imprint_shown := false        ## the stela shows the stand (only once the other rites are done)
var instant := false              ## the autotest: no waiting
var _data: Dictionary
var _rects := {}                  ## piece -> Rect2 where it is drawn
var _nodes := {}                  ## piece -> Sprite2D (centred)
var _avatar: Node2D
var _imprint: Node2D
var _kneeler: Sprite2D
var _light: ColorRect
var _light_layer: CanvasLayer
var _turn := 0.0
var _tween: Tween
var _base_clue: Sprite2D
var _base_clue_tween: Tween


func setup(level: Dictionary, nodes: Dictionary, avatar: Node2D) -> void:
	_data = level.ending
	_avatar = avatar
	for nm in PIECES:
		var sp: Sprite2D = nodes[nm]
		_nodes[nm] = sp
		var target: Sprite2D = nodes[nm + "_place"]
		_rects[nm] = Rect2(target.position, target.texture.get_size())
		var item := MoveableObject.new()
		add_child(item)
		item.setup(nm, sp)
		item.carriable = true
		item.set_to_loc(self, Transform2D(0.0, _rects[nm].get_center()), 0)
		objects[nm] = item
	_base_clue = Sprite2D.new()
	_base_clue.texture = _nodes.stand.texture
	_base_clue.centered = false
	_base_clue.position = _rects.stand.position
	_base_clue.modulate = IMPRINT
	_base_clue.visible = false
	add_child(_base_clue)
	_imprint = nodes.stela_imprint
	_kneeler = nodes.kneeler
	_light_layer = CanvasLayer.new()
	_light_layer.layer = 100      # over the HUD too
	add_child(_light_layer)
	_light = ColorRect.new()
	_light.set_anchors_preset(Control.PRESET_FULL_RECT)
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = LIGHT
	_light.material = mat
	_light_layer.add_child(_light)


func reset() -> void:
	_clear_base_clue()
	if _tween and _tween.is_valid():
		_tween.kill()
	worn.clear()
	held = ""
	placed.clear()
	kneeling = false
	imprint_shown = false
	for nm in PIECES:
		_hide(nm)
	_imprint.visible = false
	_imprint.modulate = IMPRINT
	_kneeler.visible = false
	_kneeler.modulate.a = 1.0
	_light.visible = false
	_set_light(0.0, 0.0)


## Where a piece lies hidden: on the scroll, or (the sun disc) on the bier.
func _hide(nm: String) -> void:
	objects[nm].reset()
	_nodes[nm].visible = true


func _set_at_place(nm: String) -> void:
	_nodes[nm].flip_h = false
	objects[nm].place()
	objects[nm].lock_in_place()
	_nodes[nm].visible = true


## A hidden piece under the pointer, or "place" for the stand's place before Ra (empty, part set
## up, or whole); else "".
func pick(p: Vector2) -> String:
	for nm in PIECES:
		if not placed.has(nm) and not nm in worn and nm != held and rect_of(nm).has_point(p):
			return nm
	if place_rect().has_point(p):
		return "place"
	return ""


## A piece on you under the pointer, or "".
func worn_at(p: Vector2) -> String:
	for nm in worn:
		if rect_of(nm).has_point(p):
			return nm
	return ""


## The box round a piece's drawing where it is now (world px).
func rect_of(nm: String) -> Rect2:
	return preload("res://scripts/descriptions.gd").sprite_bounds(_nodes[nm])


func place_rect() -> Rect2:
	var r: Dictionary = _data.place
	return Rect2(r.x, r.y, r.w, r.h)


func sprite_of(nm: String) -> Sprite2D:
	return _nodes.get(nm)


## Where a piece is now, for walking to it.
func where(nm: String) -> Vector2:
	return _nodes[nm].global_position if nm in _nodes else place_rect().get_center()


## Take a piece from where it lies hidden: it goes onto you.
func take(nm: String) -> void:
	if nm in worn or nm == held or placed.has(nm):
		return
	worn.append(nm)
	var sp: Sprite2D = _nodes[nm]
	sp.reparent(self, false)
	sp.z_index = 5    # over you: you hold it
	sp.flip_h = WORN[nm].flip
	objects[nm].wear(_avatar, pose(nm))
	_follow()
	changed.emit()


## Take a piece off you: it follows the pointer.
func hold(nm: String) -> void:
	if held != "" or not nm in worn:
		return
	objects[nm].hold()
	worn.erase(nm)
	held = nm
	_nodes[nm].z_index = 10
	_follow()
	changed.emit()


## The piece in hand goes back onto you.
func unhold() -> void:
	if held == "":
		return
	objects[held].cancel_hold()
	worn.append(held)
	_nodes[held].z_index = 5
	held = ""
	_follow()
	changed.emit()


## At the place before Ra: set down the piece in hand, or (with none) the first piece on you that
## has what it rests on. A piece in hand that can't go on yet goes back onto you.
## Returns "placed", "unsupported" (nothing can go on yet), "empty" or "done" (already whole; the
## level says what is still wrong, if anything).
func set_down() -> String:
	if complete():
		return "done"
	var choice: Array = [held] if held != "" else worn.duplicate()
	if choice.is_empty():
		said.emit("Scribe", (PUZZLES.text("procession.offering_stand", "feedback", "instructions_stela") if imprint_shown else PUZZLES.text("procession.offering_stand", "instructions")))
		return "empty"
	for nm in choice:
		var under: String = RESTS_ON[nm]
		if under == "" or placed.has(under):
			worn.erase(nm)
			if nm == held:
				held = ""
			if nm == "stand":
				_clear_base_clue()
			placed[nm] = true
			_set_at_place(nm)
			if complete():
				said.emit("Scribe", (PUZZLES.text("procession.offering_stand", "feedback", "success_stela") if imprint_shown else PUZZLES.text("procession.offering_stand", "success")))
				_fade_imprint()
			changed.emit()
			return "placed"
	said.emit(TAGS[choice[0]], PUZZLES.text("procession.offering_stand", "feedback", "unsupported_stela" if imprint_shown else "unsupported") % _cap(NAMES[choice[0]]))
	unhold()
	return "unsupported"


## Ra points out the stand's foundation while a part is carried or worn.
func show_base_clue() -> void:
	if placed.has("stand") or (held == "" and worn.is_empty()):
		return
	_clear_base_clue()
	_base_clue.visible = true
	_base_clue.modulate = Color(IMPRINT, 0.0)
	_base_clue_tween = create_tween()
	_base_clue_tween.tween_property(_base_clue, "modulate:a", IMPRINT.a, 0.3)
	_base_clue_tween.tween_interval(2.5)
	_base_clue_tween.tween_property(_base_clue, "modulate:a", 0.0, 0.6)
	_base_clue_tween.tween_callback(func(): _base_clue.visible = false)


func _clear_base_clue() -> void:
	if _base_clue_tween and _base_clue_tween.is_valid():
		_base_clue_tween.kill()
	_base_clue.visible = false


func complete() -> bool:
	return placed.size() == PIECES.size()


## Where piece `nm` sits on you, from your feet as drawn.
static func pose(nm: String) -> Transform2D:
	var w: Dictionary = WORN[nm]
	return Transform2D(w.turn, Vector2(w.scale, w.scale), 0.0, w.at)


func held_name() -> String:
	return NAMES.get(held, "")


## The pieces on you sit where they are posed, mirrored as you turn and bobbing as you walk; the
## one in hand is at the pointer.
func _follow() -> void:
	for nm in worn:
		objects[nm].follow()
	if held != "":
		objects[held].move_held(get_global_mouse_position())


## Where you kneel: the adorer's place before Ra.
func kneel_x() -> float:
	return _data.kneel


## You sink into the adorer's place; light pours from Ra's disc and the new sun, floods the
## screen, and `ended` fires.
func kneel(avatar: CanvasItem) -> void:
	if kneeling:
		return
	kneeling = true
	_kneeler.visible = true
	_kneeler.modulate.a = 0.0
	_light.visible = true
	_set_light(0.0, 0.0)
	if instant:
		avatar.visible = false
		_kneeler.modulate.a = 1.0
		ended.emit()
		return
	_tween = create_tween()
	_tween.tween_property(avatar, "modulate:a", 0.0, KNEEL)
	_tween.parallel().tween_property(_kneeler, "modulate:a", 1.0, KNEEL)
	_tween.tween_interval(0.2)
	_tween.tween_method(func(v): _set_light(v, 0.0), 0.0, 1.0, RAYS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_method(func(v): _set_light(1.0, v), 0.0, 1.0, FLOOD).set_ease(Tween.EASE_IN)
	_tween.tween_interval(0.4)
	_tween.tween_callback(ended.emit)


## The other rites are done: the imprint of the stand comes up faintly on the stela (unless the
## stand already stands before Ra).
func show_imprint() -> void:
	if imprint_shown or complete():
		return
	imprint_shown = true
	_imprint.visible = true
	_imprint.modulate = IMPRINT
	if instant:
		return
	_imprint.modulate.a = 0.0
	create_tween().tween_property(_imprint, "modulate:a", IMPRINT.a, IMPRINT_FADE)


func _fade_imprint() -> void:
	if not _imprint.visible:
		return
	if instant:
		_imprint.visible = false
		return
	var t := create_tween()
	t.tween_property(_imprint, "modulate:a", 0.0, IMPRINT_FADE)
	t.tween_callback(func(): _imprint.visible = false)


func _set_light(spread: float, flood: float) -> void:
	var mat := _light.material as ShaderMaterial
	mat.set_shader_parameter("spread", spread)
	mat.set_shader_parameter("flood", flood)


func _process(delta: float) -> void:
	_follow()
	if not _light.visible:
		return
	_turn += delta
	# the two suns, where they are on screen now
	var vp := get_viewport_rect().size
	var to_screen := get_viewport().get_canvas_transform()
	var mat := _light.material as ShaderMaterial
	var ra: Array = _data.ra_disc
	mat.set_shader_parameter("sun_a", to_screen * Vector2(ra[0], ra[1]) / vp)
	mat.set_shader_parameter("sun_b", to_screen * _rects.sun.get_center() / vp)
	mat.set_shader_parameter("aspect", vp.x / vp.y)
	mat.set_shader_parameter("turn", _turn)


func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)
