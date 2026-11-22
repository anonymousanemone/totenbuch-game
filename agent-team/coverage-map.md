# Coverage map

| Role | Covered by | Artifact | Purpose | Tools | Writes | Outputs | Handoffs | Status | Approval boundary |
|---|---|---|---|---|---|---|---|---|---|
| producer | unset | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| design | unset | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| tech | agent | .claude/agents/team-tech.md, .agents/skills/team-tech/SKILL.md | The tech lead makes the game run reliably: systems, the in-game agent's interface, builds, tests, and deployment. | Read, Grep, Glob, Edit, Write, Bash | game code and tests, handoff notes | technical risk per concept; Initial Configuration Document; feasibility and agent boundary; build status; playable build; build to share with a playtester; first playable and traces; integration and deployment check; integration estimate; Update Configuration Document; Alpha and Beta status; fixes to verify; Alpha build; Final Configuration Document; release build; tagged Gold candidate; build notes; engineering section of the AAR | producer, student, qa, release, bi, design, art, narrative | tailored | You recommend; the student decides; the instructor approves gates. You never approve a gate, merge a pull request, or change a deadline. |
| art | unset | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| narrative | agent | .claude/agents/team-narrative.md, .agents/skills/team-narrative/SKILL.md | Narrative and audio roles write the words, characters, and sounds, and fit them to what the systems allow. | Read, Grep, Glob, Edit, Write | new player-visible text and references it adds in registry.json, puzzles.json and messages.json (existing text only on the student's explicit command), Min's scripted lines and voice guide, handoff notes | tone sketches; minimum text and sound list; text, voice guide, and sound cues; feedback notes; content estimate; content list; final text and audio; content defects; game description; narrative notes for the AAR | student, producer, tech, qa, release | tailored | You recommend; the student decides; the instructor approves gates. You never approve a gate, merge a pull request, or change a deadline. |
| qa | agent | .claude/agents/team-qa.md, .agents/skills/team-qa/SKILL.md | QA checks what the game does against what it should do, reproduces failures so someone else can see them, and verifies fixes. | Read, Grep, Glob, Edit, Write, Bash | tests under godot/tests/, handoff notes, QA log lines on Notion rows; never game code, scenes, JSON text or assets | early failure cases; failure cases; reproducible failures; open blockers; defect summary; test plan; verification plan; triaged bug list with severities; triaged bugs; bug counts by severity; release check results; verified-fix record; QA notes for the AAR | producer, student, tech | tailored | You recommend; the student decides; the instructor approves gates. You never approve a gate, merge a pull request, or change a deadline. |
| bi | unset | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |
| release | unset | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |

Warnings:

- other-roles.md: producer is empty; write student, not needed, <reason>, or agent <path>
- other-roles.md: design is empty; write student, not needed, <reason>, or agent <path>
- other-roles.md: art is empty; write student, not needed, <reason>, or agent <path>
- other-roles.md: bi is empty; write student, not needed, <reason>, or agent <path>
- other-roles.md: release is empty; write student, not needed, <reason>, or agent <path>

Agents: 3 of 3 by G4. Origin notes: 1 of 1 by G4.
