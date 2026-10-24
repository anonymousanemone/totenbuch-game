// The plumes on a spell-145 pylon (the cut's "structure top", exported on the pylon's sprite).
// Everything above `base` sways like reeds in a breeze: each column leans about the plumes' foot,
// out of step with its neighbours, slowly and never upward (it is not fire). `lift` is the naming
// response (PylonPlumes.react): +1 the plumes stand taller and fan out, -1 they sag and lean apart.
// The quad grows by `room` texture px above and to the sides so leaning tips are not clipped.
shader_type canvas_item;

uniform float base = 0.0;          // texture px from the top: where the plumes stand on the cornice
uniform float center = 0.0;        // texture px: middle of the row of plumes
uniform float half_width = 1.0;    // texture px: half the row's width
uniform float lift : hint_range(-1.0, 1.0) = 0.0;
uniform float sway_degrees = 2.5;  // idle lean either way
uniform float period = 4.5;        // seconds per idle sway
uniform float room = 24.0;

varying float world_x;
varying vec4 tint;

void vertex() {
	vec2 grow = vec2(UV.x * 2.0 - 1.0, UV.y < 0.5 ? -1.0 : 0.0) * room;
	VERTEX += grow;
	UV += grow * TEXTURE_PIXEL_SIZE;
	world_x = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
	tint = COLOR;
}

void fragment() {
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	vec2 source = px;
	float height = base - px.y;
	if (height > 0.0) {
		float t = TIME * TAU / period;
		// Two slow waves running along the row, so neighbouring plumes never move as one.
		float sway = radians(sway_degrees) * (0.75 * sin(t + world_x * 0.045) + 0.25 * sin(0.53 * t + world_x * 0.11));
		float side = clamp((px.x - center) / half_width, -1.0, 1.0);
		float spread = radians(side * (lift >= 0.0 ? 4.0 * lift : -10.0 * lift));
		float tall = 1.0 + 0.1 * lift;
		float from = height / tall;
		source = vec2(px.x - tan(sway * (1.0 - 0.6 * max(-lift, 0.0)) + spread) * from, base - from);
	}
	vec2 uv = source * TEXTURE_PIXEL_SIZE;
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	COLOR = texture(TEXTURE, uv) * inside * tint;
}
