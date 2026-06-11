# Parallel Ship Flow

Use parallel orchestration when independent pieces of planned work can run concurrently without sharing mutable files or depending on each other's output. Each lane is its own run of the agentic loop — a `delivery-engineer` (plus its verify/review agents) in an isolated worktree or branch. The coordinator owns the lane map, the merge, and memory; it implements nothing.

Parallel mode has two runtimes: an **agent team** (preferred when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set) and **background subagents** (fallback). Teams add per-teammate token cost, so they pay off only when lanes are genuinely independent and benefit from shared task state or peer messaging — for two small lanes, background subagents are usually enough.

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

Columbus is not a live board — lane status (in progress, blocked, done) lives in the session (or the team's shared task list). Fold lane assignments into the plan memory body only when they must survive the session:

```sh
columbus memory update mem_12 \
  --body "<plan body noting: lane A = steps 1-2 on branch feat/a, lane B = step 3 on branch feat/b>"
```

### As an agent team (preferred)

Create one team for the whole parallel flow; the coordinator session is the team lead.

- Put every lane's steps on the shared task list with their dependencies — tasks unblock automatically when a dependency completes, and claiming is race-safe. The task list and team config live outside the project (`~/.claude/tasks/<team>/`, `~/.claude/teams/<team>/`); they are the shared state for the team. Do not hand-roll status files alongside them, and never edit or pre-author the team config — it is runtime state.
- Spawn one teammate per lane from this plugin's agent definitions (e.g. `delivery-engineer`): the definition's `tools` and `model` are honored and its body is appended to the teammate's prompt. The `skills` frontmatter is **not** applied to teammates, so the spawn prompt must name the mastering skill to load (`columbus-workflow:mastering-golang`, `-typescript`, or `-design`).
- Spawn prompts must be self-contained: teammates load project context (CLAUDE.md, skills, MCP) but not the lead's conversation history. Include the lane's plan excerpt, acceptance criteria, owned files, and do-not-touch areas.
- Teammates persist for the lane's lifetime. Revision rounds, scope corrections, and follow-ups are messages to the existing teammate — never a respawn. Teammates notify the lead when idle and self-claim the next unblocked task; teammates may message each other directly when one lane's facts matter to another (a landed interface, a renamed symbol), but gate decisions and the merge stay with the lead.
- For risky lanes, require plan approval: the teammate works read-only in plan mode until the lead approves its approach.
- Constraints: one team per session; no nested teams (teammates cannot spawn teammates, so gate agents on the merged result are deployed by the lead); `/resume` does not restore in-process teammates. Shut teammates down when their lane closes, and only the lead runs team cleanup, after all teammates are down.

### As background subagents (fallback)

Without agent teams, deploy each lane's `delivery-engineer` once with a name and `run_in_background: true`, track lane status in the session, and send follow-ups to the same agent via `SendMessage`. Lanes report JSON to the coordinator as below.

## Branch And Worktree Strategy

Use separate branches or worktrees when agents will edit concurrently:

- one worktree per editing lane (deploy the lane's agents with `isolation: "worktree"`) — the default for parallel implementation; with `worktree.baseRef` set to `"head"` each worktree branches from local HEAD and sees in-progress work
- one branch per lane for independent PR-ready slices
- same branch only for read-only analysis agents or strictly non-overlapping serial edits

## Agent Communication

The active session coordinates all lanes. In subagent form, agents do not coordinate directly — shared facts travel through the coordinator's briefs. In team form, peer messages are allowed for cross-lane facts, but every gate decision still flows through the lead.

Each lane gets a scoped brief:

- the plan scope it owns (and the parent plan id)
- branch or worktree
- owned files or subsystem
- do-not-touch areas
- relevant memory findings (ADRs, documentation)
- the mastering skill to load when the lane touches code
- model to use (per the ship skill model table)

Agents report back with JSON:

```json
{ "status": "done" | "partial" | "blocked", "cause": "<short phrase>", "risks": ["<label>"] }
```

The coordinator reads JSON status and risk labels — never the raw diff. Diff reading belongs to gate agents (quality-reviewer, test-engineer, security-analyst, architecture-reviewer), which fetch the diff themselves. Do not rely on chat-only context for facts another lane needs — put shared facts in the briefs.

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

1. Collect each lane JSON report.
2. Check branch status (git commands are the coordinator's).
3. Merge or apply changes one lane at a time.
4. Resolve code conflicts by dispatching a `delivery-engineer` (model: sonnet) briefed with both lanes' JSON reports — the coordinator does not hand-edit conflicting source.
5. Run combined verification (`test-engineer`, model: sonnet, on the merged result).
6. Run final quality (`quality-reviewer`, model: sonnet), security (`security-analyst`, model: sonnet), and architecture (`architecture-reviewer`, model: opus) gates on the merged result.

## Closeout

Only after all lanes are merged and verified together:

1. Record decisions as `adr`, anchored with tags, links, and evidence. Add `documentation` only when a process or behavior genuinely needs explaining — written fresh, never converted from the plan.
2. Remove the executed plan: `columbus memory remove mem_12`.
3. If a lane failed or was deferred, update the plan memory body with what remains and why, so the next session can resume.
4. Capture discovered follow-up work as a new `plan` memory.
