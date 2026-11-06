## Survival's rites (spells 43–59), on top of the shared navigation and inspection:
## the was-sceptres (43), the gate and the mummy (44–46), the dwelling (47), the walk upside
## down (50–52), and the water of the two sycamores (57, 59). The plan is in ideas.md.
## Placeholders: the mummy game (45) passes after its opening rocking; the order of the water
## lines (59) and eating filth (52) are stand-ins until they are decided.
extends "res://scripts/survival/survival.gd"

# Frame lines and vignettes, in strip px.
const SPLICE_43_44 := 8641.5     ## the worshipper becomes the 44 man as he passes behind it
const LINE_44_45 := 8127.0       ## barred: the gate is the only way on
const LINE_45_46 := 7832.0       ## after the mummy, there is no way back right
const DWELLING := Vector2(7163.0, 7550.0)
const SPLICE_49_50 := 6222.5
const SPLICE_50_51 := 5708.5     ## he comes through it upside down
const LINE_51_52 := 5450.5       ## headlong into 52, he eats filth
const VIGNETTE_57 := Vector2(2761.0, 3294.0)
const VIGNETTE_59 := Vector2(1593.0, 1849.0)
const HALF := 75.0               ## about half the walking figure's width
const SPLICE_REACH := 110.0      ## how near a splice line he is drawn in two parts

const FIG := "res://assets/survival/figures/"
const LOOKS := {
	"43": preload(FIG + "spell43_worshipper.png"),
	"44": preload(FIG + "avatar_44.png"),
	"46": preload(FIG + "spell46_staff_bearer.png"),
	"50": preload(FIG + "spell50_walking_man.png"),
	"51": preload(FIG + "avatar_51.png"),
}
## Looks whose head can fall: [the figure without its head, the head, the whole look's key in level.avatars].
const HEADS := {
	"44": ["spell44_staff_bearer", "spell44_head", "avatar_44"],
	"51": ["spell51_walking_man", "spell51_head", "avatar_51"],
}
## The figures the avatar stands in for; their drawings are hidden.
const PLAYED := ["spell43_worshipper", "spell44_staff_bearer", "spell46_staff_bearer",
	"spell48_walking_man", "spell49_staff_bearer", "spell50_walking_man", "spell51_walking_man"]
const PLAYED_PIECES := ["spell44_head", "spell51_head"]
const DISSOLVE := preload("res://scripts/dangers/dissolve.gdshader")
const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const FIGURE_SHADER := preload("res://scripts/figure.gdshader")
const PAD := 2

## The sceptres on his back (relative to the avatar's carrying frame), one pose per sceptre.
const SCEPTRE_POSES := [Vector2(4.0, -246.0), Vector2(11.0, -244.0), Vector2(18.0, -242.0)]
const SCEPTRE_TILT := -0.22

const MUMMY_ROCK := 3.0          ## s of the opening rocking (then, for now, it counts as won)
const DARK := 0.6                ## s for the screen to go dark or come back

# 57: holding him under the water
const BEND_SINK := 0.9           ## rad/s² he bends lower when let go
const BEND_LIFT := 1.5           ## rad/s² Space raises him
const BEND_SPEED := 0.6
const BEND_LOW := -0.7
const BEND_HIGH := 0.35
const BEND_WINDOW := 0.09        ## rad either side of as drawn: his hands are in the stream
const TRAY_FILL := 8.0           ## s in the stream for the tray to come all the way out
const TRAY_DRAIN := 0.4          ## of the tray per s out of the stream ...
const TRAY_KEEP := 0.6           ## ... never below this share of the furthest it reached

# 59: the water lines
const LINE_ORDER := ["spell59_mw1", "spell59_mw4", "spell59_mw2", "spell59_mw5", "spell59_mw3", "spell59_mw6"]  ## placeholder
const FLASH := 0.45
const FLASH_GAP := 0.15

enum Mode { WALK, SCENE, FLIP, WATER57, SEATED59 }

var pieces := {}                 ## piece key -> saved Sprite2D
var mode := Mode.WALK
var gate_used := false
var claimed := false             ## the dwelling (47); the place sign is not chosen yet
var upside := false
var _sceptres: Array[MoveableObject] = []
var _carried: Array[MoveableObject] = []
var _masked := {}
var _splice: Sprite2D
var _look := ""
var _dark: ColorRect
var _special_glows: Array[Sprite2D] = []
var _was_x := 0.0
var _in_dwelling := false
var _in_59 := false
var _flip_from := 0.0
var _bend := 0.0
var _bend_v := 0.0
var _tray := 0.0
var _tray_best := 0.0
var _bending := false            ## 57: he is under the water and must be held up
var _solved := {}
var _sequence_busy := false
var _entered := []
var _run := 0                    ## bumped on restart: pending timers of an older run do nothing
var _ready_done := false


func _ready() -> void:
	for node in $Figures.find_children("*", "Sprite2D", true, false):
		if node.has_meta("piece_id"):
			pieces[node.get_meta("piece_id")] = node
	super._ready()
	# dev: start past the gate, the two sceptres on his back (with --at= for where)
	if "--past-gate" in OS.get_cmdline_user_args():
		_take_sceptres()
		_lose_sceptre()
		gate_used = true
		avatar.min_x = min_x()
		avatar.max_x = LINE_45_46 - HALF
		upside = "--upside" in OS.get_cmdline_user_args()
	_was_x = avatar.position.x      # a dev jump (--at=) is no walk across the lines


func _setup_rites() -> void:
	_ready_done = true
	avatar.process_priority = -1          # he moves first; his second half follows him each frame
	for i in 3:
		var obj := MoveableObject.new()
		obj.name = "Sceptre%d" % (i + 1)
		add_child(obj)
		obj.setup("spell43_sceptres", pieces["spell43_sceptre%d" % (i + 1)])
		obj.carriable = true
		_sceptres.append(obj)
	_splice = Sprite2D.new()
	_splice.centered = true
	avatar.add_child(_splice)
	var layer := CanvasLayer.new()
	layer.layer = hud.layer
	_dark = ColorRect.new()
	_dark.color = UI.INK
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dark.modulate.a = 0.0
	layer.add_child(_dark)
	add_child(layer)
	move_child(layer, hud.get_index())
	for id in PLAYED:
		figures[id].visible = false
		_descriptions.entries.erase(id)
	# what he carries is described too, though it is no figure of the scene
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/survival/registry.json"))
	_descriptions.entries["spell43_sceptres"] = registry.entries.spell43_sceptres
	for key in PLAYED_PIECES:
		pieces[key].visible = false


# ---------------------------------------------------------------- restart and death

func reset() -> void:
	super.reset()
	if not Scroll.viewing:      # viewing: the scroll as drawn, with no rites (_ready_done stays false)
		_restart()


## Back to the start of the level, as at the beginning (the Journal is kept).
func _restart() -> void:
	if not _ready_done:
		_setup_rites()
	_run += 1
	mode = Mode.WALK
	gate_used = false
	upside = false
	_solved.clear()
	_entered.clear()
	_sequence_busy = false
	_dark.modulate.a = 0.0
	for obj in _sceptres:
		obj.reset()
		obj.sprite.visible = true
		obj.sprite.modulate = Color.WHITE
		obj.sprite.material = null
	_carried.clear()
	avatar.stop()
	avatar.position = _start
	avatar.facing = -1
	avatar.scale = Vector2.ONE
	avatar.modulate = Color.WHITE
	avatar.visible = true
	avatar.keys = true
	avatar.upturn = 1.0
	avatar.min_x = LINE_44_45 + HALF
	avatar.max_x = max_x()
	_was_x = avatar.position.x
	_in_dwelling = false
	_in_59 = false
	$Figures/Spell44/DoorDark.visible = false
	$Figures/Spell45/Mummy.rotation = 0.0
	pieces.spell47_ba.visible = claimed
	# 57: no one stands there; the water only dribbles and the tray is in the tree
	_bend = 0.0
	_bend_v = 0.0
	_tray = 0.0
	_tray_best = 0.0
	$Figures/Spell57/Waist.rotation = 0.0
	for key in ["spell57_upper_body", "spell57_lower_body"]:
		pieces[key].visible = false
		pieces[key].modulate = Color.WHITE
	_set_tray(0.0)
	_set_stream(pieces.spell57_stream, 0.15)
	# 59: the chair is empty and no water flows
	pieces.spell59_seated_man.visible = false
	pieces.spell59_seated_man.modulate = Color.WHITE
	_set_stream(pieces.spell59_stream, 0.0)
	for key in LINE_ORDER:
		pieces[key].modulate = Color.WHITE
	_set_look(_look_at(avatar.position.x))
	_update_splice()


## Lost: his head falls, and what is left of him reddens and crumbles. Then back to the start
## (or, once the dwelling is claimed, to 47).
func _die(head_look: String, body_at: Vector2, facing: int) -> void:
	mode = Mode.SCENE
	avatar.keys = false
	avatar.stop()
	var parts := _headless(head_look, body_at, facing)
	avatar.visible = false
	var head: Sprite2D = parts[1]
	var run := _run
	var t := create_tween()
	t.tween_property(head, "position:y", body_at.y - head.texture.get_height() / 2.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(head, "rotation", 1.6 * -facing, 0.5)
	t.tween_interval(0.4)
	t.tween_callback(func():
		for part in parts:
			_crumble(part))
	t.tween_interval(1.9)
	t.tween_callback(func():
		for part in parts:
			part.queue_free()
		if run != _run:
			return
		hud.say("Scribe", _hints.message("survival.died"))
		_restart())


## The look's body without its head and the head, as loose sprites standing where he stood.
func _headless(look: String, at: Vector2, facing: int) -> Array[Sprite2D]:
	var spec: Array = HEADS[look]
	var whole: Dictionary = level.avatars[spec[2]]
	var out: Array[Sprite2D] = []
	for i in 2:
		var key: String = spec[i]
		var it: Dictionary = level.figures[key] if i == 0 else level.pieces[key]
		var s := Sprite2D.new()
		s.texture = (figures[key] if i == 0 else pieces[key]).texture
		s.centered = true
		var local := Vector2(it.x - whole.x - whole.w / 2.0 + it.w / 2.0, it.y - whole.y - whole.h + it.h / 2.0)
		if facing != avatar.drawn_facing:
			local.x = -local.x
			s.flip_h = true
		s.position = at + local
		s.z_index = 4
		add_child(s)
		out.append(s)
	return out


## A drawing reddens and crumbles away (scripts/dangers/dissolve.gdshader).
func _crumble(sprite: Sprite2D, then := Callable()) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = DISSOLVE
	sprite.material = mat
	var t := sprite.create_tween()
	t.tween_property(sprite, "modulate", UI.INK_TINT, 0.3)
	t.tween_method(func(v: float): mat.set_shader_parameter("amount", v), 0.0, 1.05, 1.4)
	if then.is_valid():
		t.tween_callback(then)


## One sceptre reddens and crumbles away. Returns false if he has none left.
func _lose_sceptre() -> bool:
	if _carried.is_empty():
		return false
	var obj: MoveableObject = _carried.pop_back()
	_crumble(obj.sprite, func(): obj.sprite.visible = false)
	return true


func _fade_dark(to: float) -> Tween:
	var t := create_tween()
	t.tween_property(_dark, "modulate:a", to, DARK)
	return t


# ---------------------------------------------------------------- looks and splicing

func _look_at(x: float) -> String:
	if not gate_used:
		return "43" if x > SPLICE_43_44 else "44"
	if x > SPLICE_49_50:
		return "46"
	return "50" if x > SPLICE_50_51 else "51"


func _masked_look(look: String) -> Texture2D:
	if not _masked.has(look):
		_masked[look] = FIGURE_MASK.create_texture(LOOKS[look], PAD)
	return _masked[look]


func _set_look(look: String) -> void:
	_look = look
	_dress(avatar.sprite, look)
	avatar.sprite.offset = Vector2(0, -avatar.sprite.texture.get_height() / 2.0 + PAD)


func _dress(sprite: Sprite2D, look: String) -> void:
	sprite.texture = _masked_look(look)
	if not sprite.material is ShaderMaterial or (sprite.material as ShaderMaterial).shader != FIGURE_SHADER:
		var mat := ShaderMaterial.new()
		mat.shader = FIGURE_SHADER
		sprite.material = mat


## Near a splice line he is drawn in two halves: what has passed it in the new look.
func _update_splice() -> void:
	var x: float = avatar.position.x
	var line := 0.0
	for l in ([SPLICE_43_44] if not gate_used else [SPLICE_49_50, SPLICE_50_51]):
		if absf(x - l) < SPLICE_REACH:
			line = l
	var right := _look_at(x + 0.5 if line == 0.0 else line + 1.0)
	var left := _look_at(line - 1.0) if line != 0.0 else right
	var main_look := right if line != 0.0 else _look_at(x)
	if main_look != _look:
		_set_look(main_look)
	(avatar.sprite.material as ShaderMaterial).set_shader_parameter("clip_min", line if line != 0.0 else -1e9)
	_splice.visible = line != 0.0 and avatar.visible
	if not _splice.visible:
		return
	_dress(_splice, left)
	var mat := _splice.material as ShaderMaterial
	mat.set_shader_parameter("clip_max", line)
	_splice.offset = Vector2(0, -_splice.texture.get_height() / 2.0 + PAD)
	var turn := -1.0 if left == "51" and (upside or x >= line) else 1.0
	var bob: float = avatar.sprite.position.y - avatar.sprite.offset.y * (1.0 - avatar.upturn)
	_splice.flip_h = avatar.sprite.flip_h
	_splice.scale.y = turn
	_splice.position.y = bob + _splice.offset.y * (1.0 - turn)


# ---------------------------------------------------------------- each frame

func _process(delta: float) -> void:
	super._process(delta)
	if not _ready_done:
		return
	var x: float = avatar.position.x
	if mode == Mode.WALK:
		_crossings(x)
	if mode == Mode.WATER57:
		_water57(delta)
	_was_x = x
	if mode == Mode.WALK:
		# upside down only where he is drawn whole as the 51 man; at the line his 51 half is turned
		avatar.upturn = -1.0 if upside and gate_used and x <= SPLICE_50_51 - SPLICE_REACH else 1.0
	_update_splice()


func _crossings(x: float) -> void:
	# through the 50|51 line he comes out upside down
	if _was_x >= SPLICE_50_51 and x < SPLICE_50_51 and gate_used:
		if not upside:
			upside = true
			hud.say("Scribe", _hints.message("survival.upside"))
	# headlong into 52
	if upside and _was_x >= LINE_51_52 and x < LINE_51_52:
		_eat_filth()
	var in_dwelling := x > DWELLING.x and x < DWELLING.y
	if in_dwelling and not _in_dwelling and not claimed:
		hud.say("Scribe", _hints.message("survival.dwelling"))
	_in_dwelling = in_dwelling
	if x < SPLICE_43_44 and not gate_used:
		$Figures/Spell44/DoorDark.visible = true
	var in_57 := x > VIGNETTE_57.x and x < VIGNETTE_57.y
	if in_57 and not _solved.has(57) and not 57 in _entered:
		_entered.append(57)
		hud.say("Scribe", _hints.message("survival.water57"))
	var in_59 := x > VIGNETTE_59.x and x < VIGNETTE_59.y
	if in_59 and not _in_59 and not _solved.has(59):
		_play_sequence()
	_in_59 = in_59


# ---------------------------------------------------------------- picking and input

## Things to do come before figures to look at.
func _pick(point: Vector2) -> String:
	if not _ready_done:
		return super._pick(point)
	if mode == Mode.WALK:
		for obj in _sceptres:
			if obj.sprite.visible and obj.contains_point(point):
				return "#sceptres"
		if not gate_used and $Figures/Spell44/DoorDark.visible:
			var door: Rect2 = $Figures/Spell44/DoorDark.get_global_rect()
			if door.has_point(point):
				return "#door"
		if upside and avatar.upturn < 0.0 and _avatar_rect().has_point(point):
			return "#flip"
		if not _solved.has(57) and _descriptions.hit(pieces.spell57_stream, point):
			return "#water57"
		if _in_59 and not _solved.has(59) and not _sequence_busy:
			for key in LINE_ORDER:
				if _descriptions.hit(pieces[key], point):
					return "#" + key
	return super._pick(point)


func _avatar_rect() -> Rect2:
	var h: float = avatar.sprite.texture.get_height()
	var w: float = avatar.sprite.texture.get_width()
	return Rect2(avatar.position.x - w / 2.0, avatar.position.y - h, w, h)


func _set_hover(id: String) -> void:
	if not id.begins_with("#"):
		_clear_special_glow()
		super._set_hover(id)
		return
	if id == _hover:
		return
	super._set_hover("")
	_hover = id
	for sprite in _special_sprites(id):
		var g := UI.sprite_glow(sprite, UI.Glow.PROCESSION)
		(g.material as ShaderMaterial).set_shader_parameter("strength", 1.0)
		_special_glows.append(g)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _clear_special_glow() -> void:
	for g in _special_glows:
		if is_instance_valid(g):
			g.queue_free()
	_special_glows.clear()


func _special_sprites(id: String) -> Array:
	match id:
		"#sceptres":
			return _sceptres.filter(func(o): return o.sprite.visible).map(func(o): return o.sprite)
		"#door":
			return [pieces.spell44_door]
		"#water57":
			return [pieces.spell57_stream]
		"#flip":
			return []
	return [pieces[id.trim_prefix("#")]] if pieces.has(id.trim_prefix("#")) else []


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_done or hud.is_blocking():
		return
	match mode:
		Mode.WATER57:
			if event.is_action_pressed("ui_cancel"):
				_leave57()
			return
		Mode.SEATED59:
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") \
					or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				_stand59()
			return
		Mode.FLIP:
			_flip_input(event)
			return
		Mode.SCENE:
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := _pick(get_global_mouse_position())
		if id.begins_with("#"):
			_use(id, get_global_mouse_position())
			return
	super._unhandled_input(event)


func _use(id: String, point: Vector2) -> void:
	match id:
		"#sceptres":
			if _carried.is_empty():
				walk_then(pieces.spell43_sceptre3.global_position.x + 80.0, _take_sceptres)
			else:
				_descriptions.show("spell43_sceptres", hud)
		"#door":
			var door: Rect2 = $Figures/Spell44/DoorDark.get_global_rect()
			walk_then(door.get_center().x, _enter_gate)
		"#flip":
			mode = Mode.FLIP
			avatar.keys = false
			avatar.stop()
			_flip_from = point.y
		"#water57":
			walk_then(level.pieces.spell57_lower_body.x + level.pieces.spell57_lower_body.w / 2.0, _start57)
		_:
			_line59(id.trim_prefix("#"))
	_set_hover("")


# ---------------------------------------------------------------- 43: the sceptres

func _take_sceptres() -> void:
	if not _carried.is_empty():
		return
	for i in _sceptres.size():
		var obj := _sceptres[i]
		var pose := Transform2D(SCEPTRE_TILT, SCEPTRE_POSES[i])
		obj.wear(avatar, pose)
		_carried.append(obj)
	_descriptions.show("spell43_sceptres", hud)


# ---------------------------------------------------------------- 44–46: the gate and the mummy

func _enter_gate() -> void:
	if gate_used or mode != Mode.WALK:
		return
	mode = Mode.SCENE
	avatar.keys = false
	avatar.facing = -1
	var run := _run
	if not _lose_sceptre():
		_die("44", avatar.position, avatar.facing)
		return
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(avatar, "scale", Vector2(0.85, 0.85), 0.8)
	t.parallel().tween_property(avatar, "modulate:a", 0.0, 0.8)
	for obj in _carried:
		t.parallel().tween_property(obj.sprite, "modulate:a", 0.0, 0.8)
	t.tween_callback(func(): _fade_dark(1.0))
	t.tween_interval(DARK + 0.2)
	t.tween_callback(func():
		if run != _run:
			return
		gate_used = true
		avatar.visible = false
		avatar.scale = Vector2.ONE
		for obj in _carried:
			obj.sprite.visible = false
		$Figures/Spell44/DoorDark.visible = false
		avatar.min_x = min_x()
		avatar.position.x = $Figures/Spell45/Mummy.global_position.x
		_fade_dark(0.0)
		_rock_mummy(run))


## He is the mummy now, rocking slightly. (The steadying game is not decided yet: for now the
## opening rocking is all, and it passes.)
func _rock_mummy(run: int) -> void:
	var pivot: Node2D = $Figures/Spell45/Mummy
	var t := create_tween()
	t.tween_interval(DARK)
	var steps := 6
	for i in steps:
		t.tween_property(pivot, "rotation", (0.035 if i % 2 == 0 else -0.035), MUMMY_ROCK / steps).set_trans(Tween.TRANS_SINE)
	t.tween_property(pivot, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): _fade_dark(1.0))
	t.tween_interval(DARK + 0.2)
	t.tween_callback(func():
		if run == _run:
			_become_46())


func _become_46() -> void:
	var drawn: Dictionary = level.figures.spell46_staff_bearer
	avatar.position.x = drawn.x + drawn.w / 2.0
	avatar.facing = -1
	avatar.max_x = LINE_45_46 - HALF
	avatar.modulate = Color.WHITE
	avatar.visible = true
	_set_look("46")
	for obj in _carried:
		obj.sprite.visible = true
		obj.sprite.modulate = Color.WHITE
	_was_x = avatar.position.x
	_fade_dark(0.0).tween_callback(func():
		mode = Mode.WALK
		avatar.keys = true
		hud.say("Scribe", _hints.message("survival.mummy")))


# ---------------------------------------------------------------- 51–52: upside down

func _flip_input(event: InputEvent) -> void:
	var h: float = avatar.sprite.texture.get_height()
	if event is InputEventMouseMotion:
		var progress := clampf((_flip_from - get_global_mouse_position().y) / h, 0.0, 1.0)
		avatar.upturn = lerpf(-1.0, 1.0, progress)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var up: bool = avatar.upturn > 0.0
		var t := create_tween()
		t.tween_property(avatar, "upturn", 1.0 if up else -1.0, 0.2)
		t.tween_callback(func():
			upside = not up
			mode = Mode.WALK
			avatar.keys = true)


func _eat_filth() -> void:
	# What eating filth looks like is not decided yet: for now he reddens, loses a sceptre and is
	# set upright.
	upside = false
	if _carried.is_empty():
		_die("51", avatar.position, avatar.facing)
		return
	_lose_sceptre()
	hud.say("Scribe", _hints.message("survival.filth"))
	var t := create_tween()
	t.tween_property(avatar, "modulate", UI.INK_TINT, 0.2)
	t.tween_property(avatar, "modulate", Color.WHITE, 0.6)


# ---------------------------------------------------------------- 57: catching the water

func _set_stream(sprite: Sprite2D, share: float) -> void:
	sprite.region_enabled = true
	var size := sprite.texture.get_size()
	sprite.region_rect = Rect2(0, 0, size.x, size.y * clampf(share, 0.0, 1.0))
	sprite.visible = share > 0.0


## The tray comes out of the tree from where its hand is drawn: its tip first.
func _set_tray(share: float) -> void:
	var sprite: Sprite2D = pieces.spell57_tray
	var it: Dictionary = level.pieces.spell57_tray
	var w: float = it.w * clampf(share, 0.0, 1.0)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(it.w - w, 0, w, it.h)
	sprite.position.x = it.x
	sprite.visible = w > 0.5


func _start57() -> void:
	if mode != Mode.WALK or _solved.has(57):
		return
	mode = Mode.WATER57
	avatar.keys = false
	avatar.stop()
	_bending = false
	_bend = 0.0
	_bend_v = 0.0
	var t := create_tween()
	t.tween_property(avatar, "modulate:a", 0.0, 0.4)
	for key in ["spell57_upper_body", "spell57_lower_body"]:
		pieces[key].visible = true
		pieces[key].modulate.a = 0.0
		t.parallel().tween_property(pieces[key], "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		avatar.visible = false
		_set_stream(pieces.spell57_stream, 1.0)
		_bending = true)
	hud.say("Scribe", _hints.message("survival.bend"), "minigame")


func _water57(delta: float) -> void:
	if not _bending:
		return
	var lift := Input.is_action_pressed("ui_accept")
	_bend_v = clampf(_bend_v + (BEND_LIFT if lift else -BEND_SINK) * delta, -BEND_SPEED, BEND_SPEED)
	_bend += _bend_v * delta
	if _bend <= BEND_LOW or _bend >= BEND_HIGH:
		_bend = clampf(_bend, BEND_LOW, BEND_HIGH)
		_bend_v = 0.0
	$Figures/Spell57/Waist.rotation = _bend
	if absf(_bend) < BEND_WINDOW:
		_tray = minf(1.0, _tray + delta / TRAY_FILL)
		_tray_best = maxf(_tray_best, _tray)
	else:
		_tray = maxf(_tray_best * TRAY_KEEP, _tray - TRAY_DRAIN * delta)
	_set_tray(_tray)
	if _tray >= 1.0:
		_solve57()


func _solve57() -> void:
	_solved[57] = true
	_bending = false
	mode = Mode.SCENE
	var t := create_tween()
	t.tween_property($Figures/Spell57/Waist, "rotation", 0.0, 0.3)
	t.tween_callback(func():
		UI.success_flash(pieces.spell57_tray)
		_stand_at(level.pieces.spell57_lower_body.x - HALF))


func _leave57() -> void:
	_bending = false
	mode = Mode.SCENE
	var t := create_tween()
	t.tween_property($Figures/Spell57/Waist, "rotation", 0.0, 0.2)
	for key in ["spell57_upper_body", "spell57_lower_body"]:
		t.parallel().tween_property(pieces[key], "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		for key in ["spell57_upper_body", "spell57_lower_body"]:
			pieces[key].visible = false
		_set_stream(pieces.spell57_stream, 0.15)
		_stand_at(avatar.position.x))


## He stands up as the 51 man at `x`, beside where he sat or stood; the drawn figure stays.
func _stand_at(x: float) -> void:
	avatar.position.x = x
	_was_x = x
	avatar.visible = true
	avatar.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(avatar, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		mode = Mode.WALK
		avatar.keys = true)


# ---------------------------------------------------------------- 59: the water lines

var _next := 0


func _flash_line(key: String, seconds: float) -> void:
	pieces[key].modulate = UI.INK_TINT
	get_tree().create_timer(seconds).timeout.connect(func(): pieces[key].modulate = Color.WHITE)


## Both water signs flash, then each line in its order, then both again.
func _play_sequence() -> void:
	_sequence_busy = true
	_next = 0
	var run := _run
	var t := create_tween()
	t.tween_callback(func():
		for key in LINE_ORDER:
			_flash_line(key, FLASH))
	t.tween_interval(FLASH + FLASH_GAP)
	for key in LINE_ORDER:
		t.tween_callback(_flash_line.bind(key, FLASH))
		t.tween_interval(FLASH + FLASH_GAP)
	t.tween_callback(func():
		for key in LINE_ORDER:
			_flash_line(key, FLASH))
	t.tween_interval(FLASH)
	t.tween_callback(func():
		if run == _run:
			_sequence_busy = false)


func _line59(key: String) -> void:
	if _sequence_busy or _solved.has(59):
		return
	_flash_line(key, 0.25)
	if key != LINE_ORDER[_next]:
		_play_sequence()
		return
	_next += 1
	if _next == LINE_ORDER.size():
		_solve59()


func _solve59() -> void:
	_solved[59] = true
	mode = Mode.SCENE
	avatar.keys = false
	avatar.stop()
	var stream: Sprite2D = pieces.spell59_stream
	var man: Sprite2D = pieces.spell59_seated_man
	var t := create_tween()
	t.tween_method(func(v: float): _set_stream(stream, v), 0.0, 1.0, 1.2)
	t.tween_property(avatar, "modulate:a", 0.0, 0.4)
	man.visible = true
	man.modulate.a = 0.0
	t.parallel().tween_property(man, "modulate:a", 1.0, 0.4)
	t.tween_callback(func():
		avatar.visible = false
		mode = Mode.SEATED59
		UI.success_flash(man))


func _stand59() -> void:
	mode = Mode.SCENE
	var it: Dictionary = level.pieces.spell59_chair
	_stand_at(it.x + it.w + HALF)
