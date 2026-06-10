---
name: write-a-skill
description: Create or revise portable SKILL.md agent skills with clear activation rules, progressive disclosure, and optional bundled resources. Use when the user asks to create, write, update, improve, audit, or debug an agent skill, SKILL.md file, skill folder, workflow skill, or reusable agent capability.
---

# Write A Skill

Create skills as small, portable runbooks that an agent can discover from metadata, load when relevant, and execute without needing repeated explanation.

## Process

1. **Define the activation contract**
   - Name the skill with lowercase letters, digits, and hyphens only.
   - Keep the folder name and frontmatter `name` identical.
   - Write `description` as: what the skill does + when to use it.
   - Include the phrases, task types, file types, or contexts users will naturally say.
   - Avoid host-specific setup paths or platform names unless the skill is truly platform-specific.
   - Avoid XML angle brackets in frontmatter.

2. **Choose the smallest useful structure**
   - Default to one `SKILL.md` when the workflow is short.
   - Add `references/` for detailed docs, rubrics, schemas, or variant-specific guidance loaded only when needed.
   - Add `scripts/` for deterministic, repeated, or fragile operations that should not be regenerated from scratch.
   - Add `assets/` for templates or files copied into outputs.
   - Keep references one level deep and link each one directly from `SKILL.md`.

3. **Write the runbook**
   - Start with the purpose and expected output.
   - List the concrete workflow in the order the agent should perform it.
   - State decision points, safety boundaries, and when to ask the user.
   - Link optional references with clear load conditions, for example: "For API pagination details, read `references/api.md`."
   - Include a short validation checklist.

4. **Validate and test**
   - Confirm the file is named exactly `SKILL.md`.
   - Confirm frontmatter YAML parses.
   - Confirm `name` matches the parent folder and is under 64 characters.
   - Confirm `description` is under 1024 characters and includes specific triggers.
   - Run two or three realistic user prompts: one that should trigger, one adjacent task that should not, and one explicit invocation.

## Recommended Structure

```text
skill-name/
├── SKILL.md
├── references/
│   └── detailed-guidance.md
├── scripts/
│   └── helper.sh
└── assets/
    └── template.md
```

Only create folders that are needed for the skill. Do not add README, changelog, install guide, or other auxiliary documentation unless the skill itself needs them as an asset or reference.

## SKILL.md Template

```md
---
name: skill-name
description: Does a specific capability. Use when the user asks to "trigger phrase", "related phrase", or work with specific files/domains.
---

# Skill Name

One sentence describing the outcome this skill should produce.

## Workflow

1. Gather the minimum context needed.
2. Follow the domain-specific steps.
3. Use bundled references or scripts only when their load condition applies.
4. Validate the output before finishing.

## References

- `references/example.md`: Read when the task needs [specific condition].

## Validation

- [ ] Output matches the user's requested format.
- [ ] No placeholders or stale assumptions remain.
- [ ] Any scripts used were necessary and safe for the task.
```

## Description Rules

Treat `description` as the trigger condition, not marketing copy.

Good descriptions:

- Say exactly what the skill does.
- Include "Use when..." with realistic user wording.
- Mention important file types, systems, or domains.
- Distinguish this skill from nearby skills.

Poor descriptions:

- "Helps with docs."
- "Improves code."
- "Use this powerful workflow for many tasks."
- Descriptions that explain what the body contains but not when to activate it.

## Progressive Disclosure

Design for three loading levels:

1. **Metadata**: `name` and `description`; always visible and must be enough to decide activation.
2. **SKILL.md body**: concise workflow loaded only when the skill activates.
3. **Bundled resources**: references, scripts, and assets loaded or executed only when needed.

If `SKILL.md` starts becoming a full manual, split the details into linked reference files and keep the body as routing plus workflow.

## When To Add Scripts

Add scripts when they improve reliability:

- Validation, linting, parsing, formatting, conversion, or repeated shell logic.
- Operations where generated code would be brittle or verbose.
- Tasks with explicit error handling or stable inputs/outputs.

Before adding a script, define:

- Inputs and outputs.
- Exit-code behavior.
- Dependencies.
- Whether it reads, writes, or sends data outside the workspace.

## Review Checklist

- [ ] Skill name is portable, short, and folder-matched.
- [ ] Description has clear triggers and no host-specific assumptions.
- [ ] Body is a runnable workflow, not background essay.
- [ ] Detailed material is moved to `references/` with explicit load conditions.
- [ ] Scripts are necessary, scoped, and inspectable.
- [ ] Assets are output resources, not hidden instructions.
- [ ] The skill states when to ask the user before destructive or external actions.
- [ ] A realistic trigger prompt and non-trigger prompt have been considered.
