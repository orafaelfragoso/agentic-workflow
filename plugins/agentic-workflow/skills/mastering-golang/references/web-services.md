# Web Services

> **Load when:** the question is about building an HTTP service in Go — routing,
> handlers, middleware, JSON APIs, context, or graceful shutdown.

The stdlib `net/http` is a complete, production-grade HTTP toolkit. Since 1.22 the
built-in `ServeMux` does method-and-pattern routing, so most services need no web
framework at all.

## Routing with the stdlib mux (1.22+)

Patterns support methods, wildcards, and path-value extraction:

```go
mux := http.NewServeMux()
mux.HandleFunc("GET /users/{id}", getUser)
mux.HandleFunc("POST /users", createUser)
mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
})

func getUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")           // typed path segment
    // r.Context() is request-scoped and cancelled on client disconnect
    u, err := store.Find(r.Context(), id)
    // ...
}
```

`{id...}` matches the rest of the path; a trailing `/` makes a subtree match.
Reach for `chi` only when you need route groups, rich middleware chains, or
sub-routers — and it stays `http.Handler`-compatible, so the rest of this applies.

## Handlers and dependencies

Give handlers their dependencies via a struct (or closures) rather than globals:

```go
type API struct {
    store  UserStore
    logger *slog.Logger
}

func (a *API) routes() http.Handler {
    mux := http.NewServeMux()
    mux.HandleFunc("GET /users/{id}", a.getUser)
    return a.withMiddleware(mux)
}

func (a *API) getUser(w http.ResponseWriter, r *http.Request) {
    u, err := a.store.Find(r.Context(), r.PathValue("id"))
    if err != nil {
        a.writeError(w, r, err) // central error mapping
        return
    }
    writeJSON(w, http.StatusOK, u)
}
```

## Middleware = handler decorators

Middleware is `func(http.Handler) http.Handler`. Compose them outermost-first.

```go
func RequestLogger(log *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            next.ServeHTTP(w, r)
            log.Info("request",
                "method", r.Method, "path", r.URL.Path,
                "dur_ms", time.Since(start).Milliseconds())
        })
    }
}

func Recover(log *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            defer func() {
                if rec := recover(); rec != nil {
                    log.Error("panic", "value", rec, "stack", debug.Stack())
                    http.Error(w, "internal error", http.StatusInternalServerError)
                }
            }()
            next.ServeHTTP(w, r)
        })
    }
}
```

## JSON in / out

Decode strictly, validate, and encode with a small helper. Don't leak internal
errors to clients.

```go
func decodeJSON[T any](r *http.Request) (T, error) {
    var v T
    dec := json.NewDecoder(http.MaxBytesReader(nil, r.Body, 1<<20)) // cap 1 MiB
    dec.DisallowUnknownFields()
    if err := dec.Decode(&v); err != nil {
        return v, fmt.Errorf("decode body: %w", err)
    }
    return v, nil
}

func writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(v)
}
```

## Map errors at the boundary

Translate sentinels/types into status codes in one place; log the full chain
once, return a clean message. See [error-handling.md](error-handling.md).

```go
func (a *API) writeError(w http.ResponseWriter, r *http.Request, err error) {
    switch {
    case errors.Is(err, ErrNotFound):
        writeJSON(w, http.StatusNotFound, map[string]string{"error": "not found"})
    case errors.As(err, new(*ValidationError)):
        writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
    default:
        a.logger.ErrorContext(r.Context(), "unhandled", "err", err)
        writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "internal error"})
    }
}
```

## Server config & graceful shutdown

Never use `http.ListenAndServe` bare in production — set timeouts and shut down
cleanly on a signal so in-flight requests finish.

```go
func run(ctx context.Context, api *API) error {
    srv := &http.Server{
        Addr:              ":8080",
        Handler:           api.routes(),
        ReadHeaderTimeout: 5 * time.Second,
        ReadTimeout:       15 * time.Second,
        WriteTimeout:      15 * time.Second,
        IdleTimeout:       60 * time.Second,
    }

    ctx, stop := signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)
    defer stop()

    errCh := make(chan error, 1)
    go func() { errCh <- srv.ListenAndServe() }()

    select {
    case err := <-errCh:
        if !errors.Is(err, http.ErrServerClosed) { return err }
        return nil
    case <-ctx.Done():
        shutCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
        defer cancel()
        return srv.Shutdown(shutCtx) // stop accepting, drain in-flight
    }
}
```

## Outbound HTTP

- Reuse one `*http.Client` (it pools connections); don't make one per request.
- Set a timeout: `&http.Client{Timeout: 10 * time.Second}` or per-request via
  `http.NewRequestWithContext` + a context deadline.
- Always `defer resp.Body.Close()` and drain the body so the connection can be
  reused.
