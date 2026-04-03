#!/bin/bash

set -eufo pipefail

. $CHEZMOI_SCRIPTS/darwin/scripts/install-homebrew.sh

brew install curl wget zip unzip xz
brew install --cask 1password
brew install --cask 1password-cli
brew install --cask jandedobbeleer/oh-my-posh/oh-my-posh
