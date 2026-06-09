# TypeScript Type System

> **Load when:** the question is about annotations, `interface` vs `type`,
> unions/intersections, narrowing, or the special types (`unknown`/`never`/`void`).

TypeScript types are **structural**: compatibility is decided by shape, not by
name. Two types with the same members are interchangeable even if declared
independently. Keep that in mind throughout.

## Annotations and inference

Prefer inference where the type is obvious; annotate at boundaries (parameters,
return types of exported functions, and anywhere inference would widen too far).

```typescript
const name = "Alice";          // inferred string — don't annotate
const ids: readonly number[] = [1, 2, 3];
const pair: [x: number, y: number] = [10, 20]; // labeled tuple

function greet(name: string): string {
  return `Hello, ${name}`;
}

// Annotate exported return types: it locks the contract and speeds checking.
export function makeUser(name: string): { id: string; name: string } {
  return { id: crypto.randomUUID(), name };
}
```

Use `as const` to stop widening and get the narrowest literal types:

```typescript
const ROLES = ["user", "admin", "moderator"] as const;
type Role = (typeof ROLES)[number]; // "user" | "admin" | "moderator"
```

## `interface` vs `type`

Both describe object shapes; they differ at the edges.

- `interface` — extendable (`extends`), implementable by classes, and supports
  declaration merging. Reach for it for public object contracts and class shapes.
- `type` — can alias anything: unions, intersections, tuples, primitives,
  mapped and conditional types. Reach for it for everything that isn't a plain
  extendable object.

```typescript
interface User { id: string; name: string }
interface Employee extends User { department: string }

type Status = "pending" | "approved" | "rejected"; // unions need `type`
type WithTimestamps<T> = T & { createdAt: Date; updatedAt: Date };
```

| Use case | Prefer |
|----------|--------|
| Public object contract, class `implements` | `interface` |
| Union / tuple / primitive alias | `type` |
| Mapped or conditional type | `type` |
| Needs declaration merging (e.g. augmenting a lib) | `interface` |

Default to `type` for app code and `interface` when you need extension/merging —
consistency inside a codebase matters more than the rule.

## Unions and intersections

A **union** (`A | B`) is "one of"; an **intersection** (`A & B`) is "all of".
The most useful union is the **discriminated union** — a shared literal tag that
lets the compiler narrow exhaustively.

```typescript
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "rect"; width: number; height: number };

function area(s: Shape): number {
  switch (s.kind) {
    case "circle": return Math.PI * s.radius ** 2;
    case "rect":   return s.width * s.height;
    default:       return assertNever(s); // compile error if a case is missed
  }
}

function assertNever(x: never): never {
  throw new Error(`Unhandled: ${JSON.stringify(x)}`);
}
```

This pattern beats objects full of optional fields: it makes illegal
combinations unrepresentable instead of merely discouraged.

## Literal and template-literal types

```typescript
type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
type DiceRoll = 1 | 2 | 3 | 4 | 5 | 6;

// Template literal types compose strings at the type level
type EventName = "click" | "focus" | "hover";
type Handler = `on${Capitalize<EventName>}`; // "onClick" | "onFocus" | "onHover"

type Px = `${number}px`;
const gap: Px = "8px"; // ok; "8" would be an error
```

## Narrowing and guards

The compiler narrows types along control flow. Lean on it rather than casting.

```typescript
function format(v: string | number | null): string {
  if (v === null) return "—";
  if (typeof v === "string") return v.trim();
  return v.toFixed(2); // v is number here
}
```

**`instanceof`** narrows class instances; **`in`** narrows by property presence:

```typescript
function describe(x: { swim(): void } | { fly(): void }): void {
  if ("swim" in x) x.swim();
  else x.fly();
}
```

**Custom type guards** return a type predicate (`x is T`):

```typescript
type Account =
  | { type: "user"; name: string }
  | { type: "admin"; name: string; permissions: string[] };

function isAdmin(a: Account): a is Extract<Account, { type: "admin" }> {
  return a.type === "admin";
}
```

**Assertion functions** narrow by throwing:

```typescript
function assertDefined<T>(v: T | undefined, msg: string): asserts v is T {
  if (v === undefined) throw new Error(msg);
}
```

## Special types

### `any` vs `unknown`

`any` switches off checking and propagates silently — avoid it. `unknown` is the
type-safe top type: you can hold anything, but must narrow before use.

```typescript
function handle(input: unknown): string {
  if (typeof input === "string") return input;     // ok after narrowing
  if (typeof input === "number") return String(input);
  throw new Error("unsupported");
}
```

### `never`

`never` is the empty type — no value inhabits it. It is the return type of
functions that never produce a value (they throw or loop forever) and the engine
behind exhaustiveness checks (see `assertNever` above).

### `void` vs `undefined`

`void` means "the return value is ignored"; `undefined` is a concrete value. A
`void`-returning callback may return any value (it just won't be used) — useful
for passing `array.push` to `forEach` without a type error.

### `null` vs `undefined`

With `strictNullChecks` (part of `strict`), neither is assignable to other types
implicitly. Model absence explicitly (`T | undefined`) and prefer `??` (nullish
coalescing) and `?.` (optional chaining) over truthiness checks that misfire on
`0`/`""`.

## Strictness flags worth knowing

- `noUncheckedIndexedAccess` — `arr[i]` and `record[key]` become `T | undefined`,
  forcing you to handle the miss. The single highest-value flag after `strict`.
- `exactOptionalPropertyTypes` — `{ x?: number }` no longer silently accepts
  `{ x: undefined }`; optional and "explicitly undefined" stop being conflated.
- `noPropertyAccessFromIndexSignature` — forces `obj["dynamic"]` for index
  signatures and `obj.known` for declared props, keeping intent visible.
