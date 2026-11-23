## Shared scroll framing. Levels choose their own focus, bounds and transition behavior.
extends RefCounted

## The first row shown when a level's `level.json` names none: the row under the top register's upper
## rule, where the title bar's band takes over.
const VIEW_TOP := 36.0


## The rows the camera fits between the bars: the strip and the visible text beneath it.
static func view_height(level: Dictionary) -> float:
	return level.get("view_height", level.height)


## The explore levels' camera. One zoom fits the rows of `span` (`left`, `right`, `top`, `bottom`)
## between the bars. The view glides to `focus_x` (a twentieth of its width ahead of it), stays inside
## `span` (centred when `span` fits whole) and has the rows centred between the bars. The vertical
## position snaps, or glides too (`glide_y`) where the rows change, as between the Field's lanes.
static func follow(camera: Camera2D, viewport: Vector2, top: float, bottom: float, delta: float,
		unit: float, span: Dictionary, focus_x: float, glide_y := false) -> void:
	var zoom := fit_zoom(viewport, top, bottom, span.bottom, unit, 0.4 / unit, 2.4 / unit, span.top)
	camera.zoom = Vector2(zoom, zoom)
	var width: float = span.right - span.left
	var visible := viewport.x / zoom
	var target: float = span.left + width / 2.0
	if visible < width:
		target = span.left + clamp_horizontal(focus_x - span.left - visible * 0.05, visible, width)
	var k := smoothing(delta)
	camera.position.x = lerpf(camera.position.x, target, k)
	var y := vertical_center(span.bottom, top, bottom, zoom, span.top)
	camera.position.y = lerpf(camera.position.y, y, k) if glide_y else y


## `view_top` is the first row shown (0: the top of the strip, with a small margin above it).
static func fit_zoom(viewport: Vector2, top: float, bottom: float, view_height: float,
		unit: float, minimum: float, maximum: float, view_top := 0.0) -> float:
	return clampf(minf((viewport.y - top - bottom - 10.0) / (view_height - view_top),
		viewport.x / (1000.0 * unit)), minimum, maximum)


static func clamp_horizontal(target: float, visible_width: float, level_width: float) -> float:
	return clamp_between(target, visible_width, 0.0, level_width)


## The first column the walking camera may show: the outer line of the left double line, where `level.json`
## names it (`view_left`), else the left end of the scroll.
static func view_left(level: Dictionary) -> float:
	return float(level.get("view_left", 0.0))


## The column after the last the walking camera may show (`view_right`), else the right end of the scroll.
static func view_right(level: Dictionary) -> float:
	return float(level.get("view_right", level.width))


## Keeps a view `visible_width` wide between columns `left` and `right`. A view wider than that sits on `left`.
static func clamp_between(target: float, visible_width: float, left: float, right: float) -> float:
	return clampf(target, left + visible_width / 2.0,
		maxf(left + visible_width / 2.0, right - visible_width / 2.0))


## A delta of one second or more is also used by reset and CLI helpers to snap into place.
static func smoothing(delta: float, decay := 0.001) -> float:
	return 1.0 if delta >= 1.0 else 1.0 - pow(decay, delta)


## The rows `view_top` to `view_height` fill the space between the bars. From row 0 there is a 5 px
## margin above and below; from a later row (under the top register's upper rule) the view starts
## flush under the title bar and the whole margin goes below.
static func vertical_center(view_height: float, top: float, bottom: float, zoom: float,
		view_top := 0.0) -> float:
	var flush := 5.0 / zoom if view_top > 0.0 else 0.0
	return view_top + (view_height - view_top) / 2.0 + (bottom - top) / 2.0 / zoom + flush


static func visible_rect(camera: Camera2D, viewport_size: Vector2) -> Rect2:
	var size := viewport_size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)
