---
name: compose-commits
description: Compose uncommitted changes, a linear commit range, branch, or PR into logical commits. Use when the user wants to split, clean up, organize, or rewrite commits. Always inspect first, propose a breakdown, get one confirmation, create a backup branch, then rewrite.
---

# Compose Commits

Turn the requested work into logical commits that are easy to review,
explain, and revert.

The requested work may be:

- current uncommitted changes
- a linear commit range ending at `HEAD`
- a branch or PR relative to a base
- a linear commit range plus uncommitted changes

Infer the execution approach from the resolved scope.

Preserve the final tree exactly unless the user explicitly asks to change
content.

## Hard Rules

Before confirmation, run read-only inspection commands only.

Do not stage, commit, reset, switch branches, create or move branches, modify
files, generate files, push, rebase, cherry-pick, or rewrite history before the
user confirms the proposed breakdown.

Never:

- guess the base silently
- rewrite merge commits
- rewrite a range not ending at `HEAD` unless the user accepts rewriting later
  commits too
- use derived files as commit boundaries
- force-push unless explicitly asked
- delete the backup branch unless explicitly asked after successful composition
- continue past risky ambiguity

## Resolve Scope

Resolve scope in this order:

1. If the user gave an explicit revision range, use it.
2. If the user said `against <branch>` or `against <commit>`, resolve the work
   as changes on `HEAD` since the merge-base with that target.
3. If the user said `this PR`, resolve the PR base branch from repo tooling if
   available.
4. If `this PR` cannot be resolved directly, infer the remote default branch,
   say that you inferred it, and resolve the work as changes on `HEAD` since the
   merge-base with that inferred base.
5. If the user said `this branch` with no target, ask for the target branch.

Interpretation rules:

- `working tree`, `unstaged changes`, `uncommitted changes`, `my changes`:
  current uncommitted changes
- `this branch against main`: commits reachable from `HEAD` and not from `main`
- `this PR`: commits from the PR base to `HEAD`
- `last N commits`: the last `N` commits ending at `HEAD`
- `last N commits plus my changes`: commit range plus uncommitted changes
- `recent commits and current changes`: commit range plus uncommitted changes

If the user asks broadly to compose, clean up, or organize commits, inspect both
existing commits and uncommitted changes, then propose the intended scope. Do not
include dirty worktree changes in a history rewrite unless the proposal says so
and the user confirms.

Stop and ask if:

- the resolved range contains merge commits
- the resolved range does not end at `HEAD`
- the worktree is dirty and the requested scope is ambiguous
- recomposing would include commits the user probably did not intend
- the PR/base cannot be resolved
- multiple PRs match the current branch
- submodule pointer changes are in scope
- sparse checkout or missing objects may make verification unreliable
- ignored files appear to be part of the requested scope

## Historical Commits

If the user asks to split or recompose a commit that is not `HEAD`, explain that
Git must also rewrite every later commit on the current branch.

Do not ask for a separate preflight confirmation. Include the later commits in
the proposed scope, call out that their SHAs will change, and rely on the single
rewrite confirmation unless this creates risky ambiguity that requires stopping.

Example proposal note:

```text
That commit is not the tip of the branch. This plan includes the later commits
too, because Git must rewrite them as well; their SHAs will change.
```

## Inspect Before Proposal

Gather with read-only Git or repo-tooling commands:

- current branch and upstream
- pushed/shared status
- worktree status, including untracked files
- base branch or base commit
- commits in scope, oldest to newest
- recent commit subjects for message style
- changed files grouped by intent
- whether the repo has submodules
- whether sparse checkout is enabled
- whether ignored files appear relevant
- whether the backup branch exists

For PRs, use read-only repo tooling if available to identify the PR base branch.

Only inspect ignored files if they appear relevant to the requested scope.

Treat the branch as pushed/shared if it has an upstream. If `HEAD` equals its
upstream, report that it is in sync. If `HEAD` is ahead, note that a force-push
may be needed after rewriting. If `HEAD` is behind or diverged, stop and ask. If
there is no upstream, report that shared status is unknown.

## Split Rules

Split by intent, not file layout.

A good logical commit:

- does one thing
- can be explained in one sentence
- can be reviewed independently
- can be reverted independently

Prefer this order:

1. prerequisite refactor or rename
2. behavior change
3. tests
4. docs or cleanup

Do not split just because files differ. Split when a reviewer would want to
review or revert the change separately.

If same-file edits must be split, manually edit the whole file into each logical
state, stage the whole file, commit, and continue. If the edits are too
interleaved to split safely, ask whether to keep them together.

## Derived Files

Derived files are artifacts, not commit boundaries.

Plan commits from source intent. Do not split just because lockfiles, generated
code, or build outputs changed.

For each commit:

1. Edit or revert the working tree so relevant source, manifest, schema, and
   config files contain only this commit's logical changes. Staging is not
   enough because most tools read the working tree, not the Git index.
2. Regenerate derived files with the repo's normal command.
3. Stage the source/input files and only the tracked derived files belonging to
   this commit.
4. Commit them together.
5. Continue editing toward the next logical state.

Attach derived files to their cause:

- lockfiles with dependency manifest changes
- generated code with the source, schema, or config that generated it
- build outputs only if intentionally tracked

Avoid cherry-picking generated or lockfile hunks. Stop if regeneration is
unavailable, flaky, or produces unrelated changes.

## Commit Message Style

Use this priority:

1. explicit user instruction
2. existing repo convention from recent history
3. a short clear default

Mirror the local style if the repo uses prefixes, tickets, or conventional
commits.

Do not invent a new style unless the user asked for it.

## Backup Branch

Generate the backup branch name from the current branch name.

Default format:

```text
backup/compose-commits-<sanitized-branch>
```

Sanitize the current branch name like this:

- if the branch name is empty or `HEAD`, use `detached-head`
- replace `/`, whitespace, and other non-alphanumeric characters with `-`
- keep only letters, numbers, `.`, `_`, and `-`
- collapse repeated `-`
- trim leading and trailing `.`, `_`, and `-`
- if the result is empty, use `branch`

Throughout this skill, call the resolved backup branch name `<backup-branch>`.

Check whether `<backup-branch>` already exists before proposing.

Do not ask separately about backups. Backup choice is part of the single
confirmation prompt.

When the user chooses overwrite, move the branch explicitly.

When the user chooses a new backup, append a safe datetime suffix to the resolved
backup branch name and use that as `<backup-branch>` for the rest of the
operation.

Suffix format:

```text
YYYYMMDD-HHMMSS
```

Example:

```text
backup/compose-commits-feature-auth-20260502-150000
```

Never delete the backup branch unless the user explicitly confirms cleanup after
successful composition and, if needed, successful push.

## Proposal

Before any write action, show the plan in one message:

1. resolved scope
2. base branch or base commit
3. whether the branch appears pushed or shared
4. proposed commits in order, one line each
5. derived-file handling
6. commit-message style to follow
7. backup plan, including:
   - resolved `<backup-branch>`
   - whether it already exists
   - if it exists, that the user will choose overwrite or datetime-suffixed
     backup in the single confirmation prompt
8. risks or clarifications

Then, in a separate follow-up message, ask for the single confirmation choice.

If `<backup-branch>` does not exist:

1. Proceed with rewrite
2. Revise the plan

If `<backup-branch>` exists:

1. Proceed with rewrite and overwrite existing backup
2. Proceed with rewrite and create new backup with datetime suffix
3. Revise the plan

Do not begin any write action until the user selects an option.

## Execute

After confirmation, load and follow exactly one reference:

- [Uncommitted Changes Only](references/uncommitted-changes-only.md): current
  scope is only uncommitted work, including staged, unstaged, or untracked files.
- [Existing Commits Only](references/existing-commits-only.md): current scope is
  a clean-worktree linear commit range ending at `HEAD`.
- [Existing Commits Plus Uncommitted Changes](references/existing-commits-plus-uncommitted.md):
  current scope is a linear commit range ending at `HEAD`, and the approved
  proposal explicitly includes current uncommitted work.
- [Root Commit Case](references/root-commit-case.md): repo has no commits, the
  rewrite includes the root commit, or a temporary snapshot has no parent.

## Finish

If final tree verification fails:

- stop
- report the mismatch
- show the backup branch name
- report `git status --short`
- do not push
- do not delete the backup branch
- do not attempt cleanup automatically

After successful composition, report:

- backup branch name
- new commits in order
- whether the final tree matches the backup
- remaining uncommitted files, if any
- whether `git push --force-with-lease` would be required

Then ask the user to choose:

1. force-push with lease if needed
2. force-push with lease if needed, then delete the backup branch
3. do nothing

Only mention force-push if the rewritten branch would need it.

Never force-push or delete the backup branch unless the user explicitly chooses
that option.

If no push is needed, omit force-push options and ask whether to delete the
backup branch or do nothing.

## Recovery

If execution is interrupted or a split goes wrong:

- stop immediately
- report current `HEAD`
- report worktree state
- report backup branch name
- do not auto-clean up
- do not auto-force-push
- recover from the backup branch only after the user confirms

Useful recovery command:

```bash
git reset --hard "<backup-branch>"
```
