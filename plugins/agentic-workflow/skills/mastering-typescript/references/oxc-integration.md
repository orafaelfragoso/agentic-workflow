# Oxc Integration (oxlint / oxfmt / tsgolint)

> **Load when:** the question is about ultra-fast linting/formatting with the Oxc
> (Rust) toolchain — oxlint, type-aware linting via tsgolint, or oxfmt.

Oxc is a JavaScript/TypeScript toolchain written in Rust, built for raw speed.
Unlike Biome's single binary, Oxc ships **separate, installable tools** — pick
what you need:

- **oxlint** — stable (1.x), 50–100× faster than ESLint for syntax rules.
- **tsgolint** — type-aware rules for oxlint, backed by `typescript-go` (TS 7
  engine). No longer "ESLint-only" territory.
- **oxfmt** — Prettier-compatible formatter (separate tool), with VS Code
  integration and native Tailwind class sorting.

## oxlint (syntax rules)

```bash
pnpm add -D oxlint
pnpm oxlint                 # lint the repo, no config needed to start
pnpm oxlint --fix          # apply safe fixes
# Bun: bun add -d oxlint && bunx oxlint
```

Optional config in [assets/oxlintrc-template.json](../assets/oxlintrc-template.json)
(copy it to `.oxlintrc.json` in your project root):

```jsonc
// .oxlintrc.json
{
  "$schema": "https://raw.githubusercontent.com/oxc-project/oxc/main/npm/oxlint/configuration_schema.json",
  "categories": { "correctness": "error", "suspicious": "warn" },
  "rules": {}
}
```

## Type-aware linting (tsgolint)

The 2026 leap: oxlint now runs **type-aware rules** through `tsgolint`, which
builds real TypeScript programs via the Go port of the compiler. It covers ~59 of
61 typescript-eslint type-aware rules (`no-floating-promises`, `await-thenable`,
`no-misused-promises`, …) — repos that took a minute under typescript-eslint
finish in seconds.

```bash
pnpm add -D oxlint-tsgolint
pnpm oxlint --type-aware          # enable typescript/* type-aware rules
pnpm oxlint --type-aware --type-check   # also surface tsc-style type diagnostics
```

```jsonc
// .oxlintrc.json — enable persistently
{ "categories": { "correctness": "error" }, "options": { "typeAware": true } }
```

This makes oxlint a viable **full** linter for many projects, not just a syntax
accelerator. Memory can spike on very large monorepos — keep that path on CI
runners with headroom.

## Running oxlint alongside ESLint

If you still need ESLint plugins oxlint lacks, use oxlint as the fast first gate:

```jsonc
// package.json
{
  "scripts": {
    "lint": "oxlint --type-aware && eslint .",
    "lint:fast": "oxlint"
  }
}
```

`eslint-plugin-oxlint` disables the ESLint rules oxlint already covers so the two
don't double-report.

## oxfmt

```bash
pnpm add -D oxfmt
pnpm oxfmt --check .       # verify (CI)
pnpm oxfmt --write .       # format in place
```

Prettier-compatible output for JS/TS(X), JSON, YAML, HTML, CSS, GraphQL, and
Markdown, with VS Code support (`source.format.oxc`, format-on-save). Pin the
version and review the first repo-wide diff before committing.

## A fully-Oxc setup

```jsonc
// package.json
{
  "scripts": {
    "lint": "oxlint --type-aware",
    "format": "oxfmt --check .",
    "typecheck": "tsgo --noEmit"
  }
}
```

## Choosing

| Situation | Pick |
|-----------|------|
| One fast lint+format binary, framework domains | Biome ([biome-integration.md](biome-integration.md)) |
| Fastest lint **with** type-aware rules | oxlint **+ tsgolint** |
| Need a niche ESLint plugin | ESLint + oxlint accelerator |
| Prettier is the CI bottleneck | oxfmt or Biome |
