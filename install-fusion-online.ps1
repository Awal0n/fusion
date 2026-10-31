#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIG
# ============================================================

$ScriptUrl = "https://glpi2.loadrom.ru/install-fusion-online.ps1"
$InstallerUrl = "https://glpi2.loadrom.ru/downloads/fusioninventory-agent_windows-x64_2.6.exe"
$ServerUrl = "https://glpi2.loadrom.ru:33336/plugins/fusioninventory/"

# ============================================================
# UAC
# ============================================================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "Requesting administrator privileges..."

    $Command = "irm '$ScriptUrl' | iex"

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList @(
            "-NoProfile"
            "-ExecutionPolicy", "Bypass"
            "-Command", $Command
        )

    exit
}

# ============================================================
# TLS
# ============================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ============================================================
# COMPUTER / COMPANY
# ============================================================

$ComputerName = $env:COMPUTERNAME

Write-Host ""
Write-Host "============================================"
Write-Host " FusionInventory Agent 2.6"
Write-Host "============================================"
Write-Host ""
Write-Host "Computer: $ComputerName"
Write-Host ""
Write-Host "Select company:"
Write-Host ""
Write-Host "1 - drHug"
Write-Host "2 - monblan"
Write-Host "3 - geo"
Write-Host "4 - fs"
Write-Host "5 - amvet"
Write-Host ""

$Choice = Read-Host "Enter number"

switch ($Choice) {
    "1" { $RootTag = "drHug_" }
    "2" { $RootTag = "monblan_" }
    "3" { $RootTag = "geo_" }
    "4" { $RootTag = "fs_" }
    "5" { $RootTag = "amvet_" }
    default {
        Write-Host ""
        Write-Host "Invalid selection."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

$Tag = $RootTag + $ComputerName

Write-Host ""
Write-Host "Tag: $Tag"
Write-Host ""
$Confirm = Read-Host "Continue? [Y/N]"

if ($Confirm -notmatch "^[Yy]$") {
    Write-Host "Cancelled."
    exit 0
}

# ============================================================
# DOWNLOAD
# ============================================================

$TempDir = Join-Path $env:TEMP "FusionInventoryInstall"
$InstallerPath = Join-Path $TempDir "fusioninventory-agent_windows-x64_2.6.exe"

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

Write-Host ""
Write-Host "Downloading FusionInventory Agent..."

Invoke-WebRequest `
    -Uri $InstallerUrl `
    -OutFile $InstallerPath `
    -UseBasicParsing

if (-not (Test-Path $InstallerPath)) {
    throw "Installer download failed."
}

Write-Host "Download complete."
Write-Host ""

# ============================================================
# INSTALL
# ============================================================

Write-Host "Installing FusionInventory Agent..."
Write-Host ""

# IMPORTANT:
# Do NOT quote ServerUrl.
# FusionInventory 2.6 parses /server= incorrectly
# when PowerShell passes the quoted URL.

$Arguments = "/S /acceptlicense /server=$ServerUrl /tag=$Tag"

$Process = Start-Process `
    -FilePath $InstallerPath `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru

Write-Host ""
Write-Host "Installer exit code: $($Process.ExitCode)"

# ============================================================
# CLEANUP
# ============================================================

Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue

Write-Host ""

if ($Process.ExitCode -eq 0) {
    Write-Host "FusionInventory Agent installed successfully."
    Write-Host "Computer: $ComputerName"
    Write-Host "Tag:      $Tag"
}
else {
    Write-Host "Installation failed."
    Write-Host "Exit code: $($Process.ExitCode)"
}

Write-Host ""
Read-Host "Press Enter to exit"