## The deceased, cut from the head of plate I. Walks along the ground line toward a target
## (click) or under keyboard control, and calls back on arrival.
extends Node2D

signal bumped  ## pushed against the left limit with the keyboard

var speed := 330.0          ## world px per second
var bob_height := 5.0
const BOB_RATE := 9.0

var keys := true            ## ← → walk; off while the level walks you somewhere itself
var min_x := 0.0
var max_x := 1.0e9
var facing := -1            ## -1 = left (direction of the procession), 1 = right
var drawn_facing := -1      ## which way the sprite faces as drawn

var _target = null          ## float or null
var _on_arrive := Callable()
var _walk_time := 0.0

## The figure is drawn opaque, filled with the papyrus (figure.gdshader).
const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const FIGURE_SHADER := preload("res://scripts/figure.gdshader")

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	var pad := 2
	sprite.texture = FIGURE_MASK.create_texture(sprite.texture, pad)
	var mat := ShaderMaterial.new()
	mat.shader = FIGURE_SHADER
	sprite.material = mat
	# origin at the feet, so flipping and bobbing pivot on the ground line
	sprite.centered = true
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + pad)


## Attachment frame for carried items: follows the figure's walking bob and facing.
func carrying_transform() -> Transform2D:
	var on_you := global_transform * Transform2D(0.0, sprite.position)
	if sprite.flip_h:
		on_you *= Transform2D.FLIP_X
	return on_you


func walk_to(x: float, on_arrive := Callable()) -> void:
	_target = clampf(x, min_x, max_x)
	_on_arrive = on_arrive


func stop() -> void:
	_target = null
	_on_arrive = Callable()


func is_walking() -> bool:
	return _target != null


func _process(delta: float) -> void:
	var moving := false
	var axis := Input.get_axis("ui_left", "ui_right") if keys else 0.0
	if axis != 0.0:
		stop()
		position.x = clampf(position.x + axis * speed * delta, min_x, max_x)
		facing = 1 if axis > 0.0 else -1
		moving = true
		if axis < 0.0 and position.x <= min_x + 0.5:
			bumped.emit()
	elif _target != null:
		var d: float = _target - position.x
		if absf(d) < 4.0:
			position.x = _target
			var cb := _on_arrive
			stop()
			if cb.is_valid():
				cb.call()
		else:
			facing = 1 if d > 0.0 else -1
			position.x += signf(d) * minf(absf(d), speed * delta)
			moving = true

	if moving:
		_walk_time += delta
	# mirror the figure when it walks the other way from how it is drawn
	sprite.flip_h = facing != drawn_facing
	sprite.position.y = -absf(sin(_walk_time * BOB_RATE)) * bob_height if moving else 0.0
