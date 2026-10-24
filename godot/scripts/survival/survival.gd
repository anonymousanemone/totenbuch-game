## Shared navigation and inspection for the Survival and Gates scrolls.
## Saved scene nodes own placement; level.json supplies stable IDs and descriptions.
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
@export var level_key := "survival"
const VIEW_TOP := 36.0
const GLOW_FADE := 0.15

var _descriptions: RefCounted
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
	_descriptions = preload("res://scripts/descriptions.gd").new(level_key)
	level = JSON.parse_string(FileAccess.get_file_as_string("res://assets/%s/level.json" % level_key))
	var chapter: Dictionary = Scroll.scene(level_key)
	_unit = level.get("scale", 1.5)
	_start = avatar.position
	avatar.speed *= _unit
	avatar.bob_height *= _unit
	for node in $Figures.find_children("*", "Sprite2D", true, false):
		if not node.has_meta("registry_id"):
			continue
		var id: String = node.get_meta("registry_id")
		assert(not figures.has(id), "Duplicate exploration figure ID: " + id)
		figures[id] = node
	# Only artwork present in this scene counts toward its journal.
	for id in _descriptions.entries.keys():
		if not figures.has(id):
			_descriptions.entries.erase(id)
	hud.setup(self, {
		"title": chapter.title,
		"journal_hint": "Click figures in the scroll to record them here.",
		"intro_title": "%s %s: %s" % ["Spell" if str(chapter.spells).is_valid_int() else "Spells", chapter.spells, chapter.title],
		"intro_body": level.get("intro_body", "Explore the scroll of food, water and breath as it is drawn.\n\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Click a figure to walk up to it and read its description. Open the Journal with [j]."),
		"outro_title": chapter.title,
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	reset()
	_development_args()


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
	hud.say("Scribe", _hints.message(level_key + ".start"))
	_update_camera(1.0)


func hint() -> void:
	hud.say("Hint", _hints.message(level_key + ".explore"))


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
			var x: float = avatar.position.x
			var destination := point.x if x >= bounds.position.x and x <= bounds.end.x else clampf(x, bounds.position.x, bounds.end.x)
			walk_then(destination, record.bind(id))


func walk_then(x: float, then := Callable()) -> void:
	avatar.walk_to(clampf(x, min_x(), max_x()), then)


## Check the visible ink with a small tolerance, including overlaps and transparent cutouts.
func _pick(point: Vector2) -> String:
	for column in $Foreground.get_children():
		var paper: ColorRect = column.get_node("Papyrus")
		if (paper.get_global_transform() * paper.get_rect()).has_point(point):
			return ""
	var ids: Array = figures.keys()
	ids.reverse()
	for id in ids:
		var sprite: Sprite2D = figures[id]
		if _descriptions.hit(sprite, point):
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
	_descriptions.inspect(id, hud, journal, figures[id].texture, _descriptions.journal_total())


func _process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	var viewport := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var zoom := SCROLL_CAMERA.fit_zoom(viewport, top, bottom, level.view_height,
		_unit, 0.4 / _unit, 2.4 / _unit, VIEW_TOP)
	camera.zoom = Vector2(zoom, zoom)
	var target := SCROLL_CAMERA.clamp_horizontal(avatar.position.x - viewport.x / zoom * 0.05,
		viewport.x / zoom, level.width)
	camera.position.x = lerpf(camera.position.x, target, SCROLL_CAMERA.smoothing(delta))
	camera.position.y = SCROLL_CAMERA.vertical_center(level.view_height, top, bottom, zoom, VIEW_TOP)


## Development previews use the same saved scene and camera as normal play.
func _development_args() -> void:
	var screenshot := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--at="):
			avatar.position.x = clampf(float(argument.trim_prefix("--at=")), min_x(), max_x())
		elif argument.begins_with("--screenshot="):
			screenshot = argument.trim_prefix("--screenshot=")
	if screenshot != "":
		hud.dismiss_intro()
		_update_camera(1.0)
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(screenshot)
		get_tree().quit()
