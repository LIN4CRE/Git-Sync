#Requires -Version 5.1
BeforeAll {
    $psd1 = Join-Path $PSScriptRoot '..' 'Git-Sync.psd1'
    Import-Module $psd1 -Force
}

Describe 'Test-GitSyncEnvironment' {

    It 'Returns a result object with Ok / Failures / Warnings / Checks' {
        $r = Test-GitSyncEnvironment -Quiet
        $r | Should -Not -BeNullOrEmpty
        $r.PSObject.Properties.Name | Should -Contain 'Ok'
        $r.PSObject.Properties.Name | Should -Contain 'Failures'
        $r.PSObject.Properties.Name | Should -Contain 'Warnings'
        $r.PSObject.Properties.Name | Should -Contain 'Checks'
    }

    It 'Includes a PowerShell version check that passes on PS 5.1+' {
        $r = Test-GitSyncEnvironment -Quiet
        $psCheck = $r.Checks | Where-Object Name -eq 'PowerShell version'
        $psCheck | Should -Not -BeNullOrEmpty
        $psCheck.Status | Should -Be 'Pass'
    }

    It 'Includes an execution policy check' {
        $r = Test-GitSyncEnvironment -Quiet
        ($r.Checks | Where-Object Name -eq 'Execution policy') | Should -Not -BeNullOrEmpty
    }

    It 'Includes a git CLI check' {
        $r = Test-GitSyncEnvironment -Quiet
        ($r.Checks | Where-Object Name -eq 'git CLI') | Should -Not -BeNullOrEmpty
    }

    It 'Includes a gh CLI check (always present, may warn)' {
        $r = Test-GitSyncEnvironment -Quiet
        ($r.Checks | Where-Object Name -eq 'gh CLI (optional)') | Should -Not -BeNullOrEmpty
    }

    It 'Includes a Git-Sync module check' {
        $r = Test-GitSyncEnvironment -Quiet
        ($r.Checks | Where-Object Name -eq 'Git-Sync module') | Should -Not -BeNullOrEmpty
    }

    It 'Reports Ok=$true when every check passes' {
        $r = Test-GitSyncEnvironment -Quiet
        $gitCheck = $r.Checks | Where-Object Name -eq 'git CLI'
        if ($gitCheck.Status -eq 'Pass') {
            $r.Ok | Should -Be $true
        }
        $r.Failures | Should -BeOfType [int]
        $r.Warnings | Should -BeOfType [int]
    }

    It 'Honors -Quiet (does not write to host)' {
        $out = Test-GitSyncEnvironment -Quiet 6>&1 | Out-String
        ($out -match 'Git-Sync Environment Doctor') | Should -Be $false
    }

    It 'Each check has Name, Status, Detail, and Fix properties' {
        $r = Test-GitSyncEnvironment -Quiet
        foreach ($c in $r.Checks) {
            $c.PSObject.Properties.Name | Should -Contain 'Name'
            $c.PSObject.Properties.Name | Should -Contain 'Status'
            $c.PSObject.Properties.Name | Should -Contain 'Detail'
            $c.PSObject.Properties.Name | Should -Contain 'Fix'
            $c.Status | Should -BeIn @('Pass','Warn','Fail')
        }
    }

    It 'Produces banner output when -Quiet is not specified' {
        $captured = Test-GitSyncEnvironment 6>&1 | Out-String
        $captured | Should -Match 'Git-Sync Environment Doctor'
        $captured | Should -Match 'PowerShell version'
        $captured | Should -Match '(HEALTHY|PROBLEMS DETECTED)'
    }

    It 'Reports HEALTHY result line when there are no failures' {
        $captured = Test-GitSyncEnvironment 6>&1 | Out-String
        $captured | Should -Match '(Result: HEALTHY|Result: PROBLEMS DETECTED)'
    }

    It 'Accepts a -RepoPath parameter and uses it for module lookup' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("doctor-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        try {
            { Test-GitSyncEnvironment -RepoPath $tmp -Quiet } | Should -Not -Throw
        }
        finally { Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue }
    }
}
