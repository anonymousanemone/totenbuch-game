// The player figure: opaque, but filled with the papyrus itself, so it hides the lines behind it
// without looking like a pasted-on patch. A narrow, faint halo of papyrus around the outline
// helps tell it apart from the figures it walks past.
//
// The texture is made by avatar.gd: R = ink, G = inside the figure's outline (1/0).
shader_type canvas_item;

#include "res://scripts/papyrus.gdshaderinc"

uniform vec4 base : source_color = vec4(0.906, 0.839, 0.682, 1.0);
uniform vec4 fibre : source_color = vec4(0.47, 0.35, 0.16, 1.0);
uniform vec4 ink : source_color = vec4(0.18, 0.11, 0.06, 1.0);
uniform float glow_width = 6.0;      // halo width in texture pixels
uniform float glow_alpha = 0.35;     // halo opacity right at the outline; it fades to 0 outward

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 paper = papyrus(world_pos, base.rgb, fibre.rgb);
	if (t.g > 0.5) {
		COLOR = vec4(mix(paper, ink.rgb, t.r), 1.0);
	} else {
		// distance to the figure, roughly: the nearest ring (of a few) that touches the inside
		float near = 0.0;
		for (int ring = 1; ring <= 4; ring++) {
			float r = glow_width * float(ring) / 4.0;
			for (int k = 0; k < 16; k++) {
				float a = 6.2831853 * float(k) / 16.0;
				vec2 uv = UV + vec2(cos(a), sin(a)) * r * TEXTURE_PIXEL_SIZE;
				if (texture(TEXTURE, uv).g > 0.5) {
					near = max(near, 1.0 - (float(ring) - 1.0) / 4.0);
				}
			}
			if (near > 0.0) { break; }
		}
		COLOR = vec4(paper, glow_alpha * near * near);
	}
}
