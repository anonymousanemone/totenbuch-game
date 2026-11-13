## The Gates (spells 144–147): Survival's exploration, plus the spell-145 pylons. Each pylon's
## adorer stays hidden until its keeper's name is given (`name_given`), and each spell-147 gate's
## adorer until `reveal_adorer` is called for it; the avatar is a copy of the first adorer, and the
## plumes answer every naming (PylonPlumes).
extends "res://scripts/survival/survival.gd"

const ADORER_FADE := 0.6    ## seconds for an adorer to appear


func reset() -> void:
	super()
	for id in figures:
		if id.ends_with("_adorer"):
			figures[id].visible = Scroll.viewing     # viewing: every adorer is shown, as drawn
			figures[id].modulate.a = 1.0
		elif id.begins_with("spell145_pylon") and id.count("_") == 1:
			PylonPlumes.still(figures[id])


## The spell-145 naming puzzle (not built yet) calls this when the player names pylon `number`'s
## keeper: the plumes answer, and a right name brings the adorer kneeling before the pylon.
func name_given(number: int, accepted: bool) -> void:
	PylonPlumes.react(figures["spell145_pylon%d" % number], accepted)
	if accepted:
		reveal_adorer("spell145_pylon%d_adorer" % number)


## Fades in the hidden adorer `id` (e.g. "spell147_gate3_adorer"); once shown, he stays.
func reveal_adorer(id: String) -> void:
	var adorer: Sprite2D = figures[id]
	if adorer.visible:
		return
	adorer.modulate.a = 0.0
	adorer.show()
	adorer.create_tween().tween_property(adorer, "modulate:a", 1.0, ADORER_FADE)
