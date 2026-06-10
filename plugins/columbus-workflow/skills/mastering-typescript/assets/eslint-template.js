// eslint.config.js — ESLint 10 flat config for TypeScript.
// Copy to your project root. Requires: eslint, @eslint/js, typescript-eslint.

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  // Ignore build artefacts first so they're skipped entirely.
  {
    ignores: ["dist/**", "build/**", "coverage/**", "node_modules/**"],
  },

  eslint.configs.recommended,

  // Type-aware strict + stylistic presets.
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,

  // Enable the typed-linting service (no need to list each tsconfig).
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  // Project rules.
  {
    rules: {
      // Allow intentionally-unused names prefixed with _.
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],

      // Type-only imports → better tree-shaking and predictable emit.
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports", fixStyle: "inline-type-imports" },
      ],

      // Async safety.
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/no-misused-promises": "error",
      "@typescript-eslint/await-thenable": "error",

      // Prefer modern nullish operators.
      "@typescript-eslint/prefer-nullish-coalescing": "error",
      "@typescript-eslint/prefer-optional-chain": "error",

      // Disallow object-literal `as` assertions (use `satisfies` instead).
      "@typescript-eslint/consistent-type-assertions": [
        "error",
        { assertionStyle: "as", objectLiteralTypeAssertions: "never" },
      ],
    },
  },

  // Config/test files don't need full type-aware linting.
  {
    files: ["**/*.config.{js,ts}", "**/*.{test,spec}.ts"],
    ...tseslint.configs.disableTypeChecked,
  },
);
