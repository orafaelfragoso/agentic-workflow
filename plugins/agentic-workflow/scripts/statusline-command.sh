#!/usr/bin/env bash
# Claude Code status line script
# Format: Model (effort) | worktree/branch or branch | tokens | 5h% | 7d% | cost

input=$(cat)

# TTY colors (ANSI)
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Foreground colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

# Bright variants
BRIGHT_RED='\033[91m'
BRIGHT_GREEN='\033[92m'
BRIGHT_YELLOW='\033[93m'
BRIGHT_BLUE='\033[94m'
BRIGHT_MAGENTA='\033[95m'
BRIGHT_CYAN='\033[96m'

# Background colors
BG_PURPLE='\033[45m'

# Foreground used against a colored background (knockout)
BLACK='\033[30m'

SEP=" "

# ---------------------------------------------------------------------------
# 0. Columbus badge (shown only when this project is Columbus-initialized)
# ---------------------------------------------------------------------------
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
columbus_str=""
if [ -n "$cwd" ] && [ -f "$cwd/.columbus.json" ] && command -v columbus >/dev/null 2>&1; then
  cb_version=$(columbus version --json 2>/dev/null | jq -r '.version // empty')
  # Reduce the git-describe string to base semver: "v0.2.0-1-g38ec.." -> "0.2.0"
  cb_version=${cb_version#v}
  cb_version=${cb_version%%-*}
  [ -n "$cb_version" ] && columbus_str="${BOLD}${BLACK}${BG_PURPLE} ⛵ Columbus ${cb_version} ${RESET}"
fi

# ---------------------------------------------------------------------------
# 1. Model + effort
# ---------------------------------------------------------------------------
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "Unknown"')
effort=$(echo "$input" | jq -r '.effort.level // empty')

if [ -n "$effort" ]; then
  model_str="${BRIGHT_CYAN}${model}${RESET}${DIM} (${effort})${RESET}"
else
  model_str="${BRIGHT_CYAN}${model}${RESET}"
fi

# ---------------------------------------------------------------------------
# 2. Worktree / branch / git status
# ---------------------------------------------------------------------------
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# Get current git branch (skip optional locks to be safe)
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_branch=$(git -C "$cwd" -c core.checkStat=minimal symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Fall back to worktree_branch from JSON if git fails
[ -z "$git_branch" ] && git_branch="$worktree_branch"

# Build the branch/worktree label
if [ -n "$worktree_name" ]; then
  branch_label="${worktree_name}/${git_branch:-?}"
else
  branch_label="${git_branch}"
fi

# Git dirty status + added/removed line counts
dirty_marker=""
added_lines=""
removed_lines=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  # Check for uncommitted changes
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    dirty_marker="${BRIGHT_YELLOW}*${RESET}"
  fi

  # Count added/removed lines across working tree + index
  numstat=$(git -C "$cwd" diff --numstat 2>/dev/null; git -C "$cwd" diff --cached --numstat 2>/dev/null)
  if [ -n "$numstat" ]; then
    added=$(echo "$numstat" | awk '{sum += $1} END {print sum+0}')
    removed=$(echo "$numstat" | awk '{sum += $2} END {print sum+0}')
    [ "$added" -gt 0 ]   && added_lines="${BRIGHT_GREEN}+${added}${RESET}"
    [ "$removed" -gt 0 ] && removed_lines="${BRIGHT_RED}-${removed}${RESET}"
  fi
fi

# Assemble git segment
git_str="${BRIGHT_BLUE}${branch_label}${RESET}${dirty_marker}"
if [ -n "$added_lines" ] || [ -n "$removed_lines" ]; then
  git_str="${git_str} ${added_lines}${removed_lines}"
fi

# ---------------------------------------------------------------------------
# 3. Token usage (session total / context window)
# ---------------------------------------------------------------------------
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

session_tokens=$((total_input + total_output))

# Format token counts with K suffix
format_k() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fK", n / 1000 }'
  else
    echo "$n"
  fi
}

session_k=$(format_k "$session_tokens")
ctx_k=$(format_k "$ctx_size")

# Color used_pct: green < 50, yellow < 80, red >= 80
if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  if [ "$pct_int" -ge 80 ]; then
    pct_color="${BRIGHT_RED}"
  elif [ "$pct_int" -ge 50 ]; then
    pct_color="${BRIGHT_YELLOW}"
  else
    pct_color="${BRIGHT_GREEN}"
  fi
  token_str="${WHITE}${session_k}${RESET}${DIM}/${RESET}${ctx_k} ${pct_color}(${pct_int}%)${RESET}"
else
  token_str="${WHITE}${session_k}${RESET}${DIM}/${RESET}${ctx_k}"
fi

# ---------------------------------------------------------------------------
# 4. Rate limits — 5h and 7d
# ---------------------------------------------------------------------------
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

color_rate() {
  local pct=$1
  local pct_int
  pct_int=$(printf "%.0f" "$pct")
  if [ "$pct_int" -ge 80 ]; then
    echo "${BRIGHT_RED}${pct_int}%${RESET}"
  elif [ "$pct_int" -ge 50 ]; then
    echo "${BRIGHT_YELLOW}${pct_int}%${RESET}"
  else
    echo "${BRIGHT_GREEN}${pct_int}%${RESET}"
  fi
}

five_str=""
week_str=""
[ -n "$five_pct" ] && five_str="${DIM}5h:${RESET}$(color_rate "$five_pct")"
[ -n "$week_pct" ] && week_str="${DIM}7d:${RESET}$(color_rate "$week_pct")"

# ---------------------------------------------------------------------------
# 5. Session cost (cumulative, whole session)
# ---------------------------------------------------------------------------
# Claude Code tracks the running total for the entire session in
# .cost.total_cost_usd — across every turn and model. Use it directly.
# If the harness doesn't provide it (older schema), show nothing rather than
# estimating from hardcoded per-token prices that silently go stale.
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // .total_cost_usd // empty')

cost_str=""
if [ -n "$cost" ] && awk -v c="$cost" 'BEGIN { exit !(c > 0) }'; then
  formatted=$(printf "\$%.3f" "$cost")
  cost_str="${DIM}cost:${RESET}${BRIGHT_MAGENTA}${formatted}${RESET}"
fi

# ---------------------------------------------------------------------------
# Assemble the final status line
# ---------------------------------------------------------------------------
parts=()
[ -n "$columbus_str" ] && parts+=("${columbus_str}")
parts+=("${model_str}")
[ -n "$git_str" ] && parts+=("${git_str}")
[ -n "$token_str" ] && parts+=("${token_str}")
[ -n "$five_str" ] && parts+=("${five_str}")
[ -n "$week_str" ] && parts+=("${week_str}")
[ -n "$cost_str" ] && parts+=("${cost_str}")

# Join with separator
result=""
for part in "${parts[@]}"; do
  if [ -z "$result" ]; then
    result="$part"
  else
    result="${result}${SEP}${part}"
  fi
done

printf "%b\n" "$result"
