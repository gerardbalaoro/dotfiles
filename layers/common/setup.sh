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
  git -C "$repository" lfs install --local
  git -C "$repository" lfs pull

  checksum="$(cksum "$repository"/layers/common/fonts/*.zip "$0")"
  if [[ -f "$state/fonts.cksum" ]] && [[ "$(cat "$state/fonts.cksum")" == "$checksum" ]]; then
    exit 0
  fi

  fonts=("CommitMono" "CommitMono_NerdFont")
  for font in "${fonts[@]}"; do
    oh-my-posh font install "$repository/layers/common/fonts/$font.zip"
  done
  mkdir -p "$state"
  printf '%s\n' "$checksum" > "$state/fonts.cksum"
else
  echo "oh-my-posh not found; run mise bootstrap to install prerequisites" >&2
  exit 1
fi
