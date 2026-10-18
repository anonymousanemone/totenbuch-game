## Cosmos exploration: the current MDP's cutouts, as drawn, with no puzzles or barriers.
## Saved scene nodes own placement; level.json supplies stable IDs and descriptions.
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const DATA_PATH := "res://assets/cosmos/level.json"
const VIEW_TOP := 36.0
const HIT_PAD := 4
const GLOW_FADE := 0.15

var level: Dictionary
var figures := {}             ## stable ID -> saved Sprite2D
var journal: Array[String] = []
var _images := {}
var _hover := ""
var _glow: Sprite2D
var _start := Vector2.ZERO
var _unit := 1.5

@onready var avatar: Node2D = $Avatar
@onready var camera: Camera2D = $Camera
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	level = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	_unit = level.get("scale", 1.5)
	_start = avatar.position
	avatar.speed *= _unit
	avatar.bob_height *= _unit
	for node in $Figures.find_children("*", "Sprite2D", true, false):
		if not node.has_meta("figure_id"):
			continue
		var id: String = node.get_meta("figure_id")
		assert(not figures.has(id), "Duplicate Cosmos figure ID: " + id)
		figures[id] = node
		var image: Image = node.texture.get_image()
		if image.is_compressed():
			image.decompress()
		_images[id] = image
	hud.setup(self, {
		"title": "The Night Journey",
		"journal_hint": "Click figures in the scroll to record them here.",
		"intro_title": "Spell 17: The Night Journey",
		"intro_body": "Explore the night world as it is drawn.\n\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Click a figure to walk up to it and read its description. Open the Journal with [j].",
		"outro_title": "The Night Journey",
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
	_set_hover("")
	avatar.stop()
	avatar.position = _start
	avatar.facing = -1
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	journal.clear()
	hud.reset_view()
	hud.say("Scribe", "Walk left through the night world. Click a figure to look, or open the Journal to read what you have seen.")
	_update_camera(1.0)


func hint() -> void:
	hud.say("Scribe", "Walk with [←] [→] or click the papyrus. Figures glow under the pointer; click one to read about it. The whole scroll is open to explore.")


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
	var ids: Array = figures.keys()
	ids.reverse()
	for id in ids:
		var sprite: Sprite2D = figures[id]
		if not sprite.is_visible_in_tree():
			continue
		var pixel := sprite.to_local(point) - sprite.get_rect().position
		var image: Image = _images[id]
		if not Rect2(Vector2.ZERO, image.get_size()).grow(HIT_PAD).has_point(pixel):
			continue
		for y in range(maxi(0, floori(pixel.y) - HIT_PAD), mini(image.get_height(), floori(pixel.y) + HIT_PAD + 1)):
			for x in range(maxi(0, floori(pixel.x) - HIT_PAD), mini(image.get_width(), floori(pixel.x) + HIT_PAD + 1)):
				if image.get_pixel(x, y).a > 0.1:
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
	var entry: Dictionary = level.figures[id]
	hud.say(entry.label, entry.description)
	if id not in journal:
		journal.append(id)
		hud.add_journal_entry(entry.label, entry.description, figures[id].texture, journal.size(), figures.size())


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
