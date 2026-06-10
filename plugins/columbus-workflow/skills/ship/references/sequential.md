# Sequential Ship Flow

Use sequential orchestration when work must pass through ordered stages or one agent's output becomes the next agent's input.

## When To Use

- Planning must happen before implementation.
- Code context must be gathered before changes.
- Implementation must finish before test, review, security, or architecture analysis.
- The story has dependencies that need gate-by-gate decisions.

## Standard Stage Order

1. Planning: clarify acceptance criteria, dependencies, branch strategy, and board scope.
2. Exploration: use `navigator` for code locations, graph shape, and recorded decisions.
3. Implementation: make the minimal scoped change.
4. Testing: add or run behavior-focused tests.
5. Quality review: check correctness, maintainability, naming, and regression risk.
6. Security review: check CVEs, dependency risk, auth, permissions, secrets, injection, and data handling.
7. Architecture review: check design patterns, boundaries, coupling, and long-term maintainability.
8. Release readiness: summarize verification, board updates, branch/PR state, and follow-ups.

## Board Protocol

Claim the task before stage 1 starts:

```sh
columbus memory update task task_123 \
  --status in_progress \
  --comment "Started sequential ship flow. Stages: plan, explore, implement, test, review, security, architecture, release."
```

Add comments at stage boundaries:

```sh
columbus memory update task task_123 \
  --comment "Exploration complete: key files are <paths>; implementation can proceed."
```

If a stage blocks the next one:

```sh
columbus memory update task task_123 \
  --status blocked \
  --comment "Blocked in security review: dependency advisory requires version decision."
```

## Agent Handoffs

Each handoff brief should include:

- task, story, and epic IDs
- current branch or worktree
- scoped Columbus memory
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
- board updates performed or requested

## Branch Strategy

Use one branch for a sequential flow unless a stage requires risky experimental work.

Use separate branches when:

- an exploration spike must be discarded independently
- a security fix must ship separately from feature work
- review asks for a separate refactor

When switching branches, add a task comment with the branch name and reason.

## Security And CVE Handling

For dependency or CVE analysis:

- identify package names and versions from lockfiles or manifests
- check current advisories with the available package manager, security tooling, or current web/advisory sources
- distinguish exploitable runtime risk from theoretical dependency presence
- recommend upgrade, pin, mitigation, or acceptance with rationale

Do not claim "no CVEs" unless current sources or tooling were checked.

## Closeout

Before marking done:

1. Confirm each required stage is complete or explicitly skipped.
2. Confirm verification commands and results.
3. Add durable Columbus memory for decisions, patterns, failures, or commands.
4. Mark the task `done`.
5. Check child tasks before marking the story or epic `done`.
