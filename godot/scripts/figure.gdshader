// The player figure: opaque, but filled with the papyrus itself, so it hides the lines behind it
// without looking like a pasted-on patch.
//
// The texture is made by avatar.gd: R = ink, G = inside the figure's outline (1/0).
shader_type canvas_item;

#include "res://scripts/papyrus.gdshaderinc"

uniform vec4 base : source_color = vec4(0.906, 0.839, 0.682, 1.0);
uniform vec4 fibre : source_color = vec4(0.47, 0.35, 0.16, 1.0);
uniform vec4 ink : source_color = vec4(0.180392, 0.113725, 0.062745, 1.0);

varying vec2 world_pos;
varying vec4 tint;      // the sprite's modulate: tints the ink (a bitten bearer goes red), not the papyrus

void vertex() {
	tint = COLOR;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 paper = papyrus(world_pos, base.rgb, fibre.rgb);
	if (t.g > 0.5) {
		COLOR = vec4(mix(paper, clamp(ink.rgb * tint.rgb, 0.0, 1.0), t.r), tint.a);
	} else {
		COLOR = vec4(clamp(ink.rgb * tint.rgb, 0.0, 1.0), t.r * tint.a);     // the soft outer edge of the outline
	}
}
