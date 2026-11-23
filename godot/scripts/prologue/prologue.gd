## The prologue, Guarding the Body (spells 151–154), on walk.gd. The vignettes lie as drawn: 151ab, 151c and 151de
## stacked in one column, 152 and 154 to the left of 151de on its ground (the row). The camera keeps the procession's
## size throughout. In the column it holds on the vignette being played; the avatar walks right to left, and once
## about three quarters of him is out past its left wall, the camera pans down to the vignette below and he appears
## inside its right wall. From 151de the row is one walk: the camera follows him along it, and he may walk back as far
## as 151de's right wall. Reaching 154's left wall ends the prologue and the funeral procession opens.
## Every vertical double line is drawn over the avatar on papyrus (`Foreground/Frame<stage>`), so he passes behind
## the rules; in the column the papyrus runs on past the left wall, so he goes out of sight as he leaves.
## Stage geometry is in level.json (`stages`, in each strip's own pixels); where each stage lies is its saved
## `Strip/Strip<stage>` node. No stage has tasks yet. `-- --stage=152` starts in that vignette.
extends "res://scripts/walk/walk.gd"

const WALL_GIVE := 30.0       ## the avatar's middle stops this far inside a wall: its body may overlap the rule a little
const OUT := 0.25             ## a column vignette is left when his middle is this much of his width past its left wall
const FADE := 0.35
const PAN := 0.7              ## seconds the camera glides down before he appears in the vignette below

var part := 0                 ## the column vignette being played (an index into `level.column`), or the row after them
var _changing := false
var _finishing := false
var _glide := false


func _ready() -> void:
	super._ready()
	avatar.bumped.connect(_on_left_wall)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			place(arg.trim_prefix("--stage="))


func reset() -> void:
	_changing = false
	_finishing = false
	_glide = false
	for node in [$Strip, $Figures, $Foreground, avatar]:
		node.modulate.a = 1.0
	super.reset()
	place(level.order[0])


func in_row() -> bool:
	return part >= level.column.size()


func stage(key: String) -> Dictionary:
	return level.stages[key]


func origin(key: String) -> Vector2:
	return (get_node("Strip/Strip" + key) as Node2D).position


## The column vignette being played, or for the row the vignette its left or right end lies in.
func _key(end := "left") -> String:
	if not in_row():
		return level.column[part]
	return level.row[-1] if end == "left" else level.row[0]


func min_x() -> float:
	if level.is_empty():
		return super.min_x()
	var key := _key("left")
	var x: float = origin(key).x + stage(key).wall_left
	if in_row():
		return x + WALL_GIVE
	return x - OUT * avatar.get_node("Sprite").texture.get_width()


func max_x() -> float:
	if level.is_empty():
		return super.max_x()
	var key := _key("right")
	return origin(key).x + stage(key).wall_right - WALL_GIVE


func ground() -> float:
	var key := _key()
	return origin(key).y + stage(key).ground


func view() -> Dictionary:
	if level.is_empty():
		return super.view()
	var key := _key()
	var s := stage(key)
	var o := origin(key)
	var rows := {"top": o.y + s.view_top, "bottom": o.y + s.view_height}
	if in_row():
		return {"left": float(level.view_left), "right": float(level.view_right), "top": rows.top, "bottom": rows.bottom}
	return {"left": o.x + s.outer_left, "right": o.x + s.outer_right, "top": rows.top, "bottom": rows.bottom}


func _update_camera(delta: float) -> void:
	SCROLL_CAMERA.follow(camera, get_viewport_rect().size, hud.top_height(), hud.bottom_height(), delta, _unit,
		view(), avatar.position.x, _glide)


## Put the avatar inside the right wall of vignette `key`, the camera on it at once.
func place(key: String) -> void:
	var i: int = level.order.find(key)
	if i < 0:
		return
	part = mini(i, level.column.size())
	avatar.stop()
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	avatar.position = Vector2(origin(key).x + stage(key).wall_right - WALL_GIVE - 100.0, ground())
	avatar.facing = -1
	_update_camera(1.0)


func walk_then(x: float, then := Callable()) -> void:
	if _changing:
		return
	if not then.is_valid() and x <= min_x():
		then = _on_left_wall
	super.walk_then(x, then)


func _on_left_wall() -> void:
	if _changing or hud.is_blocking() or not stage_done():
		return
	if in_row():
		finish()
	else:
		descend()


## Whether the vignette being played is done. No stage has tasks yet.
func stage_done() -> bool:
	return true


## The camera glides down to the next vignette; then the avatar appears inside its right wall.
func descend() -> void:
	_changing = true
	avatar.stop()
	avatar.keys = false
	avatar.modulate.a = 0.0
	part += 1
	var key: String = level.order[part]
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	avatar.position = Vector2(origin(key).x + stage(key).wall_right - WALL_GIVE - 100.0, ground())
	avatar.facing = -1
	_glide = true
	var tween := create_tween()
	tween.tween_interval(PAN)
	tween.tween_callback(func(): _glide = false)
	tween.tween_property(avatar, "modulate:a", 1.0, FADE)
	tween.tween_callback(func():
		avatar.keys = true
		_changing = false)


## Fade out, and the prologue is restored: on to the funeral procession.
func finish() -> void:
	_changing = true
	_finishing = true
	avatar.stop()
	avatar.keys = false
	var tween := create_tween()
	for node in [$Strip, $Figures, $Foreground, avatar]:
		tween.parallel().tween_property(node, "modulate:a", 0.0, FADE)
	tween.tween_callback(func(): Scroll.finish("prologue"))


func playtest_actions() -> Array:
	var actions := []
	for key in level.order:
		actions.append(["Setup: stand in " + key, _playtest_place.bind(key)])
	return actions


func _playtest_place(key: String) -> void:
	if _changing:
		return
	avatar.keys = true
	avatar.modulate.a = 1.0
	_glide = false
	place(key)


func playtest_is_finishing() -> bool:
	return _finishing
