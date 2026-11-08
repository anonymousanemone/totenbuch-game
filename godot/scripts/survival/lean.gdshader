// A seated man (spells 52, 53) leaning toward his altar: everything above his lap turns about the
// hip by `lean`, and his torso stretches along the spine by up to `stretch` px (none at the waist,
// all of it at the shoulders). His lap and legs stay as drawn. The drawing is only bent, never
// redrawn; his head and arm are separate sprites that follow the same turn and stretch.
shader_type canvas_item;

uniform vec2 hip = vec2(0.0);       // the turning point (texture pixels)
uniform vec2 thigh = vec2(1.0, 0.0); // along his lap, from the hip (unit)
uniform vec2 spine = vec2(0.0, -1.0); // from the hip to the shoulder (unit)
uniform float spine_len = 100.0;    // hip to shoulder (texture pixels)
uniform float lean = 0.0;           // rad, + leans forward (clockwise on screen)
uniform float stretch = 0.0;        // texture pixels
uniform float from_angle = 0.35;    // above the lap by this much (rad) the turn begins ...
uniform float to_angle = 0.8;       // ... and is whole

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

vec2 turned(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 q = UV * size - hip;
	vec2 up = vec2(thigh.y, -thigh.x);
	float ang = atan(dot(q, up), dot(q, thigh));
	float w = smoothstep(from_angle, to_angle, ang);
	vec2 q1 = turned(q, -lean * w);
	float along = clamp(dot(q1, spine) / spine_len, 0.0, 1.0) * w;
	vec2 src = hip + q1 - spine * stretch * along;
	vec4 col = vec4(0.0);
	if (src.x >= 0.0 && src.y >= 0.0 && src.x < size.x && src.y < size.y) {
		col = texture(TEXTURE, src / size);
	}
	COLOR = col * tint;
}
