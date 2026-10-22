## The whole scroll as the player walks it: its scenes in order, which are restored, and the
## settings, kept in user://scroll.cfg. An autoload (`Scroll`). A scene is built once
## scenes/<key>.tscn exists; scenes not yet built are skipped when moving on. Every built scene can
## be opened (nothing is locked yet).
extends Node

const SAVE := "user://scroll.cfg"
const MENU := "res://scenes/menu.tscn"

const ACTS := {
	"I": "Act I — Burial and going forth", "II": "Act II — Survival",
	"III": "Act III — Food, breath and transformations", "IV": "Act IV — The Field of Reeds",
	"V": "Act V — Gates and guardians", "VI": "Act VI — Amulets and strange creatures", "F": "Finale",
}
## In playing order: Lepsius's spell order, except the finale: Thoth opens the sky, then the weighing of the heart.
## Each scene's picture is assets/menu/<key>.png.
const SCENES := [
	{"key": "procession", "act": "I", "title": "The Funeral Procession", "spells": "1–15", "plates": "I–VI",
		"about": "Haul the sledge, restore the standards, rebuild the offering table, pour the water, open the mouth, and set up the stand before Ra."},
	{"key": "cosmos", "act": "I", "title": "The Night Journey", "spells": "17", "plates": "VII–XI",
		"about": "The lions of the horizon, the ba, the cat and the snake, the sun in Ra's boat."},
	{"key": "councils", "act": "I", "title": "The Councils", "spells": "18", "plates": "XI–XIII",
		"about": "The councils of the gods, one after another."},
	{"key": "mouth", "act": "I", "title": "Mouth and Heart", "spells": "21–29", "plates": "XIV–XV",
		"about": "Spells for the mouth and the heart."},
	{"key": "dangers", "act": "II", "title": "Dangers on the Road", "spells": "31–42", "plates": "XVI–XIX",
		"about": "Crocodiles, snakes, a beetle, Apep and the Eater of the Ass."},
	{"key": "survival", "act": "II", "title": "Survival and Sustenance", "spells": "43–63", "plates": "XX–XXIII",
		"about": "Food, water and breath for the dead."},
	{"key": "forth", "act": "III", "title": "Coming Forth by Day", "spells": "64–75", "plates": "XXIII–XXVII",
		"about": "Going out into the daylight."},
	{"key": "forms", "act": "III", "title": "Transformations", "spells": "76–88", "plates": "XXVIII–XXXIII",
		"about": "Taking the forms of the falcon, the phoenix, the swallow and the snake."},
	{"key": "ba", "act": "III", "title": "Ba and Tomb", "spells": "89–92", "plates": "XXXIII",
		"about": "The ba bird returns to the mummy, and goes out again."},
	{"key": "boats", "act": "III", "title": "Thoth and the Boats", "spells": "93–109", "plates": "XXXIV–XXXIX",
		"about": "Thoth, the palette, and the boats of the sky."},
	{"key": "field", "act": "IV", "title": "The Field of Offerings", "spells": "110", "plates": "XL–XLII",
		"about": "Plough, sow, reap and thresh; feed the gods; sail to the landing."},
	{"key": "souls", "act": "IV", "title": "The Souls of the Towns", "spells": "112–124", "plates": "XLIII–XLV",
		"about": "The souls of Pe, Nekhen and Hermopolis; Anubis leads the way."},
	{"key": "lake", "act": "V", "title": "The Lake of Fire", "spells": "126–143", "plates": "LI–LIX",
		"about": "The lake of fire and its baboons, the caverns and the boats."},
	{"key": "gates", "act": "V", "title": "The Gates", "spells": "144–146", "plates": "LX–LXVII",
		"about": "The seven arits, the twenty-one portals, the house of Osiris."},
	{"key": "baboons", "act": "V", "title": "The Baboon Gods", "spells": "147", "plates": "LXVII–LXVIII",
		"about": "Adoring the baboon gods."},
	{"key": "cows", "act": "V", "title": "The Seven Cows", "spells": "148", "plates": "LXIX–LXX",
		"about": "The seven cows and their bull."},
	{"key": "mounds", "act": "V", "title": "The Fourteen Mounds", "spells": "149–150", "plates": "LXXI–LXXIII",
		"about": "The fourteen mounds and their key."},
	{"key": "chamber", "act": "VI", "title": "Guarding the Body", "spells": "151–154", "plates": "LXXIV–LXXV",
		"about": "The burial chamber and its guardians."},
	{"key": "creatures", "act": "VI", "title": "Strange Creatures", "spells": "162–165", "plates": "LXXVII–LXXIX",
		"about": "The Ihet cow and the strange creatures of the last spells."},
	{"key": "doors", "act": "F", "title": "Thoth Opens the Sky", "spells": "161", "plates": "LXXVI",
		"about": "Thoth opens the doors of the sky."},
	{"key": "hall", "act": "F", "title": "The Weighing of the Heart", "spells": "125", "plates": "L",
		"about": "Ma'at, the balance, the 42 judges, Thoth and Osiris."},
]

var restored: Array[String] = []
var sound := 7                    ## 0..10
var fullscreen := false


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		restored.assign(cfg.get_value("progress", "restored", []))
		sound = cfg.get_value("settings", "sound", sound)
		fullscreen = cfg.get_value("settings", "fullscreen", fullscreen)
	_apply()


func is_built(key: String) -> bool:
	return ResourceLoader.exists(_path(key))


## The first unfinished built scene; empty once every playable scene is complete.
func current() -> String:
	for s in SCENES:
		if is_built(s.key) and not s.key in restored:
			return s.key
	return ""


func scene(key: String) -> Dictionary:
	return SCENES.filter(func(s): return s.key == key)[0]


func open(key: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(_path(key))


## The next playable scene; unfinished chapters on the map are skipped.
func next_built(key: String) -> Dictionary:
	var index: int = SCENES.find(scene(key))
	for entry in SCENES.slice(index + 1):
		if is_built(entry.key):
			return entry
	return {}


## A scene is done: it is restored, and the next built scene opens (the menu after the last).
func finish(key: String) -> void:
	get_tree().paused = false
	if not key in restored:
		restored.append(key)
		_save()
	var next := next_built(key)
	if not next.is_empty():
		open(next.key)
	else:
		get_tree().change_scene_to_file(MENU)


func set_sound(value: int) -> void:
	sound = clampi(value, 0, 10)
	_apply()
	_save()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply()
	_save()


## Start again from the funeral procession.
func begin_again() -> void:
	restored.clear()
	_save()


func _apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(sound / 10.0))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "restored", restored)
	cfg.set_value("settings", "sound", sound)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.save(SAVE)


func _path(key: String) -> String:
	return "res://scenes/%s.tscn" % key
