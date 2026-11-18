## The doors of the sky (spell 161): a walk level whose door swings open as you come to it, and leads into the hall.
## The two leaves swing in onto dark ink while the four Thoths lean back holding their bars (the sheets are made by
## .claude/skills/make-artwork/thoth_doors.py swing). While the door is shut the plate is the saved strip and figures. `Pieces` (the dark
## backing, the leaves and the Thoths, drawn opaque by figure.gdshader) is shown from the moment the door starts to
## open, and the flat drawings it stands in for are hidden then, though a click still reads them.
## Once it is open, light swells from a slit down the middle of the opening (the light that closes the procession),
## floods the screen, and the scene is done: the weighing of the heart comes next.
extends "res://scripts/walk/walk.gd"

const OPEN_TIME := 1.6     ## seconds from shut to fully open
const OPEN_AT := 980.0     ## the avatar's x at which the door opens: walking left, just short of the right bar
const WAIT := 0.4          ## s between the door standing open and the light
const RAYS := 1.6          ## s for the light to spread from the slit ...
const FLOOD := 0.9         ## ... and to fill the screen
const SLIT := preload("res://scripts/doors/slit_light.gdshader")
## The figures the leaves and the Thoths' sheets stand in for once the door moves.
const REPLACED := [
	"spell161_thoth_1", "spell161_thoth_2", "spell161_thoth_3", "spell161_thoth_4",
	"spell161_thoth_1_caption", "spell161_thoth_2_caption", "spell161_thoth_3_caption", "spell161_thoth_4_caption",
	"spell161_door_1_caption", "spell161_door_2_caption", "spell161_door_3_caption", "spell161_door_4_caption",
]

var opened := false
var _tween: Tween
var _slit: Rect2               ## the opening's middle line (world px): x, and its top and bottom
var _turn := 0.0
var _light: ColorRect

@onready var pieces: Node2D = $Pieces


func _ready() -> void:
	var behind: ColorRect = $Pieces/Door/Behind
	_slit = Rect2(behind.position.x + behind.size.x / 2.0, behind.position.y, 0.0, behind.size.y)
	var layer := CanvasLayer.new()
	layer.layer = 100          # over the HUD too
	add_child(layer)
	_light = ColorRect.new()
	_light.set_anchors_preset(Control.PRESET_FULL_RECT)
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SLIT
	_light.material = mat
	layer.add_child(_light)
	super()


func reset() -> void:
	super()
	shut()


## Back to the plate as drawn.
func shut() -> void:
	opened = false
	if _tween:
		_tween.kill()
	pieces.visible = false
	_show_frame(0.0)
	for id in REPLACED:
		figures[id].self_modulate.a = 1.0
	_light.visible = false
	_set_light(0.0, 0.0)
	avatar.keys = true


## The door swings open; then the light comes through it and the scene is done.
func open() -> void:
	opened = true
	avatar.stop()
	avatar.keys = false
	pieces.visible = true
	for id in REPLACED:
		figures[id].self_modulate.a = 0.0
	var last: int = _sheets()[0].hframes - 1
	_tween = create_tween()
	_tween.tween_method(_show_frame, 0.0, float(last), OPEN_TIME)
	_tween.tween_interval(WAIT)
	_tween.tween_callback(func(): _light.visible = true)
	_tween.tween_method(func(v): _set_light(v, 0.0), 0.0, 1.0, RAYS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_method(func(v): _set_light(1.0, v), 0.0, 1.0, FLOOD).set_ease(Tween.EASE_IN)
	_tween.tween_interval(0.4)
	_tween.tween_callback(_done)


func _unhandled_input(event: InputEvent) -> void:
	if opened:                  # the door and the light play out; nothing to walk to or read
		return
	super(event)


func _done() -> void:
	if get_tree().current_scene == self:       # not when a test has the scene
		Scroll.finish(level_key)


func _process(delta: float) -> void:
	super(delta)
	if not opened and avatar.position.x <= OPEN_AT:
		open()
	if _light.visible:
		_turn += delta
		var vp := get_viewport_rect().size
		var to_screen := get_viewport().get_canvas_transform()
		var top := to_screen * _slit.position / vp
		var bottom := to_screen * (_slit.position + Vector2(0.0, _slit.size.y)) / vp
		var mat := _light.material as ShaderMaterial
		mat.set_shader_parameter("slit_x", top.x)
		mat.set_shader_parameter("slit_top", top.y)
		mat.set_shader_parameter("slit_bottom", bottom.y)
		mat.set_shader_parameter("aspect", vp.x / vp.y)
		mat.set_shader_parameter("turn", _turn)


func _set_light(spread: float, flood: float) -> void:
	var mat := _light.material as ShaderMaterial
	mat.set_shader_parameter("spread", spread)
	mat.set_shader_parameter("flood", flood)


func _show_frame(frame: float) -> void:
	for sheet in _sheets():
		sheet.frame = roundi(frame)


func _sheets() -> Array:
	return pieces.find_children("*", "Sprite2D", true, false)
