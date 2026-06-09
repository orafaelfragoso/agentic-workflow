# Generics and Iterators

> **Load when:** the question is about type parameters, constraints, generic
> functions/types, or range-over-func iterators (`iter.Seq`).

A type parameter earns its place only when it removes real duplication or links an
input type to an output type. If a concrete type works, use it — and remember the
stdlib already generic-ized the common cases (`slices`, `maps`, `cmp`).

## Type parameters and constraints

A constraint is an interface describing the permitted type set.

```go
// Constrain to comparable so we can use ==.
func Index[T comparable](s []T, target T) int {
    for i, v := range s {
        if v == target { return i }
    }
    return -1
}

// constraints.Ordered (golang.org/x/exp/constraints) or a custom union:
type Number interface { ~int | ~int64 | ~float64 }

func Sum[T Number](xs []T) T {
    var total T
    for _, x := range xs { total += x }
    return total
}
```

The `~` means "any type whose underlying type is this" — so a `type Celsius
float64` still satisfies `~float64`.

## Inference does the work

Design signatures so callers don't pass explicit type arguments:

```go
func MapSlice[T, U any](xs []T, f func(T) U) []U {
    out := make([]U, len(xs))
    for i, x := range xs { out[i] = f(x) }
    return out
}

names := MapSlice(users, func(u User) string { return u.Name }) // T,U inferred
```

## Generic types

```go
type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(v T)        { s.items = append(s.items, v) }
func (s *Stack[T]) Pop() (T, bool) {
    var zero T
    if len(s.items) == 0 { return zero, false }
    v := s.items[len(s.items)-1]
    s.items = s.items[:len(s.items)-1]
    return v, true
}
```

Go 1.26 allows **self-referential generics** (a generic type referring to itself
in its own type-parameter list), which simplifies recursive structures and
builder/fluent interfaces.

## When NOT to use generics

- A single concrete caller — write the concrete function.
- "Might need it later" — add the type parameter when the second type appears.
- Where an interface is the better tool: if you only call methods (not operators,
  not `==`, no element typing), accept an interface instead.

Concrete-first keeps code readable; generics that obscure intent are a net loss.

## Prefer the generic stdlib

Most hand-rolled generic helpers already exist:

| Need | Use |
|------|-----|
| contains / index / sort | `slices.Contains`, `slices.Index`, `slices.Sort` |
| min / max / dedup | `slices.Min`, `slices.Max`, `slices.Compact` |
| clone / equal / reverse | `slices.Clone`, `slices.Equal`, `slices.Reverse` |
| map keys / values | `maps.Keys`, `maps.Values` (iterators) |
| compare / order | `cmp.Compare`, `cmp.Or`, `cmp.Less` |
| builtins | `min`, `max`, `clear` (no import) |

```go
slices.SortFunc(users, func(a, b User) int { return cmp.Compare(a.Age, b.Age) })
best := cmp.Or(userPref, orgDefault, "fallback") // first non-zero
```

## Iterators — range-over-func

Since 1.23, a function of type `iter.Seq[T]` or `iter.Seq2[K,V]` can be ranged
over directly. This is how you write lazy, composable sequences without
allocating a full slice.

```go
import "iter"

// iter.Seq[T] = func(yield func(T) bool)
func Count(n int) iter.Seq[int] {
    return func(yield func(int) bool) {
        for i := 0; i < n; i++ {
            if !yield(i) { return } // consumer broke out
        }
    }
}

for i := range Count(5) { fmt.Println(i) } // 0..4
```

`iter.Seq2[K,V]` yields pairs (index/value, key/value):

```go
func Enumerate[T any](xs []T) iter.Seq2[int, T] {
    return func(yield func(int, T) bool) {
        for i, x := range xs {
            if !yield(i, x) { return }
        }
    }
}
for i, u := range Enumerate(users) { /* ... */ }
```

### Stdlib iterators

`maps.Keys`, `maps.Values`, `maps.All`, `slices.All`, `slices.Values`,
`slices.Backward`, `strings.Lines`, `strings.SplitSeq`, and `bytes.Lines` all
return iterators. Collect one back into a concrete container with
`slices.Collect` / `slices.Sorted` / `maps.Collect`:

```go
keys := slices.Sorted(maps.Keys(m)) // deterministic key order, one line
words := slices.Collect(strings.SplitSeq(line, " "))
```

Write your own iterator when you're streaming (large/infinite data, early exit,
pipeline stages); return a slice when the caller will just want all of it anyway.
