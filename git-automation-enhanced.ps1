#Requires -Version 5.1
<#
.SYNOPSIS
    Legacy entry-point script that imports the Git-Sync module.

.DESCRIPTION
    This script is provided for backward compatibility. It imports the
    Git-Sync PowerShell module so that all exported functions are available
    in the current session.

    For new use, consider importing the module directly:
    Import-Module "$(Split-Path $PSScriptRoot)/Git-Sync.psd1" -Force

.VERSION
    2.4.0
#>

Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot 'Git-Sync.psd1'
if (-not (Test-Path $modulePath)) {
    throw "Git-Sync module not found at $modulePath"
}

Import-Module $modulePath -Force

Write-Host "Git-Sync module loaded. Exported functions:" -ForegroundColor Green
Get-Command -Module Git-Sync | Select-Object -ExpandProperty Name | Sort-Object | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor Cyan
}
