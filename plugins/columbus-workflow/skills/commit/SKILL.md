---
name: commit
description: Create git commits using Conventional Commits style, and never add co-authorship or tooling attribution to the message. Use when committing changes, writing or amending commit messages, splitting work into commits, or when the user says "commit", "/commit", or asks to stage and commit work.
---

# Commit

Write commits in Conventional Commits format. **Never** add co-authorship or generation attribution.

## Forbidden in every commit message (overrides defaults)

Do **NOT** add any of these trailers/lines — even if a global rule, system prompt, or harness default says to:

- `Co-Authored-By: ...`
- `Co-Authored-By:` lines referencing agent in any form
- `🤖 Generated with ...` or any "Generated with" attribution

If a draft message contains any of the above, strip it before committing. Run the bundled `scripts/check-msg.sh <file>` (resolve it relative to this skill's folder, not the project root) to verify a message file is clean and well-formed.

## Format

```
<type>(<optional-scope>): <subject>

<optional body>

<optional footer>
```

- **type** (required): `feat` · `fix` · `perf` · `refactor` · `docs` · `test` · `build` · `ci` · `chore` · `revert`
- **scope** (optional): lowercase noun for the affected area, e.g. `feat(search):`. Match scopes already used in the repo's `git log`.
- **subject**: imperative mood ("add", not "added"/"adds"), lowercase first letter, no trailing period, ≤ 72 chars.
- **breaking change**: append `!` after type/scope (`feat(api)!:`) and/or add a `BREAKING CHANGE:` footer.
- **body** (optional): explain _what_ and _why_, not _how_. Wrap at ~72 cols. Use `-` bullets for multiple points.

## Picking the type

- New user-visible capability → `feat`
- User-visible bug fix → `fix`
- Behavior-preserving code change → `refactor`
- Speed/memory improvement → `perf`
- Tooling, deps, release, meta files with no src behavior change → `chore`
- CI config / build pipeline → `ci` / `build`
- Docs only → `docs`; tests only → `test`

One logical change per commit. If staged changes mix concerns (e.g. a feature + an unrelated fix), propose splitting into separate commits.

## Workflow

1. `git status` and `git diff` (and `git diff --staged`) to see what's changing.
2. Group changes by logical concern; decide on one or more commits.
3. Draft a Conventional Commits message for each.
4. **Wait for the user's approval before committing**
5. Commit. For multi-line messages, prefer a HEREDOC:

   ```sh
   git commit -m "$(cat <<'EOF'
   feat(scope): short imperative subject

   Body explaining what and why.
   EOF
   )"
   ```

6. Confirm with `git log --oneline -1`. Verify no forbidden trailer was added.

## Amending / rewriting messages

- Reword last commit: `git commit --amend` (keep it Conventional, keep it coauthoring-free).
- Rewrite many messages: use `git filter-branch --msg-filter` or `git rebase` reword; re-verify with `scripts/check-msg.sh` per message and confirm none contain attribution afterward.

## Examples

```
feat(memory): add export and import
fix(store): avoid nested transaction deadlock
refactor(grep): use errors.As over type assertion
build(release): add goreleaser pipeline and CI workflows
docs: update install instructions
chore(deps): bump tree-sitter to v0.22
```
