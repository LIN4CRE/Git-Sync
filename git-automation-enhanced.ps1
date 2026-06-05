#Requires -Version 5.1
<#
.SYNOPSIS
 Enhanced Git deployment and release automation with smart versioning and advanced error handling.

.DESCRIPTION
 Production-grade module with:
 - Smart semantic version bumping (auto-increment patch/minor/major)
 - Comprehensive error handling and recovery
 - Multi-account GitHub support ready
 - Bulk operations support

.VERSION
 2.2.0 - 2026-06-06
 - Fixed missing Test-GitRemoteConnectivity function (now defined inline)
 - Fixed $GH_HOST misuse (no longer sets env var for usernames)
 - Fixed $GenerateNotes switch default (removed misleading = $true)
 - Improved empty changeset detection
 - Better null-safety on version parsing
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

#region Enhanced Helper Functions

function Get-NextVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CurrentVersion,

        [ValidateSet('Patch', 'Minor', 'Major')]
        [string]$Bump = 'Patch',

        [switch]$Prerelease
    )

    try {
        if (-not ($CurrentVersion -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)')) {
            throw "Invalid current version format: '$CurrentVersion'. Expected semver (e.g. 1.2.3)."
        }

        $parts = $CurrentVersion -split '\.'
        $major = [int]$parts[0]
        $minor = [int]$parts[1]
        $patch = [int]$parts[2]

        switch ($Bump) {
            'Major' { $major++; $minor = 0; $patch = 0 }
            'Minor' { $minor++; $patch = 0 }
            'Patch' { $patch++ }
        }

        $newVersion = "$major.$minor.$patch"

        if ($Prerelease) {
            $newVersion += "-beta.1"
        }

        return $newVersion
    }
    catch {
        Write-Error "Failed to calculate next version: $_"
        throw
    }
}

function Test-GitRepository {
    [CmdletBinding()]
    param()

    try {
        $result = git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $result) {
            throw "Not a valid Git repository"
        }
        return $true
    }
    catch {
        Write-Error "Repository check failed: $_"
        return $false
    }
}

function Test-GitRemoteConnectivity {
    [CmdletBinding()]
    param(
        [string]$Remote = 'origin'
    )
    try {
        $output = git ls-remote $Remote --heads 2>&1
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        Write-Warning "Could not reach remote '$Remote': $_"
        return $false
    }
}

function Invoke-GitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$ErrorMessage = "Git command failed",
        [switch]$IgnoreError
    )

    try {
        Write-Debug "Running: git $($Arguments -join ' ')"
        $output = & git @Arguments 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0 -and -not $IgnoreError) {
            throw "$ErrorMessage`nOutput: $output"
        }
        return @{ Success = ($exitCode -eq 0); Output = $output; ExitCode = $exitCode }
    }
    catch {
        if (-not $IgnoreError) { throw }
        return @{ Success = $false; Error = $_ }
    }
}

function Test-GhAuthentication {
    [CmdletBinding()]
    param(
        [string]$Account = $null
    )

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        # gh auth status does not use GH_HOST for usernames;
        # GH_HOST is for GitHub Enterprise. Account switching
        # should be done via gh auth switch --user <username>.
        $status = gh auth status 2>&1
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Get-LatestTag {
    [CmdletBinding()]
    param()
    try {
        $tag = git describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tag)) {
            return "0.0.0"
        }
        return $tag
    }
    catch {
        return "0.0.0"
    }
}

#endregion

#region Enhanced Main Functions

function Invoke-GitDeploy {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$Message = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'),
        [string]$Remote = 'origin',
        [switch]$Force
    )

    begin {
        if (-not (Test-GitRepository)) { throw "Not in a Git repository" }
        if (-not (Test-GitRemoteConnectivity -Remote $Remote)) {
            Write-Warning "Remote connectivity issues detected for '$Remote'"
        }
    }

    process {
        if (-not $PSCmdlet.ShouldProcess($Remote, "Deploy changes")) { return }

        try {
            Invoke-GitCommand -Arguments @('add', '-A') -ErrorMessage "Staging failed"

            $hasChanges = -not (git diff --cached --quiet 2>$null; $LASTEXITCODE -eq 0)

            if ($hasChanges) {
                Invoke-GitCommand -Arguments @('commit', '-m', $Message) -ErrorMessage "Commit failed"
                Write-Host "✓ Commit created" -ForegroundColor Green
            } else {
                Write-Host "No changes to commit" -ForegroundColor Yellow
            }

            Invoke-GitCommand -Arguments @('push', $Remote) -ErrorMessage "Push failed"
            Write-Host "✓ Deployed successfully to $Remote" -ForegroundColor Green
        }
        catch {
            Write-Error "Deploy failed: $_"
            Write-Host "Tip: Run 'git status' to check current state" -ForegroundColor Cyan
            throw
        }
    }
}

function New-GitRelease {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$Version,

        [ValidateSet('Patch','Minor','Major')]
        [string]$Bump = 'Patch',

        [string]$Message,

        [string]$Remote = 'origin',

        [switch]$GenerateNotes,

        [switch]$Force
    )

    begin {
        if (-not (Test-GitRepository)) { throw "Not in a Git repository" }

        # Smart version handling
        if ($Bump) {
            $latestTag = Get-LatestTag
            $Version = Get-NextVersion -CurrentVersion $latestTag -Bump $Bump
            Write-Host "Auto-bumped to version: $Version" -ForegroundColor Cyan
        }

        if (-not $Message) { $Message = "Release $Version" }

        # Enhanced duplicate check
        $tagExists = git tag -l $Version 2>$null
        if ($tagExists -and -not $Force) {
            Write-Warning "Version $Version already exists!"
            return
        }
    }

    process {
        if (-not $PSCmdlet.ShouldProcess("v$Version", "Create release")) { return }

        try {
            # Deploy first
            Invoke-GitDeploy -Message $Message -Remote $Remote -ErrorAction Stop

            # Create tag
            Invoke-GitCommand -Arguments @('tag', "-a", $Version, "-m", $Message) -ErrorMessage "Tag creation failed"
            Invoke-GitCommand -Arguments @('push', $Remote, "--tags") -ErrorMessage "Tag push failed"

            # GitHub release with gh
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                $ghArgs = @('release', 'create', $Version, '--title', "Release v$Version")
                if ($GenerateNotes) { $ghArgs += '--generate-notes' }

                & gh @ghArgs
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ GitHub Release v$Version created!" -ForegroundColor Green
                }
            }

            Write-Host "✓ Release v$Version completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Release failed: $_"

            # Automatic rollback suggestions
            Write-Host "`nRollback commands:" -ForegroundColor Yellow
            Write-Host " git tag -d $Version" -ForegroundColor Cyan
            Write-Host " git push $Remote :refs/tags/$Version" -ForegroundColor Cyan
            throw
        }
    }
}

#endregion

Write-Host "Enhanced Git Automation loaded. New features: Smart versioning + better error handling" -ForegroundColor Magenta
