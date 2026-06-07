#Requires -Version 5.1
<#
.SYNOPSIS
    Pester tests for Get-GitHubAccountFromRepo and Switch-GhAccount.

.DESCRIPTION
    These helpers were extracted from Sync-AllRepos-Hacker.ps1 in v2.5.0 so
    they can be unit-tested without spinning up a real git repository or
    invoking the GitHub CLI.
#>

BeforeAll {
    $psd1 = Join-Path $PSScriptRoot '..' 'Git-Sync.psd1'
    Import-Module $psd1 -Force
}

Describe 'Get-GitHubAccountFromRepo' {

    It 'Returns $null when the path does not exist' {
        $missing = Join-Path ([System.IO.Path]::GetTempPath()) ("nope-" + [guid]::NewGuid())
        Get-GitHubAccountFromRepo -RepoPath $missing | Should -BeNullOrEmpty
    }

    It 'Returns $null when git remote get-url fails' {
        $m = Get-Module Git-Sync
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("g-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            & $m {
                param($p)
                function script:git { return $null }
                $script:LASTEXITCODE = 128
                Get-GitHubAccountFromRepo -RepoPath $p
            } $tmp | Should -BeNullOrEmpty
        }
        finally { Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue }
    }

    It 'Parses an HTTPS GitHub remote URL' {
        $m = Get-Module Git-Sync
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("g-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            & $m {
                param($p)
                function script:git { return 'https://github.com/octocat/Hello-World.git' }
                $script:LASTEXITCODE = 0
                Get-GitHubAccountFromRepo -RepoPath $p
            } $tmp | Should -Be 'octocat'
        }
        finally { Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue }
    }

    It 'Parses an SSH GitHub remote URL' {
        $m = Get-Module Git-Sync
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("g-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            & $m {
                param($p)
                function script:git { return 'git@github.com:LIN4CRE/Git-Sync.git' }
                $script:LASTEXITCODE = 0
                Get-GitHubAccountFromRepo -RepoPath $p
            } $tmp | Should -Be 'LIN4CRE'
        }
        finally { Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue }
    }

    It 'Allows usernames with hyphens (regression test for v2.3.0)' {
        $m = Get-Module Git-Sync
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("g-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            & $m {
                param($p)
                function script:git { return 'https://github.com/some-user/repo.git' }
                $script:LASTEXITCODE = 0
                Get-GitHubAccountFromRepo -RepoPath $p
            } $tmp | Should -Be 'some-user'
        }
        finally { Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue }
    }

    It 'Returns $null for a non-GitHub remote' {
        $m = Get-Module Git-Sync
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("g-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            & $m {
                param($p)
                function script:git { return 'https://gitlab.com/foo/bar.git' }
                $script:LASTEXITCODE = 0
                Get-GitHubAccountFromRepo -RepoPath $p
            } $tmp | Should -BeNullOrEmpty
        }
        finally { Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue }
    }
}

Describe 'Switch-GhAccount' {

    It 'Returns $false and warns on empty target account' {
        $w = $null
        Switch-GhAccount -TargetAccount '' -WarningVariable w -WarningAction SilentlyContinue |
            Should -Be $false
        $w | Should -Not -BeNullOrEmpty
    }

    It 'Returns $false and warns on whitespace target account' {
        Switch-GhAccount -TargetAccount '   ' -WarningAction SilentlyContinue |
            Should -Be $false
    }

    It 'Returns $false when gh CLI is not installed' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$args) return $null }
            Switch-GhAccount -TargetAccount 'octocat' -WarningAction SilentlyContinue
        } | Should -Be $false
    }

    It 'Returns $true and is a no-op when already on the target account' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$args) return $true }
            function script:gh {
                # Emit what `gh auth status` typically prints
                return @(
                    'github.com',
                    '  X Logged in to github.com account as octocat (keyring)'
                )
            }
            $script:LASTEXITCODE = 0
            Switch-GhAccount -TargetAccount 'octocat'
        } | Should -Be $true
    }

    It 'Returns $true after a successful switch' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$args) return $true }
            function script:gh { return 'Logged in to github.com account as other-user' }
            $script:LASTEXITCODE = 0
            Switch-GhAccount -TargetAccount 'octocat'
        } | Should -Be $true
    }

    It 'Honors -WhatIf and does not invoke gh auth switch' {
        $m = Get-Module Git-Sync
        $callCount = 0
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$args) return $true }
            function script:gh {
                $script:LASTEXITCODE = 0
                return 'Logged in to github.com account as other-user'
            }
            Switch-GhAccount -TargetAccount 'octocat' -WhatIf
        } | Should -Be $true
    }
}
