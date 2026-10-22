## Movement/attachment only. Puzzle controllers validate destinations and own input/text.
class_name MoveableObject
extends Node2D

enum State { WORLD, WORN, HELD, PLACED }
# CLICK_FOLLOW is approved only for the words; review alternatives and obtain approval before adding uses.
enum TransportMode { DRAG_DROP, CLICK_FOLLOW }
enum InteractionMode { TRANSPORT, TOOL_USE }

signal state_changed(previous: State, current: State)
signal description_requested(object_id: String, description_key: String)

var id := ""
var sprite: Sprite2D
var state := State.WORLD
var carriable := false
var description_id := ""
var transport_mode := TransportMode.DRAG_DROP
var interaction_mode := InteractionMode.TRANSPORT
var locked_in_place := false
var carrier: Node2D
var carry_pose := Transform2D.IDENTITY
var held_pose := Transform2D.IDENTITY
var base_world_scale := Vector2.ONE
var from_loc_parent: Node
var from_loc_transform := Transform2D.IDENTITY
var from_loc_z_index := 0
var to_loc_parent: Node
var to_loc_transform := Transform2D.IDENTITY
var to_loc_z_index := 0
var _return_state := State.WORLD
var _return_parent: Node
var _return_transform := Transform2D.IDENTITY
var _return_z_index := 0
var _image: Image
var _home_flip := false

func setup(object_id: String, drawing: Sprite2D) -> void:
	id = object_id
	description_id = object_id
	sprite = drawing
	from_loc_parent = sprite.get_parent()
	from_loc_transform = sprite.transform
	from_loc_z_index = sprite.z_index
	base_world_scale = sprite.global_scale.abs()
	_home_flip = sprite.flip_h

func set_to_loc(parent: Node, pose: Transform2D, drawing_order: int) -> void:
	to_loc_parent = parent
	to_loc_transform = pose
	to_loc_z_index = drawing_order

func _change(next: State) -> void:
	var previous := state
	state = next
	state_changed.emit(previous, state)

func _apply(parent: Node, pose: Transform2D, drawing_order: int) -> void:
	if sprite.get_parent() != parent:
		sprite.reparent(parent, false)
	sprite.transform = pose
	_preserve_scale()
	sprite.z_index = drawing_order

func _preserve_scale() -> void:
	var frame := sprite.global_transform
	var facing := signf(frame.determinant())
	sprite.global_transform = Transform2D(frame.get_rotation(),
		Vector2(base_world_scale.x, base_world_scale.y * facing), 0.0, frame.origin)

func wear(avatar: Node2D, pose: Transform2D) -> void:
	if not carriable or locked_in_place:
		return
	carrier = avatar
	carry_pose = pose
	_change(State.WORN)
	follow()

func hold(pointer_pose: Transform2D = Transform2D.IDENTITY) -> void:
	if locked_in_place or state == State.HELD:
		return
	_return_state = state
	_return_parent = sprite.get_parent()
	_return_transform = sprite.transform
	_return_z_index = sprite.z_index
	held_pose = pointer_pose
	_change(State.HELD)
	sprite.z_index = 10

func move_held(world_point: Vector2) -> void:
	if state != State.HELD or interaction_mode != InteractionMode.TRANSPORT:
		return
	sprite.global_transform = Transform2D(0.0, world_point) * held_pose
	_preserve_scale()

func place() -> void:
	assert(to_loc_parent != null, "Configure a destination before placing " + id)
	_apply(to_loc_parent, to_loc_transform, to_loc_z_index)
	_change(State.PLACED)

func cancel_hold() -> void:
	if state != State.HELD:
		return
	_change(_return_state)
	_apply(_return_parent, _return_transform, _return_z_index)
	if state == State.WORN:
		follow()

func reset() -> void:
	locked_in_place = false
	interaction_mode = InteractionMode.TRANSPORT
	carrier = null
	_apply(from_loc_parent, from_loc_transform, from_loc_z_index)
	sprite.flip_h = _home_flip
	_change(State.WORLD)

func lock_in_place() -> void:
	locked_in_place = true

func request_description() -> void:
	description_requested.emit(id, description_id)

func world_rect() -> Rect2:
	return preload("res://scripts/descriptions.gd").sprite_bounds(sprite)

func contains_point(world_point: Vector2) -> bool:
	if not sprite.is_visible_in_tree() or sprite.texture == null:
		return false
	if _image == null:
		_image = sprite.texture.get_image()
		if _image.is_compressed():
			_image.decompress()
	var pixel := sprite.to_local(world_point) - sprite.get_rect().position
	if sprite.flip_h:
		pixel.x = _image.get_width() - 1 - pixel.x
	if sprite.flip_v:
		pixel.y = _image.get_height() - 1 - pixel.y
	if not Rect2(Vector2.ZERO, _image.get_size()).has_point(pixel):
		return false
	return _image.get_pixelv(Vector2i(pixel)).a > 0.1

func follow() -> void:
	if state == State.WORN and interaction_mode == InteractionMode.TRANSPORT:
		sprite.global_transform = carrier.carrying_transform() * carry_pose
		_preserve_scale()
		sprite.z_index = 5

func _process(_delta: float) -> void:
	follow()
