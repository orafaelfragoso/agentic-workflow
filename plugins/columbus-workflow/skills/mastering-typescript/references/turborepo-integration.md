# Turborepo Integration (2.x)

> **Load when:** the question is about a TypeScript monorepo — task orchestration,
> caching, boundaries, or wiring shared tsconfig/packages.

`turbo` orchestrates tasks across a workspace (pnpm / Bun / npm workspaces) with
content-aware caching and parallelism: it only rebuilds, re-typechecks, or
re-tests the packages whose inputs actually changed.

## Setup

```bash
pnpm add -D turbo                    # at the workspace root
pnpm dlx turbo run build typecheck   # run tasks across all packages
# Bun: bun add -d turbo && bunx turbo run build typecheck
```

Task graph in [assets/turbo-template.json](../assets/turbo-template.json)
(copy it to `turbo.json` in your workspace root):

```jsonc
// turbo.json
{
  "$schema": "https://turborepo.com/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "typecheck": { "dependsOn": ["^build"] },
    "lint": {},
    "test": { "dependsOn": ["^build"], "outputs": ["coverage/**"] },
    "dev": { "cache": false, "persistent": true },
  },
}
```

`^build` means "build this package's dependencies first". `outputs` tells turbo
what to cache so a clean run can restore artefacts instead of redoing work.
`persistent: true` marks long-running dev servers.

## Inputs & env — keep the cache correct

A wrong cache hit is worse than a miss. Scope task `inputs` and declare every env
var a task reads, or builds that depend on env will be cached incorrectly:

```jsonc
{
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["src/**", "tsconfig.json"],
      "env": ["NODE_ENV"],
      "outputs": ["dist/**"],
    },
  },
}
```

Put framework public env (`NEXT_PUBLIC_*`, `PUBLIC_*`) in `env`/`globalEnv` so a
value change busts the cache.

## Watch mode

`turbo watch` is a dependency-aware watcher: change a package and turbo re-runs
the affected tasks down the graph (handy for `typecheck`/`test` across packages).
For an app you're actively developing, prefer its own bundler watcher (HMR) and
let `turbo watch` drive everything upstream.

```bash
pnpm dlx turbo watch typecheck test
```

## Boundaries — enforce monorepo structure

`turbo boundaries` (experimental) catches the two violations that break caching:
importing a file outside a package, and importing a package not declared in its
`package.json`. Add **tags** to express architectural rules — e.g. a `public`
package may not depend on an `internal` one:

```jsonc
// packages/ui/turbo.json  (package-level config only)
{ "tags": ["internal"] }
```

```jsonc
// turbo.json (root)
{
  "boundaries": {
    "tags": { "internal": { "dependents": { "allow": ["web"] } } },
  },
}
```

## Workspace layout

```
my-monorepo/
├── turbo.json
├── pnpm-workspace.yaml        # packages: ["apps/*", "packages/*"]
├── tsconfig.base.json         # shared strict compiler options
├── apps/web/                  # extends ../../tsconfig.base.json
└── packages/ui/               # extends ../../tsconfig.base.json
```

Each package extends the shared base and has `build`/`typecheck`/`test` scripts.

```jsonc
// packages/ui/tsconfig.json
{ "extends": "../../tsconfig.base.json", "include": ["src"] }
```

For type-safe references across packages, either set `composite: true` in the base
and use `tsc --build`, or rely on `moduleResolution: "bundler"` + each app's
bundler to resolve workspace packages directly. With Bun/pnpm, `workspace:*`
deps link source so types update without a build step in dev.

## CI

```bash
pnpm install --frozen-lockfile
pnpm dlx turbo run typecheck lint test build   # cached: only affected packages run
```

**Remote caching** shares cached artefacts across machines and CI, so a green
build on one runner isn't recomputed on the next. Pairs cleanly with pnpm or Bun
workspaces — see [toolchain.md](toolchain.md) for the package managers.
