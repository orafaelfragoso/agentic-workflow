# Integration Testing

> Load when: testing across real boundaries — HTTP APIs with MSW, databases
> and queues with Testcontainers, or in-process HTTP handlers.

Integration tests prove that _your_ modules compose correctly with _real_
boundary behavior: real serialization, real SQL, real status codes. They live
in their own project (`tests/integration/`) so the fast unit loop never waits
on them.

## HTTP: mock the network with MSW 2, not the client

MSW intercepts at the network level, so your real `fetch`/axios/client code —
headers, query encoding, JSON parsing, error handling — all executes:

```ts
// test/msw.ts
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("https://api.example.com/users/:id", ({ params }) =>
    HttpResponse.json({ id: params.id, name: "Ada" }),
  ),
];

export const server = setupServer(...handlers);
```

```ts
// test/setup.ts (setupFiles)
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

```ts
// per-test override for the case under test
it("surfaces a 503 as a retryable error", async () => {
  server.use(
    http.get("https://api.example.com/users/:id", () =>
      HttpResponse.json({ message: "maintenance" }, { status: 503 }),
    ),
  );
  await expect(getUser("u1")).rejects.toMatchObject({ retryable: true });
});
```

- `onUnhandledRequest: 'error'` is non-negotiable — silent passthrough hides missing handlers and makes tests hit real networks.
- `server.resetHandlers()` after each test so `server.use` overrides don't leak.
- MSW 2 API is `http.*` + `HttpResponse` (the `rest.*`/`res(ctx)` API was MSW 1). It also handles `graphql.*` operations and `ws` for WebSockets.
- Test **error paths as first-class cases**: timeouts (`delay`), 4xx/5xx, malformed bodies, `HttpResponse.error()` for network failure.

## Databases & infra: Testcontainers over fakes

In-memory fakes (SQLite for Postgres, `mongodb-memory-server`, fake Redis)
diverge from production on dialect, constraints, and concurrency. Run the real
engine in Docker:

```ts
// test/global-setup.ts — once per run, URL shared via provide/inject
import { PostgreSqlContainer } from "@testcontainers/postgresql";
import type { TestProject } from "vitest/node";

export default async function (project: TestProject) {
  const pg = await new PostgreSqlContainer("postgres:17").start();
  await migrate(pg.getConnectionUri());
  project.provide("dbUrl", pg.getConnectionUri());
  return async () => {
    await pg.stop();
  };
}
```

Keep tests independent with one of these isolation strategies (in order of speed):

1. **Transaction-per-test, rolled back** — wrap each test in a transaction via a fixture; fastest, but can't test code that commits or uses multiple connections.
2. **Truncate between tests** — an `{ auto: true }` fixture truncating touched tables; robust default.
3. **Schema/database-per-worker** — when tests must run in parallel against one container; derive the name from `VITEST_WORKER_ID` (e.g. `test_${process.env.VITEST_WORKER_ID}`).

If the suite shares one database without per-worker isolation, set
`fileParallelism: false` on the integration project rather than chasing
heisenbugs.

## In-process HTTP handlers

Test route handlers without binding a port when the framework allows it
(Fetch-API frameworks like Hono take a `Request` directly):

```ts
const res = await app.request("/users/u1");
expect(res.status).toBe(200);
expect(await res.json()).toMatchObject({ id: "u1" });
```

For Node/Express-style apps, `supertest` (or `light-my-request` for Fastify —
built into `app.inject`) drives the handler stack without a network socket.
Reserve real-port listening for tests that specifically cover server wiring
(TLS, keep-alive, middleware ordering across the real stack).

## What to assert

- Status, body shape (`toMatchObject`, not full-body snapshots), and the **side effect**: the row exists, the message was enqueued, the cache was invalidated.
- Contract edges: pagination boundaries, idempotency on retry, concurrent writes if the code claims safety.
- Don't re-test pure logic already covered by unit tests through HTTP — integration tests cover the _wiring_, units cover the _logic_.
