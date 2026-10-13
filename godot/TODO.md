# To do: Dangers on the Road (`scripts/dangers.gd`)

Noted 2026-10-13, to pick up later.

## Snakes
- [x] When the spear strikes a snake, the snake flushes red, the same way the bearer's body does
      when he is bitten.

## Crocodiles, second wave / spell 32 (both sides)
- [x] Spacing across sides: the rule that no two crocodiles come closer together than about a
      front half of a body also applies between the two sides. When working out spawns, treat
      left and right crocodiles as if they were on the same side, so they never come too quickly
      one after another from opposite sides.
- [x] The last crocodile to attack is always one of the crocodiles that have been squatting on
      screen (the drawn ones).

## Losing animation (spells 31 and 32)
- [x] Use one animation both when a crocodile gets past and when the player strikes an ordinary
      crocodile with the red (heka) spear. Use the wrong-strike one: the heka word spins, falls
      into the crocodile's mouth and is carried off. Add the cackle back to it (the crocodile
      squashing up and down as it laughs).

## After losing
- [x] Never restart a fight automatically. Put the player back on the dangers scroll, standing
      at the vignette; they click the creature again to take the fight up again.

## Walking
- [x] Make the player walk very slightly faster (`avatar.gd`).

## Also seen (2026-10-13)
- [x] `--autotest` fails at spell 33 (snake lunge): the strike window comes out as 695 ms
      instead of about 80 ms, and script errors after that stop the test from finishing.

All done 2026-10-13. Walking speed went from 300 to 330 (`avatar.gd`). The spell 33 autotest
failure didn't come back (window 185 ms, autotest OK).
