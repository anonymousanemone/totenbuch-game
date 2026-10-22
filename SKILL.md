# Building new levels

## Source artwork

Inspect the hand-edited `.mdp` in `art/` and identify its spell groups, figures, captions,
frame guides, lower text, and tall vertical inscriptions. Preserve the source document;
exporting a level must not modify it. Respect existing layer names and authored positions.

## Export assets and metadata

Use the existing MDP reader in `tools/mdp300/mdp.py` and the level exporters as references.
Export named artwork into `godot/assets/<level>/figures/` and keep animation sheets, if
needed, in `animation/`. Record stable IDs, source bounds, dimensions, scale, ground,
and camera view height in `level.json`. Keep descriptions in the level's data catalog,
following the shared `descriptions.gd` format.

Export the complete scroll, including captions, frame lines, and lower inscriptions.
Preserve the original artwork's proportions and alignment. Separate tall vertical text
that needs to cover the walking avatar into foreground artwork; follow the existing
Dangers `Column` overlay for the papyrus backing and ink that hide the avatar.

## Author a saved scene

Create `godot/scenes/<key>.tscn` with the papyrus background, strip, named figures,
foreground inscriptions, starting avatar, camera, and HUD as saved nodes. Organize the
artwork by spell and retain stable IDs in node metadata. Use one `Sprite2D` for one
picture; introduce parents only for meaningful groups, pivots, or behavior.

The intended arrangement must be visible in the Godot editor. Scene positions are
authoritative; runtime setup must reuse the saved nodes rather than rebuild the level
or overwrite editor placement. Keep source coordinates separately in the metadata.

## Connect shared behavior

For navigation-only levels, reuse the shared
avatar, `scroll_camera.gd`, HUD, hover glow, figure picking, descriptions, and journal.
Allow the complete scroll to be explored without puzzles or progression barriers.
Keep foreground inscriptions above the avatar in draw order, with papyrus backing
where needed so the avatar actually disappears behind the text columns.

If a later level requires movable objects, reuse `moveable_object.gd` and the existing
placement validation and recovery rules, as specified in `AGENTS.md`.

## Integrate with the scroll

Use the level's existing key in `godot/scripts/scroll.gd`, or add an entry when needed.
The menu recognizes a built level when `scenes/<key>.tscn` exists. Provide a map picture
at `godot/assets/menu/<key>.png`, with the top of the double rule flush with the image's
top edge and no faded lower text. Keep level titles and spell ranges consistent.

## Verify

Import the project in Godot and check for script and resource errors. Inspect the
saved scene and rendered views at the start, middle, and far end of the scroll.
Verify arrow-key and click navigation, camera bounds, figure hover and inspection,
journal behavior, HUD framing, and the avatar passing behind each foreground text
column. Use checks appropriate to the change and confirm the source MDP is unchanged.
Store temporary screenshots and verification artifacts outside the repository;
do not write to `mockups/` unless explicitly requested.

# Suggesting puzzles and minigames

How to propose a game for a vignette so that it can be built from the plates we have,
is played by looking rather than reading, and fits what the levels already do.
`ideas.md` is the catalogue; this file is the rule for what goes into it.

---

## 1. Look before suggesting

A suggestion starts from the drawing, never from a description of it.

- **Crop and view the art.** Use the level's strip (`godot/assets/<level>/strip.png`), the cut
  sprites beside it, and `level.json` for positions. Use the Lepsius page when the strip has lost
  something (text columns are cut short, sprites are lifted out of the strip).
- **Write down what is actually drawn.** Note which way each figure faces, what it holds, what
  touches what, what is bound, raised or broken, what is next to it and what is missing.
  `ideas.md` descriptions were made from small scans and can be wrong. Two examples:
  - Pl. IV: the man by the lector holds a goose, not a foreleg. The foreleg item had to go.
  - Pl. III: the calf faces the Apis bull, not the sacrifice behind it.
- **Check what is already cut.** If a figure is not yet its own sprite, it needs a layer in the
  `.mdp` (see the `table`, `haul` and `standards` folders, or `heka` for caption signs). Say which
  layer(s) to add.
- **Read the level's README section and its script.** Know which kinds of play the level already
  has, so the new one adds something different.

## 2. The verb comes from the picture

Each working game takes one gesture or state that is already drawn and makes the player do it.

| Drawn | Game |
|---|---|
| Ox-driver's raised whip | Rhythm: heave as the whip comes down (`haul.gd`) |
| A heaped table | Rebuild the heap, a piece only stays once what it rests on is there (`offering_table.gd`) |
| Bearers with standards | Put each god back on its pole (procession) |
| Goose-bearer, loose goose | Take the wrong thing from his hands, give him the right one |
| Two lions back to back | Turn each lion (`cosmos.gd`) |
| Cat with a knife at a snake | Strike when the head is under the knife |
| Spear-bearer facing a creature | Each creature's own spear fight (`danger_encounters.gd`) |
| Ploughman, sower, reaper, ox | Do the field work in order (`field.gd`) |

If you cannot point to the place in the drawing that the verb comes from, the idea is not ready.

## 3. Solved means "as drawn"

The plate is the answer. A puzzle disturbs the picture, and solving it puts the picture back:

- the standards on their poles
- the table heaped
- the sledge where it is drawn
- the lions back to back
- a danger's vignette closing to its drawn state once the creature is overcome

Describe the disturbed starting state and show that the solved state is the plate itself.

## 4. Learned by looking, not reading

- **The rule must be readable from the image.** Cues that work:
  - glow under the pointer
  - a faint outline of where a piece belongs
  - a warning movement (tail wave, squash, head lift)
  - a caption sign flashing red (the heka word, the two snake signs of spell 37)
  - the beat of a drawn gesture
  - signs appearing above the lector's sheet
  - a body reddening as it is hurt
- **Text is at most one intro line and one hint line** (the `intro` / `hint` pattern), plus a
  short scribe line on success. The player must never need to read them twice to play.
- **Never make spell text the puzzle.** Quizzes, translations to match, and "the clue is in the
  spell" are all out. The spell can inspire the theme (spell 31: crocodiles come for the magic →
  the heka word is what they take), but the solution is in the picture.
- **Hieroglyphs in the caption band can be pieces.** Cut them like the heka signs and they can
  flash, glow, be clicked, or be eaten. Treat them as shapes, not words.

## 5. Prefer what exists, but explore

The engine can already do the things below with a cut figure. Reach for them first, since
they are cheap and proven. Don't stop there, though: also look for other means when a
vignette calls for them. Examples include sound, a new shader, light and shadow, the camera,
the papyrus itself, drag gestures, or a new input. Say what new machinery an idea needs.
Existing parts:

- **Pick up and set down** at its drawn place; clicking a filled place swaps the two pieces.
- **Turn / flip** a sprite (`flip_h`, a squash on `scale.x`).
- **Rotate about a pivot** (the whip about the elbow, the snake head about `head_pivot`).
- **Move a group together** (the whole hauling train).
- **Physics bodies with `rests_on`** (the fallen offerings).
- **Copies and mirrors of a drawn figure** (beetles, extra crocodiles, the mirrored Merti snake).
- **Shaders:**
  - `snake_tail.gdshader` bends part of a drawing
  - `dissolve.gdshader` makes a figure crumble
  - `glow.gdshader` lights up what can be clicked
  - red tint for hurt or heka
- **Open out the vignette:** neighbours covered, camera held.
- **Timing windows:** on the beat, at the strike, while the back is turned, while the head is
  down, while the head is up.
- **Ordered clicks** with an "out of order, not ready" response.

**Art stays the plate's.** New figures or objects that aren't on the plate are out.

Changes to what *is* drawn are fine, and often what makes a game work:
- copies and mirrors
- cuts of existing parts (a forearm, a head, a caption sign)
- tints
- minor redrawing, such as a limb in another position
- an animation of a drawn figure, like the spear-bearers' pose sheet
  (`assets/dangers/spearers.png`, eight poses from drawn-back to full thrust)

Say what drawing or animation an idea needs, so its cost is clear.

## 6. Fit the levels' conventions

- **Losing is never an automatic restart.** The figure crumbles or the vignette closes, and you
  are back on the scroll. Click to try again.
- **A gate is optional.** A task may bar the way on (an invisible barrier, the scribe saying what
  is left), but walking the scroll should stay possible where it already is.
- **One mechanic per vignette, and a different one from its neighbours.** Name the closest
  existing game and say what is new.
- **Fairness:** the game must always be winnable. For the precedent, see `min_gap` in spell 32
  and the fixed launch order in spell 31.
- **Testable:** say what `--autotest` would click or press to solve it, and what flag (`--skip`,
  `--at`) would jump to it.

## 7. Suggestion template

Sections 7 and 8 are guides, not a gate. Not every idea needs every field filled or every box
ticked. A rough idea can be a few lines, and a good game may break a rule for a reason (say
which one and why). Fill in what matters for that idea and keep the rest short.

The template is for the first review. Once an idea is accepted, it goes into `ideas.md` as a
short entry: what is drawn, the disturbed state, how it plays, and the pieces. Leave out the
justification there.

```
### <Name> (pl. N, spell S, strip x A–B)
Drawn:      what is there, checked against the crop (facing, hands, neighbours). [verify] anything unsure.
Verb:       the one drawn gesture or state the player performs.
Disturbed:  how the scene starts wrong.
Solved:     the plate as drawn.
Play:       input → what moves; success; failure; what "lost" looks like.
Cues:       how the player sees the rule without text.
Pieces:     sprites already cut / layers to add to the .mdp (folder, names), pivots.
Reuses:     closest existing kind and engine parts; anything new to build.
Tuning:     the constants (timings, counts, distances).
Text:       intro (1 sentence), hint (1 sentence).
Art:        none / which drawn figures get redrawn or animated.
Test:       what the autotest does.
```

## 8. Checklist before posting

- [ ] I looked at a crop of this exact spot and the sprites, not only `ideas.md`.
- [ ] Every figure I mention is drawn there, facing the way I say.
- [ ] The verb comes from something drawn.
- [ ] The solved state is the drawing.
- [ ] It is playable with the text hidden.
- [ ] The pieces are listed, and any redrawing or animation is named.
- [ ] It differs from its neighbours, and I named the closest existing game.
- [ ] Losing returns to the scroll, and it is always winnable.

## Example: what went wrong

On the three cattle at the pl. III/IV join (Apis bull, calf, the bull under the knife), earlier
suggestions included these:

- *"Choose the victim; the clues are in spell 11 and the Apis crown."*
  - The solution sits in a translation.
  - Nothing drawn shows "leading" an animal, and the idea never says what animation that would take.
- *"Strike Ptah's pose to make the Apis walk."*
  - It needs a spell quote to discover.
  - The four poses (Horus, Ptah, Thoth, Atum) are not drawn anywhere near, so they would be new figures, not changes to drawn ones.
- *"Garland of ankham flowers at the right ear."*
  - It comes from a rubric, not the picture.
  - The garland is not on the plate, so it would be a new object.

A better start is to look at the crop and list what is there:

- The calf, a separate sprite, prances facing right toward the Apis.
- The Apis wears a disc and two plumes, which can be cut as a layer.
- The bull lies bound on a block, with the butcher at its head.

Then pick a verb from that.
