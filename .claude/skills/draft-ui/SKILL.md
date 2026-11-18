---
name: draft-ui
description: How to design a UI change for the Book of the Dead game (a menu, the HUD, the scribe's strip, a box, the journal, a minigame screen, a set of icons) by first making one self-contained HTML draft with several labelled versions and switches to tune them, in the game's UI style, before anything is built in Godot. Use before any new or changed screen, layout or UI element.
---

# Drafting UI in HTML first

A UI change starts as an HTML draft the user can click through, compare and tune. Nothing is built in
Godot until the user has chosen a version and its settings. The files in `mockups/` are earlier drafts
of this kind (`strip-layouts.html`, `menus.html`, `pixel-boxes.html`). Read the one closest to the task
before starting, and keep to its form.

The look to match is in `project-docs/style-guide.md` (UI style) and `godot/scripts/ui.gd`. Icons and
signs follow the `make-artwork` skill (UI art). There are no exceptions to these rules unless the user
explicitly approves one.

## What a draft holds

- **One self-contained `.html` file.** It embeds Old Fax (`godot/assets/fonts/OldFax.ttf`) as a base64
  `@font-face`, and the real images as base64 PNGs: icons and bands from `godot/assets/ui/`, scene
  pictures from `godot/assets/menu/` (or a screenshot of the level). No placeholder font, no invented
  icons where a real one exists.
- **The game's frame at 1:1.** Each version is a 1280 × 720 frame, scaled only by whole numbers, with
  `image-rendering: pixelated`. Text uses 16 or 32 px (24 px is fine for labels), as in the game.
- **The palette as CSS variables**, named and valued as in `ui.gd` (`--pap: #e2d0a6`, `--deep: #cbb07c`,
  `--ink: #2e1d10`, `--rule`, `--ochre`, `--tag`, `--cream`, and the minigame and hint tag colours).
  Don't add a colour that isn't there; propose it to the user as a change to `ui.gd`.
- **Several versions, labelled A, B, C, D.** A is what the game does now, for comparison. Every other
  version differs in one clear idea, said in one line under its title. Three or four versions are
  usually enough.
- **Each frame works.** Buttons respond, a box can be shown and hidden, a menu can be clicked through,
  a map scrolls. The user judges a screen in use, not a still.
- **Switches to tune it.** A sandbox part, or controls on each frame, for the choices still open:
  position, size, which box format, which colour role, text type (speaker line, minigame clue, hint),
  with or without a box. Show each setting's current value in plain words, so the user can say which
  one they chose ("B, narrow box, tag on the band").
- **Real text.** Use lines from the level's JSON (`registry.json`, `puzzles.json`, `messages.json`),
  including the longest one, so overflow shows. Don't write new game text into a draft.

## Steps

1. Read the closest mockup, `ui.gd`, `hud.gd` and the style guide. Note what the game does now.
2. Ask the user what is open, if the request doesn't say (AskUserQuestion).
3. Build the draft directly in `mockups/`, as a new file named for what it drafts (e.g.
   `journal-entries.html`). Don't change an existing mockup unless the user asks; make a new file.
4. Check it at 1:1 next to a screenshot of the game: same font size, stroke weight and colours. Keep
   the screenshots in the scratchpad, not in `mockups/`.
5. Show it to the user and go through the versions with them. Change it until they choose.
6. Build the chosen version in Godot with the chosen settings (`ui.gd`, `hud.gd`). Take a 1280 × 720
   screenshot of the game and compare it with the draft. Report any difference.
