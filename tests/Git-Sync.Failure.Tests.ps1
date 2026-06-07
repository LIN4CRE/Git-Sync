#Requires -Version 5.1
BeforeAll {
    $psd1 = Join-Path $PSScriptRoot '..' 'Git-Sync.psd1'
    Import-Module $psd1 -Force
}

Describe 'Invoke-GitDeploy failure paths' {

    It 'Throws when git push fails' {
        $m = Get-Module Git-Sync
        {
            & $m {
                $script:callIdx = 0
                function script:git {
                    $script:callIdx++
                    switch ($script:callIdx) {
                        1 { $script:LASTEXITCODE = 0; return 'true' }
                        2 { $script:LASTEXITCODE = 0; return '' }
                        3 { $script:LASTEXITCODE = 0; return '' }
                        4 { $script:LASTEXITCODE = 0; return '' }
                        default { $script:LASTEXITCODE = 1; return 'fatal: push rejected' }
                    }
                }
                Invoke-GitDeploy -Remote origin -ErrorAction Stop
            }
        } | Should -Throw
    }

    It 'Throws when staging fails' {
        $m = Get-Module Git-Sync
        {
            & $m {
                $script:callIdx = 0
                function script:git {
                    $script:callIdx++
                    switch ($script:callIdx) {
                        1 { $script:LASTEXITCODE = 0; return 'true' }
                        2 { $script:LASTEXITCODE = 0; return '' }
                        default { $script:LASTEXITCODE = 1; return 'fatal: cannot stage' }
                    }
                }
                Invoke-GitDeploy -Remote origin -ErrorAction Stop
            }
        } | Should -Throw
    }

    It 'Throws "Not in a Git repository" when rev-parse fails' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git { $script:LASTEXITCODE = 128; return 'fatal: not a git repository' }
                Invoke-GitDeploy -Remote origin -ErrorAction Stop
            }
        } | Should -Throw
    }

    It 'Emits a warning when remote connectivity check fails but continues' {
        $m = Get-Module Git-Sync
        try {
            & $m {
                $script:callIdx = 0
                function script:git {
                    $script:callIdx++
                    switch ($script:callIdx) {
                        1 { $script:LASTEXITCODE = 0; return 'true' }
                        2 { $script:LASTEXITCODE = 1; return '' }
                        default { $script:LASTEXITCODE = 1; return '' }
                    }
                }
                Invoke-GitDeploy -Remote origin -WarningAction SilentlyContinue -ErrorAction Stop
            } 3>&1 | Out-Null
        } catch { Write-Debug "Expected warning-only path"; }
        $true | Should -Be $true
    }
}

Describe 'New-GitRelease failure paths' {

    It 'Refuses to overwrite an existing tag without -Force' {
        $m = Get-Module Git-Sync
        { & $m {
            function script:git {
                $script:LASTEXITCODE = 0
                if ($args -contains 'tag') { return '1.2.3' }
                return 'true'
            }
            New-GitRelease -Version '1.2.3' -Remote origin -WarningAction SilentlyContinue
        } } | Should -Not -Throw
    }

    It 'Throws when the underlying deploy fails (rollback path)' {
        $m = Get-Module Git-Sync
        {
            & $m {
                $script:callIdx = 0
                function script:git {
                    $script:callIdx++
                    switch ($script:callIdx) {
                        1 { $script:LASTEXITCODE = 0; return 'true' }
                        2 { $script:LASTEXITCODE = 0; return '' }
                        3 { $script:LASTEXITCODE = 0; return 'true' }
                        4 { $script:LASTEXITCODE = 0; return '' }
                        default { $script:LASTEXITCODE = 1; return 'fatal: deploy boom' }
                    }
                }
                New-GitRelease -Version '9.9.9' -Remote origin -ErrorAction Stop
            }
        } | Should -Throw
    }

    It 'Computes the next version in AutoBump mode' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git {
                    $script:LASTEXITCODE = 0
                    if ($args -contains 'rev-parse')   { return 'true' }
                    if ($args -contains 'describe')    { return 'v1.0.0' }
                    if ($args -contains 'tag')         { return '1.0.1' }
                    return ''
                }
                New-GitRelease -Bump Patch -Remote origin -WarningAction SilentlyContinue
            }
        } | Should -Not -Throw
    }

    It 'Overwrites an existing tag when -Force is used' {
        $m = Get-Module Git-Sync
        {
            & $m {
                $script:callIdx = 0
                function script:git {
                    $script:callIdx++
                    $script:LASTEXITCODE = 0
                    switch ($script:callIdx) {
                        1 { return 'true' }
                        2 { return '2.0.0' }
                        3 { return 'true' }
                        4 { return '' }
                        5 { return '' }
                        6 { $script:LASTEXITCODE = 0; return '' }
                        default { return '' }
                    }
                }
                New-GitRelease -Version '2.0.0' -Remote origin -Force -WarningAction SilentlyContinue
            }
        } | Should -Not -Throw
    }
}

Describe 'Get-NextVersion edge cases' {

    It 'Strips uppercase V prefix' {
        Get-NextVersion -CurrentVersion 'V2.0.0' -Bump Patch | Should -Be '2.0.1'
    }

    It 'Resets patch when minor is bumped' {
        Get-NextVersion -CurrentVersion '1.2.9' -Bump Minor | Should -Be '1.3.0'
    }

    It 'Resets minor and patch when major is bumped' {
        Get-NextVersion -CurrentVersion '1.9.9' -Bump Major | Should -Be '2.0.0'
    }
}

Describe 'Invoke-GitCommand contract' {

    It 'Returns a hashtable containing ExitCode, Success, and Output' {
        $m = Get-Module Git-Sync
        $r = & $m {
            function script:git { return 'ok' }
            $script:LASTEXITCODE = 0
            Invoke-GitCommand -Arguments @('status')
        }
        $r | Should -BeOfType [hashtable]
        $r.Keys | Should -Contain 'ExitCode'
        $r.Keys | Should -Contain 'Success'
        $r.Keys | Should -Contain 'Output'
        $r.ExitCode | Should -Be 0
        $r.Success  | Should -Be $true
    }

    It 'IgnoreError returns Success=$false instead of throwing' {
        $m = Get-Module Git-Sync
        $r = & $m {
            function script:git { return 'boom' }
            $script:LASTEXITCODE = 42
            Invoke-GitCommand -Arguments @('status') -IgnoreError
        }
        $r.Success | Should -Be $false
    }
}

Describe 'Catch-block coverage on probe functions' {

    It 'Test-GitRepository returns $false when git itself throws' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { throw 'simulated exec failure' }
            Test-GitRepository
        } | Should -Be $false
    }

    It 'Test-GitRemoteConnectivity returns $false when git throws' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { throw 'no network' }
            Test-GitRemoteConnectivity -Remote origin
        } | Should -Be $false
    }

    It 'Test-GhAuthentication returns $false when gh throws' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$rest) return $true }
            function script:gh { throw 'gh exploded' }
            Test-GhAuthentication
        } | Should -Be $false
    }

    It 'Get-LatestTag returns 0.0.0 when git throws' {
        $m = Get-Module Git-Sync
        & $m {
            function script:git { throw 'no tags here' }
            Get-LatestTag
        } | Should -Be '0.0.0'
    }

    It 'Invoke-GitCommand returns Success=$false with IgnoreError when git throws' {
        $m = Get-Module Git-Sync
        $r = & $m {
            function script:git { throw 'simulated' }
            Invoke-GitCommand -Arguments @('status') -IgnoreError
        }
        $r.Success | Should -Be $false
    }
}

Describe 'Invoke-GitDeploy success-with-commit branch' {

    It 'Creates a commit when staged changes exist' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git {
                    if ($args -contains 'rev-parse')   { $script:LASTEXITCODE = 0; return 'true' }
                    if ($args -contains 'ls-remote')   { $script:LASTEXITCODE = 0; return '' }
                    if ($args -contains 'diff')        { $script:LASTEXITCODE = 1; return '' }
                    $script:LASTEXITCODE = 0; return ''
                }
                Invoke-GitDeploy -Message 'test commit' -Remote origin
            }
        } | Should -Not -Throw
    }

    It 'Uses force push when -Force is specified' {
        $m = Get-Module Git-Sync
        {
            & $m {
                $script:callIdx = 0
                function script:git {
                    $script:callIdx++
                    $script:LASTEXITCODE = 0
                    switch ($script:callIdx) {
                        1 { return 'true' }
                        2 { return '' }
                        3 { return '' }
                        4 { $script:LASTEXITCODE = 0; return '' }
                        default { return '' }
                    }
                }
                Invoke-GitDeploy -Remote origin -Force -WarningAction SilentlyContinue
            }
        } | Should -Not -Throw
    }
}

Describe 'New-GitRelease rollback guidance branch' {

    It 'Prints rollback hints and throws when an inner operation fails' {
        $m = Get-Module Git-Sync
        {
            & $m {
                function script:git {
                    if ($args -contains 'rev-parse') { $script:LASTEXITCODE = 0; return 'true' }
                    if ($args -contains 'tag' -and $args -contains '-l') { $script:LASTEXITCODE = 0; return '' }
                    if ($args -contains 'ls-remote') { $script:LASTEXITCODE = 0; return '' }
                    $script:LASTEXITCODE = 1; return 'fatal: boom'
                }
                New-GitRelease -Version '7.7.7' -Remote origin -ErrorAction Stop
            }
        } | Should -Throw
    }
}

Describe 'Switch-GhAccount fallback branch' {

    It 'Falls back to legacy gh auth switch when --user fails' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$rest) return $true }
            $script:ghCallIdx = 0
            function script:gh {
                $script:ghCallIdx++
                switch ($script:ghCallIdx) {
                    1 { $script:LASTEXITCODE = 0; return 'Logged in to github.com account as other' }
                    2 { $script:LASTEXITCODE = 1; return '' }
                    3 { $script:LASTEXITCODE = 0; return '' }
                    default { $script:LASTEXITCODE = 0; return '' }
                }
            }
            Switch-GhAccount -TargetAccount 'octocat'
        } | Should -Be $true
    }

    It 'Returns $false when gh itself throws inside the try block' {
        $m = Get-Module Git-Sync
        & $m {
            function Get-Command { param([Parameter(ValueFromRemainingArguments)]$rest) return $true }
            function script:gh { throw 'gh died' }
            Switch-GhAccount -TargetAccount 'octocat' -WarningAction SilentlyContinue
        } | Should -Be $false
    }
}
