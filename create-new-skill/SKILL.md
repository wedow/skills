---
name: create-new-skill
description: Creates new Claude Code agent skills with proper structure, frontmatter, and best practices. Use when the user wants to create a new skill, add capabilities, or extend Claude with domain-specific expertise.
---

# Creating New Agent Skills

## Overview

Agent Skills are modular, filesystem-based capabilities that provide Claude with domain-specific expertise. They use progressive disclosure to load information efficiently:

- **Level 1 - Metadata**: YAML frontmatter (~100 tokens, always loaded)
- **Level 2 - Instructions**: Main SKILL.md content (~5k tokens, loaded when relevant)
- **Level 3 - Resources**: Additional files (loaded on-demand)

## Skill Creation Workflow

### 1. Plan the Skill

Before creating files, determine:

- **Purpose**: What specific problem does this skill solve?
- **Scope**: What's the minimal useful functionality?
- **Triggers**: When should Claude activate this skill?
- **Resources**: What additional files are needed (scripts, templates, references)?

### 2. Create Skill Structure

```bash
# For global skills (available in all projects)
cd ~/.claude/skills
mkdir skill-name
cd skill-name

# For project-specific skills
cd /path/to/project/.claude/skills
mkdir skill-name
cd skill-name
```

### 3. Write SKILL.md with Frontmatter

Every skill requires a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: skill-name
description: Brief description of what the skill does and when to use it (max 1024 chars)
---

# Skill Name

[Your skill content here]
```

**Naming Rules:**
- Use lowercase letters, numbers, and hyphens only
- Maximum 64 characters
- Use gerund form (verb + -ing): `processing-pdfs`, `analyzing-data`
- Be descriptive and searchable

**Description Rules:**
- Write in third person
- Include BOTH what it does AND when to use it
- Be specific, not vague
- Good: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDFs or when the user mentions document extraction."
- Bad: "Helps with documents"

### 4. Structure the Content

Keep SKILL.md under 500 lines. Use this pattern:

```markdown
---
name: your-skill
description: Your description here
---

# Skill Title

## Overview
Brief introduction (2-3 sentences)

## When to Use This Skill
- Clear trigger scenarios
- Specific use cases

## Key Concepts
Only information Claude cannot infer

## Workflows

### Common Task 1
1. Step-by-step instructions
2. With concrete examples
3. Include validation checks

### Common Task 2
1. Another workflow
2. With checklists
3. Error handling guidance

## Examples

### Example 1: [Descriptive Title]
**Input:**
```
[Input example]
```

**Expected Output:**
```
[Output example]
```

**Process:**
1. Steps taken
2. Decisions made

## Reference Files
- [Additional Documentation](./reference.md) - When to use this
- [Script Reference](./scripts/helper.py) - What this does
```

### 5. Add Supporting Resources (Optional)

Create additional files as needed:

```bash
# Reference documentation (linked from SKILL.md)
touch reference.md
touch advanced-guide.md

# Utility scripts
mkdir scripts
touch scripts/validator.py
chmod +x scripts/validator.py

# Templates or examples
mkdir templates
touch templates/example-output.txt
```

**Important:**
- Keep references one level deep (don't nest too deeply)
- Use forward slashes in paths: `scripts/helper.py` not `scripts\helper.py`
- For files over 100 lines, include a table of contents
- Scripts should solve problems, not punt to Claude

### 6. Test the Skill

Test iteratively with two Claude instances:

1. **Development instance**: Refine the skill content
2. **Testing instance**: Use the skill as a user would

Observe:
- Does Claude load the skill at the right times?
- Are instructions clear and sufficient?
- Does Claude navigate files in the expected order?
- Are examples helpful and representative?

### 7. Refine Based on Testing

Common improvements:
- Add missing examples where Claude struggled
- Clarify ambiguous instructions
- Add validation steps for error-prone operations
- Move detailed content to reference files
- Add table of contents to long files

## Best Practices Checklist

### Content
- [ ] Concise: Only information Claude cannot infer
- [ ] Specific: Match detail level to task fragility
- [ ] Concrete: Include input/output examples
- [ ] Consistent: Use same terminology throughout
- [ ] Current: No outdated information

### Structure
- [ ] Progressive disclosure: Main file is table of contents
- [ ] References one level deep from SKILL.md
- [ ] Files over 100 lines have table of contents
- [ ] Domain-organized for focused loading

### Workflows
- [ ] Sequential steps with checklists
- [ ] Validation feedback loops
- [ ] Plan-validate-execute pattern for complex tasks
- [ ] Clear error handling guidance

### Code & Scripts
- [ ] Scripts handle errors explicitly
- [ ] No "voodoo constants" - justify all numbers
- [ ] Clear whether to execute or read as reference
- [ ] Required packages listed explicitly

### Metadata
- [ ] Name: lowercase, hyphens, gerund form, max 64 chars
- [ ] Description: third person, includes triggers, max 1024 chars
- [ ] Forward slashes in all paths
- [ ] Tested with target model(s)

## Common Pitfalls to Avoid

❌ **Don't:**
- Explain concepts Claude already knows
- Offer too many options without clear guidance
- Use Windows-style paths (backslashes)
- Nest references deeply
- Include time-sensitive information
- Use inconsistent terminology
- Skip validation steps
- Assume packages are installed

✅ **Do:**
- Assume Claude's competence
- Provide one recommended approach with escape hatches
- Use forward slashes universally
- Keep references one level deep
- Mark outdated content clearly in `<details>` tags
- Pick one term per concept
- Build validation into workflows
- List required dependencies explicitly

## Quick Start Template

Use this minimal template to get started:

```markdown
---
name: your-skill-name
description: What it does and when to use it (be specific)
---

# Skill Title

## When to Use
- Trigger scenario 1
- Trigger scenario 2

## Basic Workflow

1. **Step 1**: What to do
   ```bash
   # Example command
   ```

2. **Step 2**: Next action
   - Validation checkpoint
   - Error handling

3. **Step 3**: Final step
   - Expected outcome

## Example

**Scenario:** [Description]

**Steps:**
1. Action 1
2. Action 2
3. Result

## Reference
- [Additional docs](./reference.md) if needed
```

## Skill Locations

**Global skills** (all projects):
```
~/.claude/skills/skill-name/SKILL.md
```

**Project skills** (specific project):
```
/path/to/project/.claude/skills/skill-name/SKILL.md
```

## Resources

For more details on Claude Code skills, see the official Anthropic documentation at https://docs.anthropic.com.
