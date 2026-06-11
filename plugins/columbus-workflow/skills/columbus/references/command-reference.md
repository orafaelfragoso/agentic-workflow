# Columbus Command Reference

Use `columbus <command> --help` for exact live syntax. The command groups below describe the current surface (v0.3.x).

## Project Health And Indexing

- `columbus doctor`: diagnose environment and project health.
- `columbus install`: write `.columbus.json`, create the project database, then index and embed the repository.
- `columbus reindex`: update the index after code changes.
- `columbus version`: print version information.

Useful examples:

```sh
columbus doctor
columbus install
columbus install --no-embed
columbus reindex --status
columbus reindex --changed
columbus reindex --full
```

## Retrieval

- `columbus search <query>`: search code and memories for context. `--kind code|memory|all` scopes the search (default `all`).
- `columbus show symbol <name>`: show all definitions of a symbol; `--in <substring>` narrows by path.
- `columbus show file <path>`: show a file outline and graph.
- `columbus show memory <id>`: show one memory by id (`mem_NNN`).
- `columbus graphs`: project the indexed file dependency graph; filter with `--in <substring>`, `--lang <language>`, `--role impl|test|...`, cap with `--max`.

Useful examples:

```sh
columbus search "where requests enter the system" --llm --limit 10
columbus search "token verification" --kind code --llm
columbus search "auth decision" --kind memory --llm
columbus show symbol VerifyToken --llm --in auth --snippet-lines 20
columbus show file internal/auth/service.go --llm
columbus show memory mem_12 --llm
columbus graphs --llm --in auth --depth 1 --max 40
```

## Memory

`columbus memory` manages the durable memory layer. `<kind>` is one of `adr`, `plan`, `documentation`. Memories carry tags (repeatable `--tag`), links (`--link file:<path>` or `--link symbol:<name>`), and evidence line ranges (`--evidence path:start-end`).

```sh
columbus memory list --llm
columbus memory list --kind adr --llm
columbus memory list --kind documentation --tag auth --llm
columbus memory add adr --title "Use local embeddings" --body "..." --tag infra
columbus memory add documentation --title "Search projection" --body "..." \
  --link file:internal/search/projector.go --evidence internal/search/projector.go:24-67
columbus memory update mem_12 --body "Updated text" --add-tag search
columbus memory update mem_12 --kind documentation   # re-kind a misfiled memory
columbus memory validate
columbus memory remove mem_12
```

`memory validate` checks every memory for evidence drift (line ranges that no longer match the code) and unresolvable links. `memory remove` is a hard delete and the id is retired.

## Import, Export, And Dashboard

- `columbus export`: export the memory layer (with tags, links, evidence) as portable JSON. Vectors are not exported; reindex rebuilds them.
- `columbus import [path]`: import knowledge JSON from a path or stdin; `--preserve-ids` restores original ids (errors on collision).
- `columbus view`: open the interactive dashboard (index freshness, embeddings, memory).

```sh
columbus export --out columbus-knowledge.json
columbus import columbus-knowledge.json
columbus import columbus-knowledge.json --preserve-ids
columbus view
```

## Destructive Commands

Do not run these during teaching unless explicitly requested:

```sh
columbus purge --yes        # drop all records, reset config (files stay)
columbus uninstall --yes    # remove config and the project database
columbus memory remove <id> # hard delete one memory
```

`purge` and `uninstall` prompt for confirmation on a TTY; `--yes` is required when not a TTY.

## Global Flags

- `--llm`: LLM-oriented markdown projection.
- `--json`: machine-readable JSON.
- `--limit <n>`: cap result lists (search, memory list; default 15).
- `--depth <n>`: graph traversal depth (graphs; 0 = direct only).
- `--no-color`: disable ANSI color.
