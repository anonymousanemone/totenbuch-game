---
name: log-decisions
description: How to keep project-docs/decision-log.md, a brief running record of who decided what in each session of the Book of the Dead game - the author's decisions, what was made from them, and what agents did on their own - so that no transcript has to be kept. Use at the end of every session that decided, made or changed anything, and update the same entry if the session goes on.
---

# Logging decisions

The log replaces transcripts. It records who decided what, what came of it, and what agents did without being told, so a later reader (or the G5 retrospective) can tell the author's calls from the agent's. It is read often and grows forever, so every entry is short.

## When

At the end of every session that decided, made or changed anything, before the closing message. If the session continues, update its entry rather than adding a second one. A session that only answered a question, or only read, logs nothing.

Each session writes only its own entry. Never edit another session's entry, even a parent or a side session; add a line to your own instead ("corrects 2026-11-18 playtest entry: ...").

## Format

Append at the bottom of `project-docs/decision-log.md`:

```
## 2026-11-18 · playtest and decision-log skills
- **Decided:** tester comes in completely cold; a step driver is allowed if needed.
- **Made:** `.claude/skills/playtest/`, `.claude/skills/log-decisions/`.
- **Agent did:** chose the five player types; wrote the asked/told split.
- **Corrected:** agent treated existing docs and code as reliable; only `gdf.md` is.
```

The heading is the date and a few words naming the work. Use only the lines that have something; most entries need three or four.

- **Decided**: what the author decided in chat, in their terms. Add the reason in a clause only if they gave one. Include approvals of agent suggestions ("approved the cold tester").
- **Made**: files, levels, assets, tasks or commits that came from those decisions. Paths and hashes, not descriptions. Group a folder rather than listing its files.
- **Agent did**: choices the agent made itself, in work that was actually made, that the author would notice and might overrule: a default picked, a severity set, a sibling copied, something left out. Not routine steps.
- **Corrected**: a wrong assumption or decision the agent made that the author overturned, stated as what was wrong and what is true instead (a game behaviour assumed, a detail guessed, a rule or direction misjudged). Do not quote the author; the line must make sense alone. Leave out redo requests and tweaks ("remove that", "go back to before", "make it smaller", "you broke X"), and corrections that only repeat a line already under **Decided**. These are the most useful lines in the log, so keep them few and specific.

Log only what was implemented. Suggestions, outlines, plans and open questions that were never built are left out; if one is built later, it goes in that session's entry.

## Keeping it brief

- One line per bullet, about 25 words at most. Several items on one line, separated by semicolons.
- Record only decisions and actions. Questions the author asked, explanations of how something works, and back-and-forth that changed nothing are not logged, however often they came up. A question that asks for something to happen ("how will this ensure X?" meaning "make it ensure X") is an instruction: log it under **Decided** in its imperative form, with what changed under **Made**.
- No reasoning, no process, no test runs that passed, no files read. Outcomes only.
- Name things by path, id or commit, so the detail can be found in the repo instead of the log.
- Don't repeat what an earlier entry says; refer to it by date.
- Attribution must be right: a line is **Decided** only if the author said it in chat. Anything the agent inferred, or did because nobody objected, is **Agent did**.

## Committing

The log is a project file. Commit it with the session's other changes, under the same approval as any commit. Don't rewrite or summarise old entries unless the author asks.

## Checking

1. The session has exactly one entry, at the bottom, with a date and a name.
2. Every **Decided** line is something the author said, not something the agent assumed.
3. Every agent choice the author would notice is in **Agent did**, and nothing unbuilt is logged.
4. Every bullet is one line, with paths or ids rather than descriptions, and is a decision or an action, not a question or an explanation.
5. Every **Corrected** line names the wrong assumption and the truth, without quoting the author, and is not a redo request or tweak.
6. No other session's entry was changed.
