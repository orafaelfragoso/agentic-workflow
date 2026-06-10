# Error Handling

> **Load when:** the question is about returning, wrapping, inspecting, or
> defining errors — sentinels, custom error types, `errors.Is`/`As`, `panic`.

Errors are ordinary values in Go. The discipline is mechanical and pays off:
wrap with context on the way up, inspect by identity or type, never by string.

## Return, wrap, inspect

Add context as the error travels up the stack with `%w`, which preserves the
original for later inspection:

```go
func readConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read config %q: %w", path, err) // wrap
    }
    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parse config %q: %w", path, err)
    }
    return &cfg, nil
}
```

Use `%w` to keep the chain inspectable; use `%v` only when you intentionally want
to _flatten_ an error into a message and hide its identity.

## Sentinel errors (compare by identity)

For a known, comparable failure, declare a package-level sentinel and check it
with `errors.Is` (which unwraps the whole chain):

```go
var ErrNotFound = errors.New("not found")

func (s *Store) Get(id string) (*Item, error) {
    // ...
    return nil, fmt.Errorf("get %s: %w", id, ErrNotFound)
}

if errors.Is(err, ErrNotFound) { /* handle 404 */ }
```

Never do `if err.Error() == "not found"` — message text is not an API.

## Custom error types (carry data)

When the caller needs structured detail, define a type and extract it with
`errors.As`:

```go
type ValidationError struct {
    Field  string
    Reason string
}
func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s %s", e.Field, e.Reason)
}

// implement Unwrap() to chain a cause:
type QueryError struct{ Query string; Err error }
func (e *QueryError) Error() string { return e.Query + ": " + e.Err.Error() }
func (e *QueryError) Unwrap() error { return e.Err }

var ve *ValidationError
if errors.As(err, &ve) {
    log.Warn("bad field", "field", ve.Field)
}
```

Make `Is`/`As` targets explicit: use a pointer receiver consistently, and point
`As` at a pointer to the type you want filled.

## Combining errors

`errors.Join` aggregates multiple failures (e.g. validating every field, closing
several resources) into one error that `Is`/`As` can still see through:

```go
func validate(u User) error {
    var errs []error
    if u.Name == "" { errs = append(errs, &ValidationError{"name", "required"}) }
    if u.Age < 0   { errs = append(errs, &ValidationError{"age", "negative"}) }
    return errors.Join(errs...) // nil if the slice is empty
}
```

## The `if err != nil` rhythm

Handle each error where it happens; don't accumulate. Keep the happy path at the
left margin by returning early:

```go
f, err := os.Open(name)
if err != nil {
    return err
}
defer f.Close()
// ... use f on the un-indented happy path
```

- Don't ignore errors with `_ =` except where it's provably safe (and say so in a
  comment). `errcheck` (in golangci-lint) flags the rest.
- A deferred `Close()` on a _writable_ file can lose errors — capture it:

```go
func writeFile(name string, data []byte) (err error) {
    f, err := os.Create(name)
    if err != nil { return err }
    defer func() {
        if cerr := f.Close(); cerr != nil && err == nil {
            err = cerr // surface a close error if nothing else failed
        }
    }()
    _, err = f.Write(data)
    return err
}
```

## `panic` and `recover`

`panic` is for programmer errors and truly unrecoverable invariants — not for
normal failure. Return an `error` for anything a caller might reasonably handle.

Legitimate uses:

- Impossible states (`default:` in an exhaustive switch over your own enum).
- `MustX` constructors meant to run at init with known-good input
  (`regexp.MustCompile`).
- A top-level `recover` at a goroutine/request boundary that logs and converts to
  a 500, so one bad request doesn't crash the server:

```go
defer func() {
    if r := recover(); r != nil {
        slog.Error("panic recovered", "value", r, "stack", debug.Stack())
        http.Error(w, "internal error", http.StatusInternalServerError)
    }
}()
```

A panic that crosses a goroutine boundary takes the whole process down — recover
inside the goroutine that might panic, not in its parent.

## Errors at boundaries vs internals

- **Internal** code: wrap with `%w` and let it bubble; the caller decides.
- **Boundaries** (HTTP handler, CLI `main`): translate the error into the right
  shape — status code, exit code, user message — and log the full chain once.
  Don't leak internal error strings to end users; map sentinels/types to
  responses. See [web-services.md](web-services.md).
