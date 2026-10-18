# TODO

## Open — to resolve

Everything still undecided or waiting, from the 2026-10-15 playtest. Design ideas (new games,
revamps, anything that plays boring) are also in `../ideas.md`.

### Procession

- [ ] **Put minigame instructions near the action:** the playtest suggests players expect instructions at the bottom and rarely look up. Review their placement and give instructions a slightly different appearance when entering a minigame; the visual treatment is still undecided.
- [ ] **Support players who are unsure what to do:** the playtest observation was “when confused, look around.” Review whether nearby figures, descriptions and NPC clues give enough direction. Keep these in-game clues separate from Hint-button hints.
- [ ] **Review all Procession minigame instructions:** check that each instruction matches its current objective and controls, and that entry makes the instructions easy to notice. Coordinate this with the placement and appearance review above.
- [ ] Redo the descriptions for cosmos by matching scholarly sources and actual knowledge of the bod. 


**New games and tools to consider**

- [ ] Consider a minigame for the barque.
- [ ] Consider a minigame for the mourning women.
- [ ] Consider a minigame for the two object carriers immediately behind the Apis bull.
- [ ] Consider a minigame involving the incense.
- [ ] Decide whether the second offering table should have its own minigame.
- [ ] Research a drawing or 2D rigging tool that lets you select part of an image, set a pivot/reference point and rotate that part around it.

### Dangers
- [ ] Spell 35, red light green light: too easy. Maybe one life only, or no hints (undecided).
- [ ] **Your call:** spell 37's new Merti wording (nothing may give away that the flashing sign shows which snake strikes): intro "Turn to the snake that strikes ([←] [→]), and thrust as it springs."; hint "Watch the signs above. Striking too soon provokes a snake."; bitten from behind "It sprang from your other side. Turn to face it ([←] [→]). Bitten."
- [ ] Spell 39, Rekrek (Apep): far too easy. Make it faster, or change the game.
- [ ] Spell 38: life and breath become two separate signs, and only breath is taken: the player must click the breath sign (one choice only). Taking the wrong one makes the following fights nearly impossibly hard. Clicking spell 38's caption title shows "breath" in bold (or similar), which tells the player which to pick. **Art ready (2026-10-16):** in the .mdp the ankh and the sail are separate layers now: `breath38/ankh` is the ankh (life) alone, `breath38/t3` the sail (breath). Still to decide: how "nearly impossibly hard" works after taking the wrong one. *Built (2026-10-16):* they are two sprites (`ankh38`, `sail38`), each clicked on its own; only one can be taken, the other stays in his hand. For now either one opens the way on.
- [ ] Spells 40–41: both are boring and slow. Rethink their pace (undecided).

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
