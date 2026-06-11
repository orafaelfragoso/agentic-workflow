// Setup file for the DOM/component project (wire via test.setupFiles).
// Runs before each test file — keep it lean: every file pays this cost.

import "@testing-library/jest-dom/vitest";
import { afterAll, afterEach, beforeAll } from "vitest";
import { server } from "./msw";

// MSW: fail loudly on requests no handler covers, reset per-test overrides.
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
