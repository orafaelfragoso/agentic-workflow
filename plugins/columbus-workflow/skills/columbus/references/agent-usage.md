# Agent Usage

Columbus works best when agents use it as a compact retrieval layer instead of reading the repository blindly.

## On-Demand Exploration

Use `navigator` when a user or agent needs a grounded codebase map:

```text
Find where API request validation happens. Return relevant files, symbols, graph edges if useful, and recorded decisions.
```

Navigator should:

- search by intent using `columbus search --llm`
- inspect only the few relevant files or symbols
- search task-specific memory when decisions matter
- return one cited report
- avoid writing memory or coordinating other agents

## Orchestrated Work

In `ship`, the active session coordinates:

1. Load relevant global memory once.
2. Ask `navigator` for code context if needed.
3. Pass scoped findings to task agents.
4. Verify deliverables.
5. Record durable outcomes in Columbus memory.

Task agents should not each reload global memory or repeat broad retrieval.

When task agents work from Columbus epics, stories, or tasks, they should follow `work-item-workflow.md`: move the task to `in_progress` before starting, comment on meaningful progress, mark blockers as `blocked`, and mark work `done` only after verification.

## Direct Agent Commands

Use direct Columbus commands when no agent wrapper is needed:

```sh
columbus search "how search results are ranked" --llm --limit 10
columbus search "search ranking decision" --kind memory --llm
columbus show symbol RankResults --llm --snippet-lines 20
```

## Teaching Agent Discipline

Good Columbus usage keeps context small:

- State the retrieval intent in natural language.
- Use `--llm` for agent-readable output.
- Start broad, then drill into one or two targets.
- Prefer `show symbol` over broad snippets.
- Use `graphs` for architecture or dependency shape, not every question.
- Store only durable facts in memory.
