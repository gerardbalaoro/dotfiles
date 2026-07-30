# Root Commit Case

Make a snapshot commit if needed, create `<backup-branch>` at the
snapshot/current tip, then rebuild the planned commits as new root history. Do
not use `HEAD^`; root rewrites have no parent commit to reset to.

Use an orphan branch or equivalent root-aware Git flow so the snapshot commit
does not become the parent of the new commits. Verify the final tree against
`<backup-branch>` before repointing the original branch.
