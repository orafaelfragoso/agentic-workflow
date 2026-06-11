# Setup Files, Global Setup & Fixtures

> Load when: deciding where shared test infrastructure lives — `setupFiles`
> vs `globalSetup`, `provide`/`inject`, `test.extend` fixtures, or `projects`.

## The three setup layers

| Layer                  | Runs                                      | Has test APIs? | Use for                                              |
| ---------------------- | ----------------------------------------- | -------------- | ---------------------------------------------------- |
| `globalSetup`          | **Once** per run, in Vitest's own process | no             | start containers/servers, build artifacts, seed once |
| `setupFiles`           | Before **each test file**, in the worker  | yes            | matchers, MSW lifecycle, cleanup hooks, polyfills    |
| `test.extend` fixtures | Per **test** (or scoped)                  | yes            | per-test resources with teardown, typed and lazy     |

Rule of thumb: expensive + shared → `globalSetup`; cross-cutting per-file
wiring → `setupFiles`; anything a test _receives as a value_ → fixture.

## `globalSetup` + `provide`/`inject`

Global setup runs in a separate context — it cannot share variables with tests
directly. Pass values through `provide`:

```ts
// global-setup.ts
import type { TestProject } from "vitest/node";

export default async function setup(project: TestProject) {
  const container = await new PostgreSqlContainer("postgres:17").start();
  project.provide("dbUrl", container.getConnectionUri());
  return async () => {
    await container.stop();
  }; // teardown
}
```

```ts
// in a test
import { inject } from "vitest";
const dbUrl = inject("dbUrl");
```

Type the channel once:

```ts
declare module "vitest" {
  interface ProvidedContext {
    dbUrl: string;
  }
}
```

## `setupFiles`

```ts
// vitest.config.ts
test: {
  setupFiles: ["./test/setup.ts"];
}
```

Typical contents (see `assets/setup-template.ts`): register `jest-dom`
matchers, start/stop an MSW server, `vi.setConfig` defaults, global polyfills.
Keep them **small and side-effect-conscious**:

- Every test file pays the setup file's import cost — a heavy setup file slows the whole suite linearly.
- Modules imported by a setup file land in the module cache **before** `vi.mock` factories from test files apply; don't import application modules tests will mock.
- Don't put `beforeEach` data seeding for _some_ tests in a global setup file — that's a fixture's job.

## Fixtures with `test.extend`

Fixtures are typed, lazy (only initialized when a test destructures them), and
compose. They replace ad-hoc `beforeEach` + shared `let` variables:

```ts
import { test as base, expect } from "vitest";

interface Ctx {
  db: Db;
  user: User;
}

export const test = base.extend<Ctx>({
  db: async ({}, use) => {
    const db = await connect(inject("dbUrl"));
    await use(db); // everything before `use` is setup, after is teardown
    await db.close();
  },
  user: async ({ db }, use) => {
    // fixtures can depend on fixtures
    await use(await db.users.create({ name: "Ada" }));
  },
});

test("loads the profile", async ({ user, db }) => {
  expect(await db.profiles.for(user.id)).toBeDefined();
});
```

- **Destructure to activate**: a fixture not listed in the test's arguments never runs — free laziness.
- `{ auto: true }` runs a fixture for every test without destructuring (e.g. DB truncation).
- `scope: 'worker'` (or `'file'`) initializes once per worker/file instead of per test — for expensive resources like a connection pool.
- Prefer exporting an extended `test` from `test/fixtures.ts` and importing it everywhere over re-extending per file.
- Compared to `beforeEach` + module-level `let`: fixtures are typed, can't be used uninitialized, tie teardown to setup in one place, and work with `test.concurrent` (no shared mutable bindings).

Use `beforeEach`/`afterEach` for behavior (resetting a fake clock), fixtures
for **values** tests consume.

## Projects: one config, many environments

`projects` (formerly `workspace`, renamed in Vitest 4) splits the suite by
environment, setup, or speed class — all run with one `vitest` command and
share coverage:

```ts
export default defineConfig({
  test: {
    coverage: { provider: "v8" },
    projects: [
      {
        test: {
          name: "unit",
          environment: "node",
          include: ["src/**/*.test.ts"],
        },
      },
      {
        extends: true, // inherit root-level options (plugins, resolve, etc.)
        test: {
          name: "dom",
          environment: "jsdom",
          include: ["src/**/*.test.tsx"],
          setupFiles: ["./test/setup.ts"],
        },
      },
      {
        extends: true,
        test: {
          name: "integration",
          include: ["tests/integration/**/*.test.ts"],
          globalSetup: ["./test/global-setup.ts"],
          fileParallelism: false, // shared DB — don't stampede it
        },
      },
    ],
  },
});
```

- `vitest --project unit` runs one project; `vitest` runs all.
- Give slow projects their own name so CI can run `unit` on every push and `integration` on merge.
- Root-level `coverage` and reporters apply across projects; per-project `environment`, `setupFiles`, `globalSetup`, and pool options are where they diverge.
