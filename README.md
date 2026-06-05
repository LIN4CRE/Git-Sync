# Git Multi-Sync

**Powerful multi-account Git automation toolkit** with smart versioning, bulk operations, and a beautiful hacker-style terminal UI.

## Features

- ✅ **Smart Semantic Versioning** – Auto bump Patch / Minor / Major
- ✅ **Multi-Account Support** – Works with multiple GitHub accounts (LIN4CRE, DLinacre, etc.)
- ✅ **Hacker-Style UI** – Progress bars, status ticks, and clean output
- ✅ **QoL Switches** – Continue on error, logging, pause between repos, etc.
- ✅ **One-Click Desktop Shortcut** – Run bulk sync with a single click
- ✅ **Full Logging Mode** – Silent operation with detailed log files

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/LIN4CRE/Git-Multi-Sync.git
cd Git-Multi-Sync
```

### 2. Make scripts executable (PowerShell)

```powershell
Set-ExecutionPolicy Bypass -Scope Process
```

### 3. Run the Hacker UI (Recommended)

```powershell
.\Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch -AutoSwitchGh
```

### Common Commands

```powershell
# Full sync with auto account switching + logging
.\Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Minor -AutoSwitchGh -LogFile "sync.log"

# Dry run (safe preview)
.\Sync-AllRepos-Hacker.ps1 -Action Both -WhatIf

# Only show failures + continue on error
.\Sync-AllRepos-Hacker.ps1 -Action Release -OnlyShowFailures -ContinueOnError

# Create desktop shortcut
.\Create-DesktopShortcut.ps1
```

## QoL Switches

| Switch                  | Description                              |
|-------------------------|------------------------------------------|
| `-AutoSwitchGh`         | Automatically switch GitHub accounts     |
| `-ContinueOnError`      | Keep going if one repo fails             |
| `-ShowGitStatus`        | Show changed files per repo              |
| `-PauseBetweenRepos`    | Pause after each repository              |
| `-OnlyShowFailures`     | Cleaner output (failures only)           |
| `-LogFile "sync.log"`   | Write full output to log file            |
| `-WhatIf`               | Dry run mode                             |
| `-Confirm`              | Ask before starting                      |

## Folder Structure (Recommended)

```
D:\
├── LIN4CRE\
│   ├── repo1\
│   ├── repo2\
│   └── ...
└── DLinacre\
    ├── repoA\
    └── repoB\
```

The tool automatically detects which account each repo belongs to.

## Requirements

- PowerShell 5.1 or 7+
- Git
- GitHub CLI (`gh`) – recommended for releases

## Desktop Shortcut

Run once to create a one-click desktop icon:

```powershell
.\Create-DesktopShortcut.ps1
```

## Easy Customization (Change Commands & Folders)

Everything is designed to be **easy to edit**.

### Change Default Folders

Open `Sync-AllRepos-Hacker.ps1` and edit this line near the top:

```powershell
[string[]]$BaseFolders = @("D:\LIN4CRE", "D:\DLinacre"),
```

Just change the paths to match your setup. Out-of-the-box it's configured for **LIN4CRE** and **DLinacre**.

### Change Default Action

You can also set a different default `Action`:

```powershell
[string]$Action = 'Both',     # Options: Deploy, Release, Both
```

### Example Configurations

**Minimal setup (one account only):**
```powershell
[string[]]$BaseFolders = @("D:\MyRepos")
```

**Three accounts:**
```powershell
[string[]]$BaseFolders = @("D:\Work", "D:\Personal", "D:\OpenSource")
```

## Logging Mode (Silent)

```powershell
.\Sync-AllRepos-Hacker.ps1 -Action Both -LogFile "C:\Logs\sync-$(Get-Date -Format yyyyMMdd).log"
```

## Contributing

Pull requests welcome! This tool was built to make managing multiple GitHub accounts effortless.

## License

MIT License

---

**Made for developers who manage multiple accounts.** 🚀