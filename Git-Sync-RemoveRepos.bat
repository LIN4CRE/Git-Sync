@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "TARGET=%SCRIPT_DIR%\Remove-GitRepos.ps1"
if not exist "%TARGET%" (
    echo.
    echo [Git-Sync] ERROR: Remove-GitRepos.ps1 not found.
    echo            Expected at: "%TARGET%"
    echo.
    pause
    exit /b 3
)

set "PS_EXE="
where pwsh >nul 2>&1 && set "PS_EXE=pwsh"
if not defined PS_EXE (
    where powershell >nul 2>&1 && set "PS_EXE=powershell"
)
if not defined PS_EXE (
    echo.
    echo [Git-Sync] ERROR: PowerShell not found. Install from https://aka.ms/powershell
    echo.
    pause
    exit /b 2
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%TARGET%" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
