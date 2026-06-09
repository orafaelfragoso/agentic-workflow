---
name: interview
description: Interview session that interrogates your plan against the project's domain model and recorded decisions, sharpens terminology, and records or updates Columbus memory (glossary terms, decisions, gotchas) inline as the plan crystallises. Use when the user wants to stress-test or interview a plan against the codebase's language and documented decisions, or says "interview me", "grill my plan", or "challenge this design".
---

# Interview

Interview the user's plan against the project's existing language and documented decisions, then capture what crystallises in Columbus memory.

## Quick start

Interview the user relentlessly about every aspect of the plan until you reach shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. Ask **one question at a time**, recommend an answer, and wait for feedback before continuing.

If a question can be answered by exploring the codebase or existing memory, explore instead of asking — `columbus search <query>` for code + memory, `columbus search <query> --kind memory` for memory only.

## Workflow

### 1. Preconditions

Confirm Columbus is set up before relying on memory:

```sh
columbus doctor        # verifies CLI, .columbus.json, and a built index
```

If `.columbus.json` is missing or the index is empty, stop and tell the user to run the `/columbus` skill first — without an index, code cross-referencing and memory are unavailable.

### 2. Load durable context

```sh
columbus memory list context --tag global --llm    # project-wide truths (load every session)
columbus memory list context --type glossary --llm  # the glossary
columbus memory list context --type decision --llm  # recorded decisions
```

Reuse existing context tags instead of inventing near-duplicates (`orders` vs `ordering`). List every tag in use with `columbus memory list tag`, or probe a candidate: `columbus memory list context --tag <candidate>` returns `0` if unused. When genuinely unsure which context a term belongs to, ask.

### 3. Interview

Run these moves throughout the interview:

- **Challenge against the glossary** — when a term conflicts with existing `glossary` memory, call it out: "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?" Verify with `columbus search cancellation --kind memory`.
- **Sharpen fuzzy language** — when a term is vague or overloaded, propose a precise canonical one: "You're saying 'account' — Customer or User? Those differ."
- **Discuss concrete scenarios** — stress-test domain relationships with invented edge cases that force precision about boundaries between concepts.
- **Cross-reference with code** — when the user states how something works, check the code agrees with `columbus search <query> --snippets`. Surface contradictions: "Your code cancels entire Orders, but you said partial cancellation is possible — which is right?"

### 4. Record memory inline — update, never duplicate

Capture as decisions crystallise; don't batch. **Always search first.** If a memory already covers the term/decision, `columbus memory update context <id>` it (refine the definition, revise the decision, append a consequence). Only `add` when nothing covers it yet.

Scope every memory with a tag. Reserve `--tag global` for context that should load on **every** session (broad, project-wide truths). Feature- or context-specific memory gets the relevant context tag, not `global`.

**Glossary term** — a pure definition, devoid of implementation detail; not a spec or scratch pad.

```sh
columbus search "<term>" --kind memory          # exists? update it
columbus memory update context <id> --body "<refined definition>"
# else:
columbus memory add context --type glossary --title "<Term>" \
  --body "<precise definition. note what it is NOT if it was being confused>" \
  --tag <scope>
```

**Decision** — record only when all three hold: (1) **hard to reverse**, (2) **surprising without context**, (3) **the result of a real trade-off**. If any is missing, skip it. Search for a prior decision on the same ground first; if the plan revises an earlier call, `edit` it and note the change in consequences rather than adding a contradictory second decision. Anchor it to the code it governs so it stays verifiable.

```sh
columbus memory add context --type decision --title "<decision title>" \
  --body "Decision: <what>. Context: <forces>. Alternatives: <rejected>. Consequences: <trade-off>." \
  --evidence <path>:<start>-<end> --ref symbol:<name> --tag <scope>
```

**Gotcha** — when the interview surfaces a non-obvious trap ("that breaks because X"), capture it as a `failure`-kind memory so the next session doesn't relearn it the hard way.

```sh
columbus memory add context --type failure --title "<trap>" \
  --body "<what breaks and why; the safe path>" --tag <scope>
```

### 5. Close out

After the interview, offer to capture the agreed plan as structured work. If the user accepts, invoke the **`triage`** skill — it turns the plan into a full epic→story→task breakdown, linked to the decision memories captured here. Hand it the agreed plan and the `mem_NNN` ids you recorded.

Drift is surfaced automatically: `columbus memory list context` / `columbus show memory <id>` flag evidence anchors that have moved away from the code, so re-check the decisions you anchored.
