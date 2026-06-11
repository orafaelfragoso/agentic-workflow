#!/usr/bin/env bash
# Merge the plugin's recommended Claude Code settings into the user's global
# settings and install the bundled statusline script.
#
# Usage: setup-settings.sh [--dry-run] [target-settings-file]
#   target defaults to $CLAUDE_CONFIG_DIR/settings.json (~/.claude/settings.json)
#
# Behavior:
#   - copies the plugin's statusline-command.sh to a stable path under the
#     Claude config dir so settings keep working across plugin upgrades
#   - deep-merges config/claude/settings.local.example.json into the target;
#     plugin values win on conflict, unrelated user keys are preserved
#   - backs up an existing target to <target>.bak.<timestamp> before writing
#   - --dry-run prints the merged JSON and writes nothing
#
# Exit codes: 0 success, 1 missing dependency or source file, 2 target is invalid JSON.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)

EXAMPLE="$PLUGIN_ROOT/config/claude/settings.local.example.json"
STATUSLINE_SRC="$PLUGIN_ROOT/scripts/statusline-command.sh"
OUTPUT_STYLE_SRC="$PLUGIN_ROOT/plugins/columbus-workflow/output-styles/caveman.md"

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATUSLINE_DEST="$CLAUDE_DIR/statusline-command.sh"
OUTPUT_STYLE_DEST="$CLAUDE_DIR/output-styles/caveman.md"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi
TARGET="${1:-$CLAUDE_DIR/settings.json}"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }
[ -f "$EXAMPLE" ] || { echo "error: missing $EXAMPLE" >&2; exit 1; }
[ -f "$STATUSLINE_SRC" ] || { echo "error: missing $STATUSLINE_SRC" >&2; exit 1; }
[ -f "$OUTPUT_STYLE_SRC" ] || { echo "error: missing $OUTPUT_STYLE_SRC" >&2; exit 1; }

project=$(jq --arg sl "$STATUSLINE_DEST" --arg os "$OUTPUT_STYLE_DEST" \
  '.statusLine.command = $sl | .outputStyle = $os' "$EXAMPLE")

if [ -f "$TARGET" ]; then
  jq empty "$TARGET" 2>/dev/null || { echo "error: $TARGET is not valid JSON; fix or remove it first" >&2; exit 2; }
  merged=$(jq -s '.[0] * .[1]' "$TARGET" <(printf '%s' "$project"))
else
  merged="$project"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf '%s\n' "$merged" | jq .
  exit 0
fi

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/output-styles" "$(dirname "$TARGET")"

cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
chmod +x "$STATUSLINE_DEST"

cp "$OUTPUT_STYLE_SRC" "$OUTPUT_STYLE_DEST"

if [ -f "$TARGET" ]; then
  backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET" "$backup"
  echo "backup: $backup"
fi

printf '%s\n' "$merged" | jq . > "$TARGET"

echo "settings: $TARGET"
echo "statusline: $STATUSLINE_DEST"
echo "output-style: $OUTPUT_STYLE_DEST"
