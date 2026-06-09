# Memory Model

Columbus memory is the durable knowledge layer. It preserves project facts and work structure across sessions.

## Kinds

`columbus memory` has five top-level kinds:

- `context`: durable project knowledge.
- `epic`: larger body of planned work.
- `story`: user-visible slice under an epic.
- `task`: concrete implementation step under a story.
- `tag`: labels used to group and filter knowledge.

## Context Types

`context` memories use `--type`:

- `glossary`: project terms and definitions.
- `decision`: decisions and rationale.
- `pattern`: recurring implementation or architecture pattern.
- `failure`: gotchas, traps, and known failure modes.
- `command`: lifecycle commands and operational recipes.
- `backlog`: loose inbox item before triage.

Example:

```sh
columbus memory add context --type decision \
  --title "Use locate-first retrieval" \
  --body "Agents should search first, then inspect only the few relevant symbols." \
  --tag global
```

## References And Evidence

Use references for entities that relate to code or symbols:

```sh
columbus memory add context --type pattern \
  --title "Result projection pattern" \
  --body "Search results are projected into compact LLM-ready records." \
  --ref file:internal/search/projector.go \
  --ref symbol:ProjectSearchResult
```

Use evidence for exact line ranges:

```sh
columbus memory update context mem_123 \
  --add-evidence internal/search/projector.go:24-67
```

## Tags

Use tags to control loading and grouping:

- `global`: project-wide facts worth loading at session start.
- Feature or subsystem tags: `auth`, `search`, `billing`, `cli`.
- Avoid near-duplicates such as `auth` and `authentication` unless they mean different things.

## Work Items

Epics, stories, and tasks form a hierarchy:

```sh
columbus memory add epic --title "Improve retrieval workflow" --body "..."
columbus memory add story --parent epic_123 --title "Teach locate-first search" --body "..."
columbus memory add task --parent story_123 --title "Add examples" --body "..."
columbus memory update task task_123 --status in_progress --comment "Started reference rewrite"
```

Statuses for work kinds include `todo`, `in_progress`, `blocked`, `done`, and `cancelled`.

For the agent protocol around claiming, updating, blocking, and completing work items, read `work-item-workflow.md`.

## Teaching Principle

Memory is not a transcript. Teach users to store durable facts: definitions, decisions, patterns, failures, commands, and structured work. Short focused entries age better than one large catch-all memory.
