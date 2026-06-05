#Requires -Version 5.1
<#
.SYNOPSIS
    Hacker-style Multi-Account Git Sync Tool v2.1
    Features: Progress bars, account switching, QoL switches, visual status
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
    [switch]$ContinueOnError,      # Keep going even if one repo fails
    [switch]$ShowGitStatus,        # Show git status summary per repo
    [switch]$PauseBetweenRepos,    # Pause after each repo (good for review)
    [switch]$OnlyShowFailures,     # Only display failed repos at the end
    [switch]$NoColor,              # Disable colors (for logging)
    [switch]$Confirm,              # Ask before starting
    [string]$LogFile               # Path to write full log (silent mode when used)
)

$ErrorActionPreference = 'Continue'

# ==================== HACKER STYLE UI ====================
$esc = [char]27

function Write-Hacker {
    param([string]$Text, [string]$Color = 'Green', [switch]$NoNewline)
    
    # Always log if LogFile is specified
    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFile -Value "[$timestamp] $Text" -ErrorAction SilentlyContinue
    }
    
    if ($NoColor) { Write-Host $Text -NoNewline:$NoNewline; return }
    
    $colorCode = switch ($Color) {
        'Green'  { '32' }; 'Red'    { '31' }; 'Yellow' { '33' }
        'Cyan'   { '36' }; 'Magenta'{ '35' }; 'White'  { '37' }
        'DarkGray' { '90' }; default { '32' }
    }
    Write-Host "$esc[${colorCode}m$Text$esc[0m" -NoNewline:$NoNewline
}

function Show-ProgressBar {
    param([int]$Current, [int]$Total, [string]$Label = "Progress")
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 35
    $filled = [math]::Floor($percent / 100 * $barLength)
    $bar = ('█' * $filled) + ('░' * ($barLength - $filled))
    
    Write-Host "`r$Label [$bar] $percent% ($Current/$Total)" -NoNewline -ForegroundColor Cyan
    if ($Current -eq $Total) { Write-Host "" }
}

function Show-Switch {
    param([string]$Name, [bool]$Enabled, [string]$Description = "")
    $status = if ($Enabled) { "ON " } else { "OFF" }
    $color = if ($Enabled) { "Green" } else { "DarkGray" }
    Write-Hacker "  [ $status ] $Name" $color
    if ($Description) { Write-Hacker "          $Description" "DarkGray" }
}

function Show-RepoStatus {
    param([string]$RepoName, [string]$Account, [string]$Status, [string]$Message = "")
    
    $icon = switch ($Status) {
        "Success" { "✓" }; "Failed" { "✗" }; "Skipped" { "○" }; default { "•" }
    }
    $color = switch ($Status) {
        "Success" { "Green" }; "Failed" { "Red" }; "Skipped" { "Yellow" }; default { "White" }
    }
    
    Write-Hacker "  $icon " $color -NoNewline
    Write-Hacker "$RepoName" "White" -NoNewline
    Write-Hacker " [$Account]" "DarkGray" -NoNewline
    if ($Message) { Write-Hacker " → $Message" "DarkGray" } else { Write-Host "" }
}

# ==================== GH ACCOUNT HANDLING ====================
function Get-GitHubAccountFromRepo {
    param([string]$RepoPath)
    Push-Location $RepoPath
    try {
        $remote = git remote get-url origin 2>$null
        if ($remote -match 'github.com[:/]([^/]+)/') { return $matches[1] }
    } finally { Pop-Location }
    return $null
}

function Switch-GhAccount {
    param([string]$TargetAccount)
    if (-not $AutoSwitchGh) { return $true }
    
    try {
        $current = gh auth status 2>&1 | Select-String "Logged in to github.com as"
        if ($current -match "as (\S+)") {
            if ($matches[1] -eq $TargetAccount) { return $true }
        }
        Write-Hacker "  Switching gh account → $TargetAccount" "Yellow"
        gh auth switch $TargetAccount 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}

# ==================== MAIN HACKER UI ====================
Clear-Host

Write-Hacker @"
╔══════════════════════════════════════════════════════════════════════════════╗
║   ██████╗ ██╗████████╗    ███████╗██╗   ██╗███╗   ██╗ ██████╗                ║
║  ██╔════╝ ██║╚══██╔══╝    ██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝                ║
║  ██║  ███╗██║   ██║       ███████╗ ╚████╔╝ ██╔██╗ ██║██║                     ║
║  ██║   ██║██║   ██║       ╚════██║  ╚██╔╝  ██║╚██╗██║██║                     ║
║  ╚██████╔╝██║   ██║       ███████║   ██║   ██║ ╚████║╚██████╗                ║
║   ╚═════╝ ╚═╝   ╚═╝       ╚══════╝   ╚═╝   ╚═╝  ╚═══╝ ╚═════╝                ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ "Green"

Write-Hacker "`n[ MULTI-ACCOUNT BULK SYNC v2.1 ]" "Cyan"
Write-Hacker "Accounts : $($BaseFolders -join '  |  ')" "DarkGray"
Write-Hacker "Action   : $Action" "DarkGray"
Write-Hacker "──────────────────────────────────────────────────────────────────────────────`n" "DarkGray"

# Show active QoL switches
Write-Hacker "[ QoL SWITCHES ]" "Magenta"
Show-Switch "AutoSwitchGh"     $AutoSwitchGh     "Automatically switch gh accounts per repo"
Show-Switch "ContinueOnError" $ContinueOnError  "Keep processing even if a repo fails"
Show-Switch "ShowGitStatus"   $ShowGitStatus    "Display git status summary for each repo"
Show-Switch "PauseBetweenRepos" $PauseBetweenRepos "Pause after every repository"
Show-Switch "OnlyShowFailures" $OnlyShowFailures "Only show failed repos in summary"
Show-Switch "WhatIf"          $WhatIf           "Dry run mode (no changes made)"
Write-Hacker "──────────────────────────────────────────────────────────────────────────────`n" "DarkGray"

if ($Confirm) {
    Write-Hacker "Press ENTER to start or CTRL+C to cancel..." "Yellow"
    Read-Host
}

# ==================== DISCOVERY ====================
$totalRepos = 0
$repoList = @()

foreach ($folder in $BaseFolders) {
    if (Test-Path $folder) {
        $repos = Get-ChildItem $folder -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName ".git") }
        foreach ($r in $repos) {
            $account = Get-GitHubAccountFromRepo -RepoPath $r.FullName
            if (-not $account) { $account = (Split-Path $folder -Leaf) }
            $repoList += [PSCustomObject]@{ Path = $r.FullName; Name = $r.Name; Account = $account }
        }
        $totalRepos += $repos.Count
    }
}

Write-Hacker "Discovered $totalRepos repositories across $($BaseFolders.Count) accounts`n" "Yellow"

if ($totalRepos -eq 0) {
    Write-Hacker "No repositories found. Exiting." "Red"
    return
}

# ==================== PROCESSING ====================
$allResults = @()
$processed = 0
$successCount = 0
$failCount = 0

foreach ($repo in $repoList) {
    $processed++
    Show-ProgressBar -Current $processed -Total $totalRepos -Label "SYNCING"
    
    $detectedAccount = $repo.Account
    
    if ($AutoSwitchGh) {
        Switch-GhAccount -TargetAccount $detectedAccount | Out-Null
    }
    
    Push-Location $repo.Path
    try {
        if (-not $WhatIf) {
            . "$PSScriptRoot\git-automation-enhanced.ps1" | Out-Null
            
            $params = @{}
            if ($BumpVersion) { $params.Bump = $BumpVersion }
            if ($Force) { $params.Force = $true }
            
            switch ($Action) {
                'Deploy'  { Invoke-GitDeploy -Message "Bulk sync [$detectedAccount]" @params -ErrorAction Stop | Out-Null }
                'Release' { New-GitRelease @params -ErrorAction Stop | Out-Null }
                'Both'    { 
                    Invoke-GitDeploy -Message "Bulk sync [$detectedAccount]" @params -ErrorAction Stop | Out-Null
                    New-GitRelease @params -ErrorAction Stop | Out-Null 
                }
            }
        }
        
        $status = if ($WhatIf) { "Skipped" } else { "Success" }
        if (-not $OnlyShowFailures) {
            Show-RepoStatus -RepoName $repo.Name -Account $detectedAccount -Status $status
        }
        
        if ($ShowGitStatus) {
            $statusOutput = git status --short 2>$null
            if ($statusOutput) {
                Write-Hacker "    └─ Changes: $($statusOutput.Count) files" "DarkGray"
            }
        }
        
        $allResults += [PSCustomObject]@{ Account = $detectedAccount; Repo = $repo.Name; Status = $status }
        $successCount++
        
    }
    catch {
        Show-RepoStatus -RepoName $repo.Name -Account $detectedAccount -Status "Failed" -Message $_.Exception.Message
        $allResults += [PSCustomObject]@{ Account = $detectedAccount; Repo = $repo.Name; Status = "Failed"; Error = $_.Exception.Message }
        $failCount++
        
        if (-not $ContinueOnError) {
            Write-Hacker "`nStopping due to error. Use -ContinueOnError to keep going." "Red"
            break
        }
    }
    finally {
        Pop-Location
    }
    
    if ($PauseBetweenRepos) {
        Write-Hacker "Press ENTER to continue..." "Yellow"
        Read-Host
    }
}

# ==================== FINAL SUMMARY ====================
Write-Hacker "`n══════════════════════════════════════════════════════════════════════════════" "DarkGray"
Write-Hacker "                         SYNC COMPLETE" "Green"
Write-Hacker "══════════════════════════════════════════════════════════════════════════════`n" "DarkGray"

$skipped = ($allResults | Where-Object Status -eq 'Skipped').Count

Write-Hacker "✓ Successful : $successCount" "Green"
Write-Hacker "✗ Failed     : $failCount" "Red"
Write-Hacker "○ Skipped    : $skipped" "Yellow"

if ($failCount -gt 0 -and -not $OnlyShowFailures) {
    Write-Hacker "`n[ FAILED REPOSITORIES ]" "Red"
    $allResults | Where-Object Status -eq 'Failed' | ForEach-Object {
        Write-Hacker "  ✗ $($_.Repo) [$($_.Account)] → $($_.Error)" "Red"
    }
}

Write-Hacker "`n[ END OF TRANSMISSION ]`n" "DarkGray"