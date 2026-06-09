# Changelog

All notable changes to Git-Sync are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [2.7.0] - 2026-06-09

### Added
- **`Sync-GitRepository`** — new convenience function combining `Invoke-GitDeploy` + optional `New-GitRelease` in a single call. Supports `-Path`, `-Message`, `-BumpVersion`, `-Remote`, `-Force`, `-GenerateNotes`.
- `IconUri` in module manifest pointing to `hacker-icon.png` for PowerShell Gallery listing.
- Expanded PSData `Tags` in `.psd1`: added `MultiAccount`, `BulkSync`, `SemanticVersioning`, `GitHubCLI`, `CI`, `Release-Automation`.
- Interactive numbered menu in `start.ps1` with 6 quick-action options and runtime info table.
- Tests for `Sync-GitRepository` added to test suite.

### Changed
- **`Sync-AllRepos-Hacker.ps1`**: upgraded banner, 40-char progress bar, per-repo `@account` label, elapsed-time and success-rate display in summary, cleaner section dividers.
- **`start.ps1`**: full rewrite — environment info (PS version, git, gh), interactive numbered menu.
- `Export-ModuleMember` expanded to include `Sync-GitRepository` (12 exported functions total).
- `Git-Sync.psd1` description improved for PowerShell Gallery discoverability.
- Module header comment corrected: removed duplicate `Get-GitHubAccountFromRepo` entry, accurate function list.
- Output polish in `Invoke-GitDeploy` and `New-GitRelease` (`+` / `-` / `~` prefix icons).
- `README.md` rewritten: full feature table, complete API reference, all QoL switches documented.

### Removed
- `AUDIT-REPORT.md` — duplicate of `AUDIT_REPORT.md`.
- `git-automation-enhanced.ps1` — deprecated legacy wrapper (use `Import-Module Git-Sync.psd1` directly).

---

## [2.6.0] - 2026-06-07

### Added
- `Get-GitHubAccountFromRepo` — extracts the GitHub account (owner) from a repo's remote URL, supporting both HTTPS and SSH formats.
- `Switch-GhAccount` — switches the active `gh` CLI account with automatic detection, fallback modes, and `-WhatIf` support.
- `Test-GitSyncEnvironment` — environment doctor that validates PowerShell version, execution policy, Git/gh CLI availability, and module integrity with structured result output.
- `tests/Git-Sync.Helpers.Tests.ps1` — 12 unit tests covering account helpers and switcher.
- `tests/Git-Sync.Failure.Tests.ps1` — 16 unit tests covering failure paths, edge cases, catch-block coverage, and rollback scenarios.
- `tests/Git-Sync.Doctor.Tests.ps1` — 12 unit tests covering `Test-GitSyncEnvironment` output structure and behavior.
- `.editorconfig` — cross-IDE formatting configuration for PowerShell, YAML, Markdown, and JSON files.
- `.gitignore` now excludes `TestResults.xml`, `Coverage.xml`, `.local/`, `modules/`, and `secrets/`.
- Split CI/CD workflows: `build.yml`, `test.yml`, `security.yml`, `release.yml` replacing single `ci.yml`.
- `dependabot.yml` and `.github/ISSUE_TEMPLATE/config.yml` for automated dependency updates and issue management.

### Changed
- `Invoke-GitDeploy` now issues a structured warning when remote connectivity check fails, rather than aborting.
- `Get-LatestTag` strips `v`/`V` prefix consistently.
- `New-GitRelease` AutoBump and Manual are separated into distinct parameter sets.
- Moved module import outside per-repo loop in `Sync-AllRepos-Hacker.ps1` for efficiency.

### Fixed
- `LogFile` relative path resolution and directory auto-creation in `Sync-AllRepos-Hacker.ps1`.
- Success/skip/fail counting to avoid misleading totals.
- Double error/warning messages in helper functions.
- GitHub username regex updated to allow hyphens (`some-user`).
- `New-GitRelease` parameter binding between `AutoBump` and `Manual` sets.

---

## [2.5.0] - 2026-06-01

### Added
- Bulk sync orchestrator in `Sync-AllRepos-Hacker.ps1` with hacker-style progress bars and per-repo status icons.
- QoL flags: `ContinueOnError`, `ShowGitStatus`, `PauseBetweenRepos`, `OnlyShowFailures`, `NoColor`, `LogFile`.
- Pester 5 test suite: 67 tests across 4 files, ≥80% coverage enforced in CI.
- GitHub Actions workflows: `build.yml`, `test.yml`, `security.yml`, `release.yml`.
- `PSScriptAnalyzerSettings.psd1` for project-specific lint configuration.

### Changed
- Module renamed from *Git-Multi-Sync* to **Git-Sync**.
- `New-GitRelease` now calls `Invoke-GitDeploy` internally before tagging.
- Repository published to PowerShell Gallery as `Git-Sync`.

---

## [2.0.0] - 2026-05-15

### Added
- `New-GitRelease` with `AutoBump` and `Manual` parameter sets.
- `Invoke-GitDeploy` with `Force` (`--force-with-lease`) and `WhatIf` support.
- `Get-NextVersion` supporting Major / Minor / Patch bumps and prerelease suffix.
- Initial PowerShell Gallery publication.

---

## [1.0.0] - 2026-04-01

### Added
- Initial release of the Git deployment automation script.
- Basic `git add`, `commit`, `push` wrapper.
