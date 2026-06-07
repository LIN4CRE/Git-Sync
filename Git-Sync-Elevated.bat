@echo off
REM ==========================================================================
REM  Git-Sync-Elevated.bat
REM  --------------------------------------------------------------------------
REM  Self-elevating launcher for environments where the user cannot change
REM  execution policy in CurrentUser scope (e.g. group-policy-locked machines).
REM  Triggers a UAC prompt and re-launches itself as Administrator, then runs
REM  Git-Sync.bat with whatever arguments you passed.
REM
REM  Usage is identical to Git-Sync.bat; arguments are forwarded.
REM ==========================================================================

setlocal EnableExtensions

REM ---- Check current elevation --------------------------------------------
net session >nul 2>&1
if %errorlevel%==0 (
    REM Already elevated; just chain to Git-Sync.bat.
    set "SCRIPT_DIR=%~dp0"
    if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
    call "%SCRIPT_DIR%\Git-Sync.bat" %*
    exit /b %ERRORLEVEL%
)

echo.
echo [Git-Sync] This launcher needs Administrator rights to bypass a locked
echo            execution policy.  You will see a UAC prompt.
echo.

REM ---- Build a re-launch command and request elevation ---------------------
set "ARGS=%*"
set "ARGS=%ARGS:"=\""%"
powershell -NoProfile -Command ^
    "Start-Process -FilePath '%~f0' -ArgumentList '%ARGS%' -Verb RunAs"

echo.
pause
exit /b 0
