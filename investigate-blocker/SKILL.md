---
name: investigate-blocker
description: Autonomously investigates REQUIRES-INVESTIGATION tasks through deep parallel research (internal and external), synthesizes findings, and either resolves with an actionable task or escalates to HUMAN-TASK when genuine human judgment is needed. Use when autonomous-development creates investigation tasks.
---

# Investigate Blocker Skill

## Purpose

Autonomously resolve blockers that require deeper investigation before implementation can proceed. This skill bridges the gap between "I'm stuck" and "wait for human" by performing thorough research to find answers.

## Operating Model

**IMPORTANT:** Always run `tk help` first to confirm current command syntax.

**Designed for headless operation within the autonomous loop:**

```bash
while true; do
  # Check for investigation tasks (grep tk ready output for title patterns)
  if tk ready 2>/dev/null | grep -q "REQUIRES-INVESTIGATION:"; then
    claude -p "Use investigate-blocker skill"
  else
    claude -p "Use autonomous-development skill"
  fi

  sleep 2
done
```

**Key principle:** This skill exists to find answers. It searches wherever answers exist—codebase, documentation, web, standards—based on what the problem requires.

---

## Core Principle: Contextual Research Scope

Research scope is **entirely determined by the nature of the problem**:

| Problem Type | Research Scope |
|--------------|----------------|
| Project-internal confusion | Codebase only |
| Library/framework question | Fetch official docs |
| Browser/platform API | MDN, platform docs |
| Industry convention | Web search for standards |
| Recent feature (post-training) | Active web research required |
| Integration question | Both internal patterns + external docs |

**The goal is answers. Get them from wherever they exist.**

---

## Decision Threshold (CRITICAL)

**Only resolve when the answer is clear and well-supported.**

Resolve if:
- Multiple research angles converge on the same conclusion
- No significant gaps in understanding remain
- No unresolved contradictions
- High confidence in the recommendation

Escalate to HUMAN-TASK if:
- Genuine ambiguity remains after thorough research
- Decision is subjective or business-critical (not technical)
- Research revealed conflicting valid approaches with no clear winner
- Missing context that only a human can provide
- The question is fundamentally about intent, not implementation

**Conservative default:** When uncertain, escalate. Incorrect autonomous decisions are costly.

---

## Main Agent Role (CRITICAL)

**You are a COORDINATOR.** You dispatch sub-agents and route information.

**Your responsibilities:**
- Find and extract REQUIRES-INVESTIGATION tasks
- Dispatch research sub-agents with clear focus areas
- Route findings between phases
- Make the final resolve/escalate decision based on sub-agent reports
- Create appropriate tickets for resolution

**You NEVER:**
- Read files directly (sub-agents do this)
- Perform web searches directly (sub-agents do this)
- Analyze code yourself
- Make technical judgments without sub-agent research

---

## Workflow Overview

```
1. EXTRACTION
   - Find REQUIRES-INVESTIGATION ticket(s)
   - Extract context, dependency chain, specific questions

2. SCOPING
   - Classify blocker type
   - Determine research scope (internal, external, or both)
   - Define specific questions to answer

3. RESEARCH FAN-OUT (parallel)
   - Deploy research sub-agents based on scope
   - Internal: codebase patterns, constraints, history
   - External: docs, standards, web (as needed)

3.5. PRIOR ART RESEARCH (when design questions detected)
   - Deploy parallel sub-agents to research how industry/community solved this
   - Search specifications, academic papers, major implementations
   - Determine consensus level (unanimous, majority, split, none)
   - Synthesize findings with confidence assessment

4. SYNTHESIS
   - Aggregate findings (including prior art if gathered)
   - Identify viable options
   - Evaluate against project constraints
   - Rank recommendations

5. RESOLUTION
   - If clear winner: create actionable task
   - If still ambiguous: create HUMAN-TASK with findings
   - Update dependency chain

6. EXIT
   - Report outcome
   - STATUS: RESOLVED or ESCALATED
```

---

## Stage 1: Extraction

### Find Investigation Tasks

```bash
tk query '.[] | select(.title | startswith("REQUIRES-INVESTIGATION:"))'
```

### Extract Context

**Deploy Extraction sub-agent:**
```
Extract investigation context.

Task ID: [investigation-task-id]

Instructions:
1. Run: tk show [investigation-task-id]
2. Parse the task to extract:
   - The specific question or confusion
   - What was being worked on when this arose
   - Any context provided in the description
3. Run: tk dep tree [investigation-task-id]
4. Identify what work is blocked waiting for resolution
5. Check if related tasks provide additional context

Return:
- Core question (1-2 sentences)
- Context summary
- Blocked work list
- Any clues about research direction
```

---

## Stage 2: Scoping

### Classify Blocker Type

**Deploy Scoping sub-agent:**
```
Classify and scope the investigation.

Context: [extraction summary]

Instructions:
1. Classify the blocker type:
   - DESIGN_DECISION: Multiple valid approaches, need to pick one
   - MISSING_INFORMATION: Something unknown about requirements/constraints
   - TECHNICAL_UNCERTAINTY: Unclear how to implement something
   - EXTERNAL_DEPENDENCY: Question about library/API/platform behavior
   - CONFLICTING_CONSTRAINTS: Requirements seem incompatible

2. Determine research scope:
   - INTERNAL_ONLY: Answer exists within project codebase/docs
   - EXTERNAL_ONLY: Answer requires external documentation/standards
   - HYBRID: Needs both internal patterns AND external guidance

3. Define specific research questions (2-5 questions that, if answered, resolve the blocker)

Return:
- Blocker classification
- Research scope
- Specific questions to answer
- Recommended research angles
```

---

## Stage 3: Research Fan-Out

### Deploy Research Sub-Agents Based on Scope

**Internal Research (when scope includes INTERNAL):**

```
Research: Internal codebase patterns for [topic]

Questions to answer:
1. [Specific question]
2. [Specific question]

Instructions:
1. Read ~/CLAUDE.md and project CLAUDE.md first
2. Search for existing implementations of similar functionality
3. Look for documented decisions or constraints
4. Check for related tests that reveal expected behavior
5. Find any prior art or historical context

Return:
- Findings organized by question
- Relevant file paths with line numbers
- Patterns discovered
- Constraints identified
- Gaps (questions that couldn't be answered internally)
```

**External Research (when scope includes EXTERNAL):**

```
Research: External documentation for [topic]

Questions to answer:
1. [Specific question]
2. [Specific question]

Instructions:
1. Identify the authoritative sources for this topic:
   - Official library/framework documentation
   - Platform docs (MDN for web APIs, etc.)
   - RFCs or specifications (if standards-based)
   - Reputable technical resources
2. Fetch and analyze relevant documentation
3. Look for recommended practices or patterns
4. Note any version-specific considerations
5. Find concrete examples if available

Return:
- Findings organized by question
- Source URLs
- Recommended approaches from authoritative sources
- Caveats or version considerations
- Gaps (questions that couldn't be answered externally)
```

**Industry Standards Research (when needed):**

```
Research: Industry standards and conventions for [topic]

Instructions:
1. Search for established patterns and best practices
2. Look for security considerations (OWASP, etc. if relevant)
3. Find performance or scalability guidance
4. Check for common pitfalls to avoid
5. Note any consensus vs. contested approaches

Return:
- Established conventions found
- Security/performance considerations
- Common pitfalls
- Sources (prioritize authoritative over blog posts)
```

### Parallel Deployment

Deploy all relevant research sub-agents in a single message with multiple Task calls.

---

## Stage 3.5: Prior Art Research (CRITICAL FOR DESIGN QUESTIONS)

**When to use this stage:**
When the investigation involves architectural decisions, design patterns, or fundamental implementation approaches - especially when Stage 3 research reveals multiple valid options without a clear winner.

**Key principle:** Most problems have been solved before. Before escalating design questions to HUMAN-TASK, search for how the broader community/industry has tackled similar challenges.

### Detect Design Questions

If synthesis of Stage 3 research shows:
- Multiple competing approaches with different trade-offs
- Fundamental architectural or semantic questions
- Questions about "correct" behavior in established domains
- Uncertainty about industry conventions or standards

→ Deploy prior art research before deciding to escalate.

### Deploy Prior Art Research Sub-Agents

**Fan out multiple research agents in parallel**, each targeting different aspects of prior art:

```
Research: Prior art for [problem domain] - [specific aspect]

Context:
- Core question: [the design question]
- Domain: [e.g., "programming language semantics", "distributed systems", "authentication flows"]
- Current findings: [summary from Stage 3]

Instructions:
1. Search for how established systems/projects handle this:
   - Academic papers and technical literature
   - Well-known open source implementations
   - Industry standards and RFCs
   - Language specifications (if applicable)
   - Platform documentation from major vendors

2. For each approach found:
   - Document the design choice made
   - Extract the rationale (why they chose this approach)
   - Note trade-offs or limitations mentioned
   - Identify if there's consensus or variation

3. Look specifically for:
   - **Consensus patterns**: Do most implementations converge on one approach?
   - **Historical evolution**: Did the community try approach A then move to B?
   - **Known pitfalls**: Are there documented failures or anti-patterns?
   - **Performance/security implications**: What do the experts say?

4. Evaluate source quality:
   - Prioritize: specifications, academic papers, major OSS projects, authoritative docs
   - De-prioritize: blog posts, tutorials, Stack Overflow (unless corroborating)
   - Note publication dates (recent vs historical)

Return:
- Summary of approaches found across the ecosystem
- Level of consensus (unanimous, majority, split, no clear pattern)
- Recommended approach based on prior art with supporting evidence
- Caveats or contexts where recommendations differ
- Quality of sources (how authoritative is this finding?)
```

**Deploy 3-5 parallel research agents**, each exploring different angles:
- Different implementations (e.g., "Smalltalk-80", "Pharo", "GNU Smalltalk")
- Different aspects (e.g., "compile-time semantics", "runtime behavior", "scope resolution")
- Different source types (e.g., specifications, implementations, academic research)

### Synthesis of Prior Art

After prior art research completes, deploy a **prior art synthesis sub-agent**:

```
Synthesize prior art research findings.

Context:
- Original question: [from extraction]
- Internal/external research: [summary from Stage 3]
- Prior art research: [file paths to all prior art reports]

Instructions:
1. Read all prior art research reports
2. Determine consensus level:
   - UNANIMOUS: All major implementations agree
   - STRONG_MAJORITY: >75% converge on one approach
   - WEAK_MAJORITY: >50% but significant variation
   - SPLIT: Multiple competing approaches, no clear winner
   - NO_PATTERN: Insufficient data or highly context-specific

3. If consensus exists:
   - State the consensus approach clearly
   - Document the rationale from literature
   - Note any contexts where it doesn't apply
   - HIGH CONFIDENCE → likely can resolve autonomously

4. If split or no pattern:
   - Document the competing approaches
   - Extract decision criteria used by different implementations
   - Identify if our project constraints favor one approach
   - LOWER CONFIDENCE → may need escalation

5. Integration check:
   - Does the prior art approach align with our project patterns?
   - Are there constraints that make the standard approach unsuitable?
   - What adaptation would be needed?

6. Vision alignment (if docs/VISION.md exists):
   - Read the project vision document
   - Check if prior art approach aligns with design philosophy
   - Verify compatibility with stated optimization targets
   - Flag if prior art contradicts anti-goals
   - If consensus approach conflicts with vision, note the tension
   - Consider if vision provides tiebreaker for SPLIT consensus

Return:
- Consensus level and confidence
- Recommended approach based on prior art
- Vision alignment assessment (if applicable)
- How this integrates with earlier research findings
- Updated resolution assessment (CLEAR_RESOLUTION vs NEEDS_HUMAN)
```

### Decision Impact

After prior art synthesis:

**If consensus is UNANIMOUS or STRONG_MAJORITY:**
- Proceed to Stage 4 with high confidence
- Likely outcome: CLEAR_RESOLUTION with prior art supporting the decision
- Document the consensus in resolution task

**If consensus is SPLIT or NO_PATTERN:**
- Proceed to Stage 4 but with lower resolution threshold
- Likely outcome: ESCALATED with well-researched options
- Include prior art findings in HUMAN-TASK for informed decision

**Key principle:** Prior art doesn't remove human judgment for business decisions, but it can autonomously resolve technical questions that have established industry answers.

---

## Stage 4: Synthesis

**Deploy Synthesis sub-agent:**
```
Synthesize research findings.

Context:
- Original question: [from extraction]
- Blocker type: [from scoping]
- Research findings: [file paths to all research reports]
- Prior art findings: [file paths if Stage 3.5 was performed]

Instructions:
1. Read all research report files (internal, external, AND prior art if available)

2. For each original question:
   - What answer emerged from project research?
   - What answer emerged from prior art (if researched)?
   - How confident? (HIGH/MEDIUM/LOW)
   - Any contradictions between sources?
   - Does prior art consensus strengthen or weaken confidence?

3. Identify viable options:
   - What approaches are supported by research?
   - What approaches have industry consensus (from prior art)?
   - What are the trade-offs of each?

4. Evaluate each option against:
   - Alignment with existing project patterns
   - Industry consensus (if prior art research was performed)
   - Simplicity (PRIME DIRECTIVE)
   - Risk and complexity
   - Future flexibility
   - Security implications (if relevant)

5. Produce ranked recommendations:
   - #1 recommendation with rationale
   - Supporting evidence (internal patterns + prior art consensus if applicable)
   - Alternatives with trade-offs
   - Any remaining uncertainties

6. Make resolution assessment:
   - CLEAR_RESOLUTION: One option is clearly correct (especially if prior art shows unanimous consensus)
   - VIABLE_OPTIONS: Multiple good options, slight preference for one
   - STILL_AMBIGUOUS: Research didn't resolve the core question
   - NEEDS_HUMAN: Question is subjective/business-critical

Return:
- Summary of findings (including prior art consensus level if researched)
- Ranked options with trade-offs
- Resolution assessment
- Recommended action
```

---

## Stage 5: Resolution

### Based on Synthesis Assessment

**CLEAR_RESOLUTION or VIABLE_OPTIONS → Create Actionable Task:**

```bash
# Create the resolution task
tk create "[Original feature]: [Specific implementation]" \
  --type task \
  --priority [same as investigation task] \
  --description "$(cat <<'EOF'
## Summary
[What to implement based on research findings]

## Decision Made
[The approach chosen and why]

## Research Context
[Key findings that support this decision]

## Implementation Notes
[Specific guidance for implementation]

## Files
[Files to create/modify]

## Verification
[How to verify the implementation is correct]
EOF
)"

# Link dependencies: new task blocks what investigation was blocking
tk dep [blocked-task-id] [new-task-id]

# Close the investigation task
tk close [investigation-task-id]
```

**STILL_AMBIGUOUS or NEEDS_HUMAN → Escalate to HUMAN-TASK:**

```bash
# Create narrower HUMAN-TASK with synthesized findings
tk create "HUMAN-TASK: [Specific decision needed]" \
  --type task \
  --priority 0 \
  --description "$(cat <<'EOF'
## Decision Needed
[Specific question for human - much narrower than original]

## Research Performed
[Summary of investigation done]

## Options Identified

### Option A: [Name]
- Description: [what this approach involves]
- Pros: [advantages]
- Cons: [disadvantages]
- Supported by: [which research]

### Option B: [Name]
- Description: [what this approach involves]
- Pros: [advantages]
- Cons: [disadvantages]
- Supported by: [which research]

## Why Escalation is Needed
[Explain why autonomous resolution wasn't possible]

## Recommendation
[If you have a slight preference, state it with caveats]
EOF
)"

# Update dependencies
tk dep [blocked-task-id] [new-human-task-id]

# Close original investigation task
tk close [investigation-task-id]
```

---

## Stage 6: Exit

### Session Summary Format

```markdown
# INVESTIGATE-BLOCKER SESSION SUMMARY

## Task Investigated
- **ID:** [investigation-task-id]
- **Question:** [original question]

## Research Performed
- **Scope:** [INTERNAL_ONLY | EXTERNAL_ONLY | HYBRID]
- **Sub-agents deployed:** [count]
- **Sources consulted:** [list key sources]

## Findings Summary
[2-3 sentence summary of what was learned]

## Resolution
- **Status:** [RESOLVED | ESCALATED]
- **Action taken:** [created task X | created HUMAN-TASK Y]
- **Rationale:** [why this resolution]

## Dependency Updates
- Closed: [investigation-task-id]
- Created: [new-task-id or human-task-id]
- Now unblocked: [list of tasks that can proceed]

---
EXIT_STATUS: [RESOLVED|ESCALATED|ERROR]
```

---

## Key Principles

### 1. Answers From Anywhere

Don't limit research artificially. If the answer is in MDN, fetch MDN. If it's in a library's GitHub issues, search there. The goal is resolution.

### 2. Conservative Resolution Threshold

Only resolve autonomously when confident. A wrong autonomous decision creates more work than an escalation.

### 3. Narrower Escalations

When escalating, the HUMAN-TASK should be more specific than the original REQUIRES-INVESTIGATION. Include:
- Synthesized research (human doesn't start from zero)
- Concrete options (not open-ended)
- Trade-off analysis
- Recommendation if possible

### 4. Dependency Chain Integrity

Always update the dependency chain:
- New resolution task blocks whatever the investigation was blocking
- Close the investigation task with clear reason
- Verify with `tk dep tree` that structure is correct

### 5. No Partial Resolutions

Either fully resolve (actionable task) or fully escalate (HUMAN-TASK). Don't leave investigation tasks open or create ambiguous tasks.

---

## Troubleshooting

### Research doesn't converge
- The question may be genuinely ambiguous → Escalate with options
- May need different research angles → Try alternative sources
- Question may be too broad → Break into sub-questions

### Can't find external documentation
- Library may be poorly documented → Look for source code, issues, examples
- May be too new → Check release notes, changelogs
- May be internal/proprietary → Fall back to internal research only

### Contradictory information found
- Different sources may target different versions → Note version context
- May reflect genuine controversy → Escalate with both positions
- May be outdated information → Prefer recent authoritative sources

### Investigation task lacks context
- Original creation was too vague → Create narrower REQUIRES-INVESTIGATION
- Check dependency chain for context clues
- Look at related closed tasks for history

---

## Integration with Autonomous Loop

This skill is part of the two-tier escalation system:

```
autonomous-development
  ↓ (hits confusion)
Creates: REQUIRES-INVESTIGATION task
  ↓
investigate-blocker
  ↓
├─ RESOLVED → actionable task → autonomous-development continues
└─ ESCALATED → HUMAN-TASK → loop pauses for human input
```

The bash loop handles skill selection:

```bash
while true; do
  INVESTIGATION_COUNT=$(tk query '[.[] | select(.title | startswith("REQUIRES-INVESTIGATION:"))] | length' 2>/dev/null || echo "0")

  if [ "$INVESTIGATION_COUNT" -gt 0 ]; then
    echo "Investigation task found, running investigate-blocker..."
    claude -p "Use investigate-blocker skill" || break
  else
    claude -p "Use autonomous-development skill" || break
  fi

  sleep 2
done
```
