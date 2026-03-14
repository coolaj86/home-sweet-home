---
name: create-skill
description: Create a new Agent Skill (SKILL.md). Use when the user asks to create a skill, document a pattern as a skill, or convert existing documentation into a skill. Guides scope decision (global vs project), names the skill, and writes proper agentskills.io-format SKILL.md with frontmatter.
---

## Step 1: Determine scope

Ask the user:

> "Should this skill be **global** (available in all projects, `~/.claude/skills/<name>/SKILL.md`)
> or **project-local** (only this repo, `skills/<name>/SKILL.md`)?"

- **Global** — conventions that apply across all projects (shell scripting, JS style, SQL patterns)
- **Project-local** — patterns specific to one codebase (route registration, migration format)

## Step 2: Choose a name

The directory name = the `name` field. Rules:
- Lowercase letters, numbers, hyphens only
- No leading/trailing/consecutive hyphens
- Short and action-oriented: `go-sqlc`, `create-skill`, `shell`, `javascript`

## Step 3: Determine content

Ask: what triggers this skill? What would the agent need to know?

- **What it does** — the procedural knowledge, patterns, rules
- **When to use it** — keywords and task types that should activate it
- **Reference material** — if detailed, move to `references/` and link from `SKILL.md`

## Step 4: Write the SKILL.md

Use the agentskills.io format. See [specification](references/specification.md) for the
full canonical spec (sourced from the official GitHub repo).

```markdown
---
name: skill-name
description: One or two sentences: what it does, when to use it, key trigger keywords.
compatibility: (optional) environment requirements or intended product
---

## Section

Content...
```

**Description tips:**
- Include the trigger keywords explicitly (e.g. "Use when writing `.sh` files or shell commands")
- Describe both WHAT it does and WHEN to activate it
- 1–3 sentences is ideal; max 1024 chars

**Body tips:**
- Keep SKILL.md under 500 lines
- Move long reference tables or detailed specs to `references/REFERENCE.md`
- Link to reference files: `See [format reference](references/format.md)`

## Step 5: Place the file

**Global:**
```
~/.claude/skills/<name>/SKILL.md
~/.claude/skills/<name>/references/  (if needed)
```

**Project-local:**
```
skills/<name>/SKILL.md
skills/<name>/references/  (if needed)
```

Project-local skills should also be committed to git so all team members have them.

## Step 6: Verify

Check that:
- `name` in frontmatter matches the directory name exactly
- `description` mentions both what it does and when to use it
- Body is focused — no padding, no content that belongs in a different skill
- If body exceeds ~300 lines, consider splitting into a reference file
