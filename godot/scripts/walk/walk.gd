## Shared walking and inspection for scrolls with one lane to explore (the Night Journey, the Fourteen Mounds,
## Mouth and Heart, the Weighing of the Heart). Saved scene nodes own placement; level.json supplies stable IDs and the
## camera's rows. The scene sets `level_key` (its assets/<level_key>/ folder), the title, the introduction and the
## journal's hint shown by the HUD, and `hint_key` (the prefix of its start and Hint messages: "walk" unless the level has its own).
extends Node2D

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const VIEW_TOP := SCROLL_CAMERA.VIEW_TOP

@export var level_key := ""
@export var hint_key := "walk"
@export var title := ""
@export var journal_hint := "Click anything drawn in the scroll to record it here."
@export var intro_title := ""
@export_multiline var intro_body := ""
@export var chapter_titles := false
@export var only_present_entries := false
@export var foreground_blocks := false
@export var dev_args := false

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
	if only_present_entries:
		for id in _descriptions.entries.keys():
			if not figures.has(id):
				_descriptions.entries.erase(id)
	if chapter_titles:
		var chapter: Dictionary = Scroll.scene(level_key)
		title = chapter.title
		intro_title = "%s %s: %s" % ["Spell" if str(chapter.spells).is_valid_int() else "Spells", chapter.spells, title]
		intro_body = level.get("intro_body", "")
		if intro_body == "":
			intro_body = _hints.message("survival.intro")
		journal_hint = "Click figures in the scroll to record them here."
	hud.setup(self, {
		"title": title,
		"journal_hint": journal_hint,
		"intro_title": intro_title,
		"intro_body": intro_body,
		"outro_title": title,
	})
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.hint_pressed.connect(hint)
	hud.restart_pressed.connect(reset)
	reset()
	if dev_args:
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
	hud.say_instructions("Scribe", _hints.message("view.start" if Scroll.viewing else hint_key + ".start"))
	_update_camera(1.0)


func hint() -> void:
	hud.say("Hint", _hints.message("view.hint" if Scroll.viewing else hint_key + ".explore"))


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
	if foreground_blocks:
		for column in $Foreground.get_children():
			var paper: ColorRect = column.get_node("Papyrus")
			if (paper.get_global_transform() * paper.get_rect()).has_point(point):
				return ""
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
		_glow = UI.hover_glow(figures[id])
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if id != "" else Input.CURSOR_ARROW)


func record(id: String) -> void:
	var total: int = _descriptions.journal_total() if only_present_entries else figures.size()
	_descriptions.inspect(id, hud, journal, figures[id].texture, total)


func _process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	SCROLL_CAMERA.follow(camera, get_viewport_rect().size, hud.top_height(), hud.bottom_height(), delta, _unit,
		view(), avatar.position.x)


## What the camera frames: columns `left` to `right` and rows `top` to `bottom` (by default the whole scroll,
## from the level's `view_top`, or the shared first row where it names none; the columns run between the outer
## lines of the double lines at its ends, where `level.json` has `view_left` and `view_right`).
func view() -> Dictionary:
	return {"left": SCROLL_CAMERA.view_left(level), "right": SCROLL_CAMERA.view_right(level), "top": float(level.get("view_top", SCROLL_CAMERA.VIEW_TOP)),
		"bottom": float(level.view_height)}


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
