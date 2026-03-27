# Claude Code Skills

A collection of reusable workflow patterns (skills) for Claude Code that enable structured planning and autonomous development.

## Overview

These skills provide structured workflows for:

- **Autonomous Development** - Headless task execution with Research → Implement → Verify cycles
- **Adversarial Review** - Post-completion QA that explores features as a user, writes failing tests, creates fix tickets
- **Project Planning** - Comprehensive feature planning through research and interview cycles
- **Test-Driven Development** - Red-green-refactor workflow for all implementation

## Installation

```bash
git clone https://github.com/wedow/skills.git ~/.claude/skills
cd ~/.claude/skills
./setup.sh
```

This creates:
- `~/CLAUDE.md` - Symlink to PRIME DIRECTIVE (maximal simplicity policy)
- `~/.local/bin/ai` - Autonomous development loop runner

**Also install the ticket system:**
See https://github.com/wedow/ticket for installation instructions.

Ensure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage and Philosophy

The autonomous development loop is inspired by Geoffrey Huntley's [Ralph Wiggum technique](https://ghuntley.com/ralph/) - put an agent in a while loop and let it iterate toward completion. The core insight is **one agent session equals one task**. AI tools are massively effective when focused. Results nosedive as context accumulates and distracts. Tools like [`tk`](https://github.com/wedow/ticket) enable multi-session handoff and coordination - agents create tasks capturing outstanding work and relevant context, then exit. The next agent starts fresh with a clean slate.

### Typical Workflow

Start a fresh Claude Code session for each skill invocation:

1. **`project-vision`** - Capture project philosophy and goals through structured interview
2. **`project-planning`** - Generate comprehensive feature plan (close session after)
3. **`reviewing-plans`** - Refine the plan (run 1-3 times in fresh sessions until ready)
4. **`plan-to-tickets`** - Convert finalized plan into self-contained tickets
5. **`ai`** - Run the autonomous development loop until complete or blocked

The loop automatically invokes `autonomous-development`, `investigate-blocker`, and `adversarial-review` as needed, stopping only when human input is required or all tasks are verified complete.


## Skills Reference

### Core Development Skills

| Skill | Description |
|-------|-------------|
| `autonomous-development` | Picks up tasks from tickets and executes Research → Implement → Verify cycles autonomously |
| `adversarial-review` | Post-completion QA: explores features as a user, writes failing tests for real issues, creates fix tickets |
| `test-driven-development` | Enforces red-green-refactor: write failing test first, then minimal code to pass |

### Planning Skills

| Skill | Description |
|-------|-------------|
| `project-vision` | Captures project philosophy through structured interview |
| `project-planning` | Generates comprehensive feature plans through research and user interviews |
| `reviewing-plans` | Refines plans for implementation readiness, classifies issues as blocking/non-blocking |
| `plan-to-tickets` | Converts finalized plans into self-contained tickets for autonomous execution |

### Investigation & Resolution

| Skill | Description |
|-------|-------------|
| `investigate-blocker` | Deep parallel research to resolve `REQUIRES-INVESTIGATION` tasks |

### Meta Skills

| Skill | Description |
|-------|-------------|
| `create-new-skill` | Guide for creating new skills with proper structure and best practices |

## Typical Workflow

```
1. project-vision     → Capture project goals and philosophy
2. project-planning   → Generate detailed feature plan
3. reviewing-plans    → Refine until implementation-ready
4. plan-to-tickets    → Create tickets for autonomous execution
5. ai                 → Execute tasks, then adversarial review before declaring done
```

### Running Autonomous Development

Single invocation:
```bash
claude -p "Use autonomous-development skill"
```

Continuous loop (runs until all tasks complete or human input needed):
```bash
ai
```

Signal controls while the loop is running:
- **Ctrl+C** — kill the active claude instance and exit immediately
- **Ctrl+\\** — let the current claude instance finish, then exit after the iteration completes

## Ticket System

Skills use `tk` for local task management. Install from: https://github.com/wedow/ticket

**Always run `tk help` first** to confirm command syntax.

Tickets are stored in `.tickets/` as markdown files with YAML frontmatter.

## Skill Structure

Each skill is a directory containing `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description of what it does and when to use it
---

# Skill Content
...
```

Skills follow a coordinator/sub-agent pattern:
- Main agent coordinates workflow and dispatches sub-agents
- Sub-agents perform actual research, implementation, and verification
- Sub-agents should read the project's CLAUDE.md as their first action

## License

MIT
