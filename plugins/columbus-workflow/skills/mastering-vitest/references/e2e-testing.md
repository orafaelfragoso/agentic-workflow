# End-to-End Testing

> Load when: testing whole user journeys through a running app — Playwright
> Test setup, what belongs in e2e, CI patterns.

## Use Playwright Test, not Vitest, for browser e2e

Vitest browser mode tests _components_; e2e tests exercise a **running
application** (real routing, auth, backend). Playwright Test is built for
that: auto-managed dev server, per-test retries, trace viewer, parallel
browser contexts, and storage-state auth. Don't wedge e2e suites into Vitest —
keep `e2e/` as a separate Playwright project with its own config.

```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry", // debugging artifact only when needed
  },
  webServer: {
    command: "npm run start",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
});
```

```ts
import { expect, test } from "@playwright/test";

test("user can check out", async ({ page }) => {
  await page.goto("/products/keyboard");
  await page.getByRole("button", { name: "Add to cart" }).click();
  await page.getByRole("link", { name: "Checkout" }).click();
  await page.getByLabel("Card number").fill("4242 4242 4242 4242");
  await page.getByRole("button", { name: "Pay" }).click();
  await expect(
    page.getByRole("heading", { name: "Order confirmed" }),
  ).toBeVisible();
});
```

## Principles

- **Few and critical.** E2e covers the journeys whose breakage is an incident: signup, login, checkout, the core workflow. Everything else belongs lower in the pyramid.
- **Role-based locators + web-first assertions.** `getByRole`/`getByLabel` and `await expect(locator).toBeVisible()` auto-retry — never `waitForTimeout` sleeps.
- **Independent tests.** Each test creates (or seeds via API) its own data; no test depends on another's leftovers. Use API calls for setup — driving the UI to _arrange_ state is slow and flaky; drive the UI only for the behavior under test.
- **Auth once via storage state.** Log in inside a setup project, save `storageState`, and reuse it — not a UI login per test.
- **Deterministic backend.** Point e2e at an environment you control and seed. If third-party services are involved, stub them at the environment boundary (test-mode keys, sandbox endpoints) — not inside the test.

## API e2e without a browser

For service-level e2e (deployed API, no UI), a sequential Vitest project hitting
the real base URL is fine — that's contract verification, and Vitest's
`expect.poll` handles eventual consistency. The "use Playwright" rule is about
_browser_ journeys.

## CI

- Run Playwright in its own job after build/deploy of a preview environment; cache browser binaries (`npx playwright install --with-deps`).
- Shard with `--shard=1/4 ... 4/4` across machines; merge reports with `merge-reports`.
- Upload traces/videos only on failure; review flaky-retry stats — a test that passes on retry every week is a bug, not a victory.
- Quarantine genuinely flaky tests explicitly (tag + tracking issue) rather than letting the suite train people to ignore red.
