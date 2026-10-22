// A soft glow around a drawing, for what the pointer is over (and, in pale green, for what a
// task just set right: UI.success_flash). Drawn behind the sprite, on a
// quad grown by `pad` texture px all round so the glow can spill past the drawing's edges.
shader_type canvas_item;

// Edit hover colors here; success uses UI.SUCCESS_GLOW. Unknown levels use default_color.
uniform vec4 default_color : source_color = vec4(1.0, 0.76, 0.28, 0.6);
uniform vec4 procession : source_color = vec4(1.0, 0.76, 0.28, 0.6);
uniform vec4 danger : source_color = vec4(0.95, 0.62, 0.22, 0.6);
uniform vec4 success : source_color;   // UI.SUCCESS_GLOW: transparent UI band green
uniform int level : hint_enum("Default", "Procession", "Danger", "Success") = 0;
uniform float pad = 9.0;                       // texture px the glow reaches out
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0); // the drawing's UV rect (an AtlasTexture's region)
uniform float strength = 0.0;                  // 0..1, faded in and out

void vertex() {
	vec2 corner = (UV - region.xy) / region.zw * 2.0 - 1.0;    // -1 or 1 at each corner
	VERTEX += corner * pad;
	UV += corner * pad * TEXTURE_PIXEL_SIZE;
}

float ink(sampler2D tex, vec2 uv) {
	vec2 inside = step(region.xy, uv) * step(uv, region.xy + region.zw);
	return texture(tex, uv).a * inside.x * inside.y;
}

void fragment() {
	float a = 0.0;
	for (int i = 0; i < 16; i++) {
		float ang = float(i) * 0.3927;
		vec2 dir = vec2(cos(ang), sin(ang));
		for (int j = 1; j <= 3; j++) {
			float r = float(j) / 3.0;
			a = max(a, ink(TEXTURE, UV + dir * r * pad * TEXTURE_PIXEL_SIZE) * (1.0 - r * 0.85));
		}
	}
	a = max(a, ink(TEXTURE, UV));
	vec4 glow = default_color;
	if (level == 1) {
		glow = procession;
	} else if (level == 2) {
		glow = danger;
	} else if (level == 3) {
		glow = success;
	}
	COLOR = vec4(glow.rgb, glow.a * a * strength);
}
