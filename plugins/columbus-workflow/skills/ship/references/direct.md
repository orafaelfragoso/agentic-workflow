# Direct Ship Flow

Use direct orchestration when one delivery lane can complete a single scoped piece of work without parallel handoffs. Direct means **one lane**, not "the coordinator does it" — the agentic loop still runs, with one agent per stage. The coordinator never edits files.

## When To Use

- The work touches a narrow area.
- No other work depends on a partial output.
- No expected merge conflicts.
- A single branch is acceptable.

## Plan Setup

1. Inspect the work being executed:

   ```sh
   columbus memory list --kind plan --llm
   columbus show memory mem_12 --llm
   ```

2. Confirm the scope before deploying anyone: the step being executed, its acceptance criteria, and what is out of scope. Track "in progress" in the session — Columbus is not a live board.

3. If the plan memory is stale against the code it references, run `columbus memory validate` and reconcile before starting.

## The Loop, One Lane

Run the stages in order; each is a deployed agent with a scoped brief:

1. **Explore** — `navigator` (model: sonnet), only if code locations or dependency shape are unclear (the plan memory's links and evidence often already pin them).
2. **Implement** — `delivery-engineer` (model: sonnet) on the lane's branch. The brief carries: plan memory id and the relevant body excerpt, acceptance criteria, files in scope, branch name, and constraints.
3. **Verify** — `test-engineer` (model: sonnet) runs and extends verification against the acceptance criteria. May be combined with stage 2 only when the plan explicitly includes the test work in the delivery-engineer's scope.
4. **Review** — `quality-reviewer` (model: sonnet) on the diff. Add `security-analyst` (model: sonnet) if dependencies, auth, permissions, secrets, data handling, or network exposure changed; add `architecture-reviewer` (model: opus) if abstractions, boundaries, or shared flows changed.
5. **Close** — the coordinator checks the gates, then writes memory (below).

If a review gate fails, send the findings to the *same* `delivery-engineer` via `SendMessage` — it still holds the plan scope and its own change context, so the follow-up brief is just the findings and the gate to satisfy. Do not spawn a fresh agent for a revision. Max two revision rounds, or stop early if a round makes no progress or repeats the same failure; then record the blocker in the plan memory and surface to the user.

The coordinator's own contributions are limited to: reading agent JSON reports, running read-only checks to confirm gate claims, branch management, and memory writes. The coordinator never reads diffs — gate agents (quality-reviewer, test-engineer, security-analyst, architecture-reviewer) fetch the diff themselves. Record meaningful discoveries in the plan memory body, not chat-only notes:

```sh
columbus memory update mem_12 --body "<plan body with progress notes and discoveries>"
```

## Branch Strategy

State the strategy before deploying the implementing agent.

Use the current branch when:

- the work is narrow
- nothing else is editing the same area
- the user did not ask for separate branches

Create a dedicated branch when:

- the work may be reviewed or shipped independently
- the user asks for a PR-ready slice
- the change is risky

Use a worktree (`isolation: "worktree"` on the agent) when the agent's edits must not touch the session's checkout — e.g. risky changes, or the user keeps working locally. With `worktree.baseRef` set to `"head"`, the agent's worktree branches from local HEAD and sees in-progress work.

## Delivery Gates

Run these in order, each backed by an agent JSON report `{ status, cause, risks }`:

1. Acceptance criteria check (coordinator, against the plan memory).
2. Implementation (`delivery-engineer` JSON report).
3. Tests or explicit verification (`test-engineer` JSON report).
4. Code quality review (`quality-reviewer` JSON report).
5. Security/CVE check (`security-analyst`) if dependencies, auth, permissions, secrets, data handling, or network exposure changed.
6. Architecture/design-pattern check (`architecture-reviewer`) if abstractions, boundaries, or shared flows changed.

## Closeout

Only after verification:

1. Record durable outcomes. Decisions become `adr` memories. Add a `documentation` memory only when a process or behavior genuinely needs explaining — write it fresh from the shipped code, never by converting the plan:

   ```sh
   columbus memory add adr --title "<decision>" \
     --body "Decision: <what>. Context: <forces>. Consequences: <trade-off>." \
     --tag <area> --link file:<path>

   # only if the shipped behavior needs explaining:
   columbus memory add documentation --title "<shipped behavior>" \
     --body "<how it works now>" --tag <area> --evidence <path>:<start>-<end>
   ```

2. Remove the executed plan — it is no longer future work:

   ```sh
   columbus memory remove mem_12
   ```

3. If new work appeared, capture it as a new `plan` memory instead of widening scope silently.
