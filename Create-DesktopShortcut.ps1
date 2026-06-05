# Create Desktop Shortcut for Multi-Repo Sync
param(
    [string]$ShortcutName = "Git Multi-Sync",
    [string]$TargetScript = "$PSScriptRoot\Sync-AllRepos.ps1"
)

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\$ShortcutName.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PSScriptRoot\Sync-AllRepos-Hacker.ps1`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Description = "Sync all repos in LIN4CRE and DLinacre folders"
$Shortcut.Save()

Write-Host "Desktop shortcut created: $ShortcutName.lnk" -ForegroundColor Green
Write-Host "Double-click it to sync everything!" -ForegroundColor Cyan