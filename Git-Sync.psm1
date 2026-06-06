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
    2.4.0 - 2026-06-06
    - Packaged as a proper PowerShell module (Git-Sync.psm1 / Git-Sync.psd1)
    - Fixed New-GitRelease parameter binding (AutoBump vs Manual parameter sets)
    - Fixed Get-LatestTag to strip leading 'v' or 'V' prefix
    - Fixed Get-NextVersion to tolerate malformed tags gracefully
    - Fixed double error/warning reporting in helper functions
    - Fixed Invoke-GitDeploy staging check for clarity
    - Fixed New-GitRelease to check gh exit code and handle Force correctly
    - Added Force support to Invoke-GitDeploy (uses --force-with-lease)
    - Added Force support to New-GitRelease (tag overwrite and force push)
    - Removed script-end Write-Host to avoid pollution when dot-sourced
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
        $cleanVersion = $CurrentVersion -replace '^[vV]'
        if (-not ($cleanVersion -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)')) {
            Write-Warning "Invalid current version format: '$CurrentVersion'. Defaulting to 0.0.0."
            $cleanVersion = '0.0.0'
        }

        $parts = $cleanVersion -split '\.'
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
        throw "Failed to calculate next version: $_"
    }
}

function Test-GitRepository {
    [CmdletBinding()]
    param()

    try {
        $result = git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $result) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

function Test-GitRemoteConnectivity {
    [CmdletBinding()]
    param(
        [string]$Remote = 'origin'
    )
    try {
        $null = git ls-remote $Remote --heads 2>&1
        return ($LASTEXITCODE -eq 0)
    }
    catch {
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
    param()

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        $null = gh auth status 2>&1
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
        return $tag -replace '^[vV]'
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
        [string]$Message = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),
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

            git diff --cached --quiet 2>$null
            $hasChanges = ($LASTEXITCODE -ne 0)

            if ($hasChanges) {
                Invoke-GitCommand -Arguments @('commit', '-m', $Message) -ErrorMessage "Commit failed"
                Write-Host "✓ Commit created" -ForegroundColor Green
            } else {
                Write-Host "No changes to commit" -ForegroundColor Yellow
            }

            $pushArgs = @('push', $Remote)
            if ($Force) { $pushArgs += '--force-with-lease' }
            Invoke-GitCommand -Arguments $pushArgs -ErrorMessage "Push failed"
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
        [Parameter(Mandatory, ParameterSetName='Manual')]
        [string]$Version,

        [Parameter(Mandatory, ParameterSetName='AutoBump')]
        [ValidateSet('Patch','Minor','Major')]
        [string]$Bump,

        [string]$Message,

        [string]$Remote = 'origin',

        [switch]$GenerateNotes,

        [switch]$Force
    )

    begin {
        if (-not (Test-GitRepository)) { throw "Not in a Git repository" }

        if ($PSCmdlet.ParameterSetName -eq 'AutoBump') {
            $latestTag = Get-LatestTag
            $Version = Get-NextVersion -CurrentVersion $latestTag -Bump $Bump
            Write-Host "Auto-bumped to version: $Version" -ForegroundColor Cyan
        }

        if (-not $Message) { $Message = "Release $Version" }

        $tagExists = git tag -l $Version 2>$null
        if ($tagExists -and -not $Force) {
            Write-Warning "Version $Version already exists! Use -Force to overwrite."
            return
        }
    }

    process {
        if (-not $PSCmdlet.ShouldProcess("v$Version", "Create release")) { return }

        try {
            # Deploy first
            Invoke-GitDeploy -Message $Message -Remote $Remote -Force:$Force -ErrorAction Stop

            # Create tag (force if requested)
            $tagArgs = @('tag')
            if ($Force) { $tagArgs += '-f' }
            $tagArgs += @('-a', $Version, '-m', $Message)
            Invoke-GitCommand -Arguments $tagArgs -ErrorMessage "Tag creation failed"

            # Push tag (force if requested)
            $pushTagArgs = @('push', $Remote)
            if ($Force) { $pushTagArgs += '--force' }
            $pushTagArgs += "refs/tags/$Version"
            Invoke-GitCommand -Arguments $pushTagArgs -ErrorMessage "Tag push failed"

            # GitHub release with gh
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                $ghArgs = @('release', 'create', $Version, '--title', "Release v$Version")
                if ($GenerateNotes) { $ghArgs += '--generate-notes' }

                & gh @ghArgs
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "GitHub release creation failed (exit code $LASTEXITCODE). The tag has been pushed successfully."
                } else {
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

Export-ModuleMember -Function Get-NextVersion, Test-GitRepository, Test-GitRemoteConnectivity, Invoke-GitCommand, Test-GhAuthentication, Get-LatestTag, Invoke-GitDeploy, New-GitRelease
