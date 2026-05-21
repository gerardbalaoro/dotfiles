#!/bin/bash

if command -v oh-my-posh >/dev/null; then
  chezmoi git lfs install
  chezmoi git lfs pull
  for font in "$CHEZMOI_WORKING_TREE/data/fonts"/*.zip; do
    oh-my-posh font install "$font"
  done
else
  echo "oh-my-posh not found, skipping font installation"
fi