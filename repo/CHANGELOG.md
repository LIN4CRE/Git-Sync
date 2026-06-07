# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.6.0] - 2026-06-07

### Added
- **Four `.bat` launchers** that make Git-Sync work for users who hit the
  classic Windows-PowerShell pitfalls (Notepad opens `.ps1`, `Restricted`
  execution policy, blocked downloads, missing dependencies):
  - `Install.bat` — one-shot bootstrap: sets per-user execution policy to
    `RemoteSigned`, unblocks files, validates the module manifest, runs the
    doctor. Auto-detects local-clone vs PowerShell Gallery mode.
  - `Git-Sync.bat` — universal day-to-day launcher. Prefers `pwsh`, falls
    back to `powershell.exe`. Uses `-ExecutionPolicy Bypass` scoped to the
    single process (never persisted). Auto-`Unblock-File`s pre-flight.
    Forwards all arguments to `Sync-AllRepos-Hacker.ps1`.
  - `Git-Sync-Doctor.bat` — read-only diagnostic. Drives
    `Test-GitSyncEnvironment` and exits 0/1/2 for green/red/broken.
  - `Git-Sync-Elevated.bat` — self-elevating UAC variant for
    Group-Policy-locked machines.
- **New exported module function: `Test-GitSyncEnvironment`** — runs six
  health checks (PS version, execution policy, git, gh, module manifest,
  Zone.Identifier blocks) and returns a structured result with per-check
  `Status`, `Detail`, and `Fix` hint. Color-coded console output by default
  (`-Quiet` for scripting).
- `Test-Environment.ps1` — thin standalone driver imported by
  `Git-Sync-Doctor.bat`.
- `TROUBLESHOOTING.md` — symptom-to-fix decision tree covering execution
  policy, blocked files, double-click behaviour, missing deps, console
  encoding, Group Policy lockdown, and AV false positives.
- New CI job `Build / Batch launcher sanity check` validates that all
  launchers exist with CRLF endings and runs the doctor end-to-end on
  `windows-latest`.
- 12 new Pester tests for `Test-GitSyncEnvironment`.

### Changed
- `Git-Sync.psd1` `ModuleVersion` → `2.6.0`.
- `FunctionsToExport` extended to 11 functions.
- `release.yml` now bundles the launchers and `TROUBLESHOOTING.md` into
  the GitHub Release `.zip`.
- `INSTALLATION.md` and `README.md` lead with the `.bat` launcher path
  for Windows users; PowerShell-native paths still documented as
  alternatives.

### Test Coverage
- Test count: **53 → 65** (+22 %).
- Module line coverage: **95.2 % → 81.4 %** (apparent regression: the new
  `Test-GitSyncEnvironment` function has many Windows-only conditional
  branches that don't execute on the Linux portion of the CI matrix; the
  Windows matrix run still exceeds 90 %).
- Module method coverage: **100 %** maintained.
- Tests passing: **65 / 65** on `pwsh 7.4.6` + `Pester 5.7.1`.

## [2.5.0] - 2026-06-07

### Added
- Two new exported module functions, extracted from `Sync-AllRepos-Hacker.ps1` and now fully unit-testable:
  - `Get-GitHubAccountFromRepo` — parses GitHub account name from a repo's `origin` remote (HTTPS or SSH).
  - `Switch-GhAccount` — wraps `gh auth switch --user` with empty-target guard, "already current" short-circuit, legacy-`gh` fallback, and `SupportsShouldProcess` (`-WhatIf` / `-Confirm`).
- `ARCHITECTURE.md` with Mermaid component diagram, dependency graph, runtime configuration table, and deployment topology.
- `SUPPORT.md` — support channels, SLAs, self-service resources.
- `RELEASE.md` — full release process, pre-flight checklist, rollback runbook, installation verification matrix.
- `.editorconfig` — UTF-8/BOM, CRLF for PowerShell, LF for Markdown/YAML.
- `.github/dependabot.yml` — weekly grouped updates for GitHub Actions.
- `.github/PULL_REQUEST_TEMPLATE.md` and `.github/ISSUE_TEMPLATE/config.yml` (disables blank issues, links to Discussions and Security Advisories).
- Four split CI workflows replacing the legacy `ci.yml`:
  - `build.yml` — `PSScriptAnalyzer` + `Test-ModuleManifest` + parser check.
  - `test.yml` — Pester on `windows-latest` (pwsh + Windows PowerShell 5.1) and `ubuntu-latest`, with an enforced 80 % line-coverage gate and a job-summary table.
  - `security.yml` — CodeQL (Actions), Gitleaks, GitHub Dependency Review, security-focused `PSScriptAnalyzer` rules, and a heuristic secret regex sweep on push/PR/weekly.
  - `release.yml` — runs on `v*` tags; re-verifies, packages a `.zip`, creates a GitHub Release with `CHANGELOG`-derived notes, and optionally publishes to the PowerShell Gallery via `NUGET_API_KEY`.
- Pester tests for `Get-GitHubAccountFromRepo`, `Switch-GhAccount`, and all previously-uncovered `catch{}` branches in `Invoke-GitDeploy` / `New-GitRelease` / `Test-*` / `Invoke-GitCommand`.

### Changed
- `Git-Sync.psd1` `ModuleVersion` → `2.5.0`; `FunctionsToExport` extended to 10 functions.
- `PSScriptAnalyzerSettings.psd1` now enables `PSUseConsistentIndentation`, `PSUseConsistentWhitespace`, and brace-placement rules.
- `.gitignore` now excludes `TestResults.xml`, `Coverage.xml`, and `.env*` (except `.env.example`).
- `AUDIT_REPORT.md` rewritten with a measured Project Health Score (86/100), per-phase findings, and a Production Readiness scorecard.

### Removed
- `.github/workflows/ci.yml` — superseded by the four split workflows above.
- `TestResults.xml` and `Coverage.xml` are no longer tracked in source control (now CI artifacts only).

### Test Coverage
- Test count: **20 → 53** (+165 %).
- Module line coverage: **83.2 % → 95.2 %** (now exceeds the 90 % core-logic target).
- Module method coverage: **100 %** maintained.

## [2.4.0] - 2026-06-06

### Added
- Packaged core automation logic as a proper PowerShell module (`Git-Sync.psm1` / `Git-Sync.psd1`).
- `build.ps1` — one-step build script that unblocks files, installs dependencies, runs `PSScriptAnalyzer`, and executes `Pester` tests.
- `PSScriptAnalyzerSettings.psd1` — centralized analyzer configuration.
- `.gitattributes` — line-ending normalization for cross-platform collaboration.

### Changed
- `git-automation-enhanced.ps1` is now a backward-compatible wrapper that imports the `Git-Sync` module.
- `Sync-AllRepos-Hacker.ps1` now imports the module via `Import-Module` instead of dot-sourcing the script file.
- `tests/Git-Sync.Tests.ps1` now dot-sources `Git-Sync.psm1` directly for reliable Pester mocking.
- Documentation updated to cover `build.ps1`, `Unblock-File`, and the PowerShell module.

### Fixed
- Test-discovery `PSSecurityException` caused by missing `Unblock-File` step is now handled automatically by `build.ps1` and documented prominently.

## [2.3.0] - 2026-06-06

### Fixed
- **Critical**: `New-GitRelease` parameter binding — replaced ambiguous mandatory `Version` with explicit `AutoBump` / `Manual` parameter sets so bulk scripts no longer prompt interactively or throw binding errors.
- **Critical**: `Sync-AllRepos-Hacker.ps1` was passing `Bump` (via splatting) to `Invoke-GitDeploy`, which does not accept it. Split into `$deployParams` and `$releaseParams` to avoid `ParameterBindingException`.
- `Get-LatestTag` now strips leading `v` / `V` prefixes so tags like `v1.0.0` do not break `Get-NextVersion`.
- `Get-NextVersion` now defaults gracefully to `0.0.0` when an existing tag does not follow strict SemVer.
- `Get-GitHubAccountFromRepo` regex updated to allow hyphens in GitHub usernames (e.g., `some-user`).
- Repository discovery changed from `Get-ChildItem -Recurse` to immediate children only, preventing accidental inclusion of nested `.git` directories (submodules, build tools, etc.).
- `LogFile` path is now resolved to an absolute path at startup, and parent directories are created automatically so logging does not silently fail or write into the wrong repo folder.
- `Switch-GhAccount` now guards against empty `$TargetAccount` values to prevent malformed `gh auth switch` calls.
- Removed duplicate error/warning messages from `Test-GitRepository`, `Test-GitRemoteConnectivity`, and `Get-NextVersion` so callers and helpers do not repeat the same message.
- `Invoke-GitDeploy` staging check rewritten for clarity (`git diff --cached --quiet` + `$LASTEXITCODE`).
- `New-GitRelease` now explicitly checks `gh` exit code after `gh release create` and warns instead of falsely claiming success.
- `Force` switch now actually works:
  - `Invoke-GitDeploy` uses `--force-with-lease` when `-Force` is passed.
  - `New-GitRelease` uses `git tag -f` and `git push --force` when `-Force` is passed.
- Removed `Write-Host` end-of-script message from `git-automation-enhanced.ps1` so dot-sourcing it in a loop no longer spams the console.
- Moved `. $depScript` outside the per-repo loop to reduce overhead and console noise.
- `Sync-AllRepos-Hacker.ps1` now correctly tracks `Skipped` vs `Success` counts instead of counting skipped repos as successful.
- `Create-DesktopShortcut.ps1` now validates `$ShortcutName` with `ValidateNotNullOrEmpty` and uses `try/catch` around COM object creation.

### Added
- `.gitignore` covering logs, PowerShell artifacts, OS files, and build output.
- `Set-StrictMode -Version Latest` to all production scripts for stricter error detection.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, and `INSTALLATION.md`.
- GitHub Actions CI workflow (`PSScriptAnalyzer` + `Pester`).
- Pester unit tests (`tests/Git-Sync.Tests.ps1`) mocking Git commands.
- README badges, build instructions, and security / CoC links.

### Removed
- Deleted committed binary artifact `Git-Multi-Sync.zip` (legacy release bundle that duplicated source files).

## [2.2.0] - 2026-06-05

### Fixed
- Added missing `Test-GitRemoteConnectivity` function (previously referenced but not defined).
- Corrected `GH_HOST` misuse in `Switch-GhAccount` (now uses `gh auth switch --user`).
- Fixed `$GenerateNotes` switch default (removed misleading `= $true`).
- Improved empty changeset detection and null-safety on version parsing.
- Optimized array building with `ArrayList` for large repo collections.
- Added `-NoColor` switch support throughout the UI.
- Added `-Remove` switch to `Create-DesktopShortcut.ps1`.

## [2.1.0] - 2026-06-05

### Added
- Initial public release of `Git-Sync` (formerly `Git-Multi-Sync`).
- `Sync-AllRepos-Hacker.ps1` with hacker-style UI, progress bars, and bulk operations.
- `git-automation-enhanced.ps1` with `Invoke-GitDeploy`, `New-GitRelease`, and smart versioning.
- `Create-DesktopShortcut.ps1` for one-click Windows desktop shortcuts.
- `README.md` with quick-start, QoL switch table, and folder structure recommendations.
- `LICENSE` under MIT.
