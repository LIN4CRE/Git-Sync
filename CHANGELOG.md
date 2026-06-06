# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
