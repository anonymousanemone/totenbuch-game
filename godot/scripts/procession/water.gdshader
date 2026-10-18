// The stream of purifying water (plate V) drawing itself in from the jar. `path` holds how far
// along the stream each pixel lies from the spout (1..255; 0 = no ink), cut beside the stream by
// tools/cut_procession300.py. Up to `reveal` (0..1) the stream is ink; beyond it a faint dotted
// ghost of the line shows where the water has to run.
shader_type canvas_item;

uniform sampler2D path : filter_nearest;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float ghost = 0.22;          // how strong the dotted ghost is
uniform float dashes = 48.0;         // dashes along the whole line
uniform float wet = 0.03;            // the stretch just behind the front shows darker, still running

void fragment() {
	float v = texture(path, UV).r * 255.0;
	float along = clamp((v - 1.0) / 254.0, 0.0, 1.0);
	if (v < 0.5) {
		discard;
	}
	if (along > reveal) {
		COLOR.a *= ghost * step(0.5, fract(along * dashes));
	} else if (reveal < 1.0 && along > reveal - wet) {
		COLOR.rgb *= 0.6;
	}
}
