# ── Prompt: Oh My Posh (Catppuccin Mocha) ────────────────────────────────────
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\catppuccin_mocha.omp.json" | Invoke-Expression
}

# ── Environment ───────────────────────────────────────────────────────────────
$env:EDITOR = "nvim"
# ~/.local/bin: aider and other user-installed tools land here
if ($env:PATH -notmatch [regex]::Escape("$HOME\.local\bin")) {
  $env:PATH = "$HOME\.local\bin;$env:PATH"
}

# ── PSReadLine ────────────────────────────────────────────────────────────────
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -MaximumHistoryCount 100000
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -BellStyle None
Set-PSReadLineKeyHandler -Key Tab            -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow        -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow      -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key ctrl+r         -Function ReverseSearchHistory

# ── Tool integrations ─────────────────────────────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Command direnv -ErrorAction SilentlyContinue) {
  # direnv needs a config directory; on Windows XDG_CONFIG_HOME isn't set by default
  if (-not $env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME = "$env:APPDATA" }
  $null = New-Item -ItemType Directory -Path "$env:XDG_CONFIG_HOME\direnv" -Force
  Invoke-Expression "$(direnv hook pwsh)"
}

# fzf: bind Ctrl+F to interactive file picker
if (Get-Command fzf -ErrorAction SilentlyContinue) {
  Set-PSReadLineKeyHandler -Key ctrl+f -ScriptBlock {
    $file = (fzf --preview "bat --color=always --line-range :50 {}" 2>$null)
    if ($file) {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($file)
    }
  }
}

# ── Aliases: shell ────────────────────────────────────────────────────────────
Set-Alias -Name vim -Value nvim

function ls  { eza --icons @args }
function ll  { eza -lah --icons --git @args }
function la  { eza -a --icons @args }
function lt  { eza --tree --icons --level=2 @args }
function cat { bat @args }

# ── Aliases: git ──────────────────────────────────────────────────────────────
function gs  { git status @args }
function ga  { git add @args }
function gc  { git commit @args }
function gp  { git push @args }
function gl  { git pull @args }
function gco { git checkout @args }
function gd  { git diff @args }
function glg { git log --oneline --graph --decorate --all @args }

# ── Aliases: navigation ───────────────────────────────────────────────────────
function ..  { Set-Location .. }
function ... { Set-Location ..\.. }
