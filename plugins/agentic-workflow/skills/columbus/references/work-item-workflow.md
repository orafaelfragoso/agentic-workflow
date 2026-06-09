# Work Item Workflow

Use this reference when teaching how agents should work with Columbus epics, stories, and tasks.

## Core Rule

Agents must keep work status current. Before starting implementation work, claim the specific task with `in_progress`. While working, add useful comments. If blocked, mark the task `blocked` with the reason. When verified, mark it `done`.

## Hierarchy

Columbus work items are hierarchical:

- `epic`: larger outcome or initiative.
- `story`: user-visible slice under an epic.
- `task`: concrete implementation step under a story.

Tasks are the normal unit an agent claims. Stories and epics are parent containers that move forward as their child work moves forward.

## Status Values

Work kinds support these statuses:

- `todo`: not started.
- `in_progress`: actively being worked.
- `blocked`: cannot continue without a decision, dependency, or external change.
- `done`: completed and verified.
- `cancelled`: intentionally abandoned.

## Before Starting Work

1. Inspect the assigned task or find the next task:
   ```sh
   columbus memory list task --status todo --llm
   columbus show task task_123 --llm
   ```

2. If the task is already `in_progress`, do not silently steal it. Check history/comments and report the conflict.

3. Move the task to `in_progress` before editing files or running implementation commands:
   ```sh
   columbus memory update task task_123 \
     --status in_progress \
     --comment "Started work on <short plan or scope>."
   ```

4. If this is the first active child under a story or epic, move the parent to `in_progress` too:
   ```sh
   columbus memory update story story_123 \
     --status in_progress \
     --comment "Work started via task_123."

   columbus memory update epic epic_123 \
     --status in_progress \
     --comment "Work started via story_123."
   ```

Only update parent status when you have enough context to know the parent is not already active or complete.

## During Work

Add comments for meaningful progress, discoveries, and scope changes:

```sh
columbus memory update task task_123 \
  --comment "Found validation lives in internal/api/validate.go; implementation will update the shared validator."
```

Keep comments durable and useful. Do not log every command.

## When Blocked

Mark the task blocked as soon as progress cannot continue:

```sh
columbus memory update task task_123 \
  --status blocked \
  --comment "Blocked: API error shape is undecided; need product decision on field naming."
```

If a parent story is blocked because all viable child work is blocked, update the story too:

```sh
columbus memory update story story_123 \
  --status blocked \
  --comment "Blocked by task_123: API error shape needs decision."
```

Do not mark an epic blocked unless the whole initiative is blocked.

## When Done

Only mark a task done after the requested deliverable is complete and verification has run or been explicitly skipped.

```sh
columbus memory update task task_123 \
  --status done \
  --comment "Done: implemented validator update and verified with `go test ./...`."
```

If the task produced durable code evidence, add references when useful:

```sh
columbus memory update task task_123 \
  --add-ref file:internal/api/validate.go \
  --add-ref symbol:ValidateRequest
```

Before marking a story done, list child tasks and confirm none remain `todo`, `in_progress`, or `blocked`:

```sh
columbus memory list task --parent story_123 --llm
columbus memory update story story_123 \
  --status done \
  --comment "Done: all child tasks completed and verified."
```

Before marking an epic done, list child stories and confirm the whole outcome is complete:

```sh
columbus memory list story --parent epic_123 --llm
columbus memory update epic epic_123 \
  --status done \
  --comment "Done: all stories completed."
```

## When Scope Changes

If new work is discovered, prefer adding a child task under the current story instead of hiding it in a comment:

```sh
columbus memory add task \
  --parent story_123 \
  --title "Add regression coverage for validator edge cases" \
  --body "Cover missing empty-field and malformed-payload cases found while completing task_123."
```

If the discovered work is outside the current story, add a comment and ask the coordinator or user before expanding scope.

## Agent Checklist

- [ ] Read the task and relevant parent context before starting.
- [ ] Move the task to `in_progress` before implementation.
- [ ] Move story or epic parents to `in_progress` only when appropriate.
- [ ] Add comments for meaningful progress, blockers, and verification.
- [ ] Mark blocked work as `blocked` with a clear reason.
- [ ] Mark tasks `done` only after verification.
- [ ] Mark stories and epics `done` only after child work is complete.
- [ ] Add new child tasks for discovered work instead of silently widening scope.
