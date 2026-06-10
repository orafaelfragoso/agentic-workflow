#!/usr/bin/env bash
# rtk-hook-version: 4
# RTK agent hook — rewrites Bash commands to rtk equivalents for token savings.
#
# Thin wrapper around `rtk hook claude`, rtk's native Claude Code PreToolUse
# processor and the single source of truth for rewrite + permission logic.
# Earlier versions of this script hand-rolled a protocol around `rtk rewrite`
# exit codes; that protocol changed upstream (rtk >= 0.42 reports every
# rewrite as exit 3), so all decision handling now lives in the rtk binary.
#
# Behavior:
#   - rtk missing: warn on stderr, pass the command through unchanged
#   - rtk too old for `hook claude`: pass through unchanged
#   - otherwise: emit whatever `rtk hook claude` returns (a rewrite, or
#     nothing for commands with no rtk equivalent)

if ! command -v rtk &>/dev/null; then
  echo "[rtk] WARNING: rtk is not installed or not in PATH. Hook cannot rewrite commands. Install: https://github.com/rtk-ai/rtk#installation" >&2
  exit 0
fi

INPUT=$(cat)

if OUTPUT=$(printf '%s' "$INPUT" | rtk hook claude 2>/dev/null); then
  [ -n "$OUTPUT" ] && printf '%s\n' "$OUTPUT"
fi
exit 0
