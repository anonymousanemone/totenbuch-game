## Draws a box in a level scene's `Hitboxes` node for every figure that has none yet: the bounds of
## what a click on it hits (descriptions.gd `outlines`), for looking at in the editor. Nothing reads
## these boxes, except those marked `hit_by_box` (captions get it here): their box is the hit.
## Existing boxes, hand-edited or not, are left as they are. Only adds text to the .tscn.
##
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot -s ../.claude/skills/build-levels/hitboxes.gd -- gates
extends SceneTree

const DESCRIPTIONS := preload("res://scripts/descriptions.gd")
const COLOR := "Color(0.35, 0.75, 0.9, 0.3)"   ## a little lighter than Godot's default shape blue


func _initialize() -> void:
	for level in OS.get_cmdline_user_args():
		_add_boxes(level)
	quit()


func _add_boxes(level: String) -> void:
	var path := "res://scenes/%s.tscn" % level
	var scene: Node = load(path).instantiate()
	var boxed := {}
	if scene.has_node("Hitboxes"):
		for region in scene.get_node("Hitboxes").get_children():
			boxed[region.get_meta("registry_id", region.name)] = true
	var resources := ""
	var nodes := "" if scene.has_node("Hitboxes") else '\n[node name="Hitboxes" type="Node2D" parent="."]\n'
	var added := 0
	for node in scene.find_children("*", "", true, false):
		var id: String = node.get_meta("registry_id", "")
		if id == "" or node is Area2D or boxed.has(id):
			continue
		var sprite: Sprite2D = node if node is Sprite2D else node.get_node_or_null("Sprite")
		if sprite == null:
			continue
		boxed[id] = true
		var rect := Rect2()
		for polygon in DESCRIPTIONS.outlines(sprite.texture):
			var bounds := _bounds(polygon)
			rect = bounds if rect.size == Vector2.ZERO else rect.merge(bounds)
		if sprite.flip_h:
			rect.position.x = sprite.texture.get_width() - rect.end.x
		if sprite.flip_v:
			rect.position.y = sprite.texture.get_height() - rect.end.y
		rect.position += sprite.get_rect().position
		rect = _chain(sprite) * rect
		resources += '[sub_resource type="RectangleShape2D" id="hitbox_%s"]\nsize = Vector2(%s, %s)\n\n' % [id, rect.size.x, rect.size.y]
		nodes += '\n[node name="%s" type="Area2D" parent="Hitboxes"]\nposition = Vector2(%s, %s)\n' % [id, rect.get_center().x, rect.get_center().y] \
			+ 'collision_layer = 0\ncollision_mask = 0\nmonitoring = false\nmonitorable = false\nmetadata/registry_id = "%s"\n' % id \
			+ ('metadata/hit_by_box = true\n' if "caption" in id else "") \
			+ '\n[node name="Shape" type="CollisionShape2D" parent="Hitboxes/%s"]\nshape = SubResource("hitbox_%s")\ndebug_color = %s\n' % [id, id, COLOR]
		added += 1
	scene.free()
	var text := FileAccess.get_file_as_string(path)
	var first_node := text.find("\n[node ")
	text = text.substr(0, first_node + 1) + resources + text.substr(first_node + 1).strip_edges(false, true) + "\n" + nodes
	FileAccess.open(path, FileAccess.WRITE).store_string(text)
	print("%s: %d boxes added" % [level, added])


func _bounds(polygon: PackedVector2Array) -> Rect2:
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)
	return rect


## The node's transform in the scene, without adding the scene to a tree (so no level code runs).
func _chain(node: Node) -> Transform2D:
	var transform := Transform2D.IDENTITY
	while node != null:
		if node is Node2D:
			transform = (node as Node2D).transform * transform
		node = node.get_parent()
	return transform
