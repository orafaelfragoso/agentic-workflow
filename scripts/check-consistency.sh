#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root from the script's own location so it runs from anywhere.
cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO_ROOT="$(pwd)"

echo "Running consistency checks from: ${REPO_ROOT}"

# ----------------------------------------------------------------------------
# Check 1: Version sync
# plugin.json .version must match marketplace.json .plugins[0].version
# ----------------------------------------------------------------------------
PLUGIN_VERSION="$(jq -r .version .claude-plugin/plugin.json)"
MARKETPLACE_VERSION="$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)"
if [ "${PLUGIN_VERSION}" != "${MARKETPLACE_VERSION}" ]; then
  echo "error: version mismatch — plugin.json has '${PLUGIN_VERSION}' but marketplace.json has '${MARKETPLACE_VERSION}'" >&2
  exit 1
fi
echo "ok: version sync (${PLUGIN_VERSION})"

# ----------------------------------------------------------------------------
# Check 2: Namespace — no stale agentic-workflow: references in plugins/
# ----------------------------------------------------------------------------
if grep -rn "agentic-workflow:" plugins/; then
  echo "error: stale 'agentic-workflow:' namespace found in plugins/ (see matches above)" >&2
  exit 1
fi
echo "ok: namespace (no stale agentic-workflow: references)"

# ----------------------------------------------------------------------------
# Check 3: Dead-component sweep — no triage or sprint delivery references
# ----------------------------------------------------------------------------
if grep -rniE "\btriage\b|sprint delivery" plugins/ .claude-plugin/ README.md; then
  echo "error: dead component reference found — 'triage' or 'sprint delivery' (see matches above)" >&2
  exit 1
fi
echo "ok: dead-component sweep (no triage / sprint delivery)"

# ----------------------------------------------------------------------------
# Check 4: Manifest agents exist — every path in .claude-plugin/plugin.json
# .agents[] must resolve to an existing file
# ----------------------------------------------------------------------------
while IFS= read -r agent_path; do
  if [ ! -f "${agent_path}" ]; then
    echo "error: manifest agent path does not exist: ${agent_path}" >&2
    exit 1
  fi
done < <(jq -r '.agents[]' .claude-plugin/plugin.json)
echo "ok: manifest agents exist"

# ----------------------------------------------------------------------------
# Check 5: Skill frontmatter names — the name: field in each SKILL.md must
# match the skill's parent directory name
# ----------------------------------------------------------------------------
shopt -s nullglob
skill_files=( plugins/columbus-workflow/skills/*/SKILL.md )
shopt -u nullglob
if [ "${#skill_files[@]}" -eq 0 ]; then
  echo "error: no SKILL.md files found under plugins/columbus-workflow/skills/ — skills must exist" >&2
  exit 1
fi
for skill_file in "${skill_files[@]}"; do
  dir_name="$(basename "$(dirname "${skill_file}")")"
  # Extract name: from within the YAML frontmatter block (between the first and second ---).
  # awk tracks fence state: fence=0 before first ---, fence=1 inside, fence=2 after.
  frontmatter_name="$(awk '
    /^---/ {
      fence++
      next
    }
    fence == 1 && /^name:[[:space:]]/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/[[:space:]]*$/, "")
      print
      exit
    }
    fence >= 2 { exit }
  ' "${skill_file}")"
  if [ -z "${frontmatter_name}" ]; then
    echo "error: no name: field found in YAML frontmatter of ${skill_file}" >&2
    exit 1
  fi
  if [ "${frontmatter_name}" != "${dir_name}" ]; then
    echo "error: skill frontmatter mismatch in ${skill_file}: name '${frontmatter_name}' != directory '${dir_name}'" >&2
    exit 1
  fi
done
echo "ok: skill frontmatter names"

# ----------------------------------------------------------------------------
# Check 6: Shellcheck — exclude SC2034 (intentional unused ANSI vars)
# If shellcheck is not on PATH, warn and skip; CI installs it.
# ----------------------------------------------------------------------------
if ! command -v shellcheck &> /dev/null; then
  echo "warning: shellcheck not found on PATH — skipping shellcheck (CI installs it)" >&2
else
  shopt -s nullglob
  sh_files=(
    plugins/columbus-workflow/scripts/*.sh
    plugins/columbus-workflow/skills/*/scripts/*.sh
    scripts/*.sh
  )
  shopt -u nullglob
  if [ "${#sh_files[@]}" -eq 0 ]; then
    echo "warning: no shell scripts found for shellcheck — skipping" >&2
  else
    shellcheck --exclude=SC2034 "${sh_files[@]}"
    echo "ok: shellcheck"
  fi
fi
