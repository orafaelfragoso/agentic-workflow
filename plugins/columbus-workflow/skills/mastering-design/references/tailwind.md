# Tailwind CSS v4

> **Load when:** the task involves Tailwind setup or theming, design tokens,
> dark mode variants, responsive or container queries, or utility-class style
> decisions.

Tailwind v4 is **CSS-first**: configuration lives in your stylesheet, not
`tailwind.config.js`. One import, tokens as CSS variables, utilities generated
from them.

## Setup and theme

```css
@import "tailwindcss";

@theme {
  --font-sans: "Inter", system-ui, sans-serif;
  --font-display: "Satoshi", var(--font-sans);

  --color-brand-500: oklch(0.65 0.18 255);
  --color-brand-600: oklch(0.55 0.16 255);

  --breakpoint-3xl: 1920px;

  --ease-fluid: cubic-bezier(0.3, 0, 0, 1);
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
}
```

Every `@theme` variable generates utilities (`bg-brand-500`, `font-display`,
`ease-snappy`) **and** is available as a plain CSS variable
(`var(--color-brand-500)`) for the rare cases utilities can't reach.

- Use `@theme inline` when a token references another runtime variable (the
  shadcn pattern: `--color-background: var(--background)`).
- Reset a namespace before redefining it from scratch: `--color-*: initial;`.
- Define keyframes inside `@theme` next to the `--animate-*` token that uses them.

## Token discipline

- **Do** extend `@theme` when a value you need is missing. A new token is the
  fix for a missing token — an arbitrary value is not.
- **Do** use semantic tokens (`bg-background`, `text-muted-foreground`) in
  components and raw palette tokens (`bg-brand-500`) only inside the semantic
  layer's definition. See [color.md](color.md).
- **Don't** use arbitrary values (`w-[417px]`, `text-[#3b82f6]`) except for
  one-off truly content-driven numbers (e.g. an image's intrinsic aspect
  ratio) — and say why in a comment.
- **Don't** mix spacing systems: if the app uses the default 4px-based scale,
  `p-4 gap-2` belongs; `p-[15px]` never does.

## Custom utilities and variants

```css
/* Repeated pattern → named utility (participates in variants: hover:card-edge) */
@utility card-edge {
  @apply rounded-lg border bg-card text-card-foreground shadow-sm;
}

/* Class-based dark mode (what shadcn uses) */
@custom-variant dark (&:is(.dark *));
```

- **Do** reach for `@utility` only after the same cluster of 4+ classes appears
  in three places — prefer extracting a component first in React codebases.
- **Don't** build `@apply` mega-classes that recreate Bootstrap; the utility
  model's value is co-located, greppable styling.

## Layout rules of thumb

- **Mobile-first**: write the base for small screens, add `md:`/`lg:` upward.
  `class="flex-col md:flex-row"`, not the inverse with `max-md:`.
- **Gap over margins** between siblings: `flex flex-col gap-4` instead of
  `space-y-*` or per-child `mb-*`. Margins are for relationships to outside
  context, gaps for internal rhythm.
- **Container queries for components**, media queries for page layout:

  ```html
  <div class="@container">
    <article class="grid @md:grid-cols-2 @xl:grid-cols-3">…</article>
  </div>
  ```

  A card that rearranges based on **its own width** survives being dropped
  into any column.

- Constrain line length with `max-w-prose` (or `max-w-[65ch]`) on body text —
  see [typography.md](typography.md).

## State styling

- Order interactive states completely: `hover:` `focus-visible:` `active:`
  `disabled:` — a button with only `hover:` feels broken on keyboard and touch.
- Use `focus-visible:` (not `focus:`) for focus rings so mouse clicks don't
  flash rings, and never `outline-none` without a replacement ring.
- Style off ARIA and data attributes instead of JS class juggling:
  `aria-expanded:rotate-180`, `data-[state=open]:animate-in`.
- Group-driven styling for parent-child hover: `group` + `group-hover:opacity-100`.

## Dos and don'ts

| Do                                                        | Don't                                                  |
| --------------------------------------------------------- | ------------------------------------------------------ |
| `@import "tailwindcss"` + `@theme` (v4)                    | Port a `tailwind.config.js` into new v4 projects       |
| Define colors in OKLCH                                     | Mix hex, hsl, and oklch token formats                  |
| `gap-*` for sibling rhythm                                 | `mb-*` chains that break when items reorder            |
| `prettier-plugin-tailwindcss` for class order              | Hand-sorted (i.e. unsorted) class soup                 |
| `cn()`/`tailwind-merge` when props add classes             | String-concatenating conflicting classes               |
| `motion-safe:`/`motion-reduce:` on animations              | Unconditional `animate-*` ([micro-interactions.md](micro-interactions.md)) |
| Check generated CSS size when adding huge safelists        | Safelisting entire namespaces "just in case"           |

## Verification

- Visual check in both themes: toggle `.dark` on `<html>` and confirm tokens flip.
- `grep -rn "\[#" src/` and `grep -rnE "\[[0-9]+px\]" src/` — every hit needs a justification or a token.
- Build once and skim the CSS output size; v4 only ships used utilities, so a bloated file means a safelist or content misconfiguration.
