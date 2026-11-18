# Decision log

Who decided what, session by session: the author's decisions, what was made from them, and what agents did. Kept by the `log-decisions` skill; newest at the bottom.

## 2026-11-18 · Tech Lead skills: check-features, playtest, log-decisions
- **Decided:** playtest tester comes in completely cold; a step driver is allowed if needed; name "playtest".
- **Decided:** the author is asked about important decisions and told about the rest, without reading logs; this log replaces transcripts and records only decisions and built work, not suggestions, open items or questions.
- **Made:** `.claude/skills/check-features/`, `.claude/skills/playtest/`, `.claude/skills/log-decisions/`, `project-docs/decision-log.md`; `AGENTS.md` rule to run log-decisions every session, and the three skills listed in `AGENTS.md` and `project-docs/configuration.md`. Not committed.
- **Agent did:** sorted TODO.md bug history into the check-features steps; chose the five playtest player types and the asked/told split.
- **Corrected:** "tech lead should be like the others, skills"; "no work queue yet".
- **Corrected:** "whatever is currently existing is very unreliable, so don't rely so heavily on it (except for the gdf info document)".
