# UX Principles

> **Load when:** the task involves designing or reviewing flows, screens,
> forms, navigation, or any of the states the happy path hides (loading, empty,
> error), or an accessibility pass.

## Visual hierarchy

The user should know in one glance: what this screen is, what matters most,
and what to do next.

- **One primary action per view.** A single filled/primary button; everything
  else secondary (outline), ghost, or a link. Two primary buttons means the
  designer didn't decide.
- Build hierarchy with size, weight, color contrast, and position — in that
  order of preference; reach for boxes and borders last. Spacing groups things
  better than lines (proximity beats borders).
- F/Z scanning: primary info top-left, primary action where the scan ends
  (bottom-right of forms/dialogs in LTR).
- De-emphasize deliberately: metadata in `text-sm text-muted-foreground`, not
  shouting alongside the content.

## Every view has five states

Design all of them or the UI is unfinished:

1. **Loading** — skeleton matching the final layout ([micro-interactions.md](micro-interactions.md)).
2. **Empty** — not a blank void: one line of explanation + the action that
   fills it ("No projects yet — Create your first project"). First-run empty
   states are onboarding.
3. **Error** — what happened, in human words, and what to do next (retry
   button, support link). Never a raw error code alone; never a dead end.
4. **Partial/overflow** — one item, 10,000 items, a 300-character title:
   truncate with `line-clamp-*` + title attribute, paginate or virtualize long
   lists, test with real-length content.
5. **Ideal** — the one everyone designs.

## Forms

- **Labels above inputs, always visible.** Placeholder is not a label — it
  vanishes on focus and fails recall. Use placeholders for format examples only.
- Validate on blur (not on every keystroke before first submit), show errors
  inline next to the field, in words that say how to fix it. On submit, focus
  the first invalid field.
- Don't disable the submit button as the only error signal — let users submit
  and see why it failed. Disabled buttons explain nothing.
- Mark optional fields ("Optional"), not required ones, in mostly-required
  forms; the reverse in mostly-optional ones.
- Right input mode for the data: `type=email`, `inputmode=numeric`,
  `autocomplete` attributes — mobile keyboards and password managers depend on
  them.
- Group related fields; one column beats two (two-column forms get skipped and
  mis-ordered); destructive or irreversible submissions get a confirm step
  that names the object ("Delete *project Alpha*?").
- Preserve user input at all costs: across validation errors, accidental
  navigation, and reloads where feasible. Wiping a half-filled form is the
  fastest way to lose a user.

## Navigation and orientation

- Users must always know **where they are, how they got here, how to go back**:
  active state in nav, breadcrumbs past two levels, working browser back.
- Don't hide primary navigation behind a hamburger on desktop.
- Keep destructive actions away from frequent ones (no "Delete" adjacent to
  "Save"); confirmation or undo for anything irreversible — **undo beats
  confirm** (toast with Undo) wherever the operation can be deferred.
- Respect platform conventions: Escape closes, Enter submits, clicking the
  overlay dismisses (with a guard when the dialog holds unsaved input).

## Perceived performance

- Respond to every interaction within 100 ms (press state counts), show
  progress for anything over ~1 s, and keep skeleton→content swaps stable —
  no layout jumps (reserve space for images and async content).
- Optimistic updates for high-frequency, low-risk actions.
- Never let a click do nothing visibly. Even failure must be visible.

## Accessibility (the floor, not the ceiling)

- Full keyboard pass: every action reachable in a sensible tab order, visible
  `focus-visible` ring, no traps; Escape exits overlays and focus returns to
  the trigger.
- Touch targets ≥ 44×44 px (24 px minimum with spacing); contrast per
  [color.md](color.md).
- Semantic HTML first: `button` for actions, `a` for navigation, real
  headings in order (one `h1`, no level skips), lists as lists. ARIA only for
  what HTML can't express — wrong ARIA is worse than none.
- Images get `alt` (empty `alt=""` if decorative); icon-only buttons get
  `aria-label`; async updates that matter get a live region (`role="status"`).
- Test: tab through it, zoom to 200%, run axe/Lighthouse on changed screens.

## Microcopy

- Buttons say what they do: "Save changes", "Create project" — not "OK",
  "Submit", "Yes".
- Sentence case, plain words, no system jargon ("Couldn't save — you're
  offline", not "Error 0x80070057: operation failed").
- Confirmations name the object and consequence; errors offer the next step.
- Numbers, dates, and currency get locale-aware formatting (`Intl.*`).

## Dos and don'ts

| Do                                                     | Don't                                                   |
| ------------------------------------------------------- | -------------------------------------------------------- |
| One primary action per view                             | Three filled buttons competing                            |
| Design loading/empty/error/overflow                     | Ship the ideal state only                                 |
| Labels above inputs; placeholders as examples           | Placeholder-as-label                                      |
| Inline, instructive validation on blur                  | Disabled-submit-as-error-message; alert() walls           |
| Undo for destructive actions where possible             | Confirm dialogs for everything, undo for nothing          |
| Semantic HTML, ARIA as last resort                      | div-with-onClick "buttons"                                |
| Test with real, long, awkward content                   | Lorem ipsum that happens to fit                           |
| Spacing to group; few borders                           | Boxes inside boxes inside boxes                           |

## Verification

- Walk the flow answering aloud: where am I, what matters, what do I do next — at every step.
- Force each non-ideal state (throttle network, empty DB, error responses) and screenshot all five states.
- Keyboard-only + 200% zoom + axe scan on every changed screen.
