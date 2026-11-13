## The Field of Offerings (spell 110, pl. XL–XLII), explored as drawn: no puzzles, no barriers.
## The picture is three registers framed by water, with the page's floor (`base`) under them. The camera
## shows one lane at a time and the avatar walks its ground line from one end of the scroll to the other;
## up and down arrows, or a click on the water above or below, take it across to the next lane.
## Saved scene nodes own placement; level.json supplies the lanes, the page and the foreground columns.
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const PUZZLES := preload("res://scripts/puzzles.gd")
const DATA_PATH := "res://assets/field/level.json"
const GLOW_FADE := 0.15
const CROSS_SECONDS := 0.9
const MARGIN := 60.0              ## how far from the page edges the avatar stops, in avatar units
const WATER_CLICK := 8.0          ## rows under the ground line that still count as the water below

var _descriptions = preload("res://scripts/descriptions.gd").new("field")
var level: Dictionary
var figures := {}                 ## stable ID -> saved Sprite2D
var journal: Array[String] = []
var lane := 0                     ## the lane being walked: an index into level.lanes
var _crossing := false
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
	_descriptions.use_boxes($Hitboxes)
	for node in $Figures.find_children("*", "Sprite2D", true, false):
		if not node.has_meta("registry_id"):
			continue
		var id: String = node.get_meta("registry_id")
		assert(not figures.has(id), "Duplicate Field figure ID: " + id)
		figures[id] = node
	hud.setup(self, {
		"title": "The Field of Offerings",
		"journal_hint": "Click figures and captions in the scroll to record them here.",
		"intro_title": "Spell 110: The Field of Offerings",
		"intro_body": "Explore the field as it is drawn: three registers framed by water.\n\nWalk [b]right to left[/b] with [←] [→] or click the papyrus. Press [↑] [↓], or click the water above or below, to cross to the next register. Click a figure or caption to read about it. Open the Journal with [j].",
		"outro_title": "The Field of Offerings",
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	reset()


func min_x() -> float:
	return level.page.x + MARGIN * _unit


func max_x() -> float:
	return level.page.x + level.page.w - MARGIN * _unit


func ground() -> float:
	return level.lanes[lane].ground


func reset() -> void:
	_set_hover("")
	avatar.stop()
	avatar.keys = true
	_crossing = false
	lane = 0
	avatar.position = _start
	avatar.facing = -1
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	journal.clear()
	hud.reset_view()
	hud.say("Scribe", PUZZLES.message("field.start"))
	_update_camera(1.0)


func hint() -> void:
	hud.say("Hint", PUZZLES.message("field.explore"))


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_blocking():
		return
	if event is InputEventMouseMotion:
		_set_hover(_pick(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(get_global_mouse_position())
	elif event.is_action_pressed("ui_up"):
		cross(-1)
	elif event.is_action_pressed("ui_down"):
		cross(1)


func _click(point: Vector2) -> void:
	if _crossing:
		return
	var id := _pick(point)
	if id != "":
		var bounds: Rect2 = figures[id].global_transform * figures[id].get_rect()
		var destination: float = avatar.reach(bounds)
		walk_then(destination, record.bind(id))
	elif _water_step(point) == 0 or not cross(_water_step(point)):
		walk_then(point.x)


## -1 above the current register's picture, +1 below its ground line, 0 anywhere else (the water
## frame is only drawn round the three registers; at the scroll's sides there is none to click).
func _water_step(point: Vector2) -> int:
	if point.x < level.water.x0 or point.x > level.water.x1:
		return 0
	if point.y < level.lanes[lane].inner_top:
		return -1
	if point.y > ground() + WATER_CLICK:
		return 1
	return 0


func walk_then(x: float, then := Callable()) -> void:
	avatar.walk_to(clampf(x, min_x(), max_x()), then)


## Cross to the next register above (-1) or below (1): the avatar glides over the water to its ground line.
func cross(step: int) -> bool:
	var target := lane + step
	if _crossing or target < 0 or target >= level.lanes.size():
		return false
	lane = target
	_crossing = true
	avatar.stop()
	avatar.keys = false
	_set_hover("")
	create_tween().tween_property(avatar, "position:y", ground(), CROSS_SECONDS)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished.connect(_crossed)
	return true


func _crossed() -> void:
	_crossing = false
	avatar.keys = true


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


## One zoom for every register (they are all the same height); the camera glides between them.
func _update_camera(delta: float) -> void:
	var viewport := get_viewport_rect().size
	var top: float = hud.top_height()
	var bottom: float = hud.bottom_height()
	var rows: Dictionary = level.lanes[lane]
	var zoom := SCROLL_CAMERA.fit_zoom(viewport, top, bottom, rows.bottom, _unit, 0.4 / _unit, 2.4 / _unit, rows.top)
	camera.zoom = Vector2(zoom, zoom)
	var page: Dictionary = level.page
	var target: float = SCROLL_CAMERA.clamp_horizontal(avatar.position.x - viewport.x / zoom * 0.05 - page.x,
		viewport.x / zoom, page.w) + page.x
	var k := SCROLL_CAMERA.smoothing(delta)
	camera.position.x = lerpf(camera.position.x, target, k)
	camera.position.y = lerpf(camera.position.y,
		SCROLL_CAMERA.vertical_center(rows.bottom, top, bottom, zoom, rows.top), k)
