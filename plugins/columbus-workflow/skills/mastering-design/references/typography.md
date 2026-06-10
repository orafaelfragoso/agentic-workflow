# Typography

> **Load when:** the task involves choosing fonts, sizing text, fixing
> readability or hierarchy, building a type scale, or loading web fonts.

Typography is 90% of UI. Get the scale, rhythm, and measure right and a plain
interface looks designed; get them wrong and no amount of color saves it.

## The type scale

Pick one ratio and generate every size from it — common choices: 1.2 (minor
third, dense apps), 1.25 (major third, balanced), 1.333 (perfect fourth,
editorial). Base 16px.

```css
@theme {
  --text-xs: 0.75rem;     /* meta, labels */
  --text-sm: 0.875rem;    /* secondary, dense UI body */
  --text-base: 1rem;      /* body */
  --text-lg: 1.25rem;     /* card titles */
  --text-xl: 1.563rem;    /* section headings */
  --text-2xl: 1.953rem;   /* page titles */
  --text-3xl: 2.441rem;   /* hero */
}
```

- Skip steps for contrast (body → page title), never invent in-between sizes.
- Most product UI needs only 4–5 of these per screen.
- Hierarchy comes from **weight and color before size**: same-size text in
  `font-medium text-foreground` vs `font-normal text-muted-foreground` already
  reads as two levels. Escalate size only when that's not enough.
- Fluid sizes for marketing/hero text: `clamp(2rem, 1rem + 3vw, 3.5rem)`.
  Product UI text usually shouldn't be fluid.

## Rhythm: line height, measure, spacing

- **Line height** is inversely proportional to size: body 1.5–1.6
  (`leading-relaxed`), headings 1.1–1.2 (`leading-tight`), single-line UI labels
  1 (`leading-none`). Tailwind v4 pairs them: `text-2xl/tight`.
- **Measure (line length)**: 45–75 characters; ~65ch is the sweet spot. Cap
  prose with `max-w-prose` or `max-w-[65ch]`. Full-width paragraphs on desktop
  are the most common readability bug.
- **Letter spacing**: large headings slightly tight (`tracking-tight`), body
  default, ALL-CAPS labels need `tracking-wide` + smaller size. Never track-out
  lowercase body text.
- **Paragraph spacing** beats indentation in UIs: blank line (`space-y-4` /
  `gap-4`), no first-line indent.
- Space groups by relationship: a heading sits closer to its content than to
  the previous section (e.g. `mt-10 mb-3`). Equidistant headings destroy scanning.

## Choosing and pairing fonts

- **Two families max**: a UI/body sans plus one display or mono. One family
  with a good weight range (400/500/600/700) is usually enough.
- Pair by contrast, not similarity: geometric display + humanist body, or
  serif display + sans body. Two near-identical sans faces look like a mistake.
- For data-heavy UI, pick a face with **tabular figures** and use them for
  numbers that align in columns: `tabular-nums` (Tailwind class) or
  `font-variant-numeric: tabular-nums`. Proportional figures jitter in tables
  and timers.
- System stack (`system-ui`) is a legitimate choice for product UI — free,
  instant, native-feeling. Always end custom stacks with it:
  `--font-sans: "Inter", system-ui, sans-serif`.
- Variable fonts: one file, all weights, animatable weight — prefer them when
  the family offers one.

## Loading web fonts

- Self-host WOFF2; `font-display: swap` so text renders immediately.
- Preload the one or two files used above the fold:
  `<link rel="preload" as="font" type="font/woff2" crossorigin href="...">`.
- Subset to the scripts you serve; a full-Unicode font is hundreds of KB.
- In Next.js use `next/font` (self-hosts, subsets, sets the CSS variable, zero
  layout shift); wire the variable into `@theme` as `--font-sans`.
- Limit weights to what the scale uses — every weight is a network file (or
  use a variable font).

## Dos and don'ts

| Do                                                       | Don't                                                  |
| --------------------------------------------------------- | ------------------------------------------------------- |
| One scale, generated from one ratio                       | Ad-hoc `text-[15px]`, `text-[22px]` sprinkles            |
| Weight + color for hierarchy first                        | A different size for every distinction                  |
| 45–75ch measure on prose                                  | Full-width paragraphs                                   |
| `leading-relaxed` body, `leading-tight` headings          | One global line height                                  |
| `tabular-nums` for tables, prices, timers                 | Jittering proportional digits in data                   |
| ≤ 2 families, ≤ 4 weights                                 | Font-family soup                                        |
| `font-display: swap` + preload + subset                   | Render-blocking, full-charset font loads                 |
| Real apostrophes and quotes (’ “ ”) in UI copy            | Typewriter quotes in polished surfaces                  |

## Verification

- Resize to 320px width and to 200% browser zoom: no clipped or overlapping text (WCAG requires usable at 200%).
- Count distinct font sizes on the changed screen; more than ~5 means the scale slipped.
- Check prose measure at desktop width; check numbers in any table align vertically.
