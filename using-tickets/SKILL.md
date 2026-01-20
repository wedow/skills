---
name: using-tickets
description: Local markdown-based ticket management via the tk CLI. Use when managing tasks, tracking dependencies, or working with autonomous development workflows.
---

# Using Tickets (tk CLI)

## Setup

Check if `tk` is available:
```bash
which tk || echo "tk not found"
```

If not installed, get it from: **https://github.com/wedow/ticket**

See that repo's README for installation instructions.

## Before Using

**Always run `tk help` first** to confirm current command syntax and available options.

Tickets are stored as markdown with YAML frontmatter in `.tickets/` directories for ease of search and editing.
