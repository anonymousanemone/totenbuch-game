## Step driver for playtests: keeps the game running and takes one action at a time.
## Each command (click, drag, key, wait, look) goes in over a local socket and comes back as one reply:
## a rendered frame, the band's text with when it appeared and cleared, and the clock. Game time moves
## only while an action or a wait runs (60 frames to the second); between commands the game does not run at all.
## Start it with `python3 godot/tests/step.py start` (see README.md, "Playtest step driver"), or by hand:
##   godot --path godot --fixed-fps 60 --script res://tests/step_driver.gd -- --level=procession --out=DIR
## `--fixed-fps 60` is required: it makes every frame exactly 1/60 s however long the driver waits between them.
## Flags after `--`: --level=KEY (and --view) as in the game, --port=N, --out=DIR, --size=WxH, --fresh.
extends SceneTree

const FPS := 60
const DEFAULT_PORT := 17777
const DEFAULT_SIZE := Vector2i(1280, 720)
const MOVE_SECONDS := 1.0 / FPS      ## the pointer arrives one frame before the button goes down
const PRESS_SECONDS := 0.05          ## how long a click or key press is held
const SETTLE_SECONDS := 0.3          ## time an action lets its effect play out before the reply
const DRAG_SECONDS := 0.6            ## default time to carry something from start to end
const KEY_SECONDS := 0.05
const MAX_WAIT := 120.0
const WORDS_PER_SECOND := 4.0        ## reading speed the playtest skill measures lines against
const READING_EXTRA := 1.0

var _server := TCPServer.new()
var _out := ""
var _size := DEFAULT_SIZE
var _frames := 0                     ## game frames advanced since the first look
var _step := 0
var _events: Array = []              ## band events since the last reply
var _line := {}                      ## the line now on the band: who, text, since, fading, fade_at
var _last_hash := 0
var _mouse := Vector2.ZERO
var _save_path := "user://scroll.cfg"
var _save_bytes := PackedByteArray()
var _log: FileAccess
var _peer: StreamPeerTCP


func _initialize() -> void:
	_boot.call_deferred()


func _boot() -> void:
	var args := OS.get_cmdline_user_args()
	var port := DEFAULT_PORT
	_out = OS.get_temp_dir().path_join("totenbuch-step-%d" % DEFAULT_PORT)
	for a in args:
		if a.begins_with("--port="):
			port = a.trim_prefix("--port=").to_int()
			_out = OS.get_temp_dir().path_join("totenbuch-step-%d" % port)
		elif a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
		elif a.begins_with("--size="):
			var parts := a.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_size = Vector2i(parts[0].to_int(), parts[1].to_int())
	DirAccess.make_dir_recursive_absolute(_out)
	_log = FileAccess.open(_out.path_join("log.jsonl"), FileAccess.WRITE)
	_save_bytes = FileAccess.get_file_as_bytes(_save_path)   # restored after every command: a playtest never writes the real save
	Input.use_accumulated_input = false
	root.size = _size
	root.min_size = _size
	if "--fresh" in args:
		root.get_node("Scroll").restored.clear()   # autoloads are not in scope when a script replaces the main loop
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for i in 300:      # the menu hands over to the level named by --level=, as it does in the game
		await process_frame
		if current_scene != menu and is_instance_valid(current_scene):
			break
	await _advance(0.5)
	_guard_save()
	_frames = 0      # the clock starts at the first look, with whatever the band shows then
	_line = {}
	_events.clear()
	_sample_band()
	var error := _server.listen(port, "127.0.0.1")
	if error != OK:
		printerr("step driver: cannot listen on port %d (%s)" % [port, error_string(error)])
		quit(1)
		return
	print("STEP DRIVER READY port=%d out=%s" % [port, _out])
	_serve()


func _serve() -> void:
	while true:
		var line := _wait_for_command()
		if line == "":
			_peer.disconnect_from_host()      # a connection that sends nothing is only a check that the driver is up
			continue
		var reply := await _run(line)
		_events.clear()
		_peer.put_data((JSON.stringify(reply) + "\n").to_utf8_buffer())
		_peer.poll()
		_peer.disconnect_from_host()
		if reply.get("quit", false):
			quit(0)
			return


## Blocks until a client sends a line. No frame runs meanwhile, so game time stands still and the window
## does not repaint until the next action (the OS may call it unresponsive; it is waiting for the next command).
func _wait_for_command() -> String:
	while true:
		if not _server.is_connection_available():
			OS.delay_msec(5)
			continue
		_peer = _server.take_connection()
		var buffer := PackedByteArray()
		var started := Time.get_ticks_msec()
		while Time.get_ticks_msec() - started < 5000:
			_peer.poll()
			var available := _peer.get_available_bytes()
			if available > 0:
				buffer.append_array(_peer.get_data(available)[1])
				if buffer.has(10):
					break
			elif _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
				break
			else:
				OS.delay_msec(1)
		return buffer.get_string_from_utf8().strip_edges()
	return ""


# ---------------------------------------------------------------- commands

func _run(line: String) -> Dictionary:
	var parsed = JSON.parse_string(line)
	if not parsed is Dictionary or not parsed.has("cmd"):
		return {"ok": false, "error": "send one JSON object with a \"cmd\""}
	var command: Dictionary = parsed
	var settle: float = clampf(float(command.get("settle", SETTLE_SECONDS)), 1.0 / FPS, MAX_WAIT)
	var start := _clock()
	var name := String(command.cmd)
	match name:
		"look":
			pass
		"wait":
			await _advance(clampf(float(command.get("seconds", 1.0)), 0.0, MAX_WAIT))
		"move":
			_motion(_point(command, "x", "y"), 0)
			await _advance(MOVE_SECONDS + settle)
		"click":
			var button := MOUSE_BUTTON_RIGHT if String(command.get("button", "left")) == "right" else MOUSE_BUTTON_LEFT
			await _click(_point(command, "x", "y"), button, settle)
		"drag":
			await _drag(_point(command, "x1", "y1"), _point(command, "x2", "y2"),
				clampf(float(command.get("seconds", DRAG_SECONDS)), 0.1, MAX_WAIT), settle)
		"key":
			var code := OS.find_keycode_from_string(String(command.get("key", "")))
			if code == KEY_NONE:
				return {"ok": false, "error": "unknown key \"%s\"" % command.get("key", "")}
			await _press_key(code, clampf(float(command.get("seconds", KEY_SECONDS)), 0.0, MAX_WAIT), settle)
		"quit":
			_guard_save()
			return {"ok": true, "quit": true}
		_:
			return {"ok": false, "error": "unknown cmd \"%s\"" % name}
	_guard_save()
	return await _reply(name, command, start)


func _point(command: Dictionary, kx: String, ky: String) -> Vector2:
	return Vector2(float(command.get(kx, 0)), float(command.get(ky, 0)))


func _click(p: Vector2, button: MouseButton, settle: float) -> void:
	_motion(p, 0)
	await _advance(MOVE_SECONDS)
	_button(p, button, true)
	await _advance(PRESS_SECONDS)
	_button(p, button, false)
	await _advance(settle)


func _drag(from: Vector2, to: Vector2, seconds: float, settle: float) -> void:
	_motion(from, 0)
	await _advance(MOVE_SECONDS)
	_button(from, MOUSE_BUTTON_LEFT, true)
	await _advance(PRESS_SECONDS)
	var steps := maxi(2, roundi(seconds * FPS))
	for i in range(1, steps + 1):
		_motion(from.lerp(to, float(i) / steps), MOUSE_BUTTON_MASK_LEFT)
		await _advance(1.0 / FPS)
	_button(to, MOUSE_BUTTON_LEFT, false)
	await _advance(settle)


func _press_key(code: Key, seconds: float, settle: float) -> void:
	_key(code, true)
	await _advance(seconds)
	_key(code, false)
	await _advance(settle)


# ---------------------------------------------------------------- input

## Positions come in as pixels of the frame the driver returns, which are the window's own pixels,
## so an event carries them as they are (the engine maps window pixels to the game's coordinates).
func _window_point(p: Vector2) -> Vector2:
	return p


func _motion(p: Vector2, mask: int) -> void:
	var event := InputEventMouseMotion.new()
	event.position = _window_point(p)
	event.global_position = event.position
	event.relative = _window_point(p) - _window_point(_mouse)
	event.button_mask = mask
	_mouse = p
	Input.parse_input_event(event)


func _button(p: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = _window_point(p)
	event.global_position = event.position
	event.button_index = button
	event.pressed = pressed
	event.button_mask = (1 << (button - 1)) if pressed else 0
	_mouse = p
	Input.parse_input_event(event)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.shift_pressed = pressed and code == KEY_SHIFT
	Input.parse_input_event(event)


# ---------------------------------------------------------------- time and the band

func _clock() -> float:
	return snappedf(float(_frames) / FPS, 0.001)


## Lets game time run for `seconds` (whole frames), sampling the band on every frame, and returns once the
## last of those frames is drawn, so the reply's image shows the state the clock reached.
func _advance(seconds: float) -> void:
	var count := roundi(seconds * FPS)
	if count <= 0:
		_sample_band()
		return
	for i in count:
		await process_frame
		_frames += 1
		_sample_band()
	await RenderingServer.frame_post_draw


func _hud() -> Node:
	if current_scene == null or not is_instance_valid(current_scene):
		return null
	var hud = current_scene.get("hud")
	return hud if is_instance_valid(hud) else null


## What the band shows now: the speaker's tag, the line as displayed (markup removed) and its opacity.
func _band_now() -> Dictionary:
	var hud := _hud()
	if hud == null or not is_instance_valid(hud._say):
		return {}
	var tag: Node = hud._tag
	return {
		"who": hud._tag_label.text if is_instance_valid(tag) and tag.visible else "",
		"text": hud._say.get_parsed_text().strip_edges(),
		"alpha": snappedf(hud._say.modulate.a, 0.01),
	}


func _sample_band() -> void:
	var band := _band_now()
	var text: String = band.get("text", "")
	var now := _clock()
	if text == "" or band.alpha <= 0.01:
		if not _line.is_empty():
			_close_line(now, "cleared")
		return
	if not _line.is_empty() and _line.text == text and _line.who == band.who:
		if band.alpha < 0.99 and not _line.fading:
			_line.fading = true
			_line.fade_at = now
			_events.append({"t": now, "event": "fading", "who": band.who, "text": text})
		elif band.alpha >= 0.99 and _line.fading:
			_line.fading = false
		return
	if not _line.is_empty():
		_close_line(now, "replaced")
	_line = {"who": band.who, "text": text, "since": now, "fading": false, "fade_at": 0.0}
	_events.append({"t": now, "event": "appeared", "who": band.who, "text": text})


## `how`: "cleared" (it went away) or "replaced" (another line took its place). `shown_for` runs to the start of the fade.
func _close_line(now: float, how: String) -> void:
	var until: float = _line.fade_at if _line.fading else now
	var shown_for := snappedf(until - _line.since, 0.001)
	var words: int = _line.text.split(" ", false).size()
	var reading := snappedf(words / WORDS_PER_SECOND + READING_EXTRA, 0.01)
	_events.append({"t": now, "event": how, "who": _line.who, "text": _line.text, "shown_for": shown_for,
		"words": words, "reading_time": reading, "cut_short": shown_for < reading})
	_line = {}


# ---------------------------------------------------------------- the reply

## The screen as a player sees it: which pop-up covers it, and what can be clicked (labels and centres only).
func _overlay() -> String:
	var hud := _hud()
	if hud == null:
		return "none"
	if hud._intro.visible:
		return "intro"
	if hud._outro.visible:
		return "outro"
	if hud._journal_page.visible:
		return "journal"
	return "none"


func _controls() -> Array:
	var found: Array = []
	if current_scene == null or not is_instance_valid(current_scene):
		return found
	for node in current_scene.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if not button.is_visible_in_tree() or button.disabled:
			continue
		var label := ""
		if button is Button:
			label = (button as Button).text.strip_edges()
		if label == "":
			label = button.tooltip_text.strip_edges()
		var centre: Vector2 = root.get_final_transform() * button.get_global_rect().get_center()   # frame pixels
		found.append({"label": label, "x": roundi(centre.x), "y": roundi(centre.y)})
	return found


func _reply(name: String, command: Dictionary, start: float) -> Dictionary:
	var image := root.get_texture().get_image()
	var digest: int = hash(image.get_data())
	_step += 1
	var file := _out.path_join("%04d_%s.png" % [_step, name])
	image.save_png(file)
	var band := _band_now()
	var current := {}
	if not _line.is_empty():
		current = {"who": _line.who, "text": _line.text, "on_screen_for": snappedf(_clock() - _line.since, 0.001),
			"fading": _line.fading}
	var reply := {
		"ok": true,
		"step": _step,
		"action": name,
		"t": _clock(),
		"took": snappedf(_clock() - start, 0.001),
		"frame": file,
		"frame_size": [image.get_width(), image.get_height()],
		"screen_changed": digest != _last_hash,
		"overlay": _overlay(),
		"band": current,
		"band_events": _events.duplicate(true),
		"controls": _controls(),
	}
	_last_hash = digest
	if band.is_empty() and _hud() == null:
		reply["note"] = "no band on this screen"
	var logged := reply.duplicate()
	logged["command"] = command
	_log.store_line(JSON.stringify(logged))
	_log.flush()
	return reply


## A playtest must not change the player's real progress: put the save file back as it was at start.
func _guard_save() -> void:
	var now := FileAccess.get_file_as_bytes(_save_path)
	if now == _save_bytes:
		return
	if _save_bytes.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))
		return
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_buffer(_save_bytes)
		file.close()
