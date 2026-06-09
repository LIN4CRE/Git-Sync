---
name: pwsh-in-bash
description: How to run PowerShell commands from the bash tool in this Replit environment without hanging.
---

# Running pwsh from the bash tool

## The problem
`pwsh -Command "..."` and `pwsh -File script.ps1` always hang in the bash tool with exit code -1, outputting `[?1h=` (DECCKM terminal escape). This happens because the bash tool has no TTY, and PowerShell/PSReadLine tries to set up terminal modes and then waits.

Even `TERM=dumb`, `-NonInteractive`, `-NoProfile`, `< /dev/null` redirects all fail to prevent the hang.

## The solution
Run all pwsh invocations **through the workflow** and poll for results:

1. `configureWorkflow({ name: "Start application", command: "pwsh -NoProfile -NonInteractive -File /tmp/script.ps1", outputType: "console" })`
2. `restartWorkflow({ name: "Start application" })`
3. Poll with `getWorkflowStatus({ name: "Start application", maxScrollbackLines: 500 })` until `state !== "running"`
4. When done, restore the real workflow command back to `pwsh -NoExit -File start.ps1`

**Why:** The workflow has a proper PTY attached, so pwsh starts cleanly without hanging.

## How to apply
Any time you need to run a pwsh script (tests, builds, linting), use this workflow-poll pattern. Never attempt bare `pwsh` commands in the bash tool.
