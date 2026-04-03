#! /bin/bash

if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed"
else
  echo "Installing Homebrew"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
fi

if [ -f "${CHEZMOI_WORKING_TREE}/dot_local/bin/hb" ]; then
  brew() { "${CHEZMOI_WORKING_TREE}/dot_local/bin/hb" "$@"; }
fi
