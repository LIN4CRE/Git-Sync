@{
    # Severity levels enforced in CI. Information is reported locally but
    # does not fail the build.
    Severity     = @('Error', 'Warning')

    # Rules intentionally excluded with rationale:
    #   PSAvoidUsingWriteHost          : the UI script (Sync-AllRepos-Hacker.ps1)
    #                                    is intentionally interactive and colourful.
    #   PSAvoidOverwritingBuiltInCmdlets: tests use `function script:git` to mock
    #                                    the native `git` cmdlet — by design.
    #   PSReviewUnusedParameter        : noisy on PowerShell switch parameters used
    #                                    only inside conditional branches.
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
        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }
        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckSeparator                  = $true
            CheckPipe                       = $true
            CheckInnerBrace                 = $true
            CheckParameter                  = $false
        }
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
    }
}
