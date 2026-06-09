# Next.js Integration (16.x)

> **Load when:** the question is about building a TypeScript app with Next.js —
> App Router, server boundaries, caching, linting, or migrating off `next lint`.

Next.js 16 is the full-stack React framework with the **App Router**,
**Turbopack** stable for dev and build, explicit caching (`use cache` /
`cacheComponents`), and React Compiler + React 19.2 support. This file covers the
TypeScript-relevant seams; routing/rendering internals are framework concerns.

## Scaffold

```bash
pnpm create next-app@latest my-app --ts --app   # add --biome or --eslint
# Bun: bunx create-next-app@latest my-app --ts --app
```

`create-next-app` is TypeScript-first and scaffolds **either ESLint or Biome**.

## Async request APIs — everything is a Promise now

`params`, `searchParams`, `cookies()`, `headers()`, and `draftMode()` are all
**async**. Await them in Server Components / `generateMetadata`, or unwrap with
React's `use()` in Client Components. Type the props as `Promise<...>`.

```tsx
// app/users/[id]/page.tsx — params/searchParams are untrusted, async strings
import * as z from "zod";

const Params = z.object({ id: z.uuid() });

export default async function Page({
  params,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { id } = Params.parse(await params); // throws on bad input
  const user = await getUser(id);            // id is a validated UUID
  return <UserView user={user} />;
}
```

```tsx
// Client Component — unwrap with use()
"use client";
import { use } from "react";

export default function Page(props: { params: Promise<{ id: string }> }) {
  const { id } = use(props.params);
  // ...
}
```

## Type the boundaries with Zod

Server Components, Server Actions, route handlers, and `searchParams` all receive
**untyped external input**. Validate at the edge and let the inferred type flow
inward (see [enterprise-patterns.md](enterprise-patterns.md)). Use
`useActionState` for typed action state on the client.

```tsx
// Server Action — never trust the FormData
"use server";
import * as z from "zod";

const Input = z.object({ email: z.email(), name: z.string().min(1) });

export async function createUser(_prev: unknown, form: FormData) {
  const parsed = Input.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { ok: false, errors: z.treeifyError(parsed.error) };
  await db.user.create({ data: parsed.data });
  return { ok: true };
}
```

## Caching — explicit in 16

The old implicit fetch cache is gone. Opt into caching with `use cache` (enable
`cacheComponents` in `next.config`); use `cacheLife`/`cacheTag` to scope and
invalidate. `after()` defers work past the response; `connection()` marks a
boundary as dynamic.

```tsx
import { unstable_cacheLife as cacheLife } from "next/cache";

async function getProducts() {
  "use cache";
  cacheLife("hours");
  return db.product.findMany();
}
```

```ts
// next.config.ts
import type { NextConfig } from "next";
const config: NextConfig = {
  cacheComponents: true,   // enables `use cache`
  typedRoutes: true,       // stable — typed Link href + router.push
};
export default config;
```

## Typed routes (stable)

`typedRoutes: true` makes `<Link href>` and `router.push()` reject unknown
routes at compile time. Combine with validated params for full path safety.

## Linting changed in 16 — important

- **`next lint` was removed** and `next build` no longer lints. Run ESLint or
  Biome directly from a `package.json` script.
- The `eslint` key in `next.config` is gone.
- Biome auto-enables its **`next` domain** rules when `next` is a dependency
  (see [biome-integration.md](biome-integration.md)).
- Migrate an existing project with the codemod:

```bash
pnpm dlx @next/codemod@canary next-lint-to-eslint-cli .
# Bun: bunx @next/codemod@canary next-lint-to-eslint-cli .
```

```jsonc
// package.json — lint explicitly now
{
  "scripts": {
    "lint": "eslint .",        // or: biome check .
    "typecheck": "tsc --noEmit"
  }
}
```

See [eslint-integration.md](eslint-integration.md) for `eslint-config-next` on
flat config.

## tsconfig notes

`create-next-app` generates a working `tsconfig.json` with the Next plugin
(`"plugins": [{ "name": "next" }]`), `"moduleResolution": "bundler"`, and
`"jsx": "preserve"`. Supports a typed `next.config.ts`. Keep `strict: true` and
add `noUncheckedIndexedAccess`.

## Gotchas

- Client interactivity needs `"use client"`; keep it at the leaf, not the root.
- Don't import server-only code into client components — mark server modules with
  `import "server-only"` to fail the build fast.
- `next build` won't catch type errors unless you run `tsc --noEmit`; wire it into
  CI alongside lint.
- With `cacheComponents`, an un-cached dynamic read (cookies/headers) forces the
  boundary dynamic — wrap shared data in `use cache` deliberately.
