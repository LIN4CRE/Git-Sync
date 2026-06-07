# Troubleshooting Git-Sync on Windows

Many users hit the same handful of Windows-specific PowerShell pitfalls.
This page maps each visible symptom to the underlying cause and the
fastest fix. **If in doubt, run `Git-Sync-Doctor.bat`** — it prints a
pass/fail report with a one-line fix for every failing check.

## Quick-Triage Decision Tree

```text
.ps1 won't run?
├── "running scripts is disabled on this system"   → §1 Execution Policy
├── "cannot be loaded because it is not digitally signed" / PSSecurityException
│   on test discovery                              → §2 Blocked Files
├── Double-clicking opens Notepad / VS Code         → §3 File Association
├── "'git' is not recognized..."                    → §4 Missing Dependencies
├── "The term 'gh' is not recognized..."            → §4 Missing Dependencies
├── "Could not find module 'Git-Sync'"              → §5 Module Loading
├── Garbled colours / Unicode boxes                 → §6 Console Encoding
└── Anything else                                   → Run Git-Sync-Doctor.bat
```

---

## §1 Execution Policy

**Symptom.** Running `.\Sync-AllRepos-Hacker.ps1` prints:

```
File ...\Sync-AllRepos-Hacker.ps1 cannot be loaded because running scripts is
disabled on this system. For more information, see about_Execution_Policies...
```

**Why.** Windows PowerShell defaults to `Restricted` for end users and
`RemoteSigned` for servers. Group Policy can override this and lock it.

**Three ways to fix, from least to most invasive:**

| # | What | Command | Persistence |
|---|---|---|---|
| 1 | **Use `Git-Sync.bat`** — sets `-ExecutionPolicy Bypass` for the *single process* | (just double-click it) | Never persisted |
| 2 | Set the **CurrentUser** scope to RemoteSigned (no admin needed) | `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` | Per-user, until you change it |
| 3 | Use **`Git-Sync-Elevated.bat`** if (1) and (2) are blocked by Group Policy | (UAC prompt) | Per-process, elevated |

**Recommended:** option 1 for casual use, option 2 if you'll use Git-Sync
frequently. Avoid `Set-ExecutionPolicy Bypass` at any scope wider than
`Process`.

**Verify** with `Get-ExecutionPolicy -List` or just `Git-Sync-Doctor.bat`.

---

## §2 Blocked Files (Zone.Identifier)

**Symptom.** Pester fails to discover tests with:

```
PSSecurityException: ... cannot be loaded. The file ... is not digitally
signed. You cannot run this script on the current system.
```

…even when execution policy looks fine.

**Why.** Windows tags every file downloaded from the internet with an
`Alternate Data Stream` called `Zone.Identifier`. PowerShell treats those
as untrusted regardless of execution policy.

**Fix.**

```powershell
# In the Git-Sync folder:
Get-ChildItem -Recurse -Include *.ps1, *.psm1, *.psd1 | Unblock-File
```

Or just run `Git-Sync.bat` / `Install.bat` — both unblock files
automatically as a pre-flight step.

**Verify.** `Git-Sync-Doctor.bat` reports `File unblock status` per file.

---

## §3 .ps1 Double-Click Opens Notepad

**Symptom.** Double-clicking `Sync-AllRepos-Hacker.ps1` in Explorer opens
it in Notepad/VS Code instead of running it.

**Why.** Windows ships with `.ps1` associated to *Edit*, not *Run*, to
prevent accidental script execution. That's a feature, not a bug.

**Two fixes:**

| Approach | How |
|---|---|
| ✅ **Use `Git-Sync.bat`** | `.bat` files run on double-click. This is the supported entry point. |
| ⚙️ Change file association (not recommended) | Right-click any `.ps1` → *Open with* → Choose another app → PowerShell → ☑ *Always use this app*. Affects every `.ps1` on the system. |

The Git-Sync project intentionally ships **launcher `.bat` files** so you
never need to touch file associations.

---

## §4 Missing Dependencies

**Symptom.** `'git' is not recognized as an internal or external command`,
or `Test-GhAuthentication` returns `$false` unexpectedly.

**Why.** Git-Sync calls out to `git` (required) and `gh` (optional, only
needed for `-AutoSwitchGh` and GitHub Release creation).

**Fix.**

| Tool | Install command | Verify |
|---|---|---|
| Git for Windows | `winget install --id Git.Git -e` | `git --version` |
| GitHub CLI | `winget install --id GitHub.cli -e` | `gh --version && gh auth status` |
| PowerShell 7 | `winget install --id Microsoft.PowerShell -e` | `pwsh --version` |

⚠️ **Close and reopen your terminal** after installing — PATH changes
don't propagate to existing sessions.

**Verify** with `Git-Sync-Doctor.bat`.

---

## §5 Module Loading

**Symptom.** `Import-Module Git-Sync` fails with "module not found", or
exported functions are missing.

**Why.** Either you're outside the repo directory, or the
`Git-Sync.psd1` manifest version doesn't match `Git-Sync.psm1` exports.

**Fix.**

```powershell
# Import explicitly by path
Import-Module .\Git-Sync.psd1 -Force

# Verify the manifest
Test-ModuleManifest -Path .\Git-Sync.psd1

# Confirm exports
Get-Command -Module Git-Sync
# should list 11 functions: Get-NextVersion, Test-GitRepository,
# Test-GitRemoteConnectivity, Invoke-GitCommand, Test-GhAuthentication,
# Get-LatestTag, Invoke-GitDeploy, New-GitRelease,
# Get-GitHubAccountFromRepo, Switch-GhAccount, Test-GitSyncEnvironment
```

If you installed from the PowerShell Gallery, run:

```powershell
Update-Module Git-Sync
Get-InstalledModule Git-Sync   # confirm version
```

---

## §6 Console Encoding / Garbled Colours

**Symptom.** Progress bars show as `??????`; the ASCII banner is broken;
ANSI escape sequences appear literally.

**Why.** The host doesn't support Virtual Terminal (VT) sequences, or
the active code page can't render Unicode box-drawing characters.

**Fix.**

```powershell
# 1. Switch to UTF-8 in the current session
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 2. Set the code page (CMD)
chcp 65001

# 3. As a fallback, disable colours entirely
.\Sync-AllRepos-Hacker.ps1 -NoColor
```

PowerShell 7 in Windows Terminal handles this out of the box. Windows
PowerShell 5.1 inside `conhost.exe` is the most common failure point —
either upgrade to PowerShell 7 or use `-NoColor`.

---

## §7 Group Policy Lockdown

**Symptom.** Even `Set-ExecutionPolicy -Scope CurrentUser` fails with
*"Set-ExecutionPolicy: Windows PowerShell updated your execution policy
successfully, but the setting is overridden by a policy defined at a more
specific scope."*

**Why.** An administrator has set `MachinePolicy` or `UserPolicy`
execution policy via Group Policy. These take precedence over any
scope you can touch.

**Fix.** Use the per-process bypass — that's exactly what `Git-Sync.bat`
does, and it cannot be blocked by Group Policy on the policy itself
(only by an AppLocker-style hash-allow-list rule, which is rare).

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-AllRepos-Hacker.ps1
```

If even that is blocked, escalate to your admin — your environment has
been deliberately locked down and Git-Sync cannot route around it.

---

## §8 Antivirus / Defender False Positives

**Symptom.** Files mysteriously disappear from the Git-Sync folder, or
script execution hangs and then errors with "Operation did not complete
successfully because the file contains a virus".

**Why.** Some AV products flag uncommon `.ps1` patterns (especially the
hacker-style ASCII banner) as suspicious.

**Fix.**

1. Verify the SHA-256 of the suspect file against the GitHub release.
2. Add an **exclusion** for the Git-Sync folder in your AV (e.g.,
   *Windows Security → Virus & threat protection → Manage settings →
   Add or remove exclusions*).
3. If it persists, please open an issue with the AV product/version so
   we can request the signature be reviewed.

---

## Asking for Help

If `Git-Sync-Doctor.bat` doesn't surface the cause, please open a
[bug report](https://github.com/LIN4CRE/Git-Sync/issues/new?template=bug_report.md)
and paste the doctor's full output along with:

```powershell
$PSVersionTable                       # PowerShell version
Get-ExecutionPolicy -List              # execution policies
git --version; gh --version            # dependency versions
Get-Module Git-Sync -ListAvailable     # which version is loaded
```

Make sure to **redact any tokens or hostnames** before posting.
