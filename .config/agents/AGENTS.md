# Critical Rules

- **ALWAYS commit before summarizing work for review.** Uncommitted work in worktrees has been lost — commit is the only safe checkpoint.
- **Make atomic commits at the end of every work loop before responding.** Committing is non-destructive — don't ask, just commit. Each commit should be a coherent unit of change.
- **NEVER force-remove worktrees.** If `git worktree remove` warns about modified/untracked files, STOP and ask the user.
- **Before any destructive action (--force, rm -rf, reset --hard), always ask.** The cost of pausing is low; the cost of lost work is high.

# Project & Directory Conventions

- **Always look for an `AGENTS.md`** at the root of each project, and in any directory you work in. Read it before starting work in that context — it may contain project-specific instructions, conventions, or constraints.

# Tool Preferences

- **Never use Python.** For JSON processing, use `jq`. For anything more complex, write a Go tool.

# Code Design

- **YAGNI.** Don't build for hypothetical future requirements. Only add complexity when a real use case demands it. Three similar lines of code is better than a premature abstraction. If there's no pattern in the actual data today, don't design for one.
- **One entry per line in collection literals.** In maps, slices, and arrays, put each element on its own line. Don't stagger multiple entries per line — it's harder to scan and diff.
- **Prefer libraries over frameworks.** A library is something the caller controls — it provides functions you call from your code. A framework dictates structure — it calls your code. When writing code, default to the library style: give the user composable pieces they call and control, not scaffolding they must conform to. Inversion of control should be opt-in, not the starting point.

# Batch Work Strategy

- **Manual first, automate second.** When doing a large batch of similar operations, do a few by hand first to understand the real variations. Then write a tool that automates exactly what you did manually. Run the tool, and update it as edge cases surface. Don't jump straight to automation — the manual pass reveals the actual patterns.

# MCP Tools: repo-context

The `repo-context` MCP server provides fast, pre-analyzed context for Go codebases — AST, call graphs, behavior, side effects. Analyze once, then get quick answers without reading files.

**First thing in any Go repo:** run `analyze_local path="/path/to/project"` before doing anything else. This gives you the full picture — call graphs, types, side effects — so you make informed decisions from the start instead of guessing from file reads.

**Setup:** `claude mcp add repo-context --scope user -e MCP_STORAGE_PATH=.../data/contexts -e MCP_TEMP_DIR=/tmp/mcp-repos -- mcp-repo-context` (stores in `~/.claude.json`, NOT `~/.claude/.mcp.json`)

**Available tools after analysis:**
- `smart_query` — natural language questions, auto-routes to the right tool (~2-4k tokens)
- `get_function_context` — what a function does: behavior, callers, SQL, HTTP calls (~4k tokens)
- `search_context` — find functions/types by name (~2k tokens)
- `get_callers` — who calls a function (~2k tokens)
- `search_by_side_effect` — find DB queries, HTTP calls, file I/O (~3k tokens)
- `search_by_concept` — find auth, validation, handler code (~3k tokens)

**Fall back to Explore/Grep/Read when:**
- You need exact source code (MCP gives structure and summaries, not raw source)
- Non-Go files or non-code content

# API Data Formats

- **Prefer tab-separated values (TSV) for API output.** The primary data format for APIs should be plain TSV — easy to consume with `cut`, `grep`, `sort`, `awk`, and by LLM agents. Use Go's `csvutil` with tab delimiter for struct marshaling; nested structs that inline-flatten are fine.
- **Avoid quoted fields.** Design schemas so values never need quoting — no tabs or newlines in field values. This keeps output greppable and parseable without a CSV library.
- **Lists within fields:** space-separated or comma-separated values within a single field are acceptable (e.g. `linux,darwin,windows`). JSON within a field is okay when truly necessary but should be rare.
- **JSON is secondary.** Offer JSON as an alternative format (`.json` suffix) but TSV is the default and primary format.

# Shell Style

- **Use `test` instead of `[ ... ]`** in POSIX shell scripts. `test` is the command; `[` is an alias that adds noise. Write `if test -e file` not `if [ -e file ]`.

# Shell Naming Conventions

**Variables:**
- `ALL_CAPS` — environment variables only (`PATH`, `HOME`, `WEBI_VERSION`)
- `g_varname` — global to the script (and sourced scripts)
- `b_varname` — block-scoped (inside a function, loop, or conditional)
- `a_varname` — function arguments

**Functions and commands:**
- `fn_name` — helper functions (anything other than the script's main/entry function)
- `cmd_name` — command aliases, e.g. `cmd_curl='curl --fail-with-body -sSL'`
