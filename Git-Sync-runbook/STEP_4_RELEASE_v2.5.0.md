# Step 4 — Publish v2.5.0

The annotated tag `v2.5.0` already exists in the bundle. After Step 1 is merged,
push the tag to fire the `release.yml` workflow.

## What's already done locally

- `Git-Sync.psd1` → `ModuleVersion = '2.5.0'`
- `Git-Sync.psd1` → `FunctionsToExport` extended to 10 functions
- `CHANGELOG.md` → new `## [2.5.0] - 2026-06-07` section
- Annotated tag created: `git tag -a v2.5.0` with full release notes

## Push the tag

```bash
git push origin v2.5.0
```

That single push triggers `release.yml`, which will:

1. **Verify** — re-run PSScriptAnalyzer + Pester on the tagged commit.
2. **Package** — assert the manifest version matches the tag, then build
   `Git-Sync-2.5.0.zip` containing module + LICENSE + README + CHANGELOG + SECURITY.
3. **Create GitHub Release** — title `Git-Sync 2.5.0`, body extracted from
   `CHANGELOG.md`, with the `.zip` attached. Pre-release flag auto-set if the
   tag contains a `-` (e.g. `v2.5.0-rc.1`).
4. **Publish to PowerShell Gallery** — only if `NUGET_API_KEY` secret is
   configured in the `powershell-gallery` environment (see Step 7).

## Post-push verification

Follow the **`RELEASE.md` §7 — Post-Release Verification** checklist:

```text
[ ] GitHub Release page exists at https://github.com/LIN4CRE/Git-Sync/releases/tag/v2.5.0
[ ] Tag visible: `git ls-remote --tags origin | grep v2.5.0`
[ ] Workflow run is green in https://github.com/LIN4CRE/Git-Sync/actions
[ ] (If PSGallery enabled) `Find-Module Git-Sync -RequiredVersion 2.5.0`
[ ] Module imports cleanly in a fresh shell
[ ] CHANGELOG link in the release notes resolves
```

## If something goes wrong

Follow **`RELEASE.md` §9 — Rollback**:

```bash
git tag -d v2.5.0
git push origin :refs/tags/v2.5.0
gh release delete v2.5.0 --yes
# Then ship a v2.5.1 patch with the fix.
```
