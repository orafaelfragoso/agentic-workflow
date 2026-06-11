# Test Performance

> Load when: the suite is slow or flaky-under-parallelism — profiling,
> pools, isolation, parallelism, sharding, concurrency.

## Measure before changing anything

```bash
vitest run --reporter=verbose        # per-test timing; slow tests flagged
                                      # (slowTestThreshold, default 300ms)
DEBUG=vitest:* vitest run            # where time goes: transform, collect, setup
```

Diagnose which bucket dominates:

- **Setup/collect time** (before any test runs): heavy `setupFiles`, barrel-file imports dragging in the world, big transform graphs.
- **Test time**: real I/O or real timers in unit tests, oversized arrange phases.
- **Environment**: `jsdom` per-file initialization across hundreds of files.

Cheap wins, in the order to try them:

1. **Import surgically.** A unit test importing from a barrel (`import { x } from '../index'`) transforms the entire dependency tree. Import the module directly.
2. **Fake timers** for anything that waits (see mocking reference) — sleeps are the #1 source of slow _and_ flaky.
3. **`happy-dom`** over `jsdom` where the suite doesn't need jsdom-specific APIs.
4. Keep `setupFiles` minimal — every file pays for them.

## Pools and isolation

Vitest runs test files in parallel workers; the defaults favor safety:

| Knob                                | Default                                 | Faster option & cost                                                   |
| ----------------------------------- | --------------------------------------- | ---------------------------------------------------------------------- |
| `pool`                              | `forks` (child processes)               | `threads` — often faster; some native/process-global code misbehaves   |
| `isolate`                           | `true` (fresh module registry per file) | `false` — big startup win; requires tests that don't leak module state |
| `fileParallelism`                   | `true`                                  | `false` only for suites sharing one external resource (DB)             |
| `VITEST_MAX_WORKERS` / `maxWorkers` | CPU-based                               | tune down in CI containers that report more CPUs than they have        |

`isolate: false` is the biggest single lever for large unit suites — but only
flip it per-project for tests with no module-level mutable state, and verify
with `vitest run --sequence.shuffle` that nothing was order-dependent.
`vmThreads` is a further speedup (shared VM contexts) with known memory-leak
caveats; treat it as a last resort and measure memory.

Apply per project — keep `isolate: true` for integration tests, disable for
pure-logic units:

```ts
projects: [
  { test: { name: "unit", isolate: false, pool: "threads" } },
  { test: { name: "integration", fileParallelism: false } },
];
```

## Concurrency inside files

Files parallelize automatically; tests _within_ a file run sequentially unless
marked. For I/O-bound tests (each awaiting an API/DB):

```ts
describe.concurrent("user endpoints", () => {
  it("fetches a user", async ({ expect }) => {
    /* ... */
  }); // use context expect
  it("lists users", async ({ expect }) => {
    /* ... */
  });
});
```

- Destructure `expect` from the test context in concurrent tests — snapshot and assertion bookkeeping needs the local one.
- Concurrent tests must not share mutable state — use fixtures, not module-level `let`.
- `it.sequential` opts a test out inside a concurrent block; `maxConcurrency` caps the batch.

## Sharding across machines (CI)

```sh
vitest run --reporter=blob --shard=1/3   # machine 1
vitest run --reporter=blob --shard=2/3   # machine 2
vitest run --reporter=blob --shard=3/3   # machine 3
vitest run --merge-reports               # after collecting .vitest-reports/
```

On one big machine, multiple sharded processes with capped workers beat a
single process bottlenecked on its main thread (e.g. on 32 cores, 4 shards ×
`VITEST_MAX_WORKERS=7`).

## CI hygiene

- `vitest run` (no watch) in CI; `vitest --changed` locally for tight loops (watch mode already reruns only affected files).
- Coverage costs time — run it on one shard/job, not every matrix cell, and merge.
- Track suite duration in CI; treat a 20% regression like a failing test.
- Flakiness is a performance problem too: retries multiply wall time. Fix root causes (shared state, real timers, unawaited promises) instead of `retry: n`.
