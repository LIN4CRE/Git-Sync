# Step 1 — Merge the Audit Pull Request

The audit work has been committed locally on the branch
**`chore/production-readiness-audit-v2`** with a single squashable commit and the
tag **`v2.5.0`**. Two transfer artifacts are in this workspace:

| File | Purpose |
|---|---|
| `audit-v2.patch` | Standard `git format-patch` output — apply with `git am` |
| `Git-Sync-v2.5.0.bundle` | Full git bundle containing the branch and the tag |

## Option A — Push directly (recommended for the maintainer)

```bash
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync

# Pull the audit branch + tag into the clone
git fetch /path/to/Git-Sync-v2.5.0.bundle 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'

git push origin chore/production-readiness-audit-v2
# (tag pushed later in Step 4)
```

Then open the PR on GitHub:

```bash
gh pr create \
  --base main \
  --head chore/production-readiness-audit-v2 \
  --title "chore: production-readiness audit v2 (release v2.5.0)" \
  --body-file AUDIT_REPORT.md \
  --label "audit,documentation,ci"
```

## Option B — Apply the patch in a fresh clone

```bash
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync
git checkout -b chore/production-readiness-audit-v2
git am < /path/to/audit-v2.patch
git push -u origin chore/production-readiness-audit-v2
gh pr create --base main --title "chore: production-readiness audit v2 (release v2.5.0)" --body "See AUDIT_REPORT.md and CHANGELOG.md."
```

## Merge

Squash-merge once CI is green (see Step 6 for the required checks).

```bash
gh pr merge --squash --delete-branch
```
