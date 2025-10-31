#!/bin/bash

if command -v oh-my-posh >/dev/null; then
  chezmoi git lfs install
  chezmoi git lfs pull
  oh-my-posh font install "$HOME/.local/share/chezmoi/data/fonts/Monaspace Neon.zip"
else
  echo "oh-my-posh not found, skipping font installation"
fi