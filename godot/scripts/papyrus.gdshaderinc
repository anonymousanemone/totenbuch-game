// The papyrus grain as a function of world position, shared by the background (papyrus.gdshader)
// and the player figure (figure.gdshader), so the figure can show exactly the papyrus behind it.

// p is wrapped first: on big scrolls the raw coordinates are large enough that sin() loses
// precision on the GPU and the grain turns into flat rectangular patches.
float hash(vec2 p) { p = mod(p, 289.0); return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

vec3 papyrus(vec2 p, vec3 base, vec3 fibre) {
	float v = noise(vec2(p.x * 0.35, p.y * 0.015));   // long vertical fibres
	float h = noise(vec2(p.x * 0.015, p.y * 0.3));    // cross-laid horizontal fibres
	float blotch = noise(p * 0.004);
	vec3 c = mix(base, fibre, 0.05 * v + 0.05 * h);
	return c * (0.96 + 0.08 * blotch);
}
