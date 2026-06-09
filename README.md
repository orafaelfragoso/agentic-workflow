# Agentic Workflow

This repository is a single cross-tool agent plugin. Both Claude Code and Codex install the same
asset package at `plugins/agentic-workflow`. Claude Code uses `.claude-plugin/plugin.json`, and
Codex uses `plugins/agentic-workflow/.codex-plugin/plugin.json`.

## Layout

```text
.
├── .agents/plugins/marketplace.json       # Codex local marketplace catalog
├── .claude-plugin/
│   ├── marketplace.json                   # Claude Code marketplace catalog
│   └── plugin.json                        # Claude Code plugin manifest
└── plugins/agentic-workflow/              # Shared Claude Code + Codex package
    ├── .codex-plugin/plugin.json          # Codex plugin manifest
    ├── agents/
    ├── config/claude/settings.local.example.json
    ├── output-styles/caveman.md
    ├── scripts/
    └── skills/
```

## Claude Code

Install from the hosted marketplace:

```bash
claude plugin marketplace add orafaelfragoso/agentic-workflow
claude plugin install agentic-workflow@agentic-workflow
```

When working from a local clone, add the marketplace from the repository root instead:

```bash
claude plugin marketplace add ./
claude plugin install agentic-workflow@agentic-workflow
```

When developing locally, validate the plugin from the repository root:

```bash
claude plugin validate .
```

Claude Code loads assets through root manifest paths that point into `plugins/agentic-workflow/`.
Add new Claude agents to the `agents` list in `.claude-plugin/plugin.json`.

## Codex

The Codex marketplace catalog points at `./plugins/agentic-workflow`. Unlike Claude Code, the
current Codex marketplace loader does not expose plugins whose source path is the marketplace root.

For a non-default local marketplace, register the marketplace root, then add the plugin:

```bash
codex plugin marketplace add ./
codex plugin add agentic-workflow@agentic-workflow
```

Use the `codex plugin` install flow above as the Codex smoke test. The bundled helper validator
currently rejects inline hooks, while the CLI install path accepts them.

## Ship Delivery Model

This plugin adapts sprint delivery around Columbus instead of a report registry:

- The active session is the coordinator. It loads global Columbus memory once through the startup prompt.
- `ship` processes Columbus epics, stories, and tasks through direct, sequential, or parallel delivery flows.
- `navigator` is the on-demand codebase explorer. It can be invoked directly or by orchestration, uses Columbus to locate relevant code, and returns one cited report.
- Specialist agents cover planning, implementation, tests, quality review, security/CVE review, architecture review, and release readiness.
- Task agents should not re-read global memory, broad reports, or registries. The coordinator passes only the context each task needs.
- Delivery keeps the Columbus board current: tasks move to `in_progress` before implementation, `blocked` when stuck, and `done` only after verification.
- Branch and worktree strategy is part of the flow: direct work can stay on one branch, sequential work usually stays on one branch, and parallel work should use separate branches or worktrees when agents edit concurrently.

`ship` keeps its top-level instructions short and loads one of three references based on the work shape:

- `plugins/agentic-workflow/skills/ship/references/direct.md`
- `plugins/agentic-workflow/skills/ship/references/sequential.md`
- `plugins/agentic-workflow/skills/ship/references/parallel.md`

## Session Context

`plugins/agentic-workflow/scripts/prompt.sh` is loaded on `SessionStart` for startup, clear, and compact events. It intentionally emits only:

- compact working rules for Columbus, board updates, `ship`, delegation, branch/worktree strategy, and current external-doc/security checks
- `## Project Context`, populated from Columbus memories tagged `global`

Keep this prompt stable and compact because it is injected into every session.

## Agents

The bundled agents are flat specialists. `ship` coordinates the flow; agents do not coordinate each other by default.

The agents are tuned for Claude Code: they pin Claude model aliases (`haiku`/`sonnet`), reference Claude MCP tool ids (`mcp__context7__*`), and use agent-teams tools (`SendMessage`, `EnterWorktree`, `ExitWorktree`) that require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — set in the local config template. Codex consumes the shared skills and hooks; agents and the output style are Claude Code-only today.

- `navigator`: on-demand codebase explorer using Columbus.
- `sprint-planner`: organizes epics, stories, tasks, dependencies, and branch/worktree strategy.
- `delivery-engineer`: implements one scoped task.
- `test-engineer`: designs and runs verification.
- `quality-reviewer`: reviews correctness, maintainability, regression risk, and task fit.
- `security-analyst`: reviews vulnerabilities, dependency/CVE exposure, secrets, auth, and data-handling risk.
- `architecture-reviewer`: reviews patterns, boundaries, coupling, and abstractions.
- `release-coordinator`: checks branch, merge, PR, verification, and board readiness.

## Adding Components

- Add shared skills under `plugins/agentic-workflow/skills/<skill-name>/SKILL.md`.
- Add task agents under `plugins/agentic-workflow/agents/*.md`.
- Add host manifest file paths when that host does not auto-discover agents.
- Add hooks inline in `.claude-plugin/plugin.json` and `plugins/agentic-workflow/.codex-plugin/plugin.json`. Hook script paths resolve from each host's plugin root: the repository root for Claude Code, `plugins/agentic-workflow/` for Codex.
- Keep hook scripts under `plugins/agentic-workflow/scripts/`.
- Do not add dynamic agent or skill listings back to `prompt.sh`; the prompt is loaded every session.
- When bumping the plugin version, update all three declarations together: `.claude-plugin/plugin.json`, the plugin entry in `.claude-plugin/marketplace.json`, and `plugins/agentic-workflow/.codex-plugin/plugin.json`.

## Ported From Columbus

- Skills: `ship`, `columbus`, `commit`, `mastering-golang`, `interview`, `mastering-typescript`, `triage`, `write-a-skill`, `write-an-agent`
- Agents: `navigator`, `sprint-planner`, `delivery-engineer`, `test-engineer`, `quality-reviewer`, `security-analyst`, `architecture-reviewer`, `release-coordinator`
- Scripts: `prompt.sh`, `rtk-rewrite.sh`, `statusline-command.sh`
- Hooks: `SessionStart` context injection and `PreToolUse` RTK bash rewrite
- Output style: `Caveman`
- Local config template: `plugins/agentic-workflow/config/claude/settings.local.example.json`

When copying the local config template, replace the `statusLine.command` placeholder with the absolute path to `plugins/agentic-workflow/scripts/statusline-command.sh` (settings files do not expand `${CLAUDE_PLUGIN_ROOT}`).

For hosted distribution, publish this repository as `agentic-workflow`. The Claude marketplace points
at the repository root, and the Codex marketplace points at `./plugins/agentic-workflow`.
