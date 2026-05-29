#!/usr/bin/env bash

set -e

echo "📦 Installing Homebrew packages..."
brew bundle --file=./Brewfile

echo "🔗 Linking configs..."

ln -sf $(pwd)/zsh/.zshrc ~/.zshrc
ln -sf $(pwd)/tmux/.tmux.conf ~/.tmux.conf
ln -sf $(pwd)/git/.gitconfig ~/.gitconfig

mkdir -p ~/.config/alacritty
ln -sf $(pwd)/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml

echo " Installing tmux plugins..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || true

echo " Reload shell..."
exec zsh
