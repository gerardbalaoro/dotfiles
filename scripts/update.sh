#!/bin/sh
set -eu

git pull --ff-only
mise exec -- fnox exec --only 'DOTFILES_*' -- mise bootstrap --update
