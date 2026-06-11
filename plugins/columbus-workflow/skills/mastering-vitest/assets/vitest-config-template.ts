import { defineConfig } from "vitest/config";

// Projects-based Vitest 4 config. Delete the projects you don't need;
// uncomment the browser project after installing @vitest/browser-playwright
// and the framework bridge (vitest-browser-react / -vue / -svelte).
export default defineConfig({
  test: {
    // State never leaks between tests:
    restoreMocks: true,
    unstubEnvs: true,
    unstubGlobals: true,

    coverage: {
      provider: "v8",
      include: ["src/**"],
      thresholds: {
        lines: 80,
        branches: 80,
        functions: 80,
        statements: 80,
      },
    },

    projects: [
      {
        test: {
          name: "unit",
          environment: "node",
          include: ["src/**/*.test.ts"],
          // Safe once unit tests hold no module-level mutable state:
          // isolate: false,
          // pool: 'threads',
        },
      },
      {
        extends: true,
        test: {
          name: "dom",
          environment: "jsdom", // or 'happy-dom' for speed
          include: ["src/**/*.test.tsx"],
          setupFiles: ["./test/setup.ts"],
        },
      },
      {
        extends: true,
        test: {
          name: "integration",
          include: ["tests/integration/**/*.test.ts"],
          globalSetup: ["./test/global-setup.ts"],
          // Shared external resources (DB/container) — no file stampede:
          fileParallelism: false,
        },
      },
      // {
      //   extends: true,
      //   test: {
      //     name: 'browser',
      //     include: ['src/**/*.browser.test.tsx'],
      //     browser: {
      //       enabled: true,
      //       provider: playwright(), // import { playwright } from '@vitest/browser-playwright'
      //       headless: true,
      //       instances: [{ browser: 'chromium' }],
      //     },
      //   },
      // },
    ],
  },
});
