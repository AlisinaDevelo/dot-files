#!/usr/bin/env pwsh
#Requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$DOTFILES = $PSScriptRoot

function Step  { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Blue }
function Ok    { param([string]$msg) Write-Host "  v $msg" -ForegroundColor Green }
function Warn  { param([string]$msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function Die   { param([string]$msg) Write-Host "  x $msg" -ForegroundColor Red; exit 1 }

function New-Symlink {
  param([string]$src, [string]$dst)
  $parentDir = Split-Path $dst -Parent
  if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
  }
  $item = Get-Item $dst -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType -eq "SymbolicLink") {
    if ($item.Target -eq $src) {
      Warn "Already linked: $(Split-Path $dst -Leaf)"
      return
    }
    Remove-Item $dst -Force
  } elseif (Test-Path $dst) {
    Warn "Skipping (file exists, not a symlink): $dst"
    return
  }
  New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
  Ok "Linked: $dst"
}

# ── Symlink prerequisite ──────────────────────────────────────────────────────
Step "Checking symlink permissions"
try {
  $testLink = "$env:TEMP\symlink_test_$(Get-Random)"
  New-Item -ItemType SymbolicLink -Path $testLink -Target $env:TEMP -Force | Out-Null
  Remove-Item $testLink -Force
  Ok "Symlink creation works"
} catch {
  Die "Cannot create symlinks. Enable Developer Mode in:`nSettings > Privacy & Security > For Developers`nor run this script as Administrator."
}

# ── Scoop ─────────────────────────────────────────────────────────────────────
Step "Scoop"
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  Ok "Installed Scoop"
} else {
  Ok "Scoop already installed"
}

Step "Scoop buckets"
foreach ($bucket in @("extras", "nerd-fonts", "versions")) {
  $exists = scoop bucket list 2>&1 | Where-Object { $_ -match "^$bucket" }
  if ($exists) {
    Warn "Bucket already added: $bucket"
  } else {
    scoop bucket add $bucket
    Ok "Added bucket: $bucket"
  }
}

Step "Scoop packages"
$scoopPackages = @(
  "git", "versions/neovim-nightly", "lazygit", "gh",
  "ripgrep", "fd", "bat", "eza", "fzf", "zoxide", "yazi",
  "delta", "jq", "curl", "wget",
  "oh-my-posh", "kubectl", "kubectx",
  "direnv", "tldr",
  "ollama"    # local LLMs
)
# Check installed apps via filesystem (scoop list can be unreliable with no buckets)
$scoopAppsDir = "$env:USERPROFILE\scoop\apps"
$installedViaScoop = if (Test-Path $scoopAppsDir) {
  [System.IO.Directory]::GetDirectories($scoopAppsDir) | ForEach-Object { [System.IO.Path]::GetFileName($_) }
} else { @() }

foreach ($pkg in $scoopPackages) {
  if ($installedViaScoop -contains $pkg) {
    Warn "Already installed: $pkg"
  } else {
    $out = scoop install $pkg 2>&1 | Out-String
    if ($out -match "already installed") {
      Warn "Already installed: $pkg"
    } elseif ($LASTEXITCODE -eq 0) {
      Ok "Installed: $pkg"
    } else {
      Warn "Failed to install: $pkg — check manually"
    }
  }
}

Step "Nerd Font (MesloLGS)"
# Font files in use by running terminals cause non-fatal copy errors — ignore them
$fontOut = scoop install nerd-fonts/Meslo-NF 2>&1 | Out-String
if ($fontOut -match "already installed") {
  Warn "MesloLGS Nerd Font already installed"
} else {
  Ok "MesloLGS Nerd Font installed (restart apps to pick it up)"
}

# ── Python AI tools ───────────────────────────────────────────────────────────
Step "Python AI tools (aider + llm)"
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
  Warn "pip not found — skipping aider and llm (install Python first)"
} else {
  # aider: use its bootstrapper which creates an isolated env compatible with Python 3.12+
  if (Get-Command aider -ErrorAction SilentlyContinue) {
    Warn "Already installed: aider"
  } else {
    pip install aider-install --quiet 2>&1 | Out-Null
    aider-install 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok "Installed: aider" } else { Warn "Failed to install: aider" }
  }

  # llm: unified CLI for OpenAI, Anthropic, Ollama, and more
  $llmCheck = pip show llm 2>&1 | Out-String
  if ($llmCheck -match "^Name:") {
    Warn "Already installed: llm"
  } else {
    pip install llm --quiet 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok "Installed: llm" } else { Warn "Failed to install: llm" }
  }
}

# ── GitHub Copilot CLI extension ──────────────────────────────────────────────
Step "gh copilot extension"
$ghExt = gh extension list 2>&1 | Out-String
if ($ghExt -match "gh-copilot") {
  Warn "gh copilot already installed"
} else {
  $ghAuth = gh auth status 2>&1 | Out-String
  if ($ghAuth -match "Logged in") {
    gh extension install github/gh-copilot
    Ok "Installed gh copilot"
  } else {
    Warn "Skipped gh copilot (run 'gh auth login' first, then re-run this script)"
  }
}

# ── winget GUI apps ───────────────────────────────────────────────────────────
Step "winget apps"
$wingetApps = @(
  @{ id = "Microsoft.WindowsTerminal"; name = "Windows Terminal" },
  @{ id = "Alacritty.Alacritty";       name = "Alacritty" }
)
foreach ($app in $wingetApps) {
  $check = winget list --id $app.id 2>&1 | Out-String
  if ($check -match $app.id) {
    Warn "Already installed: $($app.name)"
  } else {
    winget install --id=$($app.id) --accept-package-agreements --accept-source-agreements -e
    Ok "Installed: $($app.name)"
  }
}

# ── Config symlinks ───────────────────────────────────────────────────────────
Step "Config symlinks"

# Neovim
New-Symlink "$DOTFILES\nvim"               "$env:LOCALAPPDATA\nvim"

# Git
New-Symlink "$DOTFILES\git\.gitconfig"     "$env:USERPROFILE\.gitconfig"

# PowerShell profile (CurrentUserAllHosts so it applies to every PS host)
New-Symlink "$DOTFILES\powershell\profile.ps1" $PROFILE.CurrentUserAllHosts

# Alacritty
New-Symlink "$DOTFILES\alacritty\alacritty.toml" "$env:APPDATA\alacritty\alacritty.toml"

# Windows Terminal — path only exists after WT is installed
$wtState = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $wtState) {
  New-Symlink "$DOTFILES\windows-terminal\settings.json" "$wtState\settings.json"
} else {
  Warn "Windows Terminal not found yet — run the script again after it installs"
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host "`nAll done!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your terminal"
Write-Host "  2. Run 'nvim' to let LazyVim auto-install plugins"
Write-Host "  3. In nvim, run ':MasonInstall <server>' for language servers"
Write-Host "  4. For WSL2: run 'wsl --install', then run ./install.sh inside WSL"
Write-Host "  5. Set ANTHROPIC_API_KEY or OPENAI_API_KEY for Avante AI (in nvim)"
Write-Host "  6. Run 'ollama pull qwen2.5-coder' to download a local coding model"
