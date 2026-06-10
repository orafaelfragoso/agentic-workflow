---
name: mastering-design
description: Master professional UI design and implementation — design tokens and theming with Tailwind CSS v4, shadcn/ui components, UX principles, micro-interactions, animation with Motion (formerly Framer Motion), color science (OKLCH, contrast, dark mode), and typography. Use when building or improving user interfaces, when asked to make a UI "look professional", "polished", or "better", when styling with Tailwind or shadcn, designing color palettes or dark mode, choosing fonts, adding animations, transitions, or motion design, building or auditing a design system, or reviewing UX and accessibility.
---

# Mastering Design

Produce interfaces that look professionally designed: consistent tokens, clear hierarchy, purposeful motion, accessible by default.

> **Compatibility (mid-2026):** Tailwind CSS v4 (CSS-first config), shadcn/ui
> (Tailwind v4 + React 19 ready), Motion (`motion/react`, formerly Framer
> Motion), OKLCH color throughout. Resolve current docs with context7 before
> pinning versions — this ages.

## Core principles (the short list)

- **Tokens, not magic numbers.** Every color, spacing, radius, and font value comes from the theme. If a value appears twice, it's a token; if it appears once, question it.
- **Hierarchy before decoration.** Size, weight, color contrast, and spacing establish what matters. If everything is bold, nothing is.
- **Consistency beats novelty.** One spacing rhythm, one radius scale, one easing family, two typefaces max. Reuse the established pattern even when a new one is prettier.
- **Accessible by default.** WCAG AA contrast (4.5:1 text, 3:1 large text and UI), visible focus, 44px touch targets, `prefers-reduced-motion` respected. Not a follow-up task — part of done.
- **Motion is feedback, not garnish.** Animate to communicate state change (150–300 ms, transform/opacity only). If removing an animation loses no information, remove it.
- **Whitespace is a feature.** Generous, consistent spacing reads as quality. Cramped reads as broken.

## Workflow

1. **Read the existing design system first.** Inspect the theme (`@theme` tokens, `:root` variables, `components.json`, existing components) before writing any UI. New work must use the established tokens, spacing rhythm, and component variants — extend the system, don't fork it.
2. **Establish foundations before screens.** If tokens are missing or inconsistent (raw hex values scattered, arbitrary spacing), fix the foundation first: token architecture ([references/design-systems.md](references/design-systems.md)), color tokens ([references/color.md](references/color.md)), type scale ([references/typography.md](references/typography.md)), spacing/radius in the Tailwind theme ([references/tailwind.md](references/tailwind.md)).
3. **Build with the system.** Compose shadcn/ui components and Tailwind utilities; create new components only when the registry has nothing close ([references/shadcn.md](references/shadcn.md)). Apply UX patterns for states the happy path hides: loading, empty, error, long-content ([references/ux-principles.md](references/ux-principles.md)).
4. **Polish with motion.** Add micro-interactions to state changes and entrances last, never first ([references/micro-interactions.md](references/micro-interactions.md)); use the Motion library only where CSS can't express it ([references/motion.md](references/motion.md)).
5. **Validate** against the checklist below; check contrast and keyboard navigation, not just visuals.

## Common mistakes

| Mistake                                  | Why it bites                                | Fix                                            |
| ---------------------------------------- | ------------------------------------------- | ---------------------------------------------- |
| Arbitrary values (`mt-[13px]`, `#3b82f6`) | Breaks rhythm, unthemable, drifts           | Theme tokens; extend `@theme` if missing       |
| Gray text on gray background "subtlety"  | Fails contrast, unreadable                  | Check 4.5:1; use the muted-foreground token    |
| Pure black/white anywhere                | Harsh, flat, glare in dark mode             | Near-neutrals with slight hue (OKLCH)          |
| Dark mode by inverting colors            | Vibrating saturated colors, crushed depth   | Separate dark token set; reduce chroma         |
| Animating `width`/`height`/`top`         | Layout thrash, jank                         | `transform` and `opacity` only                 |
| Spinners for everything                  | Feels slower than it is                     | Skeletons for structure, optimistic UI for actions |
| Five font sizes in one card              | No hierarchy, visual noise                  | Stick to the type scale; vary weight and color |
| Disabling focus outlines                 | Keyboard users lost                         | Style `focus-visible`, never remove it         |
| Restyling shadcn internals with overrides | Fights the component, breaks on update      | Edit your copy of the component — you own it   |

## Reference files

Read the one whose topic matches the task — each file repeats its load condition at the top:

- [references/design-systems.md](references/design-systems.md) — read for token architecture, component API design, naming, and keeping an app consistent at scale
- [references/tailwind.md](references/tailwind.md) — read for Tailwind v4 setup, `@theme` tokens, dark mode variants, responsive/container queries, utility discipline
- [references/shadcn.md](references/shadcn.md) — read for shadcn/ui setup, semantic color tokens, customizing owned components, composition patterns
- [references/color.md](references/color.md) — read for palette construction, OKLCH, contrast, semantic color tokens, dark mode color design
- [references/typography.md](references/typography.md) — read for type scale, line length/height, font pairing, loading, fluid type
- [references/ux-principles.md](references/ux-principles.md) — read for hierarchy, states (loading/empty/error), forms, navigation, accessibility patterns
- [references/micro-interactions.md](references/micro-interactions.md) — read for transitions, durations/easing, hover/press feedback, loading patterns, reduced motion
- [references/motion.md](references/motion.md) — read for the Motion library: enter/exit, layout animations, gestures, variants/stagger, springs

## Validation

Before calling design work done:

- [ ] Every color, spacing, radius, and font value resolves to a theme token — no orphan hex codes or arbitrary pixel values without a recorded reason.
- [ ] Text contrast meets 4.5:1 (3:1 for large text and UI elements) in both light and dark themes.
- [ ] Loading, empty, error, and overflow states exist for every data-driven view.
- [ ] Keyboard-only pass: everything reachable, focus visible, no traps.
- [ ] Animations run on transform/opacity, last ≤ 300 ms for UI feedback, and honor `prefers-reduced-motion`.
- [ ] The result is consistent with the rest of the app — same rhythm, radius, type scale — not a one-off showcase.
