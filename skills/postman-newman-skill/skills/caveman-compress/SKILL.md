---
name: caveman-compress
description: >
  Compress natural language memory files (CLAUDE.md, todos, preferences, docs) into caveman
  format to save input tokens on every session start. Preserves all technical substance, code,
  URLs, commands and structure. Compressed version overwrites original. Human-readable backup
  saved as FILE.original.md. Use when user says "compress memory file", "compress CLAUDE.md",
  "reduce tokens in doc", or invokes /caveman:compress <filepath>.
---

Compress natural language files to caveman-speak. Reduce input tokens. Preserve all technical content exactly.

## Trigger

`/caveman:compress <filepath>` or "compress memory file / CLAUDE.md / doc"

## Process

1. Read the file
2. Compress prose sections only (see rules below)
3. Save backup as `<filename>.original.md`
4. Overwrite original with compressed version
5. Report: original size → compressed size → % saved

## Compression Rules

### Remove
- Articles: a, an, the
- Filler: just, really, basically, actually, simply, essentially, generally
- Pleasantries: "sure", "certainly", "of course", "happy to", "I'd recommend"
- Hedging: "it might be worth", "you could consider", "it would be good to"
- Redundant phrasing: "in order to" → "to", "make sure to" → "ensure"
- Connective fluff: "however", "furthermore", "additionally", "in addition"

### Preserve EXACTLY — never modify
- Code blocks (fenced ``` and indented)
- Inline code (`backtick content`)
- URLs and links
- File paths
- Commands
- Technical terms, library names, API names
- Proper nouns (project names, people, companies)
- Dates, version numbers, numeric values
- Environment variables

### Preserve Structure
- All markdown headings (compress body below, not heading text)
- Bullet point hierarchy
- Numbered lists
- Tables (compress cell text, keep structure)
- Frontmatter/YAML headers

### Compress
- Short synonyms: "big" not "extensive", "fix" not "implement a solution for"
- Fragments OK: "Run tests before commit" not "You should always run tests before committing"
- Drop "you should", "make sure to", "remember to"
- Merge redundant bullets

## Boundaries

- ONLY compress: `.md`, `.txt`, extensionless files
- NEVER modify: `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.toml`, `.env`, `.sh`
- Mixed content: compress prose sections only, leave code untouched
- Never compress `FILE.original.md` backups
