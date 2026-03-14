---
name: golang
description: Go development conventions and workflow. Use when writing Go HTTP handlers, middleware, routes, migrations, or CSV/TSV data endpoints. Covers routing with net/http, middleware composition, data export pattern, JWT auth, pre-commit checks, and key library references.
---

## Tech stack

- **Go 1.22+** — uses `net/http` method routing and `PathValue`
- **Router** — `net/http` stdlib (`mux.HandleFunc("GET /path/{id}", handler)`)
- **Middleware** — `github.com/therootcompany/golib/http/middleware`
- **SQL** — sqlc + `github.com/jackc/pgx/v5` (PostgreSQL) or `database/sql` (MariaDB)
- **Migrations** — `github.com/therootcompany/golib/cmd/sql-migrate`
- **JWT** — `github.com/therootcompany/golib/auth/jwt`
- **JWK / key management** — `github.com/therootcompany/golib/auth/jwt/jwk`
- **Data marshaling** — `github.com/jszwec/csvutil` (TSV default, CSV optional)

Useful CLI tools:
- `github.com/therootcompany/golib/auth/envauth` — env-based auth
- `github.com/therootcompany/golib/auth/csvauth` — CSV-based auth
- `github.com/therootcompany/golib/io/transform/gsheet2csv` — Google Sheet → CSV
- `github.com/therootcompany/golib/io/transform/gsheet2env` — Google Sheet → .env

## Routing

Go 1.22+ `net/http` supports method prefixes and path parameters natively:

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

## Middleware

Use `github.com/therootcompany/golib/http/middleware` for composing middleware chains.
Define named middleware stacks and apply them when registering routes:

```go
baseM   := middleware.New(loggingMiddleware, realIPMiddleware)
authM   := baseM.Add(jwtMiddleware)
adminM  := authM.Add(requireAdminMiddleware)

mux.Handle("GET /api/items", authM.Then(handleListItems))
mux.Handle("GET /admin/items", adminM.Then(handleAdminListItems))
```

## Data export endpoint pattern (CSV/TSV)

This pattern covers any endpoint that streams rows from a DB query as TSV or CSV.
TSV is the default output format — easy to `grep`, `cut`, and `awk`.

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

## JWT auth

Use `github.com/therootcompany/golib/auth/jwt` to validate tokens in middleware.
Use `github.com/therootcompany/golib/auth/jwt/jwk` to load signing keys.

```go
// Load key from file
key, err := jwk.LoadPrivateKey("path/to/key.jwk")

// Validate token in middleware
claims, err := jwt.Parse(tokenString, publicKey)
```

## SQL migrations

Use `github.com/therootcompany/golib/cmd/sql-migrate` for running migrations.

Migration files use a timestamp + description naming convention:
`YYYY-MM-DD-HHMMSS_description.up.sql` / `.down.sql`

If the project uses a `_migrations` tracking table:
- Up migration begins with: `INSERT INTO _migrations (name, id) VALUES (...)`
- Down migration ends with: `DELETE FROM _migrations WHERE id = '...'`
- Generate migration ID with: `openssl rand -hex 4`

## Testing

Prefer testing real code over mocks. Avoid `httptest` recording and interface mocks
when the code itself or an appropriate test environment can be tested directly. Write
tests that exercise actual behavior — real DB queries, real handler logic — rather than
substituting fakes that only verify wiring.

## Pre-commit checks

```sh
go test ./...
go vet ./...
```

If sqlc-generated packages produce spurious vet warnings, use a wrapper script that
excludes them. See the [go-sqlc skill](~/.config/agents/skills/go-sqlc/SKILL.md).
