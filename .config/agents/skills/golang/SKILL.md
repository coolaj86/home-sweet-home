---
name: golang
description: Go development conventions and workflow. Use when writing Go HTTP handlers, middleware, routes, migrations, or CSV/TSV data endpoints. Covers routing with net/http, middleware composition, data export pattern, JWT auth, pre-commit checks, and key library references.
---

## Tech stack

| Component       | Library / Notes                                                        |
| --------------- | ---------------------------------------------------------------------- |
| Go 1.26+        | many new features since Go 1.22                                        |
| HTTP Router     | `net/http` with `mux.HandleFunc("GET /{id}", handler)` and `PathValue` |
| HTTP Middleware | `github.com/therootcompany/golib/http/middleware`                      |
| HTTP Embed      | `github.com/vearutop/statigz`                                          |
| Database        | `github.com/jackc/pgx/v5` (PostgreSQL)                                 |
| ORM             | sqlc                                                                   |
| Migrations      | `github.com/therootcompany/golib/cmd/sql-migrate`                      |
| JWT / Keypairs  | `github.com/therootcompany/golib/auth/jwt`                             |
| Data marshaling | `github.com/jszwec/csvutil` (TSV default, CSV optional)                |
| Type safety     | avoid `any`; use shallow interfaces or ask to create marker interfaces |

Useful CLI tools:

- `github.com/therootcompany/golib/auth/envauth` — env-based auth
- `github.com/therootcompany/golib/auth/csvauth` — CSV-based auth
- `github.com/therootcompany/golib/io/transform/gsheet2csv` — Google Sheet → CSV
- `github.com/therootcompany/golib/io/transform/gsheet2env` — Google Sheet → .env

### Go version

Minimum: **1.26**. Use these features without version checks.

Reference per-version documentation at https://go.dev/doc/go1.xx

#### By feature

| Need                    | Use                                                              | Since |
| ----------------------- | ---------------------------------------------------------------- | ----- |
| HTTP routing            | `mux.HandleFunc("GET /{id}", h)`, `r.PathValue("id")`            | 1.22  |
| JSON with optional zero | `json:"field,omitzero"` for `T` vs `*T` and `NullBool`           | 1.24  |
| Crypto random           | `crypto/*` packages use internal CSPRNG; no `rand.Reader` needed | 1.26  |
| Crypto big ints         | `.Bytes()` methods instead of `math/big`                         | 1.25  |
| PBKDF2                  | `crypto/pbkdf2`                                                  | 1.24  |
| Iterators               | `iter` package, `range` over func                                | 1.23  |
| Loop variables          | Per-iteration scope (no `i := i` hack)                           | 1.22  |
| Random                  | `math/rand/v2`                                                   | 1.22  |
| Null types              | `database/sql.Null[T]`                                           | 1.22  |

#### Version history (for citing)

- **1.26** (Feb 2026) - crypto uses internal CSPRNG; inline pointer `new(T{f: v})`; `go fix` migrations
- **1.25** (Aug 2025) - crypto `Bytes()` replaces `big.Int`
- **1.24** (Feb 2025) - `omitzero`, `os.Root`, `crypto/pbkdf2`, `go tool`
- **1.23** (Aug 2024) - `iter` package, `range` over func
- **1.22** (Feb 2024) - ServeMux routing, per-iteration loops, `range` int, `math/rand/v2`, `sql.Null[T]`

When documenting a pattern, cite the version that introduced it (separate from minimum).

## Production-first design

Utilities and servers are built for production from the start — not "we'll harden it
later." Error handling, logging, auth, and graceful shutdown are part of the initial
implementation, not polish. Don't scaffold throwaway code; write the real thing.

## API Router

Go 1.22 added method prefixes and path parameters to `net/http` natively:

```go
mux := http.NewServeMux()
mux.HandleFunc("GET /api/items", handleListItems)
mux.HandleFunc("GET /api/items/{id}", handleGetItem)
mux.HandleFunc("POST /api/items", handleCreateItem)
```

In a handler, read path values with:

```go
id := r.PathValue("id")
```

## API Middleware

Use `github.com/therootcompany/golib/http/middleware` for composing middleware chains.
Define named middleware stacks and apply them when registering routes:

```go
baseM   := middleware.New(loggingMiddleware, realIPMiddleware)
authM   := baseM.Add(jwtMiddleware)
adminM  := authM.Add(requireAdminMiddleware)

mux.Handle("GET /api/items", authM.Then(handleListItems))
mux.Handle("GET /admin/items", adminM.Then(handleAdminListItems))
```

## API Data

Prefer TSV over JSON.

This pattern covers any endpoint that streams rows from a DB query as TSV or CSV.
TSV is the default output format — easy to `grep`, `cut`, and `awk`.

It's okay to

- embed space- or comma-delimited lists in a field
- embed small JSON objects in a field
- have some duplicate data in an endpoint
- have data spread across multiple endpoints
- use JSON when it's just too awkward to use TSV

### 1. Write SQL query

Use the `since` pattern for incremental sync support:

```sql
-- name: ItemAll :many
SELECT id, name, created_at, updated_at
FROM items
WHERE sqlc.narg('since') IS NULL OR updated_at >= sqlc.narg('since')
ORDER BY updated_at ASC, id ASC;
```

### 2. Generate Go code

```sh
sqlc generate   # or ./scripts/sqlc-generate if the project wraps it
```

### 3. Write the handler

```go
func HandleItemsAllTSV(w http.ResponseWriter, r *http.Request) {
    since := parseOptionalTime(r.URL.Query().Get("since"))

    rows, err := queries.ItemAll(r.Context(), db.ItemAllParams{
        Since: since,
    })
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "text/tab-separated-values; charset=utf-8")
    enc := csvutil.NewEncoder(w)
    enc.Delimiter = '\t'
    for _, row := range rows {
        if err := enc.Encode(row); err != nil {
            return
        }
    }
}
```

Use `github.com/jszwec/csvutil` for both reading and writing — same as `encoding/json`
but for TSV/CSV. Tag fields with `csv:"column_name"`. Embed nested structs with
`csv:",inline"` to flatten them into the row — useful for composing rows from multiple
related structs without copying fields. Offer a `.json` suffix route as a secondary
format.

### 4. Register routes

```go
mux.Handle("GET /api/items.tsv", authM.Then(HandleItemsAllTSV))
mux.Handle("GET /api/items.json", authM.Then(HandleItemsAllJSON))
```

## SQL migrations

Use `github.com/therootcompany/golib/cmd/sql-migrate` for running migrations.

Migration files use a timestamp + description naming convention:
`YYYY-MM-DD-HHMMSS_description.up.sql` / `.down.sql`

If the project uses a `_migrations` tracking table:

- Up migration begins with: `INSERT INTO _migrations (name, id) VALUES (...)`
- Down migration ends with: `DELETE FROM _migrations WHERE id = '...'`
- Generate migration ID with: `openssl rand -hex 4`

## JWT auth

Use `github.com/therootcompany/golib/auth/jwt` for issuing and verifying JWTs.
Use `github.com/therootcompany/golib/auth/jwt/keyfile` and `github.com/therootcompany/golib/auth/jwt/keyfetch` can be used for key management.

Only asymmetric algorithms are supported: Ed25519 (EdDSA), EC P-256/384/521
(ES256/384/512), RSA (RS256). Algorithm is inferred from the key type — never
configured manually.

### Claims

Embed `jwt.IDTokenClaims` (or `jwt.StandardClaims`) to satisfy `jwt.Claims`
for free via Go method promotion:

```go
type AppClaims struct {
    jwt.IDTokenClaims
    Roles []string `json:"roles"`
}
```

### Issuer: sign and publish keys

```go
// Generate a new Ed25519 signing key (recommended default).
pk, err := jwk.NewPrivateKey()

// Or wrap an existing crypto.Signer (EC, RSA, Ed25519):
pk := &jwk.PrivateKey{KID: "my-key", Signer: ecdsaPrivKey}

// Create a Signer (supports multiple keys; round-robins on sign).
signer, err := jwt.NewSigner([]jwk.PrivateKey{*pk})

// Sign a token.
tokenStr, err := signer.SignToString(&claims)

// Expose the JWKS endpoint (public keys only):
json.Marshal(&signer) // {"keys":[...]}
```

### Relying party: verify tokens

```go
// From a fixed key set:
verifier := jwt.New([]jwk.PublicKey{...})

// Or from a co-located signer:
verifier := signer.Verifier()

// Or fetch from a remote JWKS URL (lazy, cached):
fetcher := &jwt.KeyFetcher{
    URL:         "https://issuer.example.com/.well-known/jwks.json",
    MaxAge:      time.Hour,
    StaleAge:    30 * time.Minute,
    KeepOnError: true,
}
verifier, err := fetcher.Verifier()

// Verify and decode in one step:
jws, err := verifier.VerifyJWT(tokenStr)

// Decode payload into your claims struct.
var claims AppClaims
jwt.UnmarshalClaims(jws, &claims)

// Validate registered claim values (iss, aud, exp, iat, etc.).
validator := &jwt.IDTokenValidator{
    ValidatorCore: jwt.ValidatorCore{
        Iss: []string{"https://issuer.example.com"},
        Aud: []string{"my-service"},
    },
}
errs, err := validator.Validate(&claims, time.Now())
```

### JWK key management

```go
// Generate Ed25519 key with auto-computed KID (RFC 7638 thumbprint):
pk, err := jwk.NewPrivateKey()

// Read public keys from a JWKS file on disk:
keys, err := jwk.ReadFile("path/to/keys.jwks")

// Serialize a key set for storage or publishing:
data, _ := json.Marshal(jwk.JWKs{Keys: verifier.PublicKeys()})

// Round-trip a private key (includes private material; never publish):
data, _ := json.Marshal(pk)
var recovered jwk.PrivateKey
json.Unmarshal(data, &recovered)

// Determine key algorithm by type-switching on CryptoPublicKey:
switch key := pub.CryptoPublicKey.(type) {
case *ecdsa.PublicKey:  // kty "EC"
case *rsa.PublicKey:   // kty "RSA"
case ed25519.PublicKey: // kty "OKP"
}
```

## Error handling

### Sentinel errors

Define package-level sentinel errors with `errors.New` so callers can check with
`errors.Is`:

```go
var ErrNotFound = errors.New("not found")
```

### Wrapping conventions

Error messages read **less specific → more specific** (general context first,
detailed cause last). Which end gets the `%w` verb depends on which error carries
the broader meaning:

**Adding detail to a parent** — the wrapped error is the general category, and
the format string adds specifics:

```go
// ErrInvalidClaim is the parent; the rest is detail.
fmt.Errorf("%w: exp: token expired", ErrInvalidClaim)

// The caller can errors.Is(err, ErrInvalidClaim) to catch all value errors,
// while the message still says exactly what went wrong.
```

**Wrapping a child error** — the format string provides the general context, and
the wrapped error is the specific cause:

```go
// General context first, specific crypto error last.
fmt.Errorf("header json: %w", err)
```

**Both at once** (Go 1.20+ multiple `%w`) — plain-text context, then the
broader error, then the more specific one:

```go
// "payload base64" is context, ErrInvalidPayload is the broad category,
// err is the specific failure from the base64 decoder.
fmt.Errorf("payload base64: %w: %w", ErrInvalidPayload, err)
```

The rule of thumb: the `%w` goes where the _wrapped error_ sits in the
less-specific → more-specific ordering. If the sentinel is the broad category,
it goes first (`%w: details`). If it's the specific cause, it goes last
(`context: %w`).

### Composable error hierarchies

Create two-level hierarchies with `fmt.Errorf` so callers can match either the
specific error or the broader category:

```go
var (
    ErrInvalidClaim = errors.New("invalid claim value")

    // Time-based sentinels wrap ErrInvalidClaim.
    ErrAfterExp  = fmt.Errorf("%w: exp: token expired", ErrInvalidClaim)
    ErrBeforeNbf = fmt.Errorf("%w: nbf: token not yet valid", ErrInvalidClaim)
)

// errors.Is(err, ErrAfterExp)    — matches expired tokens only
// errors.Is(err, ErrInvalidClaim) — matches any invalid claim value
```

### Multi-error accumulation

Use `errors.Join` (Go 1.20+) to return all failures at once instead of
short-circuiting on the first one:

```go
var errs []error
if ... { errs = append(errs, fmt.Errorf("exp: %w", ErrMissingClaim)) }
if ... { errs = append(errs, fmt.Errorf("iss %q not allowed: %w", iss, ErrInvalidClaim)) }
return errors.Join(errs...)
```

Callers can still use `errors.Is` against the joined error to check for any
specific sentinel in the batch.

## Testing

Prefer testing real code over mocks. Avoid `httptest` recording and interface mocks
when the code itself or an appropriate test environment can be tested directly. Write
tests that exercise actual behavior — real DB queries, real handler logic — rather than
substituting fakes that only verify wiring.

## Pre-commit checks

```sh
go fmt ./...
goimports -w .
go fix ./...
go test ./...
go vet ./...
```

If sqlc-generated packages produce spurious vet warnings, use a wrapper script that
excludes them. See the [go-sqlc skill](~/.config/agents/skills/go-sqlc/SKILL.md).
