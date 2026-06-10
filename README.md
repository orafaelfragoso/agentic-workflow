# Columbus Workflow

This repository hosts the **Columbus Workflow** Claude Code plugin, distributed through the
`orafaelfragoso` marketplace. The marketplace manifest lives at `.claude-plugin/marketplace.json`,
the plugin manifest at `.claude-plugin/plugin.json`, and all plugin assets under
`plugins/columbus-workflow/`.

## Layout

```text
.
├── .claude-plugin/
│   ├── marketplace.json                   # Marketplace catalog (orafaelfragoso)
│   └── plugin.json                        # Plugin manifest
└── plugins/columbus-workflow/             # Plugin assets
    ├── agents/
    ├── config/claude/settings.local.example.json
    ├── output-styles/caveman.md
    ├── scripts/
    └── skills/
```

## Installation

Install from the hosted marketplace:

```bash
claude plugin marketplace add orafaelfragoso/agentic-workflow
claude plugin install columbus-workflow@orafaelfragoso
```

When working from a local clone, add the marketplace from the repository root instead:

```bash
claude plugin marketplace add ./
claude plugin install columbus-workflow@orafaelfragoso
```

When developing locally, validate the plugin from the repository root:

```bash
claude plugin validate .
```

Claude Code loads assets through root manifest paths that point into `plugins/columbus-workflow/`.
Add new agents to the `agents` list in `.claude-plugin/plugin.json`.

## Ship Delivery Model

This plugin adapts sprint delivery around Columbus instead of a report registry:

- The active session is the coordinator. It retrieves the relevant Columbus memory (ADRs, plans, documentation) once and passes scoped context to agents.
- `ship` executes Columbus `plan` memories through direct, sequential, or parallel delivery flows. Live execution state lives in the session; Columbus holds the durable record.
- `navigator` is the on-demand codebase explorer. It can be invoked directly or by orchestration, uses Columbus to locate relevant code, and returns one cited report.
- Specialist agents cover planning, implementation, tests, quality review, security/CVE review, architecture review, and release readiness.
- Task agents should not re-run broad memory retrieval. The coordinator passes only the context each task needs and owns all memory writes.
- Delivery closes out in memory: plan bodies are updated at milestones, decisions are recorded as `adr`, shipped behavior as `documentation`, and executed plans are re-kinded or removed.
- Branch and worktree strategy is part of the flow: direct work can stay on one branch, sequential work usually stays on one branch, and parallel work should use separate branches or worktrees when agents edit concurrently.

`ship` keeps its top-level instructions short and loads one of three references based on the work shape:

- `plugins/columbus-workflow/skills/ship/references/direct.md`
- `plugins/columbus-workflow/skills/ship/references/sequential.md`
- `plugins/columbus-workflow/skills/ship/references/parallel.md`

## Session Context

`plugins/columbus-workflow/scripts/prompt.sh` is loaded on `SessionStart` for startup, clear, and compact events. It intentionally emits only compact working rules: Columbus retrieval, plan-driven delivery with `ship`, delegation, change/verification discipline, git safety, and current external-doc/security checks.

Keep this prompt stable and compact because it is injected into every session.

## Agents

The bundled agents are flat specialists. `ship` coordinates the flow; agents do not coordinate each other by default.

The agents pin Claude model aliases (`haiku`/`sonnet`), reference Claude MCP tool ids (`mcp__context7__*`), and use agent-teams tools (`SendMessage`, `EnterWorktree`, `ExitWorktree`) that require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — set in the local config template.

- `navigator`: on-demand codebase explorer using Columbus.
- `sprint-planner`: turns plan memories into an execution plan with dependencies and branch/worktree strategy.
- `delivery-engineer`: implements one scoped piece of planned work.
- `test-engineer`: designs and runs verification.
- `quality-reviewer`: reviews correctness, maintainability, regression risk, and fit with the planned scope.
- `security-analyst`: reviews vulnerabilities, dependency/CVE exposure, secrets, auth, and data-handling risk.
- `architecture-reviewer`: reviews patterns, boundaries, coupling, and abstractions.
- `release-coordinator`: checks branch, merge, PR, verification, and plan-closeout readiness.

## Adding Components

- Add skills under `plugins/columbus-workflow/skills/<skill-name>/SKILL.md`.
- Add task agents under `plugins/columbus-workflow/agents/*.md` and register them in `.claude-plugin/plugin.json`.
- Add hooks inline in `.claude-plugin/plugin.json`. Hook script paths resolve from the plugin root (the repository root), so prefix them with `${CLAUDE_PLUGIN_ROOT}`.
- Keep hook scripts under `plugins/columbus-workflow/scripts/`.
- Do not add dynamic agent or skill listings back to `prompt.sh`; the prompt is loaded every session.
- When bumping the plugin version, update both declarations together: `.claude-plugin/plugin.json` and the plugin entry in `.claude-plugin/marketplace.json`.

## Bundled Components

- Skills: `ship`, `columbus`, `commit`, `interview`, `triage`, `improve`, `setting-sail`, `mastering-golang`, `mastering-typescript`, `write-a-skill`, `write-an-agent`
- Agents: `navigator`, `sprint-planner`, `delivery-engineer`, `test-engineer`, `quality-reviewer`, `security-analyst`, `architecture-reviewer`, `release-coordinator`
- Scripts: `prompt.sh`, `rtk-rewrite.sh`, `statusline-command.sh`
- Hooks: `SessionStart` context injection and `PreToolUse` RTK bash rewrite
- Output style: `Caveman`
- Local config template: `plugins/columbus-workflow/config/claude/settings.local.example.json`

The `setting-sail` skill applies the recommended settings as your global Claude Code defaults and
installs the bundled statusline script (it runs
`plugins/columbus-workflow/skills/setting-sail/scripts/setup-settings.sh`). When copying the local
config template manually instead, replace the `statusLine.command` placeholder with the absolute
path to `plugins/columbus-workflow/scripts/statusline-command.sh` (settings files do not expand
`${CLAUDE_PLUGIN_ROOT}`).

For hosted distribution, this repository is published as `orafaelfragoso/agentic-workflow`; the
marketplace catalog points at the repository root.
