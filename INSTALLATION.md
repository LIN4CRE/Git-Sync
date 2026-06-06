# Installation Guide

## Prerequisites

- **Windows 10 or later** (PowerShell 5.1+ is built-in; PowerShell 7 is recommended)
- **Git for Windows** ([https://git-scm.com/download/win](https://git-scm.com/download/win))
- **GitHub CLI (`gh`)** ([https://cli.github.com/](https://cli.github.com/)) — only required for `-AutoSwitchGh` and GitHub release creation

## Step 1: Install PowerShell 7 (Optional but Recommended)

PowerShell 7 (a.k.a. `pwsh`) provides cross-platform support, better performance, and modern features.

```powershell
winget install Microsoft.PowerShell
```

Or download from [https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases).

## Step 2: Install Git for Windows

Download and run the installer from [git-scm.com](https://git-scm.com/download/win).

During installation, ensure:
- Git is added to your **PATH**.
- (Optional) Git Credential Manager is enabled — this helps `gh` work seamlessly with HTTPS remotes.

Verify installation:

```powershell
git --version
```

## Step 3: Install GitHub CLI (`gh`)

```powershell
winget install GitHub.cli
```

Or download from [https://cli.github.com/](https://cli.github.com/).

Verify installation:

```powershell
gh --version
```

### Log in to multiple GitHub accounts

If you use the `-AutoSwitchGh` feature, log in to each account:

```powershell
gh auth login --hostname github.com
# Repeat for each account
```

List authenticated accounts:

```powershell
gh auth status
```

Switch manually (the script does this automatically):

```powershell
gh auth switch --user YourUsername
```

## Step 4: Clone Git-Sync

```powershell
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync
```

## Step 5: Unblock Scripts (Windows Security)

Windows may mark downloaded scripts as blocked. You must unblock them before execution.

Right-click each `.ps1` file → **Properties** → check **Unblock** (if present).

Or use PowerShell:

```powershell
Get-ChildItem *.ps1, *.psm1, *.psd1 | Unblock-File
```

> ⚠️ **If you skip this step, tests will fail to discover with a `PSSecurityException` even when Pester is installed.**

## Step 6: Set Execution Policy (Session-Only)

By default, Windows PowerShell restricts script execution. Use the session-only policy to avoid system-wide changes:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

If you run Git-Sync frequently, you may prefer to set the policy for the **CurrentUser** scope:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

> **Warning:** Never use `Bypass` as a permanent policy. `RemoteSigned` is the safest option for locally authored scripts.

## Step 7: Verify the Setup

Run a **dry run** to ensure everything is configured correctly:

```powershell
.\Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch -WhatIf
```

You should see the hacker banner and a list of discovered repositories. If you see errors, check the [Troubleshooting](#troubleshooting) section below.

## Step 8: (Optional) Create a Desktop Shortcut

```powershell
.\Create-DesktopShortcut.ps1
```

A shortcut named **Git-Sync** will appear on your desktop. Double-click it to run the default sync action.

## Using the PowerShell Module

The core automation functions are packaged as a proper PowerShell module.

```powershell
Import-Module .\Git-Sync.psd1 -Force

# Now you can use the functions in your own scripts
Invoke-GitDeploy -Message "My deploy"
New-GitRelease -Bump Patch -GenerateNotes
```

This is useful for integrating Git-Sync into larger automation pipelines or CI/CD steps.

## Troubleshooting

| Symptom | Solution |
|---|---|
| `cannot be loaded because running scripts is disabled` | Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process` or unblock the files. |
| `gh` is not recognized | Ensure `gh` is installed and in your PATH. Restart your terminal after installation. |
| `No repositories found` | Check that your `$BaseFolders` paths inside `Sync-AllRepos-Hacker.ps1` match your local drive layout. |
| `gh auth switch` fails | Ensure you are logged in to all target accounts with `gh auth login`. |
| `Git command failed` | Ensure Git is installed and the repository is not in a corrupted state. Run `git status` in the failing repo to diagnose. |
| Colors are garbled | Use `-NoColor` to disable ANSI escape sequences. |

## Folder Structure

Git-Sync expects repositories to be organized like this:

```
D:\
├── AccountName\
│   ├── repo1\
│   ├── repo2\
│   └── ...
└── AnotherAccount\
    ├── repoA\
    └── repoB\
```

Each immediate child folder of an **AccountName** directory should be a Git repository (i.e., contain a `.git` folder). Adjust the `$BaseFolders` array in `Sync-AllRepos-Hacker.ps1` to match your layout.

## Uninstallation

Delete the cloned folder and the desktop shortcut (if created):

```powershell
Remove-Item "$env:USERPROFILE\Desktop\Git-Sync.lnk" -ErrorAction SilentlyContinue
```

No registry entries or system services are created by Git-Sync.
