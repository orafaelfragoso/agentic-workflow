# Memory Model

Columbus memory is the durable knowledge layer. It preserves project decisions, plans, and explanations across sessions, anchored to code with links and evidence.

## Kinds

`columbus memory` has exactly three kinds:

- `adr`: an architecture decision record — a decision made, its rationale, and its consequences. Durable; supersede with a new ADR rather than rewriting history.
- `plan`: intended future work — a design, migration, or implementation plan that has not fully happened yet. Plans age out: remove them when executed; record anything durable as a fresh `adr` or `documentation` memory instead of converting the plan.
- `documentation`: how something currently works — subsystem explanations, patterns, gotchas, operational recipes, glossary-style definitions.

Choosing a kind: "we chose X over Y because…" is an `adr`; "we are going to…" is a `plan`; "this is how X works / beware of Y" is `documentation`.

Example:

```sh
columbus memory add adr \
  --title "Use locate-first retrieval" \
  --body "Agents search first, then inspect only the few relevant symbols. Chosen over eager file reading to keep context small." \
  --tag retrieval
```

## Tags, Links, And Evidence

Every memory can carry three kinds of anchors:

- **Tags** (`--tag`, repeatable): group and filter. Use subsystem or feature names (`auth`, `search`, `cli`). Avoid near-duplicates such as `auth` and `authentication` unless they mean different things. Filter with `memory list --tag auth`.
- **Links** (`--link`, repeatable): connect a memory to code entities — `--link file:internal/search/projector.go` or `--link symbol:ProjectSearchResult`.
- **Evidence** (`--evidence`, repeatable): exact line ranges that ground a claim — `--evidence internal/search/projector.go:24-67`.

```sh
columbus memory add documentation \
  --title "Result projection pattern" \
  --body "Search results are projected into compact LLM-ready records." \
  --link file:internal/search/projector.go \
  --link symbol:ProjectSearchResult \
  --evidence internal/search/projector.go:24-67
```

## Updating

`memory update <id>` is partial: pass only the fields to change. Anchors use add/remove pairs, and `--kind` re-kinds a memory that was filed under the wrong kind (do not use it to convert an executed `plan` into `documentation` — remove the plan and write documentation fresh if it's warranted):

```sh
columbus memory update mem_12 --body "Updated explanation" --add-tag search
columbus memory update mem_12 --add-evidence internal/search/projector.go:24-67
columbus memory update mem_12 --remove-link symbol:OldName --add-link symbol:NewName
columbus memory update mem_12 --kind documentation
```

## Validation

Code moves; memories do not. `columbus memory validate` checks every memory for evidence drift (line ranges that no longer match the indexed code) and links that no longer resolve. Run it after large refactors or before trusting old memories, then fix drifted entries with `memory update`.

```sh
columbus memory validate
```

## Removal

`memory remove <id>` is a hard delete and the id is retired. Prefer updating over deleting for `adr` and `documentation`; plans are the exception — remove them once executed, abandoned, or duplicated.

## Retrieval

Memories are embedded and searchable alongside code:

```sh
columbus search "why local embeddings" --kind memory --llm
columbus memory list --kind adr --llm
columbus show memory mem_12 --llm
```

## Teaching Principle

Memory is not a transcript. Store durable facts: decisions with rationale (`adr`), intended work (`plan`), and current behavior or gotchas (`documentation`). Short focused entries with links and evidence age better than one large catch-all memory.
