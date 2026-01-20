---
name: reviewing-plans
description: Reviews and refines feature plans for autonomous implementation readiness. Classifies issues as BLOCKING vs NON-BLOCKING, resolves autonomously, and graduates plans when implementable. Outputs READY/NEEDS_WORK status for loop integration. Use after project-planning skill.
---

# Plan Review Skill

## Purpose

Review and refine feature plans produced by the project-planning skill. Ensures plans are:
1. **Consistent** - No contradictions across documents
2. **Simple** - Adheres to PRIME DIRECTIVE (maximal simplicity)
3. **Comprehensive** - Covers all requirements without gaps
4. **Autonomous-ready** - Tasks detailed enough for implementation agents

## Core Principle: Autonomous Resolution First

**Most issues identified in audits can be resolved by gathering more information.** The skill should autonomously research and resolve issues, only escalating to the user when genuine human judgment is required.

**Human time is precious.** Don't ask the user about things that have objectively correct answers discoverable through research.

## When to Use

- After running **project-planning** skill to generate a new plan
- Before starting **autonomous-development** loops
- When plans feel over-engineered or unclear
- To validate assumptions with user before implementation

## Session Model

**One review pass per session.** This skill performs:
1. Audit
2. Resolve (autonomous - multiple waves)
3. Interview (escalated issues only)
4. Update
5. Report

Then the session ends. If the user wants another review pass, they start a **new session** and invoke the skill again.

## Workflow Overview

```
0. SELECT PLAN
   - User confirms which plan to review
   - Read review history from frontmatter (pass count, blocking history)

1. AUDIT (parallel sub-agents)
   - Dispatch auditors for each plan section
   - Classify issues as BLOCKING or NON-BLOCKING
   - Collect findings with blocking counts

2. RESOLVE (parallel sub-agents, multiple waves)
   - Dispatch resolver agent for EACH issue
   - Resolvers research codebase, check files, read library docs
   - Each issue gets: RESOLVED (with fix) or ESCALATE (needs human)
   - Run waves until no more resolvable issues remain

2.5 READINESS ASSESSMENT (coordinator decision)
   - Count remaining BLOCKING issues
   - Check implementability of first 3-5 tasks
   - Apply graduation override if 3+ passes with no persistent blockers
   - Decision: READY (skip to Update) or NEEDS_WORK (continue to Interview)

3. INTERVIEW (only if NEEDS_WORK and has escalations)
   - Present ONLY issues that couldn't be resolved autonomously
   - These are genuinely human decisions (vision, preferences, tradeoffs)

4. UPDATE (parallel sub-agents)
   - Apply all resolutions + human decisions to plan files
   - Update frontmatter (pass count, blocking history)

5. REPORT
   - Output STATUS: READY or NEEDS_WORK
   - If READY: note implementation-time refinements, proceed to tickets
   - If NEEDS_WORK: list blocking issues, run another pass
```

## Main Agent Role (CRITICAL)

**You are a COORDINATOR.** You orchestrate sub-agents and manage workflow.

**Your responsibilities:**
- Help user select which plan to review
- Dispatch audit sub-agents and collect summaries
- Dispatch resolver sub-agents for each issue
- Run resolution waves until issues converge
- Present ONLY escalated issues to user
- Route findings to update agents

**You NEVER:**
- Read plan files directly (delegate to sub-agents)
- Make design decisions without evidence or user input
- Ask the user about issues that have objective answers
- Escalate issues that can be resolved through research

---

## Stage 0: Plan Selection

**Do NOT automatically pick a plan.** Always confirm with user.

### If User Specified a Plan

```
I'll review the [specified] plan at docs/feature-plans/[name]/.

Is that correct, or would you like to review a different plan?
```

### If User Did Not Specify

List available plans:
```bash
ls -la docs/feature-plans/
```

Then present to user and wait for confirmation to select which plan to review with `tk`.

### Read Review History

After plan selection, check the plan's frontmatter for review tracking:

```yaml
---
title: Feature Name
status: draft|reviewing|ready
review_passes: 0
last_review: null
blocking_issues_history: []
---
```

If frontmatter doesn't exist, add it. The `review_passes` count and `blocking_issues_history` inform the readiness assessment later.

---

## Stage 1: Audit

### Setup

Create temp directory:
```bash
ts=$(date +%s)
mkdir -p /tmp/plan-review-$ts/{audit,resolve,research}
```

### Dispatch Auditors

Deploy parallel sub-agents, one per concern area.

**Architecture Auditor:**
```
Review architecture documentation for [feature-name].

Files:
- docs/feature-plans/[feature]/README.md
- docs/feature-plans/[feature]/INDEX.md
- docs/feature-plans/[feature]/ARCHITECTURE.md (if exists)

Audit for:
1. Internal consistency (do docs agree with each other?)
2. Completeness (sufficient context for implementation?)
3. Module structure clarity (where do components live?)

Write findings to: /tmp/plan-review-[ts]/audit/architecture.md

Format each issue as:
---
ISSUE: [short title]
TYPE: [consistency|completeness|clarity|simplicity|api-mismatch|path-error|missing-detail]
BLOCKING: [yes|no] (see classification guide below)
DESCRIPTION: [what's wrong]
AFFECTED: [file paths and line numbers]
---

**BLOCKING Classification Guide:**
An issue is BLOCKING only if an implementation agent cannot proceed without it being fixed:
- YES (blocking): File path doesn't exist, API signature is wrong, task is unactionable/ambiguous, critical contradiction, missing essential dependency
- NO (non-blocking): Wording could be clearer, optional detail missing, style/formatting, enhancement suggestion, redundant explanation

When in doubt, mark as NON-BLOCKING. The coordinator will assess overall readiness.

Return: Summary (2-3 sentences) + file path + issues count
```

**Phase Plan Auditors** (one per phase file):
```
Review phase plan: docs/feature-plans/[feature]/[phase-file].md

Read context documents first:
- the project CLAUDE.md (PRIME DIRECTIVE on maximal simplicity)
- Project CLAUDE.md (if exists)
- docs/VISION.md (if exists)

Audit for:
1. Task clarity (specific enough for autonomous agents?)
2. Verification commands (executable, not vague?)
3. File paths (explicit, not "the auth module"?)
4. Dependencies (clear and correct?)
5. Simplicity violations (over-engineering, premature abstractions?)
6. API accuracy (do signatures match actual code?)

Write findings to: /tmp/plan-review-[ts]/audit/[phase-name].md

Use the issue format specified above (including BLOCKING classification).

Return: Summary + file path + BLOCKING count + total issues count
```

### Collect Audit Results

Wait for all auditors. Parse issue files to create consolidated issue list with unique IDs.

---

## Stage 2: Resolve (Autonomous)

**This is the key innovation.** Most issues can be resolved by gathering facts.

### Issue Classification

**Auto-resolvable (dispatch resolver):**
- Import path mismatches → check go.mod, existing imports
- API signature mismatches → check actual source code
- Path inconsistencies → check filesystem, find correct path
- Duplicate code detection → verify both locations, recommend consolidation
- Missing test patterns → check how similar tests are structured
- Library API questions → read documentation (WebFetch)
- Dependency ordering → trace actual dependencies in code
- Consistency fixes → find authoritative source, align others

**Requires human (escalate immediately):**
- Design tradeoffs with no objective winner
- Scope decisions (include feature X or defer?)
- Architecture preferences between valid approaches
- Simplicity judgments where multiple options are reasonable
- Vision/goals alignment questions
- Priority/ordering preferences
- Novel situations with no existing patterns to follow

### Dispatch Resolvers

For each auto-resolvable issue, dispatch a resolver agent:

```
Resolve issue: [issue title]

Issue details:
- Type: [from audit]
- Description: [from audit]
- Affected files: [from audit]

Your task:
1. Research the codebase to gather facts
2. Check actual file contents, go.mod, existing patterns
3. Read library documentation if needed (use WebFetch)
4. Determine if there's an objectively correct resolution

You MUST return one of:

RESOLVED:
- Recommendation: [what to change]
- Evidence: [what you found that supports this]
- Confidence: [high|medium]

OR

ESCALATE:
- Reason: [why this needs human input]
- Options: [2-3 choices to present to user]
- Tradeoffs: [what each option implies]

OR

NEEDS_RESEARCH:
- Question: [what additional information is needed]
- Where to look: [files, docs, or web resources]

Write findings to: /tmp/plan-review-[ts]/resolve/[issue-id].md
```

### Resolution Waves

Some resolutions may reveal new questions or dependencies. Run in waves:

```
Wave 1: All issues from audit
  - Dispatch resolvers in parallel
  - Collect results
  - Issues marked NEEDS_RESEARCH go to Wave 2

Wave 2: Follow-up research
  - Dispatch research agents for NEEDS_RESEARCH items
  - Re-run resolvers with new information
  - More resolutions or escalations

Wave 3+: (if needed)
  - Continue until no NEEDS_RESEARCH remains
  - All issues are now RESOLVED or ESCALATE

Maximum 3 waves to prevent infinite loops.
```

### Collect Resolution Results

After waves complete:
- **RESOLVED issues**: Queue for Stage 4 (Update)
- **ESCALATE issues**: Queue for Stage 3 (Interview)

---

## Stage 2.5: Readiness Assessment

**This is the graduation gate.** After resolution, the coordinator (not auditors) decides if the plan is ready for implementation.

### Readiness Criteria

A plan is **READY** when an implementation agent could start work immediately:

1. **Zero BLOCKING issues remain** after resolution
2. **Tasks are actionable** - first 3-5 tasks have clear descriptions, file paths, and verification commands
3. **No structural contradictions** - plan sections agree with each other

A plan graduates automatically after **3+ review passes** if:
- No BLOCKING issues persist across passes (check `blocking_issues_history`)
- Remaining issues are non-blocking refinements

### Implementability Quick-Check

The coordinator performs a lightweight check (NOT a full audit):

```
For the first 3-5 implementation tasks, verify:
1. Can I understand what code to write?
2. Are file paths explicit (not "the auth module")?
3. Is the verification command executable?
4. Are dependencies on other tasks clear?

If all yes → plan is implementable
If any no → identify specific BLOCKING issue
```

### Readiness Decision

**If READY:**
- Skip Stage 3 (Interview) entirely
- Proceed to Stage 4 (Update) with resolved issues only
- Report will output `STATUS: READY`
- Remaining non-blocking issues are noted as "implementation-time refinements"

**If NEEDS_WORK:**
- Proceed to Stage 3 (Interview) for any ESCALATE issues
- Continue normal flow
- Report will output `STATUS: NEEDS_WORK`

### Graduation Override

After 3+ passes, if the same "BLOCKING" issues keep reappearing, they're likely miscategorized. The coordinator may:
1. Reclassify persistent issues as NON-BLOCKING
2. Graduate with a note: "Remaining issues are implementation-time refinements"
3. Trust that implementation agents can handle ambiguity

**The goal is implementation, not perfection.**

---

## Stage 3: Interview (Escalated Issues Only)

**Present ONLY issues that couldn't be resolved autonomously.**

### What Gets Escalated

Issues requiring human judgment because:
- Multiple valid approaches with no objective winner
- Tradeoffs that depend on unstated preferences
- Scope/priority decisions
- Vision or architectural alignment questions
- Novel situations not covered by existing patterns

### What Does NOT Get Escalated

- Factual questions (what's the import path? → check go.mod)
- Consistency fixes (two places disagree → pick authoritative source)
- Pattern matching (how do similar things work? → check codebase)
- API verification (what's the actual signature? → read the code)
- Path corrections (where are the files? → check filesystem)

### Present Escalated Issues

```
## Plan Review: [Feature Name]

### Autonomous Resolution Summary

**Total issues found:** [X]
**Resolved autonomously:** [Y]
**Escalated for your input:** [Z]

[If Z is 0: "All issues were resolved autonomously. Proceeding to update phase."]

### Decisions Needed

[For each escalated issue:]

**[Issue Title]**

[Brief description of the issue]

The resolver found:
- [Key facts discovered]
- [Why this couldn't be auto-resolved]

Options:
1. [Option A] - [implications]
2. [Option B] - [implications]
3. [Option C, if applicable]

Which approach do you prefer?
```

### Decision Handling

User can:
1. **Make a definitive choice** - "Use approach A"
2. **Allow flexibility with guidance** - "Either A or B. Prefer A if [condition], otherwise B."
3. **Request more research** - "I need to know X before deciding" → dispatch research agent
4. **Flag for later** - "Create a HUMAN-TASK ticket, block dependent work"

### If No Escalations

If all issues were resolved autonomously, inform the user:

```
All [X] issues from the audit were resolved autonomously through codebase research.

Key resolutions:
- [Summary of major fixes]

Proceeding to update the plan documents. You can review the changes in the commit.
```

---

## Stage 4: Update

Dispatch update sub-agents with:
- Resolved issues (from Stage 2)
- User decisions (from Stage 3, if any)

**Plan Update Sub-Agent Pattern:**
```
Update phase plan: docs/feature-plans/[feature]/[phase].md

Resolutions to apply:
[List of RESOLVED issues with recommendations]

User decisions (if any):
[List of decisions from interview]

Instructions:
1. Read the project CLAUDE.md (PRIME DIRECTIVE)
2. Apply each resolution to the plan
3. Ensure consistency across the document
4. Verify all tasks have:
   - Clear descriptions
   - Explicit file paths
   - Executable verification commands
   - Correct dependencies

Return: Summary of changes made
```

---

## Stage 5: Report

### Update Plan Frontmatter

Before generating the report, update the plan's frontmatter:

```yaml
---
title: Feature Name
status: reviewing  # or 'ready' if graduating
review_passes: N+1  # increment from previous
last_review: YYYY-MM-DD
blocking_issues_history:
  - pass: N+1
    blocking_count: [count from this pass]
    resolved: [how many were resolved]
---
```

### Generate Report

The report format depends on the readiness decision from Stage 2.5:

**If STATUS: READY**
```
## Plan Review Complete: [Feature Name]

STATUS: READY

### Summary
- Review pass: [N]
- Issues found: [X]
- Resolved autonomously: [Y]
- Blocking issues remaining: 0

### Graduation Criteria Met
[Why this plan is ready - e.g., "No blocking issues after 3 passes" or "All tasks are actionable"]

### Implementation-Time Refinements
These non-blocking issues can be addressed during implementation:
- [Minor issue 1]
- [Minor issue 2]

### Next Step
Run `plan-to-tickets` skill to generate implementation tasks.
```

**If STATUS: NEEDS_WORK**
```
## Plan Review Complete: [Feature Name]

STATUS: NEEDS_WORK

### Summary
- Review pass: [N]
- Issues found: [X]
- Resolved autonomously: [Y]
- Blocking issues remaining: [Z]

### Blocking Issues
These must be resolved before implementation:
- [Blocking issue 1]: [why it blocks]
- [Blocking issue 2]: [why it blocks]

### Key Changes Made
- [Resolution 1]
- [Resolution 2]

### Next Step
Run another review pass to address blocking issues.
```

### Commit Changes

```bash
git add docs/feature-plans/[feature-name]/
git commit -m "docs: review [feature-name] plan (pass N)

Status: [READY|NEEDS_WORK]
Blocking issues: [count]

Resolutions:
- [key fixes]"
```

### Cleanup
```bash
rm -rf /tmp/plan-review-[ts]/
```

### Exit Status for Loop Integration

The skill outputs a clear, parseable status line that external scripts can use:

```
PLAN_REVIEW_STATUS: READY|NEEDS_WORK
PLAN_REVIEW_PASS: N
PLAN_REVIEW_BLOCKING: [count]
```

A loop script can check this output:
- `READY` → proceed to `plan-to-tickets`
- `NEEDS_WORK` → run another review pass (up to max iterations)

---

## Key Principles

### 1. The Goal is Implementation, Not Perfection

Plans don't need to be perfect—they need to be implementable. A plan is ready when an agent could start coding, even if polish issues remain.

**Graduation mindset:**
- After 3+ passes with no persistent blockers → graduate
- Non-blocking issues are "implementation-time refinements"
- Trust that implementation agents can handle minor ambiguity
- Endless polishing wastes more time than imperfect-but-clear plans

### 2. Autonomous Resolution is the Default

If an issue can be resolved by gathering information, resolve it autonomously. Don't ask the user.

Examples of autonomous resolution:
- "Import path mismatch" → Check go.mod, use correct path
- "API signature wrong" → Read source file, fix signature
- "Path doesn't exist" → Check filesystem, find correct path
- "Duplicate function" → Verify both exist, recommend consolidation
- "Missing dependency" → Trace imports, add missing dep

### 3. Humans are for Human Things

Only escalate when the issue genuinely requires:
- Preferences (between valid options)
- Vision/goals alignment
- Scope decisions
- Tradeoff judgments
- Context only the human has

### 4. Research Before Escalating

If unsure whether to escalate, do more research first. Can you find the answer in:
- The codebase?
- go.mod / package.json / Cargo.toml?
- Library documentation?
- Existing patterns in similar code?

If yes → resolve autonomously.
If no → escalate.

### 5. Waves Prevent Premature Escalation

An issue that seems like it needs human input might become resolvable after Wave 1 research reveals more context. Run multiple waves before escalating.

### 6. User Controls Iteration (or Loop Does)

This skill does ONE pass per session. Iteration is controlled by:
- User manually starting new sessions, OR
- External loop script checking `PLAN_REVIEW_STATUS` output

The skill outputs clear status for automation:
- `READY` → proceed to `plan-to-tickets`
- `NEEDS_WORK` → run another pass (loop should have max iterations)

---

## Resolution Examples

### Example 1: Import Path Mismatch

**Audit finds:** Plan uses `github.com/myorg/agent-engine` but some files use `github.com/myorg-legacy/agent-engine`

**Resolver actions:**
1. Check go.mod → finds `module github.com/myorg-legacy/agent-engine`
2. Check existing imports in codebase → all use `github.com/myorg-legacy/...`

**Resolution:** RESOLVED - Use `github.com/myorg-legacy/agent-engine`. Evidence: go.mod declares this as module path.

**NOT escalated.** This is a factual question with an objective answer.

### Example 2: Duplicate Resample Function

**Audit finds:** Phase 2 and Phase 5 both define `Resample22kTo16k`

**Resolver actions:**
1. Read both files → confirm logic is identical
2. Check which was written first → Phase 2
3. Check if Phase 5 can import from Phase 2 → yes, no circular dep

**Resolution:** RESOLVED - Keep in pkg/tts only, Phase 5 imports from there. Evidence: Identical implementations, no import cycle.

**NOT escalated.** Clear DRY violation with obvious fix.

### Example 3: Feature Scope Decision

**Audit finds:** Task 9 (golden regeneration) may be premature for MVP

**Resolver actions:**
1. Check if regeneration is used elsewhere → no
2. Check implementation complexity → ~30 lines
3. Check if core validation works without it → yes

**Resolution:** ESCALATE - This is a scope/priority decision.
- Option A: Include (small, useful for iteration)
- Option B: Defer (focus on core validation first)
- Tradeoff: A adds minor complexity, B may require manual golden updates

**ESCALATED.** No objective answer - depends on user's priorities.

### Example 4: Suite Abstraction

**Audit finds:** Phase 5 Suite/Runner pattern may be over-engineered

**Resolver actions:**
1. Check if Suite provides real value → adds indirection, no config loading
2. Check PRIME DIRECTIVE → warns against "abstractions that add indirection without separating concerns"
3. Check alternative → direct test functions work fine

**Resolution:** RESOLVED - Remove Suite abstraction, use direct test functions. Evidence: PRIME DIRECTIVE guidance + no concrete benefit from abstraction.

**NOT escalated.** PRIME DIRECTIVE provides clear guidance.

---

## Troubleshooting

### Too many issues escalating
- Review resolver prompts - are they researching thoroughly?
- Add more research waves before giving up
- Check if issues are actually preference questions or just under-researched

### Resolution takes too long
- Run more resolvers in parallel
- Limit waves to 3 maximum
- Accept that some issues may need escalation

### User disagrees with autonomous resolution
- The resolution was based on evidence - present the evidence
- User can override - their decision gets recorded
- Update resolver heuristics for future sessions

### Circular dependencies in resolution
- Some issues may depend on others
- Resolvers should note dependencies
- Coordinator sequences dependent resolutions

---

## Integration with Other Skills

```
Session 1: project-planning
     ↓
  Generate plan docs
     ↓
Session 2-N: reviewing-plans
     ↓
  Audit → Resolve (autonomous) → Interview (escalations only) → Update
     ↓
Session N+1: plan-to-tickets
     ↓
  Translate finalized plan → tickets
     ↓
Session N+2+: autonomous-development
     ↓
  Execute tasks from tickets
```
