# Git-Sync

**Powerful multi-account Git automation toolkit** with smart versioning, bulk operations, and a beautiful hacker-style terminal UI.

> **Note:** This project was previously known as *Git-Multi-Sync*. All functionality remains the same — the name has been simplified to **Git-Sync**. If you have an older clone, please update your remotes:
> ```bash
> git remote set-url origin https://github.com/LIN4CRE/Git-Sync.git
> ```

---

## Features

- ✅ **Smart Semantic Versioning** – Auto bump Patch / Minor / Major
- ✅ **Multi-Account Support** – Works with multiple GitHub accounts (e.g., `LIN4CRE`, `DLinacre`, etc.)
- ✅ **Hacker-Style UI** – Progress bars, status ticks, and clean output
- ✅ **QoL Switches** – Continue on error, logging, pause between repos, and more
- ✅ **One-Click Desktop Shortcut** – Run bulk sync with a single click
- ✅ **Full Logging Mode** – Silent operation with detailed log files
- ✅ **Dry Run Mode** – Preview what would happen without making changes
- ✅ **Automatic Rollback Guidance** – Clear instructions if a release fails part-way

---

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/LIN4CRE/Git-Sync.git
cd Git-Sync
```

### 2. Unblock scripts (Windows)

Right-click each `.ps1` file → **Properties** → check **Unblock** (if present).

Alternatively, run:

```powershell
Get-ChildItem *.ps1 | Unblock-File
```

### 3. (Windows users) Easiest path — double-click `Install.bat`

If PowerShell scripts give you trouble on Windows (`.ps1` opens in Notepad,
"running scripts is disabled", `PSSecurityException` on blocked files…),
the project ships **four `.bat` launchers** that handle all of that for you:

| Launcher | Use it for |
|---|---|
| **`Install.bat`** | One-shot first-time setup (sets per-user execution policy, unblocks files, runs the doctor) |
| **`Git-Sync.bat`** | Day-to-day launcher (finds PowerShell, sets process-scope policy, forwards arguments) |
| **`Git-Sync-Doctor.bat`** | Diagnostic — checks PS version, execution policy, git, gh, module, file blocks |
| **`Git-Sync-Elevated.bat`** | Self-elevating UAC variant for Group-Policy-locked machines |

All four work in plain Command Prompt with no preconfiguration. See
[`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) for a symptom-to-fix map.

### 4. Run the Hacker UI (Recommended)

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

---

## QoL Switches

| Switch | Description |
|---|---|
| `-AutoSwitchGh` | Automatically switch GitHub CLI (`gh`) accounts per repo |
| `-ContinueOnError` | Keep going if one repo fails |
| `-ShowGitStatus` | Show changed files per repo |
| `-PauseBetweenRepos` | Pause after each repository |
| `-OnlyShowFailures` | Cleaner output (failures only) |
| `-LogFile "sync.log"` | Write full output to log file |
| `-WhatIf` | Dry run mode |
| `-Confirm` | Ask before starting |
| `-NoColor` | Disable ANSI colors (for log files / CI) |
| `-Force` | Overwrite existing tags and use `--force-with-lease` on push |

---

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

---

## Requirements

- **PowerShell 5.1 or 7+** (Windows)
- **Git** for Windows
- **GitHub CLI (`gh`)** – required for `-AutoSwitchGh` and release creation

> This toolkit is designed primarily for Windows environments. Linux/macOS users may need to adapt paths and the desktop shortcut script.

---

## Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions, including environment configuration, Git installation, and `gh` CLI multi-account setup.

---

## Desktop Shortcut

Run once to create a one-click desktop icon:

```powershell
.\Create-DesktopShortcut.ps1
```

To remove the shortcut later:

```powershell
.\Create-DesktopShortcut.ps1 -Remove
```

---

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

---

## Logging Mode (Silent)

```powershell
.\Sync-AllRepos-Hacker.ps1 -Action Both -LogFile "C:\Logs\sync-$(Get-Date -Format yyyyMMdd).log"
```

Log files are also auto-generated in the script directory. See `*.log` files for full output.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `gh auth switch` fails | Ensure you are logged in to all accounts: `gh auth login` for each one. |
| Release says "already exists" | Use `-Force` to overwrite, or delete the existing tag first. |
| No repos discovered | Check that `$BaseFolders` paths are correct and repos contain a `.git` folder. |
| Colors look wrong in your terminal | Use `-NoColor` to disable ANSI escape codes. |
| Script won't run | Check execution policy: `Get-ExecutionPolicy`. If files are blocked, run `Unblock-File` on them. For a single session, use `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`. |
| Missing dependency `git-automation-enhanced.ps1` | Ensure all files are kept in the same directory. |

---

## Build & Test

We provide a `build.ps1` script that handles unblocking, linting, and testing in one step.

```powershell
# Run the full build (unblocks files, installs dependencies, runs linter + tests)
.\build.ps1

# Skip tests or linter if you only need one step
.\build.ps1 -SkipTest
.\build.ps1 -SkipAnalyze
```

Or run Pester directly after unblocking files:

```powershell
Get-ChildItem *.ps1, *.psm1, *.psd1 | Unblock-File
Import-Module Pester -Force
Invoke-Pester -Path .\tests\Git-Sync.Tests.ps1
```

A CI pipeline is included under `.github/workflows/ci.yml` to run `PSScriptAnalyzer` and `Pester` tests on every pull request.

### PowerShell Module (Advanced)

The core functions are packaged as a proper PowerShell module (`Git-Sync.psd1` / `Git-Sync.psm1`). You can import it directly for use in your own scripts:

```powershell
Import-Module .\Git-Sync.psd1 -Force
Get-Command -Module Git-Sync
```

---

## Contributing

Pull requests welcome! This tool was built to make managing multiple GitHub accounts effortless.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, branch naming, and the pull request process.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

---

## Security

If you discover a security vulnerability, please review our [SECURITY.md](SECURITY.md) for disclosure guidelines.

---

## Code of Conduct

This project adheres to the [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

**Made for developers who manage multiple accounts.** 🚀
