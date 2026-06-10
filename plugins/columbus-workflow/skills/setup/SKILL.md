---
name: setup
description: Sets up the Columbus Workflow plugin end to end — checks dependencies (jq, the Columbus CLI, rtk), applies the plugin's recommended Claude Code settings (env tweaks, output style, enabled plugins, statusline) as the user's global defaults, installs the bundled statusline script, and offers Columbus project indexing. Use when the user says "setup", "set up the plugin", "setting sail", "set sail", asks to apply or install the plugin's Claude settings as their defaults, or wants the statusline script set up.
---

# Setup

Set up everything the Columbus Workflow plugin needs — global Claude Code defaults, the bundled statusline, plugin enablement, and a working Columbus index — without losing the user's existing configuration.

## What it installs

- `config/claude/settings.local.example.json` (plugin-relative) deep-merged into the user's global `settings.json`. Plugin values win on conflict; user keys not present in the example are preserved. The example enables this plugin globally (`enabledPlugins["columbus-workflow@orafaelfragoso"]`) alongside the recommended LSP plugins.
- `scripts/statusline-command.sh` copied to a stable path inside the Claude config dir (default `~/.claude/statusline-command.sh`) and referenced from `statusLine.command`. It is copied, not referenced in place, so the setting keeps working when the plugin cache path changes on upgrade.
- Optionally, a Columbus index for the current project (`columbus install`), so the plugin's skills and agents have code search and memory available.

## Workflow

1. Check dependencies: `jq` (required by the merge script), the `columbus` CLI (required by this plugin's skills and agents), and `rtk` (required by the PreToolUse rewrite hook) — check each with `command -v`. If `columbus` is missing, tell the user the plugin's retrieval and memory features won't work until it's installed, and ask whether to continue with settings-only setup. If `rtk` is missing, tell the user the bash-rewrite hook will warn and pass commands through unchanged until rtk is installed (https://github.com/rtk-ai/rtk#installation).
2. Preview the result: run `scripts/setup-settings.sh --dry-run` and compare it against the user's current global `settings.json` (default `~/.claude/settings.json`, or `$CLAUDE_CONFIG_DIR/settings.json` if that variable is set).
3. Report which existing keys would change value. If any would be overwritten, summarize them and confirm with the user before proceeding. A fresh install with no existing settings file needs no confirmation.
4. Run `scripts/setup-settings.sh`. It backs up any existing settings file to `<target>.bak.<timestamp>` before writing and prints the backup, settings, and statusline paths.
5. Validate:
   - The target settings file parses with `jq`.
   - `enabledPlugins` in the target contains a `columbus-workflow@...` entry. If the user installed the plugin from a marketplace other than `orafaelfragoso`, correct the key to match their marketplace.
   - `statusLine.command` in the target points to an existing executable file.
   - The statusline script runs: `echo '{}' | <statusline path>` exits 0 and prints a line.
6. Set up Columbus for the current project (skip if `columbus` is missing): if there is no `.columbus.json` in the project root, offer to run `columbus install` (it writes `.columbus.json`, creates the project database, and indexes the repo — get the user's go-ahead first). If the project is already configured, run `columbus doctor` and report any problems.
7. Tell the user the env-based settings (for example `CLAUDE_CODE_DISABLE_AUTO_MEMORY`) take effect on the next Claude Code session, and mention the backup path if one was created.

## Decision points

- If the existing settings file is invalid JSON, the script exits with code 2 and touches nothing. Show the user the parse problem and let them decide how to fix it; do not delete or regenerate their file unprompted.
- If `jq` is missing, ask the user to install it (for example `brew install jq`) rather than reimplementing the merge by hand.
- If `columbus` is missing, never skip silently — say what won't work and let the user choose between installing it first and settings-only setup.
- If `rtk` is missing, setup can proceed (the hook degrades gracefully), but report it so the user knows the token-saving rewrites are off.
- `columbus install` writes a config file and database into the project; always confirm before running it.
- To write somewhere other than the global settings file, pass the target path as the script's argument.

## Validation

- [ ] Backup file exists when a settings file was already present.
- [ ] Merged settings file is valid JSON and keeps user keys absent from the example.
- [ ] `enabledPlugins` contains the columbus-workflow entry for the user's marketplace.
- [ ] `statusLine.command` points at an executable copy of the statusline script.
- [ ] Statusline script produces output when fed `{}` on stdin.
- [ ] `columbus doctor` reports a healthy project, or the user explicitly deferred Columbus setup.
- [ ] `rtk` is installed, or the user was told the rewrite hook is inactive without it.
