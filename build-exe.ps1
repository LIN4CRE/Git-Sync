#Requires -Version 5.1
<#
.SYNOPSIS
    Build Git-Sync.exe from Sync-AllRepos-Hacker.ps1 using ps2exe.

.DESCRIPTION
    Requires Windows + PowerShell 5.1 or later.
    Install ps2exe first:  Install-Module ps2exe -Scope CurrentUser

.EXAMPLE
    .\build-exe.ps1

.EXAMPLE
    .\build-exe.ps1 -OutputPath "C:\MyTools\Git-Sync.exe"
#>

param(
    [string]$OutputPath = '.\dist\Git-Sync.exe',
    [string]$Version    = '2.7.0.0'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force
}
Import-Module ps2exe -Force

$outDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

Write-Host "Building Git-Sync.exe..." -ForegroundColor Cyan

Invoke-ps2exe `
    -InputFile  '.\Sync-AllRepos-Hacker.ps1' `
    -OutputFile $OutputPath `
    -Title      'Git-Sync' `
    -Version    $Version `
    -Description 'Multi-Account Git Sync Toolkit' `
    -Company    'LIN4CRE' `
    -Copyright  '(c) 2026 LIN4CRE' `
    -IconFile   '.\hacker-icon.ico' `
    -x64

if (Test-Path $OutputPath) {
    $kb = [math]::Round((Get-Item $OutputPath).Length / 1KB, 1)
    Write-Host "  + EXE built: $OutputPath ($kb KB)" -ForegroundColor Green
} else {
    Write-Error "EXE not found after build."
}
