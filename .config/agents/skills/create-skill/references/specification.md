# Agent Skills Specification

> Source: https://github.com/agentskills/agentskills/blob/main/docs/specification.mdx

## Directory structure

A skill is a directory containing, at minimum, a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

## `SKILL.md` format

The `SKILL.md` file must contain YAML frontmatter followed by Markdown content.

### Frontmatter

| Field           | Required | Constraints |
|-----------------|----------|-------------|
| `name`          | Yes      | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen. |
| `description`   | Yes      | Max 1024 characters. Non-empty. Describes what the skill does and when to use it. |
| `license`       | No       | License name or reference to a bundled license file. |
| `compatibility` | No       | Max 500 characters. Indicates environment requirements (intended product, system packages, network access, etc.). |
| `metadata`      | No       | Arbitrary key-value mapping for additional metadata. |
| `allowed-tools` | No       | Space-delimited list of pre-approved tools the skill may use. (Experimental) |

**Minimal example:**

```markdown
---
name: skill-name
description: A description of what this skill does and when to use it.
---
```

**Example with optional fields:**

```markdown
---
name: pdf-processing
description: Extract PDF text, fill forms, merge files. Use when handling PDFs.
license: Apache-2.0
metadata:
  author: example-org
  version: "1.0"
---
```

#### `name` field

- Must be 1-64 characters
- May only contain unicode lowercase alphanumeric characters (`a-z`) and hyphens (`-`)
- Must not start or end with a hyphen (`-`)
- Must not contain consecutive hyphens (`--`)
- Must match the parent directory name

Valid examples:
```yaml
name: pdf-processing
name: data-analysis
name: code-review
```

Invalid examples:
```yaml
name: PDF-Processing  # uppercase not allowed
name: -pdf            # cannot start with hyphen
name: pdf--processing # consecutive hyphens not allowed
```

#### `description` field

- Must be 1-1024 characters
- Should describe both what the skill does and when to use it
- Should include specific keywords that help agents identify relevant tasks

Good example:
```yaml
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.
```

Poor example:
```yaml
description: Helps with PDFs.
```

#### `license` field

- Specifies the license applied to the skill
- Keep it short — either the license name or a bundled license filename

```yaml
license: Proprietary. LICENSE.txt has complete terms
```

#### `compatibility` field

- Must be 1-500 characters if provided
- Only include if the skill has specific environment requirements
- Can indicate intended product, required system packages, network access needs, etc.
- Most skills do not need this field

```yaml
compatibility: Designed for Claude Code (or similar products)
compatibility: Requires git, docker, jq, and access to the internet
```

#### `metadata` field

- A map from string keys to string values
- Use for additional properties not defined by the Agent Skills spec
- Make key names reasonably unique to avoid conflicts

```yaml
metadata:
  author: example-org
  version: "1.0"
```

#### `allowed-tools` field

- A space-delimited list of tools that are pre-approved to run
- Experimental — support may vary between agent implementations

```yaml
allowed-tools: Bash(git:*) Bash(jq:*) Read
```

### Body content

The Markdown body after the frontmatter contains the skill instructions. No format
restrictions. Write whatever helps agents perform the task effectively.

Recommended sections:
- Step-by-step instructions
- Examples of inputs and outputs
- Common edge cases

The agent loads this entire file once the skill is activated. Consider splitting longer
content into referenced files.

## Optional directories

### `scripts/`

Contains executable code that agents can run. Scripts should:
- Be self-contained or clearly document dependencies
- Include helpful error messages
- Handle edge cases gracefully

Supported languages depend on the agent implementation.

### `references/`

Contains additional documentation agents can read when needed:
- `REFERENCE.md` — detailed technical reference
- `FORMS.md` — form templates or structured data formats
- Domain-specific files (`finance.md`, `legal.md`, etc.)

Keep individual reference files focused. Agents load these on demand, so smaller files
mean less context usage.

### `assets/`

Contains static resources:
- Templates (document templates, configuration templates)
- Images (diagrams, examples)
- Data files (lookup tables, schemas)

## Progressive disclosure

Skills should be structured for efficient context usage:

1. **Metadata** (~100 tokens): `name` + `description` loaded at startup for all skills
2. **Instructions** (< 5000 tokens recommended): full `SKILL.md` body loaded when skill activates
3. **Resources** (as needed): files in `scripts/`, `references/`, `assets/` loaded only when required

Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.

## File references

Use relative paths from the skill root:

```markdown
See [the reference guide](references/REFERENCE.md) for details.

Run the extraction script:
scripts/extract.py
```

Keep file references one level deep from `SKILL.md`. Avoid deeply nested reference chains.

## Validation

Use the [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref)
reference library to validate your skills:

```bash
skills-ref validate ./my-skill
```

This checks that `SKILL.md` frontmatter is valid and follows all naming conventions.
