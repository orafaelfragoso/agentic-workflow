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
- search memory (`--kind memory`) when recorded ADRs, plans, or documentation matter
- return one cited report
- avoid writing memory or coordinating other agents

## Orchestrated Work

In `ship`, the active session coordinates:

1. Retrieve relevant ADRs, plans, and documentation once.
2. Ask `navigator` for code context if needed.
3. Pass scoped findings to task agents.
4. Verify deliverables.
5. Record durable outcomes: decisions as `adr`; `documentation` only when a process or behavior genuinely needs explaining. Remove executed `plan` memories.

Task agents should not each re-run broad memory retrieval or repeat wide searches; the coordinator passes each one the scoped context its task needs.

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
- Store only durable facts in memory, anchored with tags, links, and evidence.
- Run `columbus memory validate` after refactors that move code memories point at.
