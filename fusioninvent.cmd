@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem User settings
set "SETUP_VERSION=2.6"
set "SETUP_LOCATION=https://github.com/fusioninventory/fusioninventory-agent/releases/download/%SETUP_VERSION%"
set "SETUP_OPTIONS=/acceptlicense /runnow /server='https://glpi2.loadrom.ru:33336/plugins/fusioninventory/' /tag=tagDrhug_ /S"
set "FORCE=No"

rem Detect the operating system architecture, including 32-bit cmd.exe on 64-bit Windows.
set "OS_ARCH=%PROCESSOR_ARCHITEW6432%"
if not defined OS_ARCH set "OS_ARCH=%PROCESSOR_ARCHITECTURE%"
if /i "%OS_ARCH%"=="x86" (
    set "SYSTEM_ARCH=x86"
) else if /i "%OS_ARCH%"=="AMD64" (
    set "SYSTEM_ARCH=x64"
) else (
    echo The system architecture is unknown or not supported: %OS_ARCH%
    exit /b 1
)

set "SETUP_ARCH=%SYSTEM_ARCH%"
set "SETUP=fusioninventory-agent_windows-%SETUP_ARCH%_%SETUP_VERSION%.exe"
set "INSTALLER_PATH=%TEMP%\%SETUP%"
set "CURRENT_VERSION="

rem Check the installed version using the registry locations used by the VBS script.
if /i "%SYSTEM_ARCH%"=="x86" (
    call :read_version "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent"
    if not defined CURRENT_VERSION call :read_version "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent"
) else (
    call :read_version "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent"
    if not defined CURRENT_VERSION call :read_version "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent"
    if not defined CURRENT_VERSION call :read_version "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent"
)

if /i "%FORCE%"=="No" if "%CURRENT_VERSION%"=="%SETUP_VERSION%" (
    echo FusionInventory Agent %SETUP_VERSION% is already installed.
    exit /b 0
)

if defined CURRENT_VERSION (
    echo Installation needed: %CURRENT_VERSION% -^> %SETUP_VERSION%
) else (
    echo Installation needed: %SETUP_VERSION%
)

if /i "%SETUP_LOCATION:~0,4%"=="http" (
    echo Downloading: %SETUP_LOCATION%/%SETUP%
    call :download_installer
    if errorlevel 1 (
        echo Error downloading the installer.
        exit /b 2
    )
) else (
    echo Copying: %SETUP_LOCATION%\%SETUP% to %INSTALLER_PATH%
    copy /Y "%SETUP_LOCATION%\%SETUP%" "%INSTALLER_PATH%" >nul
    if errorlevel 1 (
        echo Error copying the installer.
        exit /b 3
    )
)

echo Running: "%INSTALLER_PATH%" %SETUP_OPTIONS%
start "" /wait "%INSTALLER_PATH%" %SETUP_OPTIONS%
set "INSTALLER_EXIT=%ERRORLEVEL%"
del /q "%INSTALLER_PATH%" >nul 2>&1

if not "%INSTALLER_EXIT%"=="0" (
    echo Installer failed with exit code %INSTALLER_EXIT%.
    exit /b %INSTALLER_EXIT%
)

echo Deployment done!
exit /b 0

:read_version
for /f "tokens=2,*" %%A in ('reg query "%~1" /v DisplayVersion 2^>nul ^| findstr /i "DisplayVersion"') do set "CURRENT_VERSION=%%B"
exit /b 0

:download_installer
set "FUSION_URL=%SETUP_LOCATION%/%SETUP%"
set "FUSION_INSTALLER=%INSTALLER_PATH%"
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile($env:FUSION_URL, $env:FUSION_INSTALLER); exit 0 } catch { Write-Error $_; exit 1 }"
exit /b %ERRORLEVEL%
