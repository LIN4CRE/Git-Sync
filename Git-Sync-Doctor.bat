@echo off
REM ==========================================================================
REM  Git-Sync-Doctor.bat
REM  --------------------------------------------------------------------------
REM  Read-only diagnostic. Prints a pass/fail report for:
REM     - PowerShell version
REM     - Execution policy (Process/CurrentUser/LocalMachine)
REM     - git CLI present & versioned
REM     - gh CLI present & authenticated (optional)
REM     - Git-Sync module manifest validity
REM     - Zone.Identifier blocks on any .ps1/.psm1/.psd1
REM
REM  Exit codes:
REM     0  all checks passed (warnings allowed)
REM     1  at least one Fail
REM     2  doctor itself could not run (no PowerShell, missing files)
REM ==========================================================================

setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "DOCTOR=%SCRIPT_DIR%\Test-Environment.ps1"
if not exist "%DOCTOR%" (
    echo.
    echo [Doctor] ERROR: Test-Environment.ps1 not found at "%DOCTOR%".
    echo.
    pause
    exit /b 2
)

set "PS_EXE="
where pwsh >nul 2>&1 && set "PS_EXE=pwsh"
if not defined PS_EXE (
    where powershell >nul 2>&1 && set "PS_EXE=powershell"
)
if not defined PS_EXE (
    echo.
    echo [Doctor] ERROR: Neither pwsh nor powershell.exe is on PATH.
    echo          Install PowerShell 7 from https://aka.ms/powershell
    echo.
    pause
    exit /b 2
)

REM Unblock the doctor script itself (best-effort, silent)
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { Unblock-File -LiteralPath '%DOCTOR%' -ErrorAction SilentlyContinue } catch {}"

REM Run the doctor; it returns 0/1/2 to us.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%DOCTOR%"
set "RC=%ERRORLEVEL%"

if "%RC%"=="0" (
    echo.
    echo [Doctor] All checks passed.  You can now run Git-Sync.bat
    echo.
) else if "%RC%"=="1" (
    echo.
    echo [Doctor] One or more checks FAILED.  See the table above for fixes.
    echo          See INSTALLATION.md and TROUBLESHOOTING.md for more help.
    echo.
) else (
    echo.
    echo [Doctor] Could not complete the environment check (exit %RC%).
    echo.
)
echo.
pause
exit /b %RC%
