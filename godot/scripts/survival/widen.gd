## Survival's minigames open their vignette out a little: halfway between the Procession (which
## doesn't) and Dangers (whose vignette fills the screen). Everything in view beyond the
## vignette's two double lines, from under the top rules down to the ground rule, is pushed
## outward WIDEN px, the same each side, with the lines themselves; the vignette grows by fresh
## papyrus in between, the rule under the captions carried across. The top rules and the text
## below the ground stay where they are, and the neighbours still show beyond the pushed lines.
## (The camera holds still in a minigame, so what is pushed is a picture of the view as it was.)
extends RefCounted

const WIDEN := 120.0                 ## strip px everything beyond each double line moves outward
const OPEN := 0.5                    ## s to open out, or to close back as drawn
const DOUBLE := 20.0                 ## a double line's width (two 6 px lines, 8 px apart)
const TOP := 50.0                    ## strip y under the top rules, where the pushed part begins ...
const RULE := Vector2(180.0, 186.0)  ## ... the rule under the captions (carried across the gap) ...
const GROUND := 526.0                ## ... and the ground rule, where it ends
## Each minigame's vignette: from the left edge of its left double line to the right edge of its
## right one (strip x).
const CELLS := {
	45: Vector2(7832.0, 8128.0),
	52: Vector2(4793.0, 5461.0),
	53: Vector2(4266.0, 4813.0),
	57: Vector2(2489.0, 3314.0),
}

var game
var layer: Node2D                    ## above the scroll's foreground columns
var cell := Vector2.ZERO
var amount := 0.0                    ## 0 as drawn, 1 opened out
var sides: Array[Sprite2D] = []      ## left, right: the view beyond each double line, line included
var _home: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _gaps: Array[ColorRect] = []     ## left band, left picture, right band, right picture
var _rules: Array[Sprite2D] = []     ## the rule under the captions, across each gap
var _tween: Tween
var _token := 0                      ## bumped on each open and close: a stale open does nothing


func _init(level) -> void:
	game = level


func setup() -> void:
	layer = Node2D.new()
	layer.name = "Widen"
	layer.z_index = 7
	game.add_child(layer)
	for i in 2:
		var s := Sprite2D.new()
		s.centered = false
		layer.add_child(s)
		sides.append(s)
	for i in 4:
		var c := ColorRect.new()
		c.material = game.get_node("Papyrus").material
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(c)
		_gaps.append(c)
	for i in 2:
		var r := Sprite2D.new()
		r.centered = false
		r.region_enabled = true
		r.texture = game.get_node("Strip").texture
		layer.add_child(r)
		_rules.append(r)
	layer.visible = false


## The vignette of spell `sp` opens out, once the held view has been drawn.
func open(sp: int) -> void:
	_token += 1
	var token := _token
	cell = CELLS[sp]
	if DisplayServer.get_name() == "headless":    # nothing is drawn (tests): no picture to push
		await game.get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	if token != _token:
		return
	_take_sides()
	_animate(1.0)


## Back as drawn: pulled in, or at once (while the screen is dark, or starting over).
func close(instant := false) -> void:
	_token += 1
	if instant or amount == 0.0:
		if _tween:
			_tween.kill()
		_set_amount(0.0)
	else:
		_animate(0.0)


## What the view shows beyond each double line (between TOP and GROUND), as a picture in place.
func _take_sides() -> void:
	var vp_size: Vector2 = game.get_viewport_rect().size
	var to_screen: Transform2D = game.get_canvas_transform()
	var to_world := to_screen.affine_inverse()
	var view := Rect2(to_world * Vector2.ZERO, to_world.basis_xform(vp_size))
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		img = game.get_viewport().get_texture().get_image()
	var spans := [Vector2(view.position.x, cell.x + DOUBLE), Vector2(cell.y - DOUBLE, view.end.x)]
	for i in 2:
		var s := sides[i]
		var world := Rect2(spans[i].x, TOP, spans[i].y - spans[i].x, GROUND - TOP)
		_home[i] = world.position
		s.texture = null
		if img == null or img.is_empty() or world.size.x <= 0.0:
			continue
		var px := float(img.get_width()) / vp_size.x
		var r := Rect2i(Rect2(to_screen * world.position * px, to_screen.basis_xform(world.size) * px)) \
			.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if r.size.x <= 0 or r.size.y <= 0:
			continue
		s.texture = ImageTexture.create_from_image(img.get_region(r))
		s.scale = to_world.basis_xform(Vector2.ONE) / px
		_home[i] = to_world * (Vector2(r.position) / px)


func _animate(to: float) -> void:
	if _tween:
		_tween.kill()
	_tween = game.create_tween()
	_tween.tween_method(_set_amount, amount, to, OPEN * absf(to - amount)).set_trans(Tween.TRANS_SINE)


func _set_amount(k: float) -> void:
	amount = k
	layer.visible = k > 0.0
	if not layer.visible:
		return
	var d := WIDEN * k
	sides[0].position = _home[0] - Vector2(d, 0.0)
	sides[1].position = _home[1] + Vector2(d, 0.0)
	# the gap each side opens: fresh papyrus, with the rule under the captions running across it
	var gaps := [cell.x + DOUBLE - d, cell.y - DOUBLE]
	for i in 2:
		var x: float = gaps[i]
		_gaps[2 * i].position = Vector2(x, TOP)
		_gaps[2 * i].size = Vector2(d, RULE.x - TOP)
		_gaps[2 * i + 1].position = Vector2(x, RULE.y)
		_gaps[2 * i + 1].size = Vector2(d, GROUND - RULE.y)
		_rules[i].position = Vector2(x, RULE.x)
		_rules[i].region_rect = Rect2(cell.x + DOUBLE + 4.0, RULE.x, d, RULE.y - RULE.x)
