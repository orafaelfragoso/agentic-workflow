---
name: ship
description: Runs a complete Scrum/Kanban development flow over Columbus epics, stories, and tasks by planning the board, choosing direct/sequential/parallel orchestration, coordinating agents, updating statuses, managing branches, verifying implementation, reviewing quality, analyzing security, and closing work. Use when the user asks to ship, process a sprint, work through Columbus tasks, coordinate delivery, run agents on epics/stories/tasks, or complete a development workflow.
---

# Ship

Ship Columbus epics, stories, and tasks through a complete development process while keeping board state, session context, branch strategy, reviews, and verification coherent.

## Workflow

1. **Check the board and project context**
   - Run `columbus doctor` when Columbus state is uncertain.
   - Load active work with `columbus memory list epic|story|task --llm`.
   - Load only relevant global memory and task-specific memory. Do not make every task agent reload global context.

2. **Pick the orchestration mode**
   - Direct: one task or one agent can complete the work. Read `references/direct.md`.
   - Sequential: tasks depend on earlier outputs or need gated stages. Read `references/sequential.md`.
   - Parallel: independent tasks can run concurrently and merge later. Read `references/parallel.md`.

3. **Prepare the sprint lane**
   - Confirm the epic, story, and task IDs being processed.
   - Move claimed tasks to `in_progress` before work starts.
   - Decide branch strategy: same branch for one narrow thread, separate branches or worktrees for parallel/conflicting work.

4. **Coordinate agents with explicit handoffs**
   - Use `navigator` for codebase exploration.
   - Use specialist task agents for planning, implementation, tests, review, security, architecture, and release readiness.
   - Communicate through scoped briefs, returned reports, Columbus task comments, and memory updates for durable decisions.

5. **Apply delivery gates**
   - Acceptance criteria and dependency check.
   - Implementation and test evidence.
   - Code quality review.
   - Security and dependency/CVE review when dependencies, auth, data handling, or network exposure are touched.
   - Architecture/design-pattern review when boundaries, abstractions, or shared flows change.

6. **Close board state**
   - Mark tasks `blocked` with a reason when progress stops.
   - Mark tasks `done` only after verification.
   - Mark stories and epics `done` only after child work is complete.
   - Add or update Columbus memories for durable decisions, patterns, failures, commands, or glossary changes.

## Validation

- [ ] The orchestration mode was chosen and the matching reference was used.
- [ ] Columbus task/story/epic statuses and comments reflect current work state.
- [ ] Agent handoffs were explicit and scoped.
- [ ] Branch strategy was stated before implementation.
- [ ] Implementation, tests, review, security, and architecture gates were run or explicitly skipped with a reason.
- [ ] Durable outcomes were captured in Columbus memory.
