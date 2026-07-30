# Existing Commits Only

Require a clean worktree unless the user explicitly includes uncommitted changes.

1. Resolve `base` as the parent of the oldest commit in scope.
2. Create `<backup-branch>` at current `HEAD`:

   ```bash
   git branch "<backup-branch>" HEAD
   ```

   If overwrite was approved:

   ```bash
   git branch -f "<backup-branch>" HEAD
   ```

3. Turn the range into editable changes:

   ```bash
   git reset --soft "<base>"
   git reset --mixed
   ```

4. Build the planned commits in order.

5. Compare old and new history when possible:

   ```bash
   git range-diff "<base>..<backup-branch>" "<base>..HEAD"
   ```

6. Verify the final tree:

   ```bash
   git diff --quiet "<backup-branch>" HEAD
   git status --short
   ```
