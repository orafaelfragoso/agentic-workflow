---
name: ship
description: Runs a complete development flow over Columbus plan memories by scoping the work, choosing direct/sequential/parallel orchestration, deploying task agents through an implement-verify-review loop, managing branches and worktrees, and recording outcomes as durable memory. The session coordinates only — all implementation, testing, and review is done by deployed agents. Use when the user asks to ship, execute a plan, work through Columbus plans, coordinate delivery, run agents on planned work, or complete a development workflow.
---

# Ship

Ship Columbus-planned work through a complete development process while keeping plan state, session context, branch strategy, reviews, and verification coherent.

Columbus is durable memory, not a live board: `plan` memories hold the scoped work, the session tracks execution state, and verified outcomes land back in memory as `adr` and `documentation`.

## The coordinator rule

**The active session is a coordinator, never an implementer.** It does not edit source files, write tests, perform reviews, or read diffs itself. Every piece of delivery work is done by a deployed task agent; the coordinator scopes briefs, manages branches and worktrees, reads returned JSON reports, makes gate decisions, and writes memory. Diff reading belongs to the agents that own the gate — quality-reviewer, test-engineer, security-analyst, and architecture-reviewer each fetch the diff themselves.

Every mode runs the same **agentic loop**, differing only in how many lanes run it and in what order:

1. **Explore** — `navigator` retrieves code locations, dependency shape, and recorded decisions (skip only when the plan memory already pins them).
2. **Implement** — `delivery-engineer` makes the scoped change on the assigned branch or worktree.
3. **Verify** — `test-engineer` designs and runs verification against the acceptance criteria.
4. **Review** — `quality-reviewer` always; `security-analyst` and `architecture-reviewer` when their gates apply.
5. **Close** — `release-coordinator` for branch/PR/merge readiness when shipping; the coordinator records memory.

**Agents persist while their work is open.** Deploy each loop agent once, give it a name, and keep it addressable: a revision round continues the *same* agent via `SendMessage` with the reviewer's findings — its context (plan scope, files, prior attempts) is intact, so nothing is re-fetched. Never respawn a fresh agent for work an existing agent already has context on; respawning pays the full context-loading cost again. Use `run_in_background: true` for lanes that run while the coordinator does other work, and let agents terminate only when their lane's work is closed or blocked.

A failed gate loops back: send the findings to the implementing agent as a `SendMessage` follow-up brief. Stop conditions — surface to the user and record the blocker in the plan memory when any of these hold:

- two revision rounds are exhausted
- a round produces no progress on the gate it was sent to fix
- the same failure repeats with the same cause across rounds

## Stage classification

Classify the work **before deploying any agent** to skip unnecessary stages:

| Stage        | Condition                                                     | Skip                                                  |
| ------------ | ------------------------------------------------------------- | ----------------------------------------------------- |
| **Trivial**  | < 5 files, no shared flows or arch boundaries                 | navigator, security-analyst, architecture-reviewer    |
| **Standard** | multi-file, no boundary changes                               | architecture-reviewer (unless boundaries are touched) |
| **Complex**  | touches shared flows, module boundaries, or security surfaces | run full loop                                         |

State the classification and any skipped stages before the first agent is deployed.

## Model assignments

Deploy each agent with its assigned model:

| Agent                 | Model  |
| --------------------- | ------ |
| navigator             | sonnet |
| delivery-engineer     | sonnet |
| test-engineer         | sonnet |
| quality-reviewer      | sonnet |
| security-analyst      | sonnet |
| architecture-reviewer | opus   |
| release-coordinator   | opus   |

## Brief and report protocol

**Brief** (coordinator → agent): one clear action sentence + the necessary context (plan id, relevant memory excerpt, branch, files in scope, acceptance criteria, constraints). When the work touches code, name the mastering skill to load (`columbus-workflow:mastering-golang`, `columbus-workflow:mastering-typescript`, or `columbus-workflow:mastering-design`). Do not include context the agent does not need for its specific task.

**Report** (agent → coordinator): JSON only.

```json
{ "status": "done" | "partial" | "blocked", "cause": "<short phrase when partial or blocked>", "risks": ["<risk-label>"] }
```

`cause` is omitted when `status` is `"done"`. `risks` is an array of short labels (e.g. `"auth"`, `"scope-widened"`, `"arch-boundary"`); empty array when none.

## Workflow

1. **Load the plan and project context**
   - Run `columbus doctor` when Columbus state is uncertain.
   - Load planned work with `columbus memory list --kind plan --llm`, then `columbus show memory <id> --llm` for the plans being executed.
   - Retrieve only the relevant ADRs and documentation (`columbus search "<topic>" --kind memory --llm`). Do not make every task agent re-run broad memory retrieval.

2. **Pick the orchestration mode**
   - Direct: one lane — a single agent chain on one branch completes the work. Read `references/direct.md`.
   - Sequential: stages depend on earlier outputs or need gated stages. Read `references/sequential.md`.
   - Parallel: independent lanes run concurrently in isolated worktrees and merge later. Read `references/parallel.md`. When agent teams are available (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), run parallel lanes as a team — the shared task list and teammate messaging replace hand-tracked lane state; the reference covers both forms.

3. **Prepare the delivery lane(s)**
   - Confirm which plan memory (or which of its steps) is being executed, and its acceptance criteria.
   - Track execution state in the session: which steps are in progress, blocked, or done.
   - State the branch/worktree strategy before any agent is deployed: dedicated branch for a single lane, one worktree per lane (`isolation: "worktree"`) for parallel or conflicting work. With `worktree.baseRef` set to `"head"`, agent worktrees branch from the local HEAD, so in-progress work is visible to them.

4. **Run the agentic loop with explicit handoffs**
   - Deploy the loop's agents per the chosen mode's reference; never absorb a stage into the coordinator.
   - Communicate through scoped briefs and JSON reports per the protocol above. The coordinator reads agent JSON status and risks — never the raw diff.
   - The coordinator owns synthesis and all memory writes.

5. **Apply delivery gates**
   - Acceptance criteria and dependency check.
   - Implementation and test evidence (from agent JSON reports).
   - Code quality review.
   - Security and dependency/CVE review when dependencies, auth, data handling, or network exposure are touched.
   - Architecture/design-pattern review when boundaries, abstractions, or shared flows change.

6. **Close out in memory**
   - At milestones, update the plan memory body so progress survives the session (`columbus memory update <id> --body "..."`).
   - If work stops, note the blocker in the plan memory before ending the session.
   - After verification: record decisions as `adr`; add a `documentation` memory only when a process or behavior genuinely needs explaining — written fresh, never converted from the plan. Then remove the executed plan (`columbus memory remove <id>`).
   - Capture discovered follow-up work as a new `plan` memory instead of widening scope silently.
   - Run `columbus memory validate` if the work moved code that memories anchor to.

## Validation

- [ ] The orchestration mode was chosen and the matching reference was used.
- [ ] Every code, test, and review change was made by a deployed agent — the coordinator made no direct edits.
- [ ] The agentic loop ran in full, or skipped stages were named with a reason.
- [ ] The driving plan memory reflects current progress and any blockers.
- [ ] Agent handoffs were explicit and scoped.
- [ ] Branch/worktree strategy was stated before the first agent was deployed.
- [ ] Stage classification was stated before the first agent was deployed.
- [ ] Each agent was deployed with its assigned model from the model table.
- [ ] All agent communication used the JSON brief/report protocol.
- [ ] The coordinator did not read diffs — gate agents fetched their own.
- [ ] Implementation, tests, review, security, and architecture gates were run or explicitly skipped with a reason.
- [ ] Revision rounds continued the same agent via `SendMessage` — no agent was respawned for work a live agent had context on.
- [ ] Durable outcomes were captured: ADRs for decisions, fresh documentation only where behavior needed explaining, executed plans removed.
