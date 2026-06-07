[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Organization = "LIN4CRE",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Test-GhInstalled {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Color "ERROR: GitHub CLI (gh) is not installed or not on PATH." Red
        Write-Color "Install from: https://cli.github.com/" Yellow
        exit 1
    }
    $auth = gh auth status 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Color "ERROR: Not authenticated with GitHub CLI." Red
        Write-Color "Run: gh auth login" Yellow
        exit 1
    }
}

function Get-GitHubRepoList {
    Write-Color "`nFetching repositories for '$Organization'..." Cyan
    $repos = gh repo list $Organization --limit 500 --json name,visibility,description,updatedAt,isFork,isArchived,primaryLanguage,pullRequests,diskUsage,forkCount,stargazerCount 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $repos) {
        Write-Color "ERROR: Failed to fetch repos. Check org name and network." Red
        exit 1
    }
    Write-Color "Found $($repos.Count) repos." Green
    return $repos
}

function Show-RepoTable {
    param($Repos, [string]$Title = "Repositories")
    Write-Color "`n$Title" Cyan
    $i = 1
    $Repos | ForEach-Object {
        $icon = if ($_.isFork) { "⑂" } else { "●" }
        $arch = if ($_.isArchived) { " [ARCHIVED]" } else { "" }
        $lang = if ($_.primaryLanguage) { $_.primaryLanguage.name } else { "—" }
        $desc = if ($_.description) { $_.description.Substring(0, [Math]::Min($_.description.Length, 50)).PadRight(50) } else { "".PadRight(50) }
        Write-Host ("{0,2}. {1} {2,-30}{3,-10}{4,-12}{5}" -f $i, $icon, $_.name, $_.visibility, $lang, $arch)
        $i++
    }
}

Test-GhInstalled

$allRepos = Get-GitHubRepoList

if (-not (Get-Command Out-GridView -ErrorAction SilentlyContinue)) {
    Write-Color "Out-GridView not available (this requires PowerShell ISE or Windows PowerShell 5.1+ with a GUI)." Yellow
    Write-Color "Falling back to numbered selection mode." Yellow
    Show-RepoTable -Repos $allRepos -Title "Available repositories (numbered list)"
    Write-Color "`nEnter numbers to select (comma-separated, e.g. 1,3,5), or leave empty to cancel." Yellow
    $input = Read-Host "Select repos to delete"
    if ([string]::IsNullOrWhiteSpace($input)) {
        Write-Color "Cancelled." Gray
        exit 0
    }
    $indices = @()
    $input -split ',' | ForEach-Object {
        $n = $_ -replace '\s','' -as [int]
        if ($n -and $n -ge 1 -and $n -le $allRepos.Count) { $indices += ($n - 1) }
    }
    $selected = $allRepos[$indices]
} else {
    Write-Color "`nOpening selection window (Out-GridView)..." Cyan
    $displayData = $allRepos | Select-Object @{N='Delete';E={$false}},
        @{N='Name';E={$_.name}},
        @{N='Visibility';E={$_.visibility}},
        @{N='Type';E={if ($_.isFork) {'Fork'} else {'Source'}}},
        @{N='Archived';E={if ($_.isArchived) {'Yes'} else {'No'}}},
        @{N='Language';E={if ($_.primaryLanguage) {$_.primaryLanguage.name} else {''}}},
        @{N='Size(KB)';E={$_.diskUsage}},
        @{N='Stars';E={$_.stargazerCount}},
        @{N='Description';E={if ($_.description) {$_.description.Substring(0,[Math]::Min($_.description.Length, 60))} else {''}}}

    $selected = $displayData | Out-GridView -Title "Select Repos to DELETE — LIN4CRE/$Organization (check the box)" -OutputMode Multiple
    if (-not $selected) {
        Write-Color "No repos selected." Yellow
        exit 0
    }
    $selectedNames = $selected.Name
    $selected = $allRepos | Where-Object { $_.name -in $selectedNames }
}

if (-not $selected -or $selected.Count -eq 0) {
    Write-Color "No repos selected. Exiting." Yellow
    exit 0
}

Write-Color "`n==============================================" Magenta
Write-Color "  REVIEW: $($selected.Count) repo(s) selected for DELETION" Magenta
Write-Color "==============================================" Magenta

$warnings = @()
$selected | ForEach-Object {
    $isFork = if ($_.isFork) { $true } else { $false }
    $isArchived = if ($_.isArchived) { $true } else { $false }
    $isPrivate = ($_.visibility -eq 'PRIVATE')

    $tags = @()
    if ($isPrivate) { $tags += "PRIVATE" }
    if ($isFork) { $tags += "FORK" }
    if ($isArchived) { $tags += "ARCHIVED" }

    $tagStr = if ($tags.Count -gt 0) { " [$($tags -join ', ')]" } else { "" }
    $lang = if ($_.primaryLanguage) { $_.primaryLanguage.name.PadRight(12) } else { "".PadRight(12) }
    Write-Host ("  {0,-30} {1,-8} {2} {3}" -f $_.name, $_.visibility, $lang, $tagStr)

    if ($_.stargazerCount -gt 10) { $warnings += "$($_.name) has $($_.stargazerCount) stars!" }
    if ($_.forkCount -gt 5) { $warnings += "$($_.name) has $($_.forkCount) forks — others depend on it!" }
    if ($_.pullRequests -and $_.pullRequests.Count -gt 0) { $warnings += "$($_.name) has $($_.pullRequests.Count) open pull requests!" }
}

if ($warnings.Count -gt 0) {
    Write-Color "`n⚠  WARNINGS:" Yellow
    $warnings | ForEach-Object { Write-Host ("   • " + $_) -ForegroundColor Yellow }
}

Write-Color "`n⚠  THIS ACTION IS PERMANENT. Deleted repos CANNOT be recovered." Red -BackgroundColor Black
Write-Color ""

if ($DryRun) {
    Write-Color "DRY RUN — no repos were deleted. Pass -DryRun:$false to execute." Cyan
    exit 0
}

$confirm = Read-Host "Type DELETE (all caps) to confirm, or press Enter to cancel"
if ($confirm -ne "DELETE") {
    Write-Color "Cancelled. No repos were deleted." Yellow
    exit 0
}

Write-Color "`nDeleting $($selected.Count) repo(s)..." Cyan
$success = 0
$failures = @()

for ($i = 0; $i -lt $selected.Count; $i++) {
    $repo = $selected[$i]
    $fullName = "$Organization/$($repo.name)"
    $pct = [Math]::Round(($i / $selected.Count) * 100)
    Write-Progress -Activity "Deleting repositories" -Status "$fullName" -PercentComplete $pct

    gh repo delete $fullName --yes 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Color ("  [{0}/{1}] ✓ Deleted: {2}" -f ($i+1), $selected.Count, $fullName) Green
        $success++
    } else {
        Write-Color ("  [{0}/{1}] ✗ FAILED: {2}" -f ($i+1), $selected.Count, $fullName) Red
        $failures += $fullName
    }
}

Write-Progress -Activity "Deleting repositories" -Completed

Write-Color "`n==============================================" Magenta
Write-Color "  RESULTS" Magenta
Write-Color "==============================================" Magenta
Write-Color "  Total selected:  $($selected.Count)" White
Write-Color "  Successfully deleted: $success" $(if ($success -eq $selected.Count) { "Green" } else { "Yellow" })
if ($failures.Count -gt 0) {
    Write-Color "  Failed: $($failures.Count)" Red
    $failures | ForEach-Object { Write-Host ("    • $_") -ForegroundColor Red }
}
Write-Color ""
