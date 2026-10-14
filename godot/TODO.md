# TODO

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
