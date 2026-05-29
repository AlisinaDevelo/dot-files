# Enable Powerlevel10k instant prompt (must be near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Brew-installed plugins (sourced directly, not via OMZ)
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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

# ── Tool Integrations ─────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
source <(fzf --zsh)

# ── Aliases: better defaults ──────────────────────────────────────────────────
alias ls="eza --icons"
alias ll="eza -lah --icons --git"
alias la="eza -a --icons"
alias lt="eza --tree --icons --level=2"
alias cat="bat"

# ── Aliases: git ─────────────────────────────────────────────────────────────
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
