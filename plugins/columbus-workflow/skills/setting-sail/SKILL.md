---
name: setting-sail
description: Applies this plugin's recommended Claude Code settings (env tweaks, output style, enabled plugins, statusline) as the user's global defaults and installs the bundled statusline script. Use when the user says "setting sail", "set sail", asks to apply or install the project's Claude settings as their defaults, or wants the statusline script set up.
---

# Setting Sail

Make the plugin's recommended Claude Code settings the user's global defaults and wire up the bundled statusline script, without losing the user's existing configuration.

## What it installs

- `config/claude/settings.local.example.json` (plugin-relative) deep-merged into the user's global `settings.json`. Plugin values win on conflict; user keys not present in the example are preserved.
- `scripts/statusline-command.sh` copied to a stable path inside the Claude config dir (default `~/.claude/statusline-command.sh`) and referenced from `statusLine.command`. It is copied, not referenced in place, so the setting keeps working when the plugin cache path changes on upgrade.

## Workflow

1. Preview the result first: run `scripts/setup-settings.sh --dry-run` and compare it against the user's current global `settings.json` (default `~/.claude/settings.json`, or `$CLAUDE_CONFIG_DIR/settings.json` if that variable is set).
2. Report which existing keys would change value. If any would be overwritten, summarize them and confirm with the user before proceeding. A fresh install with no existing settings file needs no confirmation.
3. Run `scripts/setup-settings.sh`. It backs up any existing settings file to `<target>.bak.<timestamp>` before writing and prints the backup, settings, and statusline paths.
4. Validate:
   - The target settings file parses with `jq`.
   - `statusLine.command` in the target points to an existing executable file.
   - The statusline script runs: `echo '{}' | <statusline path>` exits 0 and prints a line.
5. Tell the user the env-based settings (for example `CLAUDE_CODE_DISABLE_AUTO_MEMORY`) take effect on the next Claude Code session, and mention the backup path if one was created.

## Decision points

- If the existing settings file is invalid JSON, the script exits with code 2 and touches nothing. Show the user the parse problem and let them decide how to fix it; do not delete or regenerate their file unprompted.
- If `jq` is missing, ask the user to install it (for example `brew install jq`) rather than reimplementing the merge by hand.
- To write somewhere other than the global settings file, pass the target path as the script's argument.

## Validation

- [ ] Backup file exists when a settings file was already present.
- [ ] Merged settings file is valid JSON and keeps user keys absent from the example.
- [ ] `statusLine.command` points at an executable copy of the statusline script.
- [ ] Statusline script produces output when fed `{}` on stdin.
