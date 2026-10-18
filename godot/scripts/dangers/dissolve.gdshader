// The spear-bearer crumbling away when a crocodile gets the heka word: crumbs of `grain` texture
// pixels drop out, the top first, with a #B55B3C rim at the edge of what is left.
shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.05) = 0.0;
uniform float grain = 3.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE / grain);
	float k = hash(cell) * 0.6 + (1.0 - UV.y) * 0.4;
	if (k < amount) {
		discard;
	}
	if (k < amount + 0.08) {
		COLOR.rgb = vec3(0.71, 0.357, 0.235);   // #B55B3C
	}
}
