# Uncommitted Changes Only

This approach intentionally rebuilds staging from scratch. Original staged versus
unstaged boundaries are not preserved.

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

3. Create `<backup-branch>` at the snapshot commit:

   ```bash
   git branch "<backup-branch>" HEAD
   ```

   If overwrite was approved:

   ```bash
   git branch -f "<backup-branch>" HEAD
   ```

4. If backup creation fails, stop immediately, do not reset, report the snapshot
   SHA, and ask how to proceed.

5. Restore the snapshot into editable changes:

   ```bash
   git reset --mixed "HEAD^"
   ```

6. Build the planned commits in order.

7. Verify the final tree:

   ```bash
   git diff --quiet "<backup-branch>" HEAD
   git status --short
   ```

The snapshot backs up staged changes, unstaged tracked changes, and untracked
files. It does not include ignored files.
