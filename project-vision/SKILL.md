---
name: project-vision
description: Captures project vision and philosophy through structured interview, producing comprehensive vision documentation and condensed summary. Use before project-planning for new projects or major architectural work requiring design alignment. Ensures blockers and autonomous development can align with project goals.
---

# Project Vision Skill

## Overview

This skill conducts a structured interview to capture comprehensive project vision, philosophy, and design principles. It produces both detailed documentation and a condensed summary embedded in the project's CLAUDE.md file.

**Purpose**: Establish a "north star" for decision-making that makes architectural choices obvious and enables autonomous agents to resolve blockers without escalation.

**Use this skill BEFORE project-planning** for:
- New projects (before any planning or implementation)
- Major architectural changes (requires alignment with vision)
- Projects with recurring HUMAN-TASK escalations (missing decision context)

## Output Artifacts

1. **`docs/VISION.md`** - Comprehensive vision document (~2-5k tokens)
2. **`CLAUDE.md` update** - Condensed summary (1 paragraph) with pointer to full doc
3. **Quality reports** - Validation from three review passes

## Workflow

### Stage 1: Structured Interview

**Goal**: Extract complete vision through targeted questions across 6 dimensions.

**Interview Structure**:

#### 1. Problem Space
- What problem does this project solve?
- Who experiences this problem?
- How do they currently solve it (or why can't they)?
- What makes this solution better/different?

#### 2. Users & Use Cases
- Who are the primary users?
- What are the 3-5 core use cases?
- What user behaviors or workflows change?
- What should be easy? What should be hard/impossible?

#### 3. Success Criteria
- What does "done" look like?
- How will we measure success?
- What quality level is required (prototype vs production)?
- What's the timeline/scope?

#### 4. Design Philosophy
- What are the 3-5 guiding principles?
- What trade-offs have been pre-decided?
- When in doubt, optimize for what?
- Any non-negotiable constraints?

#### 5. Anti-goals
- What are we explicitly NOT trying to do?
- What features/complexity should be avoided?
- What use cases are out of scope?
- What would make this project a failure?

#### 6. Technical Constraints
- Platform/language/framework requirements (if any)
- Integration points with existing systems
- Performance/scale requirements
- Deployment constraints
- Security/compliance requirements

**Interview Process**:
1. Ask all questions in each section
2. Probe ambiguous answers with follow-ups
3. Request examples when answers are abstract
4. Clarify contradictions immediately
5. Continue until you can articulate the vision independently

**Output**: Structured notes covering all 6 dimensions (temp file for next stage)

### Stage 2: Draft Vision Document

**Goal**: Transform interview notes into comprehensive, well-structured vision document.

**Deploy Vision Writer sub-agent**:
```
Write comprehensive project vision document.

Context:
- Interview notes: /tmp/vision-[ts]/interview-notes.md
- Project directory: [path]

Output: /tmp/vision-[ts]/VISION-DRAFT.md

Instructions:
1. Read interview notes thoroughly
2. Produce vision document with this structure:

   # Project Vision: [Project Name]

   ## Problem Statement
   [1-2 paragraphs: problem, who has it, current solutions, why this is better]

   ## Users & Use Cases
   ### Primary Users
   [Description of user personas]

   ### Core Use Cases
   1. [Use case 1]: [Description]
   2. [Use case 2]: [Description]
   ...

   ## Success Criteria
   ### Definition of Done
   [What "complete" means for this project]

   ### Quality Bar
   [Production-ready? Prototype? Research vehicle?]

   ### Metrics
   [How we measure success]

   ## Design Philosophy
   ### Guiding Principles
   1. **[Principle 1]**: [Why this matters, what it means in practice]
   2. **[Principle 2]**: [Explanation]
   ...

   ### Key Trade-offs
   [Pre-decided trade-offs that resolve common decision points]

   ### Optimization Target
   [When in doubt, we optimize for: X over Y]

   ## Anti-goals
   [Explicitly out of scope - what NOT to do]
   - [Anti-goal 1]: [Why not]
   - [Anti-goal 2]: [Why not]

   ## Technical Constraints
   [Platform, integration, performance, deployment constraints]

   ## Decision Framework
   [How to make decisions aligned with this vision]
   - If [scenario], choose [approach] because [principle]
   - Example decision patterns based on philosophy

3. Write clearly and specifically (not vague platitudes)
4. Include concrete examples for abstract principles
5. Make trade-offs explicit (not implicit)
6. Length: 2-5k tokens (comprehensive but not exhaustive)

Return: Summary + file path
```

### Stage 3: Multi-Angle Review

**Goal**: Validate vision quality through three independent review passes.

**Deploy 3 concurrent review sub-agents**:

#### 3.1 Self-Consistency Reviewer
```
Review vision for internal consistency.

Context:
- Vision draft: /tmp/vision-[ts]/VISION-DRAFT.md

Output: /tmp/vision-[ts]/REVIEW-CONSISTENCY.md

Instructions:
1. Read vision document thoroughly
2. Check for contradictions:
   - Do principles conflict with each other?
   - Do success criteria align with problem statement?
   - Do anti-goals contradict stated use cases?
   - Do technical constraints conflict with philosophy?
3. Check for completeness:
   - Every section substantive (not placeholder)?
   - Principles actionable (not vague)?
   - Trade-offs explicit?
4. Flag ambiguities:
   - Terms used inconsistently?
   - Principles too abstract to apply?
   - Success criteria not measurable?

Produce report with:
- Contradictions found (with line references)
- Completeness gaps
- Ambiguities requiring clarification
- Recommendation: APPROVED / NEEDS_REVISION

Return: Summary + file path + status
```

#### 3.2 Gap Analyzer
```
Identify gaps in vision coverage.

Context:
- Vision draft: /tmp/vision-[ts]/VISION-DRAFT.md

Output: /tmp/vision-[ts]/REVIEW-GAPS.md

Instructions:
1. Read vision document
2. Generate follow-up questions for major gaps:
   - Missing user personas or use cases?
   - Unclear success metrics?
   - Principles without examples?
   - Important trade-offs not addressed?
   - Technical constraints under-specified?
3. Classify gaps:
   - CRITICAL: Blocks decision-making
   - IMPORTANT: Would improve clarity
   - NICE_TO_HAVE: Optional enhancement

Produce report with:
- Follow-up questions by category
- Rationale for each question
- Impact if left unresolved
- Recommendation: APPROVED / NEEDS_INTERVIEW

Return: Summary + file path + status
```

#### 3.3 PRIME DIRECTIVE Reviewer
```
Review vision for adherence to PRIME DIRECTIVE.

Context:
- Vision draft: /tmp/vision-[ts]/VISION-DRAFT.md
- PRIME DIRECTIVE: Read the project CLAUDE.md (Maximal Simplicity Policy)

Output: /tmp/vision-[ts]/REVIEW-PRIME-DIRECTIVE.md

Instructions:
1. Read the project CLAUDE.md PRIME DIRECTIVE section
2. Read vision document
3. Evaluate alignment:
   - Does philosophy emphasize simplicity over complexity?
   - Are principles about separation of concerns vs complecting?
   - Do trade-offs favor simple over clever?
   - Does decision framework guide toward simplicity?
4. Check for red flags:
   - Encouraging premature abstraction?
   - Conflating concerns in design principles?
   - Optimizing for "flexibility" over directness?
   - Framework-style patterns over simple solutions?

Produce report with:
- Alignment score: STRONG / MODERATE / WEAK
- Areas of strong alignment
- Areas of concern
- Suggested principle additions/modifications
- Recommendation: APPROVED / NEEDS_REVISION

Return: Summary + file path + status
```

**Parallelism**: Deploy all reviewers in single message via multiple Task calls.

**Gate Logic** (based on sub-agent reports):
- **All APPROVED** → Proceed to Stage 4
- **Any NEEDS_REVISION** → Make revisions → Re-review
- **NEEDS_INTERVIEW** → Conduct follow-up interview → Update draft → Re-review

### Stage 4: Finalize & Integrate

**Goal**: Write final vision document and embed summary in CLAUDE.md.

**Process**:

#### 4.1 Write Final Vision Document
```bash
# Incorporate review feedback
# Write to: docs/VISION.md
```

#### 4.2 Generate Condensed Summary

Create 1-paragraph summary for CLAUDE.md:
- **Problem** (1 sentence)
- **Solution approach** (1 sentence)
- **Key philosophy** (1 sentence)
- **Optimization target** (phrase)
- **Pointer** to full doc

**Example**:
```markdown
## Project Vision

my-project is a lightweight task runner emphasizing simplicity and composability. Core philosophy: prefer simple, separated concerns over clever abstractions; optimize for debuggability and comprehension over performance; make the straightforward path obvious. When in doubt, choose the approach with fewer moving parts. See [docs/VISION.md](docs/VISION.md) for complete vision and decision framework.
```

#### 4.3 Update CLAUDE.md

**If CLAUDE.md exists in project**:
- Add `## Project Vision` section after project description
- Include condensed summary
- Pointer to docs/VISION.md

**If no CLAUDE.md**:
- Create minimal CLAUDE.md with vision section
- Note this in completion report for user review

#### 4.4 Commit Vision Documents

```bash
git add docs/VISION.md CLAUDE.md
git commit -m "docs: capture project vision and philosophy

- Comprehensive vision document (problem, users, philosophy, constraints)
- Decision framework for autonomous development
- Embedded summary in CLAUDE.md"
```

### Stage 5: Completion Report

**Report to user**:
- Vision document location: `docs/VISION.md`
- CLAUDE.md updated with summary
- Review outcomes (consistency, gaps, PRIME DIRECTIVE alignment)
- Commit hash
- **Next step**: Ready for project-planning with vision alignment

## Integration with Other Skills

### project-planning
Research sub-agents should:
1. Read `CLAUDE.md` (gets condensed vision automatically)
2. Read `docs/VISION.md` for detailed context
3. Evaluate technical approaches against design philosophy

### investigating-blocker
Prior art research synthesis should:
1. Check industry approaches against project philosophy
2. Recommend solutions aligned with optimization targets
3. Flag when prior art conflicts with vision (escalate vs auto-resolve)

### reviewing-plans
Plan auditors should:
1. Verify features align with use cases
2. Check approaches match design principles
3. Validate decisions follow trade-off guidance

### autonomous-development
Implementation agents should:
1. Reference philosophy when choosing between approaches
2. Flag implementation choices that violate principles
3. Use decision framework for ambiguous cases

## Key Principles

1. **Interview before drafting**: Don't guess vision, extract it comprehensively
2. **Multi-angle review**: Catch contradictions, gaps, and anti-patterns early
3. **Concrete over abstract**: Principles must be actionable with examples
4. **PRIME DIRECTIVE alignment**: Vision should amplify simplicity policy
5. **Dual output**: Detailed doc for deep reference, summary for quick context
6. **Decision-enabling**: Vision should resolve common architectural questions

## Troubleshooting

### Interview yields vague answers
- Ask for concrete examples
- Request counter-examples (what NOT to do)
- Probe trade-offs (if X vs Y, which and why?)
- Ground in specific use cases

### Vision document too generic
- Add concrete examples for each principle
- Make trade-offs explicit with scenarios
- Include decision patterns based on actual choices
- Reference specific project constraints

### PRIME DIRECTIVE conflict detected
- Re-interview on simplicity philosophy
- Add/strengthen simplicity principles
- Make "simple over clever" explicit in trade-offs
- Add anti-goals against premature abstraction

### Reviewers find critical gaps
- Conduct targeted follow-up interview
- Don't guess - ask user directly
- Update draft comprehensively
- Re-run full review cycle

## Context Management

**Main agent**:
- Conducts interview directly (only hands-on work)
- Dispatches sub-agents with file references
- Routes review feedback to revision

**Sub-agents**:
- Return summary + file path (not full content)
- Keep prompts under 500 tokens
- Use temp directory for coordination

**Temp structure**:
```
/tmp/vision-[timestamp]/
├── interview-notes.md     # Structured interview output
├── VISION-DRAFT.md        # Initial draft
├── REVIEW-*.md            # Review reports
└── VISION-FINAL.md        # Revised version (if needed)
```

## Success Criteria

Vision document is complete when:
- [ ] All 6 dimensions covered comprehensively
- [ ] Principles are specific and actionable
- [ ] Examples provided for abstract concepts
- [ ] Trade-offs made explicit
- [ ] No contradictions between sections
- [ ] PRIME DIRECTIVE alignment strong
- [ ] Decision framework enables autonomous resolution
- [ ] Condensed summary captures essence
- [ ] Committed to git with proper message

## Example Vision Section for CLAUDE.md

```markdown
## Project Vision

my-saas is a B2B analytics platform for small businesses, prioritizing rapid iteration and customer learning over scale. Core philosophy: ship early, learn from users, consolidate based on evidence; optimize for time-to-insight over performance; embrace manual processes until automation pays for itself. Pre-alpha risk tolerance allows breaking changes. When facing build-vs-buy, prefer battle-tested external services over custom code. See [docs/VISION.md](docs/VISION.md) for complete vision, use cases, and decision framework.
```

This gives autonomous agents immediate context while keeping CLAUDE.md scannable.
