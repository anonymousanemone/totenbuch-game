// Cheap papyrus: the base colour with vertical and horizontal fibres and a little blotching.
shader_type canvas_item;

#include "res://scripts/papyrus.gdshaderinc"

uniform vec4 base : source_color = vec4(0.906, 0.839, 0.682, 1.0);
uniform vec4 fibre : source_color = vec4(0.47, 0.35, 0.16, 1.0);

varying vec2 world_pos;

void vertex() {
	// world coordinates, so the grain scrolls with the scroll instead of sticking to the screen
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	COLOR = vec4(papyrus(world_pos, base.rgb, fibre.rgb), 1.0);
}
