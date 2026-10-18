// The tail of the snake of spell 33, waving: everything above `base` (where the body turns up out
// of the coil) is turned about it, by an angle that grows toward the tip and runs up the tail as a
// wave. The coil below stays still. The drawing is only bent, never redrawn.
shader_type canvas_item;

uniform float amp = 0.0;          // the largest turn, at the tip (radians); 0 = as drawn
uniform float phase = 0.0;        // the wave's phase
uniform float tightness = 6.5;    // how many radians of wave fit along the tail (more = tighter)
uniform vec2 base = vec2(0.0);    // the tail's base, in texture pixels
uniform float tail_height = 1.0;  // from the base up to the tip, in texture pixels

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 px = UV * size;
	float h = clamp((base.y - px.y) / tail_height, 0.0, 1.0);
	float th = amp * pow(h, 1.3) * sin(phase - tightness * h);
	vec2 d = px - base;
	float c = cos(-th);
	float s = sin(-th);
	vec2 src = base + vec2(c * d.x - s * d.y, s * d.x + c * d.y);
	vec4 col = vec4(0.0);
	if (src.x >= 0.0 && src.y >= 0.0 && src.x < size.x && src.y < size.y) {
		col = texture(TEXTURE, src / size);
	}
	COLOR = col * tint;
}
