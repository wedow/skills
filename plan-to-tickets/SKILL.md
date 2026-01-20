---
name: plan-to-tickets
description: Translates finalized feature plans into comprehensive tickets for autonomous development. Use after project-planning and reviewing-plans sessions are complete. Creates self-contained tickets with inlined requirements and verification commands.
---

# Plan to Tickets Skill

## Purpose

Translate a finalized feature plan into comprehensive tickets suitable for autonomous development. This skill is the bridge between planning (iterative, document-focused) and implementation (task-focused, ticket-driven).

## When to Use

- After `project-planning` skill has generated a plan
- After `reviewing-plans` skill sessions have refined the plan to satisfaction
- When ready to begin autonomous implementation
- Plan documents are in `docs/feature-plans/[feature-name]/`

## When NOT to Use

- Plan is still being iterated (use `reviewing-plans` instead)
- Plan hasn't been created yet (use `project-planning` first)
- Tickets already exist for this plan (would create duplicates)

## Key Design Principle: Self-Contained Tickets

**Tickets must be executable without referring back to plan documents.**

This means:
- **INLINE** task descriptions, not "See docs/feature-plans/..."
- **INLINE** verification commands, not "See verification section"
- **INLINE** acceptance criteria, not "See phase plan"
- **COMPLETE** context in each ticket for autonomous agent execution

**Why?** The autonomous-development skill picks up tickets and executes them. Agents shouldn't need to read plan documents - everything they need should be in the ticket itself.

## Workflow Overview

```
0. PLAN SELECTION (user confirms which plan)

1. PLAN PARSING (sub-agent)
   - Read all plan files
   - Extract tasks with metadata
   - Build dependency graph
   - Write parsed structure to temp file

2. TICKET GENERATION (parallel sub-agents)
   - Batch tasks across 1-8 agents based on count
   - Each agent creates tickets for its batch
   - Aggregate mappings after all complete

3. EPIC CREATION (if 5+ tickets)
   - Create epic ticket to track 100% completion
   - Include plan validation instructions in description

4. DEPENDENCY LINKING (sub-agent)
   - Link tickets according to plan dependencies
   - Link ALL tickets as blocking the epic (if created)
   - Verify no cycles

5. VALIDATION (sub-agent)
   - Count match: plan tasks vs tickets created
   - Spot-check ticket content
   - Verify dependency structure
   - Verify epic has all tickets as deps (if applicable)

6. REPORT
   - Summary of tickets created
   - Epic ticket ID (if created)
   - Dependency overview
   - Ready for autonomous-development
```

## Main Agent Role (CRITICAL)

**You are a COORDINATOR.** You dispatch sub-agents and route information.

**Your responsibilities:**
- Help user select which plan to translate
- Dispatch sub-agents with file paths
- Route outputs between stages
- Present final report

**You NEVER:**
- Read plan files directly
- Create tickets directly
- Analyze task content yourself

## Stage 0: Plan Selection

**Always confirm which plan to translate.**

### If User Specified a Plan

```
I'll translate the [specified] plan at docs/feature-plans/[name]/ into tickets.

Is that correct? This will create tickets for autonomous implementation.
```

### If User Did Not Specify

List available plans:
```bash
ls -la docs/feature-plans/
```

Then ask:
```
I found these feature plans:

1. multithreaded-runtime/ (modified 2 hours ago)
2. auth-system/ (modified 3 days ago)

Which plan would you like me to translate into tickets?

Note: Only translate plans that have been reviewed and finalized.
```

**Wait for user confirmation before proceeding.**

## Stage 1: Plan Parsing

**Goal:** Extract all tasks from plan documents into structured format.

**Setup:**
```bash
mkdir -p /tmp/plan-to-tickets-[timestamp]/
```

**Deploy Plan Parser sub-agent:**
```
Parse feature plan for ticket generation.

Input: docs/feature-plans/[feature-name]/

Output: /tmp/plan-to-tickets-[ts]/PARSED_PLAN.md

Instructions:
1. Read the project CLAUDE.md first (understand project conventions)
2. Read all .md files in the plan directory
3. For each task found, extract:
   - Task ID (from plan, e.g., "Phase 2, Task 3")
   - Title
   - Full description (everything needed to implement)
   - File paths to create/modify
   - Dependencies (which other tasks must complete first)
   - Verification commands (copy exactly from plan)
   - Acceptance criteria
   - Any flexibility allowances noted
4. Build dependency graph (which tasks block which)
5. Produce parsed plan with:
   - List of all tasks with extracted fields
   - Dependency adjacency list
   - Total task count
   - Any parsing issues encountered

Return: Summary + file path + task count
```

## Stage 2: Ticket Generation (Parallel)

**Goal:** Create one ticket per task with fully inlined content.

**Parallelization strategy:** Ticket creation is embarrassingly parallel. Each task becomes an independent ticket with no cross-dependencies during creation. Batch tasks across multiple sub-agents for speed.

**Batch sizing:**
- 1-10 tasks: 1 agent (overhead not worth it)
- 11-30 tasks: 3 agents (~10 tasks each)
- 31-60 tasks: 5 agents (~10-12 tasks each)
- 61+ tasks: 8 agents (max parallelism, diminishing returns beyond)

**Deploy Ticket Generator sub-agents (in parallel):**

For each batch, spawn a sub-agent with:
```
Generate tickets from parsed plan (batch [N] of [M]).

Context:
- Parsed plan: /tmp/plan-to-tickets-[ts]/PARSED_PLAN.md
- Feature name: [feature-name]
- Task range: Tasks [start] through [end] (inclusive)

Output: /tmp/plan-to-tickets-[ts]/TICKETS_BATCH_[N].md

Instructions:
1. Read the using-tickets skill (invoke it) to understand tk CLI
2. Read the parsed plan file
3. For EACH task in your assigned range, create a ticket:

   tk create "[Feature]: [Task Title]" \
     --type task \
     --priority [map phase to priority: phase 1 = P1, phase 2 = P2, etc.] \
     --description "$(cat <<'EOF'
   ## Summary
   [Full task description from plan - INLINE, don't reference docs]

   ## Files
   [List of files to create/modify with full paths]

   ## Implementation Notes
   [Any specific guidance, patterns to follow, constraints]

   ## Flexibility
   [If plan noted "A or B acceptable", include that here with heuristics]

   ## Verification
   [Copy verification commands EXACTLY from plan]

   ## Acceptance Criteria
   [Copy acceptance criteria EXACTLY from plan]
   EOF
   )"

4. Track each created ticket ID alongside its plan task ID
5. Write mapping to YOUR batch output file:
   - Plan Task ID → Ticket ID
   - Full ticket creation log
   - Any errors encountered

CRITICAL: Ticket descriptions must be SELF-CONTAINED. An agent reading only
the ticket should have everything needed to implement and verify the task.

Return: Summary + file path + tickets created count
```

**Aggregate batch outputs:**

After ALL parallel agents complete, aggregate the mappings:
```bash
cat /tmp/plan-to-tickets-[ts]/TICKETS_BATCH_*.md > /tmp/plan-to-tickets-[ts]/TICKETS_CREATED.md
```

Verify total count matches expected task count from Stage 1. If any batch failed, report errors before proceeding.

### Ticket Content Checklist

Every ticket description MUST include:
- [ ] What to implement (full description, not a reference)
- [ ] Where to implement (specific file paths)
- [ ] How to verify (executable commands)
- [ ] When it's done (acceptance criteria)
- [ ] Any allowed flexibility (with selection heuristics)

## Stage 3: Epic Creation (Conditional)

**Goal:** Create an epic ticket to track 100% completion when there are 5+ tickets.

**Threshold:** 5 or more tickets → create epic. Fewer than 5 → skip this stage.

**Why an epic?** Large plans need a final validation step. The epic ensures:
- All work is tracked to completion
- Implementation is verified against the original plan
- Any gaps discovered during implementation get tracked

**Create the epic:**
```bash
tk create "EPIC: [Feature Name] - Complete Implementation" \
  --type epic \
  --priority 2 \
  --description "$(cat <<'EOF'
## Purpose

This epic tracks 100% completion of the [feature-name] implementation.

**Do not close this ticket until ALL dependent tickets are complete AND validation passes.**

## Plan Reference

Plan location: docs/feature-plans/[feature-name]/

## Validation Instructions (REQUIRED before closing)

When all dependent tickets are complete, perform this validation:

### 1. Plan Coverage Check

Read the original plan and verify each planned task was implemented:

```bash
# List all tasks from plan
cat docs/feature-plans/[feature-name]/*.md | grep -E "^###? (Task|Step)"
# Compare against completed tickets
tk ls --status=closed | grep "[Feature]"
```

For each planned task, verify:
- [ ] A ticket exists that covers this task
- [ ] The ticket is marked DONE
- [ ] Implementation matches plan intent (or deviation is justified)

### 2. Verification Commands

Run ALL verification commands from the plan:

```bash
# Run test suite
[test commands from plan]

# Run any integration checks
[integration commands from plan]
```

All verification commands must pass.

### 3. Gap Analysis

If gaps are found:
1. Create new ticket(s) for missing work
2. Add them as dependencies to this epic: `tk dep [epic-id] [new-ticket-id]`
3. Do NOT close this epic until new tickets are also complete

### 4. Deviation Documentation

If implementation deviated from plan, document in this ticket:
- What changed and why
- Whether the plan should be updated for reference

## Acceptance Criteria

- [ ] All dependent tickets are DONE
- [ ] Plan coverage check: 100% of planned tasks implemented
- [ ] All verification commands pass
- [ ] No gaps remain (or new tickets created and completed)
- [ ] Deviations documented if any
EOF
)"
```

**Record epic ID:** Write to `/tmp/plan-to-tickets-[ts]/EPIC.md`:
```
Epic ID: [ticket-id]
Feature: [feature-name]
Plan location: docs/feature-plans/[feature-name]/
Dependent tickets: [count]
```

## Stage 4: Dependency Linking

**Goal:** Connect tickets according to plan's dependency structure, and link all tickets to the epic (if created).

**Deploy Dependency Linker sub-agent:**
```
Link ticket dependencies.

Context:
- Parsed plan: /tmp/plan-to-tickets-[ts]/PARSED_PLAN.md (has dependency graph)
- Ticket mapping: /tmp/plan-to-tickets-[ts]/TICKETS_CREATED.md (has task→ticket IDs)
- Epic (if exists): /tmp/plan-to-tickets-[ts]/EPIC.md (has epic ID)

Output: /tmp/plan-to-tickets-[ts]/DEPS_LINKED.md

Instructions:
1. Read parsed plan for dependency graph
2. Read ticket mapping for task→ticket ID translation
3. Check if EPIC.md exists (epic was created)

4. For each dependency in plan:
   - Translate: "Task A depends on Task B" → ticket IDs
   - Run: tk dep [ticket-A-id] [ticket-B-id]

5. If epic exists, link ALL tickets as blocking the epic:
   - Read epic ID from EPIC.md
   - For EACH ticket in the mapping:
     - Run: tk dep [epic-id] [ticket-id]
   - This ensures epic cannot be closed until all tickets are done

6. After all links created, verify no cycles:
   - Run: tk dep cycles
   - If cycles found, report which tickets involved

7. Produce linking report with:
   - Task-to-task dependencies created (count)
   - Epic dependencies created (count, if applicable)
   - Full link log
   - Cycle check result
   - Any errors

Return: Summary + file path + deps linked count + epic deps count + cycle status
```

## Stage 5: Validation

**Goal:** Verify tickets accurately represent the plan.

**Deploy Validator sub-agent:**
```
Validate tickets match plan.

Context:
- Parsed plan: /tmp/plan-to-tickets-[ts]/PARSED_PLAN.md
- Ticket mapping: /tmp/plan-to-tickets-[ts]/TICKETS_CREATED.md
- Dependency report: /tmp/plan-to-tickets-[ts]/DEPS_LINKED.md
- Epic (if exists): /tmp/plan-to-tickets-[ts]/EPIC.md

Output: /tmp/plan-to-tickets-[ts]/VALIDATION.md

Instructions:
1. Count validation:
   - Tasks in plan: [count from parsed plan]
   - Tickets created: [count from ticket mapping]
   - Match? [yes/no]

2. Content spot-check (5-10 tickets):
   - Run: tk show [ticket-id]
   - Verify description is SELF-CONTAINED (no doc references)
   - Verify verification commands are present and executable
   - Verify acceptance criteria are present

3. Dependency validation:
   - Run: tk dep tree [root-ticket-id] for each phase
   - Verify structure matches plan
   - Confirm no cycles (from linking report)

4. Epic validation (if EPIC.md exists):
   - Run: tk show [epic-id]
   - Verify epic has validation instructions in description
   - Run: tk dep tree [epic-id] to list dependencies
   - Verify ALL tickets from mapping appear as epic deps
   - Count: epic deps should equal ticket count
   - Flag any missing dependencies

5. Ready-work check:
   - Run: tk ready
   - Verify phase 1 tasks (no deps) appear as ready
   - Epic should NOT appear as ready (blocked by all tickets)

6. Produce validation report with:
   - Count match result
   - Spot-check results (pass/fail per ticket)
   - Dependency structure validation
   - Epic validation result (if applicable)
   - Ready work count
   - Recommendation: VALID or NEEDS_FIXES
   - If NEEDS_FIXES: specific issues to address

Return: Summary + file path + status + epic validation status
```

**Gate Logic:**
- NEEDS_FIXES → Report issues, ask user how to proceed
- VALID → Continue to Stage 6

## Stage 6: Report & Cleanup

**Summarize to user:**
```
## Tickets Generated: [Feature Name]

### Summary
- Tasks in plan: [count]
- Tickets created: [count]
- Dependencies linked: [count]
- Epic ticket: [epic-id] (if created, else "N/A - small plan")
- Ready to start: [count] (phase 1 tasks)

### Tickets Created
[List ticket IDs with titles, grouped by phase/priority]

### Epic Ticket (if created)
Epic ID: [epic-id]
Purpose: Tracks 100% completion and validates implementation against plan

The epic:
- Is blocked by ALL [count] tickets
- Cannot be closed until all work is done
- Contains validation instructions to verify plan coverage
- Will track any gap tickets discovered during implementation

### Dependency Structure
[High-level overview: Phase 1 → Phase 2 → Phase 3 → ... → Epic]

### Ready Work
Run `tk ready` to see tasks available for immediate work.

### Closing the Epic

When all tickets are done, close the epic by following its validation instructions:
1. Verify all planned tasks were implemented
2. Run all verification commands from the plan
3. Document any deviations
4. Create gap tickets if needed (they auto-block the epic)
5. Only close when validation passes

### Next Steps
Start autonomous development:
```bash
claude -p "Use autonomous-development skill"
```

Or run the autonomous loop:
```bash
while true; do
  claude -p "Use autonomous-development skill" || break
  sleep 2
done
```
```

### Commit Tickets

**Commit the ticket database changes:**
```bash
git add .tickets/
git commit -m "chore: generate tickets for [feature-name]

- [X] tickets created from finalized plan
- [Y] dependencies linked
- Epic: [epic-id] (if created, else omit this line)
- Ready for autonomous-development"
```

**Cleanup:**
```bash
rm -rf /tmp/plan-to-tickets-[ts]/
```

## Priority Mapping

Default mapping from plan phases to ticket priorities:

| Plan Phase | Ticket Priority | Rationale |
|------------|-----------------|-----------|
| Phase 1 (Foundation) | P1 | Must complete first |
| Phase 2 | P2 | After foundation |
| Phase 3 | P2 | Same priority, deps control order |
| Phase 4+ | P2-P3 | Later phases |
| HUMAN-TASK | P0 | Blocks other work |

Override based on plan's explicit priority markings if present.

## Handling Special Cases

### HUMAN-TASK Items

If plan contains tasks marked "HUMAN-TASK:":
```bash
tk create "HUMAN-TASK: [description]" \
  --type task \
  --priority 0 \
  --description "[Full context for human decision]"
```

These will block dependent work until resolved.

### Large Tasks

If a plan task spans multiple concerns or seems insufficiently decomposed:
- Flag in validation report
- Suggest user run another `reviewing-plans` pass to break it down
- Or proceed and let `autonomous-development` create sub-tickets during implementation

### Missing Verification Commands

If a task lacks verification commands:
- Flag in validation report
- Ask user: proceed anyway, or fix plan first?

## Key Principles

### 1. One-Way Translation

This skill creates tickets FROM plans. It does not update plans or sync back. Plans are the source of truth during planning; tickets are the frozen snapshot for execution.

### 2. Self-Contained Tickets

Every ticket must be implementable without reading plan documents. Inline everything.

### 3. Preserve Dependency Structure

The dependency graph in tickets must match the plan. `tk ready` should return exactly the tasks that have no blockers.

### 4. Idempotency Warning

Running this skill twice on the same plan will create DUPLICATE tickets. Check `tk ls` before running if unsure.

### 5. Validation Before Execution

Always validate tickets match plans before starting autonomous development. Catch errors early.

### 6. Epic Tickets for Large Plans

Plans with 5+ tickets get an epic ticket that:
- Tracks 100% completion of all work
- Is blocked by ALL individual tickets
- Contains instructions to validate implementation against the plan
- Serves as the final gate before work is considered complete

When closing the epic:
- Verify every planned task was implemented
- Run all verification commands
- If gaps are found, create new tickets and add them as epic deps
- Document any justified deviations from the plan

## Integration with Other Skills

```
project-planning
     ↓
  Creates plan docs
     ↓
reviewing-plans (1-N sessions)
     ↓
  Refines plan docs
     ↓
plan-to-tickets (THIS SKILL)
     ↓
  Creates tickets + epic (if 5+ tickets)
     ↓
autonomous-development (loop)
     ↓
  Executes tickets until all done
     ↓
epic validation (if epic exists)
     ↓
  Validate against plan, create gap tickets if needed
     ↓
  Close epic when 100% validated
```

## Troubleshooting

### Count mismatch (plan tasks ≠ tickets)
- Parser may have missed tasks → Check parsed plan file
- Some tasks may have failed to create → Check ticket creation log
- Duplicate tasks in plan → Review plan for redundancy

### Tickets reference documents instead of inlining
- Generator didn't follow instructions → Re-run with explicit reminder
- Plan was too vague → Run reviewing-plans to add detail

### Cycles detected in dependencies
- Plan has circular dependencies → Fix plan first
- Linking error → Check task→ticket ID mapping

### tk commands fail
- Database not initialized → Run `tk init` first
- Wrong directory → Check working directory

### Epic missing dependencies
- Linking failed → Check DEPS_LINKED.md for errors
- Some tickets not linked → Re-run dependency linking for epic

### Gap tickets after implementation
- Expected behavior → Create gap tickets and add as epic deps
- Run: `tk dep [epic-id] [new-ticket-id]` for each gap
- Epic blocks until all gaps resolved
