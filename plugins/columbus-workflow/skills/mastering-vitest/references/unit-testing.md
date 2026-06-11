# Unit Testing

> Load when: writing or reviewing unit tests — structure, assertions,
> parameterized tests, snapshots, async code, property-based or type-level tests.

## Structure: Arrange–Act–Assert, one behavior per test

```ts
import { describe, expect, it } from "vitest";
import { applyDiscount } from "./pricing";

describe("applyDiscount", () => {
  it("caps the discount at 100%", () => {
    const order = { total: 80 }; // arrange
    const result = applyDiscount(order, 1.5); // act
    expect(result.total).toBe(0); // assert
  });

  it("rejects negative discounts", () => {
    expect(() => applyDiscount({ total: 80 }, -0.1)).toThrow(RangeError);
  });
});
```

- Name tests after **behavior**, not method names: `'caps the discount at 100%'`, not `'test applyDiscount 3'`.
- One logical assertion per test — multiple `expect`s are fine when they describe one outcome.
- Prefer importing `describe/it/expect` explicitly over `globals: true`; explicit imports keep files portable and play better with linters. (Enable globals only when a library requires it, e.g. some Testing Library cleanup integrations.)
- Pair Vitest with `@vitest/eslint-plugin` to catch missing `await`s, focused tests (`.only`) left behind, and disabled assertions.

## Parameterized tests

`test.each` (table) and `test.for` (when you need the test context, e.g. concurrent `expect`):

```ts
it.each([
  { input: "", expected: false },
  { input: "a@b.co", expected: true },
  { input: "no-at-sign", expected: false },
])("isEmail($input) -> $expected", ({ input, expected }) => {
  expect(isEmail(input)).toBe(expected);
});
```

Use parameterization for genuinely tabular cases. If each row needs its own
arrange logic, write separate tests.

## Asserting errors and async code

```ts
// sync throw — wrap in a function
expect(() => parse("{bad")).toThrow(SyntaxError);

// async — ALWAYS await, or the test ends before the assertion runs
await expect(fetchUser("missing")).rejects.toThrow(/not found/);
await expect(fetchUser("u1")).resolves.toMatchObject({ id: "u1" });

// eventual consistency — poll instead of sleeping
await expect.poll(() => store.status, { timeout: 2000 }).toBe("ready");
await vi.waitFor(() => expect(listener).toHaveBeenCalled());
```

Never `await new Promise(r => setTimeout(r, 500))` to "wait for things" — use
`expect.poll`/`vi.waitFor` (event-driven, fails fast with a real timeout) or
fake timers (see mocking reference).

## Choosing matchers

- `toBe` for primitives/identity, `toEqual` for deep structural equality, `toStrictEqual` when `undefined` properties and class identity matter.
- `toMatchObject` for asserting a subset of a large object.
- Asymmetric matchers compose: `expect(log).toEqual({ at: expect.any(Date), msg: expect.stringContaining('saved') })`.
- `expect.soft(...)` collects multiple failures in one run instead of stopping at the first — useful for asserting several fields of one result.

## Snapshots: small, inline, intentional

```ts
expect(formatError(err)).toMatchInlineSnapshot(
  `"E1042: connection refused (retryable)"`,
);
```

- Prefer **inline snapshots** of small serialized values — they live in the file and get reviewed.
- Avoid snapshotting whole component trees or large objects: they churn on every refactor and reviewers stop reading them. If a snapshot update doesn't make you think, the snapshot isn't testing anything.
- File snapshots (`toMatchSnapshot`) are acceptable for stable, human-readable artifacts (CLI output, generated config). Review every `--update` diff.

## Property-based testing (fast-check)

For pure functions with algebraic properties (round-trips, invariants,
idempotence), properties beat hand-picked examples:

```ts
import fc from "fast-check";

it("decode reverses encode for any string", () => {
  fc.assert(fc.property(fc.string(), (s) => decode(encode(s)) === s));
});
```

Use for parsers, serializers, math, sorting/ordering logic. Keep example-based
tests alongside for documentation value and known regressions.

## Type-level tests

Vitest can assert types with `expectTypeOf` in `*.test-d.ts` files (enable
`typecheck` in config) — useful for public APIs and generic utilities:

```ts
import { expectTypeOf } from "vitest";

expectTypeOf(parseConfig).returns.toEqualTypeOf<Config>();
expectTypeOf(pick({ a: 1, b: 2 }, ["a"])).toEqualTypeOf<{ a: number }>();
```

## Housekeeping

- `it.todo('handles leap seconds')` records planned coverage; `it.fails(...)` documents a known bug that should start passing when fixed.
- `it.skip`/`describe.skip` need a comment saying why and when it can return.
- Never commit `.only` — lint for it (`@vitest/eslint-plugin` `no-focused-tests`).
