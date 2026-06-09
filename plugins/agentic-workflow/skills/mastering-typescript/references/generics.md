# Generics and Type-Level Programming

> **Load when:** the question is about generic functions/classes, constraints,
> conditional types, `infer`, mapped types, or variance.

A type parameter earns its place only when it removes real duplication or links
an input type to an output type. If a concrete type works, use it — generics are
not free to read.

## Generic functions and constraints

```typescript
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}

// Constrain with `extends` to require capabilities
function longest<T extends { length: number }>(a: T, b: T): T {
  return a.length >= b.length ? a : b;
}

// Link two parameters so the compiler enforces a relationship
function pluck<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { id: "1", age: 30 };
pluck(user, "age"); // number — not number | string
```

Let inference do the work. Don't make callers pass type arguments they
shouldn't have to; design signatures so `T` is inferred from the values.

## Default and inferred type parameters

```typescript
interface Paginated<T, M = { total: number }> {
  items: readonly T[];
  meta: M;
}

// Default values for generics keep common cases terse.
type Page = Paginated<string>; // meta defaults to { total: number }
```

## Generic classes and interfaces

```typescript
class Stack<T> {
  readonly #items: T[] = [];
  push(item: T): void { this.#items.push(item); }
  pop(): T | undefined { return this.#items.pop(); }
  get size(): number { return this.#items.length; }
}

interface Repository<T, ID = string> {
  findById(id: ID): Promise<T | null>;
  save(entity: T): Promise<T>;
}
```

## Conditional types and `infer`

A conditional type chooses a branch based on assignability. `infer` captures a
type from within the matched shape.

```typescript
type ElementOf<T> = T extends readonly (infer E)[] ? E : never;
type A = ElementOf<number[]>; // number

type Awaited2<T> = T extends Promise<infer R> ? Awaited2<R> : T; // recursive unwrap

// Distributive over unions: applied to each member, then re-unioned
type NonNullableX<T> = T extends null | undefined ? never : T;
type B = NonNullableX<string | null | undefined>; // string
```

Wrap a parameter in a tuple to **stop** distribution when you want the union
treated as a whole:

```typescript
type IsExactlyString<T> = [T] extends [string] ? true : false;
type C = IsExactlyString<string | number>; // false (no distribution)
```

## Mapped types

Mapped types transform every property of a type. Combine with key remapping
(`as`) and modifiers (`readonly`, `?`, and their `-` removers).

```typescript
type ReadonlyDeep<T> = { readonly [K in keyof T]: T[K] };
type Mutable<T> = { -readonly [K in keyof T]: T[K] }; // strip readonly
type Required2<T> = { [K in keyof T]-?: T[K] };        // strip optionality

// Key remapping: derive getter names from properties
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface Person { name: string; age: number }
type PersonGetters = Getters<Person>;
// { getName: () => string; getAge: () => number }

// Filter keys by value type using `as` + conditional
type StringKeys<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};
```

## Reach for built-in utility types first

Don't hand-roll what the standard library gives you:

| Type | Purpose |
|------|---------|
| `Partial<T>` / `Required<T>` | toggle optionality |
| `Readonly<T>` | shallow-immutable |
| `Pick<T, K>` / `Omit<T, K>` | select / exclude keys |
| `Record<K, V>` | object with typed keys/values |
| `Exclude<U, X>` / `Extract<U, X>` | filter a union |
| `NonNullable<T>` | drop `null`/`undefined` |
| `ReturnType<F>` / `Parameters<F>` | read a function's types |
| `Awaited<T>` | unwrap (possibly nested) promises |
| `NoInfer<T>` | block inference at a position |

`NoInfer` (TS 5.4+) is handy to force inference from one parameter only:

```typescript
function createState<T>(initial: T, allowed: NoInfer<T>[]): T {
  return initial;
}
// `allowed` no longer widens T — T is inferred from `initial` alone.
```

## Variance and the assignment rules

- **Function parameters are contravariant** under `strictFunctionTypes`: a
  handler taking a wider type is assignable where a narrower one is expected.
- **Return types are covariant**: returning a subtype is fine.
- **Arrays are (unsoundly) covariant** — a known footgun; `readonly` arrays are
  safer because you can't push the wrong element in.

Annotate intended variance on type parameters (TS 4.7+) when it documents intent:

```typescript
interface Producer<out T> { get(): T; }   // covariant
interface Consumer<in T>  { set(v: T): void; } // contravariant
```

## Keep type-level code readable

- Name intermediate types instead of nesting four conditionals deep.
- Prefer a utility type from the stdlib over a clever bespoke one.
- If a type needs a comment to explain *what* it computes, it's probably doing
  too much — split it or reconsider the design.
