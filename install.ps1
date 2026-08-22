#!/usr/bin/env pwsh
#Requires -Version 7
[CmdletBinding()]
param(
  [switch]$Apply,
  [switch]$LinksOnly,
  [switch]$BackupExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$DOTFILES = $PSScriptRoot
$script:LinkConflicts = 0

function Step { param([string]$Message) Write-Host "`n==> $Message" -ForegroundColor Blue }
function Ok { param([string]$Message) Write-Host "  OK $Message" -ForegroundColor Green }
function Warn { param([string]$Message) Write-Host "  WARN $Message" -ForegroundColor Yellow }
function Die { param([string]$Message) Write-Host "  ERROR $Message" -ForegroundColor Red; exit 1 }

if ($BackupExisting -and -not $Apply) {
  Die "-BackupExisting requires -Apply."
}

$scoopBuckets = @("extras", "nerd-fonts", "versions")
$scoopPackages = @(
  "git", "versions/neovim-nightly", "lazygit", "gh",
  "ripgrep", "fd", "bat", "eza", "fzf", "zoxide", "yazi",
  "delta", "jq", "curl", "wget", "lua", "shellcheck", "shfmt",
  "stylua", "gitleaks", "python", "pipx", "oh-my-posh", "kubectl",
  "kubectx", "direnv", "tldr", "ollama"
)
$wingetApps = @(
  @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
  @{ Id = "Alacritty.Alacritty"; Name = "Alacritty" },
  @{ Id = "GitHub.Copilot"; Name = "GitHub Copilot CLI" }
)

function Get-LinkState {
  param([string]$Source, [string]$Destination)
  $item = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType -eq "SymbolicLink") {
    if (([string]$item.Target) -eq $Source) { return "linked" }
    return "conflict: symlink -> $($item.Target)"
  }
  if ($item -and $item.PSIsContainer) { return "conflict: directory" }
  if ($item) { return "conflict: file" }
  return "new"
}

function Show-Link {
  param([string]$Source, [string]$Destination)
  Write-Host ("  {0,-60} {1}" -f $Destination, (Get-LinkState $Source $Destination))
}

function Backup-Destination {
  param([string]$Destination)
  $backup = "$Destination.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
  if (Test-Path -LiteralPath $backup) { $backup = "$backup.$PID" }
  Move-Item -LiteralPath $Destination -Destination $backup
  Warn "Backed up $Destination to $backup"
}

function New-SafeSymlink {
  param([string]$Source, [string]$Destination)
  $item = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue

  if ($item -and $item.LinkType -eq "SymbolicLink" -and ([string]$item.Target) -eq $Source) {
    Ok "Already linked: $Destination"
    return
  }

  if ($item) {
    if ($BackupExisting) {
      Backup-Destination $Destination
    } else {
      Warn "Skipped existing path: $Destination"
      $script:LinkConflicts++
      return
    }
  }

  $parent = Split-Path $Destination -Parent
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
  Ok "Linked: $Destination"
}

function Ensure-GitLocalConfig {
  $localConfig = Join-Path $HOME ".gitconfig.local"
  if (Test-Path -LiteralPath $localConfig) {
    Ok "Machine-local Git config exists: $localConfig"
    return
  }

  @(
    "# Machine-local Git identity and credential helpers.",
    "# git config --file ~/.gitconfig.local user.name `"Your Name`"",
    "# git config --file ~/.gitconfig.local user.email `"you@example.com`""
  ) | Set-Content -LiteralPath $localConfig -Encoding utf8NoBOM
  Warn "Created $localConfig; add your Git identity before committing"
}

$nvimDestination = Join-Path $env:LOCALAPPDATA "nvim"
$gitDestination = Join-Path $HOME ".gitconfig"
$profileDestination = $PROFILE.CurrentUserAllHosts
$alacrittyDestination = Join-Path $env:APPDATA "alacritty\alacritty.toml"
$wtState = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$wtDestination = Join-Path $wtState "settings.json"

Step "Plan"
Write-Host "  Platform: Windows $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
Write-Host "  Mode:     $(if ($Apply) { 'apply' } else { 'preview' })"
Write-Host "  Packages: $(if ($LinksOnly) { 'skip' } else { 'Scoop and winget manifests' })"
Write-Host "  Conflicts: $(if ($BackupExisting) { 'backup then link' } else { 'preserve and report' })"

Step "Config destinations"
Show-Link "$DOTFILES\nvim" $nvimDestination
Show-Link "$DOTFILES\git\.gitconfig" $gitDestination
Show-Link "$DOTFILES\powershell\profile.ps1" $profileDestination
Show-Link "$DOTFILES\alacritty\alacritty.toml" $alacrittyDestination
Show-Link "$DOTFILES\windows-terminal\settings.json" $wtDestination

if (-not $Apply) {
  Write-Host "`nPreview complete. Re-run with -Apply after reviewing the plan."
  exit 0
}

Step "Symlink permissions"
try {
  $testLink = Join-Path $env:TEMP "dotfiles-symlink-$PID"
  New-Item -ItemType SymbolicLink -Path $testLink -Target $env:TEMP -Force | Out-Null
  Remove-Item -LiteralPath $testLink -Force
  Ok "Symlink creation works"
} catch {
  Die "Cannot create symlinks. Enable Windows Developer Mode or run as Administrator."
}

if (-not $LinksOnly) {
  Step "Scoop packages"
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Die "Scoop is required. Review and install it from https://scoop.sh, then re-run this script."
  }

  foreach ($bucket in $scoopBuckets) {
    $exists = scoop bucket list 2>&1 | Where-Object { $_ -match "^$bucket" }
    if ($exists) {
      Ok "Bucket already present: $bucket"
    } else {
      scoop bucket add $bucket
      Ok "Added bucket: $bucket"
    }
  }

  foreach ($package in $scoopPackages) {
    scoop install $package | Out-Host
    if ($LASTEXITCODE -eq 0) {
      Ok "Available: $package"
    } else {
      Warn "Package failed or needs review: $package"
    }
  }

  scoop install nerd-fonts/Meslo-NF | Out-Host
  if ($LASTEXITCODE -eq 0) {
    Ok "Meslo Nerd Font available"
  } else {
    Warn "Meslo Nerd Font failed or was already in use"
  }

  Step "Python AI tools"
  foreach ($tool in @(
    @{ Package = "aider-chat"; Command = "aider" },
    @{ Package = "llm"; Command = "llm" }
  )) {
    if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
      Ok "Already available: $($tool.Command)"
    } else {
      pipx install $tool.Package
      if ($LASTEXITCODE -eq 0) {
        Ok "Installed: $($tool.Package)"
      } else {
        Warn "Failed to install: $($tool.Package)"
      }
    }
  }

  Step "winget applications"
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    foreach ($app in $wingetApps) {
      winget install --id $app.Id --accept-package-agreements --accept-source-agreements -e
      if ($LASTEXITCODE -eq 0) {
        Ok "Available: $($app.Name)"
      } else {
        Warn "Application failed or needs review: $($app.Name)"
      }
    }
  } else {
    Warn "winget is unavailable; GUI applications were skipped"
  }
}

Step "Config symlinks"
New-SafeSymlink "$DOTFILES\nvim" $nvimDestination
New-SafeSymlink "$DOTFILES\git\.gitconfig" $gitDestination
New-SafeSymlink "$DOTFILES\powershell\profile.ps1" $profileDestination
New-SafeSymlink "$DOTFILES\alacritty\alacritty.toml" $alacrittyDestination
New-SafeSymlink "$DOTFILES\windows-terminal\settings.json" $wtDestination
Ensure-GitLocalConfig

Step "Result"
if ($script:LinkConflicts -gt 0) {
  Warn "$($script:LinkConflicts) destination(s) were preserved"
  Write-Host "Re-run with -Apply -BackupExisting after reviewing those paths."
  exit 2
}

Ok "Dotfiles are installed"
Write-Host "Restart the terminal, then open nvim to finish plugin setup."
