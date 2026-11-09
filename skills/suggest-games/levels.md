# What each level already plays

Detail moved out of `README.md` so `suggest-games` can see which kinds of play each level has.
Read the section for the vignette's level before proposing a game (SKILL.md §1).

**Staleness:** this file is hand-kept and drifts as levels change. Whenever you use it, skim it
against the level's script (`godot/scripts/<level>/`) and `godot/assets/<level>/puzzles.json`;
fix or delete what no longer matches, and note anything newly built. Tuning numbers here are
examples; the constants in code win.

Script and scene paths are under `godot/` (`godot/scripts/procession/haul.gd`, ...); tools and art are at the repo root.

**View mode:** every restored level can be opened with its puzzles switched off and every rite shown
done (`Scroll.viewing`, see `README.md`). A suggested game needs a "restored" state for this, and its
clues and fights switched off while viewing.

---

## The Funeral Procession (spells 1–15, pl. I–VI)

`godot/scripts/procession/`. Whatever can be clicked glows under the pointer (`glow.gdshader`; all
eight standard-bearers glow together). Click figures to record them in the journal; click a movable
piece to pick it up and click where it belongs to set it down (clicking a filled place swaps the
two); click where you took it to put it back. Esc or the arrow keys leave any scene.

1. **Haul the bier** (pl. II, `haul.gd`): click the ox-driver or the empty rope (it shudders now and
   then until taken up), walk to the hauler's place on the rope and fade into his pose. Space starts
   the count-in; the whip only flicks, and its first full fall is the first beat. Pull with Space,
   Shift or click as the whip falls; drum and whip give the beat. Early or late lets the rope slacken
   and the bier slip back; a missed beat stops it. After a miss the next good pull is answered by the
   driver ("That's it. Keep the beat."). Twelve clean pulls bring it home. The camera holds on the
   train and the road ahead of the ox. Tuned in `haul.gd` (`BEAT`, `WINDOW`, `BACK`, `PULLS`, `SLIP`).
2. **Return the standards**: click the eight bearers to stand at their nearer end. Drag a standard
   at its original size onto a bearer (it swaps with the one there); let go elsewhere and it goes
   back. The bearers carry the wrong gods; the two falcons are interchangeable. The two-plumed
   lector (pl. V) shows the order when clicked: the eight signs appear one at a time over his
   sheet, jackal first (`RECITE_*`, `recital` in `level.json`).
3. **Rebuild the offering table** (`offering_table.gd`): the heap in pl. IV has collapsed. Click the
   table, a piece or the lector to step up; the camera holds on the table. Loose pieces are physics
   bodies on the floor, each with a faint papyrus fill inside its outline; the palm frond lies on the
   upper register line. Drag a piece (it comes to the front and follows the pointer), release or
   click again to set it down. Near its place it snaps in, but only once everything it rests on is
   there (`rests_on`); otherwise it topples back. Every loose piece has gravity; a dropped piece
   lands on the upper-register platform, and only a piece being dragged crosses it. The frond goes
   last. The lector repeats the instructions and shows a piece that can go on now, with a fading
   imprint at its destination.
4. **Give the goose back**: the man beside the lector holds a loaf instead of his goose, which lies
   among the fallen offerings. Take the loaf from him, then give him the goose. While his arms are
   empty, the clothes the goose and loaf cover show.
5. **Pour the water** (`pour_water.gd`, pl. V): a priest raises a jar over a kneeling woman; the
   wavy line from it, over Anubis holding the mummy upright, is the stream. At first the jar is
   raised and only a faint dotted ghost of the line shows (`water.gdshader`). Click the priest or
   jar to step up. His tired arm is pulled down at random (`DROOP`, `DROOP_EVERY`); hold Space to
   push it up (`LIFT`). The arm has weight and swings on (`DAMP`). Within `WINDOW` of the drawn tilt
   the water runs and the line draws itself in; too high it only drips, too low it gushes and
   splashes on the woman's hands. Not pouring, the line dries back, never below `KEEP` of its
   furthest. Once whole, the jar settles where it is drawn.
6. **Open the mummy's mouth** (`opening_mouth.gd`, pl. V–VI): the eye and mouth are faint drafts.
   Take the adze from the low table and click the mummy; the player walks into the gap by the
   kneeling woman, faces the mummy, then the camera closes on its face. The handle follows the
   pointer and each click swings the blade slightly about it. Click with the blade tip anywhere in
   either feature's bounds to ink its lines gradually (3 strip px per click), in either order. No
   timer, no loss; misses do nothing. Once both are inked the adze returns to the stand and the
   words rise above the mummy; carry them to their imprint over Ra. `mouth.strokes` describes the
   reveal paths; hit bounds come from the exported feature pixels; `mouth.face_view` in
   `level.json` the close view. The adze rides in the player's hand while walking (mirroring and
   bobbing), goes to the pointer in the face view, and returns after. The words follow the pointer.
6b. **The three bulls** (`bulls.gd`, pl. III–IV): click the calf, the plumed ox or the sacrifice to
    step up beside the plumed ox. One line: "Fix what is wrong!" (Hint gives graded clues). The calf
    faces the sacrifice and shies now and then: drag it sideways, it turns about its middle; past
    halfway it faces the plumed ox, as drawn. The disc and plumes sit on the bull at the block and
    the plumed ox walks bare: drag them onto his head (no outline shows where; elsewhere and they
    go back). With both right, he lowers his head to the calf. Sprites: `plumed_ox`, `plumes`
    (`--bulls` in the cutter, from the `.mdp` folder `bulls`; `plumes_wrong` is the same on the
    sacrifice). `bulls` in `level.json` holds both places; the scene's `plumes_place` marks the right
    one.
7. **Set up the offering stand before Ra** (`ending.gd`, pl. VI): the stand, sun disc and lotus
   before Ra are gone, and so is the kneeling adorer. Once rites 1–6 and the bulls are done, the
   stela beside the tomb shows a faint imprint of the three; until then it is blank and the pieces
   can't be taken (clicking one says it might come in handy later). They hide along the scroll and
   glow under the pointer: the stand inside the canopy frame behind the mourners (pl. I), the sun
   between the legs of the creature on the mummy's bier (pl. II; it rides with the sledge), the lotus
   on the second offering pile (pl. V). Click one to wear it (`WORN` in `ending.gd`). Drag it off (or
   click twice) to carry one at a time; let go on the place before Ra to walk there and set it on;
   elsewhere or Esc and it goes back on you. Each goes on only once what it rests on is there (stand,
   sun, lotus). Hiding places: `ending.hide` in `level.json`.

With all eight done you kneel at the adorer's place (the drawn adorer, cut as `kneeler`, takes your
place), light spreads from Ra's disc and the new sun (`light.gdshader`), and the level returns to the
menu.

---

## Dangers on the Road (spells 31–42, pl. XVI–XIX)

`godot/scripts/dangers/`. You can walk through every vignette. Click a creature (it glows) to walk
into its vignette, become its spear-bearer and start the fight at once; Space thrusts, holding Shift
lends the thrust heka. Walking into a vignette says its danger's line until it is overcome. Walking
from 40 to 41 passes behind the column of signs between them (`Column` in `dangers.tscn`; hidden
while a fight is open). In a fight every spear-bearer rests with the spear drawn back; a thrust runs
it out and back. Once overcome, the vignette is put back as drawn.

Spell 38 is barred until 31–37 are done (invisible barrier; the scribe says so); spell 42 waits until
every danger before it is overcome. At the end the breath sign grows out of his hands, shrinks off
right where six more join it, and the column sweeps right to left over the scene (`_breath_wipe` in
`dangers.gd`).

Every fight opens the same way (`_arena_setup`, `_frame_now`, `_place_frame`): over `CROC_OPEN` the
frame moves from the vignette's drawn double lines to the screen edges, the bottom line stopping above
the speaker's tag. The caption moves to the middle of the band at its walking size. Only the wide
fights (crocodiles 31–32, beetles 36) zoom out to the scroll's full height. The speaker's tag names
the danger (`tag` in `danger_encounters.gd`).

| Spell | Rule |
|---|---|
| 31 | You are the spear-bearer: ↑ ↓ / W S move, Space thrusts; only the spear point strikes a crocodile (or right by its snout) before it reaches you. Never two crocodiles with fronts overlapping or one right after another at the same spot; the last of each wave is a drawn squatting one. Wave 1 is the lesson, then a break: the heka word in the banner flashes red (click for the hold-Shift hint). Wave 2 has red crocodiles (`red_order`), turned back only by a thrust holding Shift. Bites redden the body; heka on an ordinary crocodile, or one slipping past once the word glows, loses: the crocodile laughs, turns round, the word spins into its jaws, he crumbles, and you are back on the scroll. Each crocodile is `ramp` faster. Tuned in `ENCOUNTERS` (`waves`, `break`, `ramp`) |
| 32 | The same, faster, two at a time from both sides: you stand in the middle, ← → turn, ↑ ↓ move. Spacing counts both sides as one. Some come red (`red` chance): hold Shift to turn them back; a plain thrust does nothing to a red one, heka on an ordinary one loses. Bites redden the body, heka the spear |
| 33 | Close up, he stays where drawn, spear raised. The snake coils just out of reach, breathing; its tail waves (the warning; `snake_tail.gdshader`), it squashes and snaps at his front leg. Thrust as it springs, the point on the red mark where it is drawn. The mark shrinks each strike (`marks` 14, 11, 8 plate px; window ~200 → 145 ms). Three strikes (`need`) win; three bites and he crumbles |
| 35 | Like 32, no red ones. The drawn snake moves off to rest `rest` away; more slither in and stop (never more than `at_once`, 5). One at a time, `next` s after the last attack, a resting snake shakes its tail (the only warning) and darts along its row at `speed`. Spear point on it pins it (everything waits while its head flips back and it lies as drawn, then fades). Touching any part of you, it bites and slinks back; missing, it slips past and rests on the far side. 14 speared (`need`) wins; three bites and snakes come in from everywhere and he crumbles. `--croc-bot` with `BOT_REACT` checks it can be won |
| 36 | You stand still: ← → turn, Space thrusts. Five beetles (`count`) dart very fast; every couple of darts each stops by the spear point on your left or right for 0.35–0.75 s (some just out of reach). Only the point at full thrust pins one; a catch holds everything 0.5 s and that beetle is gone. Pin all to win. A beetle that stops within reach and escapes reddens a step each time; after `passes` (3) they multiply to fill the vignette, the bearer crumbles, and you are back on the scroll |
| 37 | Close up; he stands as drawn, ← → turn, Space thrusts. The drawn snake and a mirrored copy wait coiled `rest` (90) plate px out, breathing. One of the two snake signs in the caption flashes red (left sign, left snake); that snake squashes and springs at his foot. Thrust facing it as it passes (`reach` 12 → 7 plate px; window ~110 → 90 ms); a thrust at a coiled snake makes it spring at once. Each struck twice falls; three bites and he crumbles. `warn`, `crouch`, `snap`, `reach` tighten per strike |
| 38 | Take one sign from the giver's hand, the sail (breath) or the ankh (life); one at a time, clicking the other swaps. The sail gives the later fights their easy rules; the ankh gives endless life. Taking neither is allowed once the earlier dangers are overcome |
| 39 | Close up. The barb rests a little way up its line from Apep's neck; Space thrusts. The tail lashes and a wave runs along Apep to the fold (`apep_wave.gdshader`); his head strains up. Thrust as the crest reaches the point: the wave is pressed flat, Apep flushes red, the barb rests a step further in (`need` 6; at the last, as drawn). A wave that passes rears his head round to bite the bearer's foot. After the first two (`teach`), some waves (`feint`) are small and die out; a thrust on a still neck works the barb loose a step. Waves speed up (`speed` 220 → 380), close together (`gap`, `min_gap`), and the crest must be nearer (`reach` 10 → 5). Three bites and he crumbles |
| 40 | Close up. The snake's head is down in the donkey's back; a thrust then goes into the donkey and he crumbles. The donkey swishes its tail (`tail40`) and the snake lifts its front up the spear's line (`lift_end.gdshader`) for `up` s (0.6 → 0.38, ±25%): Space then strikes it. After the first strike some swishes are only flicks (`flick` 45%). Left alone, it bites the donkey every `bite_every` s; the flesh signs count the donkey's health, and the third bite eats it. It always looks up at least once before each bite. Three strikes win. `DONKEY_CURVE=1` with `--autotest` prints win rate by reaction time |
| 41 | ↑ ↓ aim at the shivering band, Space spears the snake. Five hits, the last on top, win in mortal play. Without breath, missing the opening also causes a bite |
| 42 | End of the level. Text only (each body part given to a god); not a puzzle yet |

Spell 38's choice affects only 39–41:

| Choice | Rules | Health and ending |
|---|---|---|
| Breath sail | Easy | Three flesh signs; encounters can be completed |
| Ankh | Hard where implemented | One ankh flashes red on a damaging mistake; no death, snakes return, no level ending |
| Neither | Same hard rules as the ankh | Three flesh signs; normal deaths and victories |

Hard rules: each encounter's `hard` entry in `danger_encounters.gd` overrides its tuning (read
through `tune()`); winnable only with very quick reactions. Without either sign, after the ankh clue's
active-play limits the scribe suggests the breath ("Maybe taking a breath could help you with these
challenges."). Earlier encounters keep their rules whichever sign is carried.

With the ankh, the Journal counts each successful wave pressed back (39) or snake speared (40–41),
per spell; scores survive leaving and re-entering fights. After 60 active seconds in one encounter, or
120 combined, the scribe says: "you are living but never free. perhaps that wasn't what you needed."
Opening/closing animations, walking and the paused Journal don't count. The clue appears once per
run. Restart clears scores, journal, choice and timers (session only, no disk save).

The chosen ankh or breath sail stays on the walking player (`Avatar/CarryAnkh` / `Avatar/CarryBreath`
in `dangers.tscn`; anchors ankh `(-38, -233)`, sail `(-35, -236)` from the feet facing left; image
offsets `(-16, -67)`, `(-30.5, -49)`). It mirrors and bobs with the player, hides during combat, and
returns to the giver on restart. The unchosen sign stays in the giver's hand. Attachment transforms
are shared through `avatar.gd`'s `carrying_transform()`.

Crocodile fights (31–32): three bites and the bearer crumbles and you are back on the scroll (never an
automatic restart). The flesh sign (`godot/assets/dangers/figures/flesh.png`, `FLESH_GAP` apart; red
dots until it is there) counts health in red at the top left. 32 speeds up per crocodile (`ramp`) but
keeps `min_gap` so it can always be won. `-- --croc-bot` fights the next crocodile vignette with a
stand-in player (0.35 s reaction; `BOT_REACT=0.7` slower) and prints the tries needed.

Heka signs: caption hieroglyphs in the `heka` folder of `art/bod31-42.mdp` are cut as their own
sprites; each flashes red on the scroll (and in a crocodile fight once red crocodiles can come), glows
under the pointer in a fight, and when clicked tells the player to hold Shift.

---

## Survival and Sustenance (spells 43–63, pl. XX–XXIII)

`godot/scripts/survival/` (`survival_play.gd` on top of `survival.gd`). Walk right to left by arrows
or by clicking the papyrus. Click a glowing figure to approach it, read its description and record it
in the Journal; captions can be inspected without journal entries. Tall text columns are foreground
nodes, so the avatar passes behind them. The avatar is a copy of the spell-43 worshipper and stands in
for the drawn walking men (43, 44, 46, 48–51), whose drawings are hidden. Dev: `--past-gate` starts
past the gate with two sceptres (`--upside` also upside down), with `--at=`.

- **43:** clicking the three was-sceptres in the god's hand puts them on his back (`MoveableObject`s).
  They are his lives: each failure crumbles one away in red.
- **Splicing:** passing behind a double line (43|44, 49|50, 50|51; `SpliceLines`) he changes look,
  drawn in two halves at the line (`clip_min`/`clip_max` in `figure.gdshader`): worshipper → 44 man,
  then 46 → 50 → 51 man.
- **44–46:** in 44 the door goes black and the 44|45 line bars the way. Clicking the door costs a
  sceptre: he shrinks and fades into it and in the dark becomes the mummy, rocking in Anubis's
  hands wider and wider. Clicking the *tm* sign ("not", `spell45_tm`) fast takes a little off each
  time; still, it rests in Anubis's hands and he comes out as the 46 man, no way back past 45|46.
  Past the fall angle it falls against the 44|45 line and its head comes off: back at the door
  (going in again costs a sceptre), or with none left he dies. Without a sceptre at the door his
  head falls off and he crumbles. Dev: `--mummy` starts straight in the mummy game.
- **Opening out (`widen.gd`):** the minigames of 45, 52, 53 and 57 push everything in view beyond
  the vignette's two double lines outward `WIDEN` px each side (between the top rules and the
  ground rule; the text below stays), and the vignette grows by fresh papyrus. A picture of the
  held view is what slides, as the camera doesn't move in a minigame.
- **Death:** his head falls and he crumbles; the level restarts at 43 with everything reset but the
  Journal. (Respawn at 47 waits for the claim's place sign.)
- **47:** the ba is missing; each pass unclaimed, the scribe asks him to claim his seat.
- **50–52:** through 50|51 he comes out upside down (`avatar.upturn`); press on him and drag up past
  halfway to set him upright. Headlong into 52 he eats filth (*placeholder*: he reddens) and loses a
  sceptre.
- **57:** the water dribbles, no one stands under it, the tray is in the tree. Clicking the water, he
  fades into the 57 man, bent at the waist (`Waist`); let go and he sinks, Space raises him. With his
  hands in the stream the tray comes out; out of it, it draws back (never below 60% of its best).
  [esc] leaves; once out he stands beside the 57 man, who stays.
- **59:** walking in, both water signs flash red, then each of their six lines in turn (`LINE_ORDER`,
  a *placeholder* order), then both again. Clicking the lines in that order makes the water flow and
  he sits beneath it; a wrong line replays the sequence. [esc], Space, ← or → stand him up; the
  seated man stays.

---

## The Gates (spells 144–146, pl. LX–LXVII)

`godot/scripts/gates/`. Shares Survival's navigation, inspection, hover and journal script. The
avatar is a copy of the first pylon's adorer. Every adorer starts hidden; `name_given(pylon,
accepted)` in `gates.gd` (for the spell-145 naming puzzle to call) makes that pylon's plumes answer
and, for a right name, fades its adorer in. `PylonPlumes.react` (`plumes.gd`) makes the plumes stand
and fan for a right answer, or sag and lean apart for a wrong one. `plumes.gdshader` sways everything
above the plumes' foot like reeds. The spell-145 naming puzzle is not built yet.
