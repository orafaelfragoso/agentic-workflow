# Prettier Integration (3.7+)

> **Load when:** the question is about formatting TypeScript with Prettier —
> setup, config, caching, or pairing it with ESLint.

Prettier is the mature, opinionated formatter with the widest plugin ecosystem
(Tailwind class sorting, import sorting, etc.). It only **formats** — pair it
with ESLint for linting, or with a fast linter like oxlint. Prettier 3.6+ ships
an experimental **fast CLI** (`--experimental-cli`) and `--cache` for big speedups
on large repos.

## Setup

```bash
pnpm add -D prettier
# Bun: bun add -d prettier
```

```bash
pnpm prettier --write .              # format in place
pnpm prettier --check .              # verify in CI (non-zero exit if unformatted)
pnpm prettier --write --cache .      # only reformat changed files
```

A starter config is in [assets/prettierrc-template.json](../assets/prettierrc-template.json)
(copy it to `.prettierrc.json` in your project root). Common settings:

```jsonc
// .prettierrc.json
{
  "printWidth": 100,
  "singleQuote": false,
  "trailingComma": "all",
  "semi": true
}
```

Add a `.prettierignore` (mirror `.gitignore`: `dist`, `coverage`, `*.gen.ts`).

## Pairing with ESLint

Let Prettier own formatting and ESLint own correctness — run them as separate
steps. Modern `typescript-eslint` stylistic presets are formatter-safe; if a rule
ever conflicts, drop the **ESLint rule**, not Prettier. (`eslint-config-prettier`
is rarely needed now but still disables any stray conflicting rule.)

```jsonc
// package.json
{
  "scripts": {
    "format": "prettier --write --cache .",
    "format:check": "prettier --check .",
    "lint": "eslint ."
  }
}
```

## Useful plugins

```bash
pnpm add -D prettier-plugin-tailwindcss   # sorts Tailwind classes deterministically
pnpm add -D @ianvs/prettier-plugin-sort-imports
```

```jsonc
// .prettierrc.json
{ "plugins": ["prettier-plugin-tailwindcss"] }
```

Tailwind plugin must load **last** if combining multiple plugins.

## Faster alternatives

For large repos where Prettier is the CI bottleneck, **Biome** (see
[biome-integration.md](biome-integration.md)) or **oxfmt** (see
[oxc-integration.md](oxc-integration.md)) format the same code 30×+ faster, at
the cost of fewer plugins. Prettier remains the safest default for plugin-heavy
or mixed-language projects; reach for the alternatives when formatting time —
not plugin coverage — is the constraint.
