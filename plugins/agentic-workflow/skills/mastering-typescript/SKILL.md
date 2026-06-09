---
name: mastering-typescript
description: Master modern, type-safe TypeScript — type-system depth (generics, mapped/conditional types, satisfies), enterprise patterns (Result-style error handling, Zod 4 validation at boundaries), type-safe React, and a current toolchain (Vite 8, Node 24 or Bun, ESLint 10, Vitest 4). Use when building or reviewing type-safe apps, migrating JavaScript to TypeScript, configuring tsconfig/toolchains, or implementing advanced type patterns.
---

# Mastering Modern TypeScript

Build type-safe applications where the compiler carries the proof.

> **Compatibility (mid-2026):** TypeScript 6.x, Node.js 24 LTS (or Bun 1.2+),
> Vite 8, pnpm 11 / Bun, ESLint 10, Vitest 4, React 19.2, Zod 4.

## Toolchain at a glance

| Tool | Version | Notes |
|------|---------|-------|
| TypeScript | 6.x stable | strict-mode type checking and build |
| Runtime | Node.js 24 LTS **or** Bun 1.2+ | prefer Bun when the project already uses it |
| Package manager | pnpm 11.x **or** Bun | Bun if a `bun.lock`/`bunfig.toml` is present |
| Vite | 8.x | Rolldown (Rust) bundler by default |
| ESLint | 10.x | Flat config only; v9 EOL Aug 2026 |
| Vitest | 4.x | Vite-native test runner (or `bun test`) |
| Zod | 4.x | Top-level string formats (`z.email()`), big perf gains |

Resolve current docs with context7 before pinning a version — this table ages.

> **Bun if present.** If the repo has a `bun.lock`, `bunfig.toml`, or a Bun-based
> script setup, use Bun for the runtime and package management (`bun install`,
> `bun add`, `bun run`, `bunx`). Otherwise default to Node.js 24 LTS + pnpm 11.
> Bun runs `.ts` directly — no separate transpile step in dev.

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
    "skipLibCheck": true
  }
}
```

## When to use this skill

- Building type-safe React or Node apps and want the patterns to be correct, not just compiling.
- Migrating a JavaScript codebase to TypeScript incrementally.
- Implementing advanced types (generics, mapped/conditional types, template literals).
- Configuring a modern toolchain (Vite, pnpm, ESLint flat config, Vitest).
- Designing API contracts validated at runtime with Zod 4.

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
type Result<T, E = string> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function unwrap<T>(r: Result<T>): T {
  switch (r.ok) {
    case true:
      return r.value;
    case false:
      throw new Error(r.error);
    default:
      return assertNever(r);
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

| Mistake | Why it bites | Fix |
|---------|--------------|-----|
| Liberal `any` | Silently disables checking | `unknown` + narrowing |
| Skipping strict mode | Misses null/undefined bugs | Enable all strict flags |
| `as` to silence errors | Hides real mismatches | `satisfies` or a type guard |
| `enum` for simple sets | Emits runtime code, odd narrowing | `as const` union |
| Trusting API/env data | Runtime type lies | Zod parse at the boundary |
| `React.FC` everywhere | Implies children, weakens generics | Type props directly |

## Migration strategy (JS → TS)

1. `allowJs: true`, `checkJs: false`, rename entry points to `.ts` gradually.
2. Type the boundaries first (exports, public functions, API responses).
3. Turn on strict flags one at a time; fix the fallout per flag.
4. Use JSDoc `@param`/`@returns` to type `.js` files before renaming when a full rename is risky.

See [references/enterprise-patterns.md](references/enterprise-patterns.md) for the full migration playbook.

## Reference files

- [references/type-system.md](references/type-system.md) — annotations, interfaces vs types, unions, narrowing, special types
- [references/generics.md](references/generics.md) — constraints, conditional types, `infer`, mapped types, variance
- [references/enterprise-patterns.md](references/enterprise-patterns.md) — error handling, Zod validation, branded types, DI, migration
- [references/react-integration.md](references/react-integration.md) — typed components, hooks, events, generic components (React 19)
- [references/toolchain.md](references/toolchain.md) — Vite 8, Node 24 / Bun, Vitest 4, build & CI

### Frameworks & tooling integrations

- [references/nextjs-integration.md](references/nextjs-integration.md) — Next.js 16 (App Router, boundaries, linting)
- [references/tanstack-start-integration.md](references/tanstack-start-integration.md) — TanStack Start (typed routing, server functions)
- [references/eslint-integration.md](references/eslint-integration.md) — ESLint 10 flat config, type-aware rules
- [references/biome-integration.md](references/biome-integration.md) — Biome lint + format
- [references/prettier-integration.md](references/prettier-integration.md) — Prettier formatting
- [references/oxc-integration.md](references/oxc-integration.md) — oxlint / oxfmt (fastest)
- [references/turborepo-integration.md](references/turborepo-integration.md) — monorepo task running & caching

## Assets

Copy these into your project root and adjust:

- [assets/tsconfig-template.json](assets/tsconfig-template.json) — strict `tsconfig.json`
- [assets/eslint-template.js](assets/eslint-template.js) — ESLint 10 flat config
- [assets/biome-template.json](assets/biome-template.json) — `biome.json`
- [assets/prettierrc-template.json](assets/prettierrc-template.json) — `.prettierrc.json`
- [assets/oxlintrc-template.json](assets/oxlintrc-template.json) — `.oxlintrc.json`
- [assets/turbo-template.json](assets/turbo-template.json) — `turbo.json`
