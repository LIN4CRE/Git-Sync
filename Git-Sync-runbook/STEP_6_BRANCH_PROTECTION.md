# Step 6 — Branch Protection

Apply branch-protection rules to `main` so the required CI checks must pass
before merge.

## Required status checks

These are the exact check names emitted by the four new workflows after Step 1
merges and the first CI run completes:

| Workflow | Job | Check name (as it appears in the Branch Protection UI) |
|---|---|---|
| `build.yml` | `lint` | `Build / PSScriptAnalyzer` |
| `build.yml` | `manifest` | `Build / Module Manifest Validation` |
| `build.yml` | `syntax` | `Build / PowerShell Parse Check` |
| `test.yml` | `pester` (matrix include) | `Test / Pester (windows-latest / pwsh)` |
| `security.yml` | `codeql` | `Security / CodeQL (actions)` |
| `security.yml` | `gitleaks` | `Security / Gitleaks (secret scan)` |

> **Important:** GitHub will only let you "require" a check after it has
> successfully run **at least once** on the default branch. So the recommended
> order is:
>
> 1. Merge the audit PR (Step 1).
> 2. Wait for the first push-to-`main` CI run to complete.
> 3. Then apply the rules below.

## Option A — Apply via the GitHub UI

`Settings` → `Branches` → `Branch protection rules` → `Add rule`:

- **Branch name pattern:** `main`
- ☑ **Require a pull request before merging**
  - ☑ Require approvals: `1`
  - ☑ Dismiss stale pull request approvals when new commits are pushed
- ☑ **Require status checks to pass before merging**
  - ☑ Require branches to be up to date before merging
  - Add the six checks listed above
- ☑ **Require conversation resolution before merging**
- ☑ **Require linear history** (recommended for `main`)
- ☑ **Do not allow bypassing the above settings**

## Option B — Apply via `gh` CLI (config-as-code)

Save the JSON below as `branch-protection.json`:

```json
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Build / PSScriptAnalyzer" },
      { "context": "Build / Module Manifest Validation" },
      { "context": "Build / PowerShell Parse Check" },
      { "context": "Test / Pester (windows-latest / pwsh)" },
      { "context": "Security / CodeQL (actions)" },
      { "context": "Security / Gitleaks (secret scan)" }
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
```

Then apply with the GitHub REST API via `gh`:

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  repos/LIN4CRE/Git-Sync/branches/main/protection \
  --input branch-protection.json
```

Verify:

```bash
gh api repos/LIN4CRE/Git-Sync/branches/main/protection \
  | jq '{checks: .required_status_checks.checks, reviews: .required_pull_request_reviews.required_approving_review_count, linear: .required_linear_history.enabled, conv: .required_conversation_resolution.enabled}'
```

## Solo-maintainer note

If you're the only committer, you may want to **leave `enforce_admins` set to
`false`** (the default above) so that you can hot-fix `main` without a PR if
absolutely necessary. The CI checks will still run and you'll see them fail in
the UI, but you can override. Flip `enforce_admins` to `true` once you add a
second maintainer.
