## Shared puzzle instructions, success, feedback and Hint-button hints.
## Each scene owns hint progress; ordinary clues and instructions never advance it.
extends RefCounted

const MORE_HINTS := " (click hint again if you're still confused)"
const DATA_PATH := "res://assets/puzzles.json"
static var _catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
var data: Dictionary = _catalog
var _steps := {}


func reset() -> void:
	_steps.clear()


func find(puzzle: String, destination := "default") -> String:
	var entries: Dictionary = data.puzzles[puzzle].hints.find
	return entries.get(destination, entries.default) + MORE_HINTS


func advance(puzzle: String, phase: String) -> String:
	var entries: Array = data.puzzles[puzzle].hints.phases[phase]
	var key := puzzle + "/" + phase
	var step: int = _steps.get(key, 0)
	_steps[key] = mini(step + 1, entries.size() - 1)
	return entries[step].text + (MORE_HINTS if step < entries.size() - 1 else "")


static func message(id: String) -> String:
	return _catalog.messages[id]


## Instructions/success are plain strings; feedback is selected by event name.
static func text(puzzle: String, field: String, variant := "default") -> String:
	var entry = _catalog.puzzles[puzzle][field]
	if entry is String:
		return entry
	return entry[variant]
