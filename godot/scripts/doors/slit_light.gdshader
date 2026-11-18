// The light beyond the doors of the sky (spell 161): once the door is open, a glow swells from a slit down the
// middle of the dark opening, with faint fine rays, and floods the screen. The same light as the close of the
// procession (procession/light.gdshader), from a line instead of two suns. Drawn on a full-screen rect; positions
// in its UV.
shader_type canvas_item;

uniform float slit_x = 0.5;                     // the slit: its x, and where it starts and ends
uniform float slit_top = 0.1;
uniform float slit_bottom = 0.9;
uniform float aspect = 1.7778;                  // width / height of the screen
uniform float spread = 0.0;                     // 0..1: how far the glow reaches
uniform float flood = 0.0;                      // 0..1: the light fills the screen
uniform float turn = 0.0;                       // s: the rays drift slowly
uniform vec4 light : source_color = vec4(1.0, 0.95, 0.78, 1.0);   // lighter than the papyrus, warm
uniform vec4 core : source_color = vec4(1.0, 0.98, 0.9, 1.0);     // the heart of the slit

void fragment() {
	// distance from the slit (a vertical segment), in screen-height units
	vec2 nearest = vec2(slit_x, clamp(UV.y, slit_top, slit_bottom));
	vec2 d = (UV - nearest) * vec2(aspect, 1.0);
	float r = length(d);
	float reach = mix(0.01, 1.2, spread);
	float halo = exp(-r * r / (reach * reach * 0.3));
	float heart = smoothstep(0.004 + 0.03 * spread, 0.0, r);
	// fine rays fanning out from the middle of the slit, as from the procession's suns
	vec2 m = (UV - vec2(slit_x, (slit_top + slit_bottom) * 0.5)) * vec2(aspect, 1.0);
	float a = atan(m.y, m.x);
	float rays = pow(abs(sin(a * 11.0 + turn * 0.15)), 30.0) + 0.8 * pow(abs(sin(a * 17.0 - turn * 0.1 + 1.3)), 40.0);
	rays *= exp(-r / (reach * 0.45)) * 0.18 * spread;
	float l = clamp(halo * 0.9 + heart + rays, 0.0, 1.0);
	float on = smoothstep(0.0, 0.04, spread);
	COLOR = vec4(mix(light.rgb, core.rgb, clamp(heart, 0.0, 1.0) * (1.0 - flood)), max(l * 0.92 * on, flood));
}
