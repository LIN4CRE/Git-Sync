@{
    RootModule = 'Git-Sync.psm1'
    ModuleVersion = '2.6.0'
    GUID = '55c49c22-9867-4b9c-9516-e2f4ef0249c2'
    Author = 'LIN4CRE'
    CompanyName = 'LIN4CRE'
    Copyright = '(c) 2026 LIN4CRE. All rights reserved.'
    Description = 'Powerful multi-account Git automation toolkit with smart versioning, bulk operations, and advanced error handling.'
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
        'Test-GitSyncEnvironment'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Git', 'GitHub', 'Automation', 'DevOps', 'Versioning', 'Release', 'PowerShell')
            LicenseUri = 'https://github.com/LIN4CRE/Git-Sync/blob/main/LICENSE'
            ProjectUri = 'https://github.com/LIN4CRE/Git-Sync'
            ReleaseNotes = 'https://github.com/LIN4CRE/Git-Sync/blob/main/CHANGELOG.md'
        }
    }
}
