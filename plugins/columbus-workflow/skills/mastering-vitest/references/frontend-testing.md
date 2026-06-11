# Frontend & Component Testing

> Load when: testing UI components — Testing Library queries, jsdom vs
> happy-dom vs browser mode, `vitest-browser-react`, visual regression.

## Pick the environment first

| Environment      | What it is                                         | Use when                                                                                       |
| ---------------- | -------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `jsdom`          | DOM simulation in Node                             | default for component logic; widest API coverage                                               |
| `happy-dom`      | faster, lighter DOM simulation                     | speed matters and the suite doesn't hit its API gaps                                           |
| **Browser mode** | real Chromium/Firefox/WebKit (Playwright provider) | layout, real events, CSS, drag/focus/IntersectionObserver — anything simulated DOMs fake badly |

Simulated DOMs don't do layout: `getBoundingClientRect` returns zeros, CSS
doesn't cascade, `:hover` doesn't exist. The moment a test cares about visual
or positional truth, move it to browser mode instead of stubbing browser APIs.

## Testing Library in jsdom/happy-dom

```ts
// component test (React shown; Vue/Svelte equivalents mirror this)
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

it('shows a validation error for an invalid email', async () => {
  const user = userEvent.setup()
  render(<SignupForm />)

  await user.type(screen.getByRole('textbox', { name: /email/i }), 'nope')
  await user.click(screen.getByRole('button', { name: /sign up/i }))

  expect(await screen.findByRole('alert')).toHaveTextContent(/valid email/i)
})
```

Principles that keep these tests honest:

- **Query like a user.** Priority: `getByRole` (with accessible name) > `getByLabelText` > `getByPlaceholderText`/`getByText` > `getByTestId` as last resort. If you can't query by role, the component likely has an accessibility problem — fix that, not the test.
- **`userEvent` over `fireEvent`** — it simulates full interaction sequences (pointer, focus, keyboard) instead of dispatching one synthetic event.
- **`findBy*` for async appearance**, `waitFor` for non-element conditions, `queryBy*` only for asserting absence.
- **Assert rendered outcome, not state**: what the user sees, not `component.state.isValid`. Don't reach into instances or test hooks in isolation unless the hook is a public reusable API (then `renderHook`).
- Wire `@testing-library/jest-dom/vitest` in a setup file for matchers like `toBeVisible`, `toHaveAccessibleName`, `toBeDisabled`.
- Network the component touches → MSW handlers (see integration reference), not mocked fetch hooks.

## Browser mode (Vitest 4)

Browser mode runs the same Vitest tests in a real browser. Vitest 4 split
providers into packages — install `@vitest/browser-playwright`:

```ts
import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: playwright(),
      headless: true,
      instances: [{ browser: "chromium" }], // add firefox/webkit instances to matrix
    },
  },
});
```

Component tests use the framework bridge (`vitest-browser-react`, `-vue`,
`-svelte`) with **locators** and auto-retrying `expect.element`:

```tsx
import { render } from "vitest-browser-react";
import { page, userEvent } from "@vitest/browser/context";

it("increments", async () => {
  render(<Counter />);
  await userEvent.click(page.getByRole("button", { name: "Increment" }));
  await expect.element(page.getByText("Count: 1")).toBeVisible();
});
```

- Locators + `expect.element` retry until timeout — no manual `waitFor` for appearance/visibility.
- The same Testing Library query discipline applies (`getByRole` first).
- Run browser-mode tests as their own **project** so unit tests stay on the fast Node pool; browser instances within one project run in parallel.

### Visual regression

Browser mode ships `toMatchScreenshot` for element/page screenshot comparison.
Keep visual tests in a dedicated project, run them on a consistent OS (Linux
in CI or a remote browser service) — font rendering differs per platform and
causes false diffs. Set explicit viewports per instance.

## Component test vs e2e

A component test renders **one component** with mocked network and proves its
contract. The moment a test needs routing + auth + backend together, it's an
e2e test — write it in Playwright Test (see e2e reference) rather than
stretching component tests. Healthy ratio: many component tests, few e2e.
