# Support

Thanks for using **Git-Sync**! This page explains how to get help, what kind of support you can expect, and the fastest path to a resolution for each kind of issue.

## TL;DR

| You have... | Go to |
|---|---|
| A bug or unexpected behaviour | [Open a bug report](https://github.com/LIN4CRE/Git-Sync/issues/new?template=bug_report.md) |
| A new idea or feature request | [Open a feature request](https://github.com/LIN4CRE/Git-Sync/issues/new?template=feature_request.md) |
| A usage / "how do I…" question | [Start a Discussion](https://github.com/LIN4CRE/Git-Sync/discussions) |
| A **security vulnerability** | Follow [`SECURITY.md`](SECURITY.md) — **do not** open a public issue |
| Want to contribute code | See [`CONTRIBUTING.md`](CONTRIBUTING.md) |

## Self-Service Resources

Before opening an issue, please check:

1. **[`README.md`](README.md)** — features, quick-start, QoL switches, troubleshooting table.
2. **[`INSTALLATION.md`](INSTALLATION.md)** — full install guide with the most common Windows pitfalls (`Unblock-File`, execution policy, `gh` login).
3. **[`CHANGELOG.md`](CHANGELOG.md)** — confirm whether the issue is already fixed in a newer version.
4. **[`tests/Git-Sync.Tests.ps1`](tests/Git-Sync.Tests.ps1)** — concrete examples of how each function is intended to behave.
5. **Existing issues** — search [open + closed](https://github.com/LIN4CRE/Git-Sync/issues?q=is%3Aissue) before filing a new one.

## How to File a Useful Bug Report

A great bug report includes:

- `$PSVersionTable` output (PowerShell version, edition, OS).
- `git --version` and (if relevant) `gh --version`.
- Git-Sync version (`Get-Module Git-Sync | Select-Object Version` or the version line at the top of the script).
- The **exact command** you ran, with parameters.
- The **complete error message** (use code fences, redact tokens/paths if needed).
- What you expected vs. what happened.
- Whether `-WhatIf` reproduces the issue.

The repository ships an [issue template](.github/ISSUE_TEMPLATE/bug_report.md) that captures all of this. Please fill it in — issues missing this information will be labelled `needs-info` and may be closed if not updated within 14 days.

## Response Targets

Git-Sync is a community-maintained open source project. The maintainers volunteer their time, so response targets are **best-effort**, not guarantees.

| Issue type | Best-effort first response | Best-effort resolution |
|---|---|---|
| Critical security report (per `SECURITY.md`) | 48 hours | 5 business days for an initial patch plan |
| Reproducible bug with full repro | 5 business days | Next minor release |
| Feature request | 2 weeks | Triage label, decision in the next milestone planning |
| Usage question on Discussions | Best-effort, community-driven | n/a |

## Commercial / Priority Support

There is **no paid support tier** for Git-Sync. If you are deploying Git-Sync in a regulated or enterprise environment and need an SLA, you are encouraged to:

- Fork the repository and maintain your own internal build,
- Pin to a specific tagged release, and
- Use the [`SECURITY.md`](SECURITY.md) channel for any sensitive findings.

## Out of Scope

The maintainers cannot help with:

- Generic Git / GitHub questions unrelated to Git-Sync (try [Git documentation](https://git-scm.com/doc) or [GitHub Community](https://github.com/orgs/community/discussions)).
- Issues with **third-party tools** (`git`, `gh`, Windows, your antivirus) — please report those upstream.
- Custom forks or modifications that diverge significantly from `main`.
- Code-review of your unrelated PowerShell scripts.

## Contact Summary

| Channel | When to use |
|---|---|
| GitHub Issues | Bugs, feature requests |
| GitHub Discussions | Q&A, ideas, show-and-tell |
| Email (`security@lin4cre.dev`) | **Only** vulnerabilities, per [`SECURITY.md`](SECURITY.md) |

Thanks again — feedback and bug reports are the best way to make Git-Sync better. 💚
