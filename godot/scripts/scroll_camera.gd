## Shared scroll framing. Levels choose their own focus, bounds and transition behavior.
extends RefCounted


static func fit_zoom(viewport: Vector2, top: float, bottom: float, view_height: float,
		unit: float, minimum: float, maximum: float) -> float:
	return clampf(minf((viewport.y - top - bottom - 10.0) / view_height,
		viewport.x / (1000.0 * unit)), minimum, maximum)


static func clamp_horizontal(target: float, visible_width: float, level_width: float) -> float:
	return clampf(target, visible_width / 2.0,
		maxf(visible_width / 2.0, level_width - visible_width / 2.0))


## A delta of one second or more is also used by reset and CLI helpers to snap into place.
static func smoothing(delta: float, decay := 0.001) -> float:
	return 1.0 if delta >= 1.0 else 1.0 - pow(decay, delta)


static func vertical_center(view_height: float, top: float, bottom: float, zoom: float) -> float:
	return view_height / 2.0 + (bottom - top) / 2.0 / zoom


static func visible_rect(camera: Camera2D, viewport_size: Vector2) -> Rect2:
	var size := viewport_size / camera.zoom
	return Rect2(camera.position - size / 2.0, size)
