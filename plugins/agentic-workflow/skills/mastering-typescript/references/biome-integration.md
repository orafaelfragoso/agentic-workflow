# Biome Integration (2.x)

> **Load when:** the question is about linting and/or formatting with Biome —
> setup, config, domains, assist actions, or replacing ESLint + Prettier.

Biome is an all-in-one Rust toolchain that **lints, formats, and organizes
imports** from a single binary with near-zero config. Biome 2 added **type-aware
rules without needing `tsc`** (its own type inference), **domains**, **assist
actions**, and **GritQL plugins** — making it the most practical full ESLint +
Prettier replacement for most projects: one dependency, one config, very fast.

## Setup

```bash
pnpm add -D --save-exact @biomejs/biome
pnpm biome init        # writes biome.json
# Bun: bun add -d --exact @biomejs/biome && bunx biome init
```

Pin the exact version (`--save-exact`) — formatter output can shift between
minor versions, and you want reproducible diffs.

## Commands

```bash
pnpm biome check .            # lint + format check + import sort (read-only)
pnpm biome check --write .    # apply all safe fixes
pnpm biome check --write --unsafe .  # include unsafe fixes (review the diff)
pnpm biome format --write .   # format only
pnpm biome lint .             # lint only
```

```jsonc
// package.json
{
  "scripts": {
    "check": "biome check .",
    "fix": "biome check --write ."
  }
}
```

A starter config is in [assets/biome-template.json](../assets/biome-template.json)
(copy it to `biome.json` in your project root).

## Domains — framework-aware rules

Enable curated rule sets per domain instead of hand-picking rules. `react`,
`next`, `solid`, `test`, and `a11y` are auto-enabled when Biome detects the
matching dependency in `package.json`, or set them explicitly:

```jsonc
// biome.json
{
  "linter": {
    "domains": {
      "react": "recommended",
      "next": "recommended",
      "test": "all"
    }
  }
}
```

## Assist actions (imports & more)

In Biome 2, `organizeImports` moved under **`assist.actions`** (the old top-level
key is migrated automatically by `biome migrate`). Group imports deterministically:

```jsonc
// biome.json
{
  "assist": {
    "actions": {
      "source": {
        "organizeImports": {
          "level": "on",
          "options": {
            "groups": [":NODE:", ":BLANK_LINE:", ["@app/**"], "**"]
          }
        }
      }
    }
  }
}
```

## Type-aware rules

Biome 2 infers types **without** a full `tsc` program, so rules like
`noFloatingPromises` work out of the box — much faster than typescript-eslint,
though coverage is narrower. For the full type-aware ESLint rule set, keep ESLint
or add oxlint's `tsgolint` (see below).

## Monorepo config

Biome supports **nested `biome.json`** files: a package-level config `extends` the
root and overrides locally. Run a single `biome check .` from the root; each file
resolves the nearest config.

## Plugins (GritQL)

Write custom lint rules as GritQL patterns without compiling a plugin — point
`plugins` at `.grit` files for project-specific checks.

## Migrating from ESLint + Prettier

Biome reads your existing config and ports most rules automatically:

```bash
pnpm biome migrate eslint --write
pnpm biome migrate prettier --write
```

Then delete `.eslintrc*` / `.prettierrc*` once the diff looks right.

## When to keep ESLint instead

Biome covers the common rules and basic type-aware ones, but not the entire
typescript-eslint rule set or the full plugin universe. If you depend on **deep
type-aware** rules or a niche plugin, stay on ESLint
([eslint-integration.md](eslint-integration.md)) or run **oxlint + tsgolint** as
a fast type-aware accelerator ([oxc-integration.md](oxc-integration.md)).

| Want | Use |
|------|-----|
| One fast tool, minimal config | **Biome** |
| Framework-aware rules with zero wiring | Biome **domains** |
| Full typescript-eslint type-aware set | ESLint, or oxlint + tsgolint |
| Niche ESLint plugin | ESLint (+ Prettier) |
