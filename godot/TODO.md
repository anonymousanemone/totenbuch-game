# TODO

## Audit status and approval

Expanded UI, copy, hints, color, and code audit: 2026-10-14. Implementation awaits the user's
final go-ahead. This audit is based on code and text; new layout concerns need visual verification.
The earlier intro audit below records its own visual findings. Check implementation items off
only after the change and its relevant verification are complete.

- [x] Audit the shared HUD, menus, all five levels, encounter text, shaders, and existing TODO.
- [x] Record the expanded audit as a prioritized implementation checklist.
- [x] Review play feedback and identify what is necessary, redundant, or needs refinement.
- [ ] Receive the user's final go-ahead before implementing the following changes.

## P1 — Correct instructions and protect reading

- [ ] Fix the hauling hint: direct players to the ox-driver, not the absent hauler (`procession.gd`, `hint`).
- [ ] Make danger hints use the active fight instead of the first unsolved encounter (`dangers.gd`, `hint`).
- [ ] Make procession hints prioritize the active standards, offering, water, or hauling scene.
- [ ] Replace concatenated danger intro + hint + controls with a short objective and essential controls (`start_fight`).
- [ ] Separate walking descriptions from fight instructions; avoid repeating the full intro on entry and click.
- [ ] Keep essential controls available after success/failure feedback replaces the introduction.
- [ ] Pause gameplay and avatar keyboard movement while the Journal or a blocking overlay is open.
- [ ] Prevent delayed messages from overwriting instructions from a newer interaction; cancel stale callbacks after reset.
- [ ] Remove development status from player dialogue, including “once the gods' figures are cut” at the dangers ending.

## P2 — Text sizing and layout

- [ ] Establish a consistent dialogue size; shorten or split messages instead of routinely switching from 32 px to 16 px.
- [ ] Recheck dialogue fit on window resize and when the carried-item panel changes available width.
- [ ] Check overflow at the smallest supported font size and provide a deliberate fallback.
- [ ] Base fit calculations on the actual dialogue row height, including padding.
- [ ] Address Old Fax line spacing across dialogue, introductions, menus, and Journal entries; see the earlier audit below.
- [ ] Increase vertical Button padding and check all normal, hover, and pressed styles.
- [ ] Make the Journal responsive: replace its fixed 960 × 380 minimum and seven-column assumption as needed.
- [ ] Make intro/outro panels responsive: review the 640 px body minimum, unwrapped titles, and lack of scrolling.
- [ ] Check long speaker tags, especially “You, before the last judge,” for collisions.
- [ ] Check the controls page's fixed 280 px label column and the settings sheet's 660 px minimum width.
- [ ] Verify that bold/italic emphasis is visible; replace ineffective markup with a deliberate emphasis treatment.
- [ ] Check contrast of small ochre/rule-colored text against both papyrus backgrounds.
- [ ] Replace opacity-only icon hover feedback if it makes the active button less prominent.
- [ ] Provide visible keyboard focus and usable menu/overlay keyboard navigation without taking gameplay arrow controls.

## P2 — Color roles and consistency

Current display reds: speaker tags/headings #963e28; minimap #a3321f; progress/debug red
approximately #a3331f; danger ink, flesh signs, and targets #b55b3c. Hover is warm orange.
Ghosts and sprite modulation are tint multipliers, not directly comparable display colors.

- [ ] Define shared semantic colors for UI accent, danger, target, placement preview, success, and hover in `ui.gd`.
- [ ] Consolidate the nearly identical minimap and progress reds.
- [ ] Separate display colors from ink tint multipliers; preserve `RED_CROC`'s intended final ink color.
- [ ] Distinguish player damage from heka; `HURT` currently uses the same tint as magic.
- [ ] Add non-color distinctions between health, attack targets, warnings, beetle escape counts, and magic.
- [ ] Standardize gold completion flashes across levels, Journal entries, and judges.
- [ ] Reconcile duplicated ink and papyrus colors across scene scripts, UI, and shaders.
- [ ] Verify flesh-sign screen size and spacing under every arena camera zoom.
- [ ] Keep developer hit-region colors separate from the player-facing palette.

## P2 — Hints and copy

- [ ] Mention empty-pole outlines in the short standards introduction.
- [ ] Make standards hints progressive: nearby clue, lector's help, then explicit order.
- [ ] Split the 358-character offering-table hint into placement, support order, shelf, and lector hints.
- [ ] Explain upper-register gravity and that dragging lets pieces cross the platform.
- [ ] Describe arrow-key exits consistently for table, standards, and hauling; distinguish danger movement controls.
- [ ] Distinguish Esc returning an object from Esc leaving a scene; update the Controls page.
- [ ] Update the dangers level introduction for Space-to-start behavior.
- [ ] Reconcile donkey instructions: clicking the snake versus pointing and pressing Space.
- [ ] Correct “a miss hits the donkey”: empty-space clicks do not necessarily hit it.
- [ ] Explain heka's restriction when red crocodiles arrive; Shift on ordinary crocodiles loses the fight.
- [ ] Use consistent snake timing vocabulary instead of mixing squash, snap, spring, and lunge unnecessarily.
- [ ] Prefer recognizable visual landmarks over “the caption” and plate-number directions.
- [ ] Improve “Your hands are full” by naming the object and explaining how to return it.
- [ ] Improve “This place is empty” when the player needs to pick up a standard first.
- [ ] Shorten standards completion copy instead of listing all eight symbols again.
- [ ] Correct Cosmos's intro claim that everything must be repaired before the sun rises.
- [ ] Reconcile Hall's right-pan instructions with both pans calling `place_heart`.
- [ ] Shorten the procession introduction's list of problems; allow discovery through play.
- [ ] Move asset-production details and “nothing is redrawn” out of gameplay introductions.
- [ ] Standardize names for bier boat/bier/sledge and band/register/shelf where the distinction is not meaningful.

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

- [ ] Preserve essential visual, audio, ownership, health, progress, phase-change, and recovery feedback.
- [ ] Remove routine success narration where animation already communicates the result clearly.
- [ ] Keep concise first-occurrence rule teaching and failure explanations; put extended advice behind Hint.
- [ ] Avoid repeating the same controls in intro, walking description, click reminder, and hit feedback.
- [ ] Preserve controls while transient feedback is shown, without adding excessive UI chrome.
- [ ] Choose one readable progress indication per minigame where current animations do not show remaining work.
- [ ] Add first-occurrence feedback for an actual plain-bronze hit on a red crocodile.
- [ ] Refine ambiguous timing diagnoses and verify that feedback accurately identifies the cause.
- [ ] Make critical phase-change cues brief enough to read without sacrificing the next action.
- [ ] Consolidate failure messaging into cause and retry guidance; prevent stale messages after exit/reset.
- [ ] Preserve meaningful character dialogue and Hall declarations while trimming repetitive mechanical narration.
- [ ] Test feedback with sound muted and with repeated mistakes to verify clarity without message spam.

## P3 — Dead code and maintenance

- [ ] Remove obsolete `_parked` sprite dictionary/layer and unused pick/take/reset branches now that upper offerings are physics bodies.
- [ ] Update offering-table comments describing fixed parked sprites and the frond returning above instead of falling.
- [ ] Update hauling documentation that says the original hauler appears only after success.
- [ ] Review hidden-avatar positioning/leaning during hauling; preserve required camera/exit positioning and remove redundant work.
- [ ] Remove ignored HUD configuration fields and obsolete task-panel data where appropriate.
- [ ] Remove or give purpose to HUD `_done` and `update_tasks`, which store data without displaying it.
- [ ] Decide whether the disabled minimap is planned functionality or obsolete code, including its signals and level connections.
- [ ] Resolve the commented-out spell-38 gate override and align progression, copy, and regression expectations.
- [ ] Share repeated glow, completion-flash, and palette behavior where it prevents divergence.
- [ ] Review `_hurt` tween callbacks for freed-node access during cleanup reported by the danger test.
- [ ] Reset `_table_told` on restart so first-time table instructions can be shown again.
- [ ] Update stale README descriptions, especially spell 41's old reeds mechanic.
- [ ] Update the project description's outdated spell ranges.

## Validation after implementation

- [ ] Review all five intros/outros, Journal pages, and menus at 1280 × 720 and smaller window sizes.
- [ ] Check the longest messages with and without a carried item.
- [ ] Check each minigame before starting, during feedback, after failure, and after reopening.
- [ ] Verify Journal/overlays pause gameplay and cannot accidentally move or exit the avatar.
- [ ] Check color meaning and readability in grayscale.
- [ ] Test hints with encounters played out of order and while carrying an object.
- [ ] Verify exits match their displayed instructions.
- [ ] Run regression suites after resolving the gate override and cleanup errors.
- [ ] Check off each implementation item only after its relevant verification passes.

## Intro slides: the Old Fax font (audit 2026-10-14, waiting for the go-ahead)

Checked at 1280×720 on all five intros (procession, cosmos, field, hall, dangers). The outro uses
the same builder (`hud.gd` `_build_overlay`), so every fix here applies to it too.

**Why it looks cramped:** Old Fax is set with ascent 768 + descent 192 in a 1024 em and a line gap
of 92 that Godot ignores. At 16 px the lines are only 15 px apart, less than the font size, so
descenders nearly touch the ascenders of the next line. At 32 px (the scribe strip) it is the same.

- [ ] **Line spacing.** Set `line_separation` on RichTextLabel and `line_spacing` on Label in
  `UI.theme()`: about +6 px at 16 px (a 21 px pitch, ~1.3×) and about +10 px at 32 px. Doing it in
  the theme fixes the intros, outros, journal and scribe strip together.
- [ ] **The button.** "Begin" (32 px) has no padding, so its letters touch the box. Give the
  Button styles content margins of about 16 px left/right and 6–8 px top/bottom (normal, hover
  and pressed alike). Also check the menu's buttons, which use the same theme.
- [ ] **Panel breathing room.** The panel padding of 28/22 → about 36/30. Raise the spacing after
  the title from 14 to about 18 and before the button to about 24 (a spacer, or a separate
  separation). In the hall intro the title "Spell 125: The Hall of the Two Truths" nearly touches
  the right border.
- [ ] **Paragraph gaps.** Once lines are spaced, a full blank line between paragraphs (`\n\n`) is
  ~42 px, too much. Use single `\n` with RichTextLabel `paragraph_separation` (~10 px) instead.
- [ ] **Line length.** The body is 640 px wide, about 80 characters a line at 16 px. Narrow it to
  ~580 px (~70 characters).
- [ ] **Bold and italics do nothing.** Old Fax has no bold or italic face, so `[b]right to left[/b]`
  (dangers, procession) and `[i]…[/i]` show as plain text. In `_keys()`, map `[b]` to the tag red
  (`UI.TAG`) and `[i]` to ochre, or drop the markup.
- [ ] **Remove "Every figure is cut directly from Lepsius's 1842 plates; nothing is redrawn."**
  from the intros in `procession.gd` and `dangers.gd`. `godot/README.md` already says "Every figure
  is cut from the plate scans"; add "nothing is redrawn" there, once.

Seen in passing (not the intro, same cause):
- [ ] **Scribe strip overflow.** At 32 px, a three-line scribe line (dangers' spell 31 intro,
  the hall's opening) passes `_fit_say()`'s height test but its last line runs into the bottom
  edge of the window. Once lines are spaced, three lines at 32 px won't fit; check the
  threshold so these drop to 16 px.
