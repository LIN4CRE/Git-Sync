@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidOverwritingBuiltInCmdlets',
        'PSReviewUnusedParameter'
    )
    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSAvoidDefaultValueSwitchParameter = @{
            Enable = $false
        }
    }
}
