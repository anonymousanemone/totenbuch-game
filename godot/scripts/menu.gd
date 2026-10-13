## Level select. `-- --level=procession` or `-- --level=dangers` on the command line skips it.
extends Control

const LEVELS := [
	["procession", "The Funeral Procession", "Spells 1–15 · pl. I–VI", "Haul the sledge, restore the standards, rebuild the offering table."],
	["cosmos", "The Night Journey", "Spell 17 · pl. VII–XI", "The lions of the horizon, the ba, the cat and the snake, the sun in Ra's boat."],
	["field", "The Field of Offerings", "Spell 110 · pl. XLI", "Plough, sow, reap and thresh; feed the gods; sail to the landing."],
	["hall", "The Weighing of the Heart", "Spell 125 · pl. L", "Ma'at, the balance, the 42 judges, Thoth and Osiris."],
	["dangers", "Dangers on the Road", "Spells 31–42 · pl. XVI–XIX", "Crocodiles, snakes, a beetle, Apep and the Eater of the Ass."],
]


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			_open.call_deferred(a.trim_prefix("--level="))
			return
	var bg := ColorRect.new()
	bg.color = Color("2a1d10")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Cormorant Garamond", "Georgia", "Times New Roman", "serif"])
	var title := Label.new()
	title.text = "Totenbuch"
	title.add_theme_font_override("font", serif)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("ead9b0"))
	v.add_child(title)
	var sub := Label.new()
	sub.text = "The Book of the Dead, from Lepsius's plates (1842). Choose a stretch of the scroll."
	sub.add_theme_font_override("font", serif)
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color("ead9b0", 0.7))
	v.add_child(sub)
	for l in LEVELS:
		var b := Button.new()
		b.text = "%s   ·   %s\n%s" % [l[1], l[2], l[3]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(560, 72)
		b.add_theme_font_override("font", serif)
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", Color("2e1d10"))
		b.add_theme_color_override("font_hover_color", Color("2e1d10"))
		for state in ["normal", "hover", "pressed"]:
			var s := StyleBoxFlat.new()
			s.bg_color = Color("fff4d8") if state == "hover" else Color("f3e8cc")
			s.border_color = Color("b89c64")
			s.set_border_width_all(1)
			s.set_corner_radius_all(6)
			s.content_margin_left = 18
			s.content_margin_top = 8
			s.content_margin_bottom = 8
			b.add_theme_stylebox_override(state, s)
		b.pressed.connect(_open.bind(l[0]))
		v.add_child(b)


func _open(level: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % level)
