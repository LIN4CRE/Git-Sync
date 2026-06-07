# Contributing to Git-Sync

First off, thank you for considering contributing to Git-Sync! It's people like you that make this tool better for everyone managing multiple GitHub accounts.

## Getting Started

- Fork the repository on GitHub.
- Clone your fork locally.
- Create a new branch for your work (`git checkout -b feature/your-feature-name`).
- Make your changes and test them thoroughly.
- Commit with clear, descriptive messages.
- Push your branch and open a Pull Request.

## Development Setup

1. **PowerShell 5.1 or 7+** is required.
2. **Unblock files** downloaded from GitHub (otherwise Pester discovery fails with `PSSecurityException`):
   ```powershell
   Get-ChildItem *.ps1, *.psm1, *.psd1 | Unblock-File
   ```
3. **Run the build script** (it installs dependencies, lints, and tests automatically):
   ```powershell
   .\build.ps1
   ```
   Or manually:
   ```powershell
   Install-Module Pester -Force -SkipPublisherCheck
   Install-Module PSScriptAnalyzer -Force
   Invoke-Pester -Path .\tests\Git-Sync.Tests.ps1
   Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
   ```

## Code Style

- Use `Set-StrictMode -Version Latest` in all new scripts.
- Use `[CmdletBinding()]` on all functions.
- Provide comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`) for every public function.
- Prefer `Write-Verbose` / `Write-Debug` over `Write-Host` for non-UI library code.
- Keep the UI script (`Sync-AllRepos-Hacker.ps1`) colorful and interactive; keep the library code (`Git-Sync.psm1`) clean and reusable.
- Add new public functions to `Git-Sync.psm1` and update `Git-Sync.psd1` (`FunctionsToExport`).

## Branch Naming

- `feature/short-description` — new features
- `bugfix/short-description` — bug fixes
- `docs/short-description` — documentation updates
- `refactor/short-description` — code refactoring

## Pull Request Process

1. Update the `CHANGELOG.md` with details of your changes under the `[Unreleased]` section.
2. Ensure all tests pass and PSScriptAnalyzer reports zero `Error` and `Warning` severity issues.
3. If your PR changes behavior, update the relevant `README.md` and `INSTALLATION.md` sections.
4. Request review from a maintainer. PRs without tests or docs updates may be delayed.
5. Once approved, a maintainer will merge and tag a new release if appropriate.

## Reporting Bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:
- PowerShell version (`$PSVersionTable`)
- Git version (`git --version`)
- `gh` CLI version (`gh --version`) if applicable
- Steps to reproduce
- Expected vs actual behavior
- Relevant log output (redact sensitive info)

## Requesting Features

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md). Describe the use case, the problem you're trying to solve, and any ideas you have for implementation.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
