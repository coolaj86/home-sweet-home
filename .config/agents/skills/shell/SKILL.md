---
name: shell
description: POSIX shell scripting conventions. Use when writing any shell script (.sh file), inline shell commands, or reviewing shell code. Covers shebang, error handling, variable naming, function naming, test syntax, JSON processing, and secrets hygiene.
---

## Basics

- **POSIX sh only.** Use `#!/bin/sh` — never bash. Avoid bashisms: process substitution
  `<(...)`, arrays, `[[`, `local`, `declare`, etc.
- **Always `set -eu`.** Every script starts with `set -eu` — exit on error, error on
  undefined variables.
- **Use `test` instead of `[ ... ]`.** `test` is the command; `[` is a noisier alias.
  Write `if test -e file` not `if [ -e file ]`.

## Variable naming

| Prefix      | Scope / use                          | Example              |
|-------------|--------------------------------------|----------------------|
| `ALL_CAPS`  | Environment variables only           | `PATH`, `HOME`       |
| `g_`        | Global to the script (and sourced)   | `g_base_url`         |
| `b_`        | Block-scoped (function, loop, cond)  | `b_count`            |
| `a_`        | Function arguments                   | `a_email`            |

## Function and command naming

- `fn_name` — helper functions (anything other than the main/entry function)
- `cmd_name` — command aliases, e.g. `cmd_curl='curl --fail-with-body -sSL'`

## JSON processing

- **Use `jq` for all JSON processing** — never python one-liners.
- Pipe curl output through `jq | tee file.json` — formats JSON, shows output on screen,
  and saves to file simultaneously. Prefer over silent `> file.json` redirects.

```sh
curl -sSL "$url" | jq '.' | tee result.json
```

## Secrets hygiene

- Write secrets to `*.env` or `*.jwk` / `*.jwt` files covered by `.gitignore`. Never
  write to `/tmp/` or other world-readable paths.
- Use separate files per secret type (e.g. `prod.jwk` for signing key, `user.jwt` for
  minted token).
- **Passwords use base58 charset only** — `123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz`.
  No ambiguous chars (0/O, l/1/I), no shell-special chars (+/=), no escaping needed.

## Tools

- **keypairs** — JWT creation/inspection. Stdout = JWT string, stderr = decoded JSON.
  Key goes to `prod.jwk`, tokens to `<email>.jwt`.
