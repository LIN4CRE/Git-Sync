# Git-Sync

**Powerful multi-account Git automation toolkit** — bulk sync, smart semantic versioning, automatic GitHub CLI account switching, and a hacker-style terminal UI.

> **Previously known as** *Git-Multi-Sync*. All functionality is preserved. If you have an older clone, update your remote:
> ```bash
> git remote set-url origin https://github.com/LIN4CRE/Git-Sync.git
> ```

---

## Features

| Feature | Details |
|---|---|
| **Smart Semantic Versioning** | Auto-bump Patch / Minor / Major with prerelease (`-beta.1`) support |
| **Multi-Account GitHub** | Auto-detect and switch `gh` CLI accounts per repository |
| **Hacker-Style Terminal UI** | Progress bars, color-coded status, animated sync output |
| **Bulk Sync Orchestrator** | Scan folders, discover repos, process in one shot |
| **One-Liner API** | `Sync-GitRepository` wraps deploy + release in a single call |
| **Dry Run / WhatIf** | Preview everything before touching any repository |
| **Environment Doctor** | `Test-GitSyncEnvironment` diagnoses PS, Git, gh, and module health |
| **Logging Mode** | `‑LogFile path.log` for CI-friendly silent output |
| **QoL Flags** | ContinueOnError, ShowGitStatus, PauseBetweenRepos, NoColor, Confirm |
| **12 Exported Functions** | Full PowerShell module with CmdletBinding + SupportsShouldProcess |
| **80%+ Test Coverage** | 67 Pester 5 tests across 4 files, enforced in CI |

---

## Quick Start

### 1. Install from PowerShell Gallery

```powershell
Install-Module Git-Sync -Scope CurrentUser
Import-Module Git-Sync
```

### 2. Or clone and import directly

```powershell
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync
Import-Module .\Git-Sync.psd1
```

### 3. Bulk sync all repos (hacker UI)

```powershell
.\Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch -AutoSwitchGh
```

### 4. Sync a single repo (module API)

```powershell
# Deploy only (add + commit + push)
Invoke-GitDeploy -Message "feat: my change"

# Deploy + create a Patch release tag
Sync-GitRepository -BumpVersion Patch

# Explicit version release
New-GitRelease -Version "2.0.0" -GenerateNotes
```

---

## Module API (12 Functions)

| Function | Purpose |
|---|---|
| `Sync-GitRepository` | Deploy + optional release in one call |
| `Invoke-GitDeploy` | Stage → commit → push |
| `New-GitRelease` | Create an annotated tag + GitHub release |
| `Get-NextVersion` | Compute next semantic version string |
| `Get-LatestTag` | Read the latest `git tag` (strips `v` prefix) |
| `Test-GitSyncEnvironment` | Full environment health check |
| `Switch-GhAccount` | Switch the active `gh` CLI account |
| `Get-GitHubAccountFromRepo` | Extract GitHub username from remote URL |
| `Test-GitRepository` | Check if CWD is inside a git repo |
| `Test-GitRemoteConnectivity` | Probe remote reachability |
| `Invoke-GitCommand` | Low-level git wrapper with error handling |
| `Test-GhAuthentication` | Check `gh auth status` |

---

## Bulk Sync — Hacker UI

`Sync-AllRepos-Hacker.ps1` discovers every Git repository under your configured `BaseFolders`, auto-detects the GitHub account for each, optionally switches the `gh` CLI, and runs deploy + release with a live progress bar.

```powershell
# Deploy only, keep going on error
.\Sync-AllRepos-Hacker.ps1 -Action Deploy -ContinueOnError

# Full release with auto-patch bump, dry run first
.\Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch -WhatIf

# Silent mode with full log
.\Sync-AllRepos-Hacker.ps1 -Action Deploy -LogFile .\sync.log

# Target specific folders
.\Sync-AllRepos-Hacker.ps1 -BaseFolders "C:\Projects","C:\Work" -Action Deploy
```

### QoL Switches

| Switch | Effect |
|---|---|
| `-AutoSwitchGh` | Switch `gh` CLI account per repository automatically |
| `-ContinueOnError` | Don't abort on first failure |
| `-ShowGitStatus` | Show changed-file count per repo |
| `-PauseBetweenRepos` | Interactive pause after each repository |
| `-OnlyShowFailures` | Suppress per-repo output; show only failures |
| `-WhatIf` | Dry run — discover but make no changes |
| `-NoColor` | Disable ANSI colors for plain-text logging |
| `-Confirm` | Require ENTER before processing begins |
| `-LogFile <path>` | Write timestamped log alongside console output |

---

## Environment Doctor

```powershell
Test-GitSyncEnvironment
```

Checks:
- PowerShell version (5.1 minimum, 7+ recommended)
- Execution policy
- `git` CLI presence and version
- `gh` CLI presence and authentication
- Module manifest validity
- Windows Zone.Identifier file-block status

```
 Git-Sync Environment Doctor

 [ OK ] PowerShell version          PowerShell 7.5.1
 [ OK ] Execution policy            Effective: Bypass
 [ OK ] git CLI                     git version 2.47.0
 [WARN] gh CLI (optional)           gh installed but not authenticated
 [ OK ] Git-Sync module             Loaded version 2.7.0
 [ OK ] File unblock status         Not on Windows; Zone.Identifier not applicable

 Result: HEALTHY  (1 warning(s), 0 failure(s))
```

---

## Build & Test

```powershell
# Full build: lint + test
.\build.ps1

# Skip linting
.\build.ps1 -SkipAnalyze

# Skip tests
.\build.ps1 -SkipTest
```

Tests are in `tests/` using **Pester 5** with ≥80% code coverage enforced in CI.

---

## Installation (Windows desktop)

```powershell
.\Install.bat          # installs module to CurrentUser scope, creates shortcuts
.\Git-Sync.bat         # run Sync-AllRepos-Hacker.ps1 with execution policy bypass
.\Git-Sync-Doctor.bat  # run Test-GitSyncEnvironment
.\Git-Sync-Menu.bat    # interactive menu launcher
```

---

## Requirements

| Tool | Version | Required for |
|---|---|---|
| PowerShell | 5.1+ (7+ recommended) | Everything |
| Git | Any modern | All git operations |
| gh CLI | Any | Multi-account switching & GitHub releases |

---

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| `build.yml` | Push / PR to main | PSScriptAnalyzer lint + manifest validation + syntax check |
| `test.yml` | Push / PR | Pester 5 tests on Windows + Linux, ≥80% coverage |
| `security.yml` | Push / PR | CodeQL + Gitleaks + dependency review |
| `release.yml` | `v*.*.*` tag push | Verify → publish to PowerShell Gallery + GitHub Release |

---

## License

[MIT](LICENSE) © 2026 LIN4CRE
