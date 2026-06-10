# Standard Library Essentials

> **Load when:** the question is about choosing/using stdlib packages — `slog`,
> `slices`/`maps`/`cmp`, `encoding/json`, `io`, `time`, `os`.

Go's standard library is the framework. Before adding a dependency, check whether
the stdlib (or `golang.org/x/...`) already covers it — it usually does, with
better long-term support.

## Structured logging — log/slog

Use `log/slog` for all application logging. Structured key/value output is
filterable and machine-parseable; `fmt.Println`/`log.Print` are not.

```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))
slog.SetDefault(logger)

slog.Info("request handled",
    "method", r.Method,
    "path", r.URL.Path,
    "status", 200,
    "dur_ms", elapsed.Milliseconds(),
)

// Attach standing context with a child logger:
reqLog := slog.With("request_id", id)
reqLog.Warn("retrying", "attempt", n)
```

- `slog.NewTextHandler` for human-readable dev logs; JSON for production.
- Pass context-aware variants (`InfoContext`) when a handler extracts trace IDs
  from `ctx`.
- Prefer typed attrs (`slog.Int`, `slog.Duration`) on hot paths to avoid the
  `any` boxing of the key/value form.

## slices / maps / cmp

The generic collection helpers — reach for these before writing a loop:

```go
slices.Sort(xs)
slices.SortFunc(users, func(a, b User) int { return cmp.Compare(a.Name, b.Name) })
i, found := slices.BinarySearch(sorted, target)
xs = slices.Compact(slices.Clone(xs)) // dedup adjacent without mutating input
keys := slices.Sorted(maps.Keys(m))   // ordered keys in one line

clear(m)            // builtin: empty a map (or zero a slice)
n := max(a, b, c)   // builtin: variadic min/max
```

See [generics-and-iterators.md](generics-and-iterators.md) for the iterator forms.

## JSON — encoding/json

Tag struct fields; decode into typed structs, not `map[string]any`.

```go
type User struct {
    ID    string    `json:"id"`
    Name  string    `json:"name"`
    Email string    `json:"email,omitempty"`     // omit when empty
    Age   *int      `json:"age,omitempty"`        // pointer = distinguish 0 from absent
    Roles []string  `json:"roles"`
}

var u User
if err := json.Unmarshal(data, &u); err != nil {
    return fmt.Errorf("decode user: %w", err)
}

// Streaming for large/long-lived sources:
dec := json.NewDecoder(r)
dec.DisallowUnknownFields() // strict: reject unexpected keys
for dec.More() { /* decode one element at a time */ }
```

Go 1.26 ships **`encoding/json/v2`** (opt-in) with a faster, more correct
encoder/decoder and clearer options — adopt it for new code that needs the
performance or stricter semantics; `encoding/json` stays supported.

For optional fields, Go 1.26's expression-form `new()` makes building pointers
ergonomic: `u.Age = new(30)`.

## io — the universal interfaces

Program against `io.Reader`/`io.Writer`; they compose across files, network,
buffers, and tests.

```go
func process(r io.Reader, w io.Writer) error {
    _, err := io.Copy(w, r) // streams without buffering the whole thing
    return err
}

// Compose: a gzip writer wrapping a file, a limited reader, etc.
data, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20)) // cap at 1 MiB
```

Use `bufio` for line/token scanning; wrap with `bufio.NewWriter` for many small
writes and `Flush()` at the end.

## time — clocks and durations

```go
deadline := time.Now().Add(30 * time.Second)
ctx, cancel := context.WithDeadline(ctx, deadline)
defer cancel()

ticker := time.NewTicker(time.Second)
defer ticker.Stop() // always stop tickers/timers to avoid leaks
```

- Store and compare instants as `time.Time`; durations as `time.Duration`.
- Inject a clock interface (`now func() time.Time`) so time-dependent logic is
  testable — or test with `synctest` (see [concurrency.md](concurrency.md)).
- Use `time.Time.Compare` and monotonic-clock-aware comparisons; avoid wall-clock
  subtraction for measuring elapsed time (use `time.Since`).

## os / flag / environment

```go
port := flag.Int("port", 8080, "listen port")
flag.Parse()

dbURL, ok := os.LookupEnv("DATABASE_URL") // ok distinguishes empty from unset
if !ok { log.Fatal("DATABASE_URL required") }

// Signals for graceful shutdown:
ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()
```

Validate config once at startup and fail fast — don't discover a missing env var
deep in a request.

## What to still reach outside stdlib for

The stdlib deliberately omits some things; common, well-supported choices:

- **DB driver/pooling:** `database/sql` + a driver (e.g. `pgx` for Postgres).
- **Migrations / typed SQL:** `sqlc`, `golang-migrate`.
- **Richer HTTP routing/middleware:** `chi` (stdlib-compatible `http.Handler`).
- **UUIDs, decimal, validation:** small focused libs.

Prefer libraries that build on stdlib interfaces (`http.Handler`, `io.Reader`,
`database/sql`) so you can swap them without rewriting call sites.
