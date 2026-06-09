# Enterprise Patterns

> **Load when:** the question is about error handling, runtime validation,
> branded types, dependency injection, or migrating JavaScript to TypeScript.

These patterns trade a little ceremony for a lot of confidence at the seams of a
system — where data arrives untyped and where failures must be handled.

## Error handling

Two honest options. Pick one per layer and stay consistent.

### Typed thrown errors

Subclass `Error`, keep a discriminant, and always narrow `catch (e: unknown)`:

```typescript
class AppError extends Error {
  constructor(message: string, readonly cause?: unknown) {
    super(message);
    this.name = new.target.name; // correct subclass name
  }
}
class NotFoundError extends AppError {}
class ValidationError extends AppError {
  constructor(readonly issues: readonly string[]) {
    super("validation failed");
  }
}

try {
  // ...
} catch (e: unknown) {
  if (e instanceof ValidationError) report(e.issues);
  else if (e instanceof NotFoundError) return null;
  else throw e; // don't swallow what you don't recognise
}
```

Use the standard `cause` option to preserve the chain instead of stringifying:

```typescript
throw new AppError("failed to load user", { cause: err });
```

### Result types (errors as values)

When failure is expected (parsing, lookups, external calls), return it instead of
throwing. The caller can't forget to handle it — the type won't let them.

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

const ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const err = <E>(error: E): Result<never, E> => ({ ok: false, error });

async function loadConfig(path: string): Promise<Result<Config, string>> {
  try {
    return ok(Config.parse(JSON.parse(await readFile(path, "utf8"))));
  } catch (e) {
    return err(`bad config at ${path}: ${String(e)}`);
  }
}

const r = await loadConfig("./app.json");
if (!r.ok) process.exit(1);
r.value; // narrowed to Config
```

## Runtime validation with Zod 4

Static types vanish at runtime; anything crossing a boundary (HTTP, env, files,
`localStorage`, message queues) is `unknown` until proven otherwise. Parse once,
derive the type from the schema, and trust it everywhere downstream.

```typescript
import * as z from "zod";

// Zod 4: string formats are top-level functions
const Env = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.url(),
  ADMIN_EMAIL: z.email(),
});

// Validate process.env at startup — fail fast on misconfiguration
export const env = Env.parse(process.env);
export type Env = z.infer<typeof Env>;
```

Key Zod 4 notes:
- String formats moved to the top level: `z.email()`, `z.uuid()`, `z.url()`,
  `z.iso.datetime()` — the chained `z.string().email()` form is deprecated.
- `.safeParse()` returns `{ success, data | error }`; format issues with
  `z.treeifyError(error)` or `z.prettifyError(error)`.
- Unknown keys are stripped by default; use `z.strictObject({...})` to reject
  extras or `z.looseObject({...})` to keep them.
- Zod 4 is a large rewrite with major speedups; `zod/mini` offers a
  tree-shakable, function-style API for bundle-sensitive frontends.

Validate at the edge, then pass typed data inward — never re-validate the same
value in every function.

## Branded (nominal) types

TypeScript is structural, so a `UserId` and an `OrderId` that are both `string`
are interchangeable — a real bug source. Brand them to get nominal safety with
zero runtime cost:

```typescript
declare const brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [brand]: B };

type UserId = Brand<string, "UserId">;
type OrderId = Brand<string, "OrderId">;

const asUserId = (s: string): UserId => s as UserId; // only smart constructor casts

function getUser(id: UserId): void { /* ... */ }
getUser(asUserId("u_123")); // ok
getUser("u_123" as OrderId); // error — can't pass an OrderId
```

## Dependency injection without a framework

Plain constructor injection plus interfaces keeps things testable and explicit —
no decorators or container required.

```typescript
interface Clock { now(): Date; }
interface UserRepo { findById(id: UserId): Promise<User | null>; }

class UserService {
  constructor(private readonly repo: UserRepo, private readonly clock: Clock) {}
  async lastSeen(id: UserId): Promise<Date | null> {
    const u = await this.repo.findById(id);
    return u ? this.clock.now() : null;
  }
}

// In tests, inject fakes — no mocking library needed.
new UserService(fakeRepo, { now: () => new Date("2026-01-01") });
```

Accept the narrowest interface a function needs (consumer-defined), and wire
concrete implementations once at the composition root (`main.ts`).

## Migrating JavaScript → TypeScript

A staged path that keeps the app shippable throughout:

1. **Turn on the compiler loosely.** Add `tsconfig.json` with `allowJs: true`,
   `checkJs: false`, `strict: false`. Nothing breaks yet.
2. **Type the boundaries first.** Add `.d.ts` or JSDoc types to public exports
   and external API shapes — that's where wrong types cause the most damage.
3. **Rename leaf-up.** Convert files with few dependents to `.ts` first; let
   inference cover most of the work, annotate what it can't.
4. **Tighten incrementally.** Flip strict flags one at a time
   (`noImplicitAny` → `strictNullChecks` → the rest), fixing fallout per flag so
   reviews stay small.
5. **Validate external data** with Zod as you convert each boundary, replacing
   defensive `typeof` checks with a parse.

JSDoc lets you type `.js` files before committing to a rename:

```javascript
/** @param {string} name @param {number} age @returns {{name: string, age: number}} */
function createUser(name, age) {
  return { name, age };
}
```
