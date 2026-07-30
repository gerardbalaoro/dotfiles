# Existing Commits Plus Uncommitted Changes

Before any reset or rewrite, uncommitted changes must be captured in a snapshot
commit and anchored by the backup branch.

1. Snapshot the full current tracked and untracked state:

   ```bash
   git add -A
   git commit -m "temp: snapshot before compose-commits"
   ```

2. If the snapshot commit fails, stop and report the failure. If hooks are
   clearly the blocker, ask whether to retry with:

   ```bash
   git commit --no-verify -m "temp: snapshot before compose-commits"
   ```

3. Treat the snapshot commit as the old tip and create `<backup-branch>` there:

   ```bash
   git branch "<backup-branch>" HEAD
   ```

   If overwrite was approved:

   ```bash
   git branch -f "<backup-branch>" HEAD
   ```

4. If backup creation fails, stop immediately, do not reset, report the snapshot
   SHA, and ask how to proceed.

5. Resolve `base` as the parent of the oldest original commit in scope, not the
   parent of the snapshot commit.

6. Turn the combined range into editable changes:

   ```bash
   git reset --soft "<base>"
   git reset --mixed
   ```

7. Build the planned commits in order.

8. Compare old and new history when possible:

   ```bash
   git range-diff "<base>..<backup-branch>" "<base>..HEAD"
   ```

9. Verify the final tree:

   ```bash
   git diff --quiet "<backup-branch>" HEAD
   git status --short
   ```

The snapshot backs up staged changes, unstaged tracked changes, and untracked
files. It does not include ignored files.

The snapshot commit is only a recovery anchor and input state. It should not
survive as a final commit unless the user explicitly wants that.
