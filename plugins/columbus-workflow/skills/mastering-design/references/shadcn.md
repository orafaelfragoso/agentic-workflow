# shadcn/ui

> **Load when:** the task uses shadcn/ui components — setup, adding components,
> theming the semantic tokens, customizing or composing components, or deciding
> between building and installing.

shadcn/ui is **code distribution, not a dependency**: the CLI copies component
source into your repo and you own it from then on. Current CLI supports
Tailwind v4 and React 19; components are built on Radix primitives with
accessibility (keyboard, ARIA, focus management) already wired.

## Setup

```bash
pnpm dlx shadcn@latest init        # writes components.json, installs tokens/utils
pnpm dlx shadcn@latest add button card dialog form
```

`components.json` records style, base color, CSS variable mode, and import
aliases — the CLI reads it for every `add`. Don't hand-edit components into
the project when the CLI can add them; the CLI wires imports and dependencies.

## The semantic token system

shadcn themes through paired CSS variables defined in `:root` and `.dark`,
mapped into Tailwind via `@theme inline`:

```css
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);
  --radius: 0.625rem;
}
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  /* … full parallel set, not an inversion */
}

@theme inline {
  --color-background: var(--background);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  /* … */
  --radius-lg: var(--radius);
  --radius-md: calc(var(--radius) * 0.8);
}
```

Rules that keep theming coherent:

- **Every `x` pairs with `x-foreground`.** Text placed on `bg-primary` is
  `text-primary-foreground` — never a hardcoded white/black. Honoring the pairs
  is what makes retheming and dark mode one-file changes.
- **Components use only semantic tokens.** `bg-background`, `text-muted-foreground`,
  `border-border`, `ring-ring`. Raw palette values live solely in the `:root`/`.dark`
  definitions. To rebrand, change the variables — not the components.
- **Radius flows from one `--radius` variable.** Change it once; every component follows.
- Theme changes happen in CSS variables; component changes happen in the
  component file. Don't blur the two.

## Customizing components (you own the code)

- **Do** edit the copied component directly — that's the model. Add a variant
  to the `cva()` definition rather than sprinkling override classes at call sites:

  ```tsx
  const buttonVariants = cva("...", {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        soft: "bg-primary/10 text-primary hover:bg-primary/20", // added
      },
    },
  });
  ```

- **Do** keep the `className` prop merged through `cn(...)` so call sites can
  still adjust layout (margins, width) without forking.
- **Don't** strip the Radix wiring (`aria-*`, `data-state`, focus traps,
  `asChild` slots) while restyling — that's the part you can't cheaply rebuild.
- **Don't** wrap a shadcn component in another component that only re-passes
  props to override its look. Edit the source you already own.
- Re-running `add` for an already-installed component overwrites local edits —
  diff before accepting.

## Composition patterns

- `asChild` merges behavior into your element instead of nesting interactive
  elements: `<Button asChild><Link href="/docs">Docs</Link></Button>`.
- Compound components stay together: `Dialog` + `DialogTrigger` + `DialogContent`;
  `Form` (react-hook-form + zod) wires label, control, description, and error
  with correct `aria-describedby` — use `FormField` instead of hand-rolling.
- Prefer the registry before building: check `pnpm dlx shadcn@latest add` for an
  existing solution (combobox, command palette, data table, sidebar, chart) and
  community registries before writing a new primitive from scratch.

## Dos and don'ts

| Do                                                         | Don't                                                       |
| ----------------------------------------------------------- | ----------------------------------------------------------- |
| Add via CLI, then edit your copy                            | Treat shadcn like a locked npm dependency                   |
| Semantic tokens in every component                          | `bg-white dark:bg-zinc-900` hardcoded per component         |
| New looks as `cva` variants                                 | Per-call-site override class stacks                         |
| Respect `x`/`x-foreground` pairing                          | `text-white` on `bg-primary`                                |
| Keep focus/ARIA behavior intact when restyling              | `outline-none` and removed `data-state` styling             |
| One `--radius`, one `--ring`, themed in `:root`/`.dark`     | Per-component radius and focus-ring colors                  |

## Verification

- Toggle `.dark` and tab through the changed screens: every component readable, every focus ring visible, in both themes.
- `grep -rnE "bg-(white|black|zinc|gray|slate)-?" src/components/` — hits inside shadcn-styled components are usually token violations.
- Open dialogs/menus and confirm Escape, arrow keys, and focus return still work after customization.
