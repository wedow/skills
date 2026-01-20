---
name: feedback-driven-development
description: Analyzes tasks from first principles to determine, design, and build appropriate feedback mechanisms before implementation. Use when starting any significant task, when TDD doesn't fit cleanly, or when you need verification beyond unit tests - visual, integration, E2E, metrics, or custom verification.
---

# Feedback-Driven Development

## The Principle

Tests are one feedback mechanism. The general principle is broader:

**Before implementing anything, ensure you have accurate, reliable feedback to verify correctness.**

The only failure mode for autonomous agents is when they can't check their own work. With accurate feedback loops, agents solve virtually any problem. Without them, they stab in the dark.

## When to Use

**Always consider for:**
- Tasks where unit tests don't naturally fit
- UI/UX changes (visual verification needed)
- Performance work (benchmarks needed)
- Integration work (E2E or contract tests needed)
- CLI tools (output verification needed)
- Data pipelines (state inspection needed)
- Any task where "it works" is ambiguous

**Relationship to TDD:**
- TDD is a specific instance of this skill (tests = feedback mechanism)
- Use TDD skill when unit tests are the right fit
- Use this skill when you need to THINK about what feedback mechanism is appropriate

## Core Workflow

```
1. ANALYZE
   - What does "correct" mean for this task?
   - What observable outcomes indicate success?
   - What could go wrong?

2. CLASSIFY
   - What type of verification is appropriate?
   - Unit tests? Integration? Visual? Performance? Custom?

3. DESIGN
   - How do we capture that verification?
   - What tools, scripts, or infrastructure?
   - What's the simplest mechanism that provides accurate feedback?

4. BUILD (if needed)
   - Create the feedback mechanism as a blocking task
   - Verify the mechanism itself works

5. GATE
   - Implementation proceeds only with feedback in place
   - Every iteration through the feedback loop increases confidence
```

---

## Stage 1: Analyze

**Goal:** Understand what "correct" means before thinking about how to verify it.

### First Principles Questions

1. **What observable outcome indicates this task is complete?**
   - Not "the code is written" - what BEHAVIOR changes?
   - Not "tests pass" - what do those tests verify?

2. **How would a user know this works?**
   - What would they see, experience, or measure?
   - This often reveals the natural verification mechanism

3. **What are the failure modes?**
   - What could go wrong even if the "obvious" checks pass?
   - Edge cases, race conditions, visual regressions, performance cliffs

4. **Is there existing verification we should leverage?**
   - Existing test suites, CI pipelines, monitoring
   - Don't reinvent if adequate mechanisms exist

### Output Format

```markdown
## Task Analysis

### Success Criteria
- [Observable outcome 1]
- [Observable outcome 2]

### User-Visible Behavior
- [What changes from user perspective]

### Failure Modes
- [What could go wrong 1]
- [What could go wrong 2]

### Existing Verification
- [What already exists that we can use]
- [Gaps in existing verification]
```

---

## Stage 2: Classify

**Goal:** Determine what TYPE of feedback mechanism fits this task.

### Feedback Mechanism Taxonomy

| Category | When to Use | Tools/Approaches |
|----------|-------------|------------------|
| **Unit Tests** | Pure functions, isolated logic, data transformations | Jest, pytest, etc. - use TDD skill |
| **Integration Tests** | Multiple components interacting, API contracts | Supertest, pytest with fixtures |
| **E2E Tests** | User flows, UI interactions, full system | Playwright, Cypress |
| **Visual Verification** | UI appearance, layout, responsiveness | Screenshots, Storybook, Percy |
| **Performance Benchmarks** | Speed, memory, throughput requirements | Custom benchmarks, load tests |
| **Contract Tests** | API compatibility, schema validation | Pact, OpenAPI validation |
| **State Inspection** | Database changes, file outputs, side effects | Queries, file diffs, assertions |
| **Log Analysis** | Correct execution paths, error handling | Log parsing, pattern matching |
| **Manual Verification Scripts** | Complex scenarios, exploratory testing | Custom scripts with assertions |
| **REPL/Interactive** | Exploratory, behavior discovery | Language REPL, browser console |
| **Type Checking** | Interface contracts, refactoring safety | TypeScript, mypy |
| **Linting/Static Analysis** | Code quality, security patterns | ESLint, security scanners |

### Classification Decision Tree

```
Is the task about isolated logic/data transformation?
├─ YES → Unit Tests (use TDD skill)
└─ NO → Continue

Is the task about user-visible behavior in a UI?
├─ YES →
│  ├─ Functional behavior? → E2E Tests (Playwright)
│  └─ Visual appearance? → Visual Verification (screenshots)
└─ NO → Continue

Is the task about API behavior?
├─ YES →
│  ├─ Internal API? → Integration Tests
│  └─ External/contract? → Contract Tests
└─ NO → Continue

Is the task about performance?
├─ YES → Benchmarks with baseline comparison
└─ NO → Continue

Is the task about data/state changes?
├─ YES → State Inspection (queries, file diffs)
└─ NO → Continue

Is the task about correct execution paths?
├─ YES → Log Analysis or tracing
└─ NO → Continue

Fallback: Manual Verification Script with assertions
```

### Output Format

```markdown
## Verification Classification

### Primary Mechanism
- Type: [from taxonomy]
- Rationale: [why this fits]

### Supporting Mechanisms
- [Additional verification if needed]

### What This WON'T Catch
- [Known gaps - accept or address separately]
```

---

## Stage 3: Design

**Goal:** Design the specific feedback mechanism for this task.

### Design Principles

1. **Accuracy over convenience**
   - The mechanism must actually verify correctness
   - A passing check that misses bugs is worse than no check

2. **Immediacy**
   - Feedback should be fast enough to iterate on
   - Slow feedback = fewer iterations = less learning

3. **Clarity**
   - Pass/fail must be unambiguous
   - When it fails, the failure should point to the problem

4. **Simplicity**
   - Simplest mechanism that provides accurate feedback
   - Don't build infrastructure you don't need

### Design Questions

1. **What's the minimal verification that catches the failure modes?**
   - Don't test everything, test what matters

2. **How fast can this run?**
   - Sub-second is ideal
   - Minutes is acceptable for thorough verification
   - Hours means something's wrong

3. **What's the pass/fail output?**
   - Exit codes, assertion messages, visual diffs
   - Must be parseable by the agent

4. **Does infrastructure exist or need building?**
   - Existing test framework? Use it.
   - Need browser automation? Set up Playwright.
   - Need benchmarks? Create baseline measurements.

### Output Format

```markdown
## Feedback Mechanism Design

### Mechanism
[Description of what will be built/used]

### Verification Commands
```bash
# Command(s) the implementation agent will run
[command 1]
[command 2]
```

### Success Criteria
- [What output indicates success]
- [What output indicates failure]

### Infrastructure Needs
- [ ] [Tool/setup needed 1]
- [ ] [Tool/setup needed 2]

### Estimated Feedback Time
[How long verification takes]
```

---

## Stage 4: Build

**Goal:** Create the feedback mechanism if it doesn't exist.

### When Building is Required

- No existing test infrastructure for this type of verification
- Existing infrastructure doesn't cover this specific case
- Custom verification script needed

### Build Workflow

1. **Create as a blocking task**
   ```bash
   tk create "Setup feedback mechanism: [description]" \
     --priority [same as implementation task] \
     --type task \
     --description "[Details from design stage]"

   # Block implementation on this
   tk dep [implementation-task-id] [feedback-setup-task-id]
   ```

2. **Implement the mechanism**
   - Follow the design from Stage 3
   - Verify the mechanism itself works (test the test)

3. **Document usage**
   - Commands to run
   - Expected outputs
   - How to interpret failures

### Testing the Feedback Mechanism

**Critical:** Before considering the mechanism complete:

1. **Does it fail when it should?**
   - Introduce a known bug
   - Verify the mechanism catches it
   - This is the "red" in red-green-refactor, generalized

2. **Does it pass when it should?**
   - Fix the known bug
   - Verify the mechanism passes

3. **Is the failure message useful?**
   - Does it point to what's wrong?
   - Can an agent act on it?

---

## Stage 5: Gate

**Goal:** Ensure implementation only proceeds with feedback in place.

### Gate Checklist

Before implementation begins:
- [ ] Feedback mechanism exists and is runnable
- [ ] Verification commands are documented
- [ ] Success/failure criteria are clear
- [ ] Mechanism has been tested (fails when should fail)

### Implementation Pattern

With feedback in place, implementation follows this loop:

```
1. Make change
2. Run verification
3. Check result:
   - PASS → Change is correct, continue
   - FAIL → Change is wrong, adjust
4. Repeat until all verification passes
```

This is the generalized form of red-green-refactor.

---

## Integration with Other Skills

### With project-planning

During planning, for each task/phase:
1. Run Stage 1 (Analyze) to understand verification needs
2. Run Stage 2 (Classify) to determine mechanism type
3. Include verification design in the plan
4. Create blocking tasks for feedback mechanism setup

### With autonomous-development

Before Research → Implement → Verify cycle:
1. Check if task has defined verification mechanism
2. If not, invoke this skill first
3. Verification stage uses the designed mechanism

### With TDD

- TDD is the workflow when Stage 2 classifies as "Unit Tests"
- This skill is the meta-workflow for CHOOSING the right approach
- For unit-testable code, defer to TDD skill

---

## Feedback Mechanism Patterns

### Pattern 1: Visual UI Verification

**Task:** Implement dark mode toggle

**Analysis:**
- Success = UI renders correctly in both modes
- Failure modes = broken layout, wrong colors, contrast issues

**Classification:** Visual Verification

**Design:**
```bash
# Screenshot comparison
npx playwright test tests/visual/dark-mode.spec.ts --update-snapshots

# Verify specific elements
npx playwright test tests/visual/dark-mode.spec.ts
```

**Success criteria:** Screenshots match expected, contrast ratios pass

### Pattern 2: Performance Verification

**Task:** Optimize database query

**Analysis:**
- Success = Query runs faster than baseline
- Failure modes = Regression, different results, edge cases

**Classification:** Performance Benchmark + Correctness Check

**Design:**
```bash
# Capture baseline
npm run benchmark:query -- --save-baseline

# After changes
npm run benchmark:query -- --compare-baseline --threshold=20%

# Verify correctness
npm run test:query-results
```

**Success criteria:** 20%+ improvement, identical results

### Pattern 3: Integration Verification

**Task:** Add webhook integration

**Analysis:**
- Success = Webhooks fire correctly, payloads are valid
- Failure modes = Missing events, malformed payloads, auth issues

**Classification:** Integration Test + Contract Test

**Design:**
```bash
# Mock webhook receiver
npm run test:webhooks -- --mock-receiver

# Contract validation
npm run validate:webhook-schema

# Integration test
npm run test:integration -- --grep "webhook"
```

**Success criteria:** Events captured, schemas valid, auth works

### Pattern 4: State Verification

**Task:** Implement data migration

**Analysis:**
- Success = Data migrated correctly, no data loss
- Failure modes = Truncation, encoding issues, missing records

**Classification:** State Inspection

**Design:**
```bash
# Pre-migration snapshot
psql $DB -c "SELECT count(*), checksum_agg(hashtext(row_to_json(t)::text)) FROM table_name t" > pre.txt

# Run migration
npm run migrate:up

# Post-migration verification
psql $DB -c "SELECT count(*), checksum_agg(hashtext(row_to_json(t)::text)) FROM table_name t" > post.txt

# Compare
diff pre.txt post.txt && echo "PASS: Counts match"
```

**Success criteria:** Record counts match, checksums account for expected changes

### Pattern 5: CLI Output Verification

**Task:** Add new CLI command

**Analysis:**
- Success = Command produces correct output
- Failure modes = Wrong output, bad exit codes, missing help

**Classification:** Manual Verification Script

**Design:**
```bash
# Help works
./cli --help | grep "new-command" || exit 1

# Basic invocation
./cli new-command --input test.txt > output.txt
diff output.txt expected-output.txt || exit 1

# Error handling
./cli new-command --input nonexistent.txt 2>&1 | grep "File not found" || exit 1
echo $? | grep "1" || exit 1

echo "PASS: CLI command works correctly"
```

**Success criteria:** All assertions pass, exit codes correct

---

## Anti-Patterns

### "Tests pass so it's correct"

Tests only verify what they test. If tests pass but the feature is broken for users, your feedback mechanism is wrong.

**Fix:** Start from user-observable behavior, work backward to verification.

### "Manual testing is sufficient"

Manual testing is valuable but not a feedback LOOP. Agents can't iterate on manual testing.

**Fix:** Automate the verification, even if simplified.

### "We'll add tests later"

Without feedback during implementation, you're coding blind. Bugs compound.

**Fix:** Feedback mechanism is a BLOCKER, not a follow-up.

### "100% code coverage"

Coverage measures execution, not correctness. You can have 100% coverage and broken features.

**Fix:** Focus on behavior coverage, not line coverage.

### "The CI will catch it"

CI is the last line of defense, not the primary feedback loop. Waiting for CI is too slow.

**Fix:** Local verification first, CI as confirmation.

---

## Summary

1. **Analyze** - What does "correct" mean?
2. **Classify** - What type of verification fits?
3. **Design** - How specifically will we verify?
4. **Build** - Create the mechanism if needed
5. **Gate** - Don't implement without feedback

The whole game is feedback loops. Get them right, and agents solve virtually anything.
