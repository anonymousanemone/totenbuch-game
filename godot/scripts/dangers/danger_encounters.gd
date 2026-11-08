## Encounter data, in scroll order. Each entry: fixed keys first (art and wiring), then the tunable
## numbers. Distances in 200-dpi plate px unless marked; times in s.
extends RefCounted

## Fixed keys: `boxes` vignette frames (level.json); `spear` the bearer the player plays; `tag` the
## speaker's name in the fight; `caption` the spell's caption in the top register (strip px, x from
## and to; translations in registry.json, from Davis 1894); `task` the HUD task it belongs to.
## Tunable: a pair [a, b] goes from the first strike to the last unless noted; `hard` overrides
## keys in hard mode (spells 39-41 without the breath sign).
const ENCOUNTERS := [
	# spell 31: crocodiles crawl in; red ones turn back only with Shift + thrust
	{"id": "e31", "tag": "Crocodiles", "boxes": ["e31"], "kind": "crocs", "spear": "spear31", "task": 0, "tutorial": true,
		"foes": ["c31a", "c31b", "c31c", "c31d"],
		"caption": [5189, 6667],
		"first_speed": 140.0,   # the lesson's one slow crocodile (px/s)
		"break": 6.0,           # pause between waves while the heka word flashes
		# per wave: `count` crocodiles, `speed` px/s, each `ramp` faster than the last, launched every
		# `interval` s, `at_once` on screen; `red_order` which launches come red
		"waves": [
			{"count": 3, "speed": 190.0, "ramp": 0.01, "interval": 3.0, "at_once": 1},
			{"count": 6, "speed": 210.0, "ramp": 0.01, "interval": 2.2, "at_once": 2, "red_order": [false, true, false, true, true, false]},
		]},
	# spell 32: crocodiles from both sides
	{"id": "e32", "tag": "Crocodiles", "boxes": ["e32"], "kind": "crocs", "spear": "spear32", "task": 0,
		"foes": ["c32a", "c32b", "c32c", "c32d"], "both_sides": true,
		"caption": [3944, 5168],
		# as in 31; `red` the chance one comes red; `min_gap` least s between two reaching him
		"waves": [{"count": 12, "speed": 175.0, "ramp": 0.01, "interval": 0.8, "at_once": 2, "red": 0.35, "min_gap": 0.9}]},
	# spell 33: the snake waves its tail, then lunges at his leg; strike the red mark
	{"id": "e33", "tag": "Snake", "boxes": ["e33"], "kind": "lunge", "spear": "spear33", "task": 1,
		"foe": "snake33",
		"head_tip": [122, 218], "head_rect": [68, 205, 58, 25], "tail_base": [28, 172],   # picture px
		"caption": [3664, 3923],
		"need": 3,                    # strikes to win
		"marks": [14.0, 11.0, 8.0],   # red mark radius per strike (= hit size)
		"rest": 33.0,                 # waits this far back from where it is drawn
		"idle": [1.2, 2.4],           # wait before each attack (random range)
		"wave": 1.4,                  # tail-wave warning
		"tail": 0.26,                 # tail swing (rad)
		"wave_hz": 2.2,               # tail-wave speed
		"crouch": 0.35,               # squash before the spring
		"snap": 0.16},                # the spring to his leg
	# spell 35: snakes creep in and rest; one shakes its tail, then darts at him
	{"id": "e35", "tag": "Snakes", "boxes": ["e35"], "kind": "creep", "spear": "spear35", "task": 1,
		"foe": "snake35",
		"caption": [3298, 3643],
		"need": 10,                # snakes to spear
		"at_once": 4,              # most resting at once
		"slither": 150.0,          # creeping speed (px/s)
		"enter_gap": [1.5, 3.0],   # between arrivals (random range)
		"rest": [170.0, 250.0],    # resting distance from him (random range)
		"first": 1.5,              # first attack after the vignette opens
		"next": [0.0, 1.5],        # between attacks (random range)
		"shake": 0.8,              # tail-shake warning
		"tail": 0.15,              # tail swing (rad)
		"wave_hz": 4.0,            # tail-shake speed
		"speed": 240.0},           # dart speed (px/s)
	# spell 36: beetles dart about; pin each when it stops at the spear point
	{"id": "e36", "tag": "Beetles", "boxes": ["e36"], "kind": "roach", "spear": "spear36", "task": 1,
		"foe": "beetle36",
		"caption": [3054, 3277],
		"count": 5,                  # beetles to pin
		"passes": 3,                 # escapes allowed per beetle; one more and they swarm (lost)
		"dart": 1100.0,              # dart speed (px/s)
		"rest": [0.15, 0.5],         # pause between darts (random range)
		"bait_every": 2,             # every nth dart stops at the spear point
		"bait_rest": [0.35, 0.75],   # how long it stops there (random range)
		"fake": 0.3,                 # share of those stops just out of reach
		"range": 480.0},             # how far either side of him they roam
	# spell 37: two snakes, left and right; the flashing caption sign shows which springs next
	{"id": "e37", "tag": "Snakes", "boxes": ["e37"], "kind": "twin", "spear": "spear37", "task": 1,
		"foe": "snake37", "signs": ["glyph37_left", "glyph37_right"],
		"caption": [2803, 3033],
		"need": 2,                  # strikes per snake
		"rest": 90.0,               # coiled this far out from where drawn
		"bite": 30.0,               # springs this far past where drawn
		"idle": [0.84, 1.68],       # between attacks (random range)
		"warn": [0.945, 0.4725],    # sign flash before the spring
		"crouch": [0.3675, 0.231],  # squash before the spring
		"snap": [0.252, 0.1785],    # the spring
		"reach": [12.0, 7.0]},      # hit distance from where it is drawn
	# spell 38: take the sail (breath: easier later fights) or the ankh (life: endless fights)
	{"id": "e38", "boxes": ["e38"], "kind": "take", "items": ["sail38", "ankh38"], "task": 2, "gate": true,
		"caption": [2316, 2782]},
	# spell 39: waves run along Apep; press medium ones at the red mark, let small ones pass, hop
	# back from large ones
	{"id": "e39", "tag": "Apep", "boxes": ["e39"], "kind": "apep", "spear": "spear39", "task": 3,
		"foe": "apep",
		"fold": 492,             # where his body folds back (picture px)
		"caption": [1458, 2295],
		"need": 3,               # waves to press
		"speed": [220.0, 380.0], # wave speed (px/s)
		"gap": [2.2, 0.9],       # between waves
		"most": 2,               # most waves on him at once
		"min_gap": 0.8,          # least time between two waves reaching the point
		"switch_gap": 1.0,       # ... when they need different answers
		"lash": 0.35,            # tail-lash warning (a large wave's longer)
		"height": 12.0,          # medium wave height
		"width": 30.0,           # medium wave half-width
		"teach": 2,              # first waves are all medium
		"small": 0.25,           # share of small waves (feints) after that
		"large": 0.38,           # share of large waves (hop back)
		"dodge": 40.0,           # hop-back distance
		"advance": 16.0,         # hard: a medium let past moves him this far closer
		"room": 4,               # advances the close-up leaves room for
		"hard": {"speed": [300.0, 520.0], "gap": [1.2, 0.55], "most": 3, "min_gap": 0.5, "switch_gap": 0.55}},
	# spell 40: the snake crawls along the donkey's back; follow it and strike when it lifts its head
	{"id": "e40", "tag": "Eater of the Ass", "boxes": ["e40"], "kind": "donkey", "spear": "spear40", "task": 4,
		"foe": "snake40", "donkey": "donkey40", "tail": "tail40",
		"back": [-110.0, -34.0],                   # rump to withers (strip px)
		"lift_from": 70.0, "lift_to": 96.0,        # where its lift starts and is whole (= hit area; picture px)
		"tail_root": [1230, 529],                  # the donkey's tail pivot (strip px)
		"caption": [581, 1437],
		"need": 3,                 # strikes to win
		"crawl": [24.0, 36.0],     # crawl speed (px/s)
		"walk": 70.0,              # bearer's step speed (px/s)
		"lift_every": [1.6, 1.1],  # between lifts (about)
		"warn": [0.45, 0.35],      # coils tighten before a lift
		"up": [0.6, 0.4],          # head stays up
		"half": [0.0, 0.3],        # share of half lifts (a strike then hits the donkey)
		"lift": 9.0,               # how high the head lifts
		"hard": {"crawl": [40.0, 60.0], "lift_every": [1.1, 0.75], "warn": [0.25, 0.18], "up": [0.36, 0.26], "half": [0.15, 0.4]}},
	# spell 41: the snake hides in the sheaf; strike the band that shivers
	{"id": "e41", "tag": "Snake", "boxes": ["e41"], "kind": "sheaf", "spear": "spear41", "task": 5,
		"foe": "snake41", "bundle": "bundle41",
		"top": 63.0,               # the sheaf's top (picture px)
		"caption": [50, 560],
		"need": 5,                 # strikes to win
		"window": [1.2, 1.2],      # time on a band
		"gap": [0.4, 0.9],         # unseen between bands (random range)
		"hard": {"window": [0.85, 0.6], "gap": [0.25, 0.5]}},
]
