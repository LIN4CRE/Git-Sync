#Requires -Version 5.1
<#
.SYNOPSIS
    Git-Sync Hacker UI v2.7 — Multi-Account Bulk Git Sync Tool

.DESCRIPTION
    Syncs multiple Git repositories across different GitHub accounts with
    smart semantic versioning, bulk operations, and a polished hacker-style
    terminal UI. Features progress bars, account auto-switching, QoL flags,
    logging, and a rich summary report.

.PARAMETER BaseFolders
    Array of root folders to scan for Git repositories.

.PARAMETER Action
    What to perform: Deploy (commit+push), Release (tag+publish), Both.

.PARAMETER BumpVersion
    Required when Action is Release or Both. One of: Patch, Minor, Major.

.PARAMETER WhatIf
    Dry-run: discover repos and show what would happen without making changes.

.PARAMETER Force
    Force-push and overwrite existing tags.

.PARAMETER AutoSwitchGh
    Automatically switch the gh CLI account per repository.

.PARAMETER ContinueOnError
    Keep processing remaining repos even when one fails.

.PARAMETER ShowGitStatus
    Display a short git status summary after each repo.

.PARAMETER PauseBetweenRepos
    Pause for confirmation after each repository.

.PARAMETER OnlyShowFailures
    Suppress per-repo output; only display failures in the summary.

.PARAMETER NoColor
    Disable ANSI color output (useful for piping or logging).

.PARAMETER Confirm
    Prompt for confirmation before processing begins.

.PARAMETER LogFile
    Path for a detailed log file. Enables silent console mode when set.

.EXAMPLE
    .\Sync-AllRepos-Hacker.ps1 -Action Both -BumpVersion Patch -AutoSwitchGh

.EXAMPLE
    .\Sync-AllRepos-Hacker.ps1 -Action Deploy -ContinueOnError -LogFile sync.log

.VERSION
    2.7.0 - 2026-06-09
#>

param(
    [string[]]$BaseFolders = @("D:\LIN4CRE", "D:\DLinacre"),

    [ValidateSet('Deploy','Release','Both')]
    [string]$Action = 'Both',

    [ValidateSet('Patch','Minor','Major')]
    [string]$BumpVersion,

    [switch]$WhatIf,
    [switch]$Force,
    [switch]$AutoSwitchGh,

    # === QoL Switches ===
    [switch]$ContinueOnError,
    [switch]$ShowGitStatus,
    [switch]$PauseBetweenRepos,
    [switch]$OnlyShowFailures,
    [switch]$NoColor,
    [switch]$Confirm,
    [string]$LogFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ── Validate required parameters ──────────────────────────────────────────────
if ($Action -in @('Release','Both') -and -not $BumpVersion) {
    throw "Parameter -BumpVersion is required when Action is '$Action'."
}

# ── Resolve LogFile to an absolute path early ─────────────────────────────────
if ($LogFile) {
    if (-not [System.IO.Path]::IsPathRooted($LogFile)) {
        $LogFile = Join-Path $PSScriptRoot $LogFile
    }
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  HACKER STYLE UI HELPERS
# ══════════════════════════════════════════════════════════════════════════════

$esc = [char]27

function Write-Hacker {
    param([string]$Text, [string]$Color = 'Green', [switch]$NoNewline)

    if ($LogFile) {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFile -Value "[$ts] $Text" -ErrorAction SilentlyContinue
    }

    if ($NoColor) {
        Write-Host $Text -NoNewline:$NoNewline
        return
    }

    $code = switch ($Color) {
        'Green'    { '32' }
        'Red'      { '31' }
        'Yellow'   { '33' }
        'Cyan'     { '36' }
        'Magenta'  { '35' }
        'White'    { '97' }
        'DarkGray' { '90' }
        'Blue'     { '34' }
        default    { '32' }
    }
    Write-Host "$esc[${code}m$Text$esc[0m" -NoNewline:$NoNewline
}

function Show-ProgressBar {
    param([int]$Current, [int]$Total, [string]$Label = "Progress")
    if ($Total -le 0) { return }
    $pct      = [math]::Round(($Current / $Total) * 100)
    $barLen   = 40
    $filled   = [math]::Floor($pct / 100 * $barLen)
    $empty    = $barLen - $filled
    $bar      = ('█' * $filled) + ('░' * $empty)
    $line     = "`r  $Label  [$bar] $pct%%  ($Current / $Total)"
    if ($NoColor) {
        Write-Host $line -NoNewline
    } else {
        Write-Host "$esc[36m$line$esc[0m" -NoNewline
    }
    if ($Current -eq $Total) { Write-Host "" }
}

function Show-Switch {
    param([string]$Name, [bool]$Enabled, [string]$Desc = "")
    $tag   = if ($Enabled) { "  ON " } else { " OFF " }
    $color = if ($Enabled) { "Green" } else { "DarkGray" }
    Write-Hacker "  [$tag] " $color -NoNewline
    Write-Hacker $Name "White" -NoNewline
    if ($Desc) { Write-Hacker "  — $Desc" "DarkGray" } else { Write-Host "" }
}

function Show-RepoStatus {
    param([string]$RepoName, [string]$Account, [string]$Status, [string]$Message = "")
    $icon  = switch ($Status) {
        "Success" { "✓" }
        "Failed"  { "✗" }
        "Skipped" { "○" }
        default   { "•" }
    }
    $color = switch ($Status) {
        "Success" { "Green"  }
        "Failed"  { "Red"    }
        "Skipped" { "Yellow" }
        default   { "White"  }
    }
    Write-Hacker "  $icon " $color -NoNewline
    Write-Hacker $RepoName "White" -NoNewline
    Write-Hacker "  @$Account" "DarkGray" -NoNewline
    if ($Message) { Write-Hacker "  → $Message" "DarkGray" } else { Write-Host "" }
}

function Show-Divider {
    param([string]$Color = "DarkGray")
    Write-Hacker ("─" * 62) $Color
}

# ══════════════════════════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════════════════════════

if ($Host.UI.SupportsVirtualTerminal -and -not $NoColor) { Clear-Host }

$banner = @"
  ╔══════════════════════════════════════════════════════════╗
  ║  ██████╗ ██╗████████╗      ███████╗██╗   ██╗███╗   ██╗  ║
  ║ ██╔════╝ ██║╚══██╔══╝      ██╔════╝╚██╗ ██╔╝████╗  ██║  ║
  ║ ██║  ███╗██║   ██║   █████╗███████╗ ╚████╔╝ ██╔██╗ ██║  ║
  ║ ██║   ██║██║   ██║   ╚════╝╚════██║  ╚██╔╝  ██║╚██╗██║  ║
  ║ ╚██████╔╝██║   ██║         ███████║   ██║   ██║ ╚████║  ║
  ║  ╚═════╝ ╚═╝   ╚═╝         ╚══════╝   ╚═╝   ╚═╝  ╚═══╝  ║
  ║                                                          ║
  ║          Multi-Account Bulk Git Sync  v2.7.0             ║
  ╚══════════════════════════════════════════════════════════╝
"@

Write-Hacker $banner "Green"

$versionLabel   = "v2.7.0"
$actionLabel    = $Action.ToUpper()
$bumpLabel      = if ($BumpVersion) { $BumpVersion } else { "N/A" }
$foldersLabel   = $BaseFolders -join "  |  "

Write-Hacker "  Run Mode  : $actionLabel  |  Bump: $bumpLabel  |  $versionLabel" "Cyan"
Write-Hacker "  Scanning  : $foldersLabel" "DarkGray"
Show-Divider

Write-Hacker "  ACTIVE OPTIONS" "Magenta"
Show-Switch "AutoSwitchGh"    $AutoSwitchGh    "Auto-switch gh CLI account per repo"
Show-Switch "ContinueOnError" $ContinueOnError "Keep processing after a failure"
Show-Switch "ShowGitStatus"   $ShowGitStatus   "Show changed-file count per repo"
Show-Switch "PauseBetween"    $PauseBetweenRepos "Pause between repos"
Show-Switch "OnlyFailures"    $OnlyShowFailures  "Only report failures in summary"
Show-Switch "WhatIf (DryRun)" $WhatIf          "Preview only, no changes written"
Show-Switch "NoColor"         $NoColor         "Plain text output"
Show-Divider

if ($Confirm) {
    Write-Hacker "  Press ENTER to start or Ctrl+C to abort..." "Yellow"
    $null = Read-Host
}

# ══════════════════════════════════════════════════════════════════════════════
#  DISCOVERY
# ══════════════════════════════════════════════════════════════════════════════

Write-Hacker "  DISCOVERING REPOSITORIES" "Cyan"

$repoList = [System.Collections.ArrayList]::new()

foreach ($folder in $BaseFolders) {
    if (Test-Path $folder) {
        $repos = Get-ChildItem $folder -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName ".git") }
        foreach ($r in $repos) {
            $account = Get-GitHubAccountFromRepo -RepoPath $r.FullName
            if (-not $account) { $account = (Split-Path $folder -Leaf) }
            if ([string]::IsNullOrWhiteSpace($account)) { $account = "unknown" }
            $null = $repoList.Add([PSCustomObject]@{
                Path    = $r.FullName
                Name    = $r.Name
                Account = $account
            })
        }
        Write-Hacker "  + $folder  ($($repos.Count) repo(s))" "DarkGray"
    } else {
        Write-Hacker "  ! Folder not found: $folder" "Yellow"
    }
}

$totalRepos = $repoList.Count
Write-Hacker "" "White"
Write-Hacker "  Found $totalRepos repositories across $($BaseFolders.Count) location(s)" "Yellow"
Show-Divider

if ($totalRepos -eq 0) {
    Write-Hacker "  No repositories found. Exiting." "Red"
    return
}

# ══════════════════════════════════════════════════════════════════════════════
#  MODULE LOAD
# ══════════════════════════════════════════════════════════════════════════════

$modulePath = Join-Path $PSScriptRoot "Git-Sync.psd1"
if (-not (Test-Path $modulePath)) {
    Write-Hacker "  [ERROR] Git-Sync module not found at: $modulePath" "Red"
    Write-Hacker "          Ensure Git-Sync.psd1 is in the same directory." "Red"
    return
}
Import-Module $modulePath -Force

# ══════════════════════════════════════════════════════════════════════════════
#  PROCESSING
# ══════════════════════════════════════════════════════════════════════════════

Write-Hacker "  PROCESSING" "Cyan"
Write-Host ""

$allResults   = [System.Collections.ArrayList]::new()
$processed    = 0
$successCount = 0
$failCount    = 0
$skipCount    = 0
$startTime    = Get-Date

$deployParams  = @{}
if ($Force) { $deployParams.Force = $true }

$releaseParams = @{}
if ($BumpVersion) { $releaseParams.Bump = $BumpVersion }
if ($Force)       { $releaseParams.Force = $true }

foreach ($repo in $repoList) {
    $processed++
    Show-ProgressBar -Current $processed -Total $totalRepos -Label "SYNCING"

    $detectedAccount = $repo.Account

    if ($AutoSwitchGh) {
        $null = Switch-GhAccount -TargetAccount $detectedAccount
    }

    Push-Location $repo.Path
    try {
        if ($WhatIf) {
            $status = "Skipped"
            $skipCount++
        } else {
            switch ($Action) {
                'Deploy'  {
                    Invoke-GitDeploy -Message "Bulk sync [$detectedAccount]" @deployParams -ErrorAction Stop | Out-Null
                }
                'Release' {
                    New-GitRelease @releaseParams -ErrorAction Stop | Out-Null
                }
                'Both'    {
                    Invoke-GitDeploy -Message "Bulk sync [$detectedAccount]" @deployParams -ErrorAction Stop | Out-Null
                    New-GitRelease @releaseParams -ErrorAction Stop | Out-Null
                }
            }
            $status = "Success"
            $successCount++
        }

        if (-not $OnlyShowFailures) {
            Show-RepoStatus -RepoName $repo.Name -Account $detectedAccount -Status $status
        }

        if ($ShowGitStatus) {
            $stOut = git status --short 2>$null
            if ($stOut) {
                $cnt = if ($stOut -is [array]) { $stOut.Count } else { 1 }
                Write-Hacker "      $cnt changed file(s)" "DarkGray"
            }
        }

        $null = $allResults.Add([PSCustomObject]@{
            Account = $detectedAccount
            Repo    = $repo.Name
            Status  = $status
        })
    }
    catch {
        $errMsg = if ($_.Exception.Message) { $_.Exception.Message } else { "Unknown error" }
        Show-RepoStatus -RepoName $repo.Name -Account $detectedAccount -Status "Failed" -Message $errMsg
        $null = $allResults.Add([PSCustomObject]@{
            Account = $detectedAccount
            Repo    = $repo.Name
            Status  = "Failed"
            Error   = $errMsg
        })
        $failCount++

        if (-not $ContinueOnError) {
            Write-Host ""
            Write-Hacker "  Stopped after first failure. Use -ContinueOnError to keep going." "Red"
            break
        }
    }
    finally {
        Pop-Location
    }

    if ($PauseBetweenRepos) {
        Write-Hacker "  Press ENTER for next repo..." "Yellow"
        $null = Read-Host
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  FINAL SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

$elapsed = (Get-Date) - $startTime
$elapsedStr = "{0:mm}m {0:ss}s" -f $elapsed

Write-Host ""
Show-Divider "DarkGray"
Write-Hacker "  SYNC COMPLETE  —  $elapsedStr" "Green"
Show-Divider "DarkGray"
Write-Host ""

$pct = if ($totalRepos -gt 0) { [math]::Round(($successCount / $totalRepos) * 100) } else { 0 }

Write-Hacker "  ✓  Successful  :  $successCount" "Green"
Write-Hacker "  ✗  Failed      :  $failCount"     "Red"
Write-Hacker "  ○  Skipped     :  $skipCount"     "Yellow"
Write-Hacker "  ◉  Total       :  $totalRepos  ($pct%% success rate)" "Cyan"
Write-Host ""

if ($failCount -gt 0) {
    Write-Hacker "  FAILED REPOSITORIES" "Red"
    Show-Divider "Red"
    $allResults | Where-Object Status -eq 'Failed' | ForEach-Object {
        $e = if ($_.Error) { $_.Error } else { "No details" }
        Write-Hacker "  ✗ $($_.Repo)  @$($_.Account)" "Red" -NoNewline
        Write-Hacker "  → $e" "DarkGray"
    }
    Write-Host ""
}

if ($LogFile -and (Test-Path $LogFile)) {
    Write-Hacker "  Log saved to: $LogFile" "DarkGray"
}

Write-Hacker "  [ END OF TRANSMISSION ]" "DarkGray"
Write-Host ""
