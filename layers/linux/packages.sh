#!/bin/bash
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Native integrations retained from the original Linux installer.
install_ohmyposh() {
  if command -v oh-my-posh >/dev/null 2>&1; then
    echo "Oh My Posh is already installed."
    return 0
  fi

  echo "Installing Oh My Posh"
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s
}

install_1password() {
  if command -v op >/dev/null 2>&1; then
    echo "1Password CLI is already installed."
    return 0
  fi

  if [[ "${1:-}" == --wsl ]]; then
    echo "Skipping 1Password CLI installation on WSL."
    return 0
  fi

  local arch version url tmpdir
  version="v2.33.1"

  case "$(uname -m)" in
    x86_64) arch="amd64" ;;
    i386|i686) arch="386" ;;
    armv7l|armv6l) arch="arm" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      return 1
      ;;
  esac

  echo "Installing 1Password CLI"

  url="https://cache.agilebits.com/dist/1P/op2/pkg/${version}/op_linux_${arch}_${version}.zip"
  tmpdir="$(mktemp -d)"

  curl -fsSL "$url" -o "$tmpdir/op.zip"
  unzip -q -d "$tmpdir/op" "$tmpdir/op.zip"

  sudo mv "$tmpdir/op/op" /usr/local/bin/op
  rm -rf "$tmpdir"

  sudo groupadd -f onepassword-cli
  sudo chgrp onepassword-cli /usr/local/bin/op
  sudo chmod g+s /usr/local/bin/op
}

install_ohmyposh
install_1password "${1:-}"
