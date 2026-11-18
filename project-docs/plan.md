# Totenbuch: Initial Project Plan

**Status: Initial (G1).** Version 0.1, 2026-11-17. Owner: Sophia (Producer). Moves to Asana after G1; owners, acceptance criteria, dependencies and the full Risk Register follow there at G2/G3.

**Dates:** from the course board (`example-crew-board-sample.html`). First pitch round was 2026-11-09; G2 and G3 share one combined review.

## Gates

| Gate | Decision | Date | Status |
|---|---|---|---|
| G1 Concept | Clear, worthwhile, achievable idea to investigate? | Mon Nov 16 (recording Sun Nov 15) | In preparation |
| G2 Prototype | Does the core experience have enough support to develop further? | Mon Nov 30, with G3 (recording Sat Nov 28) | Not started |
| G3 Production | Can the agreed game be completed with the time left? | Mon Nov 30, with G2 | Not started |
| Alpha / Beta | Milestones inside Production | Dec 1 to Dec 5 | |
| G4 Final / Pre-Launch | Is this build ready to release? | Mon Dec 7 (recording Sat Dec 5) | |
| G5 Retrospective | What was learned; is the archive usable? | Mon Dec 14 | |

## Tasks through G1

| # | Task | Role | Depends on | Status |
|---|---|---|---|---|
| 1 | Move project skills into `.claude/skills` (no symlinks), fix path references | Tech Lead | none | Done 2026-11-17 |
| 2 | Initial GDD (`project-docs/gdd.md`) | Design Lead | none | Draft done; open questions listed |
| 3 | Initial Configuration Document with role coverage (`project-docs/configuration.md`) | Tech Lead | none | Draft done |
| 4 | This plan | Producer | none | Draft done |
| 5 | Six-dimension Risk Profile and Initial Risk Register (`project-docs/risk.md`) | Producer | 2, 3 | Draft done |
| 6 | Creative Pitch (GDF 5.1) and recording, including systems diagram | Creative Director | 2, 5 | To do |
| 7 | Author decision: in-game agent in or out, and which level | Creative Director | 2 | Agent in: three guides, Min (future), the snake (present) and the Ptah-dwarfs (past). The prototype carries Min only; the level is still open |
| 8 | Fill gate dates from the syllabus | Producer | none | Done 2026-11-17 (course board) |

## Tasks after G1 through G2

| # | Task | Role | Depends on | Status |
|---|---|---|---|---|
| 9 | Connect Asana; import tasks 1–8 and the tasks below; add Owner, role, acceptance criteria, dependencies | Producer | G1 approval | To do |
| 10 | Choose the G2 experiment: which level or rework, and its playtest question (GDD Q1) | Design Lead | 7 | To do |
| 11 | Check syllabus G2 requirements (first playable and its agent, extension artifact, manifest fields) | Producer | 8 | To do |
| 12 | Build the first playable for the chosen experiment (`build-levels`, `splice-plates`) | Tech Lead, Art Lead | 10 | To do |
| 13 | Extend regression tests to cover the new play; keep `run_tests.py` green | QA | 12 | To do |
| 14 | Write the missing role skills worth having (Producer, QA, BI, Release; Configuration Document Section 2) | Tech Lead | 3, 11 | To do |
| 15 | Recruit at least one external player; run and log the first playtest (GDF 5.9) | Design Lead, QA, BI | 12 | To do |
| 16 | Revise the level from the findings and record the finding-to-change link | Design Lead | 15 | To do |
| 17 | Decide delivery format for playtesters (desktop export or web) and test that someone else can run it | Publishing and Release | 12 | To do |
| 18 | Update GDD, Configuration Document, plan, Risk Register; first-playable recording | Producer | 12–17 | To do |
| 19 | G2/G3 evidence package; request review | Executive Producer | 18 | To do |

**Not before G2:** new levels beyond the chosen one, audio, scope lock (G3).

## Standing rules

- Commits and pushes only when the author approves, one commit at a time.
- Rebuild only named assets (`AGENTS.md`); test only the suites for edited levels while iterating, the full sweep before a gate.
- New ideas go to `ideas.md`/backlog and are compared at the next planning point.

## Open questions affecting the plan

- Which guide or guides, and which level, the G2 first playable carries (task 7, 10).
- Which level is the G2 experiment (task 10).
