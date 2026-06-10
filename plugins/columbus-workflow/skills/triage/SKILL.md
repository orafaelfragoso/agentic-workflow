---
name: triage
description: Processes the Columbus backlog — reads every backlog memory, clusters them by theme, runs a full interview per cluster, then turns each cluster into a full epic→story→task breakdown and deletes the consumed items. Use when the user wants to triage, groom, or process the backlog, work through the memory backlog, or says "triage", "triage the backlog", "groom the backlog", or "process backlog".
---

# Triage

Turns the loose `backlog` into structured work. Each backlog memory is a scrum-style inbox item: triage clusters them by theme, interviews each cluster to settle scope, builds the epic→story→task tree, then clears the items it consumed. This skill replaces the former `to-epic` and `to-tasks` skills — it owns the whole backlog-to-work path.

## Quick start

Collect backlog items → group by theme → for each group: full interview, then epic→story→task → delete the consumed items → report.

## Workflow

### 1. Preconditions

```sh
columbus doctor      # verify CLI, .columbus.json, and a built index
```

If Columbus isn't initialised, stop and tell the user to run `/columbus` first.

### 2. Collect the backlog

```sh
columbus memory list context --type backlog --llm
```

If empty, say so and stop — nothing to triage.

### 3. Group by theme

Cluster the items by what they're _about_ — the feature or area they touch — not by tag. Use `columbus search "<intent>" --llm` to find the code and related memory each item points at; items that converge on the same area form one group. Tags inform the grouping but don't dictate it. A group is one coherent body of work that will become one epic.

Show the user the proposed groups (which `mem_NNN` ids fall in each, and the theme) and let them adjust before interviewing.

### 4. Per group: interview, then build the tree

Process one group at a time. For each:

**a. Interview.** Run the full **interview** flow (see the `interview` skill) scoped to this group's items — one question at a time, recommend an answer, wait. Sharpen terminology, stress-test boundaries, cross-reference code, and record glossary/decision/gotcha memory inline as it crystallises. Capture the `mem_NNN` decision ids.

**b. Epic.** One epic per group — the large body of work the group describes.

```sh
columbus memory add epic --title "<deliverable>" \
  --body "Goal: <outcome>. Approach: <agreed shape>. Out of scope: <what it is NOT>." \
  --tag <scope>
columbus memory update epic <epic_id> \
  --add-ref memory:mem_NNN --add-ref symbol:<KeySymbol> --add-ref file:<path>
```

Link the decisions from the interview and the source backlog items (`--add-ref memory:<id>`) so the work stays traceable.

**c. Stories.** Carve the epic into the smallest set of coherent slices, in execution order. Inherit the epic's tag.

```sh
columbus memory add story --parent <epic_id> --title "<slice>" \
  --body "Goal: <what this slice delivers>." --tag <scope>
```

**d. Tasks.** Break each story into ordered, single-iteration steps. Each task body states what "done" looks like; note blockers. Anchor where it applies.

```sh
columbus memory add task --parent <story_id> --title "<step>" \
  --body "Done when: <observable outcome>. Depends on: <prior step, if any>." --tag <scope>
columbus memory update task <task_id> \
  --add-ref symbol:<Symbol> --add-ref file:<path> --add-ref memory:mem_NNN
```

Every group goes all the way to tasks. Leave statuses at `todo`.

### 5. Clear the consumed memories

Once a group's backlog items are captured as work and linked via `memory:` refs, hard-delete them — the backlog item is resolved:

```sh
columbus memory remove context <id> --force
```

Delete every backlog item that fed the group. Do this only after the epic tree exists and references them.

### 6. Report

For each group: the theme, the epic→story→task ids and titles created, and the `mem_NNN` items deleted. Confirm the backlog is clear:

```sh
columbus memory list context --type backlog --llm
```
