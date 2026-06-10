# Setup And Maintenance

Use this reference when teaching installation, indexing, and lifecycle operations.

## Install

`columbus install` sets up the current directory:

- writes `.columbus.json`
- creates the project database
- indexes code
- creates embeddings unless `--no-embed` is used

```sh
columbus install
columbus install --no-embed
```

## Check Health

Use `doctor` before diagnosing unexpected behavior:

```sh
columbus doctor
```

## Reindex

Use `reindex` after code changes:

```sh
columbus reindex --status
columbus reindex --changed
columbus reindex --full
columbus reindex --clean
```

Meanings:

- `--status`: report index state without writing.
- `--changed`: fast path for dirty working-tree files.
- `--full`: rebuild the full index, preserving memories.
- `--clean`: drop index data while preserving config and memories.
- `--no-embed`: skip embeddings and keep a metadata-only index.

## Export And Import

Export durable knowledge to JSON. Vectors are not exported; reindex rebuilds them.

```sh
columbus export --out columbus-knowledge.json
columbus import columbus-knowledge.json
columbus import columbus-knowledge.json --preserve-ids
```

## Dashboard

Use the dashboard for visual inspection:

```sh
columbus view
```

## Destructive Maintenance

These are destructive or high-impact commands:

```sh
columbus purge
columbus uninstall
columbus memory remove <kind> <id> --force
```

Only run them after explicit user intent. When teaching, describe their effect and ask before executing.

## Lightweight Onboarding Lesson

If the user wants to understand how to onboard a repo:

1. Run `columbus doctor`.
2. Run `columbus install`.
3. Search for entry points and core abstractions with `search --llm`.
4. Add only durable findings to `context` memory.
5. Tag project-wide facts with `global`.
