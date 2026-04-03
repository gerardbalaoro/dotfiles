#!/bin/bash

set -eufo pipefail

. $CHEZMOI_SCRIPTS/darwin/scripts/install-homebrew.sh

brew install git git-lfs gh
brew install tmux fzf zoxide
brew install --cask ghostty
brew install --cask visual-studio-code
