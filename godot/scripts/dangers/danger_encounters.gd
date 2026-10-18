## Encounter tuning and source-art geometry, in scroll order. Distances use 200-dpi plate pixels.
extends RefCounted

## Encounters in play order. `boxes` are vignette frames from level.json; `spear` is the
## vignette's spear-bearer, who stands in for the player during the fight. `caption` is the frame of
## the spell's caption in the top register (strip px, x from and to), with translations in registry.json,
## from C. H. S. Davis, The Egyptian Book of the Dead (1894), which translates this papyrus.
## `tag`: whose name stands over what is said during the fight (the danger's, not the scribe's).
const ENCOUNTERS := [
	# crocodiles: `count` is how many must be turned back in all (the four drawn ones, then copies
	# of them); `speed` in plate px per second; `at_once` how many crawl at the same time; `red` the
	# chance that a crocodile comes red (only a thrust made while holding Shift turns those back; heka on
	# an ordinary one loses the fight); `both_sides` they come from left and right, and he turns
	{"id": "e31", "tag": "Crocodiles", "boxes": ["e31"], "kind": "crocs", "spear": "spear31", "task": 0, "tutorial": true,
		"foes": ["c31a", "c31b", "c31c", "c31d"], "first_speed": 120.0, "break": 6.0,
		# `waves` instead of one count: the lesson, a break while the heka word starts to flash, then
		# a wave with red ones (`red_order`: which launches come red, in order); each crocodile of a
		# wave `ramp` faster than the one before. A lost fight starts again from the first wave.
		"waves": [
			{"count": 3, "speed": 180.0, "ramp": 0.01, "interval": 3.0, "at_once": 1},
			{"count": 6, "speed": 200.0, "ramp": 0.01, "interval": 2.2, "at_once": 2, "red_order": [false, true, false, true, true, false]},
		],
		"caption": [5189, 6667]},
	{"id": "e32", "tag": "Crocodiles", "boxes": ["e32"], "kind": "crocs", "spear": "spear32", "task": 0,
		"foes": ["c32a", "c32b", "c32c", "c32d"], "both_sides": true,
		# harder than 31 and losable, but always possible: each crocodile is `ramp` faster than the
		# one before (210 -> about 420), and none reaches him within `min_gap` s of the one before
		"waves": [{"count": 14, "speed": 180.0, "ramp": 0.01, "interval": 0.8, "at_once": 2, "red": 0.35, "min_gap": 0.9}],
		"caption": [3944, 5168]},
	# the lunging snake: it waits `rest` back from where it is drawn (out of reach) for `idle` s,
	# waves its tail (`wave` s, `tail` rad, `wave_hz`), squashes down (`crouch` s) and springs
	# (`snap` s) to his front leg. `head_tip`, `head_rect`, `tail_base`: in its picture's pixels.
	{"id": "e33", "tag": "Snake", "boxes": ["e33"], "kind": "lunge", "spear": "spear33", "task": 1,
		# `marks`: the red mark's radius (plate px) for each strike in turn, smaller each time
		"foe": "snake33", "need": 3, "marks": [11.0, 8.0, 5.0], "rest": 33.0, "idle": [1.2, 2.4], "wave": 1.4, "tail": 0.26, "wave_hz": 2.2,
		"crouch": 0.35, "snap": 0.16, "head_tip": [122, 218], "head_rect": [68, 205, 58, 25], "tail_base": [28, 172],
		"caption": [3664, 3923]},
	# the snake on the ground, its back to him: red light, green light. It lies near the far (left)
	# edge of the opened vignette; he creeps up on it, forward only, at `creep` plate px/s. Every `away`
	# s it lifts its head (`tell` s, shorter with each strike; after the first strike a `fake` share of
	# lifts settle again), turns to look at him for `watch` s, and turns away again. Moving or thrusting
	# while it looks: it strikes. Struck, it slides `flee` plate px on toward the edge.
	# `head_rect`, `head_pivot` (it turns round on this spot), `eye` (the spear point must come down
	# here): in its picture's pixels.
	{"id": "e35", "tag": "Snake", "boxes": ["e35"], "kind": "creep", "spear": "spear35", "task": 1,
		"foe": "snake35", "need": 3, "flee": 70.0, "creep": 90.0, "away": [1.2, 2.6], "tell": [0.6, 0.35],
		"watch": [1.0, 2.0], "fake": 0.3, "head_rect": [104, 42, 38, 23], "head_pivot": [123, 55], "eye": [114, 52],
		"caption": [3298, 3643]},
	# the roach: `count` beetles (the drawn one and copies), each to be pinned once by the spear
	# point. Each darts at `dart` (plate px/s), rests `rest` s, and every `bait_every` darts stops
	# by the spear point on his left or right for `bait_rest` s (a `fake` share of those just out
	# of reach), within `range` either side of him. Each may stop at the spear point and get away
	# `passes` times (it reddens each time); one more and they multiply over the screen: lost.
	# `dot`: only a red dot on its back counts
	{"id": "e36", "tag": "Beetles", "boxes": ["e36"], "kind": "roach", "spear": "spear36", "task": 1,
		"foe": "beetle36", "count": 5, "passes": 3, "dart": 1100.0, "rest": [0.15, 0.5], "bait_every": 2,
		"bait_rest": [0.35, 0.75], "fake": 0.3, "range": 480.0, "dot": false,
		"caption": [3054, 3277]},
	# the two Merti snakes: the drawn one on his left and a mirrored copy on his right, both facing him,
	# coiled `rest` plate px out from where they are drawn. Every `idle` s one of the two snake signs
	# in the caption (`signs`, cut as sprites; left sign, left snake) flashes red for `warn` s; that
	# snake squashes down (`crouch` s) and springs (`snap` s) to `bite` plate px past where it is
	# drawn, at his foot. A thrust facing it strikes it as it passes where it is drawn (within `reach`
	# plate px). Each must be struck `need` times. `warn`, `crouch`, `snap` and `reach` go from the
	# first value to the second over the strikes.
	{"id": "e37", "tag": "Snakes", "boxes": ["e37"], "kind": "twin", "spear": "spear37", "task": 1,
		"foe": "snake37", "need": 2, "rest": 90.0, "bite": 30.0, "idle": [0.8, 1.6], "warn": [0.9, 0.45],
		"crouch": [0.35, 0.22], "snap": [0.24, 0.17], "reach": [12.0, 7.0],
		"signs": ["glyph37_left", "glyph37_right"],
		"caption": [2803, 3033]},
	# spell 38: he holds out two signs, the sail (breath) and the ankh (life); only one can be taken
	# (`items`, the right one first). What taking the ankh leads to is still to be decided: for now
	# either opens the way on.
	{"id": "e38", "boxes": ["e38"], "kind": "take", "items": ["sail38", "ankh38"], "task": 2, "gate": true,
		"caption": [2316, 2782]},
	# Apep: his tail lashes (`lash` s) and a wave runs the length of him to the fold where the spear
	# point rests, at `speed` plate px/s (first to second value as the barb goes in); a new one every
	# `gap` s, none reaching the point within `min_gap` s of the one before. Each wave pressed down
	# as its crest reaches the point (`reach` plate px either side, first to second value as the barb
	# goes in) drives the barb a step in; `need`
	# steps and he lies as drawn. After the first `teach` waves, a `feint` share are smaller and die
	# out in the drawn hump (`hump`). Crest `height` and `width` (half) in plate px. `head_rect`,
	# `head_pivot` (it turns on its neck here), `fold`: in his picture's pixels.
	{"id": "e39", "tag": "Apep", "boxes": ["e39"], "kind": "apep", "spear": "spear39", "task": 3,
		"foe": "apep", "need": 6, "speed": [220.0, 380.0], "gap": [2.2, 0.9], "min_gap": 0.8, "lash": 0.35,
		"reach": [10.0, 5.0], "height": 12.0, "width": 30.0, "teach": 2, "feint": 0.35, "hump": [190, 320],
		"head_rect": [398, 23, 44, 18], "head_pivot": [440, 33], "fold": 492,
		"caption": [1458, 2295]},
	# the Eater of the Ass (spell 40): the vignette opens out close up; the bearer stands where he is
	# drawn, his spear point resting just up its line from where the snake's front lies on the
	# donkey's back. Its head is down in the donkey: a thrust then goes into the donkey, and he
	# crumbles at once. The donkey swishes its tail now and then (`swish_gap` s apart); the snake
	# lifts its front off the back to snap at it (`lift` plate px up the spear's line), up for `up` s:
	# a thrust then meets its head. After the first strike a `flick` share of swishes are small, and
	# it does not look up. Left alone it bites the donkey every `bite_every` s (its coils tighten for
	# `warn` s first; it always looks up at least once before each bite, so each bite can be stopped); three bites (the flesh signs count the donkey's) and the donkey is eaten. A
	# strike sets the bite back. `need` strikes and it falls; each tuple goes from the first strike
	# to the last. `lift_from`, `lift_to`: where the lift begins and is whole, in its picture's px.
	{"id": "e40", "tag": "Eater of the Ass", "boxes": ["e40"], "kind": "donkey", "spear": "spear40", "task": 4,
		"foe": "snake40", "donkey": "donkey40", "tail": "tail40", "need": 3,
		"swish_gap": [1.0, 2.6], "flick": 0.45, "up": [0.6, 0.38], "bite_every": [4.5, 3.6], "warn": 0.45,
		"lift": 9.0, "lift_from": 70.0, "lift_to": 96.0, "tail_root": [1230, 529],
		"caption": [581, 1437]},
	# the snake in the sheaf (spell 41): the vignette opens out close up; the sheaf's four bands are
	# undone (faint) and its stalks splay; the snake is hidden inside, and the stalks stir at its
	# height. Space (or a click on the sheaf) ties the lowest band still loose, taking `tie` s; if the
	# snake is at that band while it is tied, it bites through the stalks and the band springs loose.
	# Tied, it can never come below that band again. It stays `dwell` s at a height (it lingers at the
	# lowest it may), then moves one up or down in `move` s; after the first band, a `feint` share of
	# moves up turn back halfway. Each tuple goes from the first band to the last. Height 4 is its
	# head out at the top. Four bands and it is forced out on top, as drawn, its head at the spear
	# point; it coils `coil` s (shorter after each bite) and strikes at his hand: thrust before then.
	# Three bites (CROC_HEALTH) and he crumbles. Tuned so that a stand-in player tying 0.35 s after the
	# stir settles wins almost always, one at 0.55 s about half the time, and tying blindly never
	# (SHEAF_CURVE=1 with --autotest prints the curve).
	{"id": "e41", "tag": "Snake", "boxes": ["e41"], "kind": "sheaf", "spear": "spear41", "task": 5,
		"foe": "snake41", "bundle": "bundle41", "need": 1,
		"dwell": [[0.9, 1.6], [0.65, 1.2]], "move": [0.3, 0.18], "tie": 0.28, "feint": 0.35, "linger": 0.6,
		"coil": [1.1, 0.7], "splay": 0.32, "top": 63.0,
		"caption": [50, 560]},
	{"id": "e42", "boxes": ["e42"], "kind": "end"},
]

