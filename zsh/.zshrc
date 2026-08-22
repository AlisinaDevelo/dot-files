# Powerlevel10k instant prompt must stay near the top of this file.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -U path PATH fpath

# Homebrew on Linux is not added by macOS path_helper.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# User-level tools. Missing directories are harmless on a fresh machine.
for _tool_bin in \
  "$HOME/.local/bin" \
  "$HOME/.grok/bin" \
  "$HOME/.kimi-code/bin" \
  "$HOME/.opencode/bin"; do
  [[ -d "$_tool_bin" ]] && path=("$_tool_bin" $path)
done
[[ -d "$HOME/opt/metasploit-framework/bin" ]] && path+=("$HOME/opt/metasploit-framework/bin")

# Completion paths must be registered before Oh My Zsh initializes compinit.
[[ -d "$HOME/.grok/completions/zsh" ]] && fpath=("$HOME/.grok/completions/zsh" $fpath)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit -C
fi

_source_if_readable() { [[ -r "$1" ]] && source "$1"; }
if command -v brew >/dev/null 2>&1; then
  _brew_prefix="$(brew --prefix)"
  _source_if_readable "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  _source_if_readable "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

export EDITOR="nvim"
export VISUAL="$EDITOR"

# Homebrew JDK paths differ across macOS architectures and Linux.
if command -v brew >/dev/null 2>&1; then
  _jdk_prefix="$(brew --prefix openjdk 2>/dev/null || true)"
  if [[ -n "$_jdk_prefix" ]]; then
    path=("$_jdk_prefix/bin" $path)
    if [[ -d "$_jdk_prefix/libexec/openjdk.jdk/Contents/Home" ]]; then
      export JAVA_HOME="$_jdk_prefix/libexec/openjdk.jdk/Contents/Home"
    else
      export JAVA_HOME="$_jdk_prefix"
    fi
  fi

  _jdk11_prefix="$(brew --prefix openjdk@11 2>/dev/null || true)"
  if [[ -n "$_jdk11_prefix" ]]; then
    if [[ -d "$_jdk11_prefix/libexec/openjdk.jdk/Contents/Home" ]]; then
      export JAVA_HOME_11="$_jdk11_prefix/libexec/openjdk.jdk/Contents/Home"
    else
      export JAVA_HOME_11="$_jdk11_prefix"
    fi
  fi
fi

HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_REDUCE_BLANKS
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v fzf >/dev/null 2>&1 && _source_if_readable <(fzf --zsh 2>/dev/null)

if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons"
  alias ll="eza -lah --icons --git"
  alias la="eza -a --icons"
  alias lt="eza --tree --icons --level=2"
fi
command -v bat >/dev/null 2>&1 && alias cat="bat"

alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias glg="git log --oneline --graph --all"
alias gd="git diff"
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias ~="cd ~"

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Syntax highlighting should be sourced after all widgets and aliases exist.
if command -v brew >/dev/null 2>&1; then
  _source_if_readable "${_brew_prefix:-$(brew --prefix)}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
else
  _source_if_readable "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _tool_bin _brew_prefix _jdk_prefix _jdk11_prefix
unfunction _source_if_readable
