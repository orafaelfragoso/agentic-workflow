# Design Systems

> **Load when:** the task involves creating, extending, or auditing a design
> system — token architecture, component API design, naming, documentation, or
> keeping an app consistent as it grows.

A design system is the **single source of truth** that makes fifty screens look
like one product: tokens, components, patterns, and the rules for changing
them. In code-first teams the system _is_ the theme file plus the component
library — treat both as a public API.

## Token architecture: three tiers

```
primitive  →  semantic  →  component (only when needed)
--blue-600    --primary     --button-bg (rare)
```

1. **Primitives** — the raw scales: color ramps, spacing steps, type sizes,
   radii, shadows, easings. No opinions, never referenced by components.
2. **Semantic tokens** — meaning, not value: `background`, `primary`,
   `muted-foreground`, `border`, `ring`. This is the layer components consume
   and the layer themes (dark mode, brands) swap. See [color.md](color.md) and
   [shadcn.md](shadcn.md).
3. **Component tokens** — only when a component must diverge from the semantic
   layer across themes (`--sidebar`, `--chart-1`). Each one is maintenance
   cost; default to semantic.

Rules:

- Changes flow downward: rebrand by remapping semantic → primitive, not by
  editing components.
- A token must answer "when do I use this?" by its name. `--color-blue-2` fails;
  `--color-surface-raised` passes.
- Kill aliases that mean the same thing (`--gray` vs `--neutral`); one concept,
  one token.

## Component API design

Components are the second half of the system; their props are a contract.

- **Variants, not booleans.** `variant="destructive" size="sm"` scales;
  `isRed isSmall isOutlined` explodes combinatorially. Encode with `cva` and
  export the variant types.
- **Composition over configuration.** When a component grows a prop for every
  use case (`titleIcon`, `footerButtons`, `headerExtra`), break it into
  compound parts (`Card`, `CardHeader`, `CardFooter`) and let callers compose.
- **Constrain, then escape.** Expose the designed options as props; keep
  `className` merged via `cn()` as the escape hatch for layout concerns
  (width, margin) — not for restyling internals.
- Spread rest props onto the root element and forward refs — system components
  must not block native attributes, testing ids, or focus management.
- States are part of the spec: every interactive component defines hover,
  focus-visible, active, disabled, loading, and error appearance before it ships.

## Naming and structure

- One casing convention per layer (`kebab-case` tokens, `PascalCase`
  components, `camelCase` props) applied without exception.
- Name by role, not appearance: `Callout`, not `YellowBox` — appearance changes,
  role doesn't.
- Sizes are a closed scale (`sm | md | lg`), shared across components. A
  `Button sm` next to an `Input sm` must align.
- Co-locate each component with its variants, stories/examples, and tests; the
  system's folder layout is its table of contents.

## Governance: keeping it a system

Drift, not bad initial design, is how systems die.

- **Extend, don't fork.** A new need is first a new variant or token proposal;
  a copy-pasted `Button2.tsx` is a bug. If a one-off is truly required, mark it
  loudly as off-system with the reason.
- **The system changes by PR, not by override.** Local overrides that "fix"
  a system component at one call site hide the defect the system has.
- Audit periodically: grep for raw hex/pixel values, count distinct font sizes
  and radii in the rendered app, list components that duplicate a system
  component's role ([tailwind.md](tailwind.md) has the greps).
- Document the _why_ alongside the _what_: each component's doc states when to
  use it, when not to, and which alternative serves the rejected case. Record
  system-level decisions (token renames, breaking variant changes) durably —
  as ADRs where the project keeps them.
- Version consciously: a renamed token or removed variant is a breaking change
  for every screen; provide both for a deprecation window and grep before
  deleting.

## Dos and don'ts

| Do                                                  | Don't                                    |
| --------------------------------------------------- | ---------------------------------------- |
| Three-tier tokens; components consume semantic only | Components reading `--blue-600` directly |
| `variant`/`size` enums via `cva`                    | Boolean prop explosions                  |
| Compound components for flexible layouts            | God components with 20 slot props        |
| One shared size scale across components             | Per-component notions of "small"         |
| New needs → token/variant proposals                 | Copy-paste forks and call-site restyling |
| Deprecation windows for token/variant removal       | Silent renames that break screens        |
| Usage docs with "when not to use"                   | Prop tables with no guidance             |

## Verification

- Pick three screens built months apart: same radii, spacing rhythm, type scale, and button anatomy — differences are drift to file.
- Grep the app for raw values and off-system one-offs; each hit gets a token, a variant, or a documented exemption.
- Review a new feature's diff: it should consume the system (tokens + existing components) with near-zero new CSS.
