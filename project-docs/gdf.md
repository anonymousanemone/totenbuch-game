# A Student Reader and Guide to the Game Development Framework

**Version 2.1, November 10, 2026**

*AI in Practice: Game Design and Development*

## How to use this reader

You have an idea for a game. Before long, you will have several versions of that idea, a partly working build, more tasks than time, and observations that challenge your assumptions. The Game Development Framework (GDF) helps you decide what to pursue, what to change, and when the evidence supports a larger commitment.

Read Parts I and II for the purpose and origins of the framework. Part III explains its vocabulary, roles, working rhythm, and risks. Part IV follows a game through the five gates. Part V gives you templates to adapt to your actual project. Parts VI and VII offer discussion questions and a glossary.

**Course authority.** The [published syllabus](https://courseworks2.columbia.edu/courses/258228/assignments/syllabus) governs assessment, dates, submission formats, and course requirements. This reader explains those requirements using the syllabus revised November 9, 2026; its examples add no required features, tools, meetings, or submissions. Check the current syllabus when preparing a gate.

**The running example.** *Signal Station* is an invented game used throughout this reader. Its design changes, playtests, and results are fictional teaching examples. They show how to reason about a project; they make no claims about a commercial game's development history.

## The project at a glance

![Horizontal GDF timeline: ideation and concept to G1; prototyping to G2; production planning to G3; production, including Alpha, Beta, and Gold, to G4; release and reflection to G5. The instructor approves gates.](assets/gdf-timeline-v2.svg)

The timeline shows the sequence, with phase lengths drawn for readability. G2 and G3 share a course review while retaining separate decisions. Section 3.1 supplies the decision and next commitment at each gate. Alpha, Beta, and Gold are milestones within Production.

## Part I: Why frameworks exist

### 1.1 A game is a set of connected decisions

Suppose you want players to feel the pleasure of figuring something out. You imagine a damaged research station, strange signals, and a helpful archivist. You could make an exploration game, a deduction puzzle, or a story about the station's missing crew. Each direction suggests different mechanics, assets, engineering work, and tests.

Choosing an engine answers one question. Choosing how the player discovers a clue answers another. Choosing whether an AI archivist may reveal that clue answers several more: what the character knows, how the game protects hidden information, how long a response can take, and what happens when the service fails.

These decisions affect each other. A producer needs enough design detail to estimate the work. A designer needs a playable experiment to judge the mechanic. An engineer needs a clear state model to implement it. An artist needs to know what players must recognize. Someone must decide which recommendations to accept.

The GDF gives this work a shared structure. You develop an idea through phases, gather evidence, and review it at gates before committing further resources. Resources include your attention, development time, model budget, and the time of people who playtest or review your game.

### 1.2 Phases, gates, milestones, and deliverables

A **phase** is a period of work with a particular purpose. During prototyping, you investigate uncertainties. During production, you build and integrate the agreed game.

A **gate** is a decision about whether and how to proceed. The work leading to a gate supplies the evidence for that decision. Approval records what has been accepted and what work is authorized next.

A **milestone** is an identifiable state of the project or build. Alpha, Beta, and Gold describe progress toward release. A milestone may involve a demonstration, review, or acceptance check. In this course, those milestones sit inside Production and do not add formal gates to G1 through G5.

A **deliverable** is an artifact someone can inspect: a pitch, playable build, plan, configuration, test report, or retrospective. Its value comes from what it makes understandable or verifiable. A document saying that the game works is weaker evidence than a reproducible build and the results of testing it.

You can revise a design within a phase and revisit an earlier assumption. When a change affects an approved scope, budget, or release, record it and seek the approval appropriate to that commitment.

### 1.3 Output and outcome

An output is something you produce. An outcome is what happens because of it.

For *Signal Station*, a clue panel is an output. A player using the clue to form and test an explanation is an intended outcome. A hint agent is an output. A player receiving useful help while retaining the satisfaction of discovery is an intended outcome.

The difference changes your questions. Alongside “Did we implement the panel?” ask “Could the player read it, understand its relevance, and act on it?” Alongside “Did the model answer?” ask “Was the answer grounded, timely, within budget, and appropriate to this player's knowledge?”

Gate approval means the evidence supports a particular next commitment. You will still need judgment, iteration, and further observation.

## Part II: Where this GDF comes from

The source collection contains frameworks and working materials from EA, Disney, Amber, and related studio contexts. These materials share concerns about creative direction, feasibility, player evidence, risk, coordination, and approval. They organize those concerns differently.

EA's GDF 2.0 describes seven phases and five gates. Its first and third gates include concept and production greenlights; its fourth gate approves Alpha, and its fifth concerns release readiness. Disney's global framework includes six gates, including an Alpha executive review. Amber's framework distinguishes prototype, vertical slice, soft launch, hard launch, and live operations. Its market-validation questions reflect the products and release conditions it addresses.

**The five gates in this reader are a course adaptation.** They preserve the practice of making commitments through evidence while fitting a short studio project. G4 combines the course's final release-readiness decision. G5 makes reflection and closure an explicit course gate. Alpha, Beta, and Gold remain build milestones. A commercial studio may place or name these decisions differently.

The four recurring questions in Section 3.2 come directly from the EA GDF 2.0 approach. Sprint practices, templates, and risk tools draw from the collection and the original course reader. Their application here follows the course's individual-project and agent-team model. Source notes appear at the end of this reader.

Learn one set of names for this course. When you encounter another studio's framework, compare the purpose, evidence, authority, and commitment behind each name.

## Part III: The framework

### 3.1 Five gates and the work between them

| Work leading to the gate | Gate | Decision | Work authorized by approval |
|---|---|---|---|
| Ideation and concept development | **G1 Concept** | Is this a clear, worthwhile, achievable idea to investigate? | Prototype the proposed experience and address its main uncertainties. |
| Prototyping and player observation | **G2 Prototype** | Does the core experience have enough support to develop further? | Refine the experience and resolve production-planning questions. |
| Production planning and feasibility checks | **G3 Production** | Can the agreed game be completed with the resources remaining? | Produce the game against the approved scope and plan. |
| Production, integration, testing, and release preparation | **G4 Final / Pre-Launch Review** | Is this specific build ready to release? | Release or showcase the approved Gold build. |
| Release, showcase, feedback, and reflection | **G5 Retrospective / Closure** | What happened, what was learned, and is the project ready to archive? | Close and hand off the project with usable evidence and lessons. |

In the current course calendar, G2 and G3 share a review. They still answer separate questions. A compelling prototype may need a smaller production plan. A tidy schedule may rest on an unconvincing prototype. Show evidence for both decisions.

Inside Production, use these milestone definitions consistently:

- **Alpha:** all agreed features are implemented and integrated sufficiently to exercise them. Record incomplete content, defects, and quality gaps.
- **Beta:** planned release content is complete and locked; work concentrates on verification, balance, usability, polish, and fixes.
- **Gold / RTM:** the identified release candidate meets the release criteria and is approved at G4. Preserve the approved tag.

These definitions describe different kinds of readiness. Feature completion alone does not establish release quality. Use the syllabus for the milestone dates and the corrective-release policy after G4.

### 3.2 The Four Critical Questions

At each gate, answer four questions with evidence appropriate to the decision:

1. **Opportunity:** What experience are we offering, to whom, and why is it worth pursuing?
2. **Execution:** What have we demonstrated, and how will we complete the next work?
3. **Risks and Mitigations:** What could prevent success, how would we detect it, and what will we do?
4. **Alignment:** Do the design, implementation, plan, and people responsible describe the same project?

For *Signal Station* at G1, Opportunity is the pleasure of connecting clues. At G2, it includes whether observed players actually connect them. Execution moves from a proposed method to a working loop. Alignment includes whether the archivist's configured knowledge agrees with the GDD's information boundaries.

A useful answer names its limits: “One player used the clue correctly after we changed the labels; we have not yet tested the revised encounter.” Keep observations, interpretations, and remaining questions distinct.

### 3.3 Roles, accountability, and handoffs

In this course, projects are individual: the final, like the midterm, is yours to direct. You remain **Executive Producer** and **Creative Director**. As Executive Producer, you accept responsibility for priorities, resources, commitments, and delivery. As Creative Director, you choose the intended experience, resolve competing design recommendations, and accept the creative result. The **instructor is Gate Approver**. Peers contribute Braintrust feedback and playtest observations.

Your production agents perform delegated work in development roles. You retain accountability for each deliverable's Owner role. An agent can recommend a scope cut or prepare gate evidence; you decide what to propose, and the instructor makes the gate decision.

| Development role | Main contribution | Typical output and recipient |
|---|---|---|
| **Producer** | Connect scope, capacity, dependencies, risks, and decisions. | A feasible plan and prioritized tasks for the student and role agents. |
| **Design Lead** | Specify actions, rules, progression, balance, and intended player experience. | A design specification and playtest questions for engineering, art, and QA. |
| **Tech Lead** | Implement reliable game systems, agent interfaces, builds, and deployment. | A runnable build, technical decisions, and test evidence for QA and release. |
| **Art Lead** | Establish visual direction, readability, and a practical asset pipeline. | Visual specifications and assets for implementation and review. |
| **Narrative and Audio roles** | Develop the project's writing, character expression, sound, and their integration. | Bounded content and implementation guidance for design and engineering. |
| **QA** | Check behavior, reproduce failures, verify fixes, and preserve evidence. | Reproducible reports and release checks for engineering and the student. |
| **Business Intelligence (BI)** | Organize and interpret relevant player and performance evidence. | Measurements with limitations for design, production, and the student. |
| **Publishing and Release** | Make the game understandable, accessible to its intended players, and reproducible at release. | Release instructions, presentation materials, and archive checks for the student. |

These are responsibilities to cover, scaled to your game. A small game can use a modest visual style, a small sound vocabulary, and little narrative. Your agent team grows from evidence: you start with the implementation agent and independent reviewer from your midterm, and add an agent when you have hit the same friction twice, with an **origin note** linking those two dated moments. The role-coverage map gives every role one line: the agent that covers it, "I do this myself," or "not needed, because...". The syllabus sets the minimum at each gate. Shared models are allowed. A job title counts as an agent only with an executable configuration and evidence of use.

A **handoff** tells the recipient what to use, what to produce, and how acceptance will be judged. For example:

> Design Lead to Tech Lead: “Implement a clue notebook containing only facts the player has discovered. The archivist receives that notebook and the player's question. It may paraphrase those facts. The game validates any proposed state change. Include an undiscovered-clue test and a forced-timeout test.”

The Tech Lead returns a build and evidence. QA checks the behavior independently. You decide whether it serves the intended discovery experience. The Producer updates the plan if it needs more work.

Keep **production agents** distinct from **in-game agents**. A coding agent may need repository access; the archivist needs a bounded view of the current play session. Specify tools, knowledge, memory, prohibited actions, evaluation, and human approval boundaries for each.

### 3.4 Work cycles, scope protection, and coordination

Choose a work cycle that fits the remaining time and the published milestones. Two-week sprints are a useful reference from the source collection; the compressed final-project calendar also needs shorter commitments. The outcome of planning is a clear goal, a feasible set of tasks, and acceptance criteria.

Protect committed work from casual additions. Put new ideas in the backlog and compare them at the next planning point. When a defect, failed assumption, or access problem makes the commitment unworkable, record the change, its reason, and its effect. Seek instructor approval when it changes a gate commitment. Scope protection should support responsible decisions as evidence changes.

Use the course's **Notion tracker template** for coordination from G2 on (your G1 plan can be a simple document; Asana or another tracker with the same fields also works): tasks, student Owner and GDF role, acceptance criteria, dependencies, risks, and weekly **PPP (Progress / Plans / Problems)**. Gate decisions go in the "Gate decisions" issue of your final repository, `final-<github-login>`. Use **GitHub** for code, PRs, CI, and releases. Link the relevant evidence between them. CourseWorks holds submissions, grades, and private feedback according to the syllabus.

A task such as “improve hints” leaves acceptance uncertain. “When the service times out, display the scripted hint, preserve the turn state, and record the fallback in the trace” gives implementation and review a shared target.

Review the build against the work-cycle goal. Record what changed in your understanding and what the next cycle will accomplish. Use Section 5.5 for a compact plan and PPP.

### 3.5 The six-dimension Risk Profile

A Risk Profile summarizes where the project's uncertainty is concentrated. Rate each dimension Low, Medium, or High, and explain the rating using your project's evidence. Revisit it as evidence changes, especially when pitching and locking scope.

| Dimension | Questions to ask |
|---|---|
| **IP / Concept** | Is the concept clear? Are reference, attribution, and reuse terms understood? What is unproven about the proposed experience? |
| **Business / Audience** | Who is this for? What evidence supports that choice? Can you reach appropriate playtesters? |
| **Technology** | Which tools, services, deployment paths, or model behaviors remain unverified? |
| **Team** | Can your configured agents perform the delegated work? Are handoffs, review, and your own capacity adequate? |
| **Genre / Mechanics** | Which interactions have you tested? Which relationships among rules remain speculative? |
| **Timeline** | What must happen before other work can begin? What capacity and buffer remain? |

A High rating identifies an important uncertainty. Your response may be an experiment, a smaller scope, a fallback, or a different approach. Counting High ratings is less useful than understanding whether their causes compound. A novel mechanic, unfamiliar engine, and short schedule can all depend on the same unproven prototype.

For *Signal Station*, “the model may reveal an undiscovered clue” becomes actionable when the risk has an owner, a test, a mitigation, and a contingency. Restrict its context, test attempts to obtain hidden information, and retain a scripted hint path if the model behavior is inadequate. Section 5.4 tracks specific risks over time.

## Part IV: Gate-by-gate playbook

The activities below take place **before** the gate. The review considers their results. Each review ends with a recorded decision identifying the evidence reviewed, approved scope or build, conditions, and next work. The instructor approves course gates; Braintrust recommendations inform that decision.

The course uses recordings and selected live presentations, as specified in the syllabus. The playbooks describe the content of a review rather than prescribing an additional meeting or a separate presentation for every student.

### Before G1: Ideation and concept development

Begin with an experience you want to offer. A player motivation can help you formulate it: discovering an explanation, mastering a skill, expressing an idea, connecting with others, or relaxing through a familiar routine. The Motivation Atlas offers eleven groups to explore. A game may address several, and players may respond differently to the same mechanic.

Treat your intended motivation as a hypothesis. “Players will feel curious” becomes more useful when connected to behavior you can observe: “Players will compare two conflicting records and choose to investigate the discrepancy.”

Explore several concepts before committing. Genre supplies a vocabulary of expectations, interactions, and production demands. Choosing a deduction game suggests a different design and testing problem from choosing a competitive action game. Examine specific moments in reference games and explain what you want to learn from them. Record attribution and reuse terms when adapting existing work.

For *Signal Station*, the student considers a repair simulation, a branching conversation, and a deduction puzzle. The student chooses deduction because connecting evidence is the intended pleasure. The concept becomes:

> *Signal Station is a short deduction game in which you restore a damaged relay by comparing station records and testing an explanation, with an AI archivist that discusses only evidence you have discovered.*

This is the **X**, a one-sentence statement of the game. It gives later decisions a reference point. It can improve as you learn.

Your sixty-second pitch from the first pitch round on November 9 is an early draft of this work. Its X, player and motivation, core loop, and agent lines carry into the Creative Pitch in Section 5.1, together with the notes you heard.

### Gate 1: Concept

**Decision question:** Is this idea sufficiently clear and achievable to justify prototype work?

**Work before the review.** Define the intended player, experience, core loop, references, and boundaries. Identify the largest design and technical uncertainties. Decide what the in-game agent contributes and what a scripted baseline will do. Sketch the systems and information boundaries. Estimate time, model latency, and cost, and establish the Initial plan, Risk Register, GDD, and Configuration Document.

**Evidence for the review.** Bring the pitch and recording required by the syllabus, the X, core loop, references and attribution, systems diagram, six-dimension Risk Profile with mitigations, Initial project plan in any format (it moves to your tracker after G1), and Initial GDD and Configuration Document. State the AI design hypothesis, scripted baseline, playtest question, and latency/cost budgets. Initial documents should make the proposal inspectable while keeping open questions visible.

**Roles and handoffs.** The Design Lead proposes the loop and test question. The Tech Lead identifies a feasible implementation and agent boundary. The Art Lead, Narrative and Audio roles identify the minimum presentation needed to communicate the experience. QA proposes failure cases; BI helps define observations and measures. Publishing and Release identifies how players will access the game. The Producer combines these recommendations into a plan. You choose the concept and commitments to put before the instructor.

**Signal Station at G1.** The intended loop is inspect a record, compare facts, test a relay setting, and interpret the response. The hypothesis is that grounded conversation can help players connect discovered facts while preserving deduction. The proposed scope is one station, one bounded puzzle, and one archivist. Procedural stations and free-form world-changing dialogue go on the exclusions list. The first experiment tests whether players can understand the clue relationship with a scripted hint before adding model variation.

**Decision and next commitment.** Approval authorizes the agreed prototype investigation. A Hold identifies what must be clarified or reduced. At G1 the instructor posts the decision and conditions as a comment on your CourseWorks submission; from G2 on, decisions go in your final repository's "Gate decisions" issue. Section 5.1 helps organize the pitch.

### Gate 2: Prototype

**Decision question:** What evidence supports the core experience, including the agent's contribution?

A **prototype** is built to investigate an uncertainty. It can use rough visuals, placeholder content, paper, or a small executable experiment, provided the form can answer the question. The course's G2 submission requires a first playable with its agent and the evidence specified in the syllabus.

A **vertical slice** is a representative portion of the intended game that also tests how its systems, content, and production methods fit together. In the source frameworks it can be a distinct commitment. Give your own experiment the quality needed to test its question. Reserve production polish for evidence that requires it.

**Work before the review.** Implement the core interaction and bounded agent behavior. Run deterministic checks and budgeted live evaluation. Observe an external player using the loop. Separate what happened from your explanation of why it happened. Revise where time permits, and record unresolved questions.

**Evidence for the review.** Bring the first playable and recording, Initial Playtest Log, Update GDD and Configuration Document, updated plan and Risk Register, and the relevant implementation and evaluation evidence. In the current combined G2/G3 review, observe at least one external player using the core loop. A successful API call alone leaves the player's experience untested.

**Roles and handoffs.** The Design Lead defines what the experiment should reveal. The Tech Lead supplies the playable build and traces. Art, Narrative, and Audio provide enough readability and feedback for a fair test. QA checks behavior and preserves reproducible failures. BI organizes observations and performance measures without overstating a small sample. Publishing and Release checks that a playtester can reach and run the build. The Producer updates remaining work; you decide what the findings mean for the concept.

**Signal Station at G2.** In the fictional test, a player repeatedly switches relays without reading the records. The student first suspects the puzzle is too hard. Observation shows that the records look decorative. After improving their visual hierarchy, the player compares them and explains a hypothesis. Separately, the archivist gives away the answer in a test prompt. The student restricts the facts it receives and adds a regression case. These are two different findings, requiring different changes.

**Decision and next commitment.** Approval supports further refinement and production planning. A Hold names the unsupported assumption or failure to address. G2 does not itself lock the full production scope. In a combined review, the instructor can consider G3 immediately using the separate planning evidence.

### Gate 3: Production

**Decision question:** Can you complete the agreed game with the time and resources remaining?

**Work before the review.** Convert the demonstrated experience into a feasible production plan. Identify dependencies, asset and content work, agent-role coverage, tests, release preparation, and your capacity to review it all. Define Alpha, Beta, and Gold acceptance checks. Include time to observe players, fix problems, rerun evaluation, and prepare a reproducible release.

Decide what stays in scope, what is excluded, and what can be reduced if a risk materializes. A fallback requires a trigger and a concrete action. “Cut something if late” leaves the difficult decision until the project is already late.

**Evidence for the review.** Bring the scope-lock plan, exclusions, updated Risk Register, Update GDD and Configuration Document, and links to the prototype evidence. The Project Plan becomes Final at G3: the approved baseline for production. The GDD and Configuration Document remain Update; their Final versions at G4 will describe the release implementation.

**Roles and handoffs.** The Producer exposes capacity, dependencies, and contingencies. The Tech Lead checks the integration and deployment path. Design, Art, Narrative, and Audio estimate the remaining work at the agreed quality. QA and BI specify verification and player-evidence needs. Publishing and Release reserves time for packaging and instructions. You reconcile competing recommendations and propose the scope; the instructor approves it.

**Signal Station at G3.** The student wants three station areas but has demonstrated only one encounter. The Producer's estimate leaves no time for release testing. The student proposes one complete area, a readable notebook, one archivist, and a reliable ending. Additional areas are excluded. If the archivist repeatedly violates its knowledge boundary, the plan calls for a smaller validated response interface and instructor review of any material scope change.

**Decision and next commitment.** Approval authorizes production against the recorded scope. If the experience is promising but the plan is infeasible, reduce scope and obtain the required approval. Record later baseline changes with their cause, impact, and decision.

### Gate 4: Final / Pre-Launch Review

**Decision question:** Is this identified build ready for release or showcase?

**Work before the review.** Complete and integrate the approved features, reach Alpha, finish and lock content at Beta, and verify the release candidate. Observe an external release playtest after Alpha and before the Gold recording. Triage findings and verify fixes. Complete budgeted live evaluation, release documentation, and the final configuration record.

Across the course's G2-to-G4 window, use at least two distinct external players. Between the combined G2/G3 review and G4, test a revised encounter with an external player and link a finding to a change. The syllabus supplies the exact timing and submission requirements.

Classify problems by their consequences. A broken ending or leaked hidden state may block release. A minor presentation defect may be accepted with a recorded explanation. Name the affected build, reproduction steps, owner, and verification result.

**Evidence for the review.** Bring the Gold candidate and recording, Final GDD and Configuration Document, evaluation harness and results, Update Playtest Log and Risk Register, release instructions, and evidence that triaged fixes work. Show every development role accounted for in the coverage map. Identify any accepted defects and the deterministic fallback. The release should be runnable by another person following its instructions.

**Roles and handoffs.** The Tech Lead identifies the exact build and configuration. QA verifies fixes and release checks. BI summarizes outcomes, failures, latency, cost, and the limits of the evidence. Design checks the intended experience; Art, Narrative, and Audio check integrated readability and consistency. Publishing and Release verifies packaging and player instructions. The Producer assembles readiness evidence. You accept the proposed release and disclose unresolved issues; the instructor approves Gold.

**Signal Station at G4.** The fictional release test finds that a model timeout leaves the hint control disabled. QA reproduces it, the Tech Lead repairs the recovery path, and QA verifies it with a forced timeout. The student keeps a minor animation defect on the accepted-issues list. The final report records the tested model/configuration, including unavailable or failed runs, rather than displaying only successful conversations.

**Decision and next commitment.** Approval applies to the identified Gold build. Preserve its tag. After G4, corrective releases require recorded patches, tests, and instructor approval linked from your repository's "Gate decisions" issue. Keep approved Gold reproducible while making any authorized corrective release separately identifiable.

### Gate 5: Retrospective / Closure

**Decision question:** What does the finished project teach, and can someone understand and use its archive?

**Work before the review.** Release or showcase the approved game, collect feedback, complete the Playtest Log, and compare the result with the original intentions. Play the three assigned classmates' builds. Review the decisions, failures, changes, and agent handoffs across the project. Prepare the AAR and archive.

**Evidence for the review.** Bring the final game and AAR, Final Playtest Log, project archive, and the showcase evidence specified in the syllabus. Follow the draft-sharing and Braintrust schedule; G5 requires no additional recording. The Engineering & Design Retrospective and capstone presentation follow at Finals, as specified separately in the syllabus.

**Roles and handoffs.** Each role contributes its evidence and explains what it would change. The Producer organizes the history; QA and BI distinguish observed results from claims; Publishing and Release checks the archive. You account for the full agent team, including the decisions you retained as Executive Producer and Creative Director. The instructor reviews closure.

**Signal Station at G5.** The student finds that clue presentation mattered more than adding conversational variety. The AAR traces the original assumption, observations, design change, and later result. It also records that the smaller scope left time to repair the timeout failure. Future work proposes another encounter and states what the next experiment would test. The archive lets a future reader locate both the approved build and the evidence behind these conclusions.

An honest AAR can describe a successful decision in an imperfect game or a weak decision in a well-received one. Explain causes and uncertainty with the evidence you have.

## Part V: Templates you can use

Use these structures inside the artifacts and tools required by the syllabus. A linked task, test report, or diagram can supply evidence for several questions. Keep a clear current version rather than copying the same information into several documents that drift apart.

### 5.1 Creative Pitch (G1)

**Purpose:** make the proposed experience, investigation, and commitment clear.

**Accountable Owner:** you, as Creative Director. **Gate Approver:** instructor.

- **The X:** Our game is [one sentence describing player action and intended experience].
- **Player and motivation:** We are designing for [player/context], with the intended experience of [experience].
- **Core loop:** The player [acts]; the game [responds]; the player [interprets/chooses], leading to [next action].
- **Pillars:** [A small set of priorities you can use to choose among designs.]
- **References and attribution:** [Specific moments, mechanics, assets, or code; what you borrow or change; applicable terms.]
- **Agent hypothesis:** We expect [bounded agent behavior] to affect [player experience], compared with [scripted baseline]. We will investigate by [test].
- **Systems and boundaries:** [Diagram of state, player input, agent context/actions, validation, and feedback.]
- **Scope:** [Included experience], [explicit exclusions], and [what you would reduce first].
- **Feasibility:** [Initial plan, Risk Profile, key mitigations, latency/cost budgets, and links to Initial GDD/configuration.]
- **Decision requested:** [What prototype work you seek approval to undertake.]

### 5.2 Game Design Document and Configuration Document

**Purpose:** keep intended behavior and executable delegation understandable together.

**Accountable Owner:** you in the relevant Design Lead and Tech Lead roles, retaining Creative Director approval. **Gate Approver:** instructor.

The **GDD** describes the game: player, genre, platform, loop, mechanics, dynamics, intended aesthetics, progression, scoring, win/failure conditions, edge cases, balance, controls, feedback, content scope, references, and open questions. Include the information a person needs to understand a valid play session.

The **Configuration Document** describes agent behavior and production-role coverage: purpose, tools, permissions and prohibited actions, named context sources, knowledge boundaries, memory policy, models/settings, prompts or system instructions, failure modes, evaluations, logging, human override, timeout/retry/spending limits, fallback, configuration versions, and executable artifact locations. Include test commands and CI workflow paths.

For each production role, record **role; executable artifact; purpose; context; tools/permissions; outputs; recipient and handoff; evaluation; human approval boundary**. For in-game agents, explain the distinction between world state and the information available to that agent.

At least one agent must ship as the executable extension artifact required by the syllabus, such as a skill, plugin, tool bundle, MCP server, function-calling interface, or platform equivalent. Its common manifest retains the syllabus's required fields and may refer to native configuration files.

Keep both documents **Initial at G1, Update at G2/G3, and Final at G4**. Label unresolved questions, implemented behavior, and verified behavior so a reader can distinguish them.

### 5.3 Art Direction Peer Review

**Purpose:** determine whether presentation supports the intended interaction.

**Accountable Owner:** you in the Art Lead role; obtain peer observations where useful.

This is a working aid for reviewing relevant visual and audio choices. It adds no separate course submission.

| Aspect | Observation in the identified build | Judgment: Pass / Fail / CBB / N/A | Proposed action |
|---|---|---|---|
| Visual hierarchy and readable clues | | | |
| UI feedback and accessible distinctions | | | |
| Consistency of style | | | |
| Animation and motion | | | |
| Lighting, mood, and contrast | | | |
| Audio meaning and fit | | | |

**CBB** means “could be better.” Specify what improvement would help and whether it affects release readiness. Explain how you judged accessibility or usability; use direct observations and checks rather than assuming a stylistic choice works for everyone.

### 5.4 Risk Register

**Purpose:** track particular uncertainties and their responses.

**Accountable Owner:** you in the Producer role, with a responsible role on each risk.

| Risk | Evidence or trigger | Impact and likelihood | Responsible role | Mitigation | Contingency | Status and next check |
|---|---|---|---|---|---|---|
| If [condition] persists by [decision point], then [consequence]. | [How you will detect it.] | [Ratings with reasons.] | | [Reduce likelihood/impact.] | [Response if it occurs.] | |

For example: “If the archivist exposes undiscovered facts in the adversarial suite before scope lock, the discovery mechanic is at risk.” Restrict context, test the revised interface, and specify what smaller behavior you will propose if the failure remains. Keep the Risk Register updated through G4 and archive it with the task and gate history at G5.

### 5.5 Work-Cycle Plan and PPP

**Purpose:** connect the next commitment to inspectable results.

**Accountable Owner:** you in the Producer role.

**Goal:** By [next checkpoint], a player will be able to [observable capability], and we will know [question answered].

| Task/outcome | Student Owner and delegated role | Dependencies | Estimate | Acceptance criteria | PR/test evidence |
|---|---|---|---|---|---|
| | | | | | |

**Scope changes:** [What changed, why, effect on capacity/quality, and any approval required.]

In weekly PPP, record:

- **Progress:** completed outcomes and links to evidence.
- **Plans:** next outcomes, dependencies, and capacity.
- **Problems:** blockers, risks, and the decision or help needed.

The Project Plan is Initial at G1, Update at G2, and Final at G3 scope lock. Later changes are recorded against that approved baseline.

### 5.6 Gate Review Evidence and Decision Record

**Purpose:** make the review decision assessable and traceable.

**Accountable Owner:** you, with the Producer coordinating evidence. **Gate Approver:** instructor.

Organize the pitch, recording, or review around the question at that gate:

1. Project, gate, date, build/configuration identifiers, and decision requested.
2. Key changes since the previous review.
3. The X, intended experience, and current scope.
4. Relevant demonstration and player/evaluation evidence, including failures and limits.
5. The Four Critical Questions: Opportunity, Execution, Risks and Mitigations, Alignment.
6. Remaining work, dependencies, exclusions, and proposed next commitment.
7. Links to the required artifacts and reproducible evidence.

In your repository's "Gate decisions" issue, keep the **instructor's decision**, reviewed versions, approved scope/build, conditions, corrective work, and follow-up. Mark your own proposal as a proposal until the decision is made. A Hold specifies the work needed for reconsideration.

### 5.7 After-Action Review (G5)

**Purpose:** explain the project's results and preserve useful lessons.

**Accountable Owner:** you, with the Producer assembling contributions from the full agent team. **Gate Approver:** instructor.

Retain these six sections, which the syllabus uses:

1. **Process:** planning, work cycles, scope decisions, gates, and revisions.
2. **Production:** design, code, art, narrative, audio, and integration pipelines.
3. **Team & Communication:** delegation, role coverage, handoffs, independent review, and your retained human decisions.
4. **Tech & Tools:** engine, builds, source control, deployment, models, configuration, and service dependencies.
5. **Playtesting & QA:** hypotheses, observation, evaluation, failures, fixes, verification, and showcase feedback.
6. **Top Three lessons:** the three findings most useful to a future project, with the conditions under which each applies.

For each of the first five sections, explain **what went right, what went wrong, and what was learned**. Use a specific event, its consequence, and supporting evidence. Account for the agent team's contributions and the decisions you made as Executive Producer and Creative Director.

“We should have tested earlier” becomes useful when you explain which assumption persisted, when evidence became available, what the delay cost, and what earlier test would have exposed it. Distinguish a plausible explanation from a cause your evidence establishes.

The later Engineering & Design Retrospective develops this analysis with the research, appendix, recorded walkthrough, and presentation required by the syllabus.

### 5.8 Deliverable and Gate Matrix

This matrix summarizes the current course sequence. The published syllabus specifies the complete submission requirements. G2 and G3 share a review, but retain their separate decisions.

| Artifact | Student's accountable role | G1 | G2 | G3 | G4 | G5 |
|---|---|---|---|---|---|---|
| Pitch and concept | Creative Director | Concept for approval | Revise as needed | Match locked scope | Match release | Reflect on changes |
| GDD and Configuration Document, including role coverage | Design Lead / Tech Lead | Initial | Update | Update | Final | Archive |
| Project Plan (in your tracker from G2) | Producer | Initial | Update | Final baseline | Record changes | Archive |
| Risk Register | Producer | Initial | Update | Update | Update | Archive |
| Tasks and weekly PPP | Producer | Maintain | Maintain | Maintain | Maintain | Archive history |
| Playtest Log | Design Lead / QA / BI | Test question | Initial | Same log at combined review | Update | Final |
| Harness and evaluation evidence | Tech Lead / QA | Proposed tests and baseline | Working evidence | Link feasibility evidence | Release evidence | Archive |
| Game build | Tech Lead | Concept evidence | First playable | Demonstrated basis for scope | Gold for approval | Final game/archive |
| AAR | Producer, with all roles | | | | | Final |

**Initial** means a usable first version with open questions visible. **Update** means a revision reflecting current evidence and decisions. **Final** means the version accepted for that commitment. When later changes are permitted, record a new revision and its approval while preserving the accepted baseline. A Final GDD at G4 describes the release implementation; a Final Project Plan at G3 establishes the production commitment.

### 5.9 Playtest and Evaluation Record

**Purpose:** make findings interpretable and connect them to decisions.

**Accountable Owner:** you in the Design Lead, QA, and BI roles.

For a human playtest, record **question; consent and anonymous participant identifier; build/configuration; procedure; observations; interpretation and uncertainty; change; verification; remaining questions**. Record what the player did and said before interpreting it. If you coached the player, note when and how that affected the session.

For an agent evaluation, record **case/suite; model/settings and configuration; permitted information/actions; baseline; trial and spending bounds; outcomes; invalid actions; latency/cost; unavailable or failed runs; traces; resulting decision**. Use deterministic tests for rules and invariants and bounded live trials for current model behavior. A replay is evidence of a recorded run; current live performance requires current live evidence. Validate any model-grading rubric against human judgment.

Human observations and automated checks answer different questions. A passing state-invariant test establishes something about rule integrity. It leaves the question of whether the player found the encounter engaging to player evidence and design judgment.

## Part VI: Discussion sets

Use these questions to examine a decision in your own project or in the fictional example. They are prompts for discussion, rather than additional submissions.

1. **Motivation and evidence.** What would a curious player do in your game? Which behavior could have several explanations? What observation would challenge your intended experience?
2. **Prototype and commitment.** What is the cheapest credible experiment for your largest uncertainty? What would justify making a representative slice afterward?
3. **Roles and authority.** An agent recommends a feature that improves one encounter but threatens the schedule. Which roles should contribute evidence? Which decision belongs to you, and which commitment needs instructor approval?
4. **The combined G2/G3 review.** Describe a project that should pass the prototype decision but receive a Hold on production. What evidence would resolve the Hold?
5. **Risk and scope.** Which excluded feature most protects your ability to finish? Under what condition would you reconsider it in a future project?
6. **Release and reflection.** Which known defect could you responsibly accept? Which would block your release? What evidence would let a later reader assess your judgment?

## Part VII: Glossary

- **AAR (After-Action Review):** the six-part account of results and lessons reviewed at G5; see Section 5.7.
- **Alpha:** the Production milestone at which agreed features are implemented and integrated sufficiently to exercise them; quality gaps remain visible.
- **Approver:** the person authorized to accept a commitment. The instructor approves course gates.
- **Baseline:** an identified, accepted version of a plan, document, configuration, or build against which changes can be tracked.
- **Beta:** the Production milestone with release content complete and locked, focusing remaining work on verification, polish, and fixes.
- **Braintrust:** peers' candid, specific feedback to help you understand the work and improve your decisions.
- **CBB:** “could be better,” a review judgment that needs a stated consequence and priority.
- **Configuration Document:** the record of agents' executable configurations, context, permissions, evaluations, handoffs, and human approval boundaries.
- **Core loop:** a recurring relationship among player actions, game responses, and subsequent choices. Its duration and rewards depend on the game.
- **Deliverable:** an inspectable artifact supporting a decision or handoff.
- **Executive Producer / Creative Director:** your retained responsibility for resources and commitments / creative direction and acceptance.
- **Fallback:** a specified behavior used when the preferred path fails or is unavailable, with a defined trigger and verified result.
- **Gate:** a formal decision about whether and how the project proceeds.
- **GDD (Game Design Document):** the description of the game's intended and implemented experience, rules, content, and behavior.
- **Gold / RTM:** the identified release build approved at G4. RTM is a release label inherited from “release to manufacturing.”
- **Greenlight:** approval to make the specified next commitment of resources.
- **Handoff:** the transfer of work with context, expected output, acceptance criteria, and responsibility clear.
- **Milestone:** an identifiable project or build state, which may involve checks or review.
- **Owner:** the accountable person for an artifact or outcome. You retain human accountability when delegating execution to agents.
- **Phase:** a period of work organized around a purpose.
- **PPP:** Progress / Plans / Problems, the weekly coordination record.
- **Prototype:** an experiment designed to investigate a particular uncertainty.
- **Risk Profile / Risk Register:** a summary of uncertainty across six dimensions / the tracked specific risks, responses, and status.
- **Scope lock:** the approved production baseline at G3, with later changes recorded and approved as appropriate.
- **Vertical slice:** a representative portion of the intended game used to assess the integrated experience and production approach.
- **The X:** the one-sentence statement of the game used to align decisions.

## Source notes and adaptation choices

This reader draws on the instructor's `game-dev-frameworks` collection and the original course reader. The following notes identify the principal sources for the explanations above. Studio materials are historical examples; their labels, counts, timing, and product assumptions should be interpreted in their own contexts.

The original course-materials PDF is preserved in the instructor's reference library. For current course application, use the [published syllabus](https://courseworks2.columbia.edu/courses/258228/assignments/syllabus), particularly its Final assignment, presentations, playtests, and GDF decisions. The syllabus also describes the course's retained human leadership and the agent team you build from evidence. The local Motivation Atlas supplies optional examples and the eleven motivator groups; it adds no required reading here.

*Signal Station* and every result attributed to its development are fictional. Numerical budgets, timing, and thresholds for your own project should be explicit, justified, and consistent with the syllabus and approved scope.
