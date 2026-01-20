---
name: project-planning
description: Orchestrates comprehensive feature planning through autonomous research phases and map-reduce cycles. Researches codebase first to understand current state, only interviews user for human judgment questions, then runs research waves after each interview round. Produces detailed implementation plans with executable verification commands.
---

# Project Planning Skill

## Core Principle: Autonomous Research First

**Human time is precious. Don't ask the user about things that have objectively correct answers discoverable through research.**

Before asking ANY question, research the codebase. Most questions about "current state" or "how things work" can be answered by reading code:

- "How are objects currently stored?" → Read the code
- "What's the execution model?" → Read the code
- "Is there existing SQLite integration?" → Search the codebase
- "What patterns does the project use?" → Examine existing implementations

**Only ask the user about genuine human decisions:**
- Scope decisions (include X or defer?)
- Priority choices (which capability first?)
- Design preferences between valid approaches
- Vision/goals alignment questions
- Tradeoffs that depend on unstated preferences

## Core Principle: Autonomous Feedback Loops

The entire purpose of this workflow is to enable **fully autonomous implementation**. Every output must be:

1. **Self-verifiable**: Agents can validate their own work without external help
2. **Immediately actionable**: No waiting for humans, external parties, or future conditions
3. **Executable**: Verification is commands that run, not descriptions of what to check

## Architecture Overview

The workflow uses **research-interview-research loops** followed by **planning cycles**:

```
                    DISCOVERY CYCLE
                    ===============
Initial Research (MAP: understand current state)
        |
        v
Research Waves (until no NEEDS_RESEARCH remains)
        |
        v
Gap Analysis (classify: RESEARCHABLE | USER_INPUT | DEFERRABLE)
        |
        v
[If USER_INPUT needed] Interview (only human-judgment questions)
        |
        v
Post-Interview Research (fill gaps from responses)
        |
        v
[Loop until only DEFERRABLE gaps remain]


                    FEATURE RESEARCH CYCLE
                    ======================
Feature Research Fan-Out (MAP: N angles)
        |
        v
Research Waves (until coverage complete)
        |
        v
Aggregation (REDUCE: consolidate if large)
        |
        v
Final Gap Analysis
        |
        [Loop back if gaps found]


                    PLANNING CYCLE
                    ==============
High-Level Architecture (REDUCE: single overview)
        |
        v
Architecture Verification (self-consistency)
        |
        v
Decomposition Assessment (identify complex sections)
        |
        v
Detailed Phase Planning (MAP: N agents, recursive)
        |
        v
Plan Integration (REDUCE: merge all phases)
        |
        v
Plan Verification (executable readiness check)
        |
        v
Cleanup & Report
```

## Main Agent Role (CRITICAL)

**The main agent is a COORDINATOR ONLY.** It never reads file contents, analyzes code, or makes planning decisions. Every substantive task is delegated to a sub-agent.

**Main agent responsibilities:**
- Dispatch sub-agents with lightweight prompts
- Receive sub-agent responses (short summary + file path)
- Route file paths from one phase to the next
- Make go/no-go decisions based on sub-agent reports
- Conduct interviews ONLY for questions that require human judgment
- Manage the temp directory structure

**Main agent NEVER:**
- Reads research files or code
- Analyzes architecture documents
- Evaluates plan quality directly
- Makes planning decisions
- Asks the user questions that could be answered by research

**Sub-agent response format** (all sub-agents return this):
```
## Summary
[2-3 sentences: what was done, key findings, any blockers]

## Output
[file path where full output was written]

## Status
[COMPLETE | NEEDS_ITERATION | BLOCKED]

## Next Steps (if any)
[what the main agent should do next]
```

This keeps main agent context clean. It only sees summaries and file paths, never content.

**CRITICAL**: Sub-agents must WRITE their findings to the specified file using the Write tool, then return ONLY the brief summary format above. Never return the full research content - that bloats the main agent's context.

## Context Management (CRITICAL)

**Sub-agent prompts must be lightweight.** The main agent's context fills with every sub-agent prompt it sends. With dozens of sub-agents, this becomes a problem.

**Rules:**
- Never copy file contents into prompts
- Always reference files by path and line numbers
- Keep prompts under 500 tokens where possible
- Use the temp directory structure as the coordination mechanism
- Sub-agents return summaries + file paths, not full content

---

## Stage 0: Setup

Create temp directory structure:
```bash
ts=$(date +%s)
mkdir -p /tmp/planning-$ts/{research,waves,phases}
```

All sub-agents write to this directory. Main agent tracks only the timestamp.

---

## Stage 1: Discovery

### 1.1 Initial State Research (MAP)

**Goal**: Understand the current codebase state BEFORE asking any questions.

**Dispatch parallel research agents to understand:**

**Current State Researcher:**
```
Research: Current implementation state for [feature area]

Write findings to: /tmp/planning-[ts]/research/current-state.md

Instructions:
1. Read context documents:
   - ~/CLAUDE.md (global development conventions)
   - Project CLAUDE.md (project-specific conventions)
   - docs/VISION.md (if exists - project vision and philosophy)
2. Investigate the codebase for:
   - How the relevant components currently work
   - What infrastructure exists that relates to this feature
   - What patterns the project uses
   - What's already implemented vs what's missing
3. Write report to the file above containing:
   - Summary (2-3 sentences)
   - Current architecture (what exists)
   - Relevant patterns found
   - Integration points identified
   - Source files examined (with line numbers)
   - Unresolved questions (things that can't be determined from code alone)

IMPORTANT: Write findings to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE or NEEDS_RESEARCH
Do NOT return the full report content.
```

**Vision/Constraints Researcher** (if docs/VISION.md exists):
```
Research: Vision and constraints for [feature area]

Write findings to: /tmp/planning-[ts]/research/vision-constraints.md

Instructions:
1. Read docs/VISION.md thoroughly
2. Extract:
   - Success criteria that apply to this feature
   - Anti-goals that might be violated
   - Design principles that guide implementation
   - Decision framework for architectural choices
   - Performance/quality requirements
3. Write report to the file above containing:
   - Relevant success criteria
   - Applicable constraints
   - Design principles to follow
   - Potential anti-goal conflicts to avoid

IMPORTANT: Write findings to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE or NEEDS_RESEARCH
Do NOT return the full report content.
```

**Parallelism**: Deploy all initial researchers in a single message with multiple Task calls.

### 1.2 Research Waves

**Goal**: Fill gaps discovered by initial research through additional targeted research.

Some research uncovers new questions that require further investigation. Run in waves:

```
Wave 1: Initial research agents
  - Dispatch in parallel
  - Collect results
  - Identify NEEDS_RESEARCH items from each report

Wave 2: Targeted follow-up
  - For each NEEDS_RESEARCH item, dispatch focused researcher
  - Collect results
  - Identify any remaining gaps

Wave 3+: (if needed)
  - Continue until no new NEEDS_RESEARCH items
  - Maximum 3 waves to prevent infinite loops
```

**Targeted Researcher Pattern:**
```
Research: [Specific question from previous wave]

Context: Prior research found [brief summary of what's known]

Write findings to: /tmp/planning-[ts]/waves/wave-N-[topic].md

Instructions:
1. Investigate [specific question]
2. Check [specific files, patterns, or documentation]
3. Write focused report to file answering the question
4. Note if more research still needed

IMPORTANT: Write findings to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE or NEEDS_RESEARCH
Do NOT return the full report content.
```

### 1.3 Gap Analysis

**Goal**: Classify remaining gaps to determine what needs user input.

**Deploy Gap Analyzer sub-agent:**
```
Analyze gaps in research.

Context:
- Research: /tmp/planning-[ts]/research/
- Wave results: /tmp/planning-[ts]/waves/

Write analysis to: /tmp/planning-[ts]/GAP_ANALYSIS.md

Instructions:
1. Read all research and wave reports
2. List all unresolved questions
3. For each, classify:
   - RESEARCHABLE: Can targeted codebase/doc investigation answer this?
   - USER_INPUT: Requires human judgment (scope, priority, preference, vision)
   - DEFERRABLE: Can be decided during implementation
4. For each classification, explain why:
   - RESEARCHABLE: "Could check [specific file/doc] to answer"
   - USER_INPUT: "Requires preference between valid approaches" or "Scope decision"
   - DEFERRABLE: "Implementation can decide based on [criteria]"
5. Write gap analysis to file with:
   - Questions by category
   - For RESEARCHABLE: dispatch another research wave
   - For USER_INPUT: specific question to ask user
   - Recommendation: NEEDS_RESEARCH, NEEDS_USER_INPUT, or PROCEED

IMPORTANT: Write analysis to file, then return ONLY:
- Summary (2-3 sentences with key gaps found)
- File path written
- Status + Recommendation
Do NOT return the full analysis content.
```

**Gate Logic** (main agent decides based on summary):
- NEEDS_RESEARCH → Deploy targeted researchers → Loop back to 1.2
- NEEDS_USER_INPUT → Proceed to 1.4 (Interview)
- PROCEED (only deferrable gaps) → Continue to Stage 2

### 1.4 Interview (USER_INPUT Questions Only)

**Goal**: Get human decisions on questions that genuinely require human judgment.

**Present ONLY questions classified as USER_INPUT from gap analysis:**

```
## Planning: [Feature Name]

### Research Summary

I've researched the codebase and found:
- [Key findings from current-state research]
- [Key findings from vision/constraints research]

### Decisions Needed

Based on research, these questions require your input:

**1. [Question about scope/priority/preference]**
[Brief context from research]
Options:
- A: [option] - [implications]
- B: [option] - [implications]

**2. [Question about design choice]**
[Brief context from research]
Options:
- A: [option] - [implications]
- B: [option] - [implications]

Which approaches do you prefer?
```

**Decision Handling:**
User can:
1. **Make definitive choice** - "Use approach A"
2. **Allow flexibility** - "Either A or B. Prefer A if [condition], otherwise B."
3. **Request more research** - "I need to know X first" → dispatch researcher
4. **Flag for later** - "Create HUMAN-TICKET, block dependent work"

### 1.5 Post-Interview Research

**Goal**: Fill any gaps that emerged from user responses.

User responses often reveal new areas to investigate:
- "Use approach A" → Research how A integrates with existing code
- "Prioritize X over Y" → Research what X requires as foundation
- New constraints mentioned → Verify they don't conflict with existing implementation

**Deploy targeted researchers for each new area:**
```
Research: [Topic revealed by user response]

Context:
- User decided: [decision]
- Need to understand: [what this implies for implementation]

Write findings to: /tmp/planning-[ts]/waves/post-interview-[topic].md

Instructions:
1. Investigate implications of user's decision
2. Check for conflicts with existing code
3. Identify integration points
4. Note any new gaps discovered
5. Write findings to the file above

IMPORTANT: Write findings to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE or NEEDS_RESEARCH
Do NOT return the full report content.
```

**If new USER_INPUT gaps emerge**: Loop back to 1.4 for another interview round.

**Maximum 3 interview rounds** to prevent infinite loops. After 3 rounds, remaining ambiguity becomes DEFERRABLE.

---

## Stage 2: Feature Research

### 2.1 Feature Research Fan-Out (MAP)

**Goal**: Deep-dive into feature-specific requirements from multiple angles.

By now we understand the current state and user priorities. Research the specific feature:

**Research Angles** (select based on relevance):
- Integration with existing systems identified in Stage 1
- External dependencies and their APIs
- Security implications for this feature
- Performance considerations
- Error handling patterns to follow
- Testing patterns used in the project

**Sub-Agent Prompt** (keep lightweight):
```
Research: [Specific Angle]

Write findings to: /tmp/planning-[ts]/research/[angle-name].md

Instructions:
1. Read context from prior research:
   - /tmp/planning-[ts]/research/current-state.md
   - /tmp/planning-[ts]/GAP_ANALYSIS.md
2. Investigate [specific focus area]
3. Write report to file containing:
   - Summary (2-3 sentences)
   - Findings (organized by sub-topic)
   - Implications for the feature
   - Vision alignment notes
   - Unresolved questions (if any)
   - Source files examined (with line numbers)

IMPORTANT: Write findings to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE or NEEDS_RESEARCH
Do NOT return the full report content.
```

**Parallelism**: Deploy all researchers in a single message with multiple Task calls.

### 2.2 Feature Research Waves

Apply the same wave pattern from 1.2:
- Wave 1: Initial feature research
- Wave 2+: Follow-up on NEEDS_RESEARCH items
- Maximum 3 waves

### 2.3 Research Validation

**Goal**: Verify research covers all requirements before planning.

**Deploy Research Validator sub-agent:**
```
Validate research coverage.

Context:
- User requirements: [summary from interview]
- All research: /tmp/planning-[ts]/research/
- Wave results: /tmp/planning-[ts]/waves/

Write validation to: /tmp/planning-[ts]/RESEARCH_VALIDATION.md

Instructions:
1. Read all research reports
2. For each requirement: Is it addressed? By which report?
3. Identify gaps: requirements not covered
4. Classify remaining gaps (RESEARCHABLE | USER_INPUT | DEFERRABLE)
5. Write validation report to file with:
   - Coverage matrix (requirement → report)
   - Gaps identified with classification
   - Recommendation: PROCEED, NEEDS_RESEARCH, or NEEDS_USER_INPUT

IMPORTANT: Write validation to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status + Recommendation
Do NOT return the full validation content.
```

**Gate Logic:**
- NEEDS_RESEARCH → Deploy targeted researchers → Loop to 2.2
- NEEDS_USER_INPUT → Interview user → Loop to 1.4
- PROCEED → Continue to Stage 3

### 2.4 Aggregation (Conditional)

**Trigger**: Combined research exceeds ~100k tokens.

**Check**: `wc -w /tmp/planning-[ts]/research/*.md /tmp/planning-[ts]/waves/*.md | tail -1`

**If aggregation needed**, deploy Aggregator sub-agent:
```
Aggregate research findings.

Read from: /tmp/planning-[ts]/research/ and /tmp/planning-[ts]/waves/
Write aggregation to: /tmp/planning-[ts]/AGGREGATION.md

Instructions:
1. Read all .md files in research and waves directories
2. Identify themes, contradictions, complementary findings
3. Consolidate to ~50k tokens max
4. Include citations: [finding] (source-file.md:line-number)
5. List any remaining unresolved questions
6. Write aggregation to file

IMPORTANT: Write aggregation to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE
Do NOT return the aggregated content.
```

---

## Stage 3: Planning

### 3.1 High-Level Architecture

**Goal**: Produce architectural overview, NOT detailed implementation.

**Deploy Architect sub-agent:**
```
Create high-level architecture for [feature name].

Context:
- Research: /tmp/planning-[ts]/research/ (or AGGREGATION.md if exists)
- User decisions: [list key decisions from interview]

Write architecture to: /tmp/planning-[ts]/ARCHITECTURE.md

Instructions:
1. Read research context
2. Write architectural overview to file containing:
   - Component overview (what are the major pieces?)
   - Component responsibilities (what does each do?)
   - Interfaces (how do components communicate?)
   - Data flow (how does data move through the system?)
   - Technology decisions (what tools/frameworks/patterns?)
   - Constraints and non-negotiables
   - Open decisions (things implementation can decide)

Keep to ~2-5k tokens. This is structure, not implementation detail.
Do NOT include detailed implementation steps.
Do NOT include code examples.

IMPORTANT: Write architecture to file, then return ONLY:
- Summary (2-3 sentences)
- File path written
- Status: COMPLETE
Do NOT return the architecture content.
```

### 3.2 Architecture Verification

**Goal**: Validate architecture is internally consistent before decomposition.

**Deploy Architecture Verifier sub-agent:**
```
Verify architecture consistency.

Context:
- Architecture: /tmp/planning-[ts]/ARCHITECTURE.md
- Requirements: [1-2 sentence summary]

Write verification to: /tmp/planning-[ts]/ARCHITECTURE_VERIFICATION.md

Instructions:
1. Read ARCHITECTURE.md thoroughly
2. Check consistency:
   - Every component mentioned → is it defined?
   - Every interface → has producer and consumer?
   - Data flows → form a DAG (no unexpected cycles)?
   - All requirements → addressed by some component?
   - No TODO/TBD placeholders?
3. Write verification report to file with:
   - Issues found (with line numbers)
   - Severity: CRITICAL (blocks planning) or MINOR (can proceed)
   - Suggested fixes for each issue
   - Recommendation: APPROVED or NEEDS_REVISION

IMPORTANT: Write verification to file, then return ONLY:
- Summary (2-3 sentences with key issues if any)
- File path written
- Status + Recommendation: APPROVED or NEEDS_REVISION
Do NOT return the full verification content.
```

**Gate Logic:**
- NEEDS_REVISION → Send verification report to Architect for fixes → Loop to 3.1
- APPROVED → Proceed to 3.3

### 3.3 Decomposition Assessment

**Goal**: Identify which architectural sections need detailed planning.

**Deploy Decomposition Assessor sub-agent:**
```
Assess architecture for decomposition.

Context:
- Architecture: /tmp/planning-[ts]/ARCHITECTURE.md

Write assessment to: /tmp/planning-[ts]/DECOMPOSITION.md

Instructions:
1. Read ARCHITECTURE.md
2. For each major section, evaluate:
   - Complexity: SIMPLE / MEDIUM / COMPLEX
   - Ambiguity: Could an agent implement directly? Or decisions needed?
   - Size: Estimated task count
3. Classify each section:
   - SIMPLE: Direct to tickets generation
   - COMPLEX: Needs detailed phase planning
4. Write decomposition report to file with:
   - Section list with line numbers and classifications
   - Rationale for each classification
   - Recommended planning approach

IMPORTANT: Write assessment to file, then return ONLY:
- Summary (2-3 sentences listing SIMPLE vs COMPLEX sections)
- File path written
- Status: COMPLETE
Do NOT return the full assessment content.
```

**Output format in DECOMPOSITION.md:**
```
Section 2: Database Schema (lines 23-45) - SIMPLE
  Rationale: Standard CRUD, no complex logic

Section 3: Authentication (lines 46-89) - COMPLEX
  Rationale: Multiple auth methods, security considerations

Section 4: API Endpoints (lines 90-134) - COMPLEX
  Rationale: 12+ endpoints, validation logic, error handling

Section 5: Error Handling (lines 135-156) - SIMPLE
  Rationale: Follow existing patterns
```

### 3.4 Detailed Phase Planning (MAP, Recursive)

**Goal**: Produce implementation-ready plans for complex sections.

**Setup:**
1. Create phases directory: `/tmp/planning-[ts]/phases/`
2. Deploy N sub-agents, one per complex section
3. Each agent works independently on their section

**Sub-Agent Prompt:**
```
Detailed planning for: [Section Name]

Context:
- Architecture: /tmp/planning-[ts]/ARCHITECTURE.md (lines X-Y)
- Research: /tmp/planning-[ts]/research/
- Adjacent sections: [list other section files for interface awareness]

Write plan to: /tmp/planning-[ts]/phases/[NN]-[section-name].md

Instructions:
1. Read your assigned section from ARCHITECTURE.md
2. Read relevant research files
3. Write detailed implementation plan to file containing:

   ## Overview
   [1-2 sentence summary]

   ## Tasks
   For each implementation task:
   ### Task N: [Title]
   - **Description**: What to implement
   - **Files**: Specific files to create/modify (with paths)
   - **Dependencies**: What must be done first (reference other tasks)
   - **Verification**: Executable commands to prove correctness

   ## Verification Commands
   For EVERY task, include commands the implementation agent can run:
   - Unit test commands
   - Integration test commands
   - Manual verification via curl/CLI
   - Log checks
   - State inspection queries

4. Complexity check: If any task spans multiple concerns or would require
   touching many unrelated files, note in the plan:

   ## Needs Further Decomposition
   - Task N: [reason - e.g., "mixes database and API concerns"]
   - Suggested split: [how to break it down by concern]

IMPORTANT: Write plan to file, then return ONLY:
- Summary (2-3 sentences: section covered, task count, any decomposition needed)
- File path written
- Status: COMPLETE or NEEDS_DECOMPOSITION
Do NOT return the plan content.
```

**Recursive Decomposition:**
If any agent reports sections needing further breakdown:
1. Split those sections into sub-sections
2. Deploy additional sub-agents for the splits
3. Merge results back into the phase plan
4. Repeat until all tasks are implementation-ready
5. Maximum 3 decomposition levels

### 3.5 Plan Integration

**Goal**: Merge all phase plans into coherent whole.

**Deploy Plan Integrator sub-agent:**
```
Integrate phase plans.

Context:
- Architecture: /tmp/planning-[ts]/ARCHITECTURE.md
- Phase plans: /tmp/planning-[ts]/phases/
- Feature name: [feature-name]

Write integrated plan to: docs/feature-plans/[feature-name]/

Instructions:
1. Read all phase plans in phases/
2. Check cross-phase consistency:
   - Interfaces align between phases?
   - No conflicting decisions?
   - Dependencies form a DAG?
3. Write integrated plan structure:
   - docs/feature-plans/[feature-name]/README.md (overview + task index)
   - docs/feature-plans/[feature-name]/phase-NN-name.md (each phase)
4. If issues found, note them

IMPORTANT: Write plan files, then return ONLY:
- Summary (2-3 sentences: files created, task count, any cross-phase issues)
- Output directory path
- Status + Recommendation: INTEGRATED or NEEDS_FIXES
Do NOT return the plan content.
```

**Gate Logic:**
- NEEDS_FIXES → Report issues to relevant phase planner → Loop to 3.4
- INTEGRATED → Proceed to 3.6

**For simple features**: Single file `docs/feature-plans/[feature-name].md` may suffice.

### 3.6 Plan Verification

**Goal**: Validate every task is implementation-ready with executable verification.

**Deploy Plan Verifier sub-agent:**
```
Verify plan implementation-readiness.

Context:
- Plan: docs/feature-plans/[feature-name]/

Write verification to: /tmp/planning-[ts]/PLAN_VERIFICATION.md

Instructions:
1. Read all plan files
2. For EVERY task, verify:
   - [ ] Clear description of what to implement
   - [ ] Specific file references (not "the auth module")
   - [ ] Explicit dependencies (or "none")
   - [ ] Executable verification commands
   - [ ] Verification requires no human involvement
   - [ ] Clear pass/fail criteria
3. Flag red flags:
   - "Test with users" → NOT executable
   - "Verify performance is acceptable" → NOT specific
   - "Check that it works" → NOT actionable
   - TODO/TBD placeholders → NOT ready
4. Write verification report to file with:
   - Tasks passing all checks
   - Tasks failing checks (with specific failures)
   - Recommendation: APPROVED or NEEDS_REVISION

IMPORTANT: Write verification to file, then return ONLY:
- Summary (2-3 sentences: pass/fail count, key issues if any)
- File path written
- Status + Recommendation: APPROVED or NEEDS_REVISION
Do NOT return the full verification content.
```

**Gate Logic:**
- NEEDS_REVISION → Report failing tasks to relevant phase planner → Loop to 3.4
- APPROVED → Proceed to Stage 4

---

## Stage 4: Cleanup

### 4.1 Artifact Cleanup

```bash
rm -rf /tmp/planning-[timestamp]/
```

This removes:
- Research reports (no longer needed)
- Wave results (no longer needed)
- Aggregation document (no longer needed)
- Phase working files (content moved to docs/)

### 4.2 Commit Plan

**Commit the generated plan documents:**
```bash
git add docs/feature-plans/[feature-name]/
git commit -m "docs: add [feature-name] implementation plan

- [X] phases covering [brief scope summary]
- Ready for review via reviewing-plans skill"
```

### 4.3 Completion Report

Summarize to user:
- Feature plan location: `docs/feature-plans/[feature]/`
- Total task count across phases
- Dependency structure overview
- Key decisions made during interview
- Commit hash for the plan
- **Next step**: Run `reviewing-plans` skill to refine, then `plan-to-tickets` to convert to tickets

---

## Executable Verification Commands

This is the most critical part of the workflow. Verification commands must be:

1. **Runnable immediately** by the implementation agent
2. **Self-contained** (no external dependencies)
3. **Deterministic** (same inputs → same outputs)
4. **Fast** (seconds to minutes, not hours)

**For comprehensive patterns and examples by domain, see:** `templates/verification.md`

### Quick Checklist

Sub-agents creating verification commands must ensure:
- [ ] Commands are copy-paste runnable
- [ ] Success/failure is clear from output
- [ ] No human judgment required
- [ ] No external services/people needed
- [ ] Expected outputs are documented

### What NOT to Include

- "Have QA verify" / "Get user feedback" → NOT executable
- "Make sure it works" / "Check that it's correct" → NOT specific
- "Ask tech lead to review" / "Wait for CI" → NOT autonomous
- "Monitor production" / "Test with 100 users" → NOT immediate

---

## Question Classification Guide

When gap analysis identifies questions, classify them correctly:

### RESEARCHABLE (don't ask user)

- "What's the current implementation?" → Read the code
- "How does X integrate with Y?" → Trace the code paths
- "What patterns does the project use?" → Examine existing code
- "What dependencies are needed?" → Check package files
- "How are similar features tested?" → Look at test files
- "What's the API signature?" → Read the source

### USER_INPUT (ask user)

- "Should we include X in MVP or defer?" → Scope decision
- "Which capability is higher priority?" → Priority choice
- "Approach A or B?" (when both are valid) → Preference
- "Is performance target X or Y?" → Requirements clarification
- "Should this be public API or internal?" → Design philosophy

### DEFERRABLE (don't ask, note in plan)

- "Should we use pattern A or B for this edge case?" → Implementation detail
- "How should we name this helper function?" → Implementation detail
- "Should this be one file or two?" → Implementation detail
- "What's the best error message?" → Implementation detail

---

## Troubleshooting

### Research keeps finding gaps
- Feature may be poorly defined → Ask ONE focused question to user
- Scope may be too large → Split into multiple features
- Domain may be unfamiliar → Accept higher research investment

### Too many questions for user
- Review classifications - are you escalating researchable questions?
- Batch related questions into single decision
- Accept more deferrable gaps

### Plans are too vague
- Decomposition didn't go deep enough → Force another round
- Architects thinking too abstractly → Provide concrete examples
- Ambiguity in requirements → Return to interview for that specific question

### Verification commands are non-executable
- Implementation agent doesn't have test infrastructure → Add task to create it
- Tests don't exist yet → First task in phase should create test scaffolding
- Can't test in isolation → Rethink component boundaries

### Main agent context filling up
- Prompts are too verbose → Trim to file references only
- Too many sub-agents → Batch into fewer, larger scopes
- Research too extensive → Aggregate more aggressively
- **Sub-agents returning full content instead of summaries** → Sub-agents must WRITE to files using Write tool, then return ONLY the brief summary format. If main agent is doing Write calls after sub-agent returns, sub-agent failed to write the file itself.

### Research waves won't terminate
- Set hard limit: Maximum 3 waves per stage
- Accept remaining gaps as DEFERRABLE
- Some ambiguity is acceptable - implementation can resolve

---

## Key Principles Summary

1. **Research before asking**: Never ask user what can be learned from code
2. **Waves fill gaps**: First research wave often reveals questions for next wave
3. **Classify questions rigorously**: Most questions are RESEARCHABLE or DEFERRABLE
4. **Post-interview research**: User responses reveal new areas to investigate
5. **Main agent = coordinator only**: Never reads files, never analyzes, only dispatches
6. **File references over content copying**: Keep prompts lightweight
7. **Sub-agents WRITE files themselves**: They use Write tool, then return only summary + path
8. **Sub-agents return summaries + paths**: Main agent sees status, not content (NEVER full content)
9. **Executable over descriptive**: Verification must be commands
10. **Maximum 3 iterations**: Waves, interview rounds, and decomposition levels all cap at 3
