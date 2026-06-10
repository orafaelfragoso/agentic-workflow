---
name: mastering-typescript
description: Master modern, type-safe TypeScript — type-system depth (generics, mapped/conditional types, satisfies), enterprise patterns (Result-style error handling, Zod 4 validation at boundaries), type-safe React 19, frameworks (Next.js 16, TanStack Start), and a current toolchain (Vite 8, Node 24 or Bun, ESLint 10 / Biome / oxlint, Prettier, Vitest 4, Turborepo). Use when building or reviewing type-safe apps, migrating JavaScript to TypeScript, configuring tsconfig, linters, formatters, or monorepo tooling, or implementing advanced type patterns.
---

# Mastering Modern TypeScript

Build type-safe applications where the compiler carries the proof.

> **Compatibility (mid-2026):** TypeScript 6.x, Node.js 24 LTS (or Bun 1.2+),
> Vite 8, pnpm 11 / Bun, ESLint 10, Vitest 4, React 19.2, Zod 4.

## Toolchain at a glance

| Tool            | Version                        | Notes                                                  |
| --------------- | ------------------------------ | ------------------------------------------------------ |
| TypeScript      | 6.x stable                     | strict-mode type checking and build                    |
| Runtime         | Node.js 24 LTS **or** Bun 1.2+ | prefer Bun when the project already uses it            |
| Package manager | pnpm 11.x **or** Bun           | Bun if a `bun.lock`/`bunfig.toml` is present           |
| Vite            | 8.x                            | Rolldown (Rust) bundler by default                     |
| ESLint          | 10.x                           | Flat config only; v9 EOL Aug 2026                      |
| Vitest          | 4.x                            | Vite-native test runner (or `bun test`)                |
| Zod             | 4.x                            | Top-level string formats (`z.email()`), big perf gains |

Resolve current docs with context7 before pinning a version — this table ages.

> **Bun if present.** If the repo has a `bun.lock`, `bunfig.toml`, or a Bun-based
> script setup, use Bun for the runtime and package management (`bun install`,
> `bun add`, `bun run`, `bunx`). Otherwise default to Node.js 24 LTS + pnpm 11.
> Bun runs `.ts` directly — no separate transpile step in dev. Node 24 also runs
> `.ts` directly via type stripping (erasable syntax only — pair with the
> `erasableSyntaxOnly` compiler flag; see [references/toolchain.md](references/toolchain.md)).

## Quick start

```bash
# Bun (if the project uses it)
bun create vite my-app --template vanilla-ts
cd my-app && bun install

# Node + pnpm (default)
pnpm create vite@latest my-app --template vanilla-ts
cd my-app && pnpm install
```

Then enable strict checking (see [assets/tsconfig-template.json](assets/tsconfig-template.json)):

```jsonc
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
  },
}
```

## Project setup checklist

```
- [ ] Bun if the repo uses it (bun.lock/bunfig.toml); else pnpm + Node 24 LTS
- [ ] ESM-first ("type": "module" in package.json)
- [ ] strict: true + noUncheckedIndexedAccess + exactOptionalPropertyTypes
- [ ] ESLint 10 flat config with typescript-eslint strictTypeChecked
- [ ] Prettier (or Biome) for formatting
- [ ] Vitest 4 for tests
```

## Core idioms (the short list)

- **`unknown`, never `any`.** Accept `unknown` at boundaries and narrow with guards.
- **`satisfies` over `as`.** Validate a value against a type while keeping its narrow inferred type. Reserve `as` for genuinely unprovable casts.
- **Discriminated unions over optional-field bags.** A literal tag (`kind`/`type`) plus an exhaustive `switch` with a `never` default makes missed cases compile errors.
- **`as const` unions, not `enum`.** Unions are zero-runtime and narrow better.
- **Validate at the edges.** Parse external data (HTTP, env, files) with Zod once; infer the static type from the schema so there is one source of truth.
- **Derive, don't duplicate.** `typeof`, `keyof`, indexed access, `ReturnType`, and `z.infer` keep types tied to a single definition.

### Discriminated union + exhaustiveness

```typescript
type PaymentEvent =
  | { kind: "authorized"; amount: number }
  | { kind: "captured"; amount: number }
  | { kind: "failed"; reason: string };

function describe(e: PaymentEvent): string {
  switch (e.kind) {
    case "authorized":
      return `authorized ${e.amount}`;
    case "captured":
      return `captured ${e.amount}`;
    case "failed":
      return e.reason;
    default:
      return assertNever(e); // compile error when a variant is missed
  }
}

function assertNever(x: never): never {
  throw new Error(`Unhandled variant: ${JSON.stringify(x)}`);
}
```

### `satisfies`

```typescript
// `as` widens and hides bugs; `satisfies` checks and preserves literals.
const palette = {
  primary: "#007bff",
  danger: "#d6336c",
} satisfies Record<string, `#${string}`>;

palette.primary.startsWith("#"); // ok — known to exist, typed as string
```

### Validate at the boundary (Zod 4)

```typescript
import * as z from "zod";

// Zod 4: string formats are top-level (z.email/z.uuid), not z.string().email()
const User = z.object({
  id: z.uuid(),
  name: z.string().min(1).max(100),
  email: z.email(),
  role: z.enum(["user", "admin", "moderator"]),
  createdAt: z.coerce.date(),
});

type User = z.infer<typeof User>; // single source of truth

function parseUser(input: unknown): User {
  return User.parse(input); // throws ZodError on bad input
}

const res = User.safeParse(input);
if (!res.success) console.error(z.treeifyError(res.error));
```

## Common mistakes

| Mistake                | Why it bites                       | Fix                         |
| ---------------------- | ---------------------------------- | --------------------------- |
| Liberal `any`          | Silently disables checking         | `unknown` + narrowing       |
| Skipping strict mode   | Misses null/undefined bugs         | Enable all strict flags     |
| `as` to silence errors | Hides real mismatches              | `satisfies` or a type guard |
| `enum` for simple sets | Emits runtime code, odd narrowing  | `as const` union            |
| Trusting API/env data  | Runtime type lies                  | Zod parse at the boundary   |
| `React.FC` everywhere  | Implies children, weakens generics | Type props directly         |

## Migration strategy (JS → TS)

1. `allowJs: true`, `checkJs: false`, rename entry points to `.ts` gradually.
2. Type the boundaries first (exports, public functions, API responses).
3. Turn on strict flags one at a time; fix the fallout per flag.
4. Use JSDoc `@param`/`@returns` to type `.js` files before renaming when a full rename is risky.

See [references/enterprise-patterns.md](references/enterprise-patterns.md) for the full migration playbook.

## Reference files

Read the one whose topic matches the task — each file repeats its load condition at the top:

- [references/type-system.md](references/type-system.md) — read for annotations, `interface` vs `type`, unions, narrowing, `unknown`/`never`/`void`
- [references/generics.md](references/generics.md) — read for constraints, conditional types, `infer`, mapped types, variance
- [references/enterprise-patterns.md](references/enterprise-patterns.md) — read for error handling, Zod validation, branded types, DI, JS→TS migration
- [references/react-integration.md](references/react-integration.md) — read when typing React components, hooks, events, refs (React 19)
- [references/toolchain.md](references/toolchain.md) — read for project setup, tsconfig, Vite 8, Node 24 / Bun, Vitest 4, CI

### Frameworks & tooling integrations

- [references/nextjs-integration.md](references/nextjs-integration.md) — read for Next.js 16 (App Router, boundaries, linting)
- [references/tanstack-start-integration.md](references/tanstack-start-integration.md) — read for TanStack Start (typed routing, server functions)
- [references/eslint-integration.md](references/eslint-integration.md) — read for ESLint 10 flat config, type-aware rules
- [references/biome-integration.md](references/biome-integration.md) — read for Biome lint + format
- [references/prettier-integration.md](references/prettier-integration.md) — read for Prettier formatting
- [references/oxc-integration.md](references/oxc-integration.md) — read for oxlint / oxfmt (fastest lint/format)
- [references/turborepo-integration.md](references/turborepo-integration.md) — read for monorepo task running & caching

## Assets

Copy these into your project root and adjust:

- [assets/tsconfig-template.json](assets/tsconfig-template.json) — strict `tsconfig.json`
- [assets/eslint-template.js](assets/eslint-template.js) — ESLint 10 flat config
- [assets/biome-template.json](assets/biome-template.json) — `biome.json`
- [assets/prettierrc-template.json](assets/prettierrc-template.json) — `.prettierrc.json`
- [assets/oxlintrc-template.json](assets/oxlintrc-template.json) — `.oxlintrc.json`
- [assets/turbo-template.json](assets/turbo-template.json) — `turbo.json`

## Validation

Before calling TypeScript work done:

- [ ] `tsc --noEmit` passes with `strict` and `noUncheckedIndexedAccess` on
- [ ] No new `any`, `as` casts, or `@ts-expect-error` without a justifying comment
- [ ] External data (HTTP, env, files, storage) is parsed with Zod at the boundary
- [ ] Lint and tests pass (`eslint .` / `biome check`, `vitest run`)
- [ ] Any newly pinned tool versions were verified against current docs (context7), not this skill's table
