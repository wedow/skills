# Agent Coordination Patterns

## The Delegation Model

### Main Agent Role
- **Coordinator and overseer**, not hands-on implementer
- Understands user's request and plans work
- Creates and delegates to subagents with focused tasks
- Monitors progress and coordinates results
- Ensures adherence to core directives

### Subagent Role
- **Focused executor**, not decision maker
- Executes concrete tasks with clear specifications
- Works with code (read, write, test, debug)
- Reports results clearly and concisely
- Does not make architectural decisions

## Subagent Initialization Protocol

### Mandatory First Steps
**Every subagent that interacts with code MUST do this FIRST:**

1. **Read global guidelines**:
   ```
   Read ~/CLAUDE.md to understand:
   - PRIME DIRECTIVE (maximal simplicity policy)
   - Development environment setup
   - File editing best practices
   ```

2. **Read project-specific guidance**:
   ```
   Read [PROJECT]/CLAUDE.md to understand:
   - Project-specific architecture and naming
   - Code organization
   - Testing strategy and commands
   - Key design decisions
   ```

3. **Only then proceed** with the delegated task

### Subagent Task Template
```
IMPORTANT: Before starting work:
1. Read ~/CLAUDE.md (sections on change policy and best practices)
2. Read [PROJECT]/CLAUDE.md (if applicable)
3. Only then proceed with the task

Task: [your specific, focused request]

Constraints:
- Follow PRIME DIRECTIVE (maximal simplicity)
- Maintain TDD workflow
- Do not commit unless explicitly requested
- Report specific results and any issues

Expected output: [what the agent should report back]
```

## Coordination Patterns

### Implementation-Verification Loop
1. **Implementation Agent**: Executes focused task
2. **Verification Agent**: Reviews implementation for:
   - PRIME DIRECTIVE compliance (simplicity, no complecting)
   - Build compilation and test passing
   - Style check compliance
3. **Iteration**: If issues found, dispatch correction agent
4. **Completion**: Mark TODO complete, proceed to next item

### Explorer Agent Deployment
Use for:
- Understanding current codebase state
- Researching specific implementation questions
- Finding relevant files and patterns
- Analyzing architecture and dependencies

### Final Verification Agent
Deploy before completion to ensure:
- PRIME DIRECTIVE compliance (simplest implementation)
- Build and tests pass cleanly
- All requirements met
- Ready for issue closure and commit

## Error Handling in Coordination

### When Implementation Fails
- **Analyze failure**: Determine root cause
- **Clarify requirements**: Provide more specific instructions
- **Break down further**: Split complex tasks into smaller units
- **Provide examples**: Show expected patterns and outputs

### When Verification Fails
- **Document issues clearly**: Specific problems and locations
- **Provide correction guidance**: Exact changes needed
- **Re-verify**: Ensure corrections resolve all issues
- **Learn patterns**: Update future task instructions

## Communication Patterns

### Clear Task Boundaries
- **Single focus**: Each task should have one clear objective
- **Specific deliverables**: Define expected outputs
- **Explicit constraints**: List limitations and requirements
- **Clear success criteria**: Define when task is complete

### Status Reporting
- **Specific results**: Report exactly what was accomplished
- **Issues encountered**: Document problems and solutions
- **Next steps**: Suggest follow-up actions if needed
- **Resource references**: Point to relevant files or documentation

## Quality Assurance in Coordination

### Multi-Level Review
1. **Self-check**: Subagent verifies own work
2. **Peer review**: Verification agent checks implementation
3. **Final review**: Main agent ensures overall quality
4. **Integration check**: Verify work fits with existing codebase

### Consistency Maintenance
- **Follow established patterns**: Use existing conventions
- **Maintain naming standards**: Follow project guidelines
- **Preserve architectural decisions**: Don't deviate from design
- **Keep documentation current**: Update relevant files

## Efficient Coordination Strategies

### Parallel Execution
- **Independent tasks**: Run multiple subagents simultaneously
- **Different focus areas**: Explorer + implementation in parallel
- **Resource optimization**: Maximize agent utilization
- **Reduced wait time**: Minimize sequential dependencies

### Iterative Refinement
- **Small increments**: Break large tasks into small steps
- **Quick feedback**: Verify each step before proceeding
- **Course correction**: Adjust approach based on results
- **Progressive completion**: Build toward final solution