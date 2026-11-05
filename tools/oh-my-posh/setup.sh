#!/bin/bash
set -euo pipefail

repository="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v oh-my-posh >/dev/null; then
  echo 'Fetching font archives with Git LFS...'
  git -C "$repository" lfs install --local
  git -C "$repository" lfs pull

  checksum="$(cksum "$repository"/tools/oh-my-posh/fonts/*.zip "$0")"
  if [[ -f "$state/fonts.cksum" ]] && [[ "$(cat "$state/fonts.cksum")" == "$checksum" ]]; then
    echo 'Fonts are already installed.'
    exit 0
  fi

  # Older releases need --headless; version 30 removed the font installer TUI.
  font_help="$(oh-my-posh font install --help)"
  font_command=(oh-my-posh font install)
  if [[ "$font_help" == *"--headless"* ]]; then
    font_command+=(--headless)
  elif [[ "$font_help" != *"font install <font>"* ]]; then
    echo 'Update Oh My Posh to a release with noninteractive font installation.' >&2
    exit 1
  fi

  fonts=("CommitMono" "CommitMono_NerdFont")
  for font in "${fonts[@]}"; do
    echo "Installing $font..."
    "${font_command[@]}" "$repository/tools/oh-my-posh/fonts/$font.zip"
  done
  mkdir -p "$state"
  printf '%s\n' "$checksum" > "$state/fonts.cksum"
else
  echo "oh-my-posh not found; run mise bootstrap to install prerequisites" >&2
  exit 1
fi
