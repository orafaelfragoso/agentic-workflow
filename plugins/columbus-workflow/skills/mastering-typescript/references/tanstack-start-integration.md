# TanStack Start Integration (1.x)

> **Load when:** the question is about building a TypeScript app with TanStack
> Start — typed routing, loaders, server functions, or middleware.

TanStack Start is a full-stack React framework built on **Vite** and **TanStack
Router**, with end-to-end type inference: types flow from route → loader →
component → server function with no manual wiring. There is no RSC model — it's
client-first SSR with typed server functions for the server boundary.

## Scaffold

```bash
pnpm create start-app my-app
cd my-app && pnpm install && pnpm dev
# Bun: bunx create-start-app my-app
```

It wires the Vite plugin (`@tanstack/react-start/plugin/vite`) and file-based
routing for you. The router writes `routeTree.gen.ts` — **commit it** (or
regenerate in CI); it is the source of all route type safety.

## Server functions (typed end-to-end)

`createServerFn` defines a server-only function callable from anywhere with full
type safety. Build it fluently: pick a method, attach a `validator`, optional
`middleware`, then a `handler`. The validated, typed `data` and middleware
`context` arrive in the handler.

```ts
import { createServerFn } from "@tanstack/react-start";
import * as z from "zod";

export const createPost = createServerFn({ method: "POST" })
  .validator(z.object({ title: z.string().min(1) })) // parses + types `data`
  .middleware([authMiddleware]) // contributes `context`
  .handler(async ({ data, context }) => {
    // data: { title: string }  — validated
    // context: typed from middleware (e.g. { userId })
    return db.posts.create({ title: data.title, authorId: context.userId });
  });

const post = await createPost({ data: { title: "Hello" } }); // typed call + result
```

- `.validator()` accepts any Standard Schema validator (Zod, Valibot, ArkType) or
  a plain `(input) => output` function. Prefer a schema so bad input throws at the
  boundary — see [enterprise-patterns.md](enterprise-patterns.md).
- `method: "GET"` server fns are cacheable/loader-friendly; `"POST"` for mutations.

### Calling from components — `useServerFn`

Don't call a server fn directly inside a component for reactive data; wrap it so
the router tracks invalidation, or feed it to TanStack Query.

```tsx
import { useServerFn } from "@tanstack/react-start";

function PostList() {
  const getPosts = useServerFn(getServerPosts);
  const { data } = useQuery({ queryKey: ["posts"], queryFn: () => getPosts() });
  // ...
}
```

## Middleware (typed context)

Middleware is the auth/logging/context seam. Each layer can read request data and
return `context` that the next layer and the handler see, fully typed.

```ts
import { createMiddleware } from "@tanstack/react-start";

const authMiddleware = createMiddleware().server(async ({ next, request }) => {
  const user = await getUserFromSession(request);
  if (!user) throw new Error("Unauthorized");
  return next({ context: { userId: user.id } }); // typed downstream
});
```

## Server routes (raw HTTP handlers)

For webhooks/REST endpoints, attach handlers to a file route:

```ts
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/hello")({
  server: {
    handlers: {
      GET: async () => Response.json("Hello, World!"),
    },
  },
});
```

## Typed loaders & route context

Loaders feed components through the router's inference — `Route.useLoaderData()`
is typed from the loader's return, no generics. `beforeLoad` runs first and can
add to the route `context` (auth, query client) that loaders consume.

```tsx
export const Route = createFileRoute("/users/$id")({
  beforeLoad: ({ context }) => ({ user: context.user }), // typed context
  loader: async ({ params }) => getUser(params.id), // params.id is typed
  component: UserPage,
});

function UserPage() {
  const user = Route.useLoaderData(); // inferred as the loader's return type
  return <h1>{user.name}</h1>;
}
```

Validate dynamic search params with `validateSearch` (Standard Schema) so
`Route.useSearch()` is typed and runtime-safe.

## Environment variables

Server functions read **any** `process.env.*`. Client code only sees variables
prefixed `PUBLIC_` via `import.meta.env.PUBLIC_*`. Never reference a secret env
var in client-reachable code — keep it inside a server fn.

```ts
const getUser = createServerFn().handler(async () => {
  return connect(process.env.DATABASE_URL); // ✅ server-only
});
// Client: import.meta.env.PUBLIC_APP_NAME   ✅ exposed
```

## tsconfig notes

```jsonc
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "moduleResolution": "Bundler",
    "module": "ESNext",
    "target": "ES2022",
    "strict": true,
    "skipLibCheck": true,
  },
}
```

(Use `"jsxImportSource": "solid-js"` for the Solid variant.) Keep `strict: true`
and add `noUncheckedIndexedAccess` — the router's inference is only as good as
your config.

## When to pick it over Next.js

Start leans into Vite's fast dev loop and client-first, fully-typed routing with
server functions, rather than the App Router / RSC model. Choose on whether you
want RSC + server-component streaming (Next — see
[nextjs-integration.md](nextjs-integration.md)) or end-to-end router/server-fn
inference without a compiler-driven server/client split (Start).
