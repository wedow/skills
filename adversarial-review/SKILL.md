---
name: adversarial-review
description: Reviews completed work by exploring features as a user would, finding gaps between intent and implementation, writing failing tests for real issues, and creating tickets for genuine problems. Runs automatically after all planned tasks complete.
---

# Adversarial Review

Review completed work by acting as an adversarial QA engineer. Explore features like a real user, find gaps between stated intent and actual implementation, write failing tests for genuine issues, and create tickets to drive fixes.

## Operating Mode

**Designed for headless operation via the auto-dev loop script.**

The loop invokes this skill after all planned tasks reach DONE status. You don't choose when to run — the loop calls you.

```bash
claude --dangerously-skip-permissions --model=opus -p "Use adversarial-review skill"
```

**You are adversarial.** Your job is to find real problems. You succeed when you find genuine failing test scenarios. You fail when you wave things through that a human would immediately notice are broken.

**You are not a nitpicker.** You fail equally when you generate noise — filing tickets for theoretical edge cases, style preferences, or problems no user would encounter. Every ticket you create must pass the rubric: **"Would a reasonable user encounter this within their first day of using the feature?"**

---

## Core Principle

**You (the coordinator) ONLY:**
- Run `tk` commands
- Read plans, tickets, and vision docs
- Dispatch subagents for exploration, code review, and test writing
- Create tickets for genuine findings
- Print session summary and EXIT

**Subagents do ALL the actual work.**

Always run `tk help` first to confirm current command syntax.

---

## Workflow

### Phase 1: Gather Context

**Dispatch a context-gathering subagent to:**

1. Read the project CLAUDE.md (first action — always)
2. Read any plan/vision documents referenced in tickets
3. Run `tk list` and `tk show <id>` for all recently completed tickets
4. Run `git log --oneline -20` and `git diff main...HEAD` (or appropriate base branch) to see the aggregate changes
5. Synthesize the **intent**: what was the user trying to achieve across all this work? Not what individual tickets said — what's the *goal*?

**Subagent reports back:**
```
INTENT: [1-3 sentence summary of what the user wanted to achieve]
SCOPE: [which files/modules were touched]
TICKETS_REVIEWED: [list of ticket IDs]
PLAN_DOCS: [any plan files found]
KEY_BEHAVIORS: [what the implementation should do, derived from tickets + plans]
```

---

### Phase 2: Exploratory QA

**This is the most important phase.** Dispatch a QA subagent that acts like a human user encountering the feature for the first time.

The subagent must first figure out *how* to test, then actually test. If the project lacks the tooling to replicate what a human would do, the agent's job is to build that tooling before proceeding.

**Subagent prompt must include:**

```
IMPORTANT: Before starting work:
1. Read ~/CLAUDE.md (prime directive and best practices)
2. Read [PROJECT]/CLAUDE.md (if applicable)
3. Only then proceed with the task

You are a QA engineer testing a feature for the first time. Your goal is to
USE the feature like a real user would, not just read the code.

INTENT: [from Phase 1]
KEY_BEHAVIORS: [from Phase 1]
SCOPE: [from Phase 1]

Your job:

1. Figure out how a human actually uses this feature
   - Read docs, READMEs, help text
   - Look at how tests invoke the code
   - Find entry points (CLI commands, API endpoints, UI pages)
   - Ask: "If I were a user, what would I physically DO?" (click, type,
     run a command, send a request, open a file, etc.)

2. Figure out how to replicate that interaction programmatically
   - BEFORE testing, assess: do I have the tools to accurately replicate
     what a human would do?
   - If YES: proceed to step 3
   - If NO: build or install what you need FIRST. Examples:

     Web app → install/configure Playwright or use the browser tool
     Game → set up screenshot capture + input simulation (xdotool,
       pyautogui, or engine-specific test harness)
     CLI tool → straightforward, just run commands
     API → use curl/httpie or write a small test client
     Desktop app → find or build automation (accessibility APIs,
       window management tools)
     Data pipeline → set up state inspection (DB queries, file diffs,
       log tailing)
     Anything else → get creative. The requirement is: your test
       steps must be REPEATABLE by another agent without human
       intervention.

   - Whatever tooling you build, keep it minimal and commit it.
     Future review passes and fix agents will use it.
   - If you truly cannot replicate the interaction (e.g., requires
     physical hardware), document what a human would need to do and
     flag it — don't pretend you tested something you couldn't.

3. Try the happy path first
   - Does the basic intended workflow work end to end?
   - Does the output/behavior match what the tickets described?

4. Try obvious variations
   - What would a user naturally try next?
   - What inputs would a user reasonably provide?
   - NOT exotic edge cases — normal usage patterns

5. Try the seams between tickets
   - Individual tickets may be correct in isolation
   - Do they compose properly? Does workflow A → B → C work?

6. Check error cases a user would hit
   - Missing required input
   - Obvious invalid input (empty string, wrong type)
   - NOT adversarial fuzzing — just things users do by accident

For each issue found, document:
- WHAT: What you did and what went wrong
- EXPECTED: What should have happened (based on intent/tickets)
- ACTUAL: What actually happened
- SEVERITY: BLOCKING (breaks stated intent) or SIGNIFICANT (normal usage fails)
- REPRODUCIBLE: Exact steps to reproduce — these MUST be executable commands
  or scripts, not prose descriptions. Another agent will use these steps to
  verify the fix. If you can't express it as repeatable commands, the finding
  isn't actionable.

Discard anything that doesn't meet the severity threshold.
Do NOT report style preferences, theoretical concerns, or exotic edge cases.

Use available tools: run commands, use the browser for web apps, invoke CLIs,
read output files — whatever a human QA would do. Build new tools if needed.
```

---

### Phase 3: Code Review

**Dispatch a code review subagent.** This runs in parallel with or after Phase 2.

**Subagent prompt must include:**

```
IMPORTANT: Before starting work:
1. Read ~/CLAUDE.md (prime directive and best practices)
2. Read [PROJECT]/CLAUDE.md (if applicable)
3. Only then proceed with the task

You are reviewing code changes for a completed feature.

INTENT: [from Phase 1]
SCOPE: [from Phase 1]
TICKETS_REVIEWED: [from Phase 1]

Review the diff (git diff main...HEAD or equivalent) for:

1. INTENT MATCH
   - Does the code actually implement what the tickets describe?
   - Are there tickets whose requirements are only partially fulfilled?
   - Are there stated behaviors that aren't implemented at all?

2. PRIME DIRECTIVE COMPLIANCE
   - Are concerns separated or complected?
   - Is this the simplest implementation that achieves the goal?
   - Are there unnecessary abstractions or over-engineering?
   - Is there duplication that should be consolidated?

3. COMPOSITION ISSUES
   - Do the changes from different tickets work together?
   - Are there contradictions between how different tickets were implemented?
   - Are there shared assumptions that aren't enforced?

4. OBVIOUS ROBUSTNESS GAPS
   - Error handling for common (not exotic) failure modes
   - Missing validation at system boundaries (user input, external APIs)
   - NOT internal defensive coding — trust framework guarantees

For each issue found, document:
- WHAT: The specific code and the problem
- WHY: Why this is a real issue (reference intent/tickets)
- SEVERITY: BLOCKING or SIGNIFICANT
- FILE: Path and line range

Do NOT report: style nits, naming preferences, missing comments,
theoretical edge cases, or issues that require exotic conditions to trigger.
```

---

### Phase 4: Encode Findings

For each BLOCKING or SIGNIFICANT issue from Phases 2 and 3, dispatch a test-writing subagent.

**Not every finding needs a test.** Some findings are:
- Missing documentation → ticket, no test
- Misleading error message → ticket, maybe a test
- Feature doesn't work → test that demonstrates the failure

**Subagent prompt for test writing:**

```
IMPORTANT: Before starting work:
1. Read ~/CLAUDE.md (prime directive and best practices)
2. Read [PROJECT]/CLAUDE.md (if applicable)
3. Only then proceed with the task

Write a failing test that demonstrates this issue:

ISSUE: [description from Phase 2 or 3]
EXPECTED_BEHAVIOR: [what should happen]
ACTUAL_BEHAVIOR: [what does happen]
RELEVANT_CODE: [file paths and line ranges]
REPRODUCTION_STEPS: [exact commands from Phase 2 finding]
QA_TOOLING: [any test infrastructure built during Phase 2]

Requirements:
- Use the project's existing test framework and conventions
- If Phase 2 built test infrastructure (Playwright setup, input simulation,
  screenshot tooling, etc.), USE it — don't reinvent it
- The test MUST currently fail (it encodes a real bug)
- The test should pass once the issue is fixed
- The test MUST be runnable by another agent without human intervention —
  this is non-negotiable. If the fix agent can't run the test, the ticket
  is worthless.
- Place the test where the project's conventions dictate
- Keep it minimal — test the specific issue, not everything around it
- Commit the test file(s) with a clear message like:
  "test: failing test for [brief issue description]"

If you cannot write a meaningful test for this issue (e.g., it's a docs gap
or UX issue), report back that no test is applicable and explain why.
```

---

### Phase 5: Triage and Ticket

After all subagents report back, the coordinator:

1. **Deduplicate** findings across phases (exploratory QA and code review may find the same issue)

2. **Apply the rubric** one more time: for each finding, ask "Would a reasonable user encounter this within their first day?" If no, discard it.

3. **Create tickets** for genuine issues. Each ticket MUST include enough detail for a fix agent to understand, reproduce, and verify the fix without asking questions:
   ```bash
   tk create "Fix: [clear description of the issue]" \
     --priority [p0 for BLOCKING, p1 for SIGNIFICANT] \
     --description "## Problem
   [What's wrong — expected vs actual behavior]

   ## Reproduction
   [Exact commands to reproduce — must be copy-pasteable]

   ## Failing Test
   [Path to the committed failing test, or 'N/A — see verification command']

   ## Verification
   [Command to run that currently fails and should pass after the fix]

   ## Relevant Files
   [Paths and line ranges]"
   ```

4. **Do NOT create tickets for:**
   - Style or naming preferences
   - Theoretical edge cases
   - Performance concerns without measurement
   - "Nice to have" improvements
   - Anything the user didn't ask for and wouldn't notice

---

## Session Summary

Print a clear summary at the end:

```
## Adversarial Review Complete

### Intent Reviewed
[1-3 sentence summary of what was being verified]

### Findings
- BLOCKING: [count]
- SIGNIFICANT: [count]
- Discarded (noise): [count]

### Tests Written
- [test file]: [what it tests] — FAILING (encodes bug)
- ...

### Tickets Created
- [ticket-id]: [title] (priority)
- ...

### Verdict
[ONE OF:]
- CLEAN: No issues found. Implementation matches intent.
- ISSUES_FOUND: [N] tickets created for genuine problems.
- CRITICAL: Multiple blocking issues — implementation does not fulfill stated intent.

EXIT_STATUS: REVIEW_CLEAN | REVIEW_ISSUES_FOUND
```

The auto-dev loop reads `EXIT_STATUS` to decide whether to continue fixing or exit.

---

## What This Skill Is NOT

- **Not a linter.** Don't report what automated tools catch.
- **Not a style reviewer.** Don't have opinions about naming or formatting.
- **Not a security audit.** Don't look for OWASP issues unless the feature is security-related.
- **Not an edge case generator.** Don't invent scenarios that require 5 preconditions to trigger.
- **Not a perfectionist.** "Good enough for users" is the bar, not "theoretically optimal."

This skill exists because autonomous agents complete tickets without checking whether the *aggregate work actually achieves the user's goal*. Your job is to be the human who tries the feature and says "this doesn't work" — and to be specific enough about *why* that another agent can fix it.
