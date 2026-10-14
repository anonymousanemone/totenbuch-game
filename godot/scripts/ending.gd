## The end of spell 15 (plate VI): set the offering stand up again before Ra, and kneel to him.
##
## The stand, the sun disc on it and the lotus bending over it are the layers of the `sprites`
## folder of art/procession1-15.mdp, cut out of the picture by tools/cut_procession300.py. They lie
## hidden along the scroll (`ending.hide` in level.json): the stand inside the canopy frame behind
## the women mourners (pl. I), the sun disc between the legs of the creature on the mummy's bier
## (pl. II; it rides with the sledge), the lotus on the second offering pile (pl. V). Once the
## other rites are done (`show_imprint`) the stela by the tomb shows a faint imprint of the three as
## they stand; until then its face is blank. A piece found is carried; at its
## place before Ra each goes on only once what it rests on is there: the stand, then the sun, then
## the lotus. The kneeling adorer before Ra is absent until the player kneels in his place; then
## light pours from Ra's disc and the new sun and floods the screen (`ended`).
class_name EndingStand
extends Node2D

signal said(who: String, text: String)
signal changed
signal ended

const PIECES := ["stand", "sun", "lotus"]
const RESTS_ON := {"stand": "", "sun": "stand", "lotus": "sun"}
const NAMES := {"stand": "the offering stand", "sun": "the sun disc", "lotus": "the lotus"}
const IMPRINT := Color(1.9, 1.0, 0.6, 0.2)   ## the imprint on the stela: faint and reddish
const IMPRINT_FADE := 1.5    ## s for the imprint to go once the stand stands
const KNEEL := 0.8           ## s for you to sink into the adorer's place
const RAYS := 1.6            ## s for the light to spread from the two suns ...
const FLOOD := 0.9           ## ... and to fill the screen
const LIGHT := preload("res://scripts/light.gdshader")

var carried: Array[String] = []   ## found, not yet at its place, in the order found
var placed := {}                  ## piece -> true once at its place
var kneeling := false
var imprint_shown := false        ## the stela shows the stand (only once the other rites are done)
var instant := false              ## the autotest: no waiting
var _data: Dictionary
var _rects := {}                  ## piece -> Rect2 where it is drawn
var _nodes := {}                  ## piece -> Sprite2D (centred)
var _sledge: Node2D               ## the bier the sun disc rides on while hidden
var _imprint: Node2D
var _kneeler: Sprite2D
var _light: ColorRect
var _light_layer: CanvasLayer
var _turn := 0.0
var _tween: Tween


func setup(level: Dictionary, art: String, sledge: Node2D) -> void:
	_data = level.ending
	_sledge = sledge
	for nm in PIECES:
		var s: Dictionary = level.sprites[nm]
		_rects[nm] = Rect2(s.x, s.y, s.w, s.h)
		var sp := Sprite2D.new()
		sp.texture = load(art % nm)
		_nodes[nm] = sp
		add_child(sp)
	# the imprint: the three as they stand, smaller, on the stela's face
	var st: Dictionary = _data.stela
	var whole: Rect2 = _rects.stand.merge(_rects.sun).merge(_rects.lotus)
	_imprint = Node2D.new()
	_imprint.scale = Vector2.ONE * st.scale
	_imprint.position = Vector2(st.cx - whole.size.x * st.scale / 2.0, st.top) - whole.position * st.scale
	_imprint.modulate = IMPRINT
	add_child(_imprint)
	move_child(_imprint, 0)
	for nm in PIECES:
		var ghost := Sprite2D.new()
		ghost.texture = _nodes[nm].texture
		ghost.centered = false
		ghost.position = _rects[nm].position
		_imprint.add_child(ghost)
	var k: Dictionary = level.sprites.kneeler
	_kneeler = Sprite2D.new()
	_kneeler.texture = load(art % "kneeler")
	_kneeler.centered = false
	_kneeler.position = Vector2(k.x, k.y)
	add_child(_kneeler)
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
	if _tween and _tween.is_valid():
		_tween.kill()
	carried.clear()
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
	var sp: Sprite2D = _nodes[nm]
	var h: Dictionary = _data.hide[nm]
	var size: Vector2 = _rects[nm].size
	var parent: Node = _sledge if h.has("on") else self
	if sp.get_parent() != parent:
		sp.reparent(parent, false)
	sp.visible = true
	sp.rotation_degrees = h.get("rot", 0.0)
	sp.scale = Vector2.ONE * h.get("scale", 1.0)
	if h.has("cx"):    # lying turned, centred on cx, resting on `bottom`
		var turned := (Transform2D(sp.rotation, Vector2.ZERO) * Rect2(-size / 2.0, size)).size * sp.scale
		sp.position = Vector2(h.cx, h.bottom - turned.y / 2.0)
	else:
		sp.position = Vector2(h.x, h.y) + size / 2.0


func _set_at_place(nm: String) -> void:
	var sp: Sprite2D = _nodes[nm]
	if sp.get_parent() != self:
		sp.reparent(self, false)
	sp.visible = true
	sp.rotation = 0.0
	sp.scale = Vector2.ONE
	sp.position = _rects[nm].get_center()


## A hidden piece under the pointer, or "place" for the stand's place before Ra (empty, part
## set up, or whole); else "".
func pick(p: Vector2) -> String:
	for nm in PIECES:
		if placed.has(nm) or nm in carried:
			continue
		var sp: Sprite2D = _nodes[nm]
		var size := sp.texture.get_size()
		var r := sp.get_global_transform() * Rect2(-size / 2.0, size)
		if r.grow(6.0).has_point(p):
			return nm
	if place_rect().has_point(p):
		return "place"
	return ""


func place_rect() -> Rect2:
	var r: Dictionary = _data.place
	return Rect2(r.x, r.y, r.w, r.h)


func sprite_of(nm: String) -> Sprite2D:
	return _nodes.get(nm)


## Where a piece is now, for walking to it.
func where(nm: String) -> Vector2:
	return _nodes[nm].global_position if nm in _nodes else place_rect().get_center()


func take(nm: String) -> void:
	if nm in carried or placed.has(nm):
		return
	carried.append(nm)
	_nodes[nm].visible = false
	match nm:
		"stand":
			said.emit("Scribe", "Inside the canopy frame stands an offering stand, on its own. It does not belong here.")
		"sun":
			said.emit("Scribe", "A sun disc sits between the creature's legs on the bier. You take it.")
		"lotus":
			said.emit("Scribe", "A lotus lies on top of the offerings, its stem bent. You take it.")
	if carried.size() + placed.size() == PIECES.size():
		said.emit("Scribe", "You carry the stand, the sun disc and the lotus." + (" The stela by the tomb shows how they stood before Ra." if imprint_shown else ""))
	changed.emit()


## At the place before Ra: set down the next carried piece that has what it rests on.
## Returns "placed", "unsupported" (nothing carried can go on yet), "empty" or "done" (already
## whole; the level says what is still wrong, if anything).
func set_down() -> String:
	if complete():
		return "done"
	if carried.is_empty():
		said.emit("Scribe", "Something stood here before Ra." + (" The stela by the tomb shows what." if imprint_shown else ""))
		return "empty"
	for nm in carried:
		var under: String = RESTS_ON[nm]
		if under == "" or placed.has(under):
			carried.erase(nm)
			placed[nm] = true
			_set_at_place(nm)
			if complete():
				said.emit("Scribe", "The stand stands before Ra again, the sun disc on it and the lotus bending over it" + (", as on the stela." if imprint_shown else "."))
				_fade_imprint()
			changed.emit()
			return "placed"
	said.emit("Scribe", "%s has nothing to rest on yet." % _cap(NAMES[carried[0]]) + (" Look at the stela: something stands beneath it." if imprint_shown else ""))
	return "unsupported"


func complete() -> bool:
	return placed.size() == PIECES.size()


func carried_name() -> String:
	return ", ".join(carried.map(func(nm): return NAMES[nm]))


func carried_texture() -> Texture2D:
	return _nodes[carried[-1]].texture if not carried.is_empty() else null


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
