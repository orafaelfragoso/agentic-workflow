#!/usr/bin/env bash
set -euo pipefail

emit_rules() {
cat <<'EOF'
## Working Rules

- Prefer Columbus for project context when available. Locate first, read second: search with `columbus search ... --llm`, then use `show` or `graphs` only for the few targets that matter. Fall back to normal locate-first file discovery when Columbus is absent.
- Project Context below is the shared global baseline. Do not make every task agent reload global memory, broad reports, or registries. Pass only the scoped context each task needs.
- Keep the Columbus board current during delivery work. Move tasks to `in_progress` before implementation, add meaningful progress comments, mark blocked work `blocked` with a reason, and mark work `done` only after verification.
- Use `ship` for sprint delivery over Columbus epics, stories, and tasks. Choose direct, sequential, or parallel flow from dependencies and branch/worktree needs; state the branch/worktree strategy before implementation.
- Delegate sparingly. Use `navigator` for codebase exploration and the most specific delivery agent for implementation, tests, quality review, security/CVE analysis, architecture review, or release readiness. Give each agent a self-contained brief and trust its returned report.
- For third-party libraries, frameworks, SDKs, external APIs, dependency behavior, or CVE claims, verify current information with Context7 (or WebSearch if Context7 is unavailable), security tooling, package manager data, or live advisory sources before coding, pinning, or asserting safety.
EOF
}

# SessionStart hooks may emit plain stdout (added as context) or a JSON
# envelope. Without jq we can neither parse Columbus output nor build the
# JSON envelope, so degrade to plain-text context instead of failing the hook.
if ! command -v jq > /dev/null 2>&1; then
  emit_rules
  printf '\n## Project Context\n'
  printf -- '- (jq not found on PATH - project context unavailable; install jq: https://jqlang.github.io/jq/download/)\n'
  exit 0
fi

build_prompt() {
emit_rules

printf '\n## Project Context\n'
if command -v columbus > /dev/null 2>&1; then
  # The global --limit defaults to 15; raise it explicitly so global memories
  # are never silently truncated once a project accrues more than 15.
  ids="$(columbus memory list context --tag global --limit 500 --json 2>/dev/null | jq -r '.items[]?.id' 2>/dev/null || true)"
  if [ -n "$ids" ]; then
    # `memory list --json` returns ids/titles only (no bodies), so one
    # `show memory` per id is required to render the body text.
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      columbus show memory "$id" --json 2>/dev/null \
        | jq -r '"- **" + .title + "** - " + .body' 2>/dev/null || true
    done <<< "$ids"
  else
    printf -- '- (no global memory yet - ask for Columbus setup guidance or run columbus install when appropriate)\n'
  fi
else
  printf -- '- (columbus CLI not found on PATH)\n'
fi
}

# Emit as SessionStart additionalContext so the prompt is injected on startup,
# clear, and compact through the plugin hook config.
jq -n --arg ctx "$(build_prompt)" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
