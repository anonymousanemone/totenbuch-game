extends RefCounted

enum Kind { TAKE_PLACE, DRAG }


static func is_exit(event: InputEvent, kind: Kind) -> bool:
	return event.is_action_pressed("ui_cancel") or (kind == Kind.DRAG and (
		event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")))
