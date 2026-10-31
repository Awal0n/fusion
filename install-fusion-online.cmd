@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Configuration copied from install-fusion-online.ps1
set "INSTALLER_URL=https://github.com/fusioninventory/fusioninventory-agent/releases/download/2.6/fusioninventory-agent_windows-x64_2.6.exe"
set "SERVER_URL=https://glpi2.loadrom.ru:33336/plugins/fusioninventory/"
set "INSTALLER_NAME=fusioninventory-agent_windows-x64_2.6.exe"
set "INSTALL_DIR=%TEMP%\FusionInventoryInstall"
set "INSTALLER_PATH=%INSTALL_DIR%\%INSTALLER_NAME%"
set "COMPUTER_NAME=%COMPUTERNAME%"
set "ROOT_TAG="

rem Request elevation, matching the PowerShell script's administrator requirement.
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 goto :elevate

echo.
echo ============================================
echo  FusionInventory Agent 2.6
echo ============================================
echo.
echo Computer: %COMPUTER_NAME%
echo.
echo Select company or enter a tag:
echo.
echo 0 - Enter tag manually
echo 1 - drHug
echo 2 - monblan
echo 3 - geo
echo 4 - fs
echo 5 - amvet
echo 6 - vivet
echo.
choice /c 0123456 /n /m "Enter number: "
if errorlevel 7 goto :company_vivet
if errorlevel 6 goto :company_amvet
if errorlevel 5 goto :company_fs
if errorlevel 4 goto :company_geo
if errorlevel 3 goto :company_monblan
if errorlevel 2 goto :company_drHug
if errorlevel 1 goto :manual_tag
goto :invalid_selection

:company_drHug
set "ROOT_TAG=drHug_"
goto :company_selected

:company_monblan
set "ROOT_TAG=monblan_"
goto :company_selected

:company_geo
set "ROOT_TAG=geo_"
goto :company_selected

:company_fs
set "ROOT_TAG=fs_"
goto :company_selected

:company_amvet
set "ROOT_TAG=amvet_"
goto :company_selected

:company_vivet
set "ROOT_TAG=vivet_"
goto :company_selected

:company_selected
set "TAG=%ROOT_TAG%%COMPUTER_NAME%"
goto :tag_selected

:manual_tag
set "TAG="
set /p "TAG=Enter full tag (letters, numbers, dot, underscore, hyphen): "
if not defined TAG goto :invalid_manual_tag
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "if ($env:TAG -cmatch '^[A-Za-z0-9._-]{1,128}$') { exit 0 } else { exit 1 }"
if errorlevel 1 goto :invalid_manual_tag

:tag_selected
echo.
echo Tag: %TAG%
echo.
choice /c YN /n /m "Continue? [Y/N] "
if errorlevel 2 goto :cancelled
if errorlevel 1 goto :download
goto :cancelled

:download
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%" goto :download_failed

echo.
echo Downloading FusionInventory Agent...
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri $env:INSTALLER_URL -OutFile $env:INSTALLER_PATH -UseBasicParsing; if (-not (Test-Path $env:INSTALLER_PATH)) { throw 'Installer download failed.' }; exit 0 } catch { Write-Error $_; exit 1 }"
if errorlevel 1 goto :download_failed
if not exist "%INSTALLER_PATH%" goto :download_failed

echo Download complete.
echo.
echo Installing FusionInventory Agent...
echo.

rem Keep /server unquoted: FusionInventory Agent 2.6 misparses a quoted server URL.
start "" /wait "%INSTALLER_PATH%" /S /acceptlicense /server=%SERVER_URL% /tag=%TAG%
set "INSTALLER_EXIT=%ERRORLEVEL%"

del /q "%INSTALLER_PATH%" >nul 2>&1
echo.
echo Installer exit code: %INSTALLER_EXIT%
echo.

if "%INSTALLER_EXIT%"=="0" (
    echo FusionInventory Agent installed successfully.
    echo Computer: %COMPUTER_NAME%
    echo Tag:      %TAG%
) else (
    echo Installation failed.
    echo Exit code: %INSTALLER_EXIT%
)

echo.
pause
exit /b %INSTALLER_EXIT%

:elevate
echo Requesting administrator privileges...
set "SCRIPT_PATH=%~f0"
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { Start-Process -FilePath $env:ComSpec -Verb RunAs -ArgumentList ('/c ""' + $env:SCRIPT_PATH + '""') } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
    echo Could not request administrator privileges.
    pause
    exit /b 1
)
exit /b 0

:invalid_selection
echo.
echo Invalid selection.
pause
exit /b 1

:invalid_manual_tag
echo.
echo Invalid tag. Use 1-128 letters, numbers, dot, underscore, or hyphen.
pause
exit /b 1

:cancelled
echo Cancelled.
exit /b 0

:download_failed
echo.
echo Installer download failed.
if exist "%INSTALLER_PATH%" del /q "%INSTALLER_PATH%" >nul 2>&1
pause
exit /b 1
