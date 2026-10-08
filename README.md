<div align="center">

# 🌸 Catppuccin Mocha Terminal

**Aesthetic, distraction-free, and unified Windows Terminal setup featuring Catppuccin Mocha, Fastfetch, Oh My Posh, and Clink.**

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D4?logo=windows&logoColor=white)](https://github.com/krambovic/catppuccin-terminal)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/krambovic/catppuccin-terminal)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin%20Mocha-CBA6F7?logo=catppuccin&logoColor=white)](https://github.com/catppuccin/catppuccin)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<br />

<img src="assets/preview.png" alt="Catppuccin Mocha Terminal Preview" width="360" />

<br />

*Pixel-perfect alignment: compact 14-line Anime Girl ASCII art matching system specs line-by-line.*

</div>

---

## ⚡ Quick Install (One-Liner)

Open **PowerShell** (as your regular user) and run:

```powershell
irm https://raw.githubusercontent.com/krambovic/catppuccin-terminal/main/install.ps1 | iex
```

> [!NOTE]
> That's it! After the script finishes, close all terminal windows and open a new **Windows Terminal** or **CMD** window.

---

## ✨ Features

- 🌸 **Catppuccin Mocha Everywhere**: Cohesive pastel aesthetic across Windows Terminal, PowerShell, Command Prompt, Fastfetch, and Oh My Posh.
- 🎀 **Pixel-Perfect Anime Girl ASCII Art**: Beautiful 14-line braille art with Catppuccin accents (sapphire hair, pink blush/eyes, peach highlights) designed to align 1:1 with Fastfetch's system info block without blank gaps or vertical overflow.
- ⚡ **Identical CMD & PowerShell Experience**: Both shells share the exact same Oh My Posh prompt and input syntax coloring (yellow commands, gray flags, white arguments).
- 🛡️ **Zero Prompt Jumping**: No annoying `transient_prompt` ANSI glitches (`\e[1A`) when pressing `Enter`. Commands stay firmly in place upon execution.
- 🧼 **Distraction-Free CMD**: Clink is tuned to strip away intrusive gray autosuggestion ghosts, red unrecognized-word flashing, and the `[F2] list suggestions` bar.
- 🚀 **Always-On Fastfetch**: Fastfetch launches automatically whenever you open a terminal, whether through Windows Terminal, `Win + R` (`cmd` or `powershell`), the Start menu, or File Explorer.
- 🔤 **JetBrains Mono Nerd Font**: Automatically downloaded, installed, and wired up in your Windows Terminal profiles.
- 🗄️ **Safe Automatic Backups**: Existing configurations are backed up to `~/catppuccin-terminal-backups/<timestamp>/` before anything is changed.
- 🔄 **Idempotent & Self-Healing**: Can be run multiple times safely without duplicate profile entries or file corruption.

---

## 🛡️ Edge-Case Handling & Resilience

The installer script is specifically engineered to handle notorious Windows quirks out of the box:

| Challenge | Solution |
| :--- | :--- |
| **Execution Policy Restricted** | Automatically applies `-ExecutionPolicy Bypass -Scope CurrentUser` |
| **Unindexed Winget** | Auto-probes `%LOCALAPPDATA%\Microsoft\WindowsApps` and `Program Files\WindowsApps` to locate `winget.exe` even if missing from `$env:Path` |
| **PowerShell 5.1 vs 7 (Core)** | Configures both Windows PowerShell 5.1 and modern PowerShell 7 (`pwsh`) profiles |
| **Encoding / Mojibake (`вЎ†вЈђ`)** | Enforces UTF-8 without BOM (`[System.Text.UTF8Encoding]($false)`) and switches codepage via `chcp 65001` to eliminate CP1251/CP866 mangling |
| **Windows Terminal Editions** | Supports Microsoft Store Stable, Microsoft Store Preview, and Unpackaged / Portable installations |
| **Background / Non-Interactive Tasks** | Detects non-interactive executions (`-Command`, `-File`, automation agents) and suppresses screen-clearing banners so scripts never get corrupted |

---

## 📂 Repository Structure

```text
catppuccin-terminal/
├── assets/
│   └── preview.png                           # Showcase screenshot
├── config/
│   ├── clink/
│   │   └── catppuccin.lua                    # CMD Clink integration script
│   ├── fastfetch/
│   │   ├── ascii/
│   │   │   └── anime-girl-1.txt              # Compact Catppuccin anime ASCII art
│   │   └── config.jsonc                      # Fastfetch Catppuccin Mocha configuration
│   └── oh-my-posh/
│       └── catppuccin-mocha.omp.json         # Oh My Posh prompt theme
├── install.ps1                               # Fully automated all-in-one installer
├── uninstall.ps1                             # Safe uninstaller & backup restorer
├── LICENSE                                   # MIT License
└── README.md                                 # Documentation
```

---

## 📦 What Gets Installed?

The script uses `winget` to install the following lightweight tools:

1. **[Fastfetch](https://github.com/fastfetch-cli/fastfetch)** (`Fastfetch-cli.Fastfetch`) — Lightning-fast, modern system information tool.
2. **[Oh My Posh](https://ohmyposh.dev/)** (`JanDeDobbeleer.OhMyPosh`) — Shell prompt engine.
3. **[Clink](https://chrisant996.github.io/clink/)** (`chrisant996.Clink`) — Readline and prompt enhancements for `cmd.exe`.
4. **[JetBrains Mono Nerd Font](https://www.nerdfonts.com/)** (`DEVCOM.JetBrainsMonoNerdFont`) — Clean programming font with full glyph support.

---

## 🗑️ Uninstallation

To cleanly remove all Catppuccin configurations and revert your PowerShell profile and CMD to standard Windows defaults:

```powershell
irm https://raw.githubusercontent.com/krambovic/catppuccin-terminal/main/uninstall.ps1 | iex
```

*(Your original backups remain preserved in `~/catppuccin-terminal-backups/`)*

---

<div align="center">
  <sub>Created with 💖 by <a href="https://github.com/krambovic">krambovic</a></sub>
</div>
