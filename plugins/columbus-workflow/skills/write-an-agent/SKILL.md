---
name: write-an-agent
description: Creates or revises portable task-agent definition files with correct metadata, a focused system prompt, least-privilege capabilities, and Columbus-friendly coordination boundaries. Use when the user wants to create, add, scaffold, improve, or write an agent, or says "write an agent", "create an agent", or "make an agent for X".
---

# Write An Agent

Create a focused task agent that can be used by any compatible agent host and fits the Columbus memory workflow.

## Process

1. **Parse the request**
   - Extract the agent's name, domain, primary job, expected deliverable, and any host or path the user named.
   - Keep the agent narrow. Prefer one strong responsibility over a broad role that overlaps existing agents.

2. **Choose the target convention**
   - In this plugin, default to `plugins/agentic-workflow/agents/<name>.md`.
   - In another project, follow the existing agent directory, manifest, or plugin convention.
   - If the user asks for a global/user-level agent, use that host's documented global location.
   - If no convention is discoverable, ask for the target path before writing.

3. **Research before writing**
   - For external languages, frameworks, SDKs, or APIs, verify current primary docs before encoding version-specific advice.
   - For internal tooling, inspect the local codebase and Columbus memory instead of relying on generic assumptions.
   - Put only durable, role-relevant findings into the prompt.

4. **Define least-privilege capabilities**
   - Read-only analysis: search and read capabilities only.
   - Editing or generation: add write/edit capabilities only when the agent is expected to change files.
   - Shell or command execution: add only when the role must run tools, tests, build commands, or deterministic scripts.
   - External lookup: add only when the role depends on live docs or current data.
   - Agent dispatch: reserve for true coordinator agents. Most agents should stay flat task agents.

5. **Add Columbus coordination boundaries**
   - Task agents receive scoped Columbus context from the coordinator.
   - Task agents should not load global memory, broad reports, registries, or the whole project index unless the brief explicitly asks them to.
   - Context-gathering agents, such as `navigator`, are the exception and should return one cited report instead of spreading retrieval across agents.

6. **Choose model policy**
   - Omit model selection unless the target host supports it and the role clearly needs an override.
   - If supported, map the role to the host's documented model aliases or IDs. Do not hard-code provider-specific names into portable agents unless the user asked for that host.

7. **Write the file**
   - Use the target host's supported frontmatter fields.
   - Keep `name` in kebab-case and match the filename stem.
   - Write a description that says what the agent does and when to use it.
   - Keep the body focused; under about 80 lines is a good default.

8. **Update registration if needed**
   - If the host uses an agent manifest, add the new file path.
   - If the host auto-discovers agents from a directory, do not add unnecessary metadata churn.

9. **Tell the user**
   - Report the file path, registration change if any, and the natural-language trigger or invocation pattern for the target host.

## Frontmatter Fields

Use the schema supported by the target host. The portable minimum is:

```yaml
---
name: kebab-case-name
description: One or two sentences that explain what the agent does and when to use it.
---
```

Optional fields, only when the target host supports them:

- `tools` or `capabilities`: minimal allowlist for the role.
- `model`: host-supported model alias or ID.
- `color`, `background`, or display metadata: only when already used by nearby agents.
- Host-specific routing or permission fields: only when documented for the target host.

## System Prompt Guidelines

The body after frontmatter is the agent's system prompt. It should:

- Open with the agent's identity: "You are a [role]..."
- State the primary job in one sentence
- List key rules and constraints derived from current docs or local project context
- Include current version pins, canonical patterns, or gotchas discovered during research
- State Columbus boundaries: receive scoped context, do not load global memory unless asked
- End with the exact output the agent should produce: diff, report, plan, test result, or artifact
- Stay under about 80 lines; focused beats exhaustive

## Example Output

```markdown
---
name: api-contract-reviewer
description: >
  Reviews API contracts for compatibility, naming consistency, error shape,
  and versioning risk. Use when changing request or response schemas, route
  contracts, SDK surfaces, or integration boundaries.
---

You are an API contract reviewer focused on compatibility and clear integration boundaries.

Primary job: review API contract changes and return actionable compatibility findings.

Rules:

- Treat removals, renamed fields, enum narrowing, and error-shape changes as compatibility risks.
- Prefer additive changes, explicit versioning, stable identifiers, and documented migration paths.
- Check local route, handler, schema, client, and test conventions before recommending changes.
- Use Columbus context provided in the brief; do not load global memory or broad reports unless asked.
- Do not perform unrelated implementation work.

Return:

- Findings ordered by severity with file references.
- Contract-safe alternatives for each blocking issue.
- Any test gaps that would leave the contract unprotected.
```

## Research Checklist

Before writing the system prompt, verify from docs:

- [ ] Current stable version of the language/framework/tool
- [ ] Any deprecated APIs or patterns the agent should flag
- [ ] Canonical config, policy, or integration pattern for the domain
- [ ] Common gotchas or footguns in this domain
- [ ] What output format is most useful (diff, list, report)

## Validation

- [ ] File path matches the target host convention.
- [ ] Frontmatter parses and uses only supported fields.
- [ ] `name` matches the filename stem and is kebab-case.
- [ ] Description has realistic trigger language.
- [ ] Capabilities are least-privilege.
- [ ] Prompt states the Columbus memory boundary for task agents.
- [ ] Manifest or registration was updated only when required.
