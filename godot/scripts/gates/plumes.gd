## The plumes on a spell-145 pylon answer a naming: for the right name they stand taller and fan
## out, for a wrong one they sag and lean apart, and then settle back into their sway
## (plumes.gdshader). Not attached yet: the spell-145 naming puzzle will call `react`.
class_name PylonPlumes
extends RefCounted

const RISE := 0.35      ## seconds to rise (or sag)
const HOLD := 1.2       ## seconds held there
const SETTLE := 1.4     ## seconds back to the idle sway


## `pylon` is a spell-145 pylon sprite with the plumes material. A new reaction replaces one
## still running.
static func react(pylon: Sprite2D, accepted: bool) -> Tween:
	var material := pylon.material as ShaderMaterial
	if pylon.has_meta("plumes_tween"):
		(pylon.get_meta("plumes_tween") as Tween).kill()
	var set_lift := func(value: float) -> void: material.set_shader_parameter("lift", value)
	var target := 1.0 if accepted else -1.0
	var current = material.get_shader_parameter("lift")
	var tween := pylon.create_tween()
	tween.tween_method(set_lift, 0.0 if current == null else float(current), target, RISE) \
		.set_trans(Tween.TRANS_BACK if accepted else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD)
	tween.tween_method(set_lift, target, 0.0, SETTLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pylon.set_meta("plumes_tween", tween)
	return tween


## Stop any reaction and return the plumes to their idle sway.
static func still(pylon: Sprite2D) -> void:
	if pylon.has_meta("plumes_tween"):
		(pylon.get_meta("plumes_tween") as Tween).kill()
		pylon.remove_meta("plumes_tween")
	(pylon.material as ShaderMaterial).set_shader_parameter("lift", 0.0)
