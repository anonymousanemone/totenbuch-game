---
name: write-notion
description: Rules for writing to the project's Notion, the Final project tracker page and its three databases (Totenbuch Tasks, Weekly PPP, Risk Register): stay inside them, never delete without approval, sweep Done tasks into History only on explicit request and after confirming the exact list, set Roles, never reference gitignored files except `references/` source paths (turbo plans get their own row with full content), and write safely. Use before any Notion read of the tracker or any create, update, move or delete.
---

# Writing to Notion

The project's Notion lives on one page, **Final project tracker** (`https://app.notion.com/p/a2767ab14ecf83f381a38164610eda05`). This skill covers three databases on it:

| Database | Holds | Data source (use as `parent: {data_source_id}` when creating) |
|---|---|---|
| **Totenbuch Tasks** (`https://app.notion.com/p/41b67ab14ecf81048c25c441f4064b1d`) | the game's tasks, Plans, Docs and History pages | `collection://41b67ab1-4ecf-8198-b2f5-000b7d402646` |
| **Weekly PPP** (`https://app.notion.com/p/08d67ab14ecf82829b4081d6d800e39f`) | Progress, Plans and Problems for each week | `collection://42667ab1-4ecf-8229-a518-87287f2da05b` |
| **Risk Register** (`https://app.notion.com/p/b4c67ab14ecf83f096c301919dd7186f`) | the project's risks | `collection://53767ab1-4ecf-832e-9978-07bb7db8ffd0` |

Read this file before any Notion write. These rules come from the user and outrank a tool's defaults.

## 1. Scope: the tracker page and its three databases

- Read and write only those three databases, their views, and the pages inside them. Read the Final project tracker page itself only to find them; do not edit its text. Never read, edit, create, move or duplicate anything else in the workspace: other pages, databases, teamspaces, calendars, comments, files, memory.
- The course's template **Tasks** database was deleted from the page (2026-11-22); do not recreate it. Weekly PPP's **Tasks** relation points at Totenbuch Tasks.
- Create pages only with one of the three data sources as parent. No drafts, no workspace-level pages, no other databases.
- Never move a page out of its database (`notion-move-pages`), and never duplicate one outside it.
- If a task seems to need something outside them, stop and ask.
- Sections 2 and 5 and the general rules in Section 8 apply to all three databases. Sections 3, 4, 6 and 7, and the Categories and view rules in Section 8, are about Totenbuch Tasks only. Weekly PPP and Risk Register follow Section 9.

## 2. Deleting needs approval

Never delete anything unless the user has explicitly told you to, or approves your request first. Approval covers only the list shown to them, once.

What counts as deleting:

- Trashing a page (`notion-delete-pages`) or deleting a database, view or comment.
- Removing a property or a select/status option. Removing an option strips that value from every row that has it.
- Removing existing page text: `replace_content` or `update_content` that drops blocks, anything needing `allow_deleting_content`, or removing a child page or database.
- Clearing a property value that held information.

Not deleting: moving a finished task into its History item (Section 3), and adding content.

**The request for approval** must be plain and complete. Use `AskUserQuestion` and put this in the question or the text just before it:

1. How many items, and what kind ("3 task rows", "the Dangers: Completed page", "1 select option").
2. Each item by its title and link, with a few words on what it holds and its status or scope. For many items, group by scope with counts and list every title; never "and 40 others".
3. What happens: "moved to Notion's Trash; it can be restored from there" for pages; "removed from every row that uses it" for an option; "the text below is replaced" for content, quoting what goes.
4. What is not touched.

Options: delete exactly these, or don't. Wait for a clear yes. A yes does not carry over to later deletions. Pass `user_confirmed: true` to the tool only after it. Delete at most 20 pages per call. After deleting, say what was removed and how to restore it (`notion-restore-pages`).

## 3. Finished tasks stay at Done or go to History

A finished task stays at Done unless the user explicitly requests a History sweep and confirms the exact tasks to move.

- When you move a task to **Done** or see a task already in **Done**, fill an empty **Done date** with the date you see it in Done. Keep existing dates. The fallback records the day observed.
- For verified completed work, record the outcome, the implementation commit and a relevant PR or test link when available.

### Pick up In progress tasks

A row in **In progress** is work the user wants done now. Whenever an agent works in the database, it checks the In progress rows and picks up each one that nobody is working on, then completes it.

- **Unclaimed** (pick it up): the page has no Agent log, or the last log line is not a take, handover or blocker by an agent still on it. A row the user dragged to In progress with no log line is theirs to hand out, so it is unclaimed.
- **Claimed** (leave it alone): the last log line shows another agent took it, was handed it, or is working on it ("accepted", "handed over: … → <Role>", "working on …"). Also leave it if its Role names a different agent than you and that agent has a log line on it. Do not take over another agent's task; if one looks abandoned, ask the user.
- **Blocked:** if the last line is a blocker that only the user can clear, leave it and mention it to the user.
- **Picking up:** add a log line (`<date time> · <your role> · picked up`) before starting, and set Role to your own role if it is blank (Section 4). Read the whole page, its relations and the matching TODO.md line first.
- **Completing:** do the work in the repo following the project's other skills, then add a log line saying what was done and move the row to Done. Do not commit or push without asking (Section 8).
- **When to stop and ask:** the task is unclear, too big to finish in one go, needs a decision from the user, or turns out to be undecided (ask the user directly; don't set TBD yourself, Section 6). Write a blocker log line and leave the row in In progress.
- Pick up only what the current session can reasonably finish. If there are several, list them to the user first and say which you are taking.

### Sweep into History on request

- Review Done rows for History only when the user explicitly requests a sweep. Limit the review to the requested tasks or scope.
- Before writing anything to History, present the exact batch for confirmation. Give the count, each task's title and link, and its destination History item. Flag tasks with a full plan, a substantial body, or more material than fits in a short History entry, and explain what would be carried over. Wait for a clear yes and move only the confirmed rows.
- If the user chooses to keep a page, append a brief note recording their decision in the task body and leave its status at Done. On later sweeps, skip pages with a recorded decision to keep them.
- Each scope has one **History** item: a page named `<Scope>: History`, Scope set, Status `History` (they were first called `<Scope>: Completed`). If a scope has none, create it.

To sweep a task:

1. Fetch the task row. Read everything on it: name, description, body text, sub-bullets, agent log, scope, category, role, gate, owner, commits and dates, TODO.md line and section, relations (parent, sub-tasks, blocked by, blocking) and any comments.
2. Carry over the row's Done date, filling it from the day observed if empty. Verify the done commit in `git log`. Leave unknown commit and added-date metadata blank.
3. Add it to the History item as a checked box, in this shape (nested bullets under the line carry any sub-bullets, body text and the agent log lines, unchanged and in order):

```
- [x] {full task name and text}
	- *Done {commit} ({date}) · added {commit} ({date}) · {categories, or "no category"} · {role/gate/owner if set} · TODO.md line N, {section path}*
```

4. Fetch the History item and check every piece of text and metadata is there.
5. Only then remove the standalone row from the confirmed batch. The user's confirmation of the sweep covers this removal.
6. If something cannot be carried across (a comment, an attachment, a relation to a task that stays open), stop and ask. Do not remove the row.

Batch the move: write all entries for a scope in one edit, verify, then remove the rows in batches of 20. Say afterwards how many rows moved, to which History items, and what the links are.

## 4. Role on each item

The **Role** property says which agent a task belongs to: Producer, Design Lead, Tech Lead, Art Lead, Narrative and Audio, QA, BI or Publishing & Release. The team is those agents, the user and the professor.

- **One role per task.** Work shared between roles is split into separate tasks.
- **Who sets it.** An agent sets its own role on a task it is doing or has finished. For any other task, propose roles to the user in one batch (task, proposed role, a few words why) and set them only after approval. Do not change a Role the user set.
- **No clear owner:** leave Role blank. A blank Role means the work is the user's. Do not fill in Owner or Gate unless asked.
- **Until agents exist,** leave Role blank on everything and say so.
- A History entry carries the Role in its metadata line when the task had one.
- This is the user's current decision and may change; ask before extending it (for example to several roles per task).

### Agent log

Each task page ends with an **Agent log**: short notes by the assigned agent, and how the task moved between agents. It is for communication between agents, not a record of every edit, and there is no "edited by" property.

```
Agent log
- 2026-11-17 14:05 · Design Lead → Tech Lead · created: split off from "Spell 37 Merti wording"
- 2026-11-17 16:40 · Tech Lead · accepted; hint phase added
- 2026-11-18 09:10 · Tech Lead → QA · handed over: hint phase added and wired to the flashing signs
- 2026-11-18 11:30 · QA · checked on hard; done
```

- One line per note: date and time (24 h), the writing agent's role, then a short note. Keep it to a sentence.
- Write a note when you take a task, finish it, hit a blocker, or hand it on. Not for routine property edits.
- **Before assigning or passing a task on, add a brief context note first.** It says where the task came from or what was done, in a few words. It is not a description of the task and not a reason for choosing that agent.
  - Created for another agent: say what it spawned from ("split off from <bigger task>"). The creator writes this first line and sets Role to the receiver.
  - Handed over: say what was accomplished ("hint phase added and wired to the flashing signs"). Write `<From Role> → <To Role> · handed over: …`, then change Role to the receiver.
  - Every creation and handover has its log line and a note, however short: a few words is fine ("done", "split off from <task>"). No filler such as "please do this" or "needs Tech Lead".
- Only the assigned agent writes notes on its task, apart from creation and handover lines. Never write under another agent's role, and never edit or remove an earlier line; add a new one.
- **No log line means the user.** Any change, creation or handover with no agent log line is assumed to be the user's own. If a page does not look that way (for example a Role set to an agent, or a handover in the History with no line), ask before building on it.
- Until agents exist, notes are `Main session`, only for tasks the user asks you to log.
- When a task is swept into History, its agent log goes with it (Section 3).

## 5. Write safely

- **Fetch first.** Fetch the page or data source before writing; use the exact property names and option values from its schema. Never invent a Status, Scope, Category, Role or Gate value. Adding or removing options is a schema change: do it only when asked.
- **Smallest edit.** Prefer `update_content` and `insert_content` to `replace_content`. Preserve wording, order and native links you were not asked to change. Text a person wrote is never overwritten: append, or ask.
- **Write backticks, match `<code>`.** Write inline code with backticks. Notion returns it as `<code>…</code>` (and bold as `<b>`), so an `update_content` `old_str` must copy the fetched form, not what you sent.
- **Check for change.** If a page's `page_last_edited_at` is later than when you read it, fetch again before editing.
- **No gitignored files.** Never reference a gitignored path in Notion (a link, a path, "see file X"): other people and agents can't open it. Check with `git check-ignore -v <path>`, which also catches the global ignore (for example `.turbo/`). Copy the content in instead, or leave the reference out.
- **Exception: `references/`.** Source PDFs are cited by their `references/` path (including the `BookoftheDead alias` readings). That is the main way the List of Sources and other pages point to a source, so use it.
- **Turbo plans become their own row, only when the user says.** Never put a turbo plan into Notion on your own; wait until the user tells you to add that plan. Then it gets its own task row in the matching scope, with the plan's full content copied into the page body, unchanged and in order. Never link or point to the plan file. Name, Description, Category, Role and Status follow Sections 4 and 6 (Status Backlog unless the user says otherwise). If the plan changes later, update the row's body only when the user asks.
- **Docs, Plans, tasks.** One Doc (what is built, Status Documentation) and one Plan (large or unbuilt work, Status Plan) per scope, plus the Game-wide topic Docs the user created. Do not add another without being asked. See "Task, TBD or Plan" below for what becomes a row.

## 6. Task, TBD or Plan

A row is a task only if it is truly a task: one concrete piece of work that someone can pick up and finish, with a clear point where it is done (fix this bug, check this caption against Davis, shorten these nine descriptions).

- **TBD (a row, Status TBD):** only the user makes these. Create a TBD row or set Status TBD only when the user explicitly says "TBD" for that item. Never sort undecided points into TBD on your own. When an undecided point becomes relevant to the work (a task depends on it, or you would have to guess), ask the user directly with `AskUserQuestion` instead. A TBD row is phrased as the decision ("Decide …", "Choose …"); once the user decides, it moves to Backlog or To do as a task.
- **Plan (text in the scope's Plan item):** large game drafting, what ideas.md used to hold: proposed games and levels, merges, register-by-register designs, and an unbuilt minigame until it is broken into concrete steps. Its small open points inside a draft (tuning numbers, "its game is TBD") stay with the draft.

Do not move anything into a Plan without being asked. A cross-scope TBD row gets Scope Game-wide.

When the user asks for a Plan point to become a TBD row, put its full text in the new row's body, then replace the Plan passage with a one-line mention of the row ("<topic>: TBD, <mention>") so the Plan still reads whole.

**Always ask when it is ambiguous.** If a row could be read either way (a design decision that might be ready to act on, an idea phrased as a question, a review with a partly clear scope), do not decide alone: list the unclear rows in one `AskUserQuestion` (title, scope, a few words why) and act only on the answer. When the user drags a row to To do, treat it as a task unless they say otherwise.

### Title and Description of a task

Title, Description and page body each say something different; never repeat one in another.

- **Default: the description is the title.** Most tasks are one sentence (up to about 130 characters); that sentence is the title and the Description stays empty.
- **Task with extra specifics** (one or two further details that would make the title too long, about 200 characters): the title states the whole task as an action; the Description holds only the extra specifics (where, which items, a source, a constraint).
- **Very long task** (more than that, or several paragraphs or bullets): a descriptive title, a one-line Description summing up what matters, and the full text in the page body.

How to write them:

- The title is the task itself, not half of it and not a label: "nut_over_scarab: find a source that the goddess is Nut", not "Cosmos, nut_over_scarab".
- Don't repeat the Scope or the TODO.md section in the title ("Cosmos, …", "Unsourced: …", "TBD — …"); those are properties.
- You may reword to make the title an action, but keep every fact, name, ID, source and number. Nothing from the old text is dropped: it moves to the Description or the body.
- When unsure which tier a task is, or a rewording might change its meaning, ask.

These rules apply to task rows. Plan, Doc and History items keep their name-style titles (`<Scope> plan`, `<Scope>: History`).

## 7. Pipeline: ideas.md → Plan → tasks → History

Work moves through these stages, one way:

1. **ideas.md (repo).** Game and level ideas are written and argued here first. It stays the source of the design text; Notion does not replace it.
2. **Plan item (Notion).** When ideas.md gains a new level or section, or changes an existing one, carry it into that scope's Plan: summarise it, keep `[verify]` and `tbd` markers, and name the ideas.md section it came from. A new level with no scope yet gets a new Scope option and its own `<Scope> plan` page, only after the user agrees (it is a schema change). If ideas.md moves material from one level to another, move it between the Plans too and fix references (rewards, "later" uses) on both sides.
3. **Tasks out of the Plan.** A piece of the Plan becomes its own task row only when it is a true task (Section 6): decided, concrete, with a clear end, for example "cut each baboon's raised arms as their own layer" once the game is chosen. When you split one out:
   - Create the row in the same scope with Name, Description, Category and the Plan text it came from in the body, and Status Backlog (or To do if the user says so). Set Role per Section 4.
   - In the Plan, keep the line and mark it as split out with a mention of the new row, so the Plan still reads whole. Do not delete it.
   - If you are unsure whether it is ready to be a task, ask (Section 6).
   - Propose splits to the user in one batch; create them after a yes, unless the user asked for that split directly.
4. **Working the task.** Backlog → To do → In progress, with agent log lines (Section 4).
5. **Done → retained page or History.** Keep finished tasks at Done and follow Section 3 if the user requests a History sweep. In the Plan, mark the line as done with a link to the retained task page or its History page, or remove the line if the Plan has nothing left to say about it.
6. **Doc.** Once a feature is built, its behaviour belongs in the scope's Doc (Status Documentation), not the Plan. Update the Doc only when asked or when you built it.

Rows never go backwards into a Plan. If a task turns out to be undecided, ask the user; it goes to TBD only if they say so.

## 8. Other rules
- **Categories** (one per task) are only:
  - **References:** find, read or record the source for a claim, identification or translation. Not when text already cites a source and only needs checking.
  - **Source check:** compare existing text (caption, description, order, name) against a named source or the plate, and correct it.
  - **Writing:** write or rewrite player-facing text: intros, instruction lines, hints, descriptions, shortening.
  - **Gameplay:** what happens inside a scene: mechanics, puzzles, in-scene feedback, level flow.
  - **Interface:** anything outside the scroll: bottom bar, journal, hint button, map, cursor, message box, start prompt.
  - **Art:** splicing, cutting layers, exporting and registry entries for figures, and how the art reads in play.
  - **Bug:** something built that behaves differently from what was intended.

  Retired, never use or recreate: Design decision, Bug fix, Game feature mod, Text & research, UI / UX, New game feature, Testing & verification, Refactor / tech. An open decision is not a category: ask the user about it.
- **Schema and views.** Changing properties, options, views or filters needs the user's request. Keep completed items hidden in every view except status views, and Plan and Documentation out of the Tasks view.
- **Queries.** SQL and rows mode share a workspace usage limit. Prefer a saved view in `view` mode (100 per page, follow `next_cursor`). If the limit is reached, tell the user once and do not retry in a loop.
- **Limits.** At most 100 pages per create call and 20 per delete call. Check warnings in every result and report them.
- **Verify.** After a move, a bulk create or anything with a warning, fetch and check. Report what changed with links; do not claim a write you did not see succeed.
- **Privacy.** No personal details (name, email) in page text or properties.
- **Repo vs Notion.** `TODO.md` in the repo is still the source for TODO text and line numbers. Do not edit it to match Notion unless asked.
- **Git.** Writing to Notion never implies committing. Ask before any commit or push.

## 9. Weekly PPP and Risk Register

Both hold the student's own reporting to course staff, so a fact in them must be true and sourced. Fetch the data source before writing and copy the format of an existing row (date style, how a field is phrased).

### Weekly PPP

Properties: **Week** (title), **Date**, **Progress**, **Plans**, **Problems**, **Tasks** (relation).

- One row per week. Before creating, check whether that week's row exists; if it does, add to it and keep what is written.
- Write or change a row only when the user asks. Draft only from what the sources show: Totenbuch Tasks rows moved to Done or In progress that week, `project-docs/decision-log.md`, `git log`. Never invent progress. Text a person wrote is never overwritten (Section 5).
- Progress is what was done, Plans what is next, Problems what blocked or worries the work. A problem the user has not decided how to handle is stated as a problem; do not turn it into a plan or a TBD (Section 6).
- **Tasks** relates to Totenbuch Tasks: link the rows that week's text covers (usually those moved to Done that week).
- **Date** is the week's Monday to Sunday.

### Risk Register

Properties: **Risk** (title), **Dimension**, **Likelihood**, **Impact**, **Mitigation**, **Status**, **Last reviewed**.

- Use only the existing options: Dimension (IP / Concept, Business / Audience, Technology, Team, Genre / Mechanics, Timeline), Likelihood and Impact (Low, Medium, High), Status (Open, Watching, Closed). Adding or removing one is a schema change (Section 5).
- Write the title as the risk (what could go wrong) and put the response in Mitigation.
- Likelihood, Impact, Status and closing a risk are the user's judgement. Propose them in chat with a few words why, and set them after a yes. Set **Last reviewed** only to a date the user reviewed it.
- Add a risk only when the user asks, or propose it in chat first.
