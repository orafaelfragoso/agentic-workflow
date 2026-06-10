# Modern Toolchain

> **Load when:** the question is about project setup, build tooling, package
> management, linting, testing, or CI for a TypeScript project.

A current, batteries-included setup (mid-2026). Pin against live docs via
context7 before locking versions — this ecosystem moves fast.

| Tool            | Version                        | Role                                         |
| --------------- | ------------------------------ | -------------------------------------------- |
| TypeScript      | 6.x                            | type checking / build                        |
| Runtime         | Node.js 24 LTS **or** Bun 1.2+ | use Bun when the project already does        |
| Package manager | pnpm 11.x **or** Bun           | Bun if `bun.lock`/`bunfig.toml` present      |
| Vite            | 8.x                            | dev server / bundler (Rolldown)              |
| ESLint          | 10.x                           | linting (flat config)                        |
| Vitest          | 4.x                            | testing (or `bun test`)                      |
| Prettier        | 3.x                            | formatting (or Biome for lint+format in one) |

## Runtime & package management

**Detect first.** If the repo has a `bun.lock`, `bunfig.toml`, or Bun-based
scripts, use **Bun** for runtime and packages. Otherwise default to **Node 24
LTS + pnpm 11**. Don't mix managers — match the lockfile that's committed.

### Bun (if present)

Bun is an all-in-one runtime, package manager, and bundler that executes `.ts`
and `.tsx` directly — no separate transpile step in dev.

```bash
bun install
bun add zod
bun add -d typescript vitest
bun run dev        # run a package.json script
bunx <tool>        # one-off binary (like npx)
```

Bun reads `package.json` and writes `bun.lock`; per-project settings live in
`bunfig.toml`. It still does **not** type-check — run `tsc --noEmit` (below).

### Node 24 runs TypeScript directly

Node 24 executes `.ts` files natively (`node index.ts`) by **stripping types** —
no flags, no loader. Only *erasable* syntax is supported: `enum`, `namespace`,
parameter properties, and `import x = require()` need real transpilation. For
Node-run projects (scripts, servers without a bundler), enable the matching
compiler flag so `tsc` rejects non-erasable syntax up front:

```jsonc
{ "compilerOptions": { "erasableSyntaxOnly": true } }
```

This pairs naturally with the "`as const` unions, not `enum`" idiom — erasable
code needs no build step on either Node or Bun. Type stripping is execution
only; keep `tsc --noEmit` as the type gate.

### pnpm 11 (default)

Fast and disk-efficient (content-addressed store, hard links) and strict about
phantom dependencies.

```bash
corepack enable          # ships with Node; pins the pnpm version per-project
pnpm install
pnpm add zod
pnpm add -D typescript vitest
```

pnpm 11 is pure ESM and needs Node 22+. Supply-chain guards are on by default —
`minimumReleaseAge` holds back just-published versions and `blockExoticSubdeps`
blocks non-registry transitive deps. Commit `pnpm-lock.yaml`; use
`pnpm-workspace.yaml` for monorepos.

## Build / dev — Vite 8

Vite 8 uses **Rolldown** (a Rust bundler) under the hood for much faster builds
with the same plugin model. Scaffold and run (swap `pnpm` for `bun` if the
project uses Bun):

```bash
pnpm create vite@latest my-app --template react-ts   # or vanilla-ts
cd my-app && pnpm install
pnpm dev          # dev server with HMR
pnpm build        # production build
pnpm preview      # serve the build locally
```

Vite handles transpilation; it does **not** type-check. Run `tsc` separately so
type errors fail the build:

```jsonc
// package.json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "tsc --noEmit && vite build",
  },
}
```

## TypeScript config

Start from [assets/tsconfig-template.json](../assets/tsconfig-template.json).
The non-negotiables:

```jsonc
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler", // for Vite/bundler-driven projects
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true, // explicit `import type`; predictable emit
    "isolatedModules": true, // each file transpiles alone (Vite/esbuild)
    "skipLibCheck": true, // skip checking .d.ts of deps — faster
  },
}
```

`moduleResolution: "bundler"` suits Vite. For a Node library you ship directly,
use `"nodenext"` and set `"module": "nodenext"`. Under Bun, keep
`"moduleResolution": "bundler"`, install `@types/bun`, and set
`"types": ["bun"]` for Bun's APIs.

## Linting & formatting

Pick one lane and stay consistent. Each has its own integration doc:

- **ESLint 10** (flat config, type-aware rules) — [eslint-integration.md](eslint-integration.md)
- **Biome** (one Rust binary, lint **+** format) — [biome-integration.md](biome-integration.md)
- **Prettier** (the default formatter) — [prettier-integration.md](prettier-integration.md)
- **Oxc** (oxlint / oxfmt, fastest) — [oxc-integration.md](oxc-integration.md)

Rule of thumb: Biome for one fast tool with minimal config; ESLint (+Prettier)
when type-aware rules or niche plugins matter; add oxlint when lint speed is the
bottleneck.

## Testing — Vitest 4

Vitest shares Vite's config and transform pipeline, so TS, path aliases, and
plugins "just work".

```typescript
// math.test.ts
import { describe, it, expect } from "vitest";
import { add } from "./math";

describe("add", () => {
  it("sums", () => {
    expect(add(2, 3)).toBe(5);
  });
});
```

```bash
pnpm vitest          # watch mode
pnpm vitest run      # single run (CI)
pnpm vitest --coverage
```

On Bun, you can run Vitest the same way (`bunx vitest run`) or use Bun's built-in,
Jest-compatible runner for fast unit tests:

```bash
bun test             # uses Bun's native runner
```

Use `expectTypeOf` / `assertType` for **type-level** tests when a public type
contract matters. Type tests live in `*.test-d.ts` files by default and only
run with the `--typecheck` flag (`vitest --typecheck`):

```typescript
// add.test-d.ts
import { assertType, expectTypeOf } from "vitest";
expectTypeOf(add).parameters.toEqualTypeOf<[number, number]>();
// @ts-expect-error strings are not accepted
assertType(add("1", "2"));
```

## Formatting

Prettier 3 is the default; or use Biome to lint and format with one tool.

```bash
pnpm add -D prettier
pnpm prettier --write .
```

## CI pipeline (the four gates)

Run these in order; fail the build on any (swap `pnpm` for `bun` on Bun
projects; use `bun install --frozen-lockfile`):

```bash
pnpm install --frozen-lockfile
pnpm typecheck      # tsc --noEmit
pnpm lint           # eslint .
pnpm vitest run     # tests
pnpm build          # production build
```
