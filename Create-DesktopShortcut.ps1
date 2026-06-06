#Requires -Version 5.1
<#
.SYNOPSIS
    Create or remove a desktop shortcut for Git-Sync.

.DESCRIPTION
    Creates a one-click desktop shortcut that launches the Git-Sync
    Hacker UI with default parameters. Supports -Remove to clean up.

.EXAMPLE
    .\Create-DesktopShortcut.ps1

.EXAMPLE
    .\Create-DesktopShortcut.ps1 -Remove
#>

param(
    [ValidateNotNullOrEmpty()]
    [string]$ShortcutName = "Git-Sync",
    [switch]$Remove
)

Set-StrictMode -Version Latest

$ShortcutPath = Join-Path $env:USERPROFILE "Desktop" "$ShortcutName.lnk"

if ($Remove) {
    if (Test-Path $ShortcutPath) {
        Remove-Item $ShortcutPath -Force
        Write-Host "Desktop shortcut removed: $ShortcutPath" -ForegroundColor Green
    } else {
        Write-Host "No shortcut found at: $ShortcutPath" -ForegroundColor Yellow
    }
    return
}

$TargetScript = Join-Path $PSScriptRoot "Sync-AllRepos-Hacker.ps1"

if (-not (Test-Path $TargetScript)) {
    Write-Error "Target script not found at $TargetScript. Please run this script from the Git-Sync directory."
    return
}

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$TargetScript`""
    $Shortcut.WorkingDirectory = $PSScriptRoot
    $Shortcut.IconLocation = "powershell.exe,0"
    $Shortcut.Description = "Git-Sync: Sync all repos across multiple accounts"
    $Shortcut.Save()
    Write-Host "Desktop shortcut created: $ShortcutPath" -ForegroundColor Green
    Write-Host "Double-click it to sync everything!" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to create desktop shortcut: $_"
}
