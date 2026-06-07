@echo off
REM ==========================================================================
REM  Install.bat - one-shot Git-Sync bootstrapper for Windows
REM  --------------------------------------------------------------------------
REM  What it does, in order:
REM     1. Verifies PowerShell is available (pwsh preferred).
REM     2. Sets execution policy to RemoteSigned for the *CurrentUser* scope
REM        (per-user, no admin required, recoverable).
REM     3. Installs the Git-Sync module from the PowerShell Gallery
REM        OR uses the local checkout if one is present alongside this script.
REM     4. Runs the doctor to verify the install.
REM
REM  Two modes:
REM     Install.bat               -> auto-detect (local if .psd1 found, else PSGallery)
REM     Install.bat --local       -> force local-only
REM     Install.bat --gallery     -> force PSGallery
REM ==========================================================================

setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "MODE=auto"
if /i "%~1"=="--local"   set "MODE=local"
if /i "%~1"=="--gallery" set "MODE=gallery"

REM ---- PowerShell discovery ------------------------------------------------
set "PS_EXE="
where pwsh >nul 2>&1 && set "PS_EXE=pwsh"
if not defined PS_EXE (
    where powershell >nul 2>&1 && set "PS_EXE=powershell"
)
if not defined PS_EXE (
    echo.
    echo [Install] ERROR: PowerShell not found. Install PowerShell 7 from:
    echo                  https://aka.ms/powershell
    echo.
    exit /b 2
)

echo.
echo === Git-Sync installer (mode: %MODE%) ===
echo Using PowerShell: %PS_EXE%
echo.

REM ---- Auto-detect mode ----------------------------------------------------
if "%MODE%"=="auto" (
    if exist "%SCRIPT_DIR%\Git-Sync.psd1" (
        set "MODE=local"
    ) else (
        set "MODE=gallery"
    )
    echo [Install] Auto-detected mode: !MODE!
)

REM ---- Step 1: Set per-user execution policy -----------------------------
echo [Install] (1/3) Setting CurrentUser execution policy to RemoteSigned...
"%PS_EXE%" -NoProfile -Command ^
    "try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop; Write-Host '       OK' -ForegroundColor Green } catch { Write-Host ('       FAILED: ' + $_) -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
    echo.
    echo [Install] Could not set the execution policy.  This usually means the
    echo           policy is locked by Group Policy.  See Git-Sync-Elevated.bat
    echo           or run installation manually per INSTALLATION.md.
    echo.
    exit /b 1
)

REM ---- Step 2: Install / verify the module --------------------------------
if "%MODE%"=="local" (
    echo [Install] (2/3) Unblocking local files and validating manifest...
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
        "Get-ChildItem -LiteralPath '%SCRIPT_DIR%' -Recurse -Include *.ps1,*.psm1,*.psd1 | Unblock-File; Test-ModuleManifest -Path '%SCRIPT_DIR%\Git-Sync.psd1' | Out-Null; Write-Host '       OK' -ForegroundColor Green"
) else (
    echo [Install] (2/3) Installing Git-Sync from PowerShell Gallery (CurrentUser scope)...
    "%PS_EXE%" -NoProfile -Command ^
        "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module Git-Sync -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop; Write-Host '       OK' -ForegroundColor Green"
)
if errorlevel 1 (
    echo [Install] Module install failed.  Aborting.
    exit /b 1
)

REM ---- Step 3: Run the doctor ---------------------------------------------
echo [Install] (3/3) Running environment doctor...
echo.
if "%MODE%"=="local" (
    call "%SCRIPT_DIR%\Git-Sync-Doctor.bat"
) else (
    "%PS_EXE%" -NoProfile -Command "Import-Module Git-Sync -Force; (Test-GitSyncEnvironment).Ok"
)

echo.
echo [Install] Done.
if "%MODE%"=="local" (
    echo           Launch the tool with: Git-Sync.bat
) else (
    echo           Launch the tool with: pwsh -c "Import-Module Git-Sync; Invoke-GitDeploy -WhatIf"
)
echo.
exit /b 0
