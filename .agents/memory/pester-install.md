---
name: pester-install
description: How to install Pester and PSScriptAnalyzer in this Replit environment without Install-Module hanging.
---

# Installing Pester / PSScriptAnalyzer

## The problem
`Install-Module` hangs in the bash tool (same TTY issue as pwsh generally). `script -c`, `setsid`, and `< /dev/null` redirects all fail.

## The solution
Download the `.nupkg` from PowerShell Gallery and extract with Python's `zipfile`:

```bash
PESTER_VER="5.6.1"
DEST="$HOME/.local/share/powershell/Modules/Pester/$PESTER_VER"
mkdir -p "$DEST"
curl -sSL "https://www.powershellgallery.com/api/v2/package/Pester/$PESTER_VER" -o /tmp/pester.zip

python3 -c "
import zipfile, os
with zipfile.ZipFile('/tmp/pester.zip') as z:
    z.extractall('$DEST')
"
```

Same pattern for PSScriptAnalyzer (v1.23.0).

## Loading in a pwsh script
```powershell
$modulesRoot = '/home/runner/.local/share/powershell/Modules'
Import-Module "$modulesRoot/Pester/5.6.1/Pester.psd1" -Force
```

## Pester 5.6.1 quirk
`Invoke-Pester -Configuration $config -PassThru` errors with "Parameter set cannot be resolved". Use `$config.Run.PassThru = $true` and call `Invoke-Pester -Configuration $config` instead; the result is the return value.

**Why:** nupkg files are plain ZIP files; extracting them directly bypasses all interactive prompts.
