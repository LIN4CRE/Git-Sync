@echo off
REM ==========================================================================
REM  Git-Sync universal launcher
REM  --------------------------------------------------------------------------
REM  Purpose: make Git-Sync "just work" on Windows by handling the four most
REM           common reasons a .ps1 won't run for a non-PowerShell user:
REM             1. .ps1 file association sends you to Notepad
REM             2. Execution policy is Restricted / AllSigned
REM             3. Downloaded files are blocked (Zone.Identifier)
REM             4. PowerShell 7 (pwsh) and Windows PowerShell 5.1 coexist
REM
REM  Usage:
REM     Git-Sync.bat                  -> launches Sync-AllRepos-Hacker.ps1
REM     Git-Sync.bat -WhatIf          -> dry run; args are forwarded verbatim
REM     Git-Sync.bat -Action Release -BumpVersion Patch
REM
REM  Exit codes:
REM     0   success (or successful dry run)
REM     2   PowerShell not found on PATH
REM     3   Target .ps1 not found next to this .bat
REM     >3  whatever the .ps1 returned
REM ==========================================================================

setlocal EnableExtensions EnableDelayedExpansion

REM ---- Resolve our own folder (script may be launched from any CWD) --------
set "SCRIPT_DIR=%~dp0"
REM Strip trailing backslash for nicer messages
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "TARGET=%SCRIPT_DIR%\Sync-AllRepos-Hacker.ps1"
if not exist "%TARGET%" (
    echo.
    echo [Git-Sync] ERROR: Sync-AllRepos-Hacker.ps1 not found.
    echo            Expected at: "%TARGET%"
    echo            Make sure Git-Sync.bat lives in the same folder as the .ps1 files.
    echo.
    exit /b 3
)

REM ---- Pick the best available PowerShell ----------------------------------
REM Prefer PowerShell 7+ (pwsh) when present; fall back to Windows PowerShell.
set "PS_EXE="
where pwsh >nul 2>&1 && set "PS_EXE=pwsh"
if not defined PS_EXE (
    where powershell >nul 2>&1 && set "PS_EXE=powershell"
)
if not defined PS_EXE (
    echo.
    echo [Git-Sync] ERROR: Could not find PowerShell on PATH.
    echo            Install PowerShell 7 from https://aka.ms/powershell
    echo            or ensure Windows PowerShell 5.1 (powershell.exe) is available.
    echo.
    exit /b 2
)

REM ---- Soft pre-flight: unblock any Zone.Identifier streams ---------------
REM   Cheap, idempotent, and fixes the #1 cause of "tests won't discover".
REM   We do this in-process so we don't open a second window.
set "PRELUDE=$ErrorActionPreference='SilentlyContinue';"
set "PRELUDE=%PRELUDE% Get-ChildItem -LiteralPath '%SCRIPT_DIR%' -Recurse -Include *.ps1,*.psm1,*.psd1 ^| Unblock-File;"

REM ---- Build the PowerShell command line ----------------------------------
REM   -NoProfile         : faster, deterministic
REM   -ExecutionPolicy Bypass : scoped to THIS PROCESS only; never persisted
REM   -File              : run the script with the remaining args
REM
REM   We use -Command (not -File) so we can inject the pre-flight unblock,
REM   then & call the .ps1 with the forwarded arguments.
set "FORWARDED=%*"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "%PRELUDE% & '%TARGET%' %FORWARDED%"

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo [Git-Sync] PowerShell returned exit code %RC%.
    echo            Run "Git-Sync-Doctor.bat" to diagnose the environment.
    echo.
)
echo.
pause
exit /b %RC%
