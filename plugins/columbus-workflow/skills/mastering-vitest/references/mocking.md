# Mocking & Spying

> Load when: choosing or implementing test doubles — `vi.fn`, `vi.spyOn`,
> `vi.mock`, partial mocks, fake timers, system time, env/global stubs, cleanup.

## The decision ladder

Stop at the first rung that works; every rung down costs realism.

1. **No double.** Real code, real values.
2. **`vi.spyOn(obj, 'method')`** — observe calls, keep real behavior (or override one method).
3. **`vi.fn()` injected as a dependency** — best for code designed with injection.
4. **`vi.mock('./module')`** — replace a whole module you own.
5. **MSW** for HTTP, **Testcontainers** for infrastructure (see integration reference) — more real than any of the above for those boundaries.

Mock **boundaries you own** (your `payments.ts` wrapper), not third-party
internals — if you mock the SDK's shape directly, every SDK upgrade silently
invalidates your tests.

## `vi.fn` and `vi.spyOn`

```ts
const onSave = vi.fn().mockResolvedValue({ id: "u1" });
// also: mockReturnValue, mockImplementation, mockRejectedValue,
// mockReturnValueOnce / mockImplementationOnce (consumed in order)

await form.submit(onSave);

expect(onSave).toHaveBeenCalledExactlyOnceWith({ name: "Ada" });
expect(onSave.mock.calls[0][0]).toMatchObject({ name: "Ada" });

// spy: real method still runs unless you override it
const spy = vi.spyOn(cache, "get");
const stub = vi.spyOn(cache, "get").mockReturnValue(null); // override
spy.mockRestore(); // put the original back
```

Assert the **fewest specifics that prove the behavior**: `toHaveBeenCalledWith`
on the argument that matters, not exhaustive call-count choreography of every
collaborator.

## Module mocking: `vi.mock`

`vi.mock` is **hoisted** above all imports and applies to the whole file:

```ts
import { sendEmail } from "./email"; // already the mock by the time tests run
import { register } from "./register";

vi.mock("./email"); // automock: all exports become vi.fn()

it("emails the new user", async () => {
  vi.mocked(sendEmail).mockResolvedValue(undefined); // vi.mocked = typed access
  await register("a@b.co");
  expect(sendEmail).toHaveBeenCalledWith("a@b.co", expect.any(String));
});
```

Key mechanics:

- **Hoisting trap:** the factory runs before any `const` in the file exists. Hoist shared values with `vi.hoisted`:

  ```ts
  const { mockLoad } = vi.hoisted(() => ({ mockLoad: vi.fn() }));
  vi.mock("./config", () => ({ load: mockLoad }));
  ```

- **Partial mock** — keep the module real, replace one export:

  ```ts
  vi.mock(import("./metrics"), async (importOriginal) => ({
    ...(await importOriginal()),
    track: vi.fn(),
  }));
  ```

  The `vi.mock(import('./metrics'), ...)` form gives typed `importOriginal` and IDE rename support — prefer it over the string form in TypeScript.

- **`{ spy: true }`** — automock that _keeps_ real implementations, so you can assert calls without changing behavior: `vi.mock(import('./db'), { spy: true })`.
- **`vi.doMock`** — non-hoisted variant; affects only imports made _after_ the call (use with dynamic `await import(...)` inside the test).
- Mocks declared in a test file don't apply to modules already loaded by setup files (module cache); structure setup files so they don't import what tests will mock.
- A sibling `__mocks__/module.ts` file is used automatically when `vi.mock('./module')` has no factory — good for a hand-written fake shared by many test files.

## Cleanup semantics (get this into config once)

| Config flag / method | Effect                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------ |
| `clearMocks`         | clears call history (`mock.calls`, results) before each test                               |
| `mockReset`          | clears history **and** resets implementation to the original `vi.fn` impl (or `undefined`) |
| `restoreMocks`       | all of the above **and** restores `vi.spyOn`'d originals                                   |
| `unstubEnvs`         | undoes `vi.stubEnv` before each test                                                       |
| `unstubGlobals`      | undoes `vi.stubGlobal` before each test                                                    |

Recommended baseline: `restoreMocks: true, unstubEnvs: true, unstubGlobals: true`.
With that set, you rarely need manual `afterEach(() => vi.restoreAllMocks())`.

## Fake timers

Use whenever the code under test waits, debounces, retries, or schedules:

```ts
beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

it("retries three times with backoff", async () => {
  const attempt = vi.fn().mockRejectedValue(new Error("down"));
  const run = retryWithBackoff(attempt); // schedules setTimeouts

  await vi.advanceTimersByTimeAsync(1000 + 2000 + 4000); // async variant flushes promises
  await expect(run).rejects.toThrow("down");
  expect(attempt).toHaveBeenCalledTimes(3);
});
```

- `advanceTimersByTimeAsync` / `runAllTimersAsync` when timer callbacks contain `await` — the sync variants won't flush microtasks.
- `vi.runAllTimers()` errors on infinite-loop timers (e.g. `setInterval` that never clears) — advance by time instead.
- Fake timers patch `setTimeout`, `setInterval`, `Date`, and more by default; pass `toFake` options if you need `performance` or want to leave `queueMicrotask` real.

## System time, env, globals

```ts
vi.setSystemTime(new Date("2026-02-29T00:00:00Z")); // deterministic "now"
vi.stubEnv("API_URL", "http://localhost:9999"); // process.env / import.meta.env
vi.stubGlobal("crypto", fakeCrypto);
```

Set a fixed system time for anything date-dependent (formatting, expiry,
scheduling) — tests that depend on the real clock fail at midnight, on
Feb 29, or in another timezone. Pin `TZ=UTC` in CI for the same reason.

## Smells that mean "stop mocking"

- A test re-declares the same `vi.mock` web in five files → extract a fixture or fake, or test one level higher.
- Mock setup is longer than the assertion → the unit's dependencies are too wide; refactor or move the test up a layer.
- You changed the implementation and only mock expectations broke (behavior identical) → the test asserted implementation details; assert outcomes instead.
