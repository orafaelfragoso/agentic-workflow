# Plan Lifecycle — keeping Columbus plan memory alive

The advisor's job doesn't end at the plan. Plans age: code drifts under them, executors finish or stall, findings get fixed in passing. The `reconcile` variant processes what happened since the last session so the plan memory stays trustworthy.

The founding rule survives unchanged: **the advisor never edits source code.** Reconciling touches only Columbus memory.

## Lifecycle of a plan memory

Columbus's memory model is the guide: plans are intended future work, and **plans age out — re-kind or remove them when they're no longer future work.**

- **Written** → `columbus memory add plan`, tagged `improve` + category, anchored with links and evidence. Row added to the audit-summary memory with status TODO.
- **Executed and verified** → re-kind it: `columbus memory update mem_NN --kind documentation`, and rewrite the body from "what to do" into "how it now works" (keep the why; drop the steps; refresh links/evidence to the landed code). Mark DONE in the audit summary. If nothing durable is worth keeping, `columbus memory remove mem_NN` and record DONE in the summary instead.
- **Blocked** → update the body with the blocker and what was learned; mark BLOCKED (one-line reason) in the audit summary.
- **Rejected / abandoned** → `columbus memory remove mem_NN`; record the rationale in the audit summary's "considered and rejected" section. If the rejection is a durable judgment ("we will not migrate to X because Y"), record it as an `adr` so future audits inherit it.

## `reconcile` — the session-start sweep

Read the audit-summary memory and every plan memory:

```sh
columbus search "improve audit" --kind memory --llm   # find the summary
columbus memory list --kind plan --tag improve --llm
columbus memory validate                              # evidence drift, dead links
```

Then per status in the summary:

- **DONE** — spot-check that the done criteria still hold on the current HEAD (cheap ones only). If the plan memory wasn't re-kinded when it shipped, do it now (see lifecycle above).
- **BLOCKED** — read the reason. Investigate the underlying obstacle in the codebase. Either rewrite the plan around it (`memory update` with a refreshed body and new `Planned at` SHA) or remove it and record REJECTED with one line of rationale.
- **IN PROGRESS** (stale) — flag it to the user; an executor probably died mid-run. Check for a leftover branch or worktree if one was used.
- **TODO** — run the plan's drift check (`git diff --stat <planned-at SHA>..HEAD -- <in-scope paths>`) and heed `memory validate`'s drift report. If drifted: re-verify the finding still exists (it may have been fixed in passing), then refresh the "Current state" excerpts, evidence ranges, and `Planned at` SHA via `memory update`. If the finding is gone, remove the plan and record REJECTED ("fixed independently") in the summary.

Finish by updating the audit-summary memory's status table, then report: what's verified done, what was refreshed, what's rejected, and what's executable right now.

## Handing plans to executors

Execution belongs to the delivery workflow, not this skill. When the user wants a plan built, point them at the `ship` workflow or a `delivery-engineer` agent and pass the plan by id. The dispatcher should inline the full body (`columbus show memory mem_NN --llm`) in the executor's brief — the self-containment rule pays off here: the body needs no edits to make sense to whoever (or whatever) picks it up. The plan's owner — not the executor — updates Columbus memory afterward.
