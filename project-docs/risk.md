# Totenbuch: Risk Profile and Risk Register

**Status: Initial (G1).** Version 0.1, 2026-11-17. Owner: Sophia (Producer). Updated at G2/G3 and through G4 (GDF 3.5, 5.4).

**Evidence used.**

- This repo: git history (67 commits, 2026-10-13 to 2026-11-15) and the playtest notes from 2026-10-15 (`ideas.md`, `TODO.md`).
- The midterm excerpt of this game (`game-dev-f26/midterms/anonymousanemone`, spells 31–32):
  - its evaluation (`EVALUATION.md`, `reports/held-out-final.md`)
  - its peer playtest (`PEER-NOTES.md`, 2026-11-07)
  - its agent-team log (`AGENT-TEAM.md`)

**Gate dates** (course board, `example-crew-board-sample.html`):

- **G1:** Mon Nov 16
- **G2/G3:** combined review Mon Nov 30, recording Sat Nov 28
- **G4:** Mon Dec 7, recording Sat Dec 5
- **G5:** Mon Dec 14

## Risk Profile

| Dimension | Rating | Evidence |
|---|---|---|
| **IP / Concept** | Low | **Art:** from Lepsius's *Todtenbuch* (1842), which is public domain. The digital edition is credited to Dr. Marcus Müller (Totenbuch-Projekt, Bonn), hosted by UB Heidelberg / Propylaeum-DOK. **Font:** Old Fax (George Blackwell), CC BY 4.0, unmodified. **HUD borders and icons:** made with Claude Code. **Davis (1894) translations:** public-domain status not yet confirmed. I plan to modify his translations, and they will be credited as adapted from Davis. **Concept:** clear, and five levels are built. |
| **Business / Audience** | Medium | **Subject:** niche (Egyptology), but the topic and the way it is built are unusual: the player restores a real papyrus by looking at its drawings. The concept draws interest. The risk lies in the implementation: whether each game is actually fun to play, not only a good idea. **Evidence so far:** two small playtests, one player each (2026-10-15 on this game; 2026-11-07 on the midterm excerpt). Both were about difficulty and pace. |
| **Technology** | Medium | **The midterm** used the same model family, Gemini Flash-Lite on Vertex, driving this game's Godot combat: 2,199 calls in the frozen evaluation, with 14 provider failures (11 timeouts at 30 s, 3 HTTP errors), all handled by labelled fallbacks. Across all its runs: 4,944 calls, about $3.19, median latency 0.9 s, 95th percentile 2.5 s. **Not covered by that precedent:** the midterm called the model from a Python harness using local credentials (Application Default Credentials). The game here would call through a proxy (Godot → Cloud Run → Vertex), and that path is untested. Dialogue replies are longer than the midterm's actions, so latency must be measured again. The export, including the excluded guide folder, is untested. **CI:** the midterm had one (29 tests passed on GitHub); this repo has none. **Fallback:** the Hint button stays, so the game never depends on the model. |
| **Team** | Medium | **Role artifacts:** they exist for Design, Tech, Art and Narrative. QA has test suites only. Producer, BI and Release are planned. **Capacity:** I am the only reviewer for every commit, art fix and gate. |
| **Genre / Mechanics** | Medium | **Built:** the core loop and minigames, covered by regression tests. **Not yet tested:** the graded hints, the guides (Min, the snake, the Ptah-dwarfs), and whether players notice before they act. |
| **Timeline** | High | **Time:** 13 days from G1 to the G2/G3 review (Nov 30, recording Nov 28), including Thanksgiving. Production runs only Dec 1–5 before G4. **Work due:** G2 needs a first playable with its agent, an evaluation, and an external playtest. **Past pace:** most commits came 2026-10-13 to 10-27; November went largely to the midterm (8 commits). |

**How the risks combine.** Technology, Genre/Mechanics and Timeline all depend on one G2 build that carries both the guide module and the chosen level. The cheapest single response is to build the module into a level that is already built, so one experiment tests all three. Timeline is the one High.

## Risk Register

| # | Risk | Evidence or trigger | Impact / likelihood | Role | Mitigation | Contingency | Status / next check |
|---|---|---|---|---|---|---|---|
| 1 | If the G2 build needs a new level as well as the guide module, it won't be ready to playtest before the review. | Nothing playable two weeks before the review | High / High: 13 days to the review, including Thanksgiving; November pace was slow | Producer | Put the module into an already built level for G2; the prototype carries one guide, Min | The G2 build has the module in a built level only; the new level moves to after G3 | Open; check at the Nov 23 working session |
| 2 | If Min or the dwarfs give away answers or invent facts during the trap-question tests, the noticing mechanic is undermined. | The trap-question suite fails, or the log flags a name a role isn't allowed to use | High / Medium: a cheap model; the midterm model ignored rules it had been given (it held heka with no thrust) | Tech Lead, QA | Answers built from fact ids only, a closed list of names, a check for revealing too much, one re-ask, regression cases (Configuration Document Section 4) | Min and the dwarfs use scripted lines only | Open; first evaluation run |
| 3 | If a guide's reply takes over about 3 s, the creatures feel broken. | Logged latency; the midterm's 95th percentile was 2.5 s for short replies | Medium / Medium: dialogue replies are longer, and the proxy adds a network hop | Tech Lead | Minimum thinking, cached prompt prefix, one-line replies, about a 3 s timeout | Show the scripted line straight away; or make the guides scripted only | Open; first end-to-end call |
| 4 | If players can't tell when the snake is wrong, or find its rudeness unpleasant, they'll be frustrated rather than amused. | Players act on a wrong opinion more than once, or say they felt tricked or insulted | Medium / Medium | Design Lead | Its own text colour, correct facts with opinions set apart, a sulky reaction when proven wrong, rudeness aimed at moves, never at the player | It gives opinions less often, its tone is softened, or it is cut | Open; playtest observation |
| 5 | If a level's difficulty is set from my own play, new players will find it too easy or quit. | Playtest: 35, 36 and 39 too easy; spell 32 had no wins in 6 tries | Medium / High: both playtests found this | Design Lead, BI | Tune from playtest numbers (attempts, time, thrusts per kill), not my own runs; at least two players before deciding | Lower the difficulty by default; let the guides comment after repeated failures | Open; each playtest |
| 6 | If the export or the proxy fails on another machine, playtesters can't run the build. | The build fails on a second person's machine | High / Medium: export and proxy are untested | Publishing & Release | Test the export and a run on another machine early; keep a build without the module | Hand playtesters the build without the module | Open; before the first playtest |
| 7 | If the guide folder slips into the release build, the release makes network calls, against GDD Section 13. | The suite without the module fails, or the release export contains `godot/guides/` | Medium / Low | QA | Run the suites with and without the module; check the release build's contents | Remove the folder and re-export | Open; each release build |
| 8 | If spending passes the GCP credits, the guides stop. | The $10 monthly budget alert fires | Low / Low: the midterm spent about $3.19 over 4,944 calls | Tech Lead | 40-call cap per session, a Vertex quota, the proxy can be switched off | The guides become scripted | Open; monthly |
