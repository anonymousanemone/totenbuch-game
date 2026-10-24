# TODO

## Open — to resolve

### Shared

#### General

- [ ] green flashes of success!!! in both the text and the "game" parts!!!

### Procession

#### General

- [ ] **Put minigame instructions near the action:** the playtest suggests players expect instructions at the bottom and rarely look up. Review their placement and give instructions a slightly different appearance when entering a minigame; the visual treatment is still undecided.
- [ ] procession has no changing text depending on walking location.
- [ ] **Support players who are unsure what to do:** the playtest observation was “when confused, look around.” Review whether nearby figures, descriptions and NPC clues give enough direction. Keep these in-game clues separate from Hint-button hints.
- [ ] **Review all Procession minigame instructions:** check that each instruction matches its current objective and controls, and that entry makes the instructions easy to notice. Coordinate this with the placement and appearance review above.

#### Hauling

- [x] hauling game: lead shakes (like the calf). 
- [x] pull when my whip falls - the count down are small falls, then the first real one is the regular sized 
- [x] processional boat description - remove the talk to ox driver part.
- [x] allow clicking on the empty rope to start game

#### Opening of the Mouth

- [ ] success message for words in place is bad. also, should read what it says (like scenery) once the words are in place. 

#### Offering stand

- [ ] procession is in order - chnage to "Off to the left, something glows." (because the procession is not in order, you still have to assemble the offering stand)

### Dangers
- [ ] the all snakes come and eat you looks too triangular. have it look like the player is covered in snakes, criss crossed across the body, and not in a triangular cone on the outside of the body, it should look like a large mass.
- [ ] can the speared snake animation be really fast?
- [ ] 

#### General

- [ ] in dangers, press enter to start - maybe put a frame? some papyrus scrap shape? with hints in a damaged area
- [ ] the striker in dangers after completing a levels says - "you have turned away the crocodiles" or whatever
- know to look around environment for clues
- when clicking heka in game, should be given time to read it
- [x] move the flesh and ankh signs down a little and to the left a little.

#### Crocodiles — spells 31–32

- crocodile not just snout to hit
- when you click the header snakes while playing the game, it should say "the snake that strikes flashes red." it should give look at the two s
- [ ] dont say "they come again" for the second wave, let the player read the flashign red sign and have the player have that instruction stay there (unless explicitly something is preocessed to include new motion)

#### Snakes — spell 35

- [ ] Spell 35, change the red light green light snake to be like the crocodile game, where snakes will come towards you from both sides to attack, and the player can flip left, right, or move up and down. there are no red snakes. when the screen expands, the one snake that was on screen should move somewhere a distance away from the player (like crocodiles, but only 1). then, snakes slither on screen and stop at a location. one will attack, its tail shaking a little (remove the head shaking animation for this entirely). then, it will move to you at a quick speed (faster than crocodiles, but not too much, because the player should be forced to have to watch for the snake tail signal in order to get there in time). never have more than 5 snakes on screen at once. a snake may shake their tail 0-1.5 seconds after the last snake has been speared (i will want to tune this timing). the losing animation will be snakes appear everywhere, and then move towards the player (sometimes diagonally, but no more than 15 degrees angle) and "bite" (make contact with) every part of the player. the player disintegrates. ask if anything is unclear, and reuse as much code as possible. remember karpathy

#### Beetles — spell 36

- roach - know that they will crawl to hitting position (left or right) 3 times, and get redder, if they don't get hit by 3 times they've cralwed by, you lose

#### Two snakes — spell 37

- [ ] **Your call:** spell 37's new Merti wording (nothing may give away that the flashing sign shows which snake strikes): intro "Turn to the snake that strikes ([←] [→]), and thrust as it springs."; hint "Watch the signs above. Striking too soon provokes a snake."; bitten from behind "It sprang from your other side. Turn to face it ([←] [→]). Bitten."
- two snakes - look around for clues
- prevent crocs from slipping past, sometimes you have to block them with your body and make a sacrifice.

#### Life and breath — spell 38

- [ ] Spell 38: life and breath become two separate signs, and only breath is taken: the player must click the breath sign (one choice only). Taking the wrong one makes the following fights nearly impossibly hard. Clicking spell 38's caption title shows "breath" in bold (or similar), which tells the player which to pick. **Art ready (2026-10-16):** in the .mdp the ankh and the sail are separate layers now: `breath38/ankh` is the ankh (life) alone, `breath38/t3` the sail (breath). Still to decide: how "nearly impossibly hard" works after taking the wrong one. *Built (2026-10-16):* they are two sprites (`ankh38`, `sail38`), each clicked on its own; only one can be taken, the other stays in his hand. For now either one opens the way on.
- [x] if breath is taken, the games are 'easy'. if ankh is taken, the games are hard but they never die, but the game never ends. the three flesh signs are replaced by a single ankh sign. every time they lose the ankh sign flashes red.  (they have infinite life, but the snakes aren't repelled, so they keep coming). after a certain amount of time playing with one game, or after a certain amoutn of time for all games combined (whatever is sooner), automatically give the clue "you are living but never free. perhaps that wasn't what you needed." however, if that setting is chosen, do silently save a score board in the journal - each spell has its own entry for dangers, each would say (xxx repelled or speared xxx times or something). if they take neither, it is very hard (same as the ankh sign difficulty), but they only get the three flesh signs, like usual.
- [ ] the block is in front of the life and breath thing (the man in front of you irght fullly blocks himself from the menacing creatures. you may not pass until these have been vanquished.)

#### Apep — spell 39

- [ ] Spell 39, Rekrek (Apep): concept is apophis, who tries to eat the deceased body. can only have one snake. 

#### Sheaf — spell 41

- spell 41: instead of binding the sheaf, i want the player to have to strike at the band that is wiggling. if they get the wrong band, they get bit. ("your spear slips past/stops just before the snake and you are bit.") you have to strike the snake 5 times. the last time will always be at the top band. the rest can be random. in hard mode, you get bit if you don't strike when a band moves. in the regular/easy mode, the player will not be penalized for not taking action. the figure will lean accordingly and press up and down (to move up and down the sheafs). 

#### Gates — spells 145–146

- [ ] **Spell 145, name-and-god matching game:** the player carries a name over their head and must match it to the right god. They walk to the correct god and drag the name onto it; the god lights up and a version of the adorer appears. A different name then appears over the player's head, until every name and god is matched. Reuse `moveable_object.gd` (press-drag-release; check the name-over-head carry against the movable-objects rules in AGENTS.md before building).
  - The pylon's plumes answer each match: call `PylonPlumes.react(pylon, accepted)` (`scripts/gates/plumes.gd`); they rise and fan for a right name, sag and lean apart for a wrong one.
- [ ] **Spell 146, same game, now lethal:** the gods are dangerous spirits, so a wrong match kills the player and they start over. The names always come in the same order, so a restart is learnable rather than random.
- [ ] **Spell 145 wrong-match response:** a soft, visible refusal.
  - A wrong drop is rejected. The god refuses it: it flinches, its blade lowers, or it goes dark. The name snaps back over the player's head, and the player loses a moment but no progress.
  - The game says why. A short line explains the refusal, so the player learns that a mismatch is something to avoid.
  - A repeated mistake gets help. After a couple of misses, the correct god gets a faint hint (it could glow a little, or the narration points toward it). This teaches without making the player stuck.
  - 146 uses the same refusal, made deadly. The god rejects the name the same way, but now it strikes. Because the player has seen the refusal in 145, they'll read the death in 146 as the same mistake with higher stakes.

### Cosmos

#### General

- [ ] Redo the descriptions for cosmos by matching scholarly sources and actual knowledge of the bod. 

## Audit status and approval

Expanded UI, copy, hints, color, and code audit: 2026-10-14. Implementation approved by the user and completed. This audit is based on code and text; layout changes were verified by integration tests and rendered screenshots.
The earlier intro audit below records its own visual findings. Check implementation items off
only after the change and its relevant verification are complete.

- [x] Audit the shared HUD, menus, all five levels, encounter text, shaders, and existing TODO.
- [x] Record the expanded audit as a prioritized implementation checklist.
- [x] Review play feedback and identify what is necessary, redundant, or needs refinement.
- [x] Receive the user's final go-ahead before implementing the following changes.

## P1 — Correct instructions and protect reading

- [x] Fix the hauling hint: direct players to the ox-driver, not the absent hauler (`procession.gd`, `hint`).
- [x] Make danger hints use the active fight instead of the first unsolved encounter (`dangers.gd`, `hint`).
- [x] Make procession hints prioritize the active standards, offering, water, or hauling scene.
- [x] Replace concatenated danger intro + hint + controls with a short objective and essential controls (`start_fight`).
- [x] Separate walking descriptions from fight instructions; avoid repeating the full intro on entry and click.
- [x] Keep essential controls available after success/failure feedback replaces the introduction.
- [x] Pause gameplay and avatar keyboard movement while the Journal or a blocking overlay is open.
- [x] Prevent delayed messages from overwriting instructions from a newer interaction; cancel stale callbacks after reset.
- [x] Remove development status from player dialogue, including “once the gods' figures are cut” at the dangers ending.

## P2 — Text sizing and layout

- [x] Establish a consistent dialogue size; shorten or split messages instead of routinely switching from 32 px to 16 px.
- [x] Recheck dialogue fit on window resize and when the carried-item panel changes available width.
- [x] Check overflow at the smallest supported font size and provide a deliberate fallback.
- [x] Base fit calculations on the actual dialogue row height, including padding.
- [x] Address Old Fax line spacing across dialogue, introductions, menus, and Journal entries; see the earlier audit below.
- [x] Increase vertical Button padding and check all normal, hover, and pressed styles.
- [x] Make the Journal responsive: replace its fixed 960 × 380 minimum and seven-column assumption as needed.
- [x] Make intro/outro panels responsive: review the 640 px body minimum, unwrapped titles, and lack of scrolling.
- [x] Check long speaker tags, especially “You, before the last judge,” for collisions.
- [x] Fit the title-page illustration and buttons inside short windows.
- [x] Check the controls page's fixed 280 px label column and the settings sheet's 660 px minimum width.
- [x] Verify that bold/italic emphasis is visible; replace ineffective markup with a deliberate emphasis treatment.
- [x] Check contrast of small ochre/rule-colored text against both papyrus backgrounds.
- [x] Replace opacity-only icon hover feedback if it makes the active button less prominent.
- [x] Provide visible keyboard focus and usable menu/overlay keyboard navigation without taking gameplay arrow controls.

## P2 — Color roles and consistency

Current display reds: speaker tags/headings #963e28; minimap #a3321f; progress/debug red
approximately #a3331f; danger ink, flesh signs, and targets #b55b3c. Hover colors are defined per level in `glow.gdshader`.
Ghosts and sprite modulation are tint multipliers, not directly comparable display colors.

- [x] Define shared semantic colors for UI accent, danger, target, placement preview, success, and hover in `ui.gd`.
- [x] Consolidate the nearly identical minimap and progress reds.
- [x] Separate display colors from ink tint multipliers; preserve `RED_CROC`'s intended final ink color.
- [x] Distinguish player damage from heka; `HURT` currently uses the same tint as magic.
- [x] Add non-color distinctions between health, attack targets, warnings, beetle escape counts, and magic.
- [x] Standardize gold completion flashes across levels, Journal entries, and judges.
- [x] Reconcile duplicated ink and papyrus colors across scene scripts, UI, and shaders.
- [x] Verify flesh-sign screen size and spacing under every arena camera zoom.
- [x] Keep developer hit-region colors separate from the player-facing palette.

## P2 — Hints and copy

- [x] Give carried sun, ba, and grain hints their immediate destination or recovery step.
- [x] Remove unavailable Esc return instructions for the heart and breath of life.
- [x] Name the actual next built scene in outros instead of promising unfinished chapters.

- [x] Mention empty-pole outlines in the short standards introduction.
- [x] Make standards hints progressive: nearby clue, lector's help, then explicit order.
- [x] Split the 358-character offering-table hint into placement, support order, shelf, and lector hints.
- [x] Explain upper-register gravity and that dragging lets pieces cross the platform.
- [x] Describe arrow-key exits consistently for table, standards, and hauling; distinguish danger movement controls.
- [x] Distinguish Esc returning an object from Esc leaving a scene; update the Controls page.
- [x] Update the dangers level introduction for Space-to-start behavior.
- [x] Reconcile donkey instructions: clicking the snake versus pointing and pressing Space.
- [x] Correct “a miss hits the donkey”: empty-space clicks do not necessarily hit it.
- [x] Explain heka's restriction when red crocodiles arrive; Shift on ordinary crocodiles loses the fight.
- [x] Use consistent snake timing vocabulary instead of mixing squash, snap, spring, and lunge unnecessarily.
- [x] Prefer recognizable visual landmarks over “the caption” and plate-number directions.
- [x] Improve “Your hands are full” by naming the object and explaining how to return it.
- [x] Improve “This place is empty” when the player needs to pick up a standard first.
- [x] Shorten standards completion copy instead of listing all eight symbols again.
- [x] Correct Cosmos's intro claim that everything must be repaired before the sun rises.
- [x] Reconcile Hall's right-pan instructions with both pans calling `place_heart`.
- [x] Shorten the procession introduction's list of problems; allow discovery through play.
- [x] Move asset-production details and “nothing is redrawn” out of gameplay introductions.
- [x] Standardize names for bier boat/bier/sledge and band/register/shelf where the distinction is not meaningful.

### Suggested short copy (drafts, not implemented)

| Situation | Draft |
| --- | --- |
| Hauling | Heave when my whip falls. [space] to begin; [esc] or arrows to leave. |
| Standards | Return each standard to its bearer. Click to take or swap. Empty poles show what belongs there. |
| Offerings | Drag offerings into place, lowest first. Use the upper shelf to clear space. Ask the lector what can go next. |
| Crocodiles | Meet the snout with your spear tip. [↑] [↓] to aim; [space] to begin and thrust; [esc] to leave. |

## Play-feedback review — necessity and proposed treatment

Audit completed; recommendations below still await approval. Necessary feedback explains an
otherwise ambiguous result, teaches a rule, supports timing, communicates remaining work, or
marks a meaningful transition. Text that merely narrates an unmistakable animation is optional.
Preserve narrative character interactions: their purpose is not limited to mechanical instruction.

| Feedback currently offered | Necessary? | Recommendation |
| --- | --- | --- |
| Hover glow and hand cursor | Yes: indicates a clickable target | Keep; verify that glowing targets and available actions agree. |
| Held-object sprite and return instruction | Yes: communicates ownership and recovery | Keep; avoid multiple redundant representations or reminders. |
| Empty-pole/placement outlines and water guide | Yes: communicates a destination or target | Keep; verify visibility and color consistency. |
| Hauling whip, beat sound, heave, train movement, slack | Yes: supports rhythm and distinguishes outcomes | Keep the rhythm cues; provide a readable visual cue for muted play. |
| Hauling “Ready...”, “...and...”, “Heave!” | Useful during count-in | Keep the brief count-in; avoid hiding controls or repeating tutorial prose. |
| Hauling first-pull praise and halfway message | Optional | Remove or shorten if progress is clear; do not overwrite a useful error explanation. |
| Hauling early/late/missed-beat explanations | Yes on first occurrence | Retain short, accurate first-occurrence feedback; current once-per-reason limiting is useful. |
| Standards take/place/swap sentences | State feedback useful; full sentences on every click are excessive | Prefer the held piece and changed pole; retain concise feedback for ambiguous swaps or invalid actions. |
| Offering placement flash and falling/toppling animation | Yes: communicates acceptance or rejection | Keep; explain missing support once because falling alone does not reveal the rule. |
| Goose-bearer exchanges and lector demonstrations | Yes: explains changed ownership and teaches support order | Keep concise character dialogue and visual demonstration. |
| Water stream/drops/splashes and jar response | Yes: distinguishes wrong tilt, instability, and progress | Keep; verify that the causes can be distinguished without reading a long hint. |
| Crocodile retreat/fade plus “The crocodile turns away” | Repeated text unnecessary | Keep animation; remove routine success narration after the lesson. |
| Crocodile first-thrust, movement, and first-hit lesson | Yes for learning the rule | Keep once, in short steps; avoid duplicated intro instructions. |
| Crocodile wave-break and heka-onset messages | Yes when rules change | Explain the new rule during the break; routine “They come again” is optional. |
| Snake “Struck!”, beetle “Pinned!”, sheaf final “Struck!” | Generic repeated text unnecessary when the animation is clear | Keep hit animation; retain progress only where otherwise unclear. |
| Remaining hits appended to successful snake/beetle attacks | Useful when remaining work is not visually evident | Choose one progress representation; do not remove the only reliable indication of remaining work. |
| Damage flash, bite animation, flesh-sign loss | Yes: communicates damage | Keep consistent treatment; distinguish it from a successful hit on an enemy. |
| Early/late, wrong side, missed eye, movement while watched | Yes: explains failure cause | Keep concise, accurate causal feedback; first occurrence or explicit Hint for longer advice. |
| Twin-snake “Too early or too late” | Too ambiguous to teach timing | Refine the diagnosis if measurable; otherwise describe the target moment without claiming a cause. |
| Red crocodile unaffected by plain bronze | Currently can look like a missed attack | Add a brief first-occurrence explanation when the hit actually connects without heka. |
| Heka misuse or stolen word | Yes: surprising loss condition | Explain the cause and recovery once; retain loss animation. |
| Apep successful barb advance plus “Pressed down” | Animation/progress necessary; repeated narration optional | Keep visible advance; explain once and reserve text for setback or completion. |
| Apep early thrust or barb working loose | Yes: distinguishes timing failure from lost progress | Keep short cause-specific feedback; limit repeated messages. |
| Sheaf first band tied and first bite explanation | Yes once; already limited by `fight.told` | Preserve this pattern, shorten wording if needed. |
| Sheaf snake emergence | Essential phase change requiring immediate action | Keep; use a short cue readable within the reaction window. |
| Donkey hit penalty and snake speeding up | Useful because rules/progress change | Keep concise warning and progress feedback; distinguish empty-space misses. |
| Crumbling/swarm/arena closure plus failure prose | Loss and recovery necessary; narration often redundant | One short cause and retry instruction, instead of a sequence of explanatory messages. |
| Fight completion and return to exploration | Yes: signals mode change and success | Keep one brief completion message; cancel stale combat feedback. |
| Cosmos cat success/miss narration | Miss cause useful; repeated success prose optional | Keep concise timing correction and final success; rely on recoil for intermediate hits. |
| Field plough/sow/reap/thresh narration | Flavor useful; often repeats the animation | Shorten or make optional; keep stage readiness, waiting, and completed-work feedback. |
| Hall declarations and judges' responses | Narrative content essential to this interaction | Keep declarations; reduce repeated “heart rises” prose and make remaining judges easy to identify. |
| Hall completed-judge response | Useful when recognition is ambiguous | Preserve persistent heard-judge styling; repeated reminder can be shorter. |
| Delayed “procession lurches forward” narration | Optional and can interrupt newer dialogue | Prefer animation; remove or suppress stale delayed narration. |
| Journal-entry gold flash | Optional acknowledgment | Keep only if subtle; do not compete with completion feedback. |

### Feedback implementation checklist

- [x] Preserve essential visual, audio, ownership, health, progress, phase-change, and recovery feedback.
- [x] Remove routine success narration where animation already communicates the result clearly.
- [x] Keep concise first-occurrence rule teaching and failure explanations; put extended advice behind Hint.
- [x] Avoid repeating the same controls in intro, walking description, click reminder, and hit feedback.
- [x] Preserve controls while transient feedback is shown, without adding excessive UI chrome.
- [x] Choose one readable progress indication per minigame where current animations do not show remaining work.
- [x] Add first-occurrence feedback for an actual plain-bronze hit on a red crocodile.
- [x] Refine ambiguous timing diagnoses and verify that feedback accurately identifies the cause.
- [x] Make critical phase-change cues brief enough to read without sacrificing the next action.
- [x] Consolidate failure messaging into cause and retry guidance; prevent stale messages after exit/reset.
- [x] Preserve meaningful character dialogue and Hall declarations while trimming repetitive mechanical narration.
- [x] Test feedback with sound muted and with repeated mistakes to verify clarity without message spam.

## Completion notes

- Dialogue stays at 32 px and pages without dropping words. Essential controls and progress stay
  visible independently of feedback. Journal, intros, and outros pause gameplay and physics.
- Hints follow the active task; controls, names, and short introductions match the interactions.
  Routine hit narration is replaced by visible actions and progress; corrective advice is limited
  to first occurrences and remains available through Hint.
- Shared colors distinguish UI accent, danger ink, damage, placement previews, and success.
  Used health signs are crossed out, magic crocodiles carry a diamond, and beetle escapes have
  marks. Journal flashes were removed after rendered review found them excessive.
- The hidden minimap/task panel and parked-sprite paths were removed. Empty-pole guides are now
  actually rendered. Spell-38 gating is restored; stale timers and encounter animations are
  canceled or guarded on newer interactions, retry, and reset.
- All five level suites, shared script regressions, and UI integration regressions pass:
  **667 checks across 7 suites**. UI checks cover 1280×720, 800×600, and 640×480, including
  actual outros, carried-item layout, both ends of the standards frame, start/exit/retry,
  modal pause, muted feedback, and repeated mistakes.
- Rendered review includes all five intros, actual level outros, narrow Journal/controls,
  multiple danger arenas, and grayscale feedback. Screenshots are temporary review artifacts
  under `/tmp/totenbuch-ui-final`; capture them again using the command in `README.md`.
- The headless renderer still reports its known glow-sampler diagnostic, macOS certificate
  diagnostic, and occasional exit-time object-leak warning; no unexpected errors were reported.

## Completed — 2026-10-18

### Shared hint system — implemented (2026-10-18)

- [x] **Move hint content into JSON:** create a hand-edited `godot/assets/puzzles.json`, split by stable puzzle IDs such as `procession.standards`, `procession.offerings`, `procession.goose`, `procession.water`, `procession.bulls`, `procession.opening_mouth`, `procession.offering_stand`, `procession.haul`, and `dangers.e31` through the actual encounter IDs. Keep this file independent of the art cutters and generated `level.json` files. Each puzzle contains `instructions`, `success`, `feedback`, then `hints`. Instructions and success are plain strings; named feedback entries preserve intermediate responses and alternate messages. Keep puzzle rules and progress in gameplay scripts; JSON holds authored text, not executable conditions.

**Suggested hint levels**

**Terminology:** “clues” are information available within the game world through NPC descriptions, speech, artwork, objects and other observations. “Hints” exclusively means help requested by clicking the **Hint button**. Ordinary controls and minigame instructions remain instructions.

These four levels are Hint-button hints. They can point toward or explain in-game clues, but are separate from those clues and from ordinary instructions and feedback. These are editorial meanings; existing text is reused, and intermediate levels are omitted where no suitable text exists.

| Level | Purpose | Example: turning the calf |
| --- | --- | --- |
| 1 — Find | Point toward an unfinished puzzle and where to find it, without explaining its solution. | “Look for the calf and the two bulls near the sacrifice.” |
| 2 — Notice | Point toward a relevant detail or someone worth consulting, without stating the answer. | “Look at what the calf is facing.” |
| 3 — Interpret | Explain the relationship or principle the player needs to understand. | “The calf shies at the sacrifice. It should face the living ox.” |
| 4 — Act | Give the exact next action, including the answer when needed. | “Drag the calf sideways until it turns to face the plumed ox, then release.” |

- [x] Keep Find at the puzzle level. Write each Notice → Interpret → Act ladder about one puzzle phase or remaining problem. Do not use a later slot to introduce an unrelated task. For example, turning the calf and moving the plumes need separate ladders; finding the final stand pieces and assembling them also need separate phases.
- [x] Use Find plus up to three puzzle-specific levels per phase; do not pad simple actions with artificial hints. The last available hint should be actionable. Basic controls and entry instructions should be available immediately as ordinary instructions, without spending a hint level.
- [x] Keep hints short enough for the bottom dialogue strip. Level 1 directs the player to an unfinished puzzle; level 2 encourages examining a clue within it; explicit solutions belong at level 4. Respect the existing spell-37 wording constraint: no hint should disclose which flashing sign predicts which snake.

**Proposed JSON shape**

```json
{
  "puzzles": {
    "procession.bulls": {
      "instructions": "Fix what is wrong!",
      "success": "The plumed ox lowers his head to the calf. All three are as they should be.",
      "feedback": {
        "calf_turned": "The calf turns its back on the block and settles.",
        "plumes_restored": "The disc and plumes sit on the living ox again."
      },
      "hints": {
        "find": {
          "default": "Look for the calf and the two bulls near the sacrifice."
        },
        "phases": {
          "calf": [
            {
              "level": "notice",
              "text": "Look at what the calf is facing."
            },
            {
              "level": "interpret",
              "text": "The calf shies at the sacrifice. It should face the living ox."
            },
            {
              "level": "act",
              "text": "Drag the calf sideways until it turns to face the plumed ox, then release."
            }
          ]
        }
      }
    }
  }
}
```

- [x] **Shared selection and progression:** the level supplies the current puzzle and phase IDs to a shared hint reader. It selects the next authored entry and sends it through the existing HUD as speaker “Hint”. Puzzle/phase IDs must not depend on visible names or scene node paths.
- [x] While exploring, the Hint button gives level 1 (Find): point toward a nearby unfinished puzzle, otherwise the next unfinished puzzle in level order. A relevant carried item can determine which unfinished puzzle to point toward. When the player is in a puzzle, the button gives that phase's Notice → Interpret → Act hints instead. Find is an explicit hint level, stored once per puzzle, but repeating it while walking does not consume that puzzle's phase hints. Never point toward completed puzzles or give advice for completed phases; when none remain, give a brief completion/navigation message.
- [x] Advance puzzle-specific hint levels only when the player explicitly presses Hint while in that puzzle. Entering a minigame, receiving ordinary instructions, or seeing gameplay feedback must not consume a Hint-button hint. Remember the next hint separately for each puzzle and phase during the current attempt; leaving and returning preserves it. A newly reached phase starts at its first hint. Repeat the last hint after the ladder is exhausted. Restarting the level clears hint progression. No automatic hints or cross-session persistence in the initial implementation.
- [x] Cosmos currently has no puzzles: retain its general exploration help, without creating artificial puzzle ladders.

**Before the JSON migration (2026-10-18)**

Before migration, the HUD shared a Hint button and signal, but each level implemented its own selection logic without shared hint JSON or standardized difficulty levels.

| Current context | Current hints | Difference from the proposal |
| --- | --- | --- |
| Procession: standards | Two successive lines: consult the plumed lector, then the full eight-standard order. | Roughly Notice → Act; no intermediate interpretation. |
| Procession: offering table | Three lines: build lowest first; use the upper shelf; ask the lector to show a placeable offering. | A sequence of different practical tips, rather than three levels about the same obstacle. |
| Procession: bulls | Three lines: inspect facing/headgear; turn the calf; move the plumes. | First line is broad, but the next two address separate unsolved tasks. |
| Procession: water | Three lines: Space lifts the arm; keep the stream on its guide; compensate for changing droop. | Starts with controls and continues with technique; not an increasing reveal of one answer. |
| Procession: final stand | Three lines: inspect the stela; locations of the three pieces; assembly order. | Mixes finding and assembly phases in one ladder. |
| Procession: hauling and active opening-mouth game | One fixed action hint each. | No escalation. The mouth hint still says “finish all three” despite only eye and mouth being carved. |
| Procession: carrying the adze or words, goose task, and exploration | Fixed next-action or navigation messages; exploration follows the first unfinished task in a hard-coded order. | No separate per-phase ladders; navigation is mixed into the same handler. |
| Dangers | One `hint` string per encounter in `danger_encounters.gd`; active fight takes priority, then the local unfinished encounter, then the next unfinished task. Crocodile help can append a heka reminder. | State-aware selection, but repeated requests generally repeat the same advice. |
| Cosmos | One fixed walking/inspection message. | General help only; appropriate until puzzles exist. |

Before migration, Procession's `_hint_step` remembered independent indices for standards, table, bulls, water and stand. Repeated requests stopped advancing the displayed text at the last entry; level restart cleared the indices. Other hints had no ladder counter.

- [x] **Migration and acceptance:** move existing text into the puzzle/phase structure, then edit it into the proposed levels; review it against actual gameplay rather than assuming the existing line order is a difficulty order. Correct stale mouth instructions to eye and mouth; do not implement the separately proposed mouth-game rule changes as part of the hint migration. Check Find selection among unfinished puzzles, the switch from Find to puzzle-specific hints on entry, separation from ordinary minigame instructions, phase changes, completed-phase exclusion, independent progression, final-hint repetition and restart reset. Verify JSON IDs and ordered levels, and check readability at the supported window sizes. Implemented in `assets/puzzles.json` and `scripts/puzzles.gd`, with level scripts selecting context. Existing text was restructured; edits were limited to stale counts, state accuracy and navigation direction.

### Background and sprite descriptions — implemented (2026-10-18)

- [x] **One shared description system, with content per level:** use hand-edited `assets/<level>/registry.json` files, following the Procession registry proposal below. Each describable figure, object or background feature has a stable ID, a display name, descriptive text and optional speech and journal settings. Keep descriptions independent of generated art metadata and `puzzles.json`; art exports must never overwrite authored writing.
- [x] **Sprites:** attach the registry ID to the saved scene object. Keep its texture, placement and hit area in the scene. Parts can share a description ID when they represent one subject; give a part its own ID only when it has something distinct to describe. A group described together can remain one subject.
- [x] **Background:** retain the continuous illustration, guidelines and text as background art. Add named, editable inspection regions in the scene only for features worth describing, such as a stela inscription, a landscape or a scene's setting. Link those regions to the same registry as sprites; a region does not require a separate image. Ordinary empty papyrus remains click-to-walk, with no generic description on every click.

**Content and terminology**

- [x] Descriptions state what the player sees; NPC speech states what the character says. Either can provide an in-game **clue**. Write observations that help the player infer a solution, such as “The young calf shakes at the sight of the sacrifice,” rather than automatically issuing the Hint-button answer “Turn the calf around.” Keep basic controls and minigame instructions separate. **Hints** remain exclusively the help requested through the Hint button.
- [x] Store text in each entry's `descriptions` dictionary, with `default` and named states such as `unsettled` and `settled` as sibling keys. Gameplay scripts select the appropriate variant from actual state, falling back to `default`; JSON contains text, not condition expressions. Repeat inspection shows the appropriate description again; it does not advance a hint ladder or progressively reveal answers.
- [x] Keep text brief enough for the bottom dialogue strip. Use a consistent descriptive voice; label speech with the NPC's name and observations with the subject's name. Preserve uncertainty in identifications instead of presenting guesses as established facts.

**Proposed JSON shape**

```json
{
  "entries": {
    "calf": {
      "name": "Calf",
      "descriptions": {
        "default": "A young calf stands near the bulls.",
        "unsettled": "The young calf shakes at the sight of the sacrifice.",
        "settled": "The calf faces the living ox."
      },
      "journal": true
    },
    "stela": {
      "name": "Stela",
      "descriptions": {
        "default": "A round-topped stela beneath the winged sun."
      },
      "journal": true
    }
  }
}
```

An entry may also supply `speech` and `speaker` when an NPC has a spoken line. The stela can be linked to a sprite or a background inspection region without changing its text entry. The examples illustrate the registry format; existing text is reused in the implemented entries.

**Interaction and journal behavior**

- [x] Use a shared inspection handler to resolve the selected object's ID, obtain the current text variant and display it through the existing HUD. Scene scripts retain puzzle actions and decide whether a click inspects, speaks, picks up an item or enters a minigame. Preserve explicit interaction exceptions; do not make an extra inspection click mandatory before every puzzle action.
- [x] Pick active minigame controls and foreground objects before background regions. Resolve overlapping subjects consistently with drawing order and distinct parts. Use suitable hit shapes or alpha checks so transparent sprite margins do not block subjects behind them. Highlight the actual selected subject; do not highlight an entire background when only one feature is selected.
- [x] In ordinary exploration, clicking a physical describable subject walks to it using the shared approach rule, then displays its text. Background caption translations continue to display in place. Clicking empty space walks there. Hover only identifies the subject; it does not show a description or reveal a clue automatically.
- [x] Journal entries use stable IDs, not display names, to avoid duplicates and allow identically named figures. Record only text the player has actually seen. Re-inspecting a changed subject updates that entry to its latest observed description; unseen variants never appear automatically. Use the sprite's image or a crop of the background region as its journal picture.
- [x] **Migration and acceptance:** move Procession's cutter-authored hotspot descriptions, Dangers' descriptive encounter text and Cosmos' figure descriptions into this format without moving combat tuning or puzzle rules. Connect saved sprites and necessary background regions by ID. Check default and state-specific text, NPC speech, overlapping targets, empty-space walking, journal updates, and that inspection never consumes or advances Hint-button hints. Verify re-exporting art preserves all authored descriptions. Implemented through per-level `registry.json` files, `scripts/descriptions.gd`, saved inspection regions and sprite IDs, with journal entries updated by stable ID. Art exporters now write IDs and geometry instead of authored descriptions.

### Procession

- [x] **Clickable figures as sprites:** use the already separated artwork to give each clickable figure (or group described together) its own sprite in the saved scene, with a stable registry ID and attached hit area. Export these layers individually instead of recombining them into the background strip; ensure the background does not retain duplicate figures. Keep placement and hit areas editable in Godot, with consistent picking for overlapping figures.
- [x] **Centralize figure descriptions and interactions:** add a hand-edited `assets/procession/registry.json` keyed by stable IDs, holding names, descriptions, journal text/settings, and any named text variants. Link scene figures to it by ID rather than display-name comparisons. Use a shared loader and interaction component for description lookup, displaying text through the existing HUD, and journal recording; keep puzzle actions and selection of state-dependent responses in gameplay scripts. Move authored descriptions out of the art cutters and generated `level.json`, so re-exporting art cannot overwrite writing. Keep cutters responsible for images and source-art geometry, preserve existing behavior during migration, and establish a format reusable by other levels without migrating them as part of this task.
- [x] the calf description - "the young calf shakes at the sight of the sacrifice"
- [x] **Opening of the Mouth artwork and adze alignment:** use the manually separated eye and mouth artwork, with no beard carving. Verify the existing handle-to-pointer alignment and small downward strike rotation about the pointer. The blade tip must match the point used to detect a successful strike.
- [x] **Opening of the Mouth without a loss state:** remove the missed-strike limit and failure/reset behavior. Keep Esc available to leave the minigame at any time. Remove the small target bubbles and accept strikes wherever the adze tip falls within the eye or mouth feature bounds, rather than requiring the next point along a stroke.
- [x] **Consistent click-to-walk behavior:** clicking a physical subject should walk to it before interacting, unless that interaction explicitly requires otherwise. Approach the nearest horizontal edge when standing outside its bounds; when already in front of it, walk to the clicked position within those bounds. Review all Procession interactions for consistency with this rule.
- [x] **Offering-table snapping during dragging:** snap a held piece into its correct place as soon as it is close enough and its supporting pieces are in place, even while the mouse button is still held. Currently placement waits for release or another click.
- [x] **Make the lector priest the clear point of contact:** make it apparent that the player should click the priest beside the collapsed offering table. Clicking him should display the table minigame's instructions, including when the player needs to read them again. Instructions now appear on every entry; review how clearly the priest is presented as the point of contact.
- [x] **Show the placement imprint with the priest’s clue:** when the lector priest beside the offering table is clicked, keep showing a piece that can currently be placed and simultaneously fade in a faint imprint of that piece at its correct destination. Fade the imprint out with the existing piece clue, using the same timing.
- [x] **Review offering-table instructions:** make the objective and controls clear when entering the minigame. Review the existing text in `assets/puzzles.json` rather than adding a second source of instructions.
- [x] All levels that are programmed and playable should be marked black in the map and playable (unlocked). and by default, clicking "play" should take you to the first level.
- [x] the censer (in front of the implements stand), should get the description (he hold incense over the small stand, purifying the sacred implements for the opening of the mouth ritual.)
- [x] currently when anubis + mummy is clicked, the water game activates instead. only activate teh water game when clicking on the priest holding the jar. if clicking anubis+mummy, they should get the description (whatever it was before + THe mummy's mouth is not opened yet, and needs the right tool).
- [x] the offering stand (with the implements) should be renamed to low table. and write, "a small stand with two rods, a hooked adze, and a foreleg laid on it."
- [x] standards are drag and drop only, however it moves off of the mouse and becomes smaller. it should remain the same size and not look like it's jupming away from the mouse.
- [x] for the cows minigame - the three separate sprites should be clickable in that game, and reveal their 'unresolved' descriptions that gives hints - the slaughtered bull should be: the apis bull should never be slaughtered. (Not even Cambyses did it, despite what Herodotus claimed.). the calf: whatever it is right now, something about trembling at the sight of th eslaughter. the other bull (the actual apis bull). A bull.


## Centralized movable objects class — implemented

- [x] Add `godot/scripts/moveable_object.gd`, with `class_name MoveableObject` extending `Node2D`. Give each movable item an instance that controls its existing sprite, carrying state, and position.

Scope: standardize movable-object interaction using the rules below. This class handles movement and attachment; puzzle scripts decide whether pickup or placement is allowed. Calf turning, water-jar tipping, and adze carving remain separate mechanics with their current controls. Implemented in `scripts/moveable_object.gd` and the Procession/Dangers controllers. `tests/moveable_object_regressions.gd` covers shared movement and puzzle-specific recovery; existing suites also exercise the migrated interactions.

### Required interaction behavior

- [x] Preserve each movable object's authored world-scale magnitude across world, avatar attachment, dragging, accepted placement, cancellation, and reset. Rotation and facing/mirroring may change, but object size must not change due to carry poses, destination transforms, or scaled parents. Camera zoom changes screen size normally. Remove the lotus's current carry-only `0.7` scale; it must retain its world size on the avatar and while dragged/placed. Check composed global transforms, not just the sprite's local scale.
- [x] Approved scale exceptions: change the adze's carving scale from `0.35` to `0.5` (50%) in `TOOL_USE`, restoring its normal size on exit, and preserve the words' appearance/rise/unroll scale animation. Update the carving grip/tip calculations consistently with the new adze scale. Words retain their normal size during subsequent transport. The lector's scaled hint preview is a separate display copy, not the movable object; leave that preview unchanged.
- [x] Only objects marked `carriable` can be collected from the world by clicking and attached to the avatar. Puzzle eligibility checks still apply. Non-carriable puzzle pieces can be dragged directly without attaching to the avatar.
- [x] Clicking an attached object shows its description and leaves it attached. Pressing and moving beyond the drag threshold starts dragging it off the avatar; a simple click never leaves it following the pointer.
- [x] Show the object's description when its drag begins and keep it visible during the drag. Resolve the description from current game state, allowing explicit puzzle feedback or a state-dependent description to replace/modify it. Generic hover text must not overwrite it during dragging.
- [x] Every attached object can be dragged off the avatar, including items with no usable destination. Only a valid destination accepts it; otherwise it returns to its attachment on the avatar, following the avatar's current position and facing. An item with no destination always returns.
- [x] All movable objects use press-drag-release, with no click-to-pick-up-and-follow or click-again-to-place mode. Clicking a carriable world object to collect it onto the avatar is distinct from pointer dragging. The words are the sole movable-object exception: preserve their current click-to-follow and click-to-place behavior.
- [x] Invalid drops return objects to a valid location. For an avatar-origin drag this is the avatar; for other objects the puzzle resolves the valid return location. Preserve the original valid location until a placement is accepted; reset-to-source and cancel-drag are distinct operations.
- [x] Preserve the offering table's existing placement validation, support dependencies, automatic snap while dragging, shelf parking, and loose-piece gravity. Remove click-and-follow input. Apply the revised bounds, goose-bearer drops, and recovery rules below. Automatic snapping before mouse release is an explicitly retained table behavior.
- [x] Expand the offering floor/drop region's right boundary to the goose-bearer's rightmost bound. Update the floor, right wall, drop clamping, and relevant zone checks together so rejected offerings can fall in front of him.
- [x] Add a physical blocker covering the lector priest so loose offerings cannot fall onto or cover him. He currently has an inspection `Area2D`, not a physical barrier; `_build_floor()` currently creates only the floor, side walls, and upper shelf. Ensure release/spawn positions do not start inside the new blocker, including fallback drops.
- [x] Rejecting an item dropped on the goose-bearer releases it onto the floor in front of him with gravity; it must not remain attached to the pointer. Preserve his acceptance of the goose and return of his own loaf when his arms are empty.
- [x] the falcons in the standrards are not interchangeable.
- [x] Giving the goose to the bearer while  he holds the loaf replaces the loaf with the goose and drops the displaced loaf onto the floor in front of him with gravity. Do not put the displaced loaf in the player's hand or leave it following the pointer.
- [x] Esc or leaving the table mid-drag returns an item directly taken from the bearer to him. Once an item has been released into the table's physics region, it belongs to the table for recovery purposes, even if it originally came from the bearer (including the long loaf). A subsequent cancelled drag returns it to the table using the table fallback calculation, not to the bearer. Shelf-origin cancellation retains the shelf recovery rule. Track the origin of the current drag rather than the item's historical source.
- [x] Preserve adze carving controls: pointer-following tool positioning and click-to-strike are tool use, separate from object transport. They do not become drag-to-strike.
- [x] Words and the carving adze remain `MoveableObject` instances with explicit behavior overrides. Words use `CLICK_FOLLOW`: clicking their valid destination places them; clicking anything invalid returns them to where they appeared above the mummy, ending pointer-following. Configure their `from_loc` at that appearance location. Enter carving only by dragging the carried adze onto the mummy and releasing it. Clicking the mummy or empty tool stand only describes it. The adze switches to `TOOL_USE` during carving and back to `TRANSPORT` on exit; `OpeningMouth` owns pointer positioning and strikes during tool use, and the ordinary transport handler is suspended.
- [x] `CLICK_FOLLOW` is an extremely rare exception, currently approved only for the magical words. Before proposing any other use, check drag/drop and other alternatives; do not introduce another use without explicit user approval.
- [x] Include the plumes as a non-carriable movable object, preserving their press-drag-release behavior, grab offset, and destination/snap calculation. A valid release attaches them to the walking ox and immediately locks them against further pickup/dragging, even before the calf is turned or the whole bull puzzle is complete. An invalid release or leaving before placement returns them to their original position on the slaughtered bull. `Bulls` retains puzzle completion rules. Water jars and the calf are excluded from this class because their restricted gestures transform them in place.
- [x] Lock the goose against further pickup/dragging as soon as the goose-bearer accepts it, matching offerings locked into their assembled places. Apply the same placement lock to the plumes on the walking ox. The lock prevents movement, not description clicks; puzzle reset clears the lock and restores the starting state.
- [x] Distinguish clicks on the goose-bearer from clicks on the goose once he holds it. Clicking the bearer uses existing `procession.goose.feedback.success_carrying` in `godot/assets/procession/puzzles.json`: "He carries his goose with joy and purpose." Clicking his goose says exactly "He clings to his goose, refusing to give it up again." Add that goose-specific text to the JSON during implementation. Give the goose's visible pixels priority over the bearer's larger hit region; neither click permits taking or dragging the accepted goose.

Verified offering-table behavior: `_fall()` clamps the release x to `[floor_x.x + min(half_width, 60), floor_x.y - min(half_width, 60)]`, and sets y to `min(release_y, ground - 20)` before spawning a gravity-driven rigid body. Thus the release y is preserved only when above that ground limit. Near a supported target, the piece snaps into its authored position; near an unsupported target, it spawns at the target center with sideways/upward velocity and rotation, then topples. Shelf parking clamps both x and y to the shelf region using the piece's half dimensions. Esc currently restores bearer/shelf items specially, while ordinary loose pieces fall from the table's horizontal midpoint at `ground - 200`. Keep these calculations with the expanded bounds and revised bearer/recovery rules above, avoiding the lector blocker when spawning fallback items.

### Attributes

| Attribute | Type | Purpose |
|---|---|---|
| `id` | `String` | Existing item ID, such as `sun` or `ankh38`. |
| `sprite` | `Sprite2D` | Existing drawing controlled by this object. |
| `base_world_scale` | `Vector2` | Authored world-scale magnitude captured during setup and preserved across ordinary movement states, compensating for parent scale. Facing reflection is handled separately. Only approved tool/appearance effects may override this temporarily. |
| `state` | `State` enum | `WORLD`, `WORN`, `HELD`, or `PLACED`. |
| `carriable` | `bool` | Whether a world click may collect this object onto the avatar; does not restrict dragging an attached object. |
| `description_id` | `String` | Key used by the description system; puzzle state may select alternate text. |
| `transport_mode` | `TransportMode` enum | `DRAG_DROP` by default; `CLICK_FOLLOW` only for the approved magical-words exception. |
| `interaction_mode` | `InteractionMode` enum | `TRANSPORT` by default; the adze uses `TOOL_USE` during carving while remaining a movable object. |
| `locked_in_place` | `bool` | Prevent pickup/holding after final accepted placement (goose, assembled offerings, plumes). Description clicks remain available; reset clears the lock. |
| `carrier` | `Node2D` | Avatar providing `carrying_transform()`. |
| `carry_pose` | `Transform2D` | Position, rotation, and mirroring relative to the avatar; preserve `base_world_scale` rather than applying carry-only resizing. |
| `held_pose` | `Transform2D` | Drawing offset, rotation, and mirroring relative to the pointer; preserve `base_world_scale` outside approved exceptions. |
| `from_loc_parent` | `Node` | Authored source parent. |
| `from_loc_transform` | `Transform2D` | Source pose relative to `from_loc_parent`. |
| `from_loc_z_index` | `int` | Source drawing order. |
| `to_loc_parent` | `Node` | Destination parent, supplied by the puzzle controller. |
| `to_loc_transform` | `Transform2D` | Destination pose relative to `to_loc_parent`. |
| `to_loc_z_index` | `int` | Destination drawing order. |
| `_return_state` | `State` | State before entering `HELD`. |
| `_return_parent` | `Node` | Parent of the last valid location before dragging. |
| `_return_transform` | `Transform2D` | Parent-relative pose of the last valid location before dragging. |
| `_return_z_index` | `int` | Drawing order to restore when cancelling. |

Use the existing authored sprite rather than creating another copy. Preserve its original parent so objects can ride on moving scenery, such as the sun on the bier.

`from_loc` and `to_loc` are the source and destination field groups above. Store transforms relative to their respective parents so both locations follow moving scenery. `setup()` captures `from_loc`; the puzzle configures `to_loc` before placement. For standards, update `to_loc` when the controller selects a pole. Wearing and pointer holding are intermediate states: they do not overwrite either location. Keep cancellation's temporary return state separate from the authored source, so cancelling a drag from the body returns the item to the body while resetting returns it to `from_loc`.

All location/carry transforms must preserve the captured world-scale magnitude when composed with their parents. Normalize or compensate their scale during application; stored destination poses must not silently resize objects. Verify that replacing offering sprites with held drawings and physics bodies also preserves the same size.

### Functions and parameters

| Function | Parameters | Behavior |
|---|---|---|
| `setup()` | `object_id: String, drawing: Sprite2D` | Store identity and capture `from_loc_parent`, `from_loc_transform`, and `from_loc_z_index` from the drawing. |
| `set_to_loc()` | `parent: Node, pose: Transform2D, z_index: int` | Configure `to_loc_parent`, `to_loc_transform`, and `to_loc_z_index` without moving the object. |
| `contains_point()` | `world_point: Vector2` | Test the transformed sprite, including its visible pixels, for picking. |
| `world_rect()` | None | Return the current bounding rectangle for walking approach, hover, and clues. |
| `wear()` | `avatar: Node2D, pose: Transform2D` | Require `carriable`; enter `WORN` and attach the drawing to the avatar's carrying frame after controller eligibility checks. |
| `hold()` | `pointer_pose: Transform2D` | Refuse when `locked_in_place`. Otherwise save the previous state and enter `HELD`. Preserve a grab offset or set a specific grip. Ignore repeated calls while already held so the return state is preserved. |
| `move_held()` | `world_point: Vector2` | Update the held drawing from the pointer position. |
| `request_description()` | None | Emit `description_requested(id, description_id)`; the controller resolves current game-state text through the existing description/HUD system. |
| `place()` | None | Enter `PLACED`; apply the configured `to_loc` parent, transform, and drawing order. The controller must configure the destination first. |
| `lock_in_place()` | None | Set `locked_in_place` after the controller accepts a final placement; leave description access intact. |
| `cancel_hold()` | None | Restore the previous worn attachment using the avatar's current carrying frame, or the saved parent-relative valid location. Physics-based table recovery remains controller-owned. |
| `reset()` | None | Apply `from_loc_parent`, `from_loc_transform`, and `from_loc_z_index`; restore `WORLD` state and clear `locked_in_place`. |
| `_process()` | `delta: float` | Update worn objects using `carrier.carrying_transform()`. |

Signals: `state_changed(previous: State, current: State)` and `description_requested(object_id: String, description_id: String)`. Puzzle controllers resolve descriptions, refresh hover effects or UI, and retain responsibility for completion and dialogue.

### Call sites and ownership

| Existing caller | New calls and responsibility |
|---|---|
| `EndingStand.setup()` | Create stand, sun, and lotus objects; call `setup()` to capture each `from_loc` and `set_to_loc()` for its assembled position before Ra. Convert `WORN` entries into carry transforms. |
| `EndingStand.pick()` / `worn_at()` | Keep existing bounds picking on objects in the appropriate state; the shared class also provides ink picking. |
| `EndingStand.take()` | Call `wear(avatar, pose)` after pickup is approved. |
| `EndingStand.hold()` | Call `hold(pointer_pose)` only once an avatar-object press crosses the drag threshold. |
| `EndingStand.unhold()` | Call `cancel_hold()`. |
| `EndingStand.set_down()` | Check `RESTS_ON`, then call `place()` for an accepted piece. |
| `procession._click_world()` / `_stand_piece_input()` | On an attached-object press, request its description and record the press. Cross the drag threshold to call `hold()`; release over a valid destination to place, otherwise cancel. A simple click only reads the description. Remove click-again placement and automatic walking to place a dragged stand piece. |
| `procession` mouse-motion handling | Pass the world pointer position to the active object's `move_held()`. |
| `procession` / `dangers` object input and description handlers | Apply the same attached-object click/drag rules to all carried objects; request descriptions on click and drag start, resolve state-specific text, and preserve it during the drag unless explicit game feedback replaces it. |
| `dangers.take()` | Call `wear()` using the existing `CarryAnkh` or `CarryBreath` marker transform. |
| `OpeningMouth.take_adze()` | Call `wear()` with the adze's hand attachment pose. |
| `OpeningMouth.take_words()` | Configure `CLICK_FOLLOW` and the appearance location as `from_loc`; call `hold()` with the words' pointer pose. |
| `OpeningMouth.touch()` | Enter the existing carving tool mode. Pointer tracking and strike animation stay in `OpeningMouth`; transporting the adze remains subject to the shared drag/drop rules. |
| `OpeningMouth.put_back()` | Call `reset()` for the carried object. |
| `OpeningMouth.setup()` | Capture each object's `from_loc`; call `set_to_loc()` for the words' destination over Ra. |
| `OpeningMouth.place_words()` | Call `place()` to apply the words' configured `to_loc`. |
| Words input handling in `procession` / `OpeningMouth` | While words follow the pointer, a valid destination click calls `place_words()`; any invalid click restores their appearance location using `reset()` and restores the spoken/available puzzle phase. |
| `OfferingTable.take()` | Remove or disable the loose physics body, then call `hold()`. |
| `OfferingTable.setup()` | Capture each object's `from_loc`; call `set_to_loc()` for each offering's assembled position. |
| `OfferingTable.drop_at()` | Validate support and snapping, then call `place()` if accepted; otherwise resume existing physics behavior. |
| `OfferingTable._build_floor()` / `_fall()` / `in_zone()` | Use the expanded right boundary and add the lector's physical blocker; keep physics and spawn positions consistent. |
| `OfferingTable.bearer_act()` / `procession._act_bearer()` | Drop rejected items and any loaf displaced by the goose onto the floor in front of the bearer; never leave them following the pointer after release. |
| `OfferingTable.take()` / `put_back()` / `procession.leave_table()` | Track current-drag origin: return directly borrowed items to the bearer on cancellation, table-origin items to the table, and shelf-origin items to the shelf. Releasing a borrowed loaf onto the table changes its subsequent recovery origin to the table. |
| `procession._table_input()` | Start holding on press, keep existing automatic snapping during motion, and resolve unsnapped placement on release. A release without a drag must not leave an item following the pointer. Preserve table fallback calculations and bearer interactions. |
| `procession.act_slot()` | Call `hold()` for a standard. |
| `procession._drop_standard()` | Choose the pole, call `set_to_loc()` with its parent, pose, and drawing order, then `place()`; call `cancel_hold()` for an invalid drop. |
| `Bulls.setup()` / `press()` / `drag()` / `release()` / `leave()` | Configure the plumes' slaughtered-bull `from_loc` and walking-ox `to_loc`. Delegate sprite holding/movement/placement to the movable object while preserving grab offset, `SNAP` validation, and invalid-release/leave return to `from_loc`. Keep calf controls and puzzle completion in `Bulls`. |
| `OfferingTable._place()` / goose acceptance in `bearer_act()` / accepted plumes in `Bulls.release()` | Call `lock_in_place()` immediately on final accepted placement. Exclude locked objects from pickup/drag targeting while retaining description targeting. |
| Each puzzle's `reset()` | Call every owned object's `reset()`, then apply puzzle-specific initial state. |

For offerings, physics remains owned by `OfferingTable`: the movable object controls the drawing while held or placed, and the existing rigid body controls it when loose. Make that handoff explicit so both systems cannot update the sprite simultaneously.

Input stays in the level controller. Objects do not implement `_unhandled_input()`: `procession.gd` decides which minigame owns the mouse, whether the player must approach first, and whether a release counts as a drag.

Keep placement rules, completion, hands-full checks, dialogue, hints, journal updates, hover glow, offering gravity, calf turning, jar tipping, and spear combat outside the class.

### Migration and verification

- [x] Verify constant world-scale magnitude through every ordinary state transition and differently scaled parents, especially lotus world-to-avatar-to-pointer-to-placement. Verify the two approved visual exceptions restore normal scale afterward. Keep hint-preview scaling and camera zoom separate from object scale.
1. [x] Migrate the ending stand first. Verify carriable-only click collection, body poses, mirroring, click-to-describe without detachment, description persistence/state overrides during drag, valid drag placement, invalid-drop return to a moving avatar, cancellation, and reset.
2. [x] Migrate Dangers. Verify both collectible choices retain their marker poses and follow the avatar; clicking reads their descriptions and dragging them anywhere without an accepted destination returns them to the avatar.
3. [x] Migrate the plumes. Verify grab offset, invalid drop/leave return to the slaughtered bull, and valid snap to the walking ox. Verify they cannot be dragged again immediately after acceptance, even while the calf remains unresolved. Verify the accepted goose and assembled offerings also refuse pickup/dragging, descriptions remain readable, and reset restores movability. Keep calf and water-jar gestures outside the movable-object class.
4. [x] Migrate the adze, words, standards, and offerings one interaction at a time, using the existing regression tests. Verify words alone retain click-follow transport, carving stays unchanged, non-carriable pieces never attach through a world click, and standards return on invalid drops. Verify table automatic snapping, support/topple rules, clamped gravity drops, shelf handling, and removal of click-follow controls. Verify expanded bounds, lector exclusion, rejected-item floor drops, and displaced-loaf floor drops. Test cancelling a loaf drag directly from the bearer versus cancelling a new drag after that same loaf was dropped onto the table.

#### Offering table

- [x] offering table game: "he speaks to you (look up)"
- [x] offering table stuff is not in the right place
- [x] when offering table is done, only clicking the offering tbale should say - it is whole again.
- [x] second offering table should be clickable, with its own description.
- [x] the snap while drag boundary needs to be a little smaller, for offering table.
- [x] goose message only appears after you click the goose and drop it. delete that entirely. just say when taking the bread from the goose bearer or clicking on the goose bearer that "get this poor man something to carry"
- [x] when clicking on goose bearer, give the default message, which is him carrying his goose
- [x] and do not prompt can you help again once the game is done.
- [x] in the game, when clicking on goose man, the description should be "odd that he's holding bread" and only gives you the bread if you click on the bread (whole vs part highlight), and doesn't say "he's missing his goose" but says "get this poor man an offering to carry." all other offerings fall through. only the goose stays and clisks (this should already be true)

Completed with the revised wording: the priest says "He tells you the next offering to place."; the empty bearer stares forlornly at his empty hands. The second table says "Another large pile of offerings, with more architectural integrity." Restored offering offsets were reset, preserving the large palm frond and the goose/bread swap.
#### Standards

- [x] standards plumed priest when giving hint. - "he speaks to you" (append this to the description)
- [x] plumed lector priest's default description is never shown, and when clicked on, he gives no corresponding text on the bottom.
