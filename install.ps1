<#
.SYNOPSIS
    Catppuccin Mocha Terminal - The Ultimate Windows Terminal Rice Setup
.DESCRIPTION
    One-shot automated installer for Windows Terminal, Windows PowerShell 5.1,
    PowerShell 7 (pwsh), and Command Prompt (cmd.exe).
    Configures Fastfetch (with compact anime art), Oh My Posh (Catppuccin Mocha),
    Clink (with matching PowerShell syntax styling and zero distractions),
    and JetBrains Mono Nerd Font.
.NOTES
    Author: krambovic
    Repository: https://github.com/krambovic/catppuccin-terminal
    License: MIT
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipFont
)

$ErrorActionPreference = 'Stop'

# Ensure UTF-8 output in current process
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
if (Get-Command chcp.com -ErrorAction SilentlyContinue) {
    chcp.com 65001 > $null
}

function Write-Step([string]$Message) {
    Write-Host "`n[+] $Message" -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-WarningMsg([string]$Message) {
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Write-Failure([string]$Message) {
    Write-Host "`n[ERROR] $Message" -ForegroundColor Red
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Backup-File([string]$Path, [string]$BackupDir) {
    if (Test-Path -LiteralPath $Path) {
        $name = [System.IO.Path]::GetFileName($Path)
        Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupDir $name) -Force
    }
}

function Refresh-PathEnvironment {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $appApps = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    $extra = @(
        'C:\Program Files\Git\cmd',
        'C:\Program Files (x86)\clink',
        'C:\Program Files\clink',
        "$env:LOCALAPPDATA\Programs\clink",
        $appApps
    ) | Where-Object { Test-Path -LiteralPath $_ }

    $combined = ($machinePath, $userPath, ($extra -join ';')) -join ';'
    $env:Path = ($combined -split ';' | Select-Object -Unique | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ';'
}

function Find-Winget {
    Refresh-PathEnvironment
    $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        return $wingetCmd.Source
    }

    $candidates = @(
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe",
        "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
    )
    foreach ($pattern in $candidates) {
        $match = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($match) {
            $parent = Split-Path -Parent $match.FullName
            $env:Path = "$parent;$env:Path"
            return $match.FullName
        }
    }
    return $null
}

function Install-WingetPackage([string]$WingetPath, [string]$Id) {
    Write-Host "    Installing/verifying $Id..." -ForegroundColor Gray
    & $WingetPath install --id $Id --source winget --exact --accept-package-agreements --accept-source-agreements --silent
    $validExitCodes = @(0, -1978335189, -1978335212, 2316632065, -1978335215)
    if ($LASTEXITCODE -notin $validExitCodes) {
        Write-WarningMsg "winget returned exit code $LASTEXITCODE for $Id (package may already be present or requires manual confirmation)."
    } else {
        Write-Success "$Id is ready"
    }
}

function Find-ClinkExe {
    Refresh-PathEnvironment
    $cmds = @('clink_x64.exe', 'clink_arm64.exe', 'clink_x86.exe', 'clink.exe')
    foreach ($name in $cmds) {
        $c = Get-Command $name -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
    }

    $candidateDirs = @(
        'C:\Program Files\clink',
        'C:\Program Files (x86)\clink',
        "$env:LOCALAPPDATA\Programs\clink"
    )
    foreach ($dir in $candidateDirs) {
        foreach ($bin in @('clink_x64.exe', 'clink_arm64.exe', 'clink_x86.exe', 'clink.exe')) {
            $p = Join-Path $dir $bin
            if (Test-Path -LiteralPath $p) { return $p }
        }
    }
    return $null
}

function Remove-CatppuccinBlock([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $pattern = '(?si)\r?\n?# >>> Catppuccin Terminal Setup >>>.*?# <<< Catppuccin Terminal Setup <<<\r?\n?'
    return [regex]::Replace($Text, $pattern, '').TrimEnd()
}

# ----------------- MAIN EXECUTION -----------------
try {
    Write-Host ''
    Write-Host '===========================================================' -ForegroundColor Magenta
    Write-Host '   Catppuccin Mocha Terminal Setup' -ForegroundColor Magenta
    Write-Host '   Fastfetch + Oh My Posh + Clink + Windows Terminal' -ForegroundColor Magenta
    Write-Host '===========================================================' -ForegroundColor Magenta

    # 1. Self-set ExecutionPolicy for CurrentUser
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
        Write-Success 'PowerShell ExecutionPolicy set to Bypass for CurrentUser'
    }
    catch {
        Write-WarningMsg "Could not set ExecutionPolicy: $($_.Exception.Message)"
    }

    $homeDir = $HOME
    $configRoot = Join-Path $homeDir '.config'
    $fastfetchDir = Join-Path $configRoot 'fastfetch'
    $ompDir = Join-Path $configRoot 'oh-my-posh'
    $asciiDir = Join-Path $fastfetchDir 'ascii'
    $clinkDir = Join-Path $homeDir 'AppData\Local\clink'
    $backupRoot = Join-Path $homeDir 'catppuccin-terminal-backups'
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path $backupRoot $stamp

    New-Item -ItemType Directory -Path $fastfetchDir, $ompDir, $asciiDir, $clinkDir, $backupDir -Force | Out-Null

    # 2. Check Package Manager (winget)
    Write-Step 'Resolving package manager (winget)'
    $wingetExe = Find-Winget
    if (-not $wingetExe) {
        Write-Failure "winget.exe was not found. Please install App Installer from Microsoft Store or GitHub, then rerun this script."
        throw "winget.exe not found"
    }
    Write-Success "Found winget at $wingetExe"

    # 3. Install core dependencies
    Write-Step 'Installing core dependencies'
    Install-WingetPackage $wingetExe 'Fastfetch-cli.Fastfetch'
    Install-WingetPackage $wingetExe 'JanDeDobbeleer.OhMyPosh'
    Install-WingetPackage $wingetExe 'chrisant996.Clink'
    if (-not $SkipFont) {
        Install-WingetPackage $wingetExe 'DEVCOM.JetBrainsMonoNerdFont'
    }

    Refresh-PathEnvironment

    # 4. Install Anime ASCII Art
    Write-Step 'Installing Catppuccin Anime Girl ASCII Art'
    $artBase64 = 'JDjioYbio5DiopXiopXiopXiopXiopXiopXiopXiopXioIXiopfiopXiopXiopXiopXiopXiopXiopXioJXioJXiopXiopXiopXiopXiopXiopXiopXiopXiopUK4qKQ4qKV4qKV4qKV4qKV4qKV4qOV4qKV4qKV4qCV4qCB4qKV4qKV4qKV4qKV4qKV4qKV4qKV4qKV4qCFJDPioYQkOOKileKileKileKileKileKileKileKileKilQriopXiopXiopXiopXiopXioIXiopfiopXioJUkM+KjoOKghCQ44qOX4qKV4qKV4qCV4qKV4qKV4qKV4qCVJDPioqDio78kOOKgkOKileKileKileKgkeKileKileKgteKilQriopXiopXiopXiopXioIHiopzioJUkM+KigeKjtOKjv+KhhyQ44qKT4qKV4qK14qKQ4qKV4qKV4qCVJDPiooHio77ior/io6ckOOKgkeKileKileKghOKikeKileKgheKilQriopXiopXioLXiooHioJQkM+KigeKjpOKjpOKjtuKjtuKjtiQ44qGQ4qOV4qK94qCQ4qKV4qCVJDPio6Hio77io7bio7bio7bio6QkOOKhgeKik+KileKghOKikeKiheKikQrioI3io6fioIQkM+KjtuKjvuKjv+Kjv+Kjv+Kjv+Kjv+Kjv+KjtyQ44qOU4qKV4qKEJDPioqHio77io7/io7/io7/io7/io7/io7/io7/io6YkOOKhkeKileKipOKgseKikArioqDiopXioIUkM+KjvuKjv+Kgi+Kiv+Kjv+Kjv+Kjv+KgieKjv+Kjv+Kjt+KjpuKjtuKjveKjv+Kjv+KgiOKjv+Kjv+Kjv+Kjv+Kgj+KiueKjt+Kjt+KhhSQ44qKQCuKjlOKileKipSQz4qK74qO/4qGA4qCI4qCb4qCb4qCB4qKg4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qGA4qCI4qCb4qCb4qCB4qCE4qO84qO/4qO/4qGHJDjiopQK4qKV4qKV4qK94qK4JDPiop8kNOKin+KiluKiluKipCQz4qO24qGf4qK74qO/4qG/4qC74qO/4qO/4qGf4qKA4qO/JDTio6bioqTioqTiopTiop7ior8kM+Kiv+Kjv+KggSQ44qKVCuKileKileKghSQ04qOQ4qKV4qKV4qKV4qKV4qKVJDPio7/io7/ioYTioJviooDio6bioIjioJviooHio7zio78kNOKil+KileKileKileKileKileKilSQ44qGP4qOY4qKVCuKileKileKghSQ04qKT4qOV4qOV4qOV4qOVJDPio7Xio7/io7/io7/io77io7/io7/io7/io7/io7/io7/io7/io7ckNOKjleKileKileKileKileKhtSQ44qKA4qKV4qKVCuKikeKileKgg+KhiCQz4qK/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/4qO/JDjiooPiopXiopXiopUK4qOG4qKV4qCE4qKx4qOEJDPioJvior/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/io7/ioL8kOOKigeKileKileKgleKigQrio7/io6bioYDio7/io7/io7fio7bio6zio40kM+Kjm+Kjm+Kjm+Khm+Kgv+Kgv+Kgv+Kgm+Kgm+Kim+KjmyQ44qOJ4qOt4qOk4qOC4qKc4qCV4qKR4qOh4qO04qO/'
    $artFile = Join-Path $asciiDir 'anime-girl-1.txt'
    # Clean old extra arts if any
    Get-ChildItem -Path $asciiDir -Filter "*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force
    $artBytes = [System.Convert]::FromBase64String($artBase64)
    [System.IO.File]::WriteAllBytes($artFile, $artBytes)
    Write-Success 'Anime ASCII art installed'

    # 5. Fastfetch Configuration
    Write-Step 'Configuring Fastfetch'
    $fastfetchConfigPath = Join-Path $fastfetchDir 'config.jsonc'
    Backup-File $fastfetchConfigPath $backupDir

    $artPathEscaped = $artFile.Replace('\', '/')
    $fastfetchJson = @"
{
  "`$schema": "https://github.com/fastfetch-cli/fastfetch/wiki/Configuration",
  "logo": {
    "type": "file",
    "source": "$artPathEscaped",
    "color": {
      "1": "#F5E0DC",
      "2": "#F2CDCD",
      "3": "#F5C2E7",
      "4": "#FAB387",
      "5": "#F9E2AF",
      "6": "#A6E3A1",
      "7": "#94E2D5",
      "8": "#89DCEB",
      "9": "#74C7EC"
    },
    "padding": {
      "top": 1,
      "right": 3
    }
  },
  "display": {
    "separator": "  \u276f  ",
    "color": {
      "title": "#F5C2E7",
      "output": "#CDD6F4",
      "separator": "#6C7086"
    }
  },
  "modules": [
    "break",
    {
      "type": "title",
      "color": {
        "user": "#F5C2E7",
        "at": "#CDD6F4",
        "host": "#89DCEB"
      }
    },
    {
      "type": "separator",
      "string": "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
    },
    {
      "type": "os",
      "key": "\ue70f OS",
      "keyColor": "#89DCEB"
    },
    {
      "type": "kernel",
      "key": "\uf013 Kernel",
      "keyColor": "#B4BEFE"
    },
    {
      "type": "uptime",
      "key": "\udb80\udd50 Uptime",
      "keyColor": "#F9E2AF"
    },
    {
      "type": "shell",
      "key": "\uf489 Shell",
      "keyColor": "#CBA6F7"
    },
    {
      "type": "terminal",
      "key": "\ue795 Terminal",
      "keyColor": "#F5C2E7"
    },
    {
      "type": "cpu",
      "key": "\uf4bc CPU",
      "keyColor": "#FAB387"
    },
    {
      "type": "gpu",
      "key": "\udb81\udcae GPU",
      "keyColor": "#F38BA8"
    },
    {
      "type": "memory",
      "key": "\uefc5 Memory",
      "keyColor": "#A6E3A1"
    },
    {
      "type": "disk",
      "key": "\udb80\udcca Disk",
      "keyColor": "#94E2D5"
    },
    {
      "type": "wm",
      "key": "\uf488 WM",
      "keyColor": "#74C7EC"
    },
    "break",
    {
      "type": "colors",
      "symbol": "circle"
    }
  ]
}
"@
    Write-Utf8NoBom $fastfetchConfigPath $fastfetchJson
    Write-Success 'Fastfetch config saved'

    # 6. Oh My Posh Theme (Catppuccin Mocha)
    Write-Step 'Configuring Oh My Posh theme'
    $ompConfigPath = Join-Path $ompDir 'catppuccin-mocha.omp.json'
    Backup-File $ompConfigPath $backupDir

    $ompJson = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 4,
  "final_space": true,
  "palette": {
    "crust": "#11111b",
    "mantle": "#181825",
    "base": "#1e1e2e",
    "surface0": "#313244",
    "surface1": "#45475a",
    "text": "#cdd6f4",
    "subtext0": "#a6adc8",
    "pink": "#f5c2e7",
    "mauve": "#cba6f7",
    "red": "#f38ba8",
    "peach": "#fab387",
    "yellow": "#f9e2af",
    "green": "#a6e3a1",
    "teal": "#94e2d5",
    "sapphire": "#74c7ec",
    "blue": "#89b4fa",
    "lavender": "#b4befe"
  },
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "os",
          "style": "diamond",
          "leading_diamond": "\ue0b6",
          "trailing_diamond": "\ue0b4 ",
          "background": "p:mauve",
          "foreground": "p:crust",
          "template": " {{ .Icon }} {{ .UserName }} "
        },
        {
          "type": "path",
          "style": "diamond",
          "leading_diamond": "\ue0b6",
          "trailing_diamond": "\ue0b4 ",
          "background": "p:sapphire",
          "foreground": "p:crust",
          "options": {
            "style": "agnoster_short",
            "home_icon": "~"
          },
          "template": " \udb80\udc4b {{ .Path }} "
        },
        {
          "type": "git",
          "style": "diamond",
          "leading_diamond": "\ue0b6",
          "trailing_diamond": "\ue0b4 ",
          "background": "p:green",
          "foreground": "p:crust",
          "options": {
            "branch_icon": "\udb80\udea2 ",
            "fetch_status": true
          },
          "template": " \udb80\udea2 {{ .HEAD }}{{ if .Working.Changed }} \udb81\udc4c{{ end }}{{ if .Staging.Changed }} \udb80\ude1e{{ end }} "
        },
        {
          "type": "status",
          "style": "diamond",
          "leading_diamond": "\ue0b6",
          "trailing_diamond": "\ue0b4 ",
          "background": "p:red",
          "foreground": "p:crust",
          "template": " \udb80\udd59 {{ .Code }} "
        },
        {
          "type": "text",
          "style": "plain",
          "foreground": "p:mauve",
          "template": "\u276f "
        }
      ]
    }
  ]
}
'@
    Write-Utf8NoBom $ompConfigPath $ompJson
    Write-Success 'Oh My Posh theme saved'

    # 7. Clink (CMD Integration)
    Write-Step 'Configuring Clink for Command Prompt (cmd.exe)'
    $clinkLuaPath = Join-Path $clinkDir 'catppuccin.lua'
    $clinkLua = @'
-- Catppuccin Terminal setup for Clink (CMD)
os.execute("@chcp 65001 >nul")
local home = os.getenv("USERPROFILE") or ""
local ompConfig = home .. "\\.config\\oh-my-posh\\catppuccin-mocha.omp.json"

-- Fastfetch banner on startup (for interactive CMD sessions)
local fastfetch_shown = false
if clink and clink.onbeginedit then
    clink.onbeginedit(function()
        if not fastfetch_shown and not os.getenv("CATPPUCCIN_CMD_FASTFETCH_SHOWN") then
            fastfetch_shown = true
            os.setenv("CATPPUCCIN_CMD_FASTFETCH_SHOWN", "1")
            os.execute("cls && fastfetch && echo.")
        end
    end)
end

-- Initialize Oh My Posh prompt
local cmd = 'oh-my-posh init cmd --config "' .. ompConfig .. '"'
local handle = io.popen(cmd)
if handle then
    local res = handle:read("*a")
    handle:close()
    if res and #res > 0 then
        load(res)()
    end
end
'@
    Write-Utf8NoBom $clinkLuaPath $clinkLua
    Write-Success 'Clink Lua script saved'

    $clinkExe = Find-ClinkExe
    if ($clinkExe) {
        & $clinkExe autorun install
        # Align Clink syntax colors with PowerShell PSReadLine
        & $clinkExe set clink.colorize_input True
        & $clinkExe set color.cmd "sgr 93"
        & $clinkExe set color.executable "sgr 93"
        & $clinkExe set color.doskey "sgr 93"
        & $clinkExe set color.unrecognized "sgr 93"
        & $clinkExe set color.arg "default"
        & $clinkExe set color.flag "sgr 90"
        & $clinkExe set color.input "default"
        & $clinkExe set color.cmdredir "default"
        & $clinkExe set color.cmdsep "default"
        & $clinkExe set color.arginfo "default"
        # Disable all annoying popups & hints
        & $clinkExe set autosuggest.enable False
        & $clinkExe set autosuggest.hint False
        & $clinkExe set argmatcher.show_hints False
        & $clinkExe set clink.logo none
        Write-Success "Clink AutoRun registered and configured at $clinkExe"
    } else {
        Write-WarningMsg 'clink_x64.exe was not found immediately in path. It will activate once terminal restarts.'
    }

    # 8. Configure PowerShell Profiles (5.1 Desktop and 7+ Core, including OneDrive)
    Write-Step 'Configuring PowerShell profiles'
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

    $profileBlock = @'
# >>> Catppuccin Terminal Setup >>>
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

$ompConfig = Join-Path $HOME '.config\oh-my-posh\catppuccin-mocha.omp.json'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompShell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
    oh-my-posh init $ompShell --config $ompConfig | Invoke-Expression
}

$isNonInteractive = ([System.Environment]::GetCommandLineArgs() | Where-Object { $_ -match '^-(c|command|f|file|encodedcommand)' })
if (-not $isNonInteractive -and -not $env:CATPPUCCIN_FASTFETCH_SHOWN) {
    $env:CATPPUCCIN_FASTFETCH_SHOWN = '1'
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        Clear-Host
        fastfetch
        Write-Host ''
    }
}
# <<< Catppuccin Terminal Setup <<<
'@

    foreach ($pPath in $uniqueProfileTargets) {
        $pDir = Split-Path -Parent $pPath
        if (-not (Test-Path -LiteralPath $pDir)) {
            New-Item -ItemType Directory -Path $pDir -Force | Out-Null
        }
        Backup-File $pPath $backupDir
        $existing = if (Test-Path -LiteralPath $pPath) { Get-Content -LiteralPath $pPath -Raw } else { '' }
        $cleaned = Remove-CatppuccinBlock $existing
        $newContent = if ([string]::IsNullOrWhiteSpace($cleaned)) { $profileBlock.Trim() } else { "$cleaned`r`n`r`n" + $profileBlock.Trim() }
        Write-Utf8NoBom $pPath $newContent
        Write-Success "Updated profile: $pPath"
    }

    # 9. Configure Windows Terminal (Theme, Color Scheme, Font & Bypass flags)
    Write-Step 'Configuring Windows Terminal settings'
    $wtSettingsCandidates = @(
        (Get-ChildItem -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $catppuccinSchemeJson = @'
        {
            "name": "Catppuccin Mocha",
            "background": "#1E1E2E",
            "foreground": "#CDD6F4",
            "cursorColor": "#F5E0DC",
            "selectionBackground": "#45475A",
            "black": "#45475A",
            "red": "#F38BA8",
            "green": "#A6E3A1",
            "yellow": "#F9E2AF",
            "blue": "#89B4FA",
            "purple": "#CBA6F7",
            "cyan": "#94E2D5",
            "white": "#BAC2DE",
            "brightBlack": "#585B70",
            "brightRed": "#F38BA8",
            "brightGreen": "#A6E3A1",
            "brightYellow": "#F9E2AF",
            "brightBlue": "#89B4FA",
            "brightPurple": "#F5C2E7",
            "brightCyan": "#94E2D5",
            "brightWhite": "#CDD6F4"
        },
'@

    foreach ($wtFile in $wtSettingsCandidates) {
        try {
            $wtJson = Get-Content -LiteralPath $wtFile -Raw
            $modified = $false

            # 1. Inject Catppuccin Mocha color scheme into schemes array if absent
            if ($wtJson -notmatch '"name"\s*:\s*"Catppuccin Mocha"') {
                if ($wtJson -match '("schemes"\s*:\s*\[)') {
                    $wtJson = $wtJson -replace '("schemes"\s*:\s*\[)', "`$1`r`n$catppuccinSchemeJson"
                    $modified = $true
                } elseif ($wtJson -match '(\{)') {
                    $wtJson = $wtJson -replace '(\{)', "`$1`r`n    `"schemes`": [`r`n$catppuccinSchemeJson`r`n    ],"
                    $modified = $true
                }
            }

            # 2. Set default colorScheme and font in profiles.defaults
            if ($wtJson -match '("defaults"\s*:\s*\{)') {
                if ($wtJson -notmatch '"colorScheme"') {
                    $wtJson = $wtJson -replace '("defaults"\s*:\s*\{)', "`$1`r`n        `"colorScheme`": `"Catppuccin Mocha`","
                    $modified = $true
                }
                if ($wtJson -notmatch 'JetBrainsMono') {
                    $wtJson = $wtJson -replace '("defaults"\s*:\s*\{)', "`$1`r`n        `"font`": { `"face`": `"JetBrainsMono NF`" },"
                    $modified = $true
                }
            }

            # 3. Add -NoLogo -ExecutionPolicy Bypass to powershell.exe if not present
            if ($wtJson -match 'powershell\.exe' -and $wtJson -notmatch 'powershell\.exe -NoLogo') {
                $wtJson = $wtJson -replace 'powershell\.exe', 'powershell.exe -NoLogo -ExecutionPolicy Bypass'
                $modified = $true
            }

            if ($modified) {
                Backup-File $wtFile $backupDir
                Write-Utf8NoBom $wtFile $wtJson
                Write-Success "Updated Windows Terminal settings at $wtFile"
            }
        }
        catch {
            Write-WarningMsg "Could not parse/modify Windows Terminal settings: $($_.Exception.Message)"
        }
    }

    # Summary
    Write-Host ''
    Write-Host '===========================================================' -ForegroundColor Green
    Write-Host '   INSTALLATION COMPLETED SUCCESSFULLY!' -ForegroundColor Green
    Write-Host '===========================================================' -ForegroundColor Green
    Write-Host "  Fastfetch config : $fastfetchConfigPath"
    Write-Host "  Oh My Posh theme : $ompConfigPath"
    Write-Host "  Anime ASCII art  : $artFile"
    Write-Host "  Clink (CMD) Lua  : $clinkLuaPath"
    Write-Host "  Backups saved in : $backupDir"
    Write-Host ''
    Write-Host '  Restart your terminal or open a new window to enjoy!' -ForegroundColor Yellow
    Write-Host ''
}
catch {
    Write-Failure "Installation failed: $($_.Exception.Message)"
    exit 1
}
