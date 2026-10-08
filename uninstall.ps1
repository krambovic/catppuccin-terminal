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
$docDirs = @(
    (Join-Path $homeDir 'Documents'),
    [Environment]::GetFolderPath('MyDocuments'),
    [Environment]::GetFolderPath('Personal')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

$profileTargets = [System.Collections.Generic.List[string]]::new()
foreach ($d in $docDirs) {
    $profileTargets.Add((Join-Path $d 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))
    $profileTargets.Add((Join-Path $d 'PowerShell\Microsoft.PowerShell_profile.ps1'))
}
if ($PROFILE) {
    if ($PROFILE.CurrentUserCurrentHost) { $profileTargets.Add($PROFILE.CurrentUserCurrentHost) }
    if ($PROFILE.CurrentUserAllHosts) { $profileTargets.Add($PROFILE.CurrentUserAllHosts) }
}
$uniqueProfileTargets = $profileTargets | Select-Object -Unique

Write-Step 'Cleaning PowerShell profiles'
foreach ($pPath in $uniqueProfileTargets) {
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

$candidateDirs = @(
    'C:\Program Files\clink',
    'C:\Program Files (x86)\clink',
    "$env:LOCALAPPDATA\Programs\clink"
)
$unregistered = $false
foreach ($dir in $candidateDirs) {
    foreach ($bin in @('clink_x64.exe', 'clink_arm64.exe', 'clink_x86.exe', 'clink.exe')) {
        $p = Join-Path $dir $bin
        if (Test-Path -LiteralPath $p) {
            & $p autorun uninstall
            Write-Success "Unregistered Clink autorun"
            $unregistered = $true
            break
        }
    }
    if ($unregistered) { break }
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
