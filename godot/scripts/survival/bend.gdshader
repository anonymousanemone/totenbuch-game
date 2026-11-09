// The 57 man bending at the waist: above it his body turns about the waist by `bend`, easing in
// over `band` px so the drawing curves there instead of breaking; below it he stays as drawn. The
// drawing is only bent, never redrawn.
shader_type canvas_item;

uniform vec2 waist = vec2(0.0);   // the turning point (texture pixels)
uniform float bend = 0.0;         // rad, + is clockwise on screen
uniform float band = 24.0;        // px above the waist over which the turn eases in

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 q = UV * size - waist;
	float w = smoothstep(0.0, band, -q.y);
	float a = -bend * w;
	vec2 src = waist + vec2(cos(a) * q.x - sin(a) * q.y, sin(a) * q.x + cos(a) * q.y);
	vec4 col = vec4(0.0);
	if (src.x >= 0.0 && src.y >= 0.0 && src.x < size.x && src.y < size.y) {
		col = texture(TEXTURE, src / size);
	}
	COLOR = col * tint;
}
