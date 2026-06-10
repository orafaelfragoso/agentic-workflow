---
name: ship
description: Runs a complete development flow over Columbus plan memories by scoping the work, choosing direct/sequential/parallel orchestration, coordinating agents, managing branches, verifying implementation, reviewing quality, analyzing security, and recording outcomes as durable memory. Use when the user asks to ship, execute a plan, work through Columbus plans, coordinate delivery, run agents on planned work, or complete a development workflow.
---

# Ship

Ship Columbus-planned work through a complete development process while keeping plan state, session context, branch strategy, reviews, and verification coherent.

Columbus is durable memory, not a live board: `plan` memories hold the scoped work, the session tracks execution state, and verified outcomes land back in memory as `adr` and `documentation`.

## Workflow

1. **Load the plan and project context**
   - Run `columbus doctor` when Columbus state is uncertain.
   - Load planned work with `columbus memory list --kind plan --llm`, then `columbus show memory <id> --llm` for the plans being executed.
   - Retrieve only the relevant ADRs and documentation (`columbus search "<topic>" --kind memory --llm`). Do not make every task agent re-run broad memory retrieval.

2. **Pick the orchestration mode**
   - Direct: one agent or the active session can complete the work. Read `references/direct.md`.
   - Sequential: steps depend on earlier outputs or need gated stages. Read `references/sequential.md`.
   - Parallel: independent steps can run concurrently and merge later. Read `references/parallel.md`.

3. **Prepare the delivery lane**
   - Confirm which plan memory (or which of its steps) is being executed, and its acceptance criteria.
   - Track execution state in the session: which steps are in progress, blocked, or done.
   - Decide branch strategy: same branch for one narrow thread, separate branches or worktrees for parallel/conflicting work.

4. **Coordinate agents with explicit handoffs**
   - Use `navigator` for codebase exploration.
   - Use specialist task agents for planning, implementation, tests, review, security, architecture, and release readiness.
   - Communicate through scoped briefs and returned reports. The coordinator owns synthesis and any memory writes.

5. **Apply delivery gates**
   - Acceptance criteria and dependency check.
   - Implementation and test evidence.
   - Code quality review.
   - Security and dependency/CVE review when dependencies, auth, data handling, or network exposure are touched.
   - Architecture/design-pattern review when boundaries, abstractions, or shared flows change.

6. **Close out in memory**
   - At milestones, update the plan memory body so progress survives the session (`columbus memory update <id> --body "..."`).
   - If work stops, note the blocker in the plan memory before ending the session.
   - After verification: record decisions as `adr`, shipped behavior as `documentation`, then re-kind the executed plan (`memory update <id> --kind documentation`) or remove it.
   - Capture discovered follow-up work as a new `plan` memory instead of widening scope silently.
   - Run `columbus memory validate` if the work moved code that memories anchor to.

## Validation

- [ ] The orchestration mode was chosen and the matching reference was used.
- [ ] The driving plan memory reflects current progress and any blockers.
- [ ] Agent handoffs were explicit and scoped.
- [ ] Branch strategy was stated before implementation.
- [ ] Implementation, tests, review, security, and architecture gates were run or explicitly skipped with a reason.
- [ ] Durable outcomes were captured: ADRs for decisions, documentation for shipped behavior, executed plans re-kinded or removed.
