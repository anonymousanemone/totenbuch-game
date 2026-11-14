## A walk-only level: one lane to explore as drawn, with no puzzles or barriers (the Fourteen Mounds, Mouth and Heart).
## Saved scene nodes own placement; level.json supplies stable IDs and the camera's rows. The scene sets `level_key`
## (its assets/<level_key>/ folder) and the title and introduction shown by the HUD.
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const GLOW_FADE := 0.15

@export var level_key := ""
@export var title := ""
@export var intro_title := ""
@export_multiline var intro_body := ""

var _descriptions
var level: Dictionary
var figures := {}             ## stable ID -> saved Sprite2D
var journal: Array[String] = []
var _hints = preload("res://scripts/puzzles.gd").new()
var _hover := ""
var _glow: Sprite2D
var _start := Vector2.ZERO
var _unit := 1.5

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string("res://assets/%s/level.json" % level_key))
	_descriptions = preload("res://scripts/descriptions.gd").new(level_key)
	_unit = level.get("scale", 1.5)
	_start = avatar.position
	avatar.speed *= _unit
	avatar.bob_height *= _unit
	_descriptions.use_boxes($Hitboxes)
	for node in $Figures.find_children("*", "Sprite2D", true, false):
		if not node.has_meta("registry_id"):
			continue
		var id: String = node.get_meta("registry_id")
		assert(not figures.has(id), "Duplicate figure ID: " + id)
		figures[id] = node
	hud.setup(self, {
		"title": title,
		"journal_hint": "Click anything drawn in the scroll to record it here.",
		"intro_title": intro_title,
		"intro_body": intro_body,
		"outro_title": title,
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	reset()


func min_x() -> float:
	return 60.0 * _unit


func max_x() -> float:
	return level.width - 60.0 * _unit


func reset() -> void:
	_hints.reset()
	_set_hover("")
	avatar.stop()
	avatar.position = _start
	avatar.facing = -1
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	journal.clear()
	hud.reset_view()
	hud.say("Scribe", _hints.message("view.start" if Scroll.viewing else "walk.start"))
	_update_camera(1.0)


func hint() -> void:
	hud.say("Hint", _hints.message("view.hint" if Scroll.viewing else "walk.explore"))


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking():
		return
	if event is InputEventMouseMotion:
		_set_hover(_pick(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point := get_global_mouse_position()
		var id := _pick(point)
		if id == "":
			walk_then(point.x)
		else:
			var bounds: Rect2 = figures[id].global_transform * figures[id].get_rect()
			var destination: float = avatar.reach(bounds)
			walk_then(destination, record.bind(id))


func walk_then(x: float, then := Callable()) -> void:
	avatar.walk_to(clampf(x, min_x(), max_x()), then)


## Check the visible ink with a small tolerance, including overlaps and transparent cutouts.
func _pick(point: Vector2) -> String:
	var ids: Array = figures.keys()
	ids.reverse()
	for id in ids:
		if _descriptions.hit(figures[id], point):
			return id
	return ""


func _set_hover(id: String) -> void:
	if id == _hover:
		return
	_hover = id
	if is_instance_valid(_glow):
		_glow.queue_free()
		_glow = null
	if id != "":
		_glow = UI.sprite_glow(figures[id], UI.Glow.PROCESSION)
		_glow.create_tween().tween_method(func(strength: float):
			if is_instance_valid(_glow):
				(_glow.material as ShaderMaterial).set_shader_parameter("strength", strength), 0.0, 1.0, GLOW_FADE)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if id != "" else Input.CURSOR_ARROW)


func record(id: String) -> void:
	_descriptions.inspect(id, hud, journal, figures[id].texture, figures.size())


func _process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	var viewport := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var view_top: float = level.view_top
	var zoom := SCROLL_CAMERA.fit_zoom(viewport, top, bottom, level.view_height,
		_unit, 0.4 / _unit, 2.4 / _unit, view_top)
	camera.zoom = Vector2(zoom, zoom)
	var target: float = level.width / 2.0     # the whole scroll fits the view (the hall): keep it centred
	if viewport.x / zoom < level.width:
		target = SCROLL_CAMERA.clamp_horizontal(avatar.position.x - viewport.x / zoom * 0.05,
			viewport.x / zoom, level.width)
	camera.position.x = lerpf(camera.position.x, target, SCROLL_CAMERA.smoothing(delta))
	camera.position.y = SCROLL_CAMERA.vertical_center(level.view_height, top, bottom, zoom, view_top)
