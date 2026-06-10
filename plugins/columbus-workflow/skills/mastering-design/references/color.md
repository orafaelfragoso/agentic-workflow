# Color Science

> **Load when:** the task involves choosing or generating colors, building a
> palette, designing dark mode, fixing contrast, or working with OKLCH values.

## Work in OKLCH

Define colors as `oklch(L C H)` — lightness (0–1), chroma (≈0–0.37), hue
(0–360). Unlike HSL, OKLCH is **perceptually uniform**: equal lightness steps
look like equal steps to humans, and two colors with the same `L` actually look
equally bright (HSL yellow at 50% looks far lighter than HSL blue at 50%).

Practical consequences:

- **Palette ramps**: hold hue and chroma roughly steady, step lightness evenly
  (e.g. `0.97 → 0.88 → 0.75 → 0.65 → 0.55 → 0.45 → 0.35 → 0.25` for a 50→900 ramp).
  Drop chroma slightly at both extremes — very light and very dark can't hold
  high chroma without clipping.
- **Hue-consistent variations**: lighten/darken by changing only `L`; HSL-style
  lightening shifts perceived hue, OKLCH doesn't.
- **Equal-vibrance categorical sets** (charts): same `L` and `C`, hues spread
  ≥ 60° apart.

## Build palettes semantically

Two layers, never mixed:

1. **Raw ramps**: `brand-50…950`, `gray-50…950`, plus status hues (success ≈ 145,
   warning ≈ 85, danger ≈ 25–30 hue in OKLCH).
2. **Semantic tokens** referencing the ramps: `background`, `foreground`,
   `primary`, `muted`, `destructive`, `border`, `ring` — what components actually
   use (see [shadcn.md](shadcn.md)).

Distribution rule of thumb — **60-30-10**: ~60% neutral surface, ~30% secondary
(muted surfaces, borders, secondary text), ~10% accent. If the accent covers a
third of the screen, it no longer reads as an accent.

Neutrals deserve a hue: pure gray (`C = 0`) looks lifeless next to a brand
color. Tint neutrals 1–2% chroma toward (or opposite) the brand hue:
`oklch(0.97 0.005 255)` instead of `oklch(0.97 0 0)`.

## Contrast is non-negotiable

WCAG AA minimums:

| Element                           | Minimum ratio |
| --------------------------------- | ------------- |
| Body text                         | 4.5:1         |
| Large text (≥ 24px / 19px bold)   | 3:1           |
| UI components, borders, icons     | 3:1           |
| Focus indicators against adjacent | 3:1           |

- Check both themes; muted text on muted backgrounds is where AA dies.
- Placeholder text counts as text. The classic `gray-400`-on-white placeholder fails.
- Don't rely on hue alone to encode meaning (≈8% of men have a color-vision
  deficiency): pair red/green status with an icon, label, or weight change.
- Disabled elements are exempt from AA — but still keep them legible (~3:1).

## Dark mode is a second palette, not an inversion

- **Don't flip the ramp.** Design the dark set deliberately: background around
  `L 0.14–0.18` (never pure black — OLED smearing and harsh contrast), text
  around `L 0.93–0.985` (never pure white — glare).
- **Reduce chroma** on large surfaces and **lower the lightness of accents**
  slightly; saturated colors vibrate against dark backgrounds.
- **Elevation = lighter, not shadowed.** Dark surfaces stack by increasing `L`
  (`0.14` page → `0.18` card → `0.22` popover); shadows are nearly invisible on dark.
- Status colors usually need their own dark variants — the light theme's
  `danger-600` is illegible on `L 0.15`.

## Gradients and transparency

- Interpolate gradients in OKLCH (`in oklch` in CSS) to avoid the gray dead
  zone hue-distant gradients get in sRGB.
- For overlays and borders, prefer alpha (`oklch(1 0 0 / 10%)`, Tailwind
  `bg-foreground/10`) over near-match solid colors — alpha survives any
  background change. shadcn's dark `--border: oklch(1 0 0 / 10%)` is this pattern.

## Dos and don'ts

| Do                                              | Don't                                          |
| ----------------------------------------------- | ---------------------------------------------- |
| OKLCH everywhere; ramps with even `L` steps     | Eyeballed hex ramps with jumping brightness    |
| Semantic tokens consumed by components          | Components referencing `brand-500` directly    |
| 60-30-10 distribution; neutral-dominant UIs     | Accent-colored everything                      |
| Slightly tinted neutrals                        | Dead `C = 0` gray scales next to a vivid brand |
| Deliberate dark token set, reduced chroma       | `filter: invert()`-style dark mode             |
| Verify contrast programmatically in both themes | "Looks fine on my screen"                      |
| Icon/label + color for status                   | Hue as the only signal                         |

## Verification

- Run every text/background semantic pair through a contrast checker in both themes; record the ratios in the PR/report.
- View the UI with a grayscale filter: hierarchy and status must still be readable.
- Squint test: the accent should appear in roughly one place per view, not everywhere.
