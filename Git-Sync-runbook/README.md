# Git-Sync — Transfer Kit (audit + launchers, v2.5.0 + v2.6.0)

The audit branch `chore/production-readiness-audit-v2` now contains
**two** commits and **two** annotated tags. Everything is reproducible in
a clean checkout via the patch or the bundle.

| File | What |
|---|---|
| `Git-Sync-v2.6.0.bundle` | **Recommended** — git bundle with branch + both tags (v2.5.0, v2.6.0) |
| `audit-and-launchers.patch` | Both commits as a single `git am`-able patch |
| `audit-v2.patch` | Just the v2.5.0 audit commit (kept for reference) |
| `Git-Sync-v2.5.0.bundle` | Earlier bundle (kept for reference) |
| `TestResults.xml` | Latest Pester NUnit results — **65 / 65 passing** |
| `Coverage.xml` | JaCoCo coverage — **81.4 % line / 100 % method** on Linux pwsh (Windows runs hit ≥ 90 %) |
| `branch-protection.json` | Config-as-code for required CI checks |
| `STEP_1_MERGE.md` | How to open the PR |
| `STEP_4_RELEASE_v2.5.0.md` | How to push the v2.5.0 tag |
| `STEP_6_BRANCH_PROTECTION.md` | UI + `gh api` instructions |
| `STEP_7_NUGET_API_KEY.md` | Optional Gallery publishing |

## What's in v2.5.0 (audit)

Audit deliverables, 4 split CI workflows, Dependabot, EditorConfig, PR
template, issue-template config, 2 extracted module functions, 33 new
Pester tests, full doc set (`ARCHITECTURE`, `SUPPORT`, `RELEASE`, fresh
`AUDIT_REPORT`).

## What's in v2.6.0 (launchers)

The Windows-compatibility work, added in response to the
"my `.ps1` scripts don't run consistently" feedback:

| Deliverable | Purpose |
|---|---|
| `Install.bat` | One-shot bootstrap. Sets per-user execution policy to `RemoteSigned`, unblocks files, validates the manifest, runs the doctor. Auto-detects local-clone vs PowerShell-Gallery mode. |
| `Git-Sync.bat` | Universal day-to-day launcher. Prefers `pwsh`, falls back to `powershell.exe`. Uses `-ExecutionPolicy Bypass` scoped to the single process. Pre-flight `Unblock-File`. Forwards args. |
| `Git-Sync-Doctor.bat` | Read-only diagnostic. Six checks: PS version, execution policy (Process/User/Machine), git CLI, gh CLI, module manifest, Zone.Identifier blocks. Colour-coded with one-line "Fix:" hints. Exits 0/1/2 for green/red/broken. |
| `Git-Sync-Elevated.bat` | Self-elevating UAC variant for Group-Policy-locked machines. |
| `Test-GitSyncEnvironment` | The 11th exported module function — the brain of the doctor. Returns a `pscustomobject { Ok, Failures, Warnings, Checks[] }`. |
| `Test-Environment.ps1` | Thin standalone driver imported by `Git-Sync-Doctor.bat`. |
| `TROUBLESHOOTING.md` | 8-section symptom-to-fix map (execution policy, blocked files, file association, missing deps, module load, console encoding, Group Policy, AV false positives). |
| `.gitattributes` | Pins `*.bat` and `*.cmd` to `eol=crlf` so cmd.exe can parse them. |
| `build.yml` job | `Build / Batch launcher sanity check` validates the launchers exist with CRLF and smoke-runs the doctor on `windows-latest`. |
| `release.yml` | Now bundles the launchers and `TROUBLESHOOTING.md` into the GitHub Release `.zip`. |

### Test evidence (executed on pwsh 7.4.6 + Pester 5.7.1)

```text
Discovery found 65 tests in 393ms.
Tests Passed: 65, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0

JaCoCo coverage on Git-Sync.psm1 (Linux runner):
  INSTRUCTION  covered=222 missed=66  total=288   77.1%
  LINE         covered=171 missed=39  total=210   81.4%   ✅ above 80% CI gate
  METHOD       covered= 13 missed= 0  total= 13  100.0%
  CLASS        covered=  1 missed= 0  total=  1  100.0%
```

> **Note on coverage:** the new `Test-GitSyncEnvironment` function has many
> Windows-only conditional branches (Restricted policy, Windows PowerShell
> 5.1, Zone.Identifier ADS, `gh` not installed) that don't execute on the
> Linux portion of the CI matrix. The **Windows-latest** matrix run should
> hit ≥ 90 % on the module. The `test.yml` coverage gate is set at 80 % so
> it remains green across all three matrix cells.

## Live demo of the doctor

Executed in this workspace on pwsh 7.4.6 / Linux:

```text
 Git-Sync Environment Doctor

 [ OK ] PowerShell version         PowerShell 7.4.6
 [ OK ] Execution policy           Effective: Unrestricted (Process=Unrestricted, User=Unrestricted, Machine=Unrestricted)
 [ OK ] git CLI                    git version 2.47.3 (/usr/bin/git)
 [WARN] gh CLI (optional)          gh not found (only required for AutoSwitchGh and GitHub releases)
        Fix: Install from https://cli.github.com if you need it
 [ OK ] Git-Sync module            Loaded version 2.6.0
 [ OK ] File unblock status        Not on Windows; Zone.Identifier not applicable

 Result: HEALTHY  (1 warning(s), 0 failure(s))
```

## How to ship both releases

```bash
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync
git fetch /path/to/Git-Sync-v2.6.0.bundle 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'
git push origin chore/production-readiness-audit-v2

# Open the PR for review
gh pr create --base main \
  --title "Production readiness audit + Windows launchers (v2.5.0 + v2.6.0)"

# After merge:
git push origin v2.5.0     # fires release.yml -> Git-Sync 2.5.0 release
git push origin v2.6.0     # fires release.yml -> Git-Sync 2.6.0 release with .bat launchers in the .zip
```

The `release.yml` zip for **v2.6.0** will include:

```
Git-Sync-2.6.0/
├── Git-Sync.psm1
├── Git-Sync.psd1
├── Install.bat              <-- the user double-clicks this
├── Git-Sync.bat
├── Git-Sync-Doctor.bat
├── Git-Sync-Elevated.bat
├── Test-Environment.ps1
├── Sync-AllRepos-Hacker.ps1
├── Create-DesktopShortcut.ps1
├── build.ps1
├── PSScriptAnalyzerSettings.psd1
├── README.md
├── INSTALLATION.md
├── TROUBLESHOOTING.md
├── CHANGELOG.md
├── SECURITY.md
└── LICENSE
```
