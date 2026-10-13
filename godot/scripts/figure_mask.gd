## Builds the ink and interior channels shared by player and spear-bearer figures.
extends RefCounted


## Repacks the line drawing for figure.gdshader, with empty padding all round for the halo:
## R = ink, G = inside the figure's outline. Inside = everything the outside can't reach, after
## small gaps in the outline are sealed (so a broken stroke doesn't let the outside leak in).
static func create_texture(texture: Texture2D, padding: int) -> ImageTexture:
	var source := texture.get_image()
	if source.is_compressed():
		source.decompress()
	var width := source.get_width() + 2 * padding
	var height := source.get_height() + 2 * padding
	var ink_alpha := PackedByteArray()
	ink_alpha.resize(width * height)
	for y in source.get_height():
		for x in source.get_width():
			ink_alpha[(y + padding) * width + x + padding] = int(source.get_pixel(x, y).a * 255.0)
	var seal_radius := maxi(2, roundi(source.get_height() / 120.0))
	var sealed_outline := _dilate(_threshold(ink_alpha, 64), width, height, seal_radius)
	# Flood the outside from the border.
	var outside_mask := PackedByteArray()
	outside_mask.resize(width * height)
	var pending_pixels := PackedInt32Array()
	for x in width:
		pending_pixels.append(x)
		pending_pixels.append((height - 1) * width + x)
	for y in height:
		pending_pixels.append(y * width)
		pending_pixels.append(y * width + width - 1)
	while not pending_pixels.is_empty():
		var index: int = pending_pixels[pending_pixels.size() - 1]
		pending_pixels.resize(pending_pixels.size() - 1)
		if outside_mask[index] or sealed_outline[index]:
			continue
		outside_mask[index] = 1
		var x := index % width
		if x > 0: pending_pixels.append(index - 1)
		if x < width - 1: pending_pixels.append(index + 1)
		if index >= width: pending_pixels.append(index - width)
		if index < width * (height - 1): pending_pixels.append(index + width)
	# Undo the sealing's fattening: shrink the enclosed area back by the seal radius.
	var interior_mask := PackedByteArray()
	interior_mask.resize(width * height)
	for index in width * height:
		interior_mask[index] = 0 if outside_mask[index] else 1
	interior_mask = _erode(interior_mask, width, height, seal_radius)
	var result := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var index := y * width + x
			var is_inside := interior_mask[index] or ink_alpha[index] > 64
			result.set_pixel(x, y, Color(ink_alpha[index] / 255.0, 1.0 if is_inside else 0.0, 0.0, 1.0))
	return ImageTexture.create_from_image(result)


static func _threshold(mask: PackedByteArray, threshold: int) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(mask.size())
	for index in mask.size():
		result[index] = 1 if mask[index] > threshold else 0
	return result


## Square max filter, done as a row pass then a column pass with running counts.
static func _dilate(mask: PackedByteArray, width: int, height: int, radius: int) -> PackedByteArray:
	return _filter_line(_filter_line(mask, width, height, radius, true, false), width, height, radius, false, false)


static func _erode(mask: PackedByteArray, width: int, height: int, radius: int) -> PackedByteArray:
	return _filter_line(_filter_line(mask, width, height, radius, true, true), width, height, radius, false, true)


static func _filter_line(mask: PackedByteArray, width: int, height: int, radius: int,
		horizontal: bool, require_all: bool) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(mask.size())
	var line_length := width if horizontal else height        # length of a line
	var lines := height if horizontal else width
	var step := 1 if horizontal else width
	for line_index in lines:
		var start := line_index * width if horizontal else line_index
		var count := 0                # set pixels in the window
		for pixel in mini(radius, line_length - 1) + 1:
			count += mask[start + pixel * step]
		for pixel in line_length:
			var window_size := mini(pixel + radius, line_length - 1) - maxi(pixel - radius, 0) + 1
			var is_set := count == window_size if require_all else count > 0
			result[start + pixel * step] = 1 if is_set else 0
			if pixel + radius + 1 < line_length:
				count += mask[start + (pixel + radius + 1) * step]
			if pixel - radius >= 0:
				count -= mask[start + (pixel - radius) * step]
	return result


