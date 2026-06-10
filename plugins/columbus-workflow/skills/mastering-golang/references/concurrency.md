# Concurrency

> **Load when:** the question is about goroutines, channels, `context`, `sync`,
> `errgroup`, data races, or testing concurrent/time-dependent code.

Go's concurrency is cheap but not free of discipline. Two rules carry most of it:
**every goroutine needs a clear exit**, and **shared state needs a guard** (a
channel or a mutex). Prove both with `go test -race`.

## Goroutines have owners

A goroutine that no one can stop is a leak. Give every goroutine a way to finish:
a closed channel, a cancelled `context`, or a bounded loop.

```go
// Bad: leaks if the reader stops before the channel drains.
go func() { for x := range work { process(x) } }()

// Good: cancellation via context, explicit done.
go func() {
    for {
        select {
        case <-ctx.Done():
            return
        case x, ok := <-work:
            if !ok { return }
            process(x)
        }
    }
}()
```

The 1.22 loop-variable change means `for _, v := range xs { go use(v) }` captures
a fresh `v` per iteration — the classic closure bug is gone on modern Go.

## context.Context — cancellation and deadlines

`context` carries cancellation, deadlines, and request-scoped values across API
boundaries. Pass it as the **first argument**; never store it in a struct.

```go
func fetch(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel() // always cancel to release resources

    req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("fetch %s: %w", url, err)
    }
    defer resp.Body.Close()
    return io.ReadAll(resp.Body)
}
```

- Honor cancellation in loops: `select { case <-ctx.Done(): return ctx.Err() ... }`.
- `context.Value` is for request-scoped data (trace IDs), not for passing
  optional parameters — pass those explicitly.

## Channels: communicate, don't share

Use channels to hand off ownership of data between goroutines. Conventions that
prevent deadlocks and panics:

- **The sender closes**, never the receiver. Closing signals "no more values".
- Receiving from a closed channel yields the zero value + `ok == false`.
- A `nil` channel blocks forever — useful to disable a `select` case.
- Buffer only with a reason (known burst size, decoupling); an unbuffered channel
  is a synchronization point.

```go
func producer(ctx context.Context, out chan<- int) {
    defer close(out) // sender owns the close
    for i := 0; i < 10; i++ {
        select {
        case out <- i:
        case <-ctx.Done():
            return
        }
    }
}
```

## errgroup — fan-out that can fail

`golang.org/x/sync/errgroup` runs a group of goroutines, returns the first error,
and cancels the shared context so siblings stop early. Use `SetLimit` to bound
concurrency.

```go
g, ctx := errgroup.WithContext(ctx)
g.SetLimit(8) // at most 8 in flight
results := make([]Result, len(ids))
for i, id := range ids {
    g.Go(func() error {
        r, err := fetchOne(ctx, id)
        if err != nil {
            return fmt.Errorf("fetch %s: %w", id, err)
        }
        results[i] = r // distinct index per goroutine — no lock needed
        return nil
    })
}
if err := g.Wait(); err != nil {
    return nil, err
}
```

## sync primitives

- `sync.WaitGroup` waits for a set of goroutines. On Go 1.25+ prefer
  `wg.Go(fn)` over manual `Add(1)`/`go func(){ defer Done() ... }()`.
- `sync.Mutex` / `sync.RWMutex` guard shared state. Keep the critical section
  small; never copy a mutex (pass `*T`).
- `sync.Once` for one-time init; `sync.OnceValue`/`OnceFunc` (1.21+) for lazy
  singletons without boilerplate.
- `atomic.Int64` etc. for simple counters instead of a mutex.

```go
var wg sync.WaitGroup
for _, job := range jobs {
    wg.Go(func() { run(job) }) // 1.25: no Add/Done bookkeeping
}
wg.Wait()
```

```go
// Guard shared state with the narrowest lock.
type SafeMap struct {
    mu sync.RWMutex
    m  map[string]int
}
func (s *SafeMap) Get(k string) (int, bool) {
    s.mu.RLock(); defer s.mu.RUnlock()
    v, ok := s.m[k]; return v, ok
}
```

## Common patterns

- **Worker pool:** fixed goroutines reading a jobs channel; close jobs to drain,
  `WaitGroup` to wait. Or just `errgroup` with `SetLimit`.
- **Pipeline:** stages connected by channels, each stage closing its output;
  propagate `ctx` so cancellation tears the whole pipe down.
- **Fan-in / fan-out:** split work across N goroutines, merge results on one
  channel; the merger closes when all producers finish (`WaitGroup` + a closer
  goroutine).

## Data races are bugs, full stop

Two goroutines touching the same memory with at least one writer, unsynchronized,
is undefined behavior. Run tests and CI with the race detector:

```bash
go test -race ./...
```

It instruments memory accesses and reports the conflicting stacks. A green
`-race` run on representative tests is the bar before shipping concurrent code.
Go 1.26 adds an experimental **goroutine-leak profile**
(`GOEXPERIMENT=goroutineleakprofile`) that flags goroutines blocked forever.

## Testing concurrent & time-dependent code — synctest

`testing/synctest` (stable in 1.25) runs a goroutine "bubble" with a fake clock so
time-based concurrency is deterministic and fast — no real sleeping, no flakes.

```go
import "testing/synctest"

func TestTimeout(t *testing.T) {
    synctest.Test(t, func(t *testing.T) {
        ctx, cancel := context.WithTimeout(context.Background(), time.Hour)
        defer cancel()
        // time.Sleep / timers advance instantly within the bubble
        synctest.Wait() // block until all bubbled goroutines are idle
        // assert on the result deterministically
    })
}
```

Use it for retries/backoff, tickers, deadlines, and rate limiters — anything you'd
otherwise test with real `time.Sleep`. See [testing.md](testing.md).
