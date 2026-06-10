# Micro-Interactions

> **Load when:** the task involves transitions, hover/press feedback, loading
> states, or deciding what to animate and for how long. For Motion-library
> implementation details, read [motion.md](motion.md).

A micro-interaction acknowledges the user's action or explains a state change.
The test for every animation: **what does it communicate?** If the answer is
"it looks cool," cut it.

## Durations and easing

| Interaction                          | Duration   | Easing                  |
| ------------------------------------ | ---------- | ----------------------- |
| Hover/focus/press feedback           | 100–150 ms | `ease-out`              |
| Element entering (dropdown, toast)   | 150–250 ms | `ease-out`              |
| Element exiting                      | 100–200 ms | `ease-in`               |
| Layout/position change               | 200–300 ms | `ease-in-out` or spring |
| Large surfaces (page, drawer, modal) | 250–400 ms | `ease-in-out` or spring |

- **Enter decelerating (`ease-out`), exit accelerating (`ease-in`).** Linear is
  only for continuous things (spinners, progress, marquees).
- Exits faster than entrances — the user has already moved on.
- Above ~400 ms an interface animation is a delay; users perform thousands of
  these actions.
- Small elements fast, large surfaces slightly slower; same speed at different
  sizes looks wrong.
- Define one easing family as tokens (`--ease-snappy`, `--ease-fluid` in
  `@theme`) and reuse it — mixed easings across an app feel incoherent.

## What to animate

Only compositor-friendly properties: **`transform` and `opacity`** (plus
`filter` sparingly). `width`, `height`, `top`, `margin`, and `box-shadow`
trigger layout/paint and jank — fake shadow transitions by cross-fading a
pseudo-element's opacity; do layout changes with FLIP/`layout` (see
[motion.md](motion.md)).

CSS first, library second:

```css
.button {
  transition:
    transform 120ms var(--ease-snappy),
    background-color 120ms ease-out;
}
.button:active {
  transform: scale(0.97);
}
```

Tailwind: `transition-transform duration-150 ease-out active:scale-[0.97]`.
Reach for Motion only when CSS can't express it: exit animations, layout/FLIP,
orchestrated staggers, gesture physics.

## Feedback patterns

- **Press states**: every clickable element responds within one frame —
  `active:scale-[0.97]` or a background shift. Hover is not enough (touch has
  no hover).
- **Optimistic UI** for likes/toggles/renames: apply the change instantly,
  reconcile in the background, roll back with a toast on failure. Spinners on
  sub-200 ms actions make the app feel slower.
- **Loading**: skeletons that match the layout for content (cards, lists,
  text rows); spinners only for unknown-shape or in-button waits. Delay showing
  any indicator ~150 ms so fast responses never flash one. Skeleton pulse is
  the one acceptable infinite animation.
- **State transitions**: fade/scale dropdowns from their trigger
  (`transform-origin` at the trigger side), slide drawers from their edge,
  cross-fade content swaps ≤ 150 ms. Movement should explain _where it came from_.
- **Success**: a brief check morph or color pulse (≤ 600 ms total) beats a
  modal. Don't block the next action to celebrate.
- **Attention**: one subtle pulse or wiggle to direct the eye, run **once** —
  looping attention-seekers train users to ignore them.

## Reduced motion (mandatory)

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

Better than the blanket kill: keep opacity fades, remove movement — use
Tailwind's `motion-safe:`/`motion-reduce:` variants or `useReducedMotion`
per component. Vestibular-disorder users get nausea from parallax, zooms, and
large sweeps; this is an accessibility requirement.

## Dos and don'ts

| Do                                            | Don't                                           |
| --------------------------------------------- | ----------------------------------------------- |
| Animate to explain (origin, causality, state) | Animate to decorate                             |
| 100–300 ms for interface feedback             | 500 ms+ transitions on routine actions          |
| `transform`/`opacity` only                    | `width`/`height`/`top`/`box-shadow` transitions |
| One easing family from theme tokens           | A different bezier per component                |
| Press feedback on everything clickable        | Hover-only affordances                          |
| Skeletons matching real layout                | Full-screen spinners for partial loads          |
| Indicator delay (~150 ms) on fast paths       | Flashing a spinner for 80 ms                    |
| `motion-safe:`/`motion-reduce:` everywhere    | Ignoring `prefers-reduced-motion`               |
| Run attention cues once                       | Infinite pulse/bounce loops                     |

## Verification

- Click around with DevTools performance overlay: no layout shifts from animations, interactions hold 60fps.
- Toggle OS reduced-motion and confirm the UI still communicates every state change.
- Watch a full flow at 6× CPU throttle: indicators appear only where waits are real.
