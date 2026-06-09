#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Git-Sync interactive launcher for the Replit environment.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$esc = [char]27
function c { param([string]$t, [string]$fg) "$esc[${fg}m$t$esc[0m" }

Clear-Host

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host (c "  ╔══════════════════════════════════════════════════════════╗" "32")
Write-Host (c "  ║  ██████╗ ██╗████████╗      ███████╗██╗   ██╗███╗   ██╗  ║" "32")
Write-Host (c "  ║ ██╔════╝ ██║╚══██╔══╝      ██╔════╝╚██╗ ██╔╝████╗  ██║  ║" "32")
Write-Host (c "  ║ ██║  ███╗██║   ██║   █████╗███████╗ ╚████╔╝ ██╔██╗ ██║  ║" "32")
Write-Host (c "  ║ ██║   ██║██║   ██║   ╚════╝╚════██║  ╚██╔╝  ██║╚██╗██║  ║" "32")
Write-Host (c "  ║ ╚██████╔╝██║   ██║         ███████║   ██║   ██║ ╚████║  ║" "32")
Write-Host (c "  ║  ╚═════╝ ╚═╝   ╚═╝         ╚══════╝   ╚═╝   ╚═╝  ╚═══╝  ║" "32")
Write-Host (c "  ║                                                          ║" "32")
Write-Host (c "  ║      Multi-Account Bulk Git Automation  v2.7.0           ║" "36")
Write-Host (c "  ║      PowerShell Module + Hacker UI                       ║" "90")
Write-Host (c "  ╚══════════════════════════════════════════════════════════╝" "32")
Write-Host ""

# ── Environment info ──────────────────────────────────────────────────────────
$psVer   = $PSVersionTable.PSVersion
$gitVer  = try { (git --version 2>$null) -replace 'git version ','' } catch { 'not found' }
$ghVer   = try { (gh --version 2>$null | Select-Object -First 1) -replace 'gh version ','v' } catch { 'not found' }

Write-Host (c "  Runtime   " "90") -NoNewline; Write-Host (c "PowerShell $psVer" "97")
Write-Host (c "  Git       " "90") -NoNewline; Write-Host (c $gitVer "97")
Write-Host (c "  gh CLI    " "90") -NoNewline; Write-Host (c $ghVer "97")
Write-Host (c "  Location  " "90") -NoNewline; Write-Host (c $PSScriptRoot "97")
Write-Host ""
Write-Host (c "  ─────────────────────────────────────────────────────────" "90")

# ── Interactive menu ──────────────────────────────────────────────────────────
:menu while ($true) {
    Write-Host ""
    Write-Host (c "  QUICK ACTIONS" "35")
    Write-Host ""
    Write-Host (c "  [1]" "36") " Run Environment Doctor     " -NoNewline
    Write-Host (c "Test-GitSyncEnvironment" "90")
    Write-Host (c "  [2]" "36") " List exported functions     " -NoNewline
    Write-Host (c "Get-Command -Module Git-Sync" "90")
    Write-Host (c "  [3]" "36") " Run test suite              " -NoNewline
    Write-Host (c "build.ps1 -SkipAnalyze" "90")
    Write-Host (c "  [4]" "36") " Sync repos (deploy only)    " -NoNewline
    Write-Host (c "Sync-AllRepos-Hacker.ps1 -Action Deploy" "90")
    Write-Host (c "  [5]" "36") " Sync + release (patch bump) " -NoNewline
    Write-Host (c "Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch" "90")
    Write-Host (c "  [6]" "36") " Open PowerShell REPL        " -NoNewline
    Write-Host (c "Import module + interactive shell" "90")
    Write-Host (c "  [Q]" "33") " Quit"
    Write-Host ""
    Write-Host (c "  ─────────────────────────────────────────────────────────" "90")
    Write-Host (c "  Choice: " "33") -NoNewline

    $choice = Read-Host

    switch ($choice.Trim().ToUpper()) {
        '1' {
            Write-Host ""
            Import-Module (Join-Path $PSScriptRoot 'Git-Sync.psd1') -Force
            Test-GitSyncEnvironment
        }
        '2' {
            Write-Host ""
            Import-Module (Join-Path $PSScriptRoot 'Git-Sync.psd1') -Force
            Write-Host (c "  Exported functions in Git-Sync v$((Get-Module Git-Sync).Version):" "36")
            Write-Host ""
            Get-Command -Module Git-Sync | Sort-Object Name | ForEach-Object {
                Write-Host (c "    + " "32") -NoNewline
                Write-Host (c $_.Name "97")
            }
        }
        '3' {
            Write-Host ""
            Write-Host (c "  Running test suite..." "36")
            Write-Host ""
            & (Join-Path $PSScriptRoot 'build.ps1') -SkipAnalyze
        }
        '4' {
            Write-Host ""
            & (Join-Path $PSScriptRoot 'Sync-AllRepos-Hacker.ps1') -Action Deploy -WhatIf
        }
        '5' {
            Write-Host ""
            & (Join-Path $PSScriptRoot 'Sync-AllRepos-Hacker.ps1') -Action Both -BumpVersion Patch -WhatIf
        }
        '6' {
            Write-Host ""
            Write-Host (c "  Loading Git-Sync module into session..." "36")
            Import-Module (Join-Path $PSScriptRoot 'Git-Sync.psd1') -Force
            Write-Host (c "  Module loaded. Type 'exit' to return to this menu." "32")
            Write-Host ""
            # Drop into interactive pwsh
            break menu
        }
        'Q' {
            Write-Host ""
            Write-Host (c "  Goodbye." "90")
            Write-Host ""
            break menu
        }
        default {
            Write-Host (c "  Invalid choice. Enter 1-6 or Q." "33")
        }
    }
}
