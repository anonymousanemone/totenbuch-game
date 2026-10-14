// Apep's body, rippling (spell 39): each column of the drawing is lifted by the waves running
// along him from the tail, each a raised-cosine hump. The drawing is only shifted, never redrawn.
shader_type canvas_item;

const int WAVES = 4;
uniform vec4 waves[WAVES];        // (crest x, height, half-width, -) in texture pixels; height 0 = none

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

float lift(float x) {
	float h = 0.0;
	for (int i = 0; i < WAVES; i++) {
		vec4 w = waves[i];
		float d = (x - w.x) / max(w.z, 1.0);
		if (abs(d) < 1.0) {
			h += w.y * 0.5 * (1.0 + cos(PI * d));
		}
	}
	return h;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 px = UV * size;
	vec2 src = vec2(px.x, px.y + lift(px.x));
	vec4 col = vec4(0.0);
	if (src.y < size.y) {
		col = texture(TEXTURE, src / size);
	}
	COLOR = col * tint;
}
