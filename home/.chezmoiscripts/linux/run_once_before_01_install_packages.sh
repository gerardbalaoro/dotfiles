#!/bin/bash

set -eufo pipefail

# ---- Distro detection ----
# Returns: debian, fedora, rhel, or unknown
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID:-}" in
      debian|ubuntu|linuxmint|pop|elementary|zorin|kali)
        echo "debian"
        return 0
        ;;
      fedora)
        echo "fedora"
        return 0
        ;;
      rhel|centos|almalinux|rocky|ol)
        echo "rhel"
        return 0
        ;;
    esac
  fi

  # Fallback checks
  if command -v apt-get >/dev/null 2>&1 && [ -f /etc/debian_version ]; then
    echo "debian"
  elif command -v dnf >/dev/null 2>&1; then
    if [ -f /etc/fedora-release ]; then
      echo "fedora"
    else
      echo "rhel"
    fi
  else
    echo "unknown"
  fi
}

DISTRO=$(detect_distro)

install_pkg() {
  case "$DISTRO" in
    debian)
      sudo apt-get install -y "$@"
      ;;
    fedora|rhel)
      sudo dnf install -y "$@"
      ;;
    *)
      echo "Unsupported distro: $DISTRO. Install '$*' manually." >&2
      return 1
      ;;
  esac
}

# ---- Helpers ----
is_wsl() {
  command -v wslinfo >/dev/null
}

# ---- Package installers ----

install_zsh() {
  if command -v zsh >/dev/null; then
    echo "ZSH is already installed."
    return 0
  fi

  echo "Installing ZSH"
  install_pkg zsh
  chsh -s "$(command -v zsh)"
}

install_ohmyposh() {
  if command -v oh-my-posh >/dev/null; then
    echo "Oh My Posh is already installed."
    return 0
  fi

  echo "Installing Oh My Posh"
  curl -s https://ohmyposh.dev/install.sh | bash -s
}

install_1password() {
  local version_url arch op_url tmpdir

  if command -v op >/dev/null; then
    echo "1Password CLI is already installed."
    return 0
  fi

  if is_wsl; then
    echo "Skipping 1Password CLI installation on WSL."
    return 0
  fi

  echo "Installing 1Password CLI"

  # Sniff arch for the download URL
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64"  ;;
    *)
      echo "Unsupported architecture: $arch. Install 1Password CLI manually." >&2
      return 1
      ;;
  esac

  # Fetch latest version from the release notes page
  version_url="https://app-updates.agilebits.com/product_history/CLI2"
  version=$(curl -sL "$version_url" | grep -oP '/op_linux_'"$arch"'_v[\d.]+(?=\.zip)' | head -1)

  if [ -z "$version" ]; then
    echo "Failed to detect latest 1Password CLI version." >&2
    return 1
  fi

  op_url="https://cache.agilebits.com/dist/1P/op2/pkg/${version}/op_linux_${arch}_${version}.zip"
  tmpdir=$(mktemp -d)

  curl -fsSL "$op_url" -o "$tmpdir/op.zip"
  sudo unzip -q -o -d /usr/local/bin "$tmpdir/op.zip" 2>/dev/null
  rm -rf "$tmpdir"

  sudo groupadd -f onepassword-cli
  sudo chown root:onepassword-cli /usr/local/bin/op
  sudo chmod 750 /usr/local/bin/op
}

# ---- Main ----

# Refresh package index on Debian-family
if [ "$DISTRO" = "debian" ]; then
  sudo apt-get update
fi

install_pkg zip unzip git git-lfs
install_pkg curl wget
install_pkg tmux zoxide fzf

install_zsh
install_ohmyposh
install_1password
