// The stalks of spell 41's sheaf stirring where the snake moves inside: a band of rows around
// `at` (UV y) is pushed side to side, most in the middle of the band, as a quick shiver. The
// drawing is only bent, never redrawn.
shader_type canvas_item;

uniform float at = 0.5;           // the middle of the stir (UV y, 0 = top of the stalks)
uniform float spread = 0.09;      // its half-height (UV)
uniform float amp = 0.0;          // the largest push (texture pixels); 0 = still
uniform float phase = 0.0;        // the shiver's phase

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	float k = exp(-pow((UV.y - at) / spread, 2.0));
	float dx = amp * k * sin(phase + UV.y * 40.0) * TEXTURE_PIXEL_SIZE.x;
	vec2 src = UV - vec2(dx, 0.0);
	vec4 col = vec4(0.0);
	if (src.x >= 0.0 && src.x <= 1.0) {
		col = texture(TEXTURE, src);
	}
	COLOR = col * tint;
}
