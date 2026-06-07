# Release Process

This document is the **single source of truth** for cutting a Git-Sync release. It is written so that any maintainer (or future you) can ship a release confidently in under 30 minutes.

---

## 1. Versioning Policy

Git-Sync follows **[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)**:

| Bump | Trigger | Examples |
|---|---|---|
| **Major** (`X.0.0`) | Breaking change to a public function signature, removed exported function, behavioural change requiring user action. | Removing `Invoke-GitDeploy`; renaming `-Bump` to `-BumpType`. |
| **Minor** (`x.Y.0`) | Backward-compatible feature, new exported function, new parameter, new switch. | Adding `-Tag` to `Invoke-GitDeploy`; new `Push-GitRepository` cmdlet. |
| **Patch** (`x.y.Z`) | Bug fixes, doc-only changes, internal refactors, dependency bumps that don't affect API. | Fixing `Get-LatestTag` regex; updating CI versions. |

Pre-releases use SemVer pre-release identifiers: `2.5.0-beta.1`, `2.5.0-rc.1`. Pre-release tags are pushed but `release.yml` does **not** publish them to the PowerShell Gallery by default — flip `PUBLISH_PRERELEASE=true` in the workflow to opt in.

> Tags **must** be prefixed with `v` (e.g., `v2.4.1`) so that `release.yml`'s `on: push: tags: [ 'v*' ]` trigger fires. The module manifest version itself omits the prefix.

---

## 2. Release Cadence

- **Patch** releases ship as needed, ideally within 1 week of a confirmed regression.
- **Minor** releases ship roughly every 4–6 weeks, batching multiple features.
- **Major** releases are rare and announced at least 2 weeks in advance via a pinned discussion.

---

## 3. Pre-Release Checklist

Run this list **on the `main` branch** with a clean working tree:

```text
[ ] CI is green on the latest commit (build / test / security all ✅)
[ ] `git status` shows no uncommitted changes
[ ] `git pull --ff-only origin main` is up to date
[ ] CHANGELOG.md has an `[Unreleased]` section with all user-visible changes
[ ] All issues/PRs targeted at this milestone are closed/merged
[ ] No open Dependabot PRs that should be in this release
[ ] `.\build.ps1` passes locally (lint + tests + coverage ≥ 80%)
[ ] Module manifest `ModuleVersion` is updated in `Git-Sync.psd1`
[ ] Comment-based help (`.SYNOPSIS`, `.DESCRIPTION`) is up to date for every exported function
[ ] README "Quick Start" snippets still work against the current code
[ ] Any new exported functions are listed in `Git-Sync.psd1` `FunctionsToExport`
```

If anything is unchecked, fix it before proceeding.

---

## 4. Cutting the Release

### Option A — One-shot via the module itself (dogfooding)

```powershell
Import-Module .\Git-Sync.psd1 -Force
New-GitRelease -Bump Patch -GenerateNotes
```

This will:
1. Stage + commit any pending changes.
2. Compute the next version from the latest `v*` tag.
3. Push the commit.
4. Create an annotated tag (`v2.4.1`) and push it.
5. Create a GitHub Release via `gh` with auto-generated notes.

### Option B — Manual

```bash
# 1. Bump version in the manifest
#    edit Git-Sync.psd1 -> ModuleVersion = '2.4.1'
git add Git-Sync.psd1 CHANGELOG.md
git commit -m "chore(release): 2.4.1"
git push origin main

# 2. Tag and push
git tag -a v2.4.1 -m "Release 2.4.1"
git push origin v2.4.1
```

In **either case**, `release.yml` will run on the new tag and:

1. Re-run the test suite.
2. Build a PowerShell Gallery–ready package (`.nupkg`).
3. Create / update a GitHub Release with the package attached.
4. Optionally `Publish-Module` to the PowerShell Gallery (requires `NUGET_API_KEY` secret).

---

## 5. CHANGELOG Discipline

Every release **must** update [`CHANGELOG.md`](CHANGELOG.md) following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/):

```markdown
## [2.4.1] - 2026-06-15

### Added
- …

### Changed
- …

### Fixed
- …

### Security
- …
```

Before tagging, move everything under `[Unreleased]` to the new version section and reset `[Unreleased]` to empty.

---

## 6. Release Notes Template

Use this as the body when filling in the GitHub Release (paste over `gh`'s auto-generated notes if needed):

```markdown
## What's new in v2.4.1

### ✨ Highlights
- One-line summary of the most important user-visible change.

### 🐛 Fixes
- `<area>`: short description (#issue / commit).

### 🔒 Security
- (only if relevant) what was fixed and how severe.

### ⬆️ Upgrade Notes
- (only if there are non-trivial changes) what users need to do.

### 📦 Install / Upgrade
```powershell
# From PowerShell Gallery
Install-Module Git-Sync -RequiredVersion 2.4.1 -Scope CurrentUser

# Or from the GitHub Release zip
# (download and extract, then Import-Module .\Git-Sync.psd1 -Force)
```

**Full changelog:** https://github.com/LIN4CRE/Git-Sync/blob/main/CHANGELOG.md
```

---

## 7. Post-Release Verification

Immediately after `release.yml` completes:

```text
[ ] GitHub Release page exists and lists the .nupkg / .zip artifact
[ ] Tag is visible: `git ls-remote --tags origin`
[ ] Module is installable: `Find-Module Git-Sync -RequiredVersion <ver>` (only if Gallery publish enabled)
[ ] Module imports cleanly in a fresh shell:
        Install-Module Git-Sync -RequiredVersion <ver> -Force -Scope CurrentUser
        Import-Module Git-Sync -Force
        Get-Command -Module Git-Sync   # should list 8 exported functions
[ ] Smoke test: `New-GitRelease -WhatIf -Bump Patch` in a throwaway repo returns the expected next version
[ ] CHANGELOG link in the release notes resolves
[ ] No new issues filed within 24 hours pointing at a regression
```

If any check fails, see **§9 Rollback**.

---

## 8. Upgrade Guidance for Users

Every release section in `CHANGELOG.md` that contains a **`### Changed`** or **`### Removed`** entry must also document the upgrade steps. Suggested phrasing:

> **Upgrading from 2.3 → 2.4:** No code changes required. `git-automation-enhanced.ps1` is now a thin compatibility shim; prefer `Import-Module Git-Sync` directly.

For **breaking** changes, add a dedicated `### ⚠️ Breaking Changes` section at the top of the release entry and link to a migration guide in `/docs/migrations/` if non-trivial.

---

## 9. Rollback

If a release introduces a regression:

```bash
# 1. Delete the bad tag locally and remotely
git tag -d v2.4.1
git push origin :refs/tags/v2.4.1

# 2. Delete the GitHub Release
gh release delete v2.4.1 --yes

# 3. (If published to Gallery) unlist the version
#    The Gallery does not allow deletion, only "unlist":
#    https://www.powershellgallery.com/packages/Git-Sync/<ver>/Manage
```

Then **immediately** ship a patch release (`v2.4.2`) with the fix and a `### Fixed` entry that references the rolled-back version.

---

## 10. Installation Verification Matrix

`release.yml` automatically runs this matrix on the new tag. You can run it locally before tagging too:

| OS | PowerShell | How |
|---|---|---|
| Windows Server 2022 | Windows PowerShell 5.1 | `windows-latest` runner |
| Windows Server 2022 | PowerShell 7 (pwsh) | `windows-latest` + `pwsh` shell |
| Ubuntu 22.04 | PowerShell 7 (pwsh) | `ubuntu-latest` + `pwsh` shell — module + Pester only; UI script not validated on Linux |

A release is considered **shippable** only if **all three** cells go green.

---

## 11. Communications

After the release succeeds:

1. Pin a short announcement to GitHub Discussions (`Announcements` category).
2. Update the repo description / topics if the release introduces new headline features.
3. (Optional) Post to relevant PowerShell / Git automation communities.

---

## Appendix — Release Owner Responsibilities

The release owner (whoever pushes the tag) is responsible for:

- Triaging issues filed in the **24 hours** following the release.
- Authoring or coordinating the patch release if a rollback is required.
- Updating the milestone for the next release with anything that slipped.
