#!/usr/bin/env bash
set -euo pipefail

emit_rules() {
cat <<'EOF'
## Working Rules

### Context retrieval
- If the `columbus` CLI is on PATH, locate code with `columbus search "..." --llm` first, then open only the few hits that matter with `show` or `graphs`. Without Columbus, locate before reading: search for files, then read only the relevant ranges of large files.
- Do not make subagents reload global memory, broad reports, or registries — pass each agent only the scoped context its task needs.
- Never answer from training memory about third-party libraries, frameworks, SDK/API behavior, version compatibility, or CVEs. Verify with Context7 (or WebSearch if Context7 is unavailable), package-manager data, or live advisories before coding against, pinning, or asserting safety of a dependency.

### Delivery workflow
- Use the `ship` skill for delivery work scoped by Columbus `plan` memories. Choose direct, sequential, or parallel flow from actual dependencies, and state the branch/worktree strategy before implementation.
- Track live execution state (in progress, blocked, done) in the session, not in Columbus. At milestones, update the driving `plan` memory so progress survives the session; after verified delivery, record decisions as `adr`, shipped behavior as `documentation`, and re-kind or remove the executed plan.
- Delegate sparingly: `navigator` for codebase exploration, the most specific delivery agent otherwise. Give each agent a self-contained brief and trust its returned report instead of re-deriving the work.

### Making changes
- Fix root causes, not symptoms. Do not silence failures with `|| true`, empty catch blocks, `any`/`@ts-ignore`/`//nolint` suppressions, broad retries, or code special-cased to satisfy a test.
- Stay in scope. No drive-by refactors, dependency bumps, or style rewrites of code the task does not touch — note them for the user instead.
- Prefer editing existing files. Do not create parallel copies (`file2.ts`, `*.bak`, `*-new`), unsolicited summary or README files, or scratch scripts that outlive the task. Remove debug output and commented-out code before finishing.

### Verifying and finishing
- "Done" means verified. Run the tests, build, and linters relevant to the change and report the actual results — including failures — verbatim. Never claim success you did not observe.
- Never make a failing test pass by deleting it, skipping it, weakening its assertions, or hardcoding expected values. If a test is genuinely wrong, say so and fix it for the stated reason.
- Finish before ending the turn. Do not pause to ask permission for reversible steps that follow from the request, and do not end with unexecuted promises ("next I'll…"). Ask only when blocked on a decision that is genuinely the user's to make.

### Git safety
- Do not commit, push, amend, rebase, or open PRs unless explicitly asked; use the `commit` skill when asked to commit.
- Never run destructive git commands (`reset --hard`, `checkout`/`restore` over uncommitted work, `clean -f`, force-push) without explicit confirmation, and inspect what would be lost first.
EOF
}

# SessionStart hooks may emit plain stdout (added as context) or a JSON
# envelope. Without jq, degrade to plain-text context instead of failing.
if ! command -v jq > /dev/null 2>&1; then
  emit_rules
  exit 0
fi

# Emit as SessionStart additionalContext so the prompt is injected on startup,
# clear, and compact through the plugin hook config.
jq -n --arg ctx "$(emit_rules)" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
