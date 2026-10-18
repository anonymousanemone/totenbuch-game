// The closing light of spell 15: a bright glow swells from two suns (Ra's disc and the sun on the
// offering stand), with faint fine rays, and floods the screen. Drawn on a full-screen rect;
// positions in its UV.
shader_type canvas_item;

uniform vec2 sun_a = vec2(0.3, 0.4);
uniform vec2 sun_b = vec2(0.4, 0.45);
uniform float aspect = 1.7778;                 // width / height of the screen
uniform float spread = 0.0;                    // 0..1: how far the glow reaches
uniform float flood = 0.0;                     // 0..1: the light fills the screen
uniform float turn = 0.0;                      // s: the rays turn slowly
uniform vec4 light : source_color = vec4(1.0, 0.95, 0.78, 1.0);   // lighter than the papyrus, warm
uniform vec4 core : source_color = vec4(1.0, 0.98, 0.9, 1.0);     // the heart of each sun

// (glow, heat): how much light reaches uv from a sun at c, and how close to its core it is
vec2 shine(vec2 uv, vec2 c) {
	vec2 d = (uv - c) * vec2(aspect, 1.0);
	float r = length(d);
	float a = atan(d.y, d.x);
	float reach = mix(0.04, 1.6, spread);
	float halo = exp(-r * r / (reach * reach * 0.3));
	float heart = smoothstep(0.025 + 0.06 * spread, 0.0, r);
	float rays = pow(abs(sin(a * 11.0 + turn * 0.15)), 30.0) + 0.8 * pow(abs(sin(a * 17.0 - turn * 0.1 + 1.3)), 40.0);
	rays *= exp(-r / (reach * 0.45)) * 0.18 * spread;
	return vec2(halo * 0.9 + heart + rays, heart);
}

void fragment() {
	vec2 s = shine(UV, sun_a) + shine(UV, sun_b);
	float l = clamp(s.x, 0.0, 1.0);
	float on = smoothstep(0.0, 0.04, spread);
	COLOR = vec4(mix(light.rgb, core.rgb, clamp(s.y, 0.0, 1.0) * (1.0 - flood)), max(l * 0.92 * on, flood));
}
