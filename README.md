# Git-Sync

**Powerful multi-account Git automation toolkit** with smart versioning, bulk operations, and a beautiful hacker-style terminal UI.

> **Note:** This project was previously known as *Git-Multi-Sync*. All functionality remains the same — the name has been simplified to **Git-Sync**. If you have an older clone, please update your remotes:
> ```bash
> git remote set-url origin https://github.com/LIN4CRE/Git-Sync.git
> ```

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
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync
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

| Switch | Description |
|---|---|
| `-AutoSwitchGh` | Automatically switch GitHub CLI accounts per repo |
| `-ContinueOnError` | Keep going if one repo fails |
| `-ShowGitStatus` | Show changed files per repo |
| `-PauseBetweenRepos` | Pause after each repository |
| `-OnlyShowFailures` | Cleaner output (failures only) |
| `-LogFile "sync.log"` | Write full output to log file |
| `-WhatIf` | Dry run mode |
| `-Confirm` | Ask before starting |
| `-NoColor` | Disable ANSI colors (for log files / CI) |

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

The tool automatically detects which account each repo belongs to by inspecting the Git remote URL.

## Requirements

- PowerShell 5.1 or 7+
- Git
- GitHub CLI (`gh`) – required for `-AutoSwitchGh` and release creation

## Desktop Shortcut

Run once to create a one-click desktop icon:

```powershell
.\Create-DesktopShortcut.ps1
```

To remove the shortcut later:

```powershell
.\Create-DesktopShortcut.ps1 -Remove
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

Log files are also auto-generated in the script directory. See `*.log` files for full output.

## Troubleshooting

| Problem | Solution |
|---|---|
| `Test-GitRemoteConnectivity` not found | This was a missing function — fixed in the latest version. Pull the newest files. |
| `gh auth switch` fails | Ensure you are logged in to all accounts: `gh auth login` for each one. |
| Release says "already exists" | Use `-Force` to overwrite, or delete the existing tag first. |
| No repos discovered | Check that `$BaseFolders` paths are correct and repos contain a `.git` folder. |
| Colors look wrong in your terminal | Use `-NoColor` to disable ANSI escape codes. |
| Script won't run | Check execution policy: `Get-ExecutionPolicy`. Use `Set-ExecutionPolicy Bypass -Scope Process` for the current session. |

## Contributing

Pull requests welcome! This tool was built to make managing multiple GitHub accounts effortless.

Please:
1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

**Made for developers who manage multiple accounts.** 🚀
