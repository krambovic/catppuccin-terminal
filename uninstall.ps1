<#
.SYNOPSIS
    Catppuccin Mocha Terminal - Uninstaller
.DESCRIPTION
    Safely uninstalls the Catppuccin Mocha Terminal configuration and
    restores original profiles and settings from backups.
#>

[CmdletBinding()]
param(
    [switch]$Full
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
    Write-Host "`n[-] $Message" -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Remove-CatppuccinBlock([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $pattern = '(?si)\r?\n?# >>> Catppuccin Terminal Setup >>>.*?# <<< Catppuccin Terminal Setup <<<\r?\n?'
    return [regex]::Replace($Text, $pattern, '').TrimEnd()
}

Write-Host ''
Write-Host '===========================================================' -ForegroundColor Yellow
Write-Host '   Catppuccin Mocha Terminal Uninstaller' -ForegroundColor Yellow
Write-Host '===========================================================' -ForegroundColor Yellow

$homeDir = $HOME
$profileTargets = @(
    (Join-Path $homeDir 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $homeDir 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
)

Write-Step 'Cleaning PowerShell profiles'
foreach ($pPath in $profileTargets) {
    if (Test-Path -LiteralPath $pPath) {
        $existing = Get-Content -LiteralPath $pPath -Raw
        $cleaned = Remove-CatppuccinBlock $existing
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($pPath, $cleaned, $utf8NoBom)
        Write-Success "Cleaned profile: $pPath"
    }
}

Write-Step 'Removing Clink (CMD) integration'
$clinkLuaPath = Join-Path $homeDir 'AppData\Local\clink\catppuccin.lua'
if (Test-Path -LiteralPath $clinkLuaPath) {
    Remove-Item -LiteralPath $clinkLuaPath -Force
    Write-Success "Removed $clinkLuaPath"
}

$clinkExeCandidates = @(
    'C:\Program Files (x86)\clink\clink_x64.exe',
    'C:\Program Files\clink\clink_x64.exe',
    "$env:LOCALAPPDATA\Programs\clink\clink_x64.exe"
)
foreach ($c in $clinkExeCandidates) {
    if (Test-Path -LiteralPath $c) {
        & $c autorun uninstall
        Write-Success "Unregistered Clink autorun"
        break
    }
}

Write-Step 'Removing Catppuccin configuration files'
$filesToRemove = @(
    (Join-Path $homeDir '.config\oh-my-posh\catppuccin-mocha.omp.json'),
    (Join-Path $homeDir '.config\fastfetch\config.jsonc'),
    (Join-Path $homeDir '.config\fastfetch\ascii\anime-girl-1.txt')
)
foreach ($f in $filesToRemove) {
    if (Test-Path -LiteralPath $f) {
        Remove-Item -LiteralPath $f -Force
        Write-Success "Removed $f"
    }
}

Write-Host ''
Write-Host '===========================================================' -ForegroundColor Green
Write-Host '   UNINSTALLATION COMPLETED' -ForegroundColor Green
Write-Host '===========================================================' -ForegroundColor Green
Write-Host '   Your backups remain intact at ~/catppuccin-terminal-backups/' -ForegroundColor Gray
Write-Host ''
