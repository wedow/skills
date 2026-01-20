# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a collection of Claude Code skills - reusable workflow patterns that extend agent capabilities. Skills are invoked automatically by Claude based on task context.

## Ticketing System

Skills use `tk` for local task management. Install from: **https://github.com/wedow/ticket**

**Always run `tk help` before ticket operations** to confirm current command syntax.

See `using-tickets/SKILL.md` for quick reference.

## Skill Structure

Each skill is a directory containing `SKILL.md` with YAML frontmatter:
```yaml
---
name: skill-name
description: One-line description shown in skill list
---
```

The body contains the skill's workflow instructions.

## Key Skills

| Skill | Purpose |
|-------|---------|
| `autonomous-development` | Headless task execution via Research → Implement → Verify cycles |
| `test-driven-development` | Red-green-refactor cycle for all implementation work |
| `feedback-driven-development` | Designing verification mechanisms beyond unit tests |
| `project-planning` | Comprehensive feature planning through research-interview cycles |
| `reviewing-plans` | Refining plans for autonomous implementation readiness |
| `plan-to-tickets` | Converting finalized plans to self-contained tickets |
| `investigate-blocker` | Deep research to resolve REQUIRES-INVESTIGATION tasks |
| `project-vision` | Capturing project philosophy through structured interview |
| `using-tickets` | Local ticket management via tk CLI |

## Autonomous Development Loop

The external bash loop at `autonomous-development/scripts/autonomous-dev-loop.sh` (symlinked to `~/.local/bin/ai`) coordinates skills:

1. Check for `REQUIRES-INVESTIGATION:` tasks → run `investigate-blocker`
2. Check for regular tasks → run `autonomous-development`
3. If only `HUMAN-TASK:` remains → stop for human input
4. If no tasks → stop

## Skill Authoring

When creating or modifying skills:

- Skills should be self-contained workflow documents
- Reference `tk` commands for task management
- Follow the coordinator/sub-agent pattern (main agent dispatches, sub-agents do work)
- Include verification commands that are executable without human involvement
- Sub-agents must read the project's `CLAUDE.md` as their first action

## Setup

Run `./setup.sh` to create symlinks:
- `~/CLAUDE.md` → `CLAUDE.md.global` (PRIME DIRECTIVE)
- `~/.local/bin/ai` → `autonomous-development/scripts/autonomous-dev-loop.sh`

Install `tk` separately from https://github.com/wedow/ticket
