@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

:main
cls
echo.
echo  ===========================================================================
echo     Git-Sync v2.6.0  -  Main Menu
echo  ===========================================================================
echo.
echo     1.  Run Environment Doctor       (check git, gh, PowerShell setup)
echo     2.  Run Installation / Setup     (unblock files, set execution policy)
echo     3.  Deploy Changes               (git add, commit, push to remote)
echo     4.  Create Release (auto-bump)   (bump version, tag, push, GitHub release)
echo     5.  Create Release (manual ver)  (specify version explicitly)
echo     6.  Switch GitHub Account        (switch gh auth between accounts)
echo     7.  Run Elevated (Admin mode)    (re-launch as Administrator via UAC)
echo     8.  Remove Repositories          (select repos to delete from GitHub)
echo.
echo     0.  Exit
echo.
set /p "choice=Enter your choice (0-8): "

if "%choice%"=="1" goto doctor
if "%choice%"=="2" goto install
if "%choice%"=="3" goto deploy
if "%choice%"=="4" goto release-auto
if "%choice%"=="5" goto release-manual
if "%choice%"=="6" goto switch-account
if "%choice%"=="7" goto elevated
if "%choice%"=="8" goto remove-repos
if "%choice%"=="0" exit /b 0

echo Invalid choice. Press any key to try again.
pause >nul
goto main

:doctor
cls
echo.
echo  === Environment Doctor ===
echo.
call "%SCRIPT_DIR%\Git-Sync-Doctor.bat"
echo.
pause
goto main

:install
cls
echo.
echo  === Installation / Setup ===
echo.
call "%SCRIPT_DIR%\Install.bat"
echo.
pause
goto main

:deploy
cls
echo.
echo  === Deploy Changes ===
echo.
echo  This will stage all changes, commit, and push to the remote.
echo.
set /p "msg=Commit message (leave blank for auto-timestamp): "
set /p "remote=Remote name (default: origin): "

if "%remote%"=="" set "remote=origin"
if "%msg%"=="" set "msg="

cls
echo.
echo  === Deploying to %remote% ===
echo.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; $m = '%SCRIPT_DIR%\Git-Sync.psd1'; Import-Module $m -Force; Invoke-GitDeploy -Remote '%remote%' -Message '%msg%' -WarningAction SilentlyContinue"
echo.
echo  Exit code: %ERRORLEVEL%
echo.
pause
goto main

:release-auto
cls
echo.
echo  === Create Release (Auto-Bump) ===
echo.
echo  Auto-detects the latest tag and bumps the version.
echo.
set /p "bump=Bump type (Patch/Minor/Major, default: Patch): "
set /p "remote=Remote name (default: origin): "
set /p "notes=Generate release notes (Y/N, default: N): "

if "%bump%"=="" set "bump=Patch"
if "%remote%"=="" set "remote=origin"
set "genNotes="
if /i "%notes%"=="Y" set "genNotes=-GenerateNotes"

cls
echo.
echo  === Creating release (%bump% bump) on %remote% ===
echo.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; Import-Module '%SCRIPT_DIR%\Git-Sync.psd1' -Force; New-GitRelease -Bump '%bump%' -Remote '%remote%' %genNotes%"
echo.
echo  Exit code: %ERRORLEVEL%
echo.
pause
goto main

:release-manual
cls
echo.
echo  === Create Release (Manual Version) ===
echo.
set /p "ver=Version number (e.g. 1.2.3): "
set /p "remote=Remote name (default: origin): "
set /p "force=Force overwrite existing tag (Y/N, default: N): "
set /p "notes=Generate release notes (Y/N, default: N): "

if "%remote%"=="" set "remote=origin"
set "forceFlag="
if /i "%force%"=="Y" set "forceFlag=-Force"
set "genNotes="
if /i "%notes%"=="Y" set "genNotes=-GenerateNotes"

cls
echo.
echo  === Creating release v%ver% on %remote% ===
echo.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; Import-Module '%SCRIPT_DIR%\Git-Sync.psd1' -Force; New-GitRelease -Version '%ver%' -Remote '%remote%' %forceFlag% %genNotes%"
echo.
echo  Exit code: %ERRORLEVEL%
echo.
pause
goto main

:switch-account
cls
echo.
echo  === Switch GitHub Account ===
echo.
set /p "account=Target GitHub username: "

if "%account%"=="" (
    echo  No account specified.
    pause
    goto main
)

cls
echo.
echo  === Switching to %account% ===
echo.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; Import-Module '%SCRIPT_DIR%\Git-Sync.psd1' -Force; Switch-GhAccount -TargetAccount '%account%'"
echo.
echo  Exit code: %ERRORLEVEL%
echo.
pause
goto main

:elevated
cls
echo.
echo  === Elevated Mode ===
echo.
call "%SCRIPT_DIR%\Git-Sync-Elevated.bat"
echo.
pause
goto main

:remove-repos
cls
echo.
echo  === Remove Repositories from GitHub ===
echo.
echo  WARNING: This permanently deletes repositories from GitHub.
echo  You will see a grid to select repos, then a confirmation prompt.
echo.
set /p "org=Organization/owner (default: LIN4CRE): "
set /p "dry=Dry-run first (Y/N, default: Y): "

if "%org%"=="" set "org=LIN4CRE"
set "dryFlag="
if /i "%dry%"=="N" ( set "dryFlag=" ) else ( set "dryFlag=-DryRun" )

cls
echo.
echo  === Fetching repos for '%org%' ===
echo.
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "& '%SCRIPT_DIR%\Remove-GitRepos.ps1' -Organization '%org%' %dryFlag%"
echo.
pause
goto main
