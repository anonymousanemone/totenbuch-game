## The seven breaths (spells 54–62): the seven raised hands start empty. A sail lies hidden at four
## places, where its sign is drawn in the text (breath_loc1–4: they glow on hover but do not
## flash); clicking one gives him a sail, once. One more is the reward for 59's water (its caption
## has no breath sign); the other two are rewards for minigames not yet decided (give_sail). He carries his sails held up in front of him, stacked; dragged onto an
## empty raised hand, a sail fills it as drawn and stays; dropped anywhere else it goes back to him.
## Dead with the dwelling claimed, the sails he carried lie on the pylon for him to take back (47).
extends RefCounted

const HANDS := ["spell54_sail", "spell55_sail", "spell56_sail", "spell58_sail", "spell60_sail",
	"spell61_sail", "spell62_sail"]
const LOCS := ["breath_loc1", "breath_loc2", "breath_loc3", "breath_loc4"]
const CARRY := Vector2(-95.0, -225.0)   ## the first sail he holds up, from his feet (drawn facing)
const STACK := Vector2(5.0, -7.0)       ## each further sail, behind and above the last
const DROP_REACH := 34.0                ## a sail dropped this near an empty hand's sail fills it (px)
const ON_PYLON := Vector2(7340.0, 262.0)   ## 47: where the first sail lies on the pylon ...
const PYLON_STEP := 26.0                ## ... and the next, along it

var game
var taken := {}                  ## spot key -> true once its sail is found
var filled := {}                 ## hand key -> true once it holds its sail
var carried: Array[MoveableObject] = []
var on_pylon: Array[MoveableObject] = []
var _held: MoveableObject


func _init(level) -> void:
	game = level


## As at the start of the level: every hand empty, every sail still hidden.
func reset() -> void:
	for obj in carried + on_pylon:
		obj.sprite.queue_free()
		obj.queue_free()
	carried.clear()
	on_pylon.clear()
	_held = null
	taken.clear()
	filled.clear()
	for key in HANDS:
		game.pieces[key].visible = false
		game.pieces[key].modulate = Color.WHITE


## The spot under `point` whose sail is still to be found, or "".
func loc_at(point: Vector2) -> String:
	for key in LOCS:
		if not taken.has(key) and game._descriptions.hit(game.pieces[key], point):
			return key
	return ""


## A sail found at a spot: he holds it up with the others.
func take(key: String) -> void:
	if taken.has(key):
		return
	taken[key] = true
	give_sail(game.pieces[key].texture)


## A sail for him to carry (a found one, or later a minigame's reward), drawn as `texture`.
func give_sail(texture: Texture2D) -> void:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	game.add_child(s)
	var obj := MoveableObject.new()
	obj.name = "Sail%d" % (carried.size() + on_pylon.size() + filled.size() + 1)
	game.add_child(obj)
	obj.setup("breath_sign", s)
	obj.carriable = true
	carried.append(obj)
	_restack()


func _restack() -> void:
	for i in carried.size():
		carried[i].wear(game.avatar, Transform2D(0.0, CARRY + STACK * i))


## The carried sail under `point` (the front one first), or null.
func carried_at(point: Vector2) -> MoveableObject:
	for i in range(carried.size() - 1, -1, -1):
		if carried[i].contains_point(point):
			return carried[i]
	return null


func start_drag(obj: MoveableObject, point: Vector2) -> void:
	_held = obj
	obj.hold(Transform2D(0.0, obj.sprite.global_position - point))
	obj.move_held(point)


func drag(point: Vector2) -> void:
	if _held:
		_held.move_held(point)


## Released: onto an empty raised hand it fills it, as drawn; anywhere else it goes back to him.
func drop() -> void:
	var obj := _held
	_held = null
	if obj == null:
		return
	var hand := _hand_near(obj.sprite.global_position + obj.sprite.texture.get_size() / 2.0)
	if hand == "":
		obj.cancel_hold()
		return
	var piece: Sprite2D = game.pieces[hand]
	obj.set_to_loc(piece.get_parent(), Transform2D(0.0, piece.position + piece.texture.get_size() / 2.0 - obj.sprite.texture.get_size() / 2.0), piece.z_index)
	obj.place()
	obj.lock_in_place()
	carried.erase(obj)
	filled[hand] = true
	piece.visible = true
	piece.modulate.a = 0.0
	var t: Tween = piece.create_tween()
	t.tween_property(piece, "modulate:a", 1.0, 0.3)
	t.parallel().tween_property(obj.sprite, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		obj.sprite.queue_free()
		obj.queue_free())
	_restack()


func _hand_near(p: Vector2) -> String:
	for key in HANDS:
		var piece: Sprite2D = game.pieces[key]
		var centre := piece.global_position + piece.texture.get_size() / 2.0
		if not filled.has(key) and p.distance_to(centre) < DROP_REACH:
			return key
	return ""


func dragging() -> bool:
	return _held != null


# ---------------------------------------------------------------- 47: after a death

## Dead with the dwelling claimed: the sails he carried lie on the pylon.
func to_pylon() -> void:
	for obj in carried:
		on_pylon.append(obj)
	carried.clear()
	for i in on_pylon.size():
		var obj := on_pylon[i]
		obj.carrier = null
		obj.state = MoveableObject.State.WORLD
		obj.sprite.reparent(game.get_node("Figures/Spell47"), false)
		obj.sprite.rotation = 0.0
		obj.sprite.position = ON_PYLON + Vector2(PYLON_STEP * i, 0.0)
		obj.sprite.z_index = 2


func pylon_at(point: Vector2) -> bool:
	return on_pylon.any(func(o): return o.contains_point(point))


## He takes back the sails lying on the pylon.
func take_back() -> void:
	carried.append_array(on_pylon)
	on_pylon.clear()
	_restack()
