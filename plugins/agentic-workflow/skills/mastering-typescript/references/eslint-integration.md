# ESLint Integration (10.x)

> **Load when:** the question is about linting TypeScript with ESLint — flat
> config, type-aware rules, `typescript-eslint`, or framework configs.

ESLint 10 is **flat-config only** (legacy `.eslintrc` is gone). It has the
deepest rule and plugin ecosystem and, via `typescript-eslint`, the most complete
set of **type-aware** rules. Use it when rule/plugin coverage matters most;
otherwise see [biome-integration.md](biome-integration.md) or
[oxc-integration.md](oxc-integration.md) for faster options.

## Setup

```bash
pnpm add -D eslint @eslint/js typescript-eslint
# Bun: bun add -d eslint @eslint/js typescript-eslint
```

Full config in [assets/eslint-template.js](../assets/eslint-template.js):

```js
// eslint.config.js
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,      // strictest; catches real bugs
  ...tseslint.configs.stylisticTypeChecked,   // consistency (type-aware)
  {
    languageOptions: {
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
  },
  { ignores: ["dist/**", "coverage/**", "**/*.gen.ts"] },
);
```

`projectService: true` enables type-aware linting without listing every
`tsconfig` — required for the `*TypeChecked` presets. It auto-includes files; use
`allowDefaultProject` for stray config files outside the TS project.

```jsonc
// package.json
{ "scripts": { "lint": "eslint .", "lint:fix": "eslint . --fix" } }
```

## Framework configs

Compose framework presets into the same flat array:

```js
import nextPlugin from "@next/eslint-plugin-next"; // or eslint-config-next
import reactHooks from "eslint-plugin-react-hooks";

export default tseslint.config(
  // ...base,
  reactHooks.configs["recommended-latest"], // enforces Rules of Hooks (incl. RC)
  // next/react plugin blocks here
);
```

`eslint-plugin-react-hooks` v6 ships flat presets and the React Compiler rule.

## Type-aware rules worth enabling

The template turns these on; they catch bugs no syntax linter can:

- `no-floating-promises` / `no-misused-promises` — unhandled async.
- `await-thenable` — awaiting a non-Promise.
- `no-unnecessary-condition` — dead branches the types prove unreachable.
- `consistent-type-imports` — `import type` for predictable emit/tree-shaking
  (pairs with `verbatimModuleSyntax`).
- `consistent-type-assertions` (objectLiteral `never`) — pushes you to
  `satisfies` over `as` on object literals.
- `restrict-template-expressions` — no accidental `[object Object]` in strings.

## Pair with a formatter, don't fight one

Let Prettier or Biome own formatting; let ESLint own correctness. Run them as
separate scripts and **don't** enable stylistic ESLint rules that conflict with
your formatter — drop the rule, not the formatter. The `*TypeChecked` presets are
already formatter-safe. See [prettier-integration.md](prettier-integration.md).

## Speed it up

Type-aware ESLint is the slow part of CI. Two accelerators:

- **oxlint first** as a fast syntax gate; `eslint-plugin-oxlint` disables the
  overlap so you don't double-report. See [oxc-integration.md](oxc-integration.md).
- For the type-aware rules themselves, **oxlint + tsgolint** now runs nearly the
  whole typescript-eslint type-aware set in seconds — consider it when
  `projectService` linting dominates CI time.

Cache in CI with `eslint --cache` and lint only changed packages in a monorepo
(see [turborepo-integration.md](turborepo-integration.md)).
