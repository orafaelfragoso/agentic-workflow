# Plan Lifecycle — keeping Columbus plan memory alive

The advisor's job doesn't end at the plan. Plans age: code drifts under them, executors finish or stall, findings get fixed in passing. The `reconcile` variant processes what happened since the last session so the plan memory stays trustworthy.

The founding rule survives unchanged: **the advisor never edits source code.** Reconciling touches only Columbus memory.

## Lifecycle of a plan memory

Columbus's memory model is the guide: plans are intended future work, and **plans age out — remove them when they're no longer future work.**

- **Written** → `columbus memory add plan`, tagged `improve` + category, anchored with links and evidence.
- **Executed and verified** → `columbus memory remove mem_NN`. Do not convert the plan into a `documentation` memory — plans describe intent, not reality, and a rewritten plan makes poor documentation. If the shipped work left a process or behavior that genuinely needs explaining, write a fresh `documentation` memory (or `adr` for the decision) anchored to the landed code; otherwise record nothing.
- **Blocked** → update the body with the blocker and what was learned — a one-line `BLOCKED: <reason>` near the top of the body keeps it visible to the next session.
- **Rejected / abandoned** → `columbus memory remove mem_NN`, noting the rationale in the session report. If the rejection is a durable judgment ("we will not migrate to X because Y"), record it as an `adr` so future audits inherit it.

## `reconcile` — the session-start sweep

Read every plan memory:

```sh
columbus memory list --kind plan --tag improve --llm
columbus memory validate                              # evidence drift, dead links
```

Then judge each plan's state from its body (executors and the ship workflow note progress and blockers there) and from the code itself:

- **Shipped** — the plan's done criteria hold on the current HEAD (spot-check the cheap ones). If the plan memory wasn't removed when it shipped, remove it now (see lifecycle above for when a fresh `documentation` memory is warranted first).
- **Blocked** (body carries a blocker note) — read the reason. Investigate the underlying obstacle in the codebase. Either rewrite the plan around it (`memory update` with a refreshed body and new `Planned at` SHA) or remove it and note the rejection in the report (record an `adr` if it's a durable judgment).
- **Stale in-progress** (body notes started work but nothing landed) — flag it to the user; an executor probably died mid-run. Check for a leftover branch or worktree if one was used.
- **Still TODO** — run the plan's drift check (`git diff --stat <planned-at SHA>..HEAD -- <in-scope paths>`) and heed `memory validate`'s drift report. If drifted: re-verify the finding still exists (it may have been fixed in passing), then refresh the "Current state" excerpts, evidence ranges, and `Planned at` SHA via `memory update`. If the finding is gone, remove the plan and note "fixed independently" in the report.

Finish by reporting: what's verified done, what was refreshed, what's rejected, and what's executable right now.

## Handing plans to executors

Execution belongs to the delivery workflow, not this skill. When the user wants a plan built, point them at the `ship` workflow or a `delivery-engineer` agent and pass the plan by id. The dispatcher should inline the full body (`columbus show memory mem_NN --llm`) in the executor's brief — the self-containment rule pays off here: the body needs no edits to make sense to whoever (or whatever) picks it up. The plan's owner — not the executor — updates Columbus memory afterward.
