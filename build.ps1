#Requires -Version 5.1
<#
.SYNOPSIS
    Build, lint, and test script for Git-Sync.

.DESCRIPTION
    Automates dependency installation, PSScriptAnalyzer linting, and Pester test execution.
    Also unblocks downloaded script files so execution policy does not prevent discovery.

.EXAMPLE
    .\build.ps1

.EXAMPLE
    .\build.ps1 -SkipTest -SkipAnalyze
#>
[CmdletBinding()]
param(
    [switch]$SkipAnalyze,
    [switch]$SkipTest,
    [switch]$SkipBlockCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot

# ───────────────────────────────────────────────
# 1. Unblock files downloaded from the internet
# ───────────────────────────────────────────────
if (-not $SkipBlockCheck) {
    $blockedFiles = @()
    $extensions = @('*.ps1', '*.psm1', '*.psd1', '*.ps1xml')
    foreach ($ext in $extensions) {
        $blockedFiles += Get-ChildItem -Path $repoRoot -Recurse -Filter $ext -ErrorAction SilentlyContinue |
            Get-Item -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue
    }
    if ($blockedFiles) {
        Write-Host "Unblocking downloaded script files..." -ForegroundColor Yellow
        foreach ($ext in $extensions) {
            Get-ChildItem -Path $repoRoot -Recurse -Filter $ext -ErrorAction SilentlyContinue | Unblock-File
        }
        Write-Host "Done.`n" -ForegroundColor Green
    } else {
        Write-Host "No blocked files detected.`n" -ForegroundColor DarkGray
    }
}

# ───────────────────────────────────────────────
# 2. Install dependencies
# ───────────────────────────────────────────────
$neededModules = @('Pester', 'PSScriptAnalyzer')
foreach ($mod in $neededModules) {
    $minVersion = if ($mod -eq 'Pester') { '5.0' } else { '0.0' }
    if (-not (Get-Module -ListAvailable -Name $mod | Where-Object { $_.Version -ge [version]$minVersion })) {
        Write-Host "Installing module: $mod (Min: $minVersion) ..." -ForegroundColor Cyan
        Install-Module $mod -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
        Write-Host "Done.`n" -ForegroundColor Green
    } else {
        Write-Host "Module already installed: $mod (Matches min version $minVersion)" -ForegroundColor DarkGray
    }
}

# ───────────────────────────────────────────────
# 3. PSScriptAnalyzer
# ───────────────────────────────────────────────
if (-not $SkipAnalyze) {
    Write-Host "=== Running PSScriptAnalyzer ===" -ForegroundColor Cyan
    $analyzerSettings = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
    $settingsPath = if (Test-Path $analyzerSettings) { $analyzerSettings } else { $null }

    $results = Invoke-ScriptAnalyzer -Path $repoRoot -Recurse -Settings $settingsPath -ErrorAction Stop

    $ourResults = $results | Where-Object {
        $_.ScriptPath -notmatch '\.local[\\/]'
    }

    if ($ourResults) {
        $ourResults | Format-Table -AutoSize
        throw "PSScriptAnalyzer found issues in project files. See above for details."
    } else {
        $total = @($results).Count
        $kept = @($ourResults).Count
        $skipped = $total - $kept
        Write-Host "PSScriptAnalyzer: Clean (skipped $skipped module-internal warnings)" -ForegroundColor Green
    }
}

# ───────────────────────────────────────────────
# 4. Pester Tests
# ───────────────────────────────────────────────
if (-not $SkipTest) {
    Write-Host "=== Running Pester Tests ===" -ForegroundColor Cyan
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

    $testOutDir = Join-Path $repoRoot 'TestResults'
    if (-not (Test-Path $testOutDir)) { New-Item -ItemType Directory -Path $testOutDir -Force | Out-Null }

    $config = New-PesterConfiguration
    $config.Run.Path = "$repoRoot/tests"
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = "$testOutDir/TestResults.xml"
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = "$repoRoot/Git-Sync.psm1"
    $config.CodeCoverage.OutputPath = "$testOutDir/Coverage.xml"
    $config.CodeCoverage.CoveragePercentTarget = 80

    Invoke-Pester -Configuration $config

    Write-Host "`nTest results written to: $testOutDir" -ForegroundColor Green
}

Write-Host "`nBuild complete." -ForegroundColor Green
