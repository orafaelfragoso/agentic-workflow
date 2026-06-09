# Modern Toolchain

> **Load when:** the question is about modules, building, vetting, linting,
> formatting, modernizing, or CI for a Go project.

Go ships its own build system, formatter, vetter, test runner, and module
manager. The job is to wire them into a tight loop and a CI gate. Pin against live
docs via context7 before locking versions — Go releases every six months.

| Tool | Command | Role |
|------|---------|------|
| Go | `go build ./...` | compile (Go 1.26) |
| Format | `gofmt -l .` / `goimports` | canonical formatting + import grouping |
| Vet | `go vet ./...` | built-in static analysis |
| Modernize | `go fix ./...` | apply current idioms (rewritten in 1.26) |
| Lint | `golangci-lint run` | aggregate third-party linters (v2) |
| Test | `go test -race ./...` | tests + race detector |
| Modules | `go mod tidy` | dependency + go.sum management |

## Modules

```bash
go mod init example.com/app     # module path = import path = repo URL
go get github.com/some/dep@v1.4.0
go get -u ./...                 # upgrade deps (within go.mod constraints)
go mod tidy                     # add missing, remove unused, sync go.sum
```

- The `go` directive in `go.mod` (`go 1.26`) gates which language features
  compile and selects the toolchain. The newer `toolchain` line can pin an exact
  toolchain version for reproducibility.
- Commit `go.mod` **and** `go.sum`. `go.sum` is the integrity record.
- A `tool` directive (1.24+) tracks developer tools (e.g. `stringer`,
  `golangci-lint`) as versioned deps — `go tool <name>` runs them without a
  global install.
- For monorepos/multi-module repos, use a `go.work` file to develop across
  modules without `replace` directives.

## Format, vet, modernize

These three are the baseline — run them before every commit:

```bash
gofmt -l .          # lists unformatted files; empty output = clean
goimports -w .      # gofmt + manage/group imports
go vet ./...        # suspicious constructs (printf, lock copies, ...)
go fix ./...        # rewritten in 1.26: the home of Go's modernizers
```

`go fix` now builds on the same analysis framework as `go vet` and applies dozens
of fixers — loopvar, `slices`/`maps`, `min`/`max`/`clear`, `any`, and a
source-level inliner driven by `//go:fix inline` directives. Run it when adopting
a new Go version or inheriting old code.

## golangci-lint v2

The de-facto meta-linter. v2 changed the config schema — it requires
`version: "2"`. Start from [assets/golangci-template.yml](../assets/golangci-template.yml)
(copy it to `.golangci.yml`):

```bash
# via the tool directive (preferred — versioned with the repo):
go tool golangci-lint run
# or installed binary:
golangci-lint run ./...
golangci-lint run --fix   # apply autofixes where linters support them
```

Sensible default linter set: `errcheck`, `govet`, `staticcheck` (now bundles
`gosimple`/`unused`), `ineffassign`, `revive`, `gocritic`, `bodyclose`,
`misspell`. Add `gosec` for security-sensitive code. Keep the list curated — a
wall of noisy linters gets ignored.

## TypeScript-style type checking? No — the compiler is the gate

Unlike some ecosystems there's no separate type-check step: `go build ./...`
fully type-checks. `go vet` catches a second tier of correctness issues the
compiler permits. Treat a clean `build` + `vet` as mandatory.

## The four gates (run locally and in CI)

```bash
gofmt -l .          # must print nothing
go vet ./...        # must pass
go build ./...      # must compile
go test -race ./... # must pass with the race detector
```

Wire these into a `Makefile` ([assets/makefile-template](../assets/makefile-template))
and a CI workflow ([assets/ci-template.yml](../assets/ci-template.yml)).

## Builds & cross-compilation

```bash
# Small, static, reproducible binary:
CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o app ./cmd/app

# Cross-compile by setting GOOS/GOARCH — no toolchain install needed:
GOOS=linux GOARCH=arm64 go build -o app-linux-arm64 ./cmd/app
```

- `-trimpath` strips local filesystem paths for reproducibility.
- `CGO_ENABLED=0` yields a static binary (great for scratch/distroless images).
- Embed assets with `//go:embed` instead of shipping loose files.

## Performance & debugging tools

```bash
go test -bench=. -benchmem ./...          # benchmarks (use b.Loop — see testing.md)
go test -cpuprofile=cpu.out -bench=.      # then: go tool pprof cpu.out
go build -gcflags="-m" ./...              # escape analysis (what heap-allocates)
GODEBUG=gctrace=1 ./app                   # GC behaviour at runtime
```

Go 1.26 enables the **Green Tea garbage collector** by default and speeds up cgo
calls (~30%) and small allocations — re-benchmark before assuming old tuning
still applies.

## CI pipeline (the gates as a workflow)

Run on every push/PR; fail on any. See the asset for a complete GitHub Actions
file. Cache the module and build caches, run `-race`, and verify formatting:

```bash
go mod download
test -z "$(gofmt -l .)"   # fail if anything is unformatted
go vet ./...
go tool golangci-lint run
go build ./...
go test -race -coverprofile=cover.out ./...
```
