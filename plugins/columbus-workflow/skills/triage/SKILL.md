---
name: triage
description: Processes the Columbus plan backlog — reads every rough plan memory, clusters them by theme, runs a full interview per cluster, then consolidates each cluster into one refined, execution-ready plan memory and deletes the consumed items. Use when the user wants to triage, groom, or process the backlog, work through rough plans, or says "triage", "triage the backlog", "groom the backlog", or "process backlog".
---

# Triage

Turns loose `plan` memories into execution-ready plans. Rough plan memories are scrum-style inbox items: triage clusters them by theme, interviews each cluster to settle scope, consolidates each cluster into one refined plan, then clears the items it consumed.

## Quick start

Collect rough plans → group by theme → for each group: full interview, then one refined plan → delete the consumed items → report.

## Workflow

### 1. Preconditions

```sh
columbus doctor      # verify CLI, .columbus.json, and a built index
```

If Columbus isn't initialised, stop and tell the user to run `/columbus` first.

### 2. Collect the backlog

```sh
columbus memory list --kind plan --llm
```

If empty, say so and stop — nothing to triage. Show the user every plan found; rough, overlapping, or stale ones are triage input, while plans already refined and in execution stay untouched (confirm which is which with the user when unclear).

### 3. Group by theme

Cluster the items by what they're _about_ — the feature or area they touch — not by tag. Use `columbus search "<intent>" --llm` to find the code and related memory each item points at; items that converge on the same area form one group. Tags inform the grouping but don't dictate it. A group is one coherent body of work that will become one plan.

Show the user the proposed groups (which `mem_NNN` ids fall in each, and the theme) and let them adjust before interviewing.

### 4. Per group: interview, then consolidate

Process one group at a time. For each:

**a. Interview.** Run the full **interview** flow (see the `interview` skill) scoped to this group's items — one question at a time, recommend an answer, wait. Sharpen terminology, stress-test boundaries, cross-reference code, and record `adr`/`documentation` memory inline as decisions crystallise. Capture the `mem_NNN` ids of recorded decisions.

**b. One refined plan.** Consolidate the group into a single execution-ready plan memory:

```sh
columbus memory add plan --title "<deliverable>" \
  --body "Goal: <outcome>. Approach: <agreed shape>. Out of scope: <what it is NOT>.

Steps:
1. <step — done when: <observable outcome>>
2. <step — depends on: <prior step>>
...

Acceptance: <how the whole deliverable is verified>." \
  --tag <scope>
columbus memory update <plan_id> \
  --link symbol:<KeySymbol> --link file:<path> \
  --evidence <path>:<start>-<end>
```

The body carries the whole work breakdown: goal, ordered steps with done-conditions and dependencies, and acceptance criteria. Anchor the plan to the code it touches with links and evidence, and mention the ADR ids from the interview in the body so the work stays traceable.

### 5. Clear the consumed memories

Once a group is captured as one refined plan, hard-delete the rough items it consumed:

```sh
columbus memory remove <id>
```

Delete every rough plan that fed the group. Do this only after the refined plan exists and covers them.

### 6. Report

For each group: the theme, the refined plan id and title, the ADR ids recorded during the interview, and the `mem_NNN` items deleted. Confirm the remaining plan list is clean:

```sh
columbus memory list --kind plan --llm
```

Refined plans are picked up by the `ship` skill for execution.
