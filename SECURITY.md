# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.3.x   | :white_check_mark: |
| < 2.3   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in Git-Sync, please report it responsibly.

**Do not** open a public issue or pull request containing sensitive details.

Instead, please email us directly at: **security@lin4cre.dev** (or contact the repository owner via GitHub private message if email is unavailable).

Please include the following details:
- A clear description of the vulnerability
- Steps to reproduce (if applicable)
- Affected versions
- Any potential impact or risk assessment
- Suggested remediation (if you have one)

We will acknowledge receipt within 48 hours and aim to provide a timeline for a fix within 5 business days. We will coordinate disclosure to ensure users are protected before details are made public.

## Scope

This security policy covers:
- All PowerShell scripts (`*.ps1`) in this repository
- GitHub Actions workflows (`.github/workflows/*.yml`)
- Documentation that could lead to insecure configurations

Out of scope:
- Third-party dependencies (Git, GitHub CLI) — please report those to their respective security teams
- Issues that require physical access to the user's machine

## Best Practices for Users

- **Never commit secrets, tokens, or passwords** into your repositories. This tool does not store credentials, but ensure you do not accidentally commit `.env` files or GitHub tokens.
- Keep Git and `gh` CLI updated to the latest stable versions.
- Use fine-grained Personal Access Tokens (PATs) with the minimum required scopes when using `gh auth login`.
- Review the `git remote` URLs before syncing to ensure you are pushing to the intended remotes.
- If you use `-Force`, ensure you understand the implications of force-pushing and force-tagging in a shared repository.

## Acknowledgments

We thank the security researchers and community members who help keep Git-Sync safe.
