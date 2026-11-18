## The prologue, Guarding the Body (spells 151–154): one walking lane on walk.gd, made of stages, each a single
## vignette in its own frame. Only the stage being played is shown and framed. Both vertical double lines of its
## frame are walls: the avatar can't walk out of it, and they are drawn over him (`Foreground/Frame<stage>`, on
## papyrus), so a foot that reaches past a wall is hidden behind it. When a stage is done the scene fades to the next one, and after
## the last the prologue is restored and the funeral procession opens. Stage geometry is in level.json (`stages`, in
## each strip's own pixels); where each stage lies is its saved `Strip/Strip<stage>` node.
## A stage has no tasks yet, so for now it is done when the avatar reaches its left wall.
## `-- --stage=152` starts at that stage.
extends "res://scripts/walk/walk.gd"

const WALL_GIVE := 30.0       ## the avatar's middle stops this far inside a wall: its body may overlap the rule a little
const FADE := 0.35

var order: Array = []
var stage := 0
var _changing := false


func _ready() -> void:
	super._ready()
	avatar.bumped.connect(_on_left_wall)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			show_stage(maxi(0, order.find(arg.trim_prefix("--stage="))))


func reset() -> void:
	order = level.order
	_changing = false
	super.reset()
	show_stage(0)


## The stage's data and where it lies in the scene.
func stage_data(i := stage) -> Dictionary:
	return level.stages[order[i]]


func stage_origin(i := stage) -> Vector2:
	return (get_node("Strip/Strip" + order[i]) as Node2D).position


func min_x() -> float:
	if order.is_empty():
		return super.min_x()
	return stage_origin().x + stage_data().wall_left + WALL_GIVE


func max_x() -> float:
	if order.is_empty():
		return super.max_x()
	return stage_origin().x + stage_data().wall_right - WALL_GIVE


func view() -> Dictionary:
	if order.is_empty():
		return super.view()
	var s := stage_data()
	var o := stage_origin()
	return {"left": o.x, "right": o.x + s.width, "top": o.y + s.view_top, "bottom": o.y + s.view_height}


## Show stage `i` alone, with the avatar inside its right wall.
func show_stage(i: int) -> void:
	stage = i
	for n in order.size():
		var shown := n == i
		for node in [get_node("Strip/Strip" + order[n]), get_node("Figures/Spell" + order[n]),
				get_node("Foreground/Frame" + order[n])]:
			node.visible = shown
			node.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
	avatar.stop()
	avatar.min_x = min_x()
	avatar.max_x = max_x()
	avatar.position = Vector2(max_x() - 100.0, level.ground)
	avatar.facing = -1
	_update_camera(1.0)


func walk_then(x: float, then := Callable()) -> void:
	if not then.is_valid() and x <= min_x():
		then = _on_left_wall
	super.walk_then(x, then)


## Only what is drawn in the stage being played can be picked.
func _pick(point: Vector2) -> String:
	var ids: Array = figures.keys()
	ids.reverse()
	for id in ids:
		if figures[id].is_visible_in_tree() and _descriptions.hit(figures[id], point):
			return id
	return ""


func _on_left_wall() -> void:
	if not _changing and not hud.is_blocking() and stage_done():
		finish_stage()


## Whether the stage being played is done. No stage has tasks yet.
func stage_done() -> bool:
	return true


## Fade out, then on to the next stage (or, after the last, out of the prologue).
func finish_stage() -> void:
	_changing = true
	var drawn: Array = [$Strip, $Figures, $Foreground, avatar]
	var tween := create_tween()
	for node in drawn:
		tween.parallel().tween_property(node, "modulate:a", 0.0, FADE)
	tween.tween_callback(func():
		if stage + 1 >= order.size():
			Scroll.finish("prologue")
			return
		show_stage(stage + 1)
		var back := create_tween()
		for node in drawn:
			back.parallel().tween_property(node, "modulate:a", 1.0, FADE)
		back.tween_callback(func(): _changing = false))
