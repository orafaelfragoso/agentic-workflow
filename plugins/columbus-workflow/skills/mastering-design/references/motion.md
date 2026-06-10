# Motion (motion.dev)

> **Load when:** the task uses the Motion library (formerly Framer Motion) —
> enter/exit animations, layout animations, gestures, scroll-linked effects, or
> orchestrated sequences in React. For *whether and how much* to animate, read
> [micro-interactions.md](micro-interactions.md) first.

Motion is the successor to Framer Motion. React API imports from
`motion/react`; a framework-agnostic `animate()` mini API exists in `motion`
for vanilla use.

## Core model

```tsx
import { motion } from "motion/react";

<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.2, ease: "easeOut" }}
/>;
```

- `initial` → `animate` runs on mount; setting `animate` to new values animates
  on re-render. State *is* the animation target — no imperative play() calls.
- Transforms and opacity run on the compositor; stick to them
  (`x`, `y`, `scale`, `rotate`, `opacity`) for anything frequent.
- Springs for movement, durations for fades:

  ```tsx
  transition={{ type: "spring", stiffness: 500, damping: 35 }}   // physical
  transition={{ duration: 0.15 }}                                 // opacity
  ```

  Springs respond to interruption naturally — a re-targeted spring redirects
  instead of jumping. Prefer them for anything the user can interrupt.

## Exit animations

React removes nodes instantly; `AnimatePresence` keeps them alive for the exit:

```tsx
import { AnimatePresence, motion } from "motion/react";

<AnimatePresence>
  {open && (
    <motion.div
      key="panel" // unique, stable key — required
      initial={{ opacity: 0, scale: 0.97 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.97 }}
    />
  )}
</AnimatePresence>;
```

- Direct children need stable, unique `key`s; the exiting element is identified
  by key, not position.
- Exits should be faster than entrances (~0.7×) — the user already decided to leave.

## Layout animations

Animate otherwise-unanimatable layout changes (reordering, size, position) with
the `layout` prop; Motion turns the layout delta into a transform (FLIP):

```tsx
<motion.li layout key={item.id} />            // smooth reorder
<motion.div layoutId="active-tab-underline" /> // shared element between states
```

- `layoutId` morphs one element between mount points — tab underlines, expanding
  cards into dialogs.
- Round corners distort under scale; put `borderRadius` in `style` so Motion
  corrects it during the layout animation.
- Don't add `layout` to everything — each layout node measures on every layout
  change; scope it to lists/containers that actually reorder.

## Gestures

```tsx
<motion.button
  whileHover={{ scale: 1.03 }}
  whileTap={{ scale: 0.97 }}
  whileFocus={{ scale: 1.03 }}
/>
```

- `whileTap` press feedback is the cheapest perceived-quality win on buttons.
- Keep gesture deltas small (scale 0.95–1.05); large ones read as toys.
- `whileFocus` keeps keyboard parity with hover effects — pair it whenever you
  use `whileHover`, and never replace the visible focus ring with motion.

## Orchestration with variants

Parents propagate named states; stagger children declaratively:

```tsx
const list = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.05 } },
};
const item = {
  hidden: { opacity: 0, y: 8 },
  show: { opacity: 1, y: 0 },
};

<motion.ul variants={list} initial="hidden" animate="show">
  {items.map((i) => (
    <motion.li key={i.id} variants={item} />
  ))}
</motion.ul>;
```

Stagger 30–60 ms per item, cap the total: animate the first ~10 and let the
rest appear — a 40-item × 100 ms cascade is a 4-second wait.

## Accessibility

```tsx
import { useReducedMotion } from "motion/react";

const shouldReduceMotion = useReducedMotion();
const y = shouldReduceMotion ? 0 : 8;
```

Honor `prefers-reduced-motion` in every component that moves things: keep
opacity fades, drop movement/scale/parallax. This is a requirement, not polish.

## Dos and don'ts

| Do                                                       | Don't                                                     |
| --------------------------------------------------------- | ---------------------------------------------------------- |
| CSS transitions for simple hover/fade; Motion for exit/layout/orchestration | Pull Motion into a component for a one-property hover     |
| Animate `x`/`y`/`scale`/`opacity`                          | Animate `width`/`height`/`top`/`left` (use `layout`)        |
| Springs for interruptible movement                         | Long duration+ease on things users interrupt               |
| Stable `key`s under `AnimatePresence`                      | Index keys that break exit tracking                         |
| `useReducedMotion` fallbacks                               | Unconditional motion                                        |
| `layoutId` for shared-element morphs                       | Hand-synced absolute-position clones                        |

## Verification

- Interrupt every animation mid-flight (open/close rapidly): no jumps, no orphaned elements stuck mid-exit.
- Enable reduced motion in OS settings and re-test: movement gone, information intact.
- Profile a list with `layout` props while filtering: interaction stays at 60fps.
