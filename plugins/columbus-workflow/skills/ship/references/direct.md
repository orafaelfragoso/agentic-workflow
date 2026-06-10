# Direct Ship Flow

Use direct orchestration when one agent or the active session can complete a single scoped piece of work without parallel handoffs.

## When To Use

- The work touches a narrow area.
- No other work depends on a partial output.
- No expected merge conflicts.
- The same branch is acceptable.

## Plan Setup

1. Inspect the work being executed:

   ```sh
   columbus memory list --kind plan --llm
   columbus show memory mem_12 --llm
   ```

2. Confirm the scope before implementation: the step being executed, its acceptance criteria, and what is out of scope. Track "in progress" in the session — Columbus is not a live board.

3. If the plan memory is stale against the code it references, run `columbus memory validate` and reconcile before starting.

## Context And Communication

- Use the plan memory's links and evidence plus relevant ADRs/documentation already retrieved by the session.
- Dispatch `navigator` only if code location or dependency shape is unclear.
- If a specialist agent is used, brief it with the plan scope, acceptance criteria, files, branch strategy, and expected return format.
- Record meaningful discoveries in the plan memory body, not chat-only notes:

  ```sh
  columbus memory update mem_12 --body "<plan body with progress notes and discoveries>"
  ```

## Branch Strategy

Prefer the current branch when:

- the work is narrow
- no other agent is editing the same area
- the user did not ask for separate branches

Create a dedicated branch when:

- the work may be reviewed or shipped independently
- the user asks for a PR-ready slice
- the change is risky

Use a worktree only when concurrent work must be isolated.

## Delivery Gates

Run these in order:

1. Acceptance criteria check.
2. Implementation.
3. Tests or explicit verification.
4. Code quality review.
5. Security/CVE check if dependencies, auth, permissions, secrets, data handling, or network exposure changed.
6. Architecture/design-pattern check if abstractions, boundaries, or shared flows changed.

## Closeout

Only after verification:

1. Record durable outcomes:

   ```sh
   columbus memory add adr --title "<decision>" \
     --body "Decision: <what>. Context: <forces>. Consequences: <trade-off>." \
     --tag <area> --link file:<path>

   columbus memory add documentation --title "<shipped behavior>" \
     --body "<how it works now>" --tag <area> --evidence <path>:<start>-<end>
   ```

2. Retire the executed plan — re-kind it if its content now describes reality, or remove it:

   ```sh
   columbus memory update mem_12 --kind documentation
   # or
   columbus memory remove mem_12
   ```

3. If new work appeared, capture it as a new `plan` memory instead of widening scope silently.
