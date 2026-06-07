@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PS_EXE="
where pwsh >nul 2>&1 && set "PS_EXE=pwsh"
if not defined PS_EXE (
    where powershell >nul 2>&1 && set "PS_EXE=powershell"
)
if not defined PS_EXE (
    echo [Setup] ERROR: PowerShell not found.
    pause
    exit /b 1
)

echo.
echo  ===========================================================================
echo     Git-Sync - Desktop Shortcut Setup
echo  ===========================================================================
echo.
echo  This will create a desktop shortcut for Git-Sync-Menu.bat with a custom
echo  icon so you can just double-click it to launch the menu.
echo.

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "$s = New-Object -ComObject WScript.Shell; $f = [Environment]::GetFolderPath('Desktop'); $lnk = $s.CreateShortcut([IO.Path]::Combine($f, 'Git-Sync.lnk')); $lnk.TargetPath = '%SCRIPT_DIR%\Git-Sync-Menu.bat'; $lnk.WorkingDirectory = '%SCRIPT_DIR%'; $lnk.Description = 'Git-Sync v2.6.0 — Deploy, release, manage repos'; $lnk.IconLocation = '%SystemRoot%\System32\imageres.dll, 50'; $lnk.Save(); Write-Host '   [OK] Shortcut created on your desktop.' -ForegroundColor Green"

if errorlevel 1 (
    echo [Setup] Failed to create shortcut.
    pause
    exit /b 1
)

echo.
echo  Done. Look for "Git-Sync" on your desktop.
echo  (Icon: imageres.dll,50 — folder with gear)
echo.
pause
