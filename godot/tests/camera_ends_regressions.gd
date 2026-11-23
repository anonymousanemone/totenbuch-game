## Run with: godot --headless --path godot --script res://tests/camera_ends_regressions.gd
## The walking camera of every scene except the Prologue is cut at the outer line of the double line at each end of
## the scroll: it shows nothing left of the left double line or right of the right one. Where the window shows the
## whole scroll between those lines, the view is centred on them. Top and bottom rows are unchanged.
extends SceneTree

const SCROLL_CAMERA := preload("res://scripts/scroll_camera.gd")
const EDGE_SCAN := 250        ## columns scanned inward from each end of a strip image
const INK := 0.55             ## a column of a double line is inked over this share of the sampled rows

## scene -> where its outer lines are drawn: the strip images of its left and right ends (path, x of the strip in
## the level) and the rows between the top and bottom rules where only the vertical lines run full height.
const SCENES := {
	"procession": {"left": ["procession/figures/strip.png", 0], "right": ["procession/figures/strip.png", 0], "rows": [60, 500]},
	"cosmos": {"left": ["cosmos/figures/strip.png", 0], "right": ["cosmos/figures/strip.png", 0], "rows": [60, 500]},
	"dangers": {"left": ["dangers/figures/strip.png", 0], "right": ["dangers/figures/strip.png", 0], "rows": [60, 500]},
	"survival": {"left": ["survival/figures/strip.png", 0], "right": ["survival/figures/strip.png", 0], "rows": [60, 500]},
	"gates": {"left": ["gates/figures/strip.png", 0], "right": ["gates/figures/strip144_145.png", 8399], "rows": [60, 500]},
	"mouth": {"left": ["mouth/figures/strip.png", 0], "right": ["mouth/figures/strip.png", 0], "rows": [60, 500]},
	"mounds": {"left": ["mounds/figures/strip.png", 0], "right": ["mounds/figures/strip.png", 0], "rows": [60, 500]},
	"doors": {"left": ["doors/figures/strip.png", 0], "right": ["doors/figures/strip.png", 0], "rows": [100, 960]},
	"hall": {"left": ["hall/figures/strip.png", 0], "right": ["hall/figures/strip.png", 0], "rows": [140, 400]},
	"field": {"left": ["field/figures/strip.png", 1040], "right": ["field/figures/strip.png", 1040], "rows": [30, 150]},
}

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func expect(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures.append(label)


func frames(count := 4) -> void:
	for i in count:
		await process_frame


## The first column (from the left end) or the column after the last (from the right end) of the outer line.
func _outer_line(path: String, rows: Array, from_right: bool) -> int:
	var image: Image = load("res://assets/" + path).get_image()
	if image.is_compressed():
		image.decompress()
	var width := image.get_width()
	var step := 4
	var count := 0
	for y in range(rows[0], rows[1], step):
		count += 1
	for i in EDGE_SCAN:
		var x := width - 1 - i if from_right else i
		var ink := 0
		for y in range(rows[0], rows[1], step):
			if image.get_pixel(x, y).a > 40.0 / 255.0:
				ink += 1
		if float(ink) / count > INK:
			return x + 1 if from_right else x
	return -1


func _run() -> void:
	expect(SCROLL_CAMERA.clamp_between(-100.0, 800.0, 500.0, 3000.0) == 900.0,
		"clamp_between: the camera cannot reveal space before the left limit")
	expect(SCROLL_CAMERA.clamp_between(9000.0, 800.0, 500.0, 3000.0) == 2600.0,
		"clamp_between: the camera cannot reveal space after the right limit")
	expect(SCROLL_CAMERA.clamp_between(0.0, 4000.0, 500.0, 3000.0) == 2500.0,
		"clamp_between: a view wider than the limits keeps its left edge on the left limit")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for key in SCENES:
		var info: Dictionary = SCENES[key]
		var left := _outer_line(info.left[0], info.rows, false) + int(info.left[1])
		var right := _outer_line(info.right[0], info.rows, true) + int(info.right[1])
		expect(left > 0 and right > left, key + " the outer lines of its double lines were found in the strip (%d, %d)" % [left, right])
		for dimensions in [Vector2i(1280, 720), Vector2i(800, 600)]:
			root.size = dimensions
			var scene = load("res://scenes/%s.tscn" % key).instantiate()
			root.add_child(scene)
			await frames(8)
			var tag := "%s %dx%d " % [key, dimensions.x, dimensions.y]
			scene.avatar.set_process(false)
			scene.avatar.position.x = -100000.0
			scene._update_camera(1.0)
			var view: Rect2 = SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
			var whole := view.size.x >= right - left
			if whole:
				expect(absf(view.get_center().x - (left + right) / 2.0) < 1.0, tag + "the view is centred on the outer lines of the two ends")
			else:
				expect(absf(view.position.x - left) < 1.0, tag + "the left edge of the view is the outer line of the left double line (%d)" % left)
			scene.avatar.position.x = 100000.0
			scene._update_camera(1.0)
			view = SCROLL_CAMERA.visible_rect(scene.camera, Vector2(dimensions))
			if not whole:
				expect(absf(view.end.x - right) < 1.0, tag + "the right edge of the view is the outer line of the right double line (%d)" % right)
			scene.queue_free()
			await frames(2)
	print("CAMERA ENDS REGRESSIONS ", "OK" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
