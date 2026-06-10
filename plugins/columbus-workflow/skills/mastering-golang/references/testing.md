# Testing

> **Load when:** the question is about writing Go tests — table-driven tests,
> subtests, parallelism, fuzzing, benchmarks, or `synctest`.

Go's testing is built in and opinionated: `testing` + `go test`, no framework
required. Table-driven tests with subtests are the default shape.

## Table-driven tests

Enumerate cases as a slice of structs; run each as a named subtest so failures
point at the exact case.

```go
func TestParse(t *testing.T) {
    tests := []struct {
        name    string
        in      string
        want    int
        wantErr bool
    }{
        {"simple", "42", 42, false},
        {"negative", "-7", -7, false},
        {"garbage", "x", 0, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Parse(tt.in)
            if (err != nil) != tt.wantErr {
                t.Fatalf("err = %v, wantErr %v", err, tt.wantErr)
            }
            if got != tt.want {
                t.Errorf("got %d, want %d", got, tt.want)
            }
        })
    }
}
```

- `t.Fatalf` stops this subtest (use when continuing is pointless); `t.Errorf`
  records and continues.
- The 1.22 loopvar change makes capturing `tt` in subtests safe.

## Parallelism and lifecycle

```go
t.Run(tt.name, func(t *testing.T) {
    t.Parallel()                 // run sibling subtests concurrently
    ctx := t.Context()           // cancelled automatically at test end (1.24)
    t.Cleanup(func() { teardown() }) // runs LIFO when the test finishes
    // ...
})
```

Mark independent tests `t.Parallel()` to cut wall time; ensure they don't share
mutable global state. Use `t.TempDir()` for filesystem isolation.

## Helpers and comparison

```go
func mustUser(t *testing.T, id string) *User {
    t.Helper() // failures report the caller's line, not this one
    u, err := loadUser(id)
    if err != nil { t.Fatalf("load %s: %v", id, err) }
    return u
}
```

Compare complex values structurally. `reflect.DeepEqual` works; many teams use
`google/go-cmp` for readable diffs and options (ignore fields, compare unexported
via exporters):

```go
if diff := cmp.Diff(want, got); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

## Fakes over mocks

Go's implicit interfaces make hand-written fakes trivial — usually better than a
mocking library. Define the interface at the consumer and pass a fake in tests.

```go
type fakeStore struct{ users map[string]*User }
func (f *fakeStore) Find(_ context.Context, id string) (*User, error) {
    u, ok := f.users[id]
    if !ok { return nil, ErrNotFound }
    return u, nil
}
// svc := NewService(&fakeStore{users: ...})
```

## Fuzzing

Built-in fuzzing finds edge cases you didn't enumerate. Add seeds, assert
invariants (e.g. round-trip), and let the engine mutate inputs.

```go
func FuzzParse(f *testing.F) {
    f.Add("42")               // seed corpus
    f.Fuzz(func(t *testing.T, s string) {
        n, err := Parse(s)
        if err != nil { return }       // invalid input is fine
        if got := Format(n); got != s { // round-trip invariant
            t.Errorf("Format(Parse(%q)) = %q", s, got)
        }
    })
}
```

```bash
go test -fuzz=FuzzParse -fuzztime=30s   # run the fuzzer
```

## Benchmarks — use b.Loop

On Go 1.24+, write benchmarks with `for b.Loop()`; it prevents the compiler from
optimizing the work away and handles setup/teardown timing correctly. Don't use
the old `for i := 0; i < b.N; i++`.

```go
func BenchmarkEncode(b *testing.B) {
    in := makeInput()
    b.ReportAllocs()
    for b.Loop() {
        _ = Encode(in)
    }
}
```

```bash
go test -bench=. -benchmem ./...
go test -bench=BenchmarkEncode -count=10 | tee new.txt
benchstat old.txt new.txt   # golang.org/x/perf — statistically compare
```

## Time and concurrency — synctest

Test retries, timeouts, tickers, and rate limiters deterministically with
`testing/synctest` (stable in 1.25): timers advance instantly in a goroutine
bubble, so no real sleeping and no flakes.

```go
func TestBackoff(t *testing.T) {
    synctest.Test(t, func(t *testing.T) {
        start := time.Now()
        retryWithBackoff(t.Context(), failing) // sleeps advance virtually
        synctest.Wait()                         // wait for bubble to go idle
        if elapsed := time.Since(start); elapsed != expectedTotal {
            t.Errorf("waited %v, want %v", elapsed, expectedTotal)
        }
    })
}
```

## Race detector & coverage

```bash
go test -race ./...                       # the bar for concurrent code
go test -cover ./...                      # quick coverage summary
go test -coverprofile=cover.out ./... && go tool cover -html=cover.out
```

Run `-race` in CI on representative tests. Chase coverage where bugs are costly
(parsing, money, auth), not for a vanity percentage.
