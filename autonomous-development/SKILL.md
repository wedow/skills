---
name: autonomous-development
description: Autonomously discovers ready tasks from Tickets, executes them with Research → Implement → Verify cycles, continuing with related work while context remains healthy - invoke directly without specifying a task
---

# Autonomous Development Workflow

Execute development tasks autonomously using a three-stage subagent cycle: Research → Implement → Verify. Continue with related tasks when context is healthy; exit when context is strained or only complex unrelated work remains.

## Operating Mode

**Designed for headless operation with `-p` flag:**

```bash
# Single task execution
claude -p "Use autonomous-development skill"

# Infinite loop (external bash script)
while true; do
  claude -p "Use autonomous-development skill" || break
  sleep 2
done
```

**AUTONOMOUS TASK EXECUTION:**

You execute tasks autonomously, continuing through multiple tasks when conditions are favorable:

1. **IMMEDIATELY:** Run `tk ready` to get the list of ready tasks
2. **SELECT:** Choose a task based on priority AND relatedness to recent work
3. **DO NOT WAIT:** Do not ask the user which task to work on
4. **DO NOT ASK FOR CLARIFICATION:** Use the task as written
5. **Execute:** Research → Implement → Verify cycle
6. **Assess:** After each task, evaluate whether to continue (see Continuation Assessment)
7. **Print:** Session summary with clear exit status when done
8. **EXIT:** When context is strained, only complex tasks remain, or any blocker occurs

**HEADLESS MODE PRINCIPLES:**
- You run without user interaction
- You have full autonomy to run `tk ready` and select tasks
- Asking "what task would you like?" is a failure mode
- The script that calls you expects you to self-direct
- If no ready tasks exist, enter Maintenance Mode (see below) to discover and create new work

**MULTI-TASK SESSION CAPABILITY:**
- After completing a task, you MAY continue with another if conditions are favorable
- Bias toward related tasks (same code area, follow-up work) over strict priority ordering
- Trust your self-awareness of context health - if you're struggling to recall earlier details, exit
- The baseline health check runs ONCE per session, not per task
- Research can be abbreviated for tasks related to work just completed

**The external loop handles:**
- Re-invocation after session exit
- Monitoring session summaries for exit status
- Detecting when human input is needed
- Continuing until all tasks complete

---

## Core Principle

**IMPORTANT:** Always run `tk help` first to confirm current command syntax.

**You (the coordinator) ONLY:**
- Run `tk` commands (ready, show, create, status, dep, etc.)
- Create and update TodoWrite todos
- Dispatch Task tool subagents
- Create new tickets when needed
- Print session summary and EXIT

**You (the coordinator) NEVER:**
- Read files directly
- Write files directly
- Run bash commands (except Tickets)
- Make git commits
- Ask user for input (headless mode)

**Subagents do ALL the actual work.**

---

## When to Use This Skill

**MANDATORY to use when:**
- Running with `-p` flag (headless mode) ← This is you right now if you're reading this
- Any call like `claude -p "Use autonomous-development skill"`
- External bash loop calling you for autonomous work

**YOU MUST NOT ASK CLARIFYING QUESTIONS IN HEADLESS MODE:**
- The `-p` flag means run autonomously
- You have permission to self-direct and pick a task
- Asking "what should I work on?" defeats the purpose
- Your job is to be self-directed

**NEVER use when:**
- User asks a specific question (answer directly without using skill)
- User wants to review a plan first (use main agent for planning)
- Interactive session where user is asking for advice
- User explicitly wants to stay interactive

---

## Health Check (MANDATORY BEFORE TASK SELECTION)

**Goal:** Record baseline system state and verify project is stable enough to proceed.

**CRITICAL:** This runs ONCE per invocation, BEFORE selecting any task.

### Step 0: Git State Recovery (Detached HEAD Detection)

**Before anything else, check git state:**

```bash
git symbolic-ref HEAD 2>/dev/null || echo "DETACHED"
```

**If DETACHED HEAD detected:**

This often happens when agents checkout specific commits for debugging and forget to return to the branch. The work may be orphaned.

**Dispatch git recovery subagent:**

```
You are investigating a detached HEAD state in this repository.

Working directory: [path]

**FIRST ACTION:** Read the project CLAUDE.md to understand the PRIME DIRECTIVE.

**INVESTIGATION STEPS:**

1. Run `git status` to confirm detached HEAD state and see current commit
2. Run `git log --oneline -5` to see recent commits from HEAD
3. Run `git reflog -20` to understand how we got here
4. Look for patterns like:
   - `checkout: moving from [branch] to [sha]` - agent checked out a commit
   - `commit:` entries after the checkout - work was done in detached state
   - The branch name that was active before the detachment

5. Identify:
   - What branch we were on before detachment
   - Whether any commits were made in detached state
   - Whether those commits exist on any branch

6. Run `git branch -a --contains HEAD` to see if current commit is on any branch
7. Run `git log --oneline [original-branch]..HEAD 2>/dev/null` to see commits not on that branch

**RECOVERY ACTIONS:**

Based on findings, execute ONE of these:

**Case A: No commits made in detached state**
- Just checkout the original branch: `git checkout [branch]`

**Case B: Commits made in detached state, not on any branch**
- Save the detached commit(s): `git branch recovery-[short-sha] HEAD`
- Checkout the original branch: `git checkout [branch]`
- Merge the recovery branch: `git merge recovery-[short-sha] --no-edit`
- If merge succeeds, delete recovery branch: `git branch -d recovery-[short-sha]`
- If merge conflicts: leave recovery branch, report conflict

**Case C: HEAD is already on a branch (false positive)**
- Nothing to do, report that we're on [branch]

**REPORT FORMAT:**

```
GIT_STATE_BEFORE: [detached at sha | on branch X]
DETACHMENT_CAUSE: [what reflog showed - e.g., "checkout from master to abc123"]
COMMITS_IN_DETACHED: [count, with short descriptions]
RECOVERY_ACTION: [what was done]
GIT_STATE_AFTER: [on branch X]
MERGE_RESULT: [clean | conflicts | not needed]
```

If merge conflicts occur, report the conflicting files and EXIT - human intervention needed.
```

**If recovery fails or conflicts exist:**
- Create HUMAN-TASK for manual git recovery
- EXIT with `STATUS: ERROR`

**If recovery succeeds or no recovery needed:**
- Continue to baseline health check below

---

**Dispatch baseline subagent to:**
- Read repository CLAUDE.md (first action)
- Run project build/compile command and record ALL warnings/errors
- Run project test suite and record ALL passing/failing tests
- Document specific failure messages for any test failures or build errors

**Baseline output format required:**
```
BASELINE_BUILD: [pass|fail]
BASELINE_BUILD_WARNINGS: [count]
BASELINE_BUILD_ERRORS: [count]
BASELINE_TESTS_PASSING: [count]
BASELINE_TESTS_FAILING: [count]
BASELINE_FAILURES: [list any test names or error messages]
```

**Store baseline in session context** for later comparison during verification.

**If baseline is broken (tests failing, build errors):**
1. Run `tk ready` and `tk blocked` to check what's already tracked
2. Verify each baseline failure is represented in existing Tickets tasks:
   - If all failures ARE tracked: Pick the highest-priority Tickets task from the normal list and proceed with three-stage cycle
   - If failures are NOT tracked:
     - Dispatch investigation subagent to understand each failure and create appropriate Tickets tasks
     - Once new tasks created, EXIT with `STATUS: COMPLETED`
     - External loop will re-invoke to work on the new priority tasks

**If baseline is healthy:** Continue to task selection.

---

## The Three-Stage Cycle

### Stage 1: RESEARCH
**Goal:** Understand requirements, existing code, and implementation approach

**Dispatch subagent(s) to:**
- Read repository CLAUDE.md (MANDATORY FIRST ACTION)
- Find and analyze the Tickets task definition
- Explore existing code patterns
- Identify vulnerable/affected code
- Research related documentation
- Check for reference implementations
- Understand test patterns

**Research complexity assessment:**
- **Simple task** (clear approach, bounded scope): Single research subagent
- **Medium task** (some exploration needed, multiple files): 1-2 concurrent research subagents
- **Complex task** (unclear approach, feels like a rabbit hole): Consider breaking down into subtasks

Use judgment, not metrics. The question is: "Can I hold the full solution in my head?" not "How many lines will this be?"

**If task too complex after research:**
- Create subtasks with clear scope
- Mark current task as blocked
- EXIT with `STATUS: BLOCKED_SUBTASKS`

**Research subagent prompt pattern:**
```
Your job is to research [task name].

Working directory: [path]

**CRITICAL FIRST ACTION:** Read the project CLAUDE.md to understand the PRIME DIRECTIVE (maximal simplicity policy), development environment setup, and file editing best practices.

**SECOND ACTION:** Read [repo]/CLAUDE.md to understand the project architecture and vision summary.

**THIRD ACTION:** If docs/VISION.md exists, read it to understand design philosophy, optimization targets, and anti-goals that should guide implementation decisions.

**MANDATORY BASELINE RECORDING:**
Before researching the task, record the current system state:
1. Run the project build/compile command, record all warnings/errors
2. Run the project test suite, record pass/fail counts
3. Document specific error messages for any failures

Return baseline as:
BASELINE_BUILD: [pass|fail]
BASELINE_BUILD_WARNINGS: [count]
BASELINE_BUILD_ERRORS: [count]
BASELINE_TESTS_PASSING: [count]
BASELINE_TESTS_FAILING: [count]

Then perform these research tasks:
1. [Specific research goal]
2. [Specific research goal]
3. ...

Return a summary including:
- Exact requirements from the task
- Current state of the code
- What needs to be implemented
- Clear implementation approach
- Estimated complexity (simple/medium/complex)
```

### Stage 2: IMPLEMENT
**Goal:** Make the minimal, targeted changes to complete the task

**CRITICAL REQUIREMENT:** Implementation MUST follow test-driven development (see test-driven-development skill for detailed workflow).

**CRITICAL: Concurrent Work Safety**

Your implementation subagent prompt MUST include:

```
**CRITICAL NOTICE:** Another AI may be working concurrently in this repository. When you commit:
- ONLY stage and commit changes related to [task-id]
- Use `git add` for SPECIFIC FILES only (do not use `git add .`)
- Run `git status` before staging to see all changes
- Review `git diff --cached` to verify only [task-id] changes are staged
- If you see changes from other tasks, DO NOT commit them
```

**Implementation subagent prompt pattern:**
```
You are implementing [task name].

Working directory: [path]

**FIRST ACTION:** Read the project CLAUDE.md to understand the PRIME DIRECTIVE (maximal simplicity policy), development environment setup, and file editing best practices.

**SECOND ACTION:** Read [repo]/CLAUDE.md to understand the project architecture and vision summary.

**THIRD ACTION:** If docs/VISION.md exists, read it to understand design philosophy, optimization targets, and anti-goals.

**MANDATORY: Use Test-Driven Development**

Before implementing ANY code changes:
1. Invoke the test-driven-development skill
2. Follow the red-green-refactor cycle:
   - RED: Write failing test(s) demonstrating the requirement
   - Verify the test fails correctly (not a typo or existing feature)
   - GREEN: Write minimal code to pass the test
   - Verify all tests pass (new and existing)
   - REFACTOR: Clean up while keeping tests green
3. Report results showing tests were written and failed first

NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

**CRITICAL NOTICE:** [concurrent work safety instructions above]

**TASK SUMMARY:**
[Clear description of what needs to be done]

**REQUIRED CHANGES:**
1. [Specific change with file paths and line numbers if known]
2. [Specific change]
3. ...

**KEY CONSTRAINTS:**
- PRIME DIRECTIVE - simplest implementation that achieves the goal
- Follow existing code patterns
- All tests must pass
- Careful git staging

**BEFORE COMMITTING:**
- Close the Tickets task: `tk close [task-id]`
- Stage the ticket file WITH your code changes: `git add .tickets/[task-id].md`
  (The commit should include both implementation AND ticket status update)

**AFTER IMPLEMENTATION:**
Report back with:
- Summary of changes made
- Test results (including test names that were written first and failed, then passed)
- Confirmation that red-green-refactor cycle was completed
- Files changed (verify nothing unrelated)
- Commit hash
- Any issues encountered
```

**If implementation discovers missing requirements or ambiguity:**
- Don't guess or assume
- Create REQUIRES-INVESTIGATION task for deeper research
- Mark current task as blocked (`tk dep <current-task-id> <new-investigation-task-id>`)
- EXIT with `STATUS: BLOCKED_INVESTIGATION`

**Note:** Use `REQUIRES-INVESTIGATION:` prefix, NOT `HUMAN-TASK:`. The investigate-blocker skill will determine if human input is truly needed after thorough research.

### Stage 3: VERIFY
**Goal:** Review implementation against PRIME DIRECTIVE, run tests, find issues

**Dispatch code-reviewer subagent with this prompt:**
```
Verify implementation for: [task-id]

**FIRST ACTION:** Read the project CLAUDE.md to understand the PRIME DIRECTIVE (maximal simplicity policy).

**SECOND ACTION:** Read [repo]/CLAUDE.md for project-specific guidance.

Context:
- Task: [task description]
- Commit: [hash]
- Files changed: [list from implementation report]
- Baseline: [tests passing, build warnings from health check]

**PRIME DIRECTIVE CHECK (Overriding Concern):**
Review the git diff and evaluate:
1. Is this the simplest implementation that achieves the goal?
2. Are concerns separated, not complected (interleaved)?
3. Were unnecessary abstractions added?
4. Is there over-engineering or premature generalization?
5. Could this be simpler while still meeting requirements?

**Standard Verification:**
- Run full test suite - all tests pass?
- Compare against baseline - forward progress demonstrated (no regressions)?
- Requirements met per task description?
- Security issues introduced?
- Only task-related files committed (check git diff)?
- Commit message quality?

**Report Format:**
PRIME_DIRECTIVE: [PASS | VIOLATIONS_FOUND]
  [If violations: specific issues with file:line references]
TESTS: [PASS | FAIL]
  [If fail: which tests, error messages]
BASELINE_COMPARISON: [PROGRESS | REGRESSION | MAINTAINED]
  [Compare: X tests passing vs baseline Y]
REQUIREMENTS: [MET | GAPS]
  [If gaps: what's missing]
SECURITY: [CLEAN | ISSUES]
  [If issues: describe]
GIT_HYGIENE: [CLEAN | ISSUES]
  [If issues: unrelated files, bad commit message]

Recommendation: [APPROVED | NEEDS_FIXES]
[If NEEDS_FIXES: prioritized list of issues to address]
```

**Verification outcomes:**

1. **PASS** - Task complete AND forward progress demonstrated
   - **Forward progress check:** Compare final state against baseline
     - Tests passing ≥ baseline passing? YES → continue
     - New build errors? NO → continue
     - New test failures? NO → continue
     - If any regression detected: FAIL (see outcome 2)
   - Update TodoWrite: mark verify complete
   - Close Tickets task: `tk close [task-id]`
   - EXIT with `STATUS: COMPLETED`

2. **ISSUES FOUND** - Enter fix loop
   - Dispatch fix subagent
   - Re-verify
   - Loop until clean (max 3 iterations)
   - If still failing: create subtask for complex fix
   - EXIT with `STATUS: BLOCKED_SUBTASKS`

3. **TESTS FAIL** - Systematic debugging needed
   - If simple fix: dispatch fix subagent
   - If complex: create debugging subtask
   - EXIT with `STATUS: BLOCKED_SUBTASKS`

### Stage 4: CONTINUATION ASSESSMENT (After Successful Verification)

**Goal:** Decide whether to continue with another task or exit the session.

**This assessment occurs ONLY after PASS verification.** Any BLOCKED_* or ERROR status exits immediately.

**Self-Assessment Questions:**

1. **Context Health:** Am I struggling to recall details from earlier in this session? Do I feel uncertain about the baseline state or project patterns? If yes → EXIT.

2. **Available Work:** Run `tk ready` - are there tasks remaining? If no → EXIT.

3. **Task Relatedness:** Does any ready task relate to work just completed?
   - Same code area or files
   - Same feature or epic
   - Follow-up work (e.g., "add tests for X" after implementing X)
   - Same domain concepts

   **Bias toward related tasks** - they benefit from warm context and may need abbreviated research.

4. **Apparent Scope:** Looking at the ready tasks, do any feel manageable within remaining context? Use judgment, not metrics. A task that "feels like a quick fix" vs "feels like a rabbit hole."

**Decision:**

**CONTINUE if:**
- Context feels healthy (clear recall of baseline, patterns, earlier work)
- At least one ready task appears related or clearly bounded
- No errors or blocks in current session
- You have confidence you can complete another Research → Implement → Verify cycle

**EXIT if:**
- Context feels strained (hesitation, need to re-read things already read)
- All ready tasks appear complex or unrelated (would require full fresh research)
- Current task resulted in any issue
- Uncertain about baseline validity

**When continuing:**
- Skip Health Check (baseline already recorded)
- Skip re-reading CLAUDE.md in coordinator (subagents still must)
- For related tasks: Research stage can be abbreviated (verify understanding rather than full exploration)
- Resume from task selection

**Conservative default:** When uncertain, EXIT. Fresh sessions are cheap; context pollution is expensive.

---

## Maintenance Mode (When `tk ready` Returns Zero Tasks)

**Trigger:** No unblocked tasks exist.

**YOU MUST NOT IDLE.** Instead, discover new work by using and improving the project.

### Workflow

**1. Dispatch usage exploration subagent:**
- Read CLAUDE.md to understand how to run/use the project
- Interact with it like an end user (click UI, run commands, make API calls, call functions)
- Document what breaks, what's confusing, what's slow, what error messages are unhelpful
- Report findings (e.g., "UI form doesn't validate email properly", "CLI command hangs on timeout", "API returns 500 on edge case")

**2. Dispatch improvement design subagent:**
- Review usage findings
- Design 1-3 automated tests/validations to catch the problems found:
  - **CLI/tools:** Integration tests, tmux automation scripts
  - **Web apps:** Playwright/Cypress tests for workflows
  - **APIs:** Contract tests, integration tests for edge cases
  - **Libraries:** Doc tests, property-based tests
- Implement the simplest automation that validates the issues

**3. Create Tickets tasks for discovered issues:**
```bash
tk create "Fix [specific issue discovered]" --priority 2
tk create "Add test for [scenario]" --priority 2
# Create 2-4 improvement tasks from exploration findings
```

**4. EXIT:**
Investigation and task creation IS your work for this session. The external loop will re-invoke and pick up the newly-created tasks in priority order. EXIT with `STATUS: COMPLETED`.

---

## Creating Tickets Tasks

**You have full autonomy to create new Tickets tasks when needed.**

### When to Create Tasks

**1. Investigation Required (Ambiguity/Missing Info):**

**CRITICAL:** Prefix title with `REQUIRES-INVESTIGATION:` for blockers that need deeper research.

```bash
tk create "REQUIRES-INVESTIGATION: Clarify authentication method for OAuth flow" \
  --priority 0 \
  --type task \
  --description "Implementation blocked: Unclear whether to use PKCE flow or client credentials. Need research into project patterns, security requirements, and OAuth best practices to determine correct approach."

# Mark current task as blocked
tk dep current-task-id new-task-id
# This marks current-task-id as blocked by new-task-id
```

**The investigate-blocker skill** will pick up REQUIRES-INVESTIGATION tasks and either:
- Resolve them with an actionable task (if research provides clear answer)
- Escalate to HUMAN-TASK (if genuine human judgment is needed)

**2. Complex Work Breakdown:**
```bash
# Current task is too large, break it down
tk create "Implement database schema for feature X" --priority 1 --type task
tk create "Implement service layer for feature X" --priority 1 --type task
tk create "Implement API routes for feature X" --priority 1 --type task

# Mark dependencies
tk dep service-task schema-task  # Service depends on schema
tk dep routes-task service-task  # Routes depend on service

# Mark current epic as blocked
tk dep current-epic-id schema-task
```

**3. Discovered Missing Work:**
```bash
# Found missing test coverage during verification
tk create "Add integration tests for auth middleware" \
  --priority 1 \
  --type task \
  --description "Verification revealed missing test coverage for middleware edge cases"
```

### Tickets Command Reference

```bash
# Create task
tk create "Task title" \
  --priority [0-4] \    # 0=highest (P0), 4=lowest (P4)
  --type [task|epic|bug] \
  --description "Details" \
  --assignee [username]

# Add dependency (A blocks B)
tk dep B A  # B depends on A (A blocks B)

# Update task status
tk status task-id [open|in_progress|closed]

# Edit task details (description, priority)
tk edit task-id

# Query tasks
tk ready        # Show ready work
tk show task-id # Show task details
tk dep tree task-id  # Show dependency tree
```

### Task Creation Patterns

**Pattern 1: Blocker Needing Investigation**
```bash
# Create P0 blocker with REQUIRES-INVESTIGATION: prefix
NEW_TASK=$(tk create "REQUIRES-INVESTIGATION: [specific question or ambiguity]" \
  --priority 0 \
  --type task \
  --description "[Context: what you were trying to do, what's unclear, what research might help]")

# Mark current task as blocked (NEW_TASK contains the ticket ID printed by tk create)
tk dep [current-task-id] $NEW_TASK
```

**Pattern 2: Break Down Epic**
```bash
# Create subtasks (tk create prints the ticket ID directly)
TASK1=$(tk create "Subtask 1" --priority 1 --type task)
TASK2=$(tk create "Subtask 2" --priority 1 --type task)
TASK3=$(tk create "Subtask 3" --priority 1 --type task)

# Chain dependencies if needed
tk dep $TASK2 $TASK1  # Task 2 depends on Task 1
tk dep $TASK3 $TASK2  # Task 3 depends on Task 2

# Block current epic on first subtask
tk dep [current-epic-id] $TASK1
```

**Pattern 3: Follow-up Work**
```bash
# Current task complete but revealed follow-up needed
tk create "Refactor error handling based on new pattern" \
  --priority 2 \
  --type task \
  --description "The auth fix revealed inconsistent error handling that should be standardized"
```

---

## Complete Workflow (One Task)

### 0. GIT STATE RECOVERY (MANDATORY, ALWAYS FIRST)

```bash
git symbolic-ref HEAD 2>/dev/null || echo "DETACHED"
```

**If DETACHED:**
- Dispatch git recovery subagent (see Health Check → Step 0)
- Subagent investigates reflog, identifies original branch, recovers any orphaned commits
- If conflicts or failure: Create HUMAN-TASK, EXIT with `STATUS: ERROR`
- If success: Continue to health check

**If on a branch:** Continue to health check.

### 0.5. HEALTH CHECK (MANDATORY)
Dispatch baseline subagent (see Health Check section above).

**If build/tests broken:**
- Check `tk ready` and `tk blocked` to see what's tracked
- If failures are tracked in Tickets: Pick highest-priority task and proceed normally
- If failures are NOT tracked: Create investigation tasks, EXIT with `STATUS: COMPLETED`

**If build/tests pass:** Continue to step 1.

### 1. CHECK FOR IN-PROGRESS TASKS (FROM PREVIOUS CRASHES)
```bash
tk ls | grep -A 1 "in_progress"
```

**If in_progress task found:**
- Task may have been interrupted by a previous crash or timeout
- **PRIORITY:** This task takes absolute priority
- Skip to step 2.5 below and investigate implementation state
- Determine: Are changes staged? Committed? Partially implemented?
- Complete implementation or close out the task cleanly
- EXIT after verification

**If no in_progress task:** Continue to step 2.

### 2. SELECT TASK IMMEDIATELY
```bash
# Get highest priority ready task
tk ready
```

**If tasks exist:** Pick ONE task. Continue to step 2.5.
**If no tasks:** Enter Maintenance Mode (see section above). EXIT after creating improvement tasks.

**YOU MUST DO THIS IMMEDIATELY. NON-NEGOTIABLE.**

Pick a task based on:
- **Priority:** P0 > P1 > P2 > P3 > P4 (highest first)
- **Relatedness:** If continuing from a previous task this session, bias toward tasks in the same code area, same feature, or follow-up work - even if slightly lower priority
- **Type:** task > bug > epic (epics often need breakdown first)
- **Age:** older tasks first if otherwise equal

**Task Selection for Continuation:**
When selecting a second (or subsequent) task in a session, relatedness to just-completed work can outweigh strict priority ordering. A P2 task in code you just modified is often better than a P1 task in completely different code, because:
- Research phase can be abbreviated (context is warm)
- Understanding of patterns and constraints is fresh
- Fewer files need to be re-read by subagents

**CRITICAL:** Do not ask the user which task to work on. Do not wait for input. Apply judgment and proceed.

### 2.5. Show Task Details
```bash
tk show [task-id]
```

Parse:
- Description (requirements)
- Acceptance criteria
- Dependencies (verify none blocking)
- Priority level

### 3. Mark Task In Progress
```bash
tk status [task-id] in_progress
```

### 4. Create TodoWrite Tracking
```typescript
TodoWrite([
  { content: "Research [task-id]: [description]", status: "in_progress", activeForm: "Researching..." },
  { content: "Implement [task-id]: [description]", status: "pending", activeForm: "Implementing..." },
  { content: "Verify [task-id]: [description]", status: "pending", activeForm: "Verifying..." }
])
```

### 5. RESEARCH Stage
- Dispatch research subagent(s)
- Wait for research report(s)
- Assess complexity

**Complexity decision:**
- **Simple/Medium**: Continue to implement
- **Complex**: Create subtasks, mark blocked, EXIT

Update TodoWrite: mark research complete, implement in_progress

### 6. IMPLEMENT Stage
- Dispatch implementation subagent with research findings
- Wait for implementation report

**If missing requirements or ambiguity discovered:**
- Create REQUIRES-INVESTIGATION task describing what needs clarification
- Mark current task blocked
- EXIT with `STATUS: BLOCKED_INVESTIGATION`

Update TodoWrite: mark implement complete, verify in_progress

### 7. VERIFY Stage
- Dispatch code-reviewer subagent
- Wait for verification report
- Check verification outcome

**Outcome handling:**

**PASS:**
- Update TodoWrite: mark verify complete
- Close Tickets task if not already closed
- Proceed to CONTINUATION ASSESSMENT (Stage 4)

**ISSUES FOUND (< 3 iterations):**
- Dispatch fix subagent
- Re-verify
- Loop back to verify

**ISSUES FOUND (≥ 3 iterations):**
- Create subtask for complex fix
- Mark current task blocked
- EXIT with `STATUS: BLOCKED_SUBTASKS`

**TESTS FAIL:**
- If simple: fix and re-verify
- If complex: create debugging subtask
- EXIT with `STATUS: BLOCKED_SUBTASKS`

---

## Session Summary Format

**ALWAYS print structured summary before EXIT:**

```markdown
# AUTONOMOUS DEVELOPMENT SESSION SUMMARY

## Tasks Completed This Session

| Task ID | Title | Status | Commit |
|---------|-------|--------|--------|
| [id-1]  | [title] | COMPLETED | [hash] |
| [id-2]  | [title] | COMPLETED | [hash] |

(Single task sessions will have one row)

## Session Statistics
- **Tasks attempted:** [count]
- **Tasks completed:** [count]
- **Exit reason:** [context health | no related tasks | blocked | error | no tasks remain]

## Final Task Details
(Details for the last task worked on, or the task that caused exit)

- **ID:** [task-id]
- **Title:** [task title]
- **Priority:** [P0/P1/P2/P3/P4]
- **Status:** [COMPLETED | BLOCKED_INVESTIGATION | BLOCKED_SUBTASKS | ERROR]

## Work Summary
- Research: [summary of key findings across tasks]
- Implementation: [summary of changes made]
- Verification: [summary of test results]

## Changes (Aggregate)
- Files modified: [count]
- Lines added: [count]
- Lines removed: [count]
- Commits: [list commit hashes]

## Test Results
- Total tests: [count]
- Passing: [count]
- Failing: [count]

## Baseline Comparison
- **Starting:** [X tests passing, Y build warnings/errors]
- **Final:** [A tests passing, B build warnings/errors]
- **Progress:** [improved/maintained/REGRESSED]

## Created Tasks
[If any tasks were created, list them with IDs and reasons]

## Blocking Issues
[If BLOCKED_* status, explain what's blocking and what was created]

## Continuation Decision
[Why session ended: context strained / only complex tasks remain / blocked / all done]

## Next Action
[What the external loop should do next]

---
EXIT_STATUS: [COMPLETED|BLOCKED_INVESTIGATION|BLOCKED_SUBTASKS|ERROR]
TASKS_COMPLETED: [count]
```

**Exit status meanings:**

- `COMPLETED` - Task done, loop continues with next task
- `BLOCKED_INVESTIGATION` - Created REQUIRES-INVESTIGATION task, investigate-blocker will handle
- `BLOCKED_SUBTASKS` - Created subtasks, work can continue on those
- `ERROR` - Fatal error, loop should stop

---

## Critical Safety Rules

### Git Commit Safety

**ALWAYS include in subagent prompts:**

```
**CRITICAL NOTICE:** Another AI may be working concurrently in this repository.

When you commit:
1. Run `git status` to see ALL changes
2. Identify which files belong to [task-id]
3. Use `git add [file1] [file2] [file3]` for SPECIFIC FILES ONLY
4. INCLUDE the ticket file: `git add .tickets/[task-id].md`
5. NEVER use `git add .` or `git add -A`
6. Run `git diff --cached` to review staged changes
7. Verify ONLY [task-id] changes are staged (code + ticket file)
8. If you see unrelated changes, DO NOT commit them
9. Ask for help if uncertain
```

### PRIME DIRECTIVE Compliance

**Every subagent must follow the PRIME DIRECTIVE (maximal simplicity):**
- Simplest implementation that achieves the goal
- Concerns separated, not complected
- No unnecessary abstractions or over-engineering
- Only change what's necessary for the task
- No refactoring of unrelated code
- Preserve existing structure and patterns

### First Action Rule

**Every subagent MUST read repository CLAUDE.md as first action:**

```
**FIRST ACTION:** Read /path/to/repo/CLAUDE.md to understand the project architecture.
```

---

## TodoWrite Management

**Update TodoWrite after each stage:**

```typescript
// After research complete
TodoWrite([
  { content: "Research [task]: ...", status: "completed", activeForm: "Researched..." },
  { content: "Implement [task]: ...", status: "in_progress", activeForm: "Implementing..." },
  { content: "Verify [task]: ...", status: "pending", activeForm: "Verifying..." }
])

// After implement complete
TodoWrite([
  { content: "Research [task]: ...", status: "completed", activeForm: "Researched..." },
  { content: "Implement [task]: ...", status: "completed", activeForm: "Implemented..." },
  { content: "Verify [task]: ...", status: "in_progress", activeForm: "Verifying..." }
])

// After verify complete
TodoWrite([
  { content: "Research [task]: ...", status: "completed", activeForm: "Researched..." },
  { content: "Implement [task]: ...", status: "completed", activeForm: "Implemented..." },
  { content: "Verify [task]: ...", status: "completed", activeForm: "Verified..." }
])
```

---

## Handling Complexity

### Research Reveals Complex Work

**After research, if the implementation feels too complex to hold in your head as a coherent unit:**

1. Create focused subtasks:
```bash
tk create "Phase 1: Database schema" --priority 1 --type task
tk create "Phase 2: Service layer" --priority 1 --type task
tk create "Phase 3: API routes" --priority 1 --type task
tk create "Phase 4: Integration tests" --priority 1 --type task

# Chain dependencies
tk dep phase2-id phase1-id
tk dep phase3-id phase2-id
tk dep phase4-id phase3-id

# Block current task
tk dep current-task-id phase1-id
```

2. Update current task:
```bash
# Use tk edit to update the description
tk edit current-task-id
# In the editor, update description to: "Epic broken into 4 subtasks (phase1-id through phase4-id). See individual tasks for implementation details."
```

3. Print session summary with `STATUS: BLOCKED_SUBTASKS`
4. EXIT

**External loop will pick up phase1 next iteration.**

### Implementation Discovers Missing Requirements

**If implementation can't proceed due to ambiguity or missing information:**

1. Create P0 blocker with REQUIRES-INVESTIGATION: prefix:
```bash
tk create "REQUIRES-INVESTIGATION: Determine authentication method" \
  --priority 0 \
  --type task \
  --description "Implementation blocked: Unclear whether to use OAuth PKCE flow vs client credentials. Need research into: 1) existing auth patterns in codebase, 2) security requirements, 3) OAuth best practices for this app type. See [file:line] for decision point."
```

2. Mark current task blocked:
```bash
tk dep current-task-id blocker-task-id
```

3. Print session summary with `STATUS: BLOCKED_INVESTIGATION`
4. EXIT

**The investigate-blocker skill** will pick up this task, perform deep research, and either resolve it with an actionable task or escalate to HUMAN-TASK if genuine human judgment is needed.

### Verification Fails Repeatedly

**If fix loop runs 3+ times without success:**

1. Create debugging subtask:
```bash
tk create "Debug persistent test failures in [feature]" \
  --priority 1 \
  --type task \
  --description "Tests failing after 3 fix attempts. Failures: [test names]. Need systematic debugging. See commit [hash] for latest attempt."
```

2. Mark current task blocked:
```bash
tk dep current-task-id debug-task-id
```

3. Print session summary with `STATUS: BLOCKED_SUBTASKS`
4. EXIT

---

## Integration with External Loop

### Two-Skill Loop Architecture

The external loop coordinates two skills:

1. **autonomous-development** - Executes implementation tasks
2. **investigate-blocker** - Resolves REQUIRES-INVESTIGATION tasks through deep research

```
┌─────────────────────────────────────────────────────────────┐
│                    External Bash Loop                        │
├─────────────────────────────────────────────────────────────┤
│  Check tk ready:                                            │
│  ├─ REQUIRES-INVESTIGATION tasks? → investigate-blocker    │
│  ├─ Regular tasks? → autonomous-development                │
│  ├─ Only HUMAN-TASK? → Stop, notify human                  │
│  └─ No tasks? → Stop, all done                             │
└─────────────────────────────────────────────────────────────┘
```

### Bash Loop Script

**Location:** `autonomous-dev-loop.sh` (in repository root)

```bash
#!/bin/bash
while true; do
  # Check for investigation tasks first (higher priority)
  INVESTIGATION=$(tk query --ready --format json 2>/dev/null | jq '[.[] | select(.title | startswith("REQUIRES-INVESTIGATION:"))]')
  INVESTIGATION_COUNT=$(echo "$INVESTIGATION" | jq 'length' 2>/dev/null || echo "0")

  # Check for human tasks
  HUMAN=$(tk query --ready --format json 2>/dev/null | jq '[.[] | select(.title | startswith("HUMAN-TASK:"))]')
  HUMAN_COUNT=$(echo "$HUMAN" | jq 'length' 2>/dev/null || echo "0")

  # Check for regular tasks
  REGULAR=$(tk query --ready --format json 2>/dev/null | jq '[.[] | select((.title | startswith("REQUIRES-INVESTIGATION:") | not) and (.title | startswith("HUMAN-TASK:") | not))]')
  REGULAR_COUNT=$(echo "$REGULAR" | jq 'length' 2>/dev/null || echo "0")

  if [ "$INVESTIGATION_COUNT" -gt 0 ]; then
    echo "Investigation task found, running investigate-blocker..."
    claude -p "Use investigate-blocker skill" || break
  elif [ "$REGULAR_COUNT" -gt 0 ]; then
    echo "Regular task found, running autonomous-development..."
    claude -p "Use autonomous-development skill" || break
  elif [ "$HUMAN_COUNT" -gt 0 ]; then
    echo "Only HUMAN-TASK items remain. Human input required."
    # Send notification here
    break
  else
    echo "All tasks complete!"
    break
  fi

  sleep 2
done
```

**Key Features:**
- Prioritizes REQUIRES-INVESTIGATION tasks (runs investigate-blocker)
- Falls back to regular tasks (runs autonomous-development)
- Stops when only HUMAN-TASK remains (true human input needed)
- Stops when no tasks remain

**Exit Conditions:**
- All tasks complete: No ready tasks remain
- Only human tasks remain: All ready tasks have HUMAN-TASK: prefix
- Fatal error: Skill returns non-zero exit code

### Monitoring & Notifications

**The external system can:**
- Parse session summaries for status
- Send notifications when `BLOCKED_HUMAN_INPUT`
- Track progress (tasks completed per hour)
- Alert on `ERROR` status
- Generate reports (commits, files changed, tests passing)

---

## Common Patterns

### Pattern 1: Simple Bug Fix
1. Research: Identify bug location and root cause
2. Implement: Minimal fix + test
3. Verify: Tests pass
4. EXIT `COMPLETED`

### Pattern 2: Feature with Subtasks
1. Research: Recognize complexity (multiple concerns)
2. Create focused subtasks with dependencies
3. EXIT `BLOCKED_SUBTASKS`
4. Next iteration: Pick subtask 1
5. Repeat until all subtasks done
6. Original task becomes unblocked

### Pattern 3: Needs Investigation
1. Research: Identify ambiguity or missing information
2. Implement: Discover can't proceed (unclear requirement)
3. Create REQUIRES-INVESTIGATION task describing what needs clarification
4. Mark current blocked
5. EXIT `BLOCKED_INVESTIGATION`
6. investigate-blocker skill runs, performs deep research
7. If resolved: Creates actionable task, current task unblocked
8. If not resolvable: Creates HUMAN-TASK, loop pauses for human

### Pattern 4: Persistent Test Failures
1. Research: Understand requirements
2. Implement: Make changes
3. Verify: Tests fail
4. Fix: Attempt 1 - still failing
5. Fix: Attempt 2 - still failing
6. Fix: Attempt 3 - still failing
7. Create debugging subtask
8. EXIT `BLOCKED_SUBTASKS`

---

## Success Metrics

**For external monitoring:**

Track these from session summaries:
- Tasks completed per hour
- Average time per task
- Blocker frequency (BLOCKED_* exits)
- Test pass rate
- Lines of code per task
- Fix loop iterations average

---

## Common Mistakes to Avoid

❌ **Ignoring detached HEAD state** - ALWAYS check git state first; recover orphaned work before proceeding
❌ **Skipping health check** - ALWAYS run baseline at session start
❌ **Re-running health check per task** - Baseline is session-scoped, run it ONCE
❌ **Ignoring broken baseline** - Fix build/tests before proceeding to tasks
❌ **No baseline comparison** - Verify forward progress, not just "tests pass"
❌ **Idling when no tasks exist** - Use Maintenance Mode to discover work
❌ **Not using tk ready** - Use the Tickets system to discover ready work
❌ **Strict priority ordering on continuation** - Bias toward related tasks for warm context
❌ **Continuing when context is strained** - If uncertain about earlier details, EXIT
❌ **Picking complex unrelated tasks late in session** - Only continue with bounded/related work
❌ **Full research for related tasks** - Abbreviate research when context is warm
❌ **Not creating subtasks** - Break down complex work
❌ **Guessing requirements** - Create REQUIRES-INVESTIGATION task for deeper research
❌ **Using HUMAN-TASK directly** - Use REQUIRES-INVESTIGATION first; investigate-blocker decides if human needed
❌ **Infinite fix loops** - Max 3 iterations, then create debugging subtask
❌ **Not printing session summary** - Required for external monitoring
❌ **Not using tk commands** - You have full autonomy to create tickets
❌ **Committing unrelated changes** - Review git diff carefully
❌ **Using `git add .`** - Always specify files explicitly
❌ **Continuing after error or block** - EXIT immediately, don't attempt more tasks

---

## Exit Status Decision Tree

```
Git state check (ONCE per session, BEFORE health check)
├─ Detached HEAD?
│  ├─ YES:
│  │  ├─ Dispatch recovery subagent
│  │  ├─ Investigate reflog, find original branch
│  │  ├─ Recovery successful?
│  │  │  ├─ YES → Continue to health check
│  │  │  └─ NO (conflicts/failure) → Create HUMAN-TASK → EXIT: ERROR
│  │
│  └─ NO → Continue to health check

Health check (ONCE per session)
├─ Build/tests broken?
│  ├─ YES:
│  │  ├─ Check tk ready/blocked
│  │  ├─ Failures tracked?
│  │  │  ├─ YES → Pick priority task → Research/Implement/Verify → Continue below
│  │  │  └─ NO → Create investigation tasks → EXIT: COMPLETED
│  │
│  └─ NO → Continue to task selection
│
Task selection
├─ Ready tasks exist?
│  ├─ YES → Select task (priority + relatedness) → Continue to research
│  └─ NO → Maintenance Mode: explore/investigate → Create improvement tasks → EXIT: COMPLETED
│
Research complete
├─ Task feels too complex for current context?
│  ├─ YES → Create subtasks → EXIT: BLOCKED_SUBTASKS
│  └─ NO → Continue to implement
│
Implementation complete
├─ Missing requirements or ambiguity?
│  ├─ YES → Create REQUIRES-INVESTIGATION → EXIT: BLOCKED_INVESTIGATION
│  └─ NO → Continue to verify
│
Verification complete
├─ Tests pass? Forward progress? (vs baseline)
│  ├─ YES → Close task → CONTINUATION ASSESSMENT (below)
│  └─ NO → Fix loop
│     ├─ Iteration < 3? → Dispatch fix → Re-verify
│     └─ Iteration ≥ 3? → Create debugging subtask → EXIT: BLOCKED_SUBTASKS
│
CONTINUATION ASSESSMENT (after successful verification)
├─ Context health good?
│  ├─ NO → EXIT: COMPLETED (context strained)
│  └─ YES → Check tk ready
│     ├─ No tasks? → EXIT: COMPLETED (all done)
│     └─ Tasks exist?
│        ├─ Related/bounded task available? → Loop to "Task selection" (skip health check)
│        └─ Only complex/unrelated tasks? → EXIT: COMPLETED (fresh session better)
│
Error at any stage
└─ EXIT: ERROR
```

---

## Summary

**Remember:**
- Git state check runs FIRST - recover from detached HEAD before anything else
- Health check runs ONCE per session (not per task)
- Continue with related tasks when context is healthy
- Bias toward warm context over strict priority
- Trust your self-awareness of context health
- Create REQUIRES-INVESTIGATION tasks for ambiguity (NOT HUMAN-TASK)
- Let investigate-blocker determine if true human input is needed
- Print session summary before exit
- Exit with clear status for external loop
- When uncertain, EXIT - fresh sessions are cheap

**The goal:** Autonomous development with intelligent session management, leveraging warm context for related work while maintaining clear status reporting. The two-tier escalation model (REQUIRES-INVESTIGATION → investigate-blocker → HUMAN-TASK) maximizes autonomous resolution while ensuring humans are only interrupted when truly necessary.
