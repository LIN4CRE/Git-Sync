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
    [string]$ShortcutName = "Git-Sync",
    [switch]$Remove
)

$ShortcutPath = "$env:USERPROFILE\Desktop\$ShortcutName.lnk"

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
    Write-Host "Error: Target script not found at $TargetScript" -ForegroundColor Red
    Write-Host "Please run this script from the Git-Sync directory." -ForegroundColor Yellow
    return
}

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
