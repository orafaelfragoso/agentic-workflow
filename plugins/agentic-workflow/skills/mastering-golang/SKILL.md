---
name: mastering-golang
description: Master modern, idiomatic Go — language fundamentals (interfaces, structs, zero values), concurrency done right (goroutines, channels, context, errgroup, synctest), generics and range-over-func iterators, errors-as-values handling, the stdlib-first toolkit (slog, slices/maps/cmp), and a current toolchain (Go 1.26, go fix modernizers, golangci-lint v2, race/fuzz testing). Use when writing or reviewing Go, designing packages and APIs, fixing concurrency or error-handling issues, modernizing legacy Go, or wiring go.mod/build/test/CI.
---

# Mastering Modern Go

Write Go that reads like the standard library: clear, small, and boring in the
best way. Let `go build`, `go vet`, and `go test` carry the proof.

> **Compatibility (mid-2026):** Go 1.26 (released Feb 2026), golangci-lint v2,
> stdlib-first (`slog`, `slices`, `maps`, `cmp`, `iter`). Targets the current
> two-release support window (1.25 / 1.26).

## Toolchain at a glance

| Tool | Version | Notes |
|------|---------|-------|
| Go | 1.26.x | `new(expr)`, self-referential generics, Green Tea GC default |
| Formatter | `gofmt` / `goimports` | non-negotiable; CI fails on unformatted code |
| Vet | `go vet ./...` | built-in static checks; same framework as `go fix` |
| Modernizer | `go fix ./...` | rewritten in 1.26 — applies current idioms + inliner |
| Linter | golangci-lint v2 | aggregate linters; config `version: "2"` |
| Test | `go test -race ./...` | table-driven + `synctest` + fuzzing |

Resolve current docs with context7 before pinning a version — this table ages.

> **Stdlib first.** Reach for a dependency only when the standard library and
> `golang.org/x/...` genuinely don't cover it. `slices`, `maps`, `cmp`, `slog`,
> `iter`, `net/http`, and `encoding/json/v2` replace most small utility deps.

## Quick start

```bash
go mod init example.com/app        # module path = repo URL
go get github.com/some/dep@latest  # add a dependency
go mod tidy                        # prune + sync go.sum

# the four gates — run before calling anything done
go build ./...
go vet ./...
go test -race ./...
gofmt -l .                         # lists unformatted files (empty = clean)
```

Set the language version in `go.mod` (gates which features compile):

```
// go.mod
module example.com/app

go 1.26
```

## When to use this skill

- Writing or reviewing Go and wanting it idiomatic, not just compiling.
- Designing package boundaries and APIs (interfaces, zero values, errors).
- Getting concurrency right — cancellation, no leaks, no data races.
- Using generics and range-over-func iterators where they remove real duplication.
- Modernizing older Go (pre-generics helpers, manual loops, `interface{}`).
- Wiring go.mod, golangci-lint, and a CI pipeline.

## Project setup checklist

```
- [ ] go.mod language version pinned (go 1.26) + go mod tidy clean
- [ ] gofmt/goimports enforced in CI (gofmt -l . is empty)
- [ ] go vet ./... clean; go fix ./... applied for modern idioms
- [ ] golangci-lint v2 configured (.golangci.yml, version: "2")
- [ ] go test -race ./... green; coverage where it matters
- [ ] context.Context threaded through I/O and concurrency
- [ ] structured logging via log/slog (no fmt.Print / log.Print)
```

## Core idioms (the short list)

- **Errors are values.** Return them; wrap with `fmt.Errorf("...: %w", err)`;
  inspect with `errors.Is`/`errors.As`, never string matching. Reserve `panic`
  for unrecoverable invariants.
- **Accept interfaces, return concrete types.** Keep interfaces small and
  defined by the *consumer*. A one-method interface is often the right size.
- **Make the zero value useful.** A freshly-declared `var b bytes.Buffer` or
  `sync.Mutex` should work without initialization.
- **`context.Context` is the first argument.** Thread it through I/O and
  concurrency; honor cancellation; never store it in a struct.
- **Every goroutine has an owner and an exit.** Share by communicating, or guard
  shared state with a mutex — and prove it with `-race`.
- **Prefer the stdlib.** `slices`/`maps`/`cmp`/`slog`/`iter` over hand-rolled
  helpers or small dependencies.
- **`go fmt` + `go vet` + `go fix` are not optional.** Formatted, vetted,
  modernized code is the baseline, not a nicety.

### Errors as values + wrapping

```go
var ErrNotFound = errors.New("not found") // comparable sentinel

func loadUser(ctx context.Context, id string) (*User, error) {
    u, err := repo.Find(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
        }
        return nil, fmt.Errorf("load user %s: %w", id, err) // keep the chain
    }
    return u, nil
}

// caller inspects by identity / type, never by string
if errors.Is(err, ErrNotFound) { /* 404 */ }
```

### Consumer-defined interfaces

```go
// Define the interface where it's used, not where it's implemented.
type UserStore interface {
    Find(ctx context.Context, id string) (*User, error)
}

func NewService(store UserStore) *Service { return &Service{store: store} }
// Tests pass a fake UserStore — no mocking framework needed.
```

### A goroutine with a clear exit (errgroup)

```go
g, ctx := errgroup.WithContext(ctx)
for _, url := range urls {
    g.Go(func() error { return fetch(ctx, url) }) // 1.22+ loopvar: safe capture
}
if err := g.Wait(); err != nil { // first error cancels the rest
    return fmt.Errorf("fetch batch: %w", err)
}
```

## Common mistakes

| Mistake | Why it bites | Fix |
|---------|--------------|-----|
| `interface{}` soup | Loses all type safety | `any` only at true boundaries; concrete types otherwise |
| String-matching errors | Breaks on message changes | `errors.Is` / `errors.As` + sentinels/types |
| Storing `context.Context` in a struct | Hidden lifetime, leaks | Pass as first arg |
| Goroutine with no exit path | Leaks until process dies | Owner + cancellation via `ctx`/channel |
| Mutex copied by value | Silently broken locking | Hold/pass `*T`; `go vet` catches some |
| `panic` for normal failures | Crashes instead of handling | Return an `error` |
| Reflexive premature generics | Harder to read, no payoff | Concrete types until duplication is real |
| `fmt.Println` logging | Unstructured, unfilterable | `log/slog` |

## Modernizing older Go

1. Set the `go` directive in `go.mod` to 1.26 so new features compile.
2. Run `go fix ./...` — the rewritten modernizer applies current idioms
   (loopvar, `slices`/`maps`, `min`/`max`/`clear`, `any`) and can inline via
   `//go:fix` directives.
3. Replace hand-rolled utilities with `slices`/`maps`/`cmp`; replace manual
   index loops over collections with range-over-func iterators where it reads
   cleaner.
4. Swap `log`/`fmt.Print` for `log/slog`; thread `context.Context` through I/O.
5. Re-run the four gates (`build`/`vet`/`test -race`/`gofmt -l`) after each step.

See [references/toolchain.md](references/toolchain.md) for the full pipeline.

## Reference files

- [references/language-fundamentals.md](references/language-fundamentals.md) — types, zero values, structs, methods, interfaces, slices/maps
- [references/error-handling.md](references/error-handling.md) — wrapping, sentinels, `errors.Is`/`As`, custom errors, panic/recover
- [references/concurrency.md](references/concurrency.md) — goroutines, channels, `context`, `sync`, `errgroup`, patterns, `synctest`
- [references/generics-and-iterators.md](references/generics-and-iterators.md) — type params, constraints, `iter.Seq`, range-over-func
- [references/stdlib-essentials.md](references/stdlib-essentials.md) — `slices`/`maps`/`cmp`, `slog`, `encoding/json`, `io`, time
- [references/testing.md](references/testing.md) — table-driven tests, subtests, `t.Parallel`, `synctest`, fuzzing, benchmarks
- [references/web-services.md](references/web-services.md) — `net/http`, ServeMux routing, middleware, JSON APIs, graceful shutdown
- [references/toolchain.md](references/toolchain.md) — modules, `go vet`/`go fix`, golangci-lint v2, race, build & CI

## Assets

Copy these into your project root and adjust:

- [assets/golangci-template.yml](assets/golangci-template.yml) — `.golangci.yml` (golangci-lint v2)
- [assets/makefile-template](assets/makefile-template) — `Makefile` with the four gates
- [assets/ci-template.yml](assets/ci-template.yml) — GitHub Actions Go pipeline
