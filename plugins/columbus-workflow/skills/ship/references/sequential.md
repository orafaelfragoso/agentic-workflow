# Sequential Ship Flow

Use sequential orchestration when work must pass through ordered stages or one agent's output becomes the next agent's input.

## When To Use

- Planning must happen before implementation.
- Code context must be gathered before changes.
- Implementation must finish before test, review, security, or architecture analysis.
- The plan has dependencies that need gate-by-gate decisions.

## Standard Stage Order

1. Planning: clarify acceptance criteria, dependencies, branch strategy, and the plan-memory scope.
2. Exploration: use `navigator` for code locations, graph shape, and recorded decisions.
3. Implementation: make the minimal scoped change.
4. Testing: add or run behavior-focused tests.
5. Quality review: check correctness, maintainability, naming, and regression risk.
6. Security review: check CVEs, dependency risk, auth, permissions, secrets, injection, and data handling.
7. Architecture review: check design patterns, boundaries, coupling, and long-term maintainability.
8. Release readiness: summarize verification, branch/PR state, memory updates, and follow-ups.

## Plan Protocol

Before stage 1, load the driving plan and state the stage sequence in the session:

```sh
columbus show memory mem_12 --llm
```

Track stage progress in the session. At meaningful boundaries — exploration done, implementation done — fold durable findings into the plan memory body so a later session can resume:

```sh
columbus memory update mem_12 \
  --body "<plan body updated with: exploration complete, key files <paths>; implementation next>"
```

If a stage blocks the flow, record the blocker in the plan memory before stopping:

```sh
columbus memory update mem_12 \
  --body "<plan body noting: blocked in security review — dependency advisory requires version decision>"
```

## Agent Handoffs

Each handoff brief should include:

- the plan memory id and the relevant excerpt of its body
- current branch or worktree
- scoped memory findings (ADRs, documentation) that apply
- relevant `navigator` report
- stage goal
- constraints and non-goals
- expected output

Each agent returns:

- findings or changes
- files touched or recommended
- commands run
- risks
- next-stage input
- memory updates recommended (the coordinator writes them)

## Branch Strategy

Use one branch for a sequential flow unless a stage requires risky experimental work.

Use separate branches when:

- an exploration spike must be discarded independently
- a security fix must ship separately from feature work
- review asks for a separate refactor

When switching branches, note the branch name and reason in the session log and, if it matters across sessions, in the plan memory.

## Security And CVE Handling

For dependency or CVE analysis:

- identify package names and versions from lockfiles or manifests
- check current advisories with the available package manager, security tooling, or current web/advisory sources
- distinguish exploitable runtime risk from theoretical dependency presence
- recommend upgrade, pin, mitigation, or acceptance with rationale

Do not claim "no CVEs" unless current sources or tooling were checked.

## Closeout

Before declaring the flow done:

1. Confirm each required stage is complete or explicitly skipped.
2. Confirm verification commands and results.
3. Record decisions as `adr` and shipped behavior as `documentation`, anchored with tags, links, and evidence.
4. Retire the executed plan: `columbus memory update mem_12 --kind documentation`, or `columbus memory remove mem_12`.
5. Capture discovered follow-up work as a new `plan` memory.
6. Run `columbus memory validate` if the work moved code that memories anchor to.
