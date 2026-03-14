---
name: go-sqlc
description: sqlc query tooling for Go projects. Use when writing, updating, or debugging SQL queries managed by sqlc — including query design rules, batch variants, parameter syntax, type mappings, and regenerating code after query changes.
---

## Overview

No inline SQL in Go code. All queries go through sqlc. Query files live in
`db/queries/` (or similar). Generated code is ephemeral — never committed.

## Regenerating after query changes

After any change to query files:

```sh
sqlc generate
# or if the project has a wrapper:
./scripts/sqlc-generate
```

Always regenerate before running tests or building.

## Query design rules

- **No inline SQL in Go code.** All queries through sqlc. Tool/test queries get their
  own dedicated SQL file.
- **Always provide batch variants.** Any fetch by ID must also accept multiple IDs via
  `IN (sqlc.slice('ids'))`.
- **Include the grouping column in batch queries.** SELECT must include the grouping key
  (e.g. `resource_id`, `account_id`) so results can be partitioned client-side.
- **Explicit column lists.** Prefer explicit columns over `SELECT *` / `RETURNING *` —
  sqlc generates precise struct types and lets you omit internal-only columns from
  return types.

## Parameter syntax

- `sqlc.narg('name')` — nullable param (optional filters like `since`)
- `sqlc.arg('name')` — required param

Example using the optional `since` filter pattern:

```sql
-- name: FooAll :many
SELECT * FROM foo
WHERE sqlc.narg('since') IS NULL OR updated_at >= sqlc.narg('since')
ORDER BY updated_at ASC, id ASC;
```

The generated Go param will be `sql.NullTime`.

## Query performance

- **Never multi-JOIN for counting across tables.** LEFT JOINing N sub-resource tables
  in one query creates a combinatorial explosion that times out on production. Use
  **correlated subqueries** instead — one `(SELECT COUNT(*) ...)` per table — or
  separate queries.
- **First-write-wins for shared-key maps.** When multiple DB rows share a lookup key,
  add `ORDER BY updated_at DESC, created_at DESC, id DESC` to the query and use
  `if _, exists := m[key]; !exists { m[key] = val }` in Go — most-recently-updated
  row wins deterministically.
- **Study existing query patterns first.** Before writing a new aggregation query, look
  at how similar queries in the codebase are structured. Prefer small, focused,
  one-table-at-a-time queries over large cross-table JOINs.

## PostgreSQL type mappings (pgx/v5)

| SQL type             | Go type            | Notes                      |
|----------------------|--------------------|----------------------------|
| `BYTEA`              | `[]byte`           |                            |
| `encode(col, 'hex')` | `string`           | Return BYTEA as hex string |
| `TEXT[]`             | `[]string`         |                            |
| `TIMESTAMP`          | `pgtype.Timestamp` |                            |
