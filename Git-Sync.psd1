@{
    RootModule = 'Git-Sync.psm1'
    ModuleVersion = '2.7.0'
    GUID = '55c49c22-9867-4b9c-9516-e2f4ef0249c2'
    Author = 'LIN4CRE'
    CompanyName = 'LIN4CRE'
    Copyright = '(c) 2026 LIN4CRE. All rights reserved.'
    Description = 'Powerful multi-account Git automation toolkit with smart versioning, bulk sync, release management, and a hacker-style terminal UI. Supports automatic GitHub CLI account switching per repo.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-NextVersion',
        'Test-GitRepository',
        'Test-GitRemoteConnectivity',
        'Invoke-GitCommand',
        'Test-GhAuthentication',
        'Get-LatestTag',
        'Invoke-GitDeploy',
        'New-GitRelease',
        'Get-GitHubAccountFromRepo',
        'Switch-GhAccount',
        'Test-GitSyncEnvironment',
        'Sync-GitRepository'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @(
                'Git', 'GitHub', 'Automation', 'DevOps', 'Versioning',
                'Release', 'PowerShell', 'MultiAccount', 'BulkSync',
                'SemanticVersioning', 'GitHubCLI', 'CI', 'Release-Automation'
            )
            LicenseUri = 'https://github.com/LIN4CRE/Git-Sync/blob/main/LICENSE'
            ProjectUri = 'https://github.com/LIN4CRE/Git-Sync'
            IconUri = 'https://raw.githubusercontent.com/LIN4CRE/Git-Sync/main/hacker-icon.png'
            ReleaseNotes = 'https://github.com/LIN4CRE/Git-Sync/blob/main/CHANGELOG.md'
        }
    }
}
