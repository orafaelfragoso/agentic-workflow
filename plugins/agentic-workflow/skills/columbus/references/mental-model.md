# Columbus Mental Model

Columbus is a local-only semantic code-context system. It indexes the current repository, builds searchable projections of files and symbols, and keeps durable project knowledge in a memory layer.

## The Two Layers

1. **Indexed code context**
   - Built by `columbus install` and refreshed by `columbus reindex`.
   - Stores file chunks, symbol metadata, semantic embeddings, and dependency graph information.
   - Queried with `search`, `show`, and `graphs`.

2. **Durable knowledge**
   - Managed with `columbus memory`.
   - Stores context memories, epics, stories, tasks, tags, references, and evidence.
   - Exported and imported with `columbus export` and `columbus import`.

## The Retrieval Loop

Use Columbus as a locator first and a reader second:

1. Search for the intent:
   ```sh
   columbus search "how authentication tokens are verified" --llm --limit 10
   ```
2. Inspect only the few relevant targets:
   ```sh
   columbus show symbol VerifyToken --llm --snippet-lines 20
   ```
3. Use graphs only when dependencies or blast radius matter:
   ```sh
   columbus graphs --llm --in auth --depth 1 --max 40
   ```

## Output Modes

- Plain text: useful for humans in a terminal.
- `--llm`: compact markdown projection for agents and chat.
- `--json`: machine-readable output for scripts.

## How To Explain It

Use this short version:

> Columbus gives an agent a grounded map of a repository. Search finds likely files and symbols, show reads focused details, graphs explain dependency shape, and memory preserves project decisions and work context between sessions.
