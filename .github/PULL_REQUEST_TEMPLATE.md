<!--
Thanks for contributing to Git-Sync! Please fill out the sections below.
A great PR makes review fast and the project safer.
-->

## Summary

<!-- One or two sentences: what does this PR do and why? -->

## Type of Change

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that changes existing behaviour)
- [ ] 📝 Documentation only
- [ ] 🔧 Build / CI / chore
- [ ] ♻️ Refactor (no functional change)
- [ ] 🔒 Security fix

## Related Issues

<!-- e.g. Closes #42, Refs #10 -->

Closes #

## Changes

<!-- Bullet list of meaningful changes. Reviewers should be able to read this and know what to look at. -->

-
-

## Screenshots / Terminal Output

<!-- For UI / terminal output changes, paste before/after. Use code fences. -->

<details>
<summary>Before</summary>

```
```

</details>

<details>
<summary>After</summary>

```
```

</details>

## Testing

How did you verify this change?

- [ ] `.\build.ps1` passes locally (lint + Pester tests)
- [ ] Added or updated Pester tests under `tests/`
- [ ] Manually exercised the affected scenario(s) — describe below
- [ ] Ran with `-WhatIf` against a real repo
- [ ] N/A — explain why

```powershell
# Commands you ran
```

## Checklist

- [ ] My code follows the project [style guide](CONTRIBUTING.md#code-style) (`Set-StrictMode`, `[CmdletBinding()]`, comment-based help).
- [ ] I have added / updated tests that prove my fix or feature works.
- [ ] `PSScriptAnalyzer` reports zero `Error` or `Warning` findings.
- [ ] I updated [`CHANGELOG.md`](CHANGELOG.md) under `## [Unreleased]`.
- [ ] I updated relevant documentation (`README.md`, `INSTALLATION.md`, `ARCHITECTURE.md`).
- [ ] If I added a new exported function, I updated `Git-Sync.psd1` `FunctionsToExport`.
- [ ] No secrets, tokens, or PII are included anywhere in the diff.

## Breaking Change Notes

<!-- If this is a breaking change, describe the migration path. Otherwise delete this section. -->

## Additional Context

<!-- Anything else reviewers should know? Links, design docs, prior art, etc. -->
