# Columbus Command Reference

Use `columbus <command> --help` for exact live syntax. The command groups below describe the current surface.

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

- `columbus search <query>`: search code and memories for context.
- `columbus show symbol <name>`: show symbol definitions.
- `columbus show file <path>`: show a file outline and graph.
- `columbus show memory <id>`: show one memory.
- `columbus graphs`: project the indexed dependency graph.

Useful examples:

```sh
columbus search "where requests enter the system" --llm --limit 10
columbus search "token verification" --kind code --llm
columbus search "auth decision" --kind memory --llm
columbus show symbol VerifyToken --llm --in auth --snippet-lines 20
columbus show file internal/auth/service.go --llm
columbus graphs --llm --in auth --depth 1 --max 40
```

## Memory And Work Items

`columbus memory` manages durable knowledge. Kinds are `epic`, `story`, `task`, `context`, and `tag`.

```sh
columbus memory list context --llm
columbus memory list context --type decision --llm
columbus memory add context --type decision --title "Use local embeddings" --body "..." --tag global
columbus memory update context mem_123 --body "Updated decision text"
columbus memory remove context mem_123 --force
```

## Import, Export, And Dashboard

- `columbus export`: export project knowledge as JSON. Vectors are not exported.
- `columbus import`: import knowledge JSON.
- `columbus view`: open the interactive dashboard.

```sh
columbus export --out columbus-knowledge.json
columbus import columbus-knowledge.json
columbus view
```

## Destructive Commands

Do not run these during teaching unless explicitly requested:

```sh
columbus purge
columbus uninstall
columbus memory remove <kind> <id> --force
```

## Global Flags

- `--llm`: LLM-oriented markdown projection.
- `--json`: machine-readable JSON.
- `--limit <n>`: cap result lists.
- `--no-color`: disable ANSI color.
- `--depth <n>`: graph traversal depth for graph commands.
