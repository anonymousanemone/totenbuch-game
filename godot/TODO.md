# TODO

## Playtest notes — 2026-10-15

Universal and procession items done on 2026-10-15 (dangers still being tested). Items marked
**Your call** need a decision before they can be done.

### Everywhere (all levels)

- [x] **Hover glow colour:** pale cream by default (`UI.HOVER`); each level sets its own (`GLOW` in `procession.gd` and `dangers.gd`); the dangers keep the warm red (`UI.HOVER_WARM`).
- [x] **Success flash:** much softer and shorter (`UI.FLASH`, 0.6 s).
- [x] **Camera refocus (procession):** stepping up to the table, the standards or the water, taking up the rope, and stepping away now ease in and out over `REFOCUS` (0.8 s). The dangers' fight camera is not done yet.
- [x] **Walking to a figure (procession):** you stop `STAND_GAP` (6 plate px) clear of the figure, on the side you came from. The dangers are not done yet.
- [x] **Carried objects have no text:** the carried-item box shows only the picture; the stand pieces say nothing when picked up; "Set them up before Ra" is gone.
- [x] **Drag and drop:** a dragged offering or standard is never in the carried-item box.
- [x] **Camera zoom-out framing (try it out):** `FRAME_FROM_TOP` in `procession.gd` (on): zoomed out, the top guideline stays under the title bar and more text below shows. At the usual zoom nothing changes. Set it to `false` for the old centring. **Your call:** keep it?
- [x] **The text below the frame (procession):** the 2026-10-15 re-cut reads it from the .mdp's `text_below` layers. The dangers' text below is not re-cut yet.
- [x] **Part-vs-whole highlighting:** a figure inside another is picked first and glows alone; anywhere else on the whole, the whole glows. A part can also be one figure of a sprite that holds several (`UI.part_glow`). First use: the censer priest and the bier, both parts of the sledge's drawing.

### Procession (spells 1–15)

**Intro**
- [x] Bigger text: the intro and outro cards use the dialogue size (32 px), up to `OVERLAY_W` (900 px) wide. This also applies to the dangers.

**Captions**
- [ ] **Your call:** split spell 1's caption where "to be said…" begins. I can place "Netherworld" (the eye and god-flag group around x 11950) and what looks like the name "Osiris Iufankh" just left of it (x ~11550–12000), but I can't find the *djed* sign for "to be said" reliably. Tell me the x where it starts (or the sign to look for), and I'll split the caption and its highlight there.

**Figures and descriptions**
- [x] **The bier:** one item, "The funerary bier", covering the whole boat (plates II–I), glowing as its own part of the sledge drawing. Its note is "A processional boat with the funerary bier."; clicked before the hauling it adds "The bier is stalled. Ask the ox-driver how to haul it." **Your call:** fill in the rest of the description (the "etc.").
- [x] **The incense man:** "Priest with censer" is on his own, with his own glow, and is recorded in the Journal when clicked. Note: "A priest walks before the bier with a censer, offering incense." **Your call:** check the wording.
- [x] **The two monuments:** taken to be the two obelisks in plate V (the tomb chapel and the stela were already clickable). One item, "Two obelisks": "Two obelisks stand on their bases." **Your call:** confirm these are the ones meant, and the wording.
- [x] **The man across the offering table:** "Man with a water jar", "A man holds a water jar over the offering table for purification.", his box trimmed to x 4835–5005 so the bouquets beside him aren't part of him.

**Hauling**
- [ ] **Art:** an animation sheet for the whip bearer (the gap where the elbow splits). Needs drawing.
- [ ] **Art (the .mdp):** the `haul/driver` layer also holds a copy of his forearm and whip (x 10989–11088), while `haul/whip+arm` is still the swinging sprite. A still copy probably stays in his hand as the whip swings. Clean one of the two layers.

**Standards**
- [x] With the standard-bearers, only the standard under the pointer highlights.
- [x] A click there never walks you off (arrows and Esc still leave).
- [x] Each standard sits on the stub of whatever pole it's on: its seat (the bottom of its middle part) matches the seat of that pole's own standard. Wepwawet's streamer hangs 6 px below its base, which made it float.
- [x] When all eight are in order, a soft wash of colour comes and goes over the scene: `STANDARDS_DONE_FLASH` in `procession.gd`.
- [x] Once complete, they lock.
- [x] Drag and drop (or click to take up, click to set down, like the table): set a standard on any pole and it swaps with the one there; let go anywhere else and it goes back where it came from.

**The double-plumed priest (the recital)**
- [x] Clicking him: you stand in front of him (he faces left), facing him.
- [x] The standards appear one at a time in the space in front of his plumes, above his sheet, each replacing the one before (`RECITE_STEP` 1.1 s apart).

**Offering table**
- [x] Clicking the goose-bearer says "Odd that he's holding a loaf of bread." The scene starts only from the lector or the heap (or a fallen piece).
- [x] At the table, the table itself no longer highlights.
- [x] Once complete, hovering it highlights the whole table, offerings included.

**The stand before Ra (the finale)**
- [ ] **Your call:** carry the three pieces like the adze and the words (follow the pointer, click to set down): one at a time, or 1–3 following the pointer for this last go-round?
- [x] Until the stela shows the imprint, the pieces can't be taken; clicking one says "This might come in handy later, but you wouldn't want your hands full right now." The old early-stand soft lock ("Some things have not been set right yet") couldn't happen any more and is gone.
- [x] When the procession is in order: "The procession is in order. Head over to Ra on his throne."

**Water pouring**
- [ ] **Art:** a sprite animation sheet for the arm (broken lines at the elbow). Needs drawing.
- [x] **New game:** his arm droops by itself, at a rate drawn at random (`DROOP` 0.06–0.4 rad/s), changing every `DROOP_EVERY` (0.6–1.6 s, also random). It really is random: a fresh seed each time you step up. Hold Space to lift (`LIFT` 0.6 rad/s). The line fills while the stream is lined up and slowly dries back when it isn't (never below `KEEP` of the furthest reached). The water particles are unchanged. **Your call:** tune once you've played it.

**Still open from before**
- [ ] **Your call:** the goose falls at an odd angle (it's dropped last and wedges in). Drop it near level and first? That changes the whole scatter's layout.

### Dangers (spells 31–42)

**Everywhere in the dangers**
- [ ] Bigger text on the intro card.
- [ ] Bring back the sassy text. It's boring now; bring back the crocodiles' responses too.
- [ ] Remove the "Press [space] to attack" start entirely: no mandatory Space before a fight starts. Spell 31 asking for one thrust before the crocodiles come was good, so keep that. Spell 32 starts 1–2 s after clicking in.

**Heka signs (spells 31–32)**
- [ ] On the scroll they flash too quickly and too brightly while you walk. Make the red flash subtler and slower, with a darker red closer to the ink colour but still clearly visible.
- [ ] No glow on them. Use the part-vs-whole highlighting instead (see Everywhere).

**Crocodiles (spells 31–32)**
- [ ] Before the second wave of spell 31, no plain "hold Shift" instruction. Go back to the subtle hint that something flashes red.
- [ ] Remove the red dots that count the crocodiles left, in both fights.
- [ ] Flesh signs: slightly bigger and placed closer together. Crop `flesh.png` to remove its extra transparent border.
- [ ] Losing after too many bites: bring back the old text (about the biting and crumbling to dust).
- [ ] Spell 32 crocodiles still feel too frequent and fast. The tuning (`waves` in `danger_encounters.gd`) and the spawning code haven't changed since the hand-tuning (commit `d59d0fd`, 2026-10-13). What did change: the HUD bars around the fight shrank (top 40 → 62 px, bottom 228 → 130 px), so the camera is about 17% closer. Crocodiles now move about 17% faster on screen and cover about 15% less ground before reaching you. Re-tune, or fit the fight's camera as it was.

**Snakes and the beetle**
- [ ] Spell 35, red light green light: too easy. Maybe one life only, or no hints (undecided).
- [ ] Spell 36, the beetles: also feel too easy (undecided).
- [ ] Spell 37, the Merti snakes: revert the descriptions. They must not give away that the flashing snake sign shows which snake strikes.
- [ ] Spell 39, Rekrek (Apep): far too easy. Make it faster, or change the game.

**Spell 38, the breath of life**
- [ ] Life and breath become two separate signs, and only breath is taken: the player must click the breath sign (one choice only). Taking the wrong one makes the following fights nearly impossibly hard. Clicking spell 38's caption title shows "breath" in bold (or similar), which tells the player which to pick.

**Bugs**
- [ ] **Crash in spell 40:** pointing at the donkey's snake during the fight crashes with "Invalid access to property or key 'foe' on a base object of type 'Dictionary'". Cause: `_targets()` in `dangers.gd` returns `[fight.foe]`, but a fight keeps its creature under `fight.e.foe`; the hover check calls it on every mouse move. One-line fix.

### Future scenes

- [ ] **The seven cows (spell 148):** think of a game for the cows, and make it.

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
approximately #a3331f; danger ink, flesh signs, and targets #b55b3c. Hover is warm orange.
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
| Boat | The bier is stalled. Ask the ox-driver how to haul it. |
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

## P3 — Dead code and maintenance

- [x] Remove obsolete `_parked` sprite dictionary/layer and unused pick/take/reset branches now that upper offerings are physics bodies.
- [x] Update offering-table comments describing fixed parked sprites and the frond returning above instead of falling.
- [x] Update hauling documentation that says the original hauler appears only after success.
- [x] Review hidden-avatar positioning/leaning during hauling; preserve required camera/exit positioning and remove redundant work.
- [x] Remove ignored HUD configuration fields and obsolete task-panel data where appropriate.
- [x] Remove or give purpose to HUD `_done` and `update_tasks`, which store data without displaying it.
- [x] Decide whether the disabled minimap is planned functionality or obsolete code, including its signals and level connections.
- [x] Resolve the commented-out spell-38 gate override and align progression, copy, and regression expectations.
- [x] Share repeated glow, completion-flash, and palette behavior where it prevents divergence.
- [x] Review `_hurt` tween callbacks for freed-node access during cleanup reported by the danger test.
- [x] Reset `_table_told` on restart so first-time table instructions can be shown again.
- [x] Update stale README descriptions, especially spell 41's old reeds mechanic.
- [x] Update the project description's outdated spell ranges.

## Validation after implementation

- [x] Review all five intros/outros, Journal pages, and menus at 1280 × 720 and smaller window sizes.
- [x] Check the longest messages with and without a carried item.
- [x] Check each minigame before starting, during feedback, after failure, and after reopening.
- [x] Verify Journal/overlays pause gameplay and cannot accidentally move or exit the avatar.
- [x] Check color meaning and readability in grayscale.
- [x] Test hints with encounters played out of order and while carrying an object.
- [x] Verify exits match their displayed instructions.
- [x] Run regression suites after resolving the gate override and cleanup errors.
- [x] Check off each implementation item only after its relevant verification passes.

## Intro slides: the Old Fax font (original audit, completed)

Checked at 1280×720 on all five intros (procession, cosmos, field, hall, dangers). The outro uses
the same builder (`hud.gd` `_build_overlay`), so every fix here applies to it too.

**Why it looks cramped:** Old Fax is set with ascent 768 + descent 192 in a 1024 em and a line gap
of 92 that Godot ignores. At 16 px the lines are only 15 px apart, less than the font size, so
descenders nearly touch the ascenders of the next line. At 32 px (the scribe strip) it is the same.

- [x] **Line spacing.** Set `line_separation` on RichTextLabel and `line_spacing` on Label in
  `UI.theme()`: about +6 px at 16 px (a 21 px pitch, ~1.3×) and about +10 px at 32 px. Doing it in
  the theme fixes the intros, outros, journal and scribe strip together.
- [x] **The button.** "Begin" (32 px) has no padding, so its letters touch the box. Give the
  Button styles content margins of about 16 px left/right and 6–8 px top/bottom (normal, hover
  and pressed alike). Also check the menu's buttons, which use the same theme.
- [x] **Panel breathing room.** The panel padding of 28/22 → about 36/30. Raise the spacing after
  the title from 14 to about 18 and before the button to about 24 (a spacer, or a separate
  separation). In the hall intro the title "Spell 125: The Hall of the Two Truths" nearly touches
  the right border.
- [x] **Paragraph gaps.** Once lines are spaced, a full blank line between paragraphs (`\n\n`) is
  ~42 px, too much. Use single `\n` with RichTextLabel `paragraph_separation` (~10 px) instead.
- [x] **Line length.** The body is 640 px wide, about 80 characters a line at 16 px. Narrow it to
  ~580 px (~70 characters).
- [x] **Bold and italics do nothing.** Old Fax has no bold or italic face, so `[b]right to left[/b]`
  (dangers, procession) and `[i]…[/i]` show as plain text. In `_keys()`, map `[b]` to the tag red
  (`UI.TAG`) and `[i]` to ochre, or drop the markup.
- [x] **Remove "Every figure is cut directly from Lepsius's 1842 plates; nothing is redrawn."**
  from the intros in `procession.gd` and `dangers.gd`. `godot/README.md` already says "Every figure
  is cut from the plate scans"; add "nothing is redrawn" there, once.

Seen in passing (not the intro, same cause):
- [x] **Scribe strip overflow.** At 32 px, a three-line scribe line (dangers' spell 31 intro,
  the hall's opening) passes `_fit_say()`'s height test but its last line runs into the bottom
  edge of the window. Once lines are spaced, three lines at 32 px won't fit; check the
  threshold. Implemented fixed-size pagination instead of dropping to 16 px.


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
