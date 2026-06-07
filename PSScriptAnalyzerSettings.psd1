@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidOverwritingBuiltInCmdlets',
        'PSReviewUnusedParameter',
        'PSAvoidAssignmentToAutomaticVariable',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingEmptyCatchBlock'
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
