## Hauling the mummy's sledge (plate II, spells 1-15): keep the beat the ox-driver calls.
##
## The ox-driver walks in front with his whip raised. It is drawn back and comes down on every
## beat, and his call sounds. Press on the beat (Space, Shift or a click) and the hauler leans
## into the rope, the ox heaves, and the whole train (the ox, the driver, the hauler, the censer
## priest and the sledge) gains a step. A press off the beat lets the rope go slack and the
## sledge slips back; a beat let pass, and the bier stops. Taking up the rope opens the vignette
## out over the start of plate I, where the train stands BACK px behind its drawn place; it is
## done when it stands where it is drawn again. The drawn hauler is not there until then: you
## take the rope in his place (the level leans your figure on the beat, see `lean()`), and he
## appears once the sledge is home.
##
## The figures are the layers of the `haul` folder of art/procession1-15.mdp, cut by
## tools/cut_procession300.py (sprites haul_*); positions are strip pixels.
class_name HaulSledge
extends Node2D

signal said(who: String, text: String)
signal finished

enum Phase { IDLE, OPENING, PLAYING, CLOSING }

const BEAT := 0.9             ## s between beats
const WINDOW := 0.17          ## s either side of a beat that a press still counts
const COUNT_IN := 2           ## beats the driver calls before the first pull counts
const BACK := 260.0           ## strip px the train stands behind its drawn place at the start
const PULLS := 12             ## good pulls that bring it home
const SLIP := 14.0            ## strip px it slips back when the rope goes slack
const FOLLOW := 6.0           ## how quickly the train closes on where the pulls have brought it (1/s)
const OPEN := 0.8             ## s for the vignette to open out, and to close again
const STRIKE := 0.55          ## the whip comes down this far (radians) below where it is drawn ...
const WIND := 0.2             ## ... having been drawn back this far above it
const ELBOW := Vector2(11122, 292)          ## the driver's elbow: his whip arm swings about it
const COVER := Rect2(12462, 186, 373, 339)  ## the start of plate I, covered while the vignette is open
const PIECES := ["haul_sledge", "haul_hauler", "haul_driver", "haul_whip"]
const RATE := 22050

var active := false           ## the rope is taken up
var instant := false          ## the autotest: open and close at once
var done := false             ## the sledge stands where it is drawn
var phase := Phase.IDLE
var offset := 0.0             ## how far behind its drawn place the train is now (strip px)
var target := 0.0             ## ... and where the pulls so far have brought it
var clock := 0.0              ## s since the first beat
var good := 0                 ## good pulls so far
var _pulled := -1             ## the last beat pulled on
var _judged := -1             ## the last beat looked at for a miss
var _heave := 0.0             ## 1 on a good pull, dying away
var _slack := 0.0             ## 1 when the rope goes slack, dying away
var _told := {}               ## what the driver has already said, so he does not repeat himself
var _nodes := {}              ## piece -> Node2D
var _home := {}               ## piece -> Node2D position as drawn
var _ox: Node2D
var _ox_home := Vector2.ZERO
var _cover: ColorRect
var _tween: Tween
var _beat_sound: AudioStreamPlayer
var _pull_sound: AudioStreamPlayer


func setup(sprites: Dictionary, art: String, ox: Node2D, papyrus: Material, cover_parent: Node, cover_index: int) -> void:
	for nm in PIECES:
		var s: Dictionary = sprites[nm]
		var r := Rect2(s.x, s.y, s.w, s.h)
		var pivot := Node2D.new()
		var sp := Sprite2D.new()
		sp.texture = load(art % nm)
		sp.centered = false
		match nm:
			"haul_whip":            # swings about the elbow
				pivot.position = ELBOW
			"haul_hauler":          # leans about his feet
				pivot.position = Vector2(r.get_center().x, r.end.y)
			_:
				pivot.position = r.position
		sp.position = r.position - pivot.position
		pivot.add_child(sp)
		add_child(pivot)
		_nodes[nm] = pivot
		_home[nm] = pivot.position
	_ox = ox
	_cover = ColorRect.new()
	_cover.material = papyrus
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.position = COVER.position
	_cover.size = COVER.size
	_cover.visible = false
	cover_parent.add_child(_cover)
	cover_parent.move_child(_cover, cover_index)
	_beat_sound = _player(_tone(70.0, 0.32, 11.0, 0.5))    # the driver's call: a low drum
	_pull_sound = _player(_tone(140.0, 0.18, 18.0, 0.9))   # the rope taking the strain


func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	active = false
	done = false
	phase = Phase.IDLE
	offset = 0.0
	target = 0.0
	_cover.visible = false
	_nodes.haul_hauler.visible = false
	_place()


## How you lean on the rope in the hauler's place: (x shift, rotation about the feet).
func lean() -> Vector2:
	return Vector2(7.0 * _heave - 5.0 * _slack, 0.045 * _heave - 0.03 * _slack)


## The drawn hauler on his rope (only once the sledge is home).
func hauler_shown() -> bool:
	return _nodes.haul_hauler.visible


## The drawing of a figure of the hauling ("haul_sledge", "haul_hauler", ...), for the hover glow.
func sprite_of(piece: String) -> Sprite2D:
	return _nodes[piece].get_child(0) if _nodes.has(piece) else null


## The ox's resting place as drawn (the level sets it before the haul moves the ox).
func set_ox_home(p: Vector2) -> void:
	_ox_home = p
	_place()


## Take up the rope: the vignette opens out and the train stands back, ready for the driver's call.
func start() -> void:
	if active or done:
		return
	active = true
	phase = Phase.OPENING
	good = 0
	_pulled = -1
	_judged = COUNT_IN - 1
	_told.clear()
	clock = -OPEN
	_cover.visible = true
	_cover.modulate.a = 0.0
	if instant:
		_open(1.0)
		_begin()
		return
	_tween = create_tween()
	_tween.tween_method(_open, 0.0, 1.0, OPEN).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(_begin)
	_say("Ox-driver", "The sledge has slid back and the rope hangs slack. Watch my whip: when it comes down, heave! ([space], [shift] or click)")


## Let go of the rope: the train stands where it stalled, and you can take it up again.
func quit() -> void:
	if not active or phase == Phase.CLOSING:
		return
	_close(false)
	_say("Scribe", "You let go of the rope. Take it up again when you are ready.")


## A press: on the beat it is a pull, off it the rope goes slack.
func press() -> void:
	if phase != Phase.PLAYING:
		return
	var k := roundi(clock / BEAT)
	var off := clock - k * BEAT
	if k < COUNT_IN:
		_say("Ox-driver", "Not yet: wait for my call.")
		return
	if absf(off) <= WINDOW and k != _pulled:
		_pull(k)
	else:
		_slip("early" if off < 0.0 else "late")


## The next beat a pull can land on (s from now), for the autotest and hints.
func to_next_beat() -> float:
	var k := maxi(COUNT_IN, ceili(clock / BEAT))
	if k == _pulled:
		k += 1
	return k * BEAT - clock


func _process(delta: float) -> void:
	if not active:
		return
	if phase == Phase.PLAYING:
		var before := clock
		clock += delta
		# the driver's call on every beat
		if floori(clock / BEAT) > floori(before / BEAT):
			var k := floori(clock / BEAT)
			_beat_sound.play()
			if k == 0:
				_say("Ox-driver", "Ready...")
			elif k == 1:
				_say("Ox-driver", "...and...")
			elif k == COUNT_IN:
				_say("Ox-driver", "Heave!")
		# a beat let pass: the bier stops
		var last := floori((clock - WINDOW) / BEAT)
		if last > _judged:
			_judged = last
			if last >= COUNT_IN and last != _pulled:
				_once("missed", "Ox-driver", "Heave when the whip comes down! Without you the bier stops.")
	_heave = maxf(0.0, _heave - delta * 2.5)
	_slack = maxf(0.0, _slack - delta * 2.0)
	offset = lerpf(offset, target, 1.0 - exp(-FOLLOW * delta))
	if phase == Phase.PLAYING and target <= 0.0 and offset < 0.5:
		offset = 0.0
		_close(true)
	_place()


func _begin() -> void:
	phase = Phase.PLAYING
	clock = -0.001


func _open(k: float) -> void:
	_cover.modulate.a = k
	offset = BACK * k * k * (3.0 - 2.0 * k)
	target = offset
	_place()


func _close(won: bool) -> void:
	phase = Phase.CLOSING
	if _tween and _tween.is_valid():
		_tween.kill()
	if instant:
		_cover.modulate.a = 0.0
		_closed(won)
		return
	_tween = create_tween()
	if not won:      # the train stands where it stalled, as drawn
		var from := offset
		_tween.tween_method(func(k: float):
			offset = from * (1.0 - k)
			target = offset
			_place(), 0.0, 1.0, OPEN)
	_tween.parallel().tween_property(_cover, "modulate:a", 0.0, OPEN)
	_tween.tween_callback(_closed.bind(won))


func _closed(won: bool) -> void:
	_cover.visible = false
	active = false
	phase = Phase.IDLE
	offset = 0.0
	target = 0.0
	_place()
	if won:
		done = true
		var h: Node2D = _nodes.haul_hauler    # he takes up the rope as drawn
		h.visible = true
		h.modulate.a = 1.0 if instant else 0.0
		if not instant:
			h.create_tween().tween_property(h, "modulate:a", 1.0, OPEN)
		finished.emit()


func _pull(k: int) -> void:
	_pulled = k
	good += 1
	target = maxf(0.0, target - BACK / PULLS)
	_heave = 1.0
	_pull_sound.play()
	if good == 1:
		_say("Ox-driver", "Heave! Again, on every call.")
	elif good == PULLS / 2:
		_say("Ox-driver", "Halfway. Keep the beat!")


func _slip(when: String) -> void:
	target = minf(BACK, target + SLIP)
	_slack = 1.0
	_once("slack_" + when, "Ox-driver", "Too %s! The rope goes slack and the sledge slips back. Heave as the whip comes down." % when)


## Put the train where it is: drawn place + offset, the hauler leaning into a pull (or lurching
## when the rope goes slack), the ox heaving, the whip on the beat.
func _place() -> void:
	if _nodes.is_empty():
		return
	var d := Vector2(offset, 0.0)
	for nm in PIECES:
		_nodes[nm].position = _home[nm] + d
		_nodes[nm].rotation = 0.0
	var h: Node2D = _nodes.haul_hauler
	h.position.x += 7.0 * _heave - 5.0 * _slack     # leans back on the rope / lurches forward
	h.rotation = 0.045 * _heave - 0.03 * _slack
	_nodes.haul_whip.rotation = _whip_angle() if active and phase == Phase.PLAYING else 0.0
	if _ox:
		_ox.position = _ox_home + d + Vector2(-6.0 * _heave, 0.0)


## The whip on the beat: just struck at the beat, back to where it is drawn, drawn back a little
## further, and down again on the next beat.
func _whip_angle() -> float:
	var u := fposmod(clock, BEAT) / BEAT
	if u < 0.35:
		return lerpf(-STRIKE, 0.0, ease(u / 0.35, 0.4))
	if u < 0.8:
		return lerpf(0.0, WIND, ease((u - 0.35) / 0.45, -1.6))
	var v := (u - 0.8) / 0.2
	return lerpf(WIND, -STRIKE, v * v)


func _say(who: String, text: String) -> void:
	said.emit(who, text)


func _once(key: String, who: String, text: String) -> void:
	if _told.has(key):
		return
	_told[key] = true
	_say(who, text)


func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -6.0
	add_child(p)
	return p


## A short struck sound: a low tone dying away, with a little noise at the start.
static func _tone(freq: float, dur: float, decay: float, noise: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in n:
		var t := float(i) / RATE
		var v := sin(TAU * freq * t * (1.0 - 0.3 * t / dur)) * exp(-t * decay)
		v += noise * rng.randf_range(-1.0, 1.0) * exp(-t * decay * 6.0)
		data.encode_s16(i * 2, int(clampf(v * 0.7, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
