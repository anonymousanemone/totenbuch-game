---
from: student
to: narrative
kind: origin
column: prototype
date: 2026-11-22
---
## Why this agent
The same text corrections kept coming back: lines too long for the strip, claims no source supports, wording that gave the fix away, and descriptions that needed a source found after the fact.
- 2026-10-18: hints and descriptions reorganized after repeated rewording requests ([83446b8](https://github.com/anonymousanemone/totenbuch-game/commit/83446b8)).
- 2026-10-20: the crocodile instructions said they are hit only at the snout, which is wrong ([decision log, 2026-10-20](../../project-docs/decision-log.md)).
- 2026-11-22: citation to-dos and a source still missing for the beetle name "Apshai" in Dangers ([6043ec2](https://github.com/anonymousanemone/totenbuch-game/commit/6043ec2)).
- Open: nine Gates descriptions longer than three lines ([Notion row](https://app.notion.com/41b67ab14ecf8190abfef5b0fc5582ec)).
## Use
`write-game-text`, `cite-references`, the level JSON (`registry.json`, `puzzles.json`, `messages.json`), Davis 1894, the Configuration Document Section 4 for Min, and Notion rows with Role Narrative and Audio, including text split off by tech under `small-fixes`.
## Produce
Changed lines with the old and new text, `reference` fields for every sourced line, Min's voice guide and scripted fallback lines, and a list of sounds needed.
## Accepted when
Every changed line is at most three rows or flagged, reachable in the game, cited when it comes from a source, and never gives the fix away; tech's text handoffs are answered; the author approves the wording.
## Evidence
The JSON diff, the description and hint suites passing (`description_regressions.gd`, `hint_regressions.gd`), and the Notion rows with their agent log lines.
## Student decision
