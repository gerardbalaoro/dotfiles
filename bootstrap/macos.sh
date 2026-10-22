#!/usr/bin/env bash
set -euo pipefail

if [[ -x /opt/homebrew/bin/brew ]]; then
  brew_bin=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  brew_bin=/usr/local/bin/brew
elif command -v brew >/dev/null 2>&1; then
  brew_bin="$(command -v brew)"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  else
    brew_bin=/usr/local/bin/brew
  fi
fi

# Install missing packages without upgrading existing installations.
for formula in curl wget zip unzip xz git git-lfs tmux fzf zoxide; do
  "$brew_bin" list --formula "$formula" >/dev/null 2>&1 || "$brew_bin" install "$formula"
done

for cask in 1password 1password-cli jandedobbeleer/oh-my-posh/oh-my-posh ghostty visual-studio-code; do
  "$brew_bin" list --cask "$cask" >/dev/null 2>&1 || "$brew_bin" install --cask "$cask"
done
