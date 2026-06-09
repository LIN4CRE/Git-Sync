Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Git-Sync PowerShell Toolkit          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available scripts:" -ForegroundColor Yellow
Get-ChildItem *.ps1 | Where-Object { $_.Name -ne "start.ps1" } | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Green
}
Write-Host ""
Write-Host "Common commands:" -ForegroundColor Yellow
Write-Host "  pwsh ./build.ps1" -ForegroundColor White
Write-Host "    Build, lint, and test the module" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  pwsh ./Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch -AutoSwitchGh" -ForegroundColor White
Write-Host "    Sync all repos with version bump" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Import-Module ./Git-Sync.psm1" -ForegroundColor White
Write-Host "    Import the Git-Sync module into current session" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Type 'Get-Help <command>' for help on any function." -ForegroundColor DarkGray
Write-Host ""
