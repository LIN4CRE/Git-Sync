# Step 7 (Optional) — Enable Automated PowerShell Gallery Publishing

`release.yml` is already wired to publish to the PowerShell Gallery
**iff** a `NUGET_API_KEY` secret is configured in a deployment environment
named `powershell-gallery`. Without it the job emits a `::warning::` and
exits 0 (the GitHub Release is still created — only Gallery publication is
skipped).

## 1. Create the PowerShell Gallery API key

1. Sign in to <https://www.powershellgallery.com/>.
2. Go to your profile → **API Keys** → **Create**.
3. Settings:
   - **Key name:** `git-sync-ci-publish`
   - **Expires in:** 365 days (set a calendar reminder to rotate)
   - **Scopes:** ☑ *Push new packages and package versions*
   - **Glob pattern:** `Git-Sync`
4. **Copy the key once** — the Gallery will never show it again.

## 2. Create a GitHub Environment

GitHub Environments let you scope secrets to specific workflow jobs and add
manual approval gates. `release.yml` already references
`environment: name: powershell-gallery`.

In the repo:

`Settings` → `Environments` → `New environment` → name **`powershell-gallery`**.

Recommended environment settings:

- ☑ **Required reviewers** (yourself) — adds a manual approval step before
  publishing. Without this, the Gallery publish happens automatically on every
  non-prerelease tag.
- ☑ **Deployment branches:** Selected branches → only `main`
  (so a feature branch tag cannot publish).
- ☐ Wait timer: leave at `0`.

## 3. Add the secret

In the **`powershell-gallery`** environment:

`Add secret` → Name **`NUGET_API_KEY`** → paste the key from step 1.

`gh` CLI alternative:

```bash
gh secret set NUGET_API_KEY \
  --env powershell-gallery \
  --repo LIN4CRE/Git-Sync \
  --body "$YOUR_API_KEY"
```

## 4. Smoke-test with a pre-release

Pre-releases are skipped by `release.yml`'s publish job
(`if: ... && !contains(github.ref_name, '-')`), so they're a safe way to
exercise the rest of the pipeline:

```bash
git tag -a v2.5.1-rc.1 -m "Pre-release smoke test"
git push origin v2.5.1-rc.1
```

Verify the GitHub Release is created and marked as pre-release; the Gallery
publish step should be skipped automatically.

## 5. Cut a real release

After the smoke test:

```bash
git tag -d v2.5.1-rc.1 && git push origin :refs/tags/v2.5.1-rc.1   # clean up
git push origin v2.5.0                                              # the real one
```

Once published, anyone can install:

```powershell
Install-Module Git-Sync -RequiredVersion 2.5.0 -Scope CurrentUser
```

## Rotation

Set a calendar reminder for the key's expiry date (or earlier). When rotating:

```bash
# 1. Create a new key in the Gallery UI.
# 2. Update the GitHub secret in place:
gh secret set NUGET_API_KEY \
  --env powershell-gallery \
  --repo LIN4CRE/Git-Sync \
  --body "$NEW_KEY"
# 3. Revoke the old key in the Gallery UI.
```

The next release will pick up the new key automatically.
