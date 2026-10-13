## Run with: godot --headless --path godot --script res://tests/script_regressions.gd
extends SceneTree

const FIGURE_MASK := preload("res://scripts/figure_mask.gd")
const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		_failures.append(description)


func _run() -> void:
	_test_camera_bounds()
	_test_figure_mask()
	_test_hover_glow()
	print("REGRESSIONS ", "OK" if _failures.is_empty() else "FAILED")
	quit(0 if _failures.is_empty() else 1)


func _test_camera_bounds() -> void:
	_expect(SCROLL_CAMERA.clamp_horizontal(-100.0, 800.0, 3000.0) == 400.0,
		"camera cannot reveal space before the scroll")
	_expect(SCROLL_CAMERA.clamp_horizontal(4000.0, 800.0, 3000.0) == 2600.0,
		"camera cannot reveal space after the scroll")
	_expect(SCROLL_CAMERA.clamp_horizontal(500.0, 4000.0, 3000.0) == 2000.0,
		"a viewport wider than the scroll keeps the original framing")
	_expect(SCROLL_CAMERA.smoothing(0.0) == 0.0 and SCROLL_CAMERA.smoothing(1.0) == 1.0,
		"camera pauses at zero delta and snaps during reset")
	var two_steps := 1.0 - pow(1.0 - SCROLL_CAMERA.smoothing(1.0 / 60.0), 2.0)
	_expect(is_equal_approx(two_steps, SCROLL_CAMERA.smoothing(1.0 / 30.0)),
		"camera smoothing gives the same result at different frame rates")
	_expect(SCROLL_CAMERA.fit_zoom(Vector2(1280, 720), 40.0, 200.0, 480.0, 1.0, 0.4, 2.4)
		== 470.0 / 480.0, "camera reserves space for both HUD bars")


func _test_figure_mask() -> void:
	var source := Image.create(21, 21, false, Image.FORMAT_RGBA8)
	# A closed ink outline encloses blank pixels; the exterior stays transparent.
	for pixel in range(5, 16):
		for point in [Vector2i(pixel, 5), Vector2i(pixel, 15), Vector2i(5, pixel), Vector2i(15, pixel)]:
			source.set_pixelv(point, Color(0, 0, 0, 1))
	var texture := ImageTexture.create_from_image(source)
	var result := FIGURE_MASK.create_texture(texture, 2).get_image()
	_expect(result.get_size() == Vector2i(25, 25), "figure mask preserves the requested padding")
	_expect(result.get_pixel(12, 12).g == 1.0 and result.get_pixel(12, 12).r == 0.0,
		"figure interior is filled without adding ink")
	_expect(result.get_pixel(7, 12).r == 1.0, "figure outline preserves its ink")
	_expect(result.get_pixel(0, 0).g == 0.0 and result.get_pixel(0, 0).r == 0.0,
		"figure exterior remains outside the fill")
	source.set_pixel(10, 5, Color.TRANSPARENT)
	var repaired := FIGURE_MASK.create_texture(ImageTexture.create_from_image(source), 2).get_image()
	_expect(repaired.get_pixel(12, 12).g == 1.0, "a small gap in the outline does not leak the fill")


func _test_hover_glow() -> void:
	var level = load("res://scenes/dangers.tscn").instantiate()
	root.add_child(level)
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var expected_signs := []
	for words in level.level.get("heka", {}).values():
		expected_signs.append_array(words)
	_expect(level._all_heka() == expected_signs, "cached heka signs retain their scroll order")
	var actor: String = level.ENCOUNTERS[0].foes[0]
	level._glow(actor, true)
	var glow: Sprite2D = level.actors[actor].get_node("Sprite/Glow")
	var fade: Tween = glow.get_meta("fade")
	fade.custom_step(0.2)
	_expect(glow.visible and is_equal_approx(glow.material.get_shader_parameter("strength"), 1.0),
		"hovered drawings finish fading into view")
	level._glow(actor, false)
	fade = glow.get_meta("fade")
	fade.custom_step(0.2)
	_expect(not glow.visible and is_zero_approx(glow.material.get_shader_parameter("strength")),
		"invisible glows stop drawing after their fade")
	level._glow(actor, true)
	fade = glow.get_meta("fade")
	fade.custom_step(0.05)
	level._glow(actor, false)
	var interrupted: Tween = glow.get_meta("fade")
	interrupted.custom_step(0.05)
	level._glow(actor, true)
	_expect(not interrupted.is_valid() and glow.visible, "re-entering cancels an unfinished fade out")
	fade = glow.get_meta("fade")
	fade.custom_step(0.2)
	_expect(glow.visible and is_equal_approx(glow.material.get_shader_parameter("strength"), 1.0),
		"rapid hover changes leave the drawing glowing")
	level.free()
