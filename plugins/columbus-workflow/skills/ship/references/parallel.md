# Parallel Ship Flow

Use parallel orchestration when independent tasks can run concurrently without sharing mutable files or depending on each other's output.

## When To Use

- Multiple tasks under a story are independent.
- Different agents can work on different files, layers, or concerns.
- Review, security, architecture, or test analysis can run against a stable implementation snapshot.
- Separate branches or worktrees can isolate risk.

## Dependency Check

Before parallelizing, classify tasks:

- Independent: can run now.
- Sequential: depends on another task output.
- Shared-file risk: likely merge conflict.
- Shared-domain risk: decisions may conflict even if files differ.

Only parallelize independent tasks. Convert uncertain tasks to sequential flow.

## Board Setup

Claim each task independently:

```sh
columbus memory update task task_123 \
  --status in_progress \
  --comment "Started parallel ship lane A on branch <branch>."

columbus memory update task task_456 \
  --status in_progress \
  --comment "Started parallel ship lane B on branch <branch>."
```

Move the parent story or epic to `in_progress` once the first child starts.

## Branch And Worktree Strategy

Use separate branches or worktrees when agents will edit concurrently:

- one branch per task for independent PR-ready slices
- one worktree per branch if simultaneous local edits are needed
- same branch only for read-only analysis agents or strictly non-overlapping serial edits

Record branch assignment in each task comment.

## Agent Communication

The active session coordinates all lanes. Agents do not coordinate directly unless the host explicitly supports it and the user asked for it.

Each lane gets a scoped brief:

- task ID and parent story/epic
- branch or worktree
- owned files or subsystem
- do-not-touch areas
- relevant Columbus memory
- expected output and verification

Agents communicate through:

- returned reports
- Columbus task comments
- durable context memory for decisions, patterns, failures, and commands
- branch names and verification commands

Do not rely on chat-only context for facts another lane needs.

## Parallel Quality Gates

Safe parallel gates:

- `navigator` exploration on separate areas
- test planning while implementation is stable enough
- security dependency inventory
- architecture review of a committed or staged snapshot

Unsafe parallel gates:

- two agents editing the same file
- review of code still changing in another lane
- security claims before dependency versions are known
- marking a parent story done before child tasks are merged and verified

## Merge And Synthesis

After lanes finish:

1. Collect each lane report.
2. Check branch status and diffs.
3. Merge or apply changes one lane at a time.
4. Resolve conflicts in the coordinator.
5. Run combined verification.
6. Run final quality, security, and architecture checks on the merged result.

## Closeout

For each completed child task:

```sh
columbus memory update task task_123 \
  --status done \
  --comment "Done: lane merged and verified with `<command>`."
```

If a lane fails or conflicts:

```sh
columbus memory update task task_123 \
  --status blocked \
  --comment "Blocked: merge conflict with task_456 in <file>; needs sequencing decision."
```

Mark the story or epic done only after all child lanes are complete, merged, and verified together.
