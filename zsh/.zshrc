# Enable Powerlevel10k instant prompt (must be near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Homebrew (Linux — adds brew to PATH before everything else) ───────────────
[[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# ── Plugins: brew paths with system fallback (Debian / Kali / Ubuntu) ─────────
_src() { [[ -f "$1" ]] && source "$1"; }
if command -v brew &>/dev/null; then
  _src "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  _src "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
  _src "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  _src "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ── Environment ───────────────────────────────────────────────────────────────
export EDITOR="nvim"
export PATH="$HOME/.local/bin:$PATH"

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_REDUCE_BLANKS

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ── Tool integrations (skip gracefully if not installed yet) ──────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
command -v fzf    &>/dev/null && source <(fzf --zsh) 2>/dev/null

# ── Aliases: better defaults (conditional on tools being present) ──────────────
if command -v eza &>/dev/null; then
  alias ls="eza --icons"
  alias ll="eza -lah --icons --git"
  alias la="eza -a --icons"
  alias lt="eza --tree --icons --level=2"
fi
command -v bat &>/dev/null && alias cat="bat"

# ── Aliases: git ──────────────────────────────────────────────────────────────
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias glg="git log --oneline --graph --all"
alias gd="git diff"

# ── Aliases: navigation ───────────────────────────────────────────────────────
alias ..="cd .."
alias ...="cd ../.."
alias ~="cd ~"

# ── Powerlevel10k ─────────────────────────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
