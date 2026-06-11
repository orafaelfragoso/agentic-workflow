---
name: mastering-vitest
description: Master testing with Vitest 4 — unit, integration, component, e2e, load, and benchmark testing with current best practices and auxiliary libraries (Testing Library, MSW 2, Testcontainers, Playwright, fast-check, k6). Covers when to mock vs spy vs use the real thing, setup files vs fixtures, browser mode, coverage, and making slow suites fast (pools, isolation, sharding, concurrency). Use when writing or reviewing tests, configuring vitest.config, fixing flaky or slow tests, choosing a mocking strategy, testing React/Vue/Svelte components, or setting up test infrastructure and CI test pipelines.
---

# Mastering Vitest

Write fast, trustworthy tests at every level of the pyramid — and know which level a given test belongs to.

> **Compatibility (mid-2026):** Vitest 4.1, Node.js 24 LTS (or Bun 1.2+),
> MSW 2.x, Testing Library (RTL 16+), Playwright 1.5x, fast-check 4, k6.
> Resolve current docs with context7 before pinning a version — this table ages.

## Choosing the right kind of test

| Kind        | What it proves                              | Runner / tools                                       | Speed    |
| ----------- | ------------------------------------------- | ---------------------------------------------------- | -------- |
| Unit        | One function/module in isolation            | Vitest, `environment: 'node'`                        | ms       |
| Component   | UI renders & behaves per user interaction   | Vitest + Testing Library (jsdom) or **browser mode** | ms–100ms |
| Integration | Modules + real I/O boundaries work together | Vitest + MSW / Testcontainers / real DB              | 100ms–s  |
| E2E         | Whole deployed app works through the UI     | **Playwright Test** (separate runner, not Vitest)    | seconds  |
| Benchmark   | Relative speed of two implementations       | `vitest bench` (Tinybench)                           | varies   |
| Load        | System behavior under concurrency/volume    | **k6** (or autocannon) — never Vitest                | minutes  |

Default split: many unit/component tests, a meaningful layer of integration
tests at real boundaries, few e2e tests for critical user journeys. If a test
needs a database and a browser and three services, it is probably an e2e test
trying to live in the wrong layer.

## Quick start

```bash
npm install -D vitest          # pnpm add -D vitest / bun add -d vitest
```

```ts
// vitest.config.ts — see assets/vitest-config-template.ts for the full version
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: "unit",
          include: ["src/**/*.test.ts"],
          environment: "node",
        },
      },
      {
        test: {
          name: "dom",
          include: ["src/**/*.test.tsx"],
          environment: "jsdom",
          setupFiles: ["./test/setup.ts"],
        },
      },
    ],
    coverage: { provider: "v8" },
  },
});
```

Vitest 4 renamed `test.workspace` to `test.projects` — one config, many
environments, one `vitest run`.

## Mock, spy, or real? (the short rules)

Work down this ladder and stop at the first rung that fits:

1. **Use the real thing.** Pure logic, your own modules, in-memory data: no test double at all.
2. **Spy (`vi.spyOn`)** when you only need to _observe_ calls but keep (or selectively override) real behavior. Restore after.
3. **Inject a `vi.fn()`** when the dependency is a parameter — prefer designing for injection over module mocking.
4. **Mock the module (`vi.mock`)** only for things you own that wrap a boundary (e.g. `./lib/payments.ts`).
5. **Mock the network, not the client.** Don't mock `fetch`/axios — intercept HTTP with MSW so serialization, headers, and error paths stay real.
6. **Containerize the dependency** (Testcontainers) when a fake would lie — databases, queues, caches.

Never mock what you're testing; mock only what it talks to. Over-mocked tests
pass while production burns — they verify your mocks, not your code.

Cleanup baseline in config so state never leaks between tests:

```ts
test: {
  restoreMocks: true,   // restore spied originals + reset vi.fn implementations
  unstubEnvs: true,     // undo vi.stubEnv
  unstubGlobals: true,  // undo vi.stubGlobal
}
```

## Common mistakes

| Mistake                             | Why it bites                               | Fix                                             |
| ----------------------------------- | ------------------------------------------ | ----------------------------------------------- |
| Mocking everything by default       | Tests verify mocks, not behavior           | Climb the ladder above; mock at boundaries      |
| Testing implementation details      | Refactors break green features             | Assert observable behavior / rendered output    |
| Shared mutable state between tests  | Order-dependent flakes                     | Fixtures (`test.extend`) or per-test setup      |
| `await` missing on async assertions | Test passes before the promise settles     | `await expect(...).resolves/rejects`, lint rule |
| Snapshotting whole components       | Giant snapshots get rubber-stamped         | Inline snapshots of small, intentional values   |
| Real timers + `setTimeout` waits    | Slow and flaky                             | `vi.useFakeTimers()` + `advanceTimersByTime`    |
| e2e suites inside Vitest            | Wrong runner: no retries/traces/web server | Playwright Test for browser e2e                 |
| Optimizing before measuring         | Wrong fix, broken isolation                | Profile first — see performance reference       |

## Reference files

Read the one whose topic matches the task — each file repeats its load condition at the top:

- [references/unit-testing.md](references/unit-testing.md) — read for test structure, assertions, `test.each`, snapshots, async testing, property-based testing (fast-check), type tests
- [references/mocking.md](references/mocking.md) — read for `vi.fn`/`vi.spyOn`/`vi.mock`, `vi.hoisted`, partial mocks, fake timers, system time, env/global stubs, cleanup semantics
- [references/setup-and-fixtures.md](references/setup-and-fixtures.md) — read for `setupFiles` vs `globalSetup`, `provide`/`inject`, `test.extend` fixtures, projects configuration
- [references/integration-testing.md](references/integration-testing.md) — read for MSW 2, Testcontainers, real-database strategies, testing HTTP handlers
- [references/frontend-testing.md](references/frontend-testing.md) — read for Testing Library, jsdom vs happy-dom vs browser mode, `vitest-browser-react`, `expect.element`, visual regression
- [references/e2e-testing.md](references/e2e-testing.md) — read for Playwright Test setup, when to e2e vs component-test, CI patterns
- [references/performance.md](references/performance.md) — read for slow suites: profiling, pools, `isolate: false`, sharding, concurrent tests
- [references/load-and-benchmarks.md](references/load-and-benchmarks.md) — read for `vitest bench` micro-benchmarks and k6 load testing

## Assets

- [assets/vitest-config-template.ts](assets/vitest-config-template.ts) — projects-based `vitest.config.ts` with coverage and cleanup defaults
- [assets/setup-template.ts](assets/setup-template.ts) — DOM test setup file (jest-dom matchers, MSW server lifecycle)

## Validation

Before calling test work done:

- [ ] `vitest run` passes locally — including the project/environment the change touches
- [ ] New tests fail when the behavior they guard is broken (verify at least once)
- [ ] No test double stands in for the unit under test itself
- [ ] No leaked state: mocks/stubs restored (config flags or explicit), no order dependence (`vitest run --sequence.shuffle` still passes)
- [ ] Slow additions justified: integration/e2e tests only where a unit test can't prove it
- [ ] Any newly pinned tool versions were verified against current docs (context7), not this skill's table
