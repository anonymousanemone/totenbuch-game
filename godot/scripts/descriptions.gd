## Shared inspection content; scene geometry and gameplay state remain in the level scripts.
extends RefCounted

const HIT_CELL := 4          ## outlines are traced at 1/4 size (two halvings): about this many px of air round a drawing count as a hit
var entries: Dictionary
var _level: String
var _outlines := {}          ## texture -> its drawing's filled outlines (polygons, in texture px)
var _boxes := {}             ## registry ID -> Area2D: the few targets hit by their box, not their drawing
static var _ink_bounds := {}


func _init(level: String) -> void:
	_level = level
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/%s/registry.json" % level))
	entries = content.entries


## The journal's key for entry `id`.
func key(id: String) -> String:
	return _level + "/" + id


func journal_total() -> int:
	return entries.values().filter(func(entry): return entry.get("journal", true)).size()


func text(id: String, variant := "default") -> String:
	var descriptions: Dictionary = entries[id].descriptions
	return descriptions.get(variant, descriptions.default)


func line(id: String, variant := "default", spoken := false) -> Dictionary:
	var entry: Dictionary = entries[id]
	return {"speaker": entry.get("speaker", entry.name) if spoken else entry.name,
		"text": entry.speech if spoken and entry.has("speech") else text(id, variant)}


func show(id: String, hud: CanvasLayer, variant := "default", spoken := false) -> void:
	var content := line(id, variant, spoken)
	hud.say(content.speaker, content.text)


func remember(id: String, hud: CanvasLayer, journal: Array[String], image: Texture2D,
		total: int, variant := "default", spoken := false) -> void:
	if not entries[id].get("journal", true):
		return
	if id not in journal:
		journal.append(id)
	var content := line(id, variant, spoken)
	hud.add_journal_entry(entries[id].name, content.text, image, journal.size(), total,
		key(id), content.speaker)


func inspect(id: String, hud: CanvasLayer, journal: Array[String], image: Texture2D,
		total: int, variant := "default", spoken := false) -> void:
	show(id, hud, variant, spoken)
	remember(id, hud, journal, image, total, variant, spoken)


## The level's Hitboxes node: one box per figure, an editor reference only, except boxes marked
## `hit_by_box` (captions, figures sharing one drawing), which are what a click on them means.
func use_boxes(hitboxes: Node) -> void:
	for region in hitboxes.get_children():
		if region.get_meta("hit_by_box", false):
			_boxes[region.get_meta("registry_id", region.name)] = region


## The box of a `hit_by_box` target, in world coordinates.
func box(id: String) -> Rect2:
	return region_bounds(_boxes[id])


## A click on a figure: inside its drawing's outline (with everything the outline encloses), plus
## about HIT_CELL px of air, respecting the sprite's saved transform. A `hit_by_box` figure is hit
## by its box instead.
func hit(sprite: Sprite2D, point: Vector2) -> bool:
	if not sprite.is_visible_in_tree():
		return false
	if _boxes.has(sprite.get_meta("registry_id", "")):
		return box(sprite.get_meta("registry_id")).has_point(point)
	var texture: Texture2D = sprite.texture
	var pixel := sprite.to_local(point) - sprite.get_rect().position
	if not Rect2(Vector2.ZERO, texture.get_size()).grow(2 * HIT_CELL).has_point(pixel):
		return false
	if not _outlines.has(texture):
		_outlines[texture] = outlines(texture)
	return _outlines[texture].any(func(polygon): return Geometry2D.is_point_in_polygon(pixel, polygon))


## The drawing's outlines, filled: traced on a quarter-size copy (two box-averaging halvings, so
## any ink in a HIT_CELL-px cell counts and small gaps in a stroke are sealed), grown by one cell,
## and scaled back to texture px. Native image calls: a few ms even for the largest figures.
static func outlines(texture: Texture2D) -> Array:
	var source := texture.get_image()
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	# one empty cell all round, so outlines close at the texture's edge
	var cells := Vector2i((source.get_size() + Vector2i(2 * HIT_CELL, 2 * HIT_CELL) + Vector2i(HIT_CELL - 1, HIT_CELL - 1)) / HIT_CELL)
	var canvas := Image.create(cells.x * HIT_CELL, cells.y * HIT_CELL, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i(HIT_CELL, HIT_CELL))
	canvas.shrink_x2()
	canvas.shrink_x2()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(canvas, 0.01)
	bitmap.grow_mask(1, Rect2i(Vector2i.ZERO, cells))
	var out := []
	for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, cells), 0.5):
		var scaled := PackedVector2Array()
		for point in polygon:
			scaled.append(point * HIT_CELL - Vector2(HIT_CELL, HIT_CELL))
		out.append(scaled)
	return out


## A tight rectangle around the texture's nontransparent pixels, in world coordinates.
static func sprite_bounds(sprite: Sprite2D) -> Rect2:
	var texture := sprite.texture
	if not _ink_bounds.has(texture):
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		_ink_bounds[texture] = Rect2(image.get_used_rect())
	var bounds: Rect2 = _ink_bounds[texture]
	if sprite.flip_h:
		bounds.position.x = texture.get_width() - bounds.end.x
	if sprite.flip_v:
		bounds.position.y = texture.get_height() - bounds.end.y
	bounds.position += sprite.get_rect().position
	return sprite.global_transform * bounds


static func region_bounds(region: Area2D) -> Rect2:
	var shape: CollisionShape2D = region.get_node("Shape")
	var size: Vector2 = (shape.shape as RectangleShape2D).size
	return shape.global_transform * Rect2(-size / 2.0, size)
