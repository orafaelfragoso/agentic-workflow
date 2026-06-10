# Retrieval Workflows

The main rule is locate first, read second. Search returns locations, signatures, scores, relevance notes, and graph hints. Read bodies only when the implementation body is necessary.

## Pointed Code Question

Use this for questions like "where are credentials verified?"

```sh
columbus search "how credentials are verified" --kind code --llm --limit 10
columbus show symbol VerifyCredentials --llm --snippet-lines 20
```

Teach the user to stop after the search if the ranked results already answer the question.

## Architecture Survey

Use a few distinct search angles plus one graph projection.

```sh
columbus search "application entry points and request flow" --kind code --llm --limit 15
columbus search "core abstractions and domain boundaries" --kind code --llm --limit 15
columbus search "main data flows and pipelines" --kind code --llm --limit 15
columbus graphs --llm --max 40
```

Do not drill into every symbol just to confirm citations. The search projection already includes locations.

## Dependency Or Blast-Radius Question

Use graph projection when imports, imported-by relationships, or test coverage shape matter. Filter with `--in` (path substring), `--lang`, or `--role impl|test`.

```sh
columbus search "payment processing service" --kind code --llm --limit 10
columbus graphs --llm --in payment --depth 1 --max 50
```

## Decision Or Memory Question

Search memory when the answer depends on recorded ADRs, plans, or documentation.

```sh
columbus search "why local embeddings are used" --kind memory --llm
columbus memory list --kind adr --llm
columbus show memory mem_12 --llm
```

## When To Use Snippets

Use `--snippets` only when a bounded body is needed for the answer.

```sh
columbus search "normalise user input" --kind code --llm --snippets --snippet-lines 20 --limit 5
```

Prefer `show symbol` for one chosen implementation over broad snippet searches.

## Common Mistakes

- Running many near-duplicate searches instead of one richer query.
- Using `--snippets` for broad surveys.
- Reading raw files after Columbus already returned exact locations.
- Running `graphs` for simple "where is this?" questions.
- Listing all memories when a scoped `search --kind memory` or `memory list --kind/--tag` filter is enough.
