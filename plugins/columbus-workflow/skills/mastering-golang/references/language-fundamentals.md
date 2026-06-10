# Language Fundamentals

> **Load when:** the question is about Go's type system — structs, methods,
> interfaces, zero values, slices/maps, or value vs pointer semantics.

Go is small on purpose. The leverage comes from a few orthogonal rules applied
consistently, not from clever abstractions.

## Zero values are the default API

Every type has a useful zero value; design so the zero value works without
construction. `var b bytes.Buffer`, `var mu sync.Mutex`, `var wg sync.WaitGroup`
are all ready to use. A constructor (`NewX`) earns its place only when the zero
value can't be valid.

```go
type Counter struct{ n int } // zero value is a working counter
func (c *Counter) Inc()  { c.n++ }
func (c *Counter) Val() int { return c.n }

var c Counter // no constructor needed
c.Inc()
```

## Structs and methods

Methods attach to a named type. Choose the receiver deliberately:

- **Pointer receiver** (`*T`) when the method mutates, the struct is large, or
  _any_ method needs a pointer (keep the set consistent).
- **Value receiver** (`T`) for small, immutable values.

```go
type Rect struct{ W, H float64 }
func (r Rect) Area() float64 { return r.W * r.H }      // value: read-only
func (r *Rect) Scale(f float64) { r.W *= f; r.H *= f } // pointer: mutates
```

Never copy a struct that contains a `sync.Mutex`/`sync.WaitGroup` — pass `*T`.
`go vet` catches many lock-copy bugs.

## Interfaces: small, and defined by the consumer

An interface is a set of method signatures. Idiomatic Go keeps them tiny and
declares them **where they're used**, not where they're implemented. Implementing
is implicit — no `implements` keyword.

```go
// Defined next to the code that needs it.
type Reader interface { Read(p []byte) (int, error) }

// Accept the narrowest interface; return concrete types.
func CountLines(r io.Reader) (int, error) { /* ... */ }
```

Guidelines:

- "Accept interfaces, return structs." Callers get a concrete type they can use
  fully; you keep freedom to satisfy narrow interfaces.
- One- and two-method interfaces are the norm (`io.Reader`, `io.Writer`,
  `fmt.Stringer`). A big interface is usually a design smell.
- The empty interface is `any`. Use it only at genuine boundaries
  (serialization, `printf`-style APIs) — then type-switch or assert.

```go
switch v := x.(type) {
case string: useString(v)
case int:    useInt(v)
default:     return fmt.Errorf("unexpected %T", v)
}
```

## Slices and maps — the sharp edges

A slice is a view (ptr, len, cap) over a backing array. Appends may or may not
reallocate, so aliasing bites:

```go
s := []int{1, 2, 3}
t := s[:2]            // shares backing array with s
t = append(t, 99)    // overwrites s[2]! both now see 99

// Want an independent copy:
u := slices.Clone(s)
```

- Preallocate when the size is known: `make([]T, 0, n)`.
- Reading a missing map key returns the zero value; use the comma-ok form to
  distinguish absent from zero: `v, ok := m[k]`.
- Maps are not safe for concurrent writes — guard with a mutex or use
  `sync.Map` for the specific read-mostly case.
- Iterate with the stdlib helpers (`slices.Sorted`, `maps.Keys`) instead of
  hand-rolled loops where it reads cleaner — see
  [generics-and-iterators.md](generics-and-iterators.md).

## Value vs pointer semantics

Go is pass-by-value: function arguments are copied. Pass a pointer to mutate the
caller's value or to avoid copying something large. Slices, maps, channels, and
functions are reference-like (they hold internal pointers) — passing them copies
the header, not the underlying data.

```go
func reset(s []int) { for i := range s { s[i] = 0 } } // mutates caller's backing array
func rename(u User) { u.Name = "x" }                  // no effect — User is copied
func rename2(u *User) { u.Name = "x" }                // mutates caller's User
```

## Composition over inheritance

Go has no inheritance. Embed a type to promote its fields and methods, and
compose behavior from small pieces.

```go
type Base struct{ ID string }
func (b Base) Key() string { return b.ID }

type User struct {
    Base          // embedded: User has .ID and .Key()
    Name string
}
```

Embed an _interface_ to require it while adding methods (decorator pattern):

```go
type LoggingStore struct {
    UserStore        // embedded interface — satisfied by the wrapped value
    log *slog.Logger
}
```

## Constants and `iota`

Use typed constant groups with `iota` for enumerations; add a `String()` method
(or `go:generate stringer`) for readable output.

```go
type State int
const (
    Pending State = iota
    Active
    Closed
)
func (s State) String() string { return [...]string{"pending", "active", "closed"}[s] }
```

## Naming and packages

- Exported = Capitalized; unexported = lowercase. Export the minimum.
- Package name is part of the API: `chk.Valid`, not `chkutil.CheckValid`. Avoid
  `util`/`common`/`helpers` grab-bags and import cycles.
- Exported symbols get a doc comment starting with the symbol name
  (`// User represents ...`).
- Short names in short scopes (`i`, `r`, `err`); descriptive names for
  package-level identifiers.
