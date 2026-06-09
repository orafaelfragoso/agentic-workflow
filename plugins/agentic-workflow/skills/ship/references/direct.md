# Direct Ship Flow

Use direct orchestration when one agent or the active session can complete a single task without parallel handoffs.

## When To Use

- One task touches a narrow area.
- No other task depends on a partial output.
- No expected merge conflicts.
- The same branch is acceptable.

## Board Setup

1. Inspect the assigned work:
   ```sh
   columbus show task task_123 --llm
   columbus memory list story --parent epic_123 --llm
   ```

2. Claim the task before implementation:
   ```sh
   columbus memory update task task_123 \
     --status in_progress \
     --comment "Started direct ship flow on <scope>."
   ```

3. Move the parent story or epic to `in_progress` only when this starts active work for that parent.

## Context And Communication

- Use Project Context and relevant Columbus memory already loaded by the session.
- Dispatch `navigator` only if code location or dependency shape is unclear.
- If a specialist agent is used, brief it with task ID, acceptance criteria, files, branch strategy, and expected return format.
- Record meaningful discoveries as task comments, not chat-only notes.

## Branch Strategy

Prefer the current branch when:

- the task is narrow
- no other agent is editing the same area
- the user did not ask for separate branches

Create a dedicated branch when:

- the work may be reviewed or shipped independently
- the user asks for a PR-ready slice
- the task has risky changes

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

Mark the task done only after verification:

```sh
columbus memory update task task_123 \
  --status done \
  --comment "Done: <summary>. Verified with `<command>`."
```

If durable knowledge changed, add or update context memory:

```sh
columbus memory add context --type decision \
  --title "<decision>" \
  --body "<what changed and why>" \
  --tag <area>
```

If new work appears, create a follow-up task instead of widening scope silently.
