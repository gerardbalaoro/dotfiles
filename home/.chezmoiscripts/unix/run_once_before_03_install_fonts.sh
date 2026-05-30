#!/bin/bash

if command -v oh-my-posh >/dev/null; then
  chezmoi git lfs install
  chezmoi git lfs pull

  fonts=("CommitMono")
  for font in "${fonts[@]}"; do
    oh-my-posh font install "$CHEZMOI_WORKING_TREE/data/fonts/$font.zip"
  done
else
  echo "oh-my-posh not found, skipping font installation"
fi