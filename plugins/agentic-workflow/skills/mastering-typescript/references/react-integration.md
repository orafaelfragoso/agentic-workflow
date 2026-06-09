# Type-Safe React (React 19)

> **Load when:** the question is about typing components, props, hooks, events,
> refs, or generic components in React with TypeScript.

This covers the React **client library** with TypeScript. Framework concerns
(routing, Server Components, SSR, data conventions) belong to the framework, not
here.

## Typing components

Type the props directly and return `ReactNode`-ish JSX. **Avoid `React.FC`** — it
implicitly adds `children`, complicates generics, and buys nothing.

```tsx
import type { ReactNode } from "react";

type ButtonProps = {
  label: string;
  onClick: () => void;
  variant?: "primary" | "secondary";
  children?: ReactNode; // declare children only when you accept them
};

function Button({ label, onClick, variant = "primary", children }: ButtonProps) {
  return (
    <button className={variant} onClick={onClick}>
      {label}
      {children}
    </button>
  );
}
```

### Make impossible props impossible

Use a discriminated union for props instead of many optional fields that allow
invalid combinations:

```tsx
type AlertProps =
  | { kind: "info"; message: string }
  | { kind: "error"; message: string; retry: () => void };

function Alert(props: AlertProps) {
  return (
    <div role={props.kind === "error" ? "alert" : "status"}>
      {props.message}
      {props.kind === "error" && <button onClick={props.retry}>Retry</button>}
    </div>
  );
}
```

## Hooks

```tsx
import { useState, useReducer, useRef, useContext, createContext } from "react";

// useState — annotate only when inference is too narrow/wide
const [count, setCount] = useState(0);                 // number
const [user, setUser] = useState<User | null>(null);   // needs the annotation

// Functional updates when next depends on prev
setCount((c) => c + 1);

// useRef — DOM ref starts null; mutable ref holds a value
const inputRef = useRef<HTMLInputElement>(null);
const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
```

### `useReducer` with a discriminated action union

```tsx
type State = { count: number };
type Action = { type: "inc" } | { type: "add"; by: number } | { type: "reset" };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "inc":   return { count: state.count + 1 };
    case "add":   return { count: state.count + action.by };
    case "reset": return { count: 0 };
    default:      return assertNever(action);
  }
}
function assertNever(x: never): never { throw new Error(`bad action: ${JSON.stringify(x)}`); }
```

### Context with a non-null guard

Default to `null` and expose a hook that throws when used outside the provider —
so consumers get a non-nullable type:

```tsx
const ThemeContext = createContext<Theme | null>(null);

export function useTheme(): Theme {
  const ctx = useContext(ThemeContext);
  if (ctx === null) throw new Error("useTheme must be used within ThemeProvider");
  return ctx;
}
```

## Events

Type handlers with React's synthetic event generics; let inference type inline
handlers from the JSX attribute.

```tsx
function onChange(e: React.ChangeEvent<HTMLInputElement>) {
  console.log(e.currentTarget.value);
}

// Inline: parameter type is inferred from the prop, no annotation needed
<button onClick={(e) => e.preventDefault()}>Go</button>;
```

Common event types: `React.MouseEvent<HTMLButtonElement>`,
`React.FormEvent<HTMLFormElement>`, `React.KeyboardEvent`,
`React.ChangeEvent<HTMLInputElement>`.

## Refs as props (React 19)

In React 19, `ref` is an ordinary prop — **no `forwardRef` needed** for new code.
Type it on the props object.

```tsx
type InputProps = {
  ref?: React.Ref<HTMLInputElement>;
  placeholder?: string;
};

function TextInput({ ref, placeholder }: InputProps) {
  return <input ref={ref} placeholder={placeholder} />;
}
```

A `ref` callback may now return a cleanup function:

```tsx
<div ref={(node) => {
  const observer = new ResizeObserver(() => {});
  if (node) observer.observe(node);
  return () => observer.disconnect();
}} />
```

## Generic components

Keep the type parameter flowing from props to render so the caller gets full
inference:

```tsx
type ListProps<T> = {
  items: readonly T[];
  getKey: (item: T) => string;
  render: (item: T) => ReactNode;
};

function List<T>({ items, getKey, render }: ListProps<T>) {
  return <ul>{items.map((it) => <li key={getKey(it)}>{render(it)}</li>)}</ul>;
}

// `T` is inferred as User from `items`
<List items={users} getKey={(u) => u.id} render={(u) => u.name} />;
```

## Custom hooks

Share behavior, not effects. Return a `const` tuple or a named object; annotate
the return type for a stable public contract.

```tsx
function useToggle(initial = false): readonly [boolean, () => void] {
  const [on, setOn] = useState(initial);
  const toggle = useCallback(() => setOn((v) => !v), []);
  return [on, toggle] as const;
}
```

## Actions & `use()` (React 19)

Model async UI with **Actions** instead of manual `isLoading`/`error` state.
`useActionState` types the state from the action's return; `useTransition` gives
`isPending` for free.

```tsx
const Schema = z.object({ email: z.email() });

function Subscribe() {
  const [state, action, isPending] = useActionState(
    async (_prev: { error?: string }, form: FormData) => {
      const r = Schema.safeParse(Object.fromEntries(form));
      if (!r.success) return { error: "Invalid email" };
      await subscribe(r.data.email);
      return {}; // success
    },
    {}, // initial state — types `state`
  );

  return (
    <form action={action}>
      <input name="email" />
      <button disabled={isPending}>Subscribe</button>
      {state.error && <p role="alert">{state.error}</p>}
    </form>
  );
}
```

`use()` reads a promise (with Suspense) or context conditionally — unlike hooks it
may sit inside branches. Type flows from the promise's resolved value:

```tsx
function Profile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise); // suspends; typed as User
  return <h1>{user.name}</h1>;
}
```

`useOptimistic` types its optimistic value from the base state for instant UI
that reconciles when the Action settles.

## React + TypeScript gotchas

- **Don't use `React.FC`** — type props directly; add `children?: ReactNode` only
  when the component renders children.
- With the **React Compiler (v1.0, stable)** enabled, drop reflexive
  `useMemo`/`useCallback`/`memo`; add them back only when profiling demands it.
- Type async/event state with `useActionState` / `useOptimistic` /
  `useTransition` rather than hand-rolled `isLoading` booleans.
- Prefer `unknown` for values from `JSON.parse`/network and validate with Zod
  before putting them in state.
