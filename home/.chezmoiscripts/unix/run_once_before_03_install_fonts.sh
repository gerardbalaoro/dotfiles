#!/bin/bash

if command -v oh-my-posh >/dev/null; then
  chezmoi git lfs install
  chezmoi git lfs pull
  oh-my-posh font install "$env:CHEZMOI_WORKING_TREE/data/fonts/GeistMonoNF.zip"
  oh-my-posh font install "$env:CHEZMOI_WORKING_TREE/data/fonts/MonaspaceNeonNF.zip"
else
  echo "oh-my-posh not found, skipping font installation"
fi