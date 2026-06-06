#Requires -Version 5.1
<#
.SYNOPSIS
    Pester tests for Git-Sync core functions.

.DESCRIPTION
    Unit tests for the helper functions exported by the Git-Sync module.
    Git commands are mocked so these tests do not require a real Git repository.

.NOTES
    Run via build.ps1 or Invoke-Pester directly:
    Invoke-Pester -Path .\tests\Git-Sync.Tests.ps1
#>

BeforeAll {
    # Import the module so Pester can mock the exported functions
    $psd1 = Join-Path $PSScriptRoot '..' 'Git-Sync.psd1'
    Import-Module $psd1 -Force
}

Describe 'Get-NextVersion' {
    It 'Increments patch by default' {
        Get-NextVersion -CurrentVersion '1.2.3' | Should -Be '1.2.4'
    }

    It 'Increments minor' {
        Get-NextVersion -CurrentVersion '1.2.3' -Bump Minor | Should -Be '1.3.0'
    }

    It 'Increments major' {
        Get-NextVersion -CurrentVersion '1.2.3' -Bump Major | Should -Be '2.0.0'
    }

    It 'Handles v-prefixed versions' {
        Get-NextVersion -CurrentVersion 'v1.2.3' -Bump Patch | Should -Be '1.2.4'
    }

    It 'Defaults to 0.0.0 when given malformed input and warns' {
        Get-NextVersion -CurrentVersion 'not-a-version' -Bump Patch -ErrorAction SilentlyContinue | Should -Be '0.0.1'
    }

    It 'Adds prerelease suffix when requested' {
        Get-NextVersion -CurrentVersion '1.0.0' -Bump Patch -Prerelease | Should -Be '1.0.1-beta.1'
    }
}

Describe 'Test-GitRepository' {
    It 'Returns true when git says we are inside a work tree' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { return 'true' }
            $script:LASTEXITCODE = 0
            Test-GitRepository
        } | Should -Be $true
    }

    It 'Returns false when git exits non-zero' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { return 'false' }
            $script:LASTEXITCODE = 1
            Test-GitRepository
        } | Should -Be $false
    }
}

Describe 'Test-GitRemoteConnectivity' {
    It 'Returns true on successful ls-remote' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { return '' }
            $script:LASTEXITCODE = 0
            Test-GitRemoteConnectivity
        } | Should -Be $true
    }

    It 'Returns false on failed ls-remote' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { return '' }
            $script:LASTEXITCODE = 128
            Test-GitRemoteConnectivity
        } | Should -Be $false
    }
}

Describe 'Invoke-GitCommand' {
    It 'Returns a success hashtable on exit code 0' {
        $m = Get-Module Git-Sync
        $result = & $m {
            function script:git { return 'ok' }
            $script:LASTEXITCODE = 0
            Invoke-GitCommand -Arguments @('status')
        }
        $result.Success | Should -Be $true
        $result.ExitCode | Should -Be 0
    }

    It 'Throws on non-zero exit code by default' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git { return 'error' }
                $script:LASTEXITCODE = 1
                Invoke-GitCommand -Arguments @('push')
            }
        } | Should -Throw
    }

    It 'Does not throw when IgnoreError is set' {
        $m = Get-Module Git-Sync
        $result = & $m {
            function script:git { return 'error' }
            $script:LASTEXITCODE = 1
            Invoke-GitCommand -Arguments @('push') -IgnoreError
        }
        $result.Success | Should -Be $false
    }
}

Describe 'Get-LatestTag' {
    It 'Returns the latest tag stripped of v-prefix' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { return 'v2.1.0' }
            $script:LASTEXITCODE = 0
            Get-LatestTag
        } | Should -Be '2.1.0'
    }

    It 'Returns 0.0.0 when no tags exist' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { return 'fatal: No names found' }
            $script:LASTEXITCODE = 128
            Get-LatestTag
        } | Should -Be '0.0.0'
    }
}

Describe 'Test-GhAuthentication' {
    It 'Returns false when gh is not installed' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param($Name) return $null }
            Test-GhAuthentication
        } | Should -Be $false
    }

    It 'Returns true when gh auth status succeeds' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param($Name) return $true }
            function script:gh { return 'Logged in' }
            $script:LASTEXITCODE = 0
            Test-GhAuthentication
        } | Should -Be $true
    }
}

Describe 'Invoke-GitDeploy' {
    It 'Should not throw in a mocked repo with no changes' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git { return 'true' }
                $script:LASTEXITCODE = 0
                Invoke-GitDeploy -Remote origin
            }
        } | Should -Not -Throw
    }
}

Describe 'New-GitRelease' {
    It 'Should bump version when using AutoBump parameter set' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git { return 'v1.0.0' }
                function script:gh { return 'ok' }
                $script:LASTEXITCODE = 0
                New-GitRelease -Bump Patch -Remote origin
            }
        } | Should -Not -Throw
    }

    It 'Should use explicit version when using Manual parameter set' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git { return 'v1.0.0' }
                function script:gh { return 'ok' }
                $script:LASTEXITCODE = 0
                New-GitRelease -Version '2.0.0' -Remote origin
            }
        } | Should -Not -Throw
    }
}
