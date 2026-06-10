# Parallel Ship Flow

Use parallel orchestration when independent pieces of planned work can run concurrently without sharing mutable files or depending on each other's output. Each lane is its own run of the agentic loop — a `delivery-engineer` (plus its verify/review agents) in an isolated worktree or branch. The coordinator owns the lane map, the merge, and memory; it implements nothing.

## When To Use

- Multiple steps of a plan (or multiple plans) are independent.
- Different agents can work on different files, layers, or concerns.
- Review, security, architecture, or test analysis can run against a stable implementation snapshot.
- Separate branches or worktrees can isolate risk.

## Dependency Check

Before parallelizing, classify each piece of work:

- Independent: can run now.
- Sequential: depends on another lane's output.
- Shared-file risk: likely merge conflict.
- Shared-domain risk: decisions may conflict even if files differ.

Only parallelize independent work. Convert uncertain pieces to sequential flow.

## Lane Setup

The coordinator owns the lane map. For each lane, state in the session:

- the plan memory id and which of its steps the lane owns
- the branch or worktree
- the lane's acceptance criteria

Columbus is not a live board — lane status (in progress, blocked, done) lives in the session. Fold lane assignments into the plan memory body only when they must survive the session:

```sh
columbus memory update mem_12 \
  --body "<plan body noting: lane A = steps 1-2 on branch feat/a, lane B = step 3 on branch feat/b>"
```

## Branch And Worktree Strategy

Use separate branches or worktrees when agents will edit concurrently:

- one worktree per editing lane (deploy the lane's agents with `isolation: "worktree"`) — the default for parallel implementation; with `worktree.baseRef` set to `"head"` each worktree branches from local HEAD and sees in-progress work
- one branch per lane for independent PR-ready slices
- same branch only for read-only analysis agents or strictly non-overlapping serial edits

## Agent Communication

The active session coordinates all lanes. Agents do not coordinate directly unless the host explicitly supports it and the user asked for it.

Each lane gets a scoped brief:

- the plan scope it owns (and the parent plan id)
- branch or worktree
- owned files or subsystem
- do-not-touch areas
- relevant memory findings (ADRs, documentation)
- expected output and verification

Agents communicate through:

- returned reports
- branch names and verification commands

The coordinator synthesizes lane reports and performs any memory writes. Do not rely on chat-only context for facts another lane needs — put shared facts in the briefs.

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
- declaring the plan complete before all lanes are merged and verified

## Merge And Synthesis

After lanes finish:

1. Collect each lane report.
2. Check branch status and diffs.
3. Merge or apply changes one lane at a time (git mechanics are the coordinator's).
4. Resolve code conflicts by dispatching a `delivery-engineer` briefed with both lanes' reports — the coordinator does not hand-edit conflicting source.
5. Run combined verification (`test-engineer` on the merged result).
6. Run final quality, security, and architecture gates on the merged result with the matching review agents.

## Closeout

Only after all lanes are merged and verified together:

1. Record decisions as `adr` and shipped behavior as `documentation`, anchored with tags, links, and evidence.
2. Retire the executed plan: `columbus memory update mem_12 --kind documentation`, or `columbus memory remove mem_12`.
3. If a lane failed or was deferred, update the plan memory body with what remains and why, so the next session can resume.
4. Capture discovered follow-up work as a new `plan` memory.
