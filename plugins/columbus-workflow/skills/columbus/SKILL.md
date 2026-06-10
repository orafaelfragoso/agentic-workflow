---
name: columbus
description: Teaches how Columbus CLI works as a local semantic code-context and durable memory system, with references for commands, retrieval, memory (adr, plan, documentation), setup, and agent usage. Use when the user asks how Columbus works, wants to learn Columbus, needs Columbus command examples, asks about search, indexing, memory, ADRs, plans, documentation memories, navigator usage, or says "teach me Columbus".
---

# Columbus

Teach Columbus as a local code-context system. The expected output is an explanation, lesson, walkthrough, or answer grounded in the bundled references and current CLI help.

## Teaching Workflow

1. **Identify the lesson goal**
   - If the user asks a broad question, start with the mental model.
   - If they ask about a command, workflow, or failure mode, load the matching reference.
   - Ask a clarifying question only when the user wants a hands-on action that may write, delete, import, export, or reindex data.

2. **Explain the core model first**
   - Columbus has an indexed code layer for locating code and a durable memory layer for recorded knowledge.
   - `search`, `show`, and `graphs` retrieve code context.
   - `memory` records durable knowledge in three kinds: `adr` (decisions), `plan` (intended work), and `documentation` (how things work).
   - Memories carry tags, links to files/symbols, and line-range evidence; `memory validate` detects drift.
   - `--llm` returns compact markdown for agents; `--json` returns machine-readable data.

3. **Teach with a reference**
   - For the high-level model, read `references/mental-model.md`.
   - For command syntax and flags, read `references/command-reference.md`.
   - For codebase exploration workflows, read `references/retrieval-workflows.md`.
   - For the durable memory kinds, tags, links, evidence, and validation, read `references/memory-model.md`.
   - For installation, reindexing, export/import, and maintenance, read `references/setup-and-maintenance.md`.
   - For using Columbus with agents and `navigator`, read `references/agent-usage.md`.

4. **Verify live command details when needed**
   - For exact flags, run `columbus <command> --help` before teaching.
   - Prefer local CLI help over remembered syntax.
   - Do not run mutating commands such as `install`, `reindex`, `memory add`, `memory update`, `memory remove`, `import`, `purge`, or `uninstall` unless the user explicitly asks.

5. **Use examples**
   - Pair each concept with one command example.
   - Prefer locate-first examples: `search --llm`, then `show` or `graphs` only when needed.
   - Explain when not to use an expensive option such as `--snippets`.

6. **Close with a check**
   - Summarize the concept in two or three sentences.
   - Offer one small exercise or next command the user can run.

## Validation

- [ ] The answer teaches rather than silently performing setup.
- [ ] Any exact command syntax was checked against `--help` when uncertain.
- [ ] The relevant reference file was used.
- [ ] Mutating or destructive commands were not run without explicit user intent.
- [ ] The explanation distinguishes the code index, the memory layer (adr, plan, documentation), and output modes.
