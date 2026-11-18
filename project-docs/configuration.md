# Totenbuch: Configuration Document

**Status: Initial (G1).** Version 0.1, 2026-11-17. Owner: Sophia (Tech Lead, with Creative Director approval). Gate Approver: instructor.

Describes how production work is delegated to agents and where their configuration lives. **In-game agent: proposed** as an optional guide module (Section 4). Tags: **[Exists]** the artifact is in the repo, **[Planned]** not yet written, **[Open]**. Nothing is marked *evaluated* yet: no role has an evaluation record.

## 1. Shared settings

| Item | Value |
|---|---|
| Coding agent | Claude Code (desktop app), model chosen per session **[Open]**: record model/version in each task |
| Repository | `github.com/anonymousanemone/totenbuch-game`, branch `main`; PRs and CI **[Planned]**: no `.github/` exists yet |
| Project instructions | `CLAUDE.md` → `AGENTS.md` (asset-rebuild rules, tests, movable objects, minigame view) |
| Project skills | `.claude/skills/<name>/SKILL.md` (moved from `skills/`, 2026-11-17; no symlinks) |
| Memory | `~/.claude/projects/.../memory/` (private to the author; not part of the archive) |
| Test command | `python3 godot/tests/run_tests.py` (all suites); single level: `godot --headless --path godot -- --level=dangers --autotest` |
| Human override | Author approves every commit and push; agents never rebuild `godot/assets/` or write to `art/` without an explicit request (`AGENTS.md`) |
| Spending / timeouts | Paid model calls only inside the optional guide module (Section 4); none in the release build. Agent session limits **[Open]** |
| Logging | `project-docs/decision-log.md` (one entry per session, `.claude/skills/log-decisions/SKILL.md`), git history, `TODO.md`, Asana (from G2), PPP weekly |

## 2. Role coverage map

| Role | Executable artifact | Purpose | Context | Tools / permissions | Outputs | Recipient / handoff | Evaluation | Human approval |
|---|---|---|---|---|---|---|---|---|
| **Producer** | **[Planned]** `.claude/skills/plan-cycle/SKILL.md` + Asana connector | Turn goals into tasks, PPP, risk updates | `project-docs/plan.md`, GDD, Asana | Read repo; Asana read/write; no code edits | Task list with owner, acceptance criteria, PPP draft | Author, then role agents | Task has acceptance criteria and dependency before it is accepted | Author accepts plan and scope changes |
| **Design Lead** | **[Exists]** `.claude/skills/suggest-games/SKILL.md` + `levels.md` | Propose puzzles from the drawn plate | Plate strip, `registry.json`, `levels.md`, `ideas.md` | Read; edit `ideas.md` only | Pitch (X / motivation / loop / what the player loses) | Tech Lead, Art Lead | Pitch checked against drawn art and existing level play | Author chooses what is built |
| **Tech Lead** | **[Exists]** `.claude/skills/build-levels/SKILL.md`, `.claude/skills/check-features/SKILL.md`, `AGENTS.md`, `tools/` | Build a level from `.mdp`, wire shared behaviour | `.mdp` in `art/`, `level.json`, scene skeleton in `README.md` | Edit `godot/` and `tools/`; rebuild only named items | Saved scene, scripts, JSON | QA | Level suite passes | Author approves asset rebuilds and commits |
| **Art Lead** | **[Exists]** `.claude/skills/splice-plates/SKILL.md` (splicing and cutting), `.claude/skills/make-artwork/SKILL.md`, `.claude/skills/draft-ui/SKILL.md`, `project-docs/style-guide.md`, `project-docs/asset-list.md` | Splice and cut plates; scroll and UI art; UI drafts | `art/og_300dpi`, Old Fax font, `ui.gd`, `mockups/` | Edit art outputs in a temp dir; never write `art/` | Spliced and cut `.mdp`, sprites, HTML UI drafts | Tech Lead | Art Direction Peer Review table (GDF 5.3); pieces match plate 1:1 | Author fixes misfits |
| **Narrative** | **[Exists]** `.claude/skills/cite-references/SKILL.md`, `.claude/skills/write-game-text/SKILL.md` | Captions, translations, citations | `registry.json`, Davis 1894, Lepsius | Edit JSON text and references | Sourced descriptions, instructions, feedback, hints | Design, Tech | Every description has a `reference`; unsourced items logged in `TODO.md`; lines within 3 rows, longer translations and titles flagged; every line reachable | Author approves wording |
| **Audio** | **[Planned]** a skill built from patterns once the first sounds exist | Background music (can be turned off) and sound effects | GDD feedback section | n/a yet | n/a | Tech Lead | n/a | Author |
| **QA** | **[Exists, partial]** `godot/tests/` (suites listed in `run_tests.py`), `.claude/skills/playtest/SKILL.md` (cold-tester playtests), `godot/tests/step_driver.gd` + `step.py` (step driver) **[Planned]** `.claude/skills/qa-report/SKILL.md` | Check behaviour, reproduce failures, verify fixes | Test suites, build, bug list | Run tests; read repo; no source edits | Reproducible report with build id | Tech Lead, author | Suites exit 0; failures reproduce from the report | Author closes defects |
| **BI** | **[Planned]** `.claude/skills/playtest-summary/SKILL.md` | Summarise playtest and test evidence with limits | Playtest Log, test output | Read-only | Observations table, limits of evidence | Design Lead, Producer | Summary separates observation from interpretation | Author interprets |
| **Publishing & Release** | **[Planned]** `.claude/skills/release-check/SKILL.md` + Godot export presets | Build, package, instructions, archive | Release criteria, export output | Run export; write to a temp dir | Release notes, build tag, archive check | Author | Fresh-machine run by a second person | Author approves Gold tag |

Shared models are allowed. A row counts as covered only once its artifact exists and has been used with evidence; today: Design, Tech, Art, Narrative (artifacts exist, no evaluation records), QA (tests exist).

## 3. Per-role details (to fill at G2)

For every role: prompt or skill location, failure modes, timeout/retry, and configuration version. Existing skills are versioned by git commit. **[Open]**

## 4. In-game agent

**[Planned]** A guide module: three of the strange creatures (163–165) can go with the player as companions and give hints. Each knows only one tense: the past, the present or the future. None is fully reliable, and none can solve a puzzle alone; the player solves it by checking what the companion says against the scene.

**Choosing a companion.** At the start of each level the player picks one companion, or none. The companion follows the avatar through that level and speaks only when the player clicks on it. Choosing none leaves the level as it plays without the module; the Hint button stays either way. The choice screen is the only place all three appear together, so their scripted lines about each other (for example, warnings about the snake) are spoken there. These lines come after G2: the prototype offers only Min or none.

**Prototype scope (G2).** The prototype carries Min only; the choice is Min or none. The snake and the dwarfs come after G2. The sections below describe all three so the module's boundaries are settled in advance.

**Agents.**

- **Min, the scarab-bodied ithyphallic god (165): the future.** Knows only the finished state of each item in the scene that is not yet fixed, and fusses over the Negative Confession. He sees whether an item is fixed, never partial progress inside it. Each time he speaks he picks one unfinished item at random, not the nearest one, so he is never a pointer; a fixed item drops off his list. He can say what "whole" looks like, but only as a wrong to avoid ("*I have not stolen the offerings*… we haven't, have we?"), never as the fix. *Why him:* the scarab body (becoming), the spell's aim that the dead rest whole, and the rubric placing him on the heart, the witness at the weighing (30B). *Fault:* he cannot see half-done work, so he frets over a partly fixed item as if nothing had been done, and he can stretch a confession onto a scene where it barely applies. *Personality:* anxious and fussy, against Min's usual confidence. He never calms: as more items are fixed he frets a little more, not less, as if the end coming near makes it worse. The fretting shows as more mentions of the Negative Confession: with few items fixed, some of his lines cite a confession; near the end, most do, and now and then one line runs two together. The rise is slight, not a change of character; the module sets how often he cites from the share of items fixed.
- **The legged snake (163): the present.** Knows only the current scene's state. Its facts (where pieces are, what figures hold) are correct; its opinions on whether something is right are guesses, often wrong. *Why it:* spell 163 keeps the body from decaying, as it is now; it walks on legs, so it is always in the current scene; it carries the sun disc. *Fault:* it cannot tell an error from the original, and it judges anyway. *Personality:* irritable and snarky, often rude, and confidently wrong.
- **The two-headed Ptah-dwarfs (164): the past.** Know only finished levels and the journal, and nothing of the current scene. They bicker: each remembers part of what happened and corrects the other. *Why them:* two heads each, and one dwarf stands behind Mut. *Fault:* they misremember, contradict each other, apply old patterns where they don't fit, and have little to say early in the game. *Personality:* a bickering old pair.

**Look.** The creatures are drawn from the plates in a colour unlike the scroll's: lapis or faience blue. Their bodies are transparent, so the papyrus shows through, and their outlines are translucent (about 60% opacity).

**Works in every level.** The creatures read no level code. Levels emit a small set of shared events (puzzle started, figure clicked, placement failed, puzzle solved, hint requested); the module listens to those only. Knowledge comes from the existing JSON (`registry.json` for descriptions, `puzzles.json` for puzzle state), with an optional per-level `guides.json` for overrides and to switch creatures off. Min's confessions are the 42 declarations of the Negative Confession already in the game data (the judges of spell 125, `godot/assets/hall/registry.json`); the model only phrases them. A future level gets the guides by emitting the shared events.

**Hints.** The creatures do not draw on the hint text. How they interact with the Hint button and its tiers is **[TBD]**.

**Removable.**

- Everything lives in one folder (e.g. `godot/guides/`), including the model calls; no base-game script refers to it.
- The game adds the module at start only if its script exists (`ResourceLoader.exists`), not as an autoload, so a missing folder cannot break a build.
- The Hint button and each level's scripted `hint()` stay as they are: the robust baseline, and the fallback whenever the module is absent, slow or failing.
- A release export preset excludes the folder (`exclude_filter`), so the published game keeps no network access (GDD Section 13).
- Test suites run with and without the folder; both must pass.

**What each role knows** (agent-visible state; the world state also holds every solution and every level).

| | Min (future) | Snake (present) | Dwarfs (past) |
|---|---|---|---|
| Finished state of this scene's unfinished items | Yes | No | No |
| Which of this scene's items are fixed (yes or no only) | Yes | No | No |
| The 42 negative confessions (spell 125) | Yes | No | No |
| This scene's current state (pieces, what figures hold) | No | Yes | No |
| Player's actions | No | The last 2–3 in this scene | Earlier levels only |
| Text the player has seen | No | This scene only | Earlier levels only |
| Journal | No | No | Yes |
| Other levels | No | No | Finished ones only |
| Hint ladder | No | No | No |

No agent holds the hint ladder; the scripted Hint button stays the reliable source.

**Prohibited actions.**

- No agent changes game state: no moving pieces, solving puzzles, writing the save or opening levels. Creatures only speak, and walk paths the module scripts for them.
- No agent uses anything outside its column of the table above.
- Min never names the target piece or its destination; he speaks of the restored scene only through its confessions. He never mentions an item that is already fixed.
- The snake may be wrong in its opinions and may answer off-topic questions, but never about its facts, the controls or the rules, and it never gives the full solution. Its rudeness is aimed at the situation or the player's moves, never at the player as a person. Its wrong opinions cost the player nothing (wrong placements already return).
- The dwarfs mention only finished levels and journal entries the player has.
- One line, about 180 characters at most, as for all dialogue.
- Vertex safety filters stay on for every role; no role asks for or keeps personal information.

**Memory policy.** Within a level the module keeps each snake opinion and whether it was proven wrong, and the last 3–4 exchanges. The snake's memory is cleared when the player leaves the scene; Min's when the level ends. Across sessions the module stores nothing of its own; the dwarfs read the save the game already keeps (journal, solved puzzles). Typed text goes only to the playtest log, never to the save.

**Preventing made-up facts.** Min and the dwarfs:

1. **The model never writes facts.** It returns a structured answer: a `fact_id` from the entries its agent may see (registry, journal or confession ids) and a short in-character line. The game inserts the cited text itself.
2. **Closed list of names.** A line may name only figures, objects and gods in its agent's snapshot. A checker rejects any other proper noun, and any spell number, date or number not in the source.
3. **"I don't know" is an answer.** Each has scripted in-character lines for factual or off-topic questions its snapshot cannot answer; it uses them rather than guess.
4. **Low temperature** (about 0–0.3).
5. **Checks before showing:** length, the name check, no naming of Min's target piece or destination, and a `fact_id` that exists and that the agent may see. A failed check gets one re-ask, then the scripted line.
6. **Regression cases:** trap questions (Egyptology trivia, spell numbers, "just tell me the answer", other levels) must produce the scripted lines. Any proper noun the log flags becomes a new case.

**The snake is the exception.** It has no "I don't know": it answers anything, off-topic included, and its opinions may be wrong. Its facts and opinions are still built from a menu (`{figure_id, object_id, claim}`, for example "holds", "is near", "looks right" or "looks wrong"), so its facts come from the current state and a wrong opinion points at real figures. Because it is often wrong, the game marks it as unreliable:

- Its lines are set apart from all other text, in their own colour or style.
- Nothing it says enters the journal or the registry, so nothing it gets wrong is ever shown as a cited fact.
- After G2, on the choice screen, the other creatures grumble about it in scripted lines (for example, the dwarfs agreeing, for once, that it is not to be trusted).
- When an opinion is proven wrong, it reacts in a scripted, sulky line, which teaches the player early that it can be wrong.

**Model.** Vertex AI Gemini 3.5 Flash-Lite (GCP credits), the model used in the midterm; no strong model. Its vision is weak, so input is a compact structured text state cut to each agent's column above, never screenshots. Output is one short line, checked before it is shown; on a bad or late answer, the scripted line is used.

**Latency and timeout.** The module's latency is not measured yet. Timeout: 3 s per call, with no retry after a timeout; the scripted line is shown instead. Latency should not matter much: Min speaks only when clicked, says one short line, and nothing in the level waits on him, so a slow answer costs a moment's pause, not play.

**Agent hypothesis (draft, prototype).** We expect Min, who knows only the future and is partly wrong, to help players solve puzzles by checking what it says against the scene, without giving the solution away, compared with the scripted Hint button. We will investigate by having external playtesters play the G2 level, half with Min offered and half with only the Hint button, and comparing puzzles solved and Hint button uses; the session log shows whether players act on the item Min named and whether any line gave a fix away.

**Spending limits.**

- Per session: a cap of 40 model calls. Past it, the creatures switch to scripted lines in character (for example, the snake sulks off to sleep). The shared prompt prefix (instructions, personality, examples) is cached.
- Per project: a GCP budget alert and a Vertex quota as a hard stop.
- No GCP key ships in any build. Calls go through a small Cloud Run proxy that holds the credentials and enforces the caps; shutting it off turns every creature scripted.

**Cost estimate** (Gemini 3.5 Flash-Lite on Vertex, global endpoint: $0.30 per million input tokens and $2.50 per million output, reasoning included). These are the prices from the midterm, confirmed on Google's pricing page on 2026-11-15. The cached-input price is not confirmed; the cached figure below assumes $0.03. Thinking is set to its minimum, because thinking tokens bill as output. Precedent from the midterm, same model: 4,944 calls, about $3.19, median latency 0.9 s, 95th percentile 2.5 s.

| Item | Assumption | Cost |
|---|---|---|
| One call | ~2,000-token prefix, ~1,500-token state and question, ~200 output tokens | about $0.0010 cached, $0.0016 uncached |
| One session at the cap | 40 calls, 20% re-asked, no caching | about $0.07 |
| Playtests | 20 sessions at the cap | about $1.50 |
| Development and evaluation runs | 5,000 calls | about $8 |

The whole course stays under about $10 at list price, inside the GCP credits. Cloud Run at this traffic should stay within its free tier. Suggested budget alert: $10 a month.

**Logging.** One local JSONL file per session in `user://`, no names, playtesters consent first. Each call records time, level, puzzle, role, hint tier, the state sent, the question, the raw answer, the `fact_id` used, whether the checks passed, the line shown, whether the scripted fallback was used and why, latency and tokens. After each line it records what followed: whether the player solved the puzzle within the next few actions, whether a snake opinion was right, and whether the player acted on the line. Bad answers become regression cases in the evaluation suite.

**Still to fill** (items the GDF, Section 5.2, requires for an in-game agent that this section does not yet cover):

- **Tools:** what each role may call (for example, read its snapshot, return a `fact_id`, pick a snake claim from the menu, point at a figure).
- **Prompts or system instructions:** where they live, and how they are versioned.
- **Failure modes:** a named list (timeout, malformed answer, made-up name, proxy down, cap reached) with the response to each.
- **Fallback:** the trigger and verified result for each failure (for example, a forced-timeout test shows the scripted line and leaves the Hint button working).
- **Human override:** how the author and the player switch the creatures off.
- **Configuration versions and artifact locations:** folder, prompt files, proxy, and test commands for the module.
- **Evaluation:** at G1, proposed tests and the baseline (GDF 5.8); from G2, records with the fields in GDF 5.9.

## 5. Executable extension artifact (syllabus requirement)

**[Open]** Candidate: a project plugin bundling the existing skills (`build-levels`, `suggest-games`, `cite-references`, `splice-plates`, `make-artwork`) with a manifest. Confirm the syllabus's required manifest fields before G2.

## 6. Open questions

1. Is a production-skill plugin enough for the extension artifact, or must it be in-game?
2. Model and spending limits per agent session.
3. CI: GitHub Actions needs a Godot install; run `run_tests.py` in CI or locally only?
4. Which new role skills (Producer, QA, BI, Release) are worth writing versus using the coding agent directly?
