## Encounter descriptions and tuning, in scroll order. Distances use 200-dpi plate pixels.
extends RefCounted

## Encounters in play order. `boxes` are vignette frames from level.json; `spear` is the
## vignette's spear-bearer, who stands in for the player during the fight.
const ENCOUNTERS := [
	# crocodiles: `count` is how many must be turned back in all (the four drawn ones, then copies
	# of them); `speed` in plate px per second; `at_once` how many crawl at the same time; `red` the
	# chance that a crocodile comes red (only a thrust made while holding Shift turns those back; heka on
	# an ordinary one loses the fight); `both_sides` they come from left and right, and he turns
	{"id": "e31", "boxes": ["e31"], "kind": "crocs", "spear": "spear31", "task": 0, "tutorial": true,
		"foes": ["c31a", "c31b", "c31c", "c31d"], "first_speed": 120.0, "break": 6.0,
		# `waves` instead of one count: the lesson, a break while the heka word starts to flash, then
		# a wave with red ones (`red_order`: which launches come red, in order); each crocodile of a
		# wave `ramp` faster than the one before. A lost fight starts again from the first wave.
		"waves": [
			{"count": 3, "speed": 180.0, "ramp": 0.01, "interval": 3.0, "at_once": 1},
			{"count": 6, "speed": 200.0, "ramp": 0.01, "interval": 2.2, "at_once": 2, "red_order": [false, true, false, true, true, false]},
		],
		"intro": "Spell 31: crocodiles come to take your magic. The vignette opens out, and you are its spear-bearer; Space then thrusts the spear.",
		"hint": "Move up or down (↑ ↓ or W S) until the spear tip is level with the coming snout, and press Space as they touch.",
		"won": "The crocodiles turn away.",
		"label": "Crocodiles of spell 31", "note": "They come to take the magic of the deceased. Turned back with the spear."},
	{"id": "e32", "boxes": ["e32"], "kind": "crocs", "spear": "spear32", "task": 0,
		"foes": ["c32a", "c32b", "c32c", "c32d"], "both_sides": true,
		# harder than 31 and losable, but always possible: each crocodile is `ramp` faster than the
		# one before (210 -> about 420), and none reaches him within `min_gap` s of the one before
		"waves": [{"count": 14, "speed": 180.0, "ramp": 0.01, "interval": 0.8, "at_once": 2, "red": 0.35, "min_gap": 0.9}],
		"intro": "Spell 32: crocodiles from the four quarters of the sky, from both sides now, faster and two at a time. ← → turn you to face either way; ↑ ↓ move you.",
		"hint": "Turn to face the nearer crocodile (← →), bring the spear tip level with its snout (↑ ↓), then Space.",
		"won": "The crocodiles of the four quarters are turned back.",
		"label": "Crocodiles of spell 32", "note": "One for each quarter of the sky. Turned back two at a time."},
	# the lunging snake: it waits `rest` back from where it is drawn (out of reach) for `idle` s,
	# waves its tail (`wave` s, `tail` rad, `wave_hz`), squashes down (`crouch` s) and springs
	# (`snap` s) to his front leg. `head_tip`, `head_rect`, `tail_base`: in its picture's pixels.
	{"id": "e33", "boxes": ["e33"], "kind": "lunge", "spear": "spear33", "task": 1,
		# `marks`: the red mark's radius (plate px) for each strike in turn, smaller each time
		"foe": "snake33", "need": 3, "marks": [11.0, 8.0, 5.0], "rest": 33.0, "idle": [1.2, 2.4], "wave": 1.4, "tail": 0.26, "wave_hz": 2.2,
		"crouch": 0.35, "snap": 0.16, "head_tip": [122, 218], "head_rect": [68, 205, 58, 25], "tail_base": [28, 172],
		"intro": "Spell 33: a snake coils just out of reach of your spear. When its tail waves, it is about to spring. Press Space as it springs, so the spear point comes down on the red mark. Each strike, the mark grows smaller.",
		"hint": "Watch the tail wave, then the squash: thrust (Space) the moment it springs. Too early and your spear is already coming back up.",
		"won": "The snake falls.",
		"label": "The lunging snake", "note": "Spell 33, against a snake. Struck three times as it sprang."},
	# the snake on the ground, its back to him: red light, green light. It lies near the far (left)
	# edge of the opened vignette; he creeps up on it, forward only, at `creep` plate px/s. Every `away`
	# s it lifts its head (`tell` s, shorter with each strike; after the first strike a `fake` share of
	# lifts settle again), turns to look at him for `watch` s, and turns away again. Moving or thrusting
	# while it looks: it strikes. Struck, it slides `flee` plate px on toward the edge.
	# `head_rect`, `head_pivot` (it turns round on this spot), `eye`: in its picture's pixels.
	{"id": "e35", "boxes": ["e35"], "kind": "creep", "spear": "spear35", "task": 1,
		"foe": "snake35", "need": 3, "flee": 70.0, "creep": 90.0, "away": [1.2, 2.6], "tell": [0.6, 0.35],
		"watch": [1.0, 2.0], "fake": 0.3, "head_rect": [104, 42, 38, 23], "head_pivot": [123, 55], "eye": [114, 52],
		"intro": "Spell 35: a snake lies on the ground with its back to you. The vignette opens out. Creep up on it (←) and thrust (Space) when the ring under your spear point turns red. When it lifts its head, freeze: if it turns and sees you move, it strikes.",
		"hint": "Move only while its head lies flat and turned away. When the head lifts, let go of the keys and wait until it looks away again. Struck three times, it lies still.",
		"won": "The snake on the ground lies still.",
		"label": "The snake on the ground", "note": "Spell 35. Crept up on from behind and struck three times."},
	# the roach: `count` beetles (the drawn one and copies), each to be pinned once by the spear
	# point. Each darts at `dart` (plate px/s), rests `rest` s, and every `bait_every` darts stops
	# by the spear point on his left or right for `bait_rest` s (a `fake` share of those just out
	# of reach), within `range` either side of him. Each may stop at the spear point and get away
	# `passes` times (it reddens each time); one more and they multiply over the screen: lost.
	# `dot`: only a red dot on its back counts
	{"id": "e36", "boxes": ["e36"], "kind": "roach", "spear": "spear36", "task": 1,
		"foe": "beetle36", "count": 3, "passes": 3, "dart": 1100.0, "rest": [0.15, 0.5], "bait_every": 2,
		"bait_rest": [0.35, 0.75], "fake": 0.3, "range": 480.0, "dot": false,
		"intro": "Spell 36: the Apshai beetles, quicker than the eye. The vignette opens out. You cannot step: ← → turn you, and Space thrusts. Spear all three with the point. Each may stop by your spear and get away only three times; it reddens each time.",
		"hint": "Watch where they stop. When one pauses at the point of your spear, turn to it and thrust. The redder a beetle, the fewer chances are left.",
		"won": "The beetles are pinned.",
		"label": "The Apshai beetle", "note": "Spell 36. Pinned with the point of the spear."},
	# the two Merti snakes: the drawn one on his left and a mirrored copy on his right, both facing him.
	# Every `idle` s one of the two snake signs in the caption (`signs`: a point on each, strip px; left
	# sign, left snake) flashes red for `warn` s; that snake turns its back on him for `window` s, then
	# whips round and bites. Each must be struck `need` times while its back is turned. `warn` and
	# `window` go from the first value to the second over the strikes.
	{"id": "e37", "boxes": ["e37"], "kind": "twin", "spear": "spear37", "task": 1,
		"foe": "snake37", "need": 2, "idle": [0.8, 1.8], "warn": [1.0, 0.5], "window": [1.1, 0.6],
		"signs": [[2830, 61], [2865, 60]],
		"intro": "Spell 37: the two Merti snakes, one on either side of you, coiled and facing you. The vignette opens out. ← → turn you; Space thrusts. When one of the two snake signs above flashes red, that snake turns its back on you: turn to it and strike before it turns round to bite. Never strike a snake that faces you.",
		"hint": "Watch the two snake signs in the caption: the left one is the snake on your left, the right one the snake on your right. Turn to the one that flashes and thrust while its back is turned.",
		"won": "The two Merti snakes fall.",
		"label": "The two Merti snakes", "note": "Spell 37. Each struck twice while its back was turned."},
	{"id": "e38", "boxes": ["e38"], "kind": "take", "item": "breath38", "task": 2, "gate": true,
		"intro": "Spell 38, for living on air. He holds out the ankh and the sail, the signs of life and breath.",
		"hint": "Click the ankh and sail he holds out.",
		"won": "You take the breath of life. The sail sign returns in later scenes.",
		"label": "The breath of life", "note": "Spell 38, for living on air. The ankh and sail taken from his hand."},
	{"id": "e39", "boxes": ["e39"], "kind": "apep", "spear": "spear39", "task": 3,
		"foe": "apep", "raise": 1.0,
		"intro": "Spell 39: Apep, the great serpent, stretches across the ground. One coil at a time rises. Strike the coil that rises, and only that one.",
		"hint": "Wait for a coil to lift, then click it. Striking a coil that lies flat lets a wounded coil heal.",
		"won": "Apep is pinned to the ground.",
		"label": "Apep", "note": "Spell 39, repelling Apep. Each coil struck as it rose."},
	{"id": "e40", "boxes": ["e40"], "kind": "donkey", "spear": "spear40", "task": 4,
		"foe": "snake40", "donkey": "donkey40", "need": 3,
		"intro": "Spell 40: the Eater of the Ass, a snake on the donkey's back. Strike the snake three times. Do not strike the donkey.",
		"hint": "The snake slides along the donkey's back. Click the snake itself; a miss hits the donkey.",
		"won": "The snake falls from the donkey's back.",
		"label": "The Eater of the Ass", "note": "Spell 40. Struck three times; the donkey spared."},
	{"id": "e41", "boxes": ["e41"], "kind": "pop", "spear": "spear41", "task": 5,
		"foe": "heads41", "bundle": "bundle41", "need": 3,
		"intro": "Spell 41: heads rise from the bundle of reeds and sink again. Strike them while they are up.",
		"hint": "Click the heads while they show above the reeds.",
		"won": "Nothing rises from the reeds any more.",
		"label": "The heads in the reeds", "note": "Spell 41. Struck three times as they rose."},
	{"id": "e42", "boxes": ["e42"], "kind": "end",
		"intro": "Spell 42 is a list, not a picture: each part of the body is given to a god."},
]

