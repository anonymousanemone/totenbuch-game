## Shared inspection content; scene geometry and gameplay state remain in the level scripts.
extends RefCounted

const HIT_PAD := 4
var entries: Dictionary
var _level: String
var _images := {}
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


## Respect the sprite's saved transform and transparent margins when picking visible artwork.
func hit(sprite: Sprite2D, point: Vector2) -> bool:
	if not sprite.is_visible_in_tree():
		return false
	var texture: Texture2D = sprite.texture
	if not _images.has(texture):
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		_images[texture] = image
	var image: Image = _images[texture]
	var pixel := sprite.to_local(point) - sprite.get_rect().position
	if not Rect2(Vector2.ZERO, image.get_size()).grow(HIT_PAD).has_point(pixel):
		return false
	for y in range(maxi(0, floori(pixel.y) - HIT_PAD), mini(image.get_height(), floori(pixel.y) + HIT_PAD + 1)):
		for x in range(maxi(0, floori(pixel.x) - HIT_PAD), mini(image.get_width(), floori(pixel.x) + HIT_PAD + 1)):
			if image.get_pixel(x, y).a > 0.1:
				return true
	return false


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
