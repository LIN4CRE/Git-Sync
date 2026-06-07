#Requires -Version 5.1
<#
.SYNOPSIS
    Standalone wrapper around Test-GitSyncEnvironment for the .bat doctor.

.DESCRIPTION
    Imports the Git-Sync module from the script's own folder and runs the
    environment check. Exits with code 0 on success, 1 if any check failed.
    Designed to be invoked from Git-Sync-Doctor.bat.
#>

[CmdletBinding()]
param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

try {
    $modulePath = Join-Path $PSScriptRoot 'Git-Sync.psd1'
    if (-not (Test-Path -LiteralPath $modulePath)) {
        Write-Host ""
        Write-Host " [FAIL] Could not find Git-Sync.psd1 at $modulePath" -ForegroundColor Red
        Write-Host "        Run Test-Environment.ps1 from the Git-Sync repo root." -ForegroundColor DarkGray
        Write-Host ""
        exit 2
    }
    Import-Module $modulePath -Force -ErrorAction Stop
    $result = Test-GitSyncEnvironment -RepoPath $PSScriptRoot -Quiet:$Quiet
    if ($result.Ok) { exit 0 } else { exit 1 }
}
catch {
    Write-Host ""
    Write-Host " [FAIL] Doctor crashed: $_" -ForegroundColor Red
    Write-Host ""
    exit 2
}
