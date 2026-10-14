// The front of spell 40's snake lifting off the donkey's back: every column right of `from_x` is
// moved by `lift`, growing to the whole of it at `to_x` and beyond, so the rest of it stays where it
// lies. The drawing is only bent, never redrawn.
shader_type canvas_item;

uniform float from_x = 0.0;       // where the lift begins (texture pixels)
uniform float to_x = 1.0;         // where it is whole
uniform vec2 lift = vec2(0.0);    // how far the front moves (texture pixels)

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 px = UV * size;
	// the column a moved pixel came from is (nearly) its own: the lift is small beside the ramp
	float w = smoothstep(from_x, to_x, px.x - lift.x);
	vec2 src = px - lift * w;
	vec4 col = vec4(0.0);
	if (src.x >= 0.0 && src.y >= 0.0 && src.x < size.x && src.y < size.y) {
		col = texture(TEXTURE, src / size);
	}
	COLOR = col * tint;
}
