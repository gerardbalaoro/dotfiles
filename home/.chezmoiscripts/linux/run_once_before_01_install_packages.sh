#!/bin/bash

set -euo pipefail

pm() {
  if command -v apt-get >/dev/null 2>&1; then
    [ $# -eq 0 ] && echo "apt" || sudo apt-get "$@"
  elif command -v dnf >/dev/null 2>&1; then
    [ $# -eq 0 ] && echo "dnf" || sudo dnf "$@"
  elif command -v pacman >/dev/null 2>&1; then
    [ $# -eq 0 ] && echo "pacman" || sudo pacman "$@"
  elif command -v zypper >/dev/null 2>&1; then
    [ $# -eq 0 ] && echo "zypper" || sudo zypper "$@"
  elif command -v apk >/dev/null 2>&1; then
    [ $# -eq 0 ] && echo "apk" || sudo apk "$@"
  else
    echo "No supported package manager found." >&2
    return 1
  fi
}

pm_install() {
  case "$(pm)" in
    apt)     pm install -y "$@" ;;
    dnf)     pm install -y "$@" ;;
    pacman)  pm -S --noconfirm "$@" ;;
    zypper)  pm install -y "$@" ;;
    apk)     pm add "$@" ;;
  esac
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

install_wsl_hello_sudo() {
  if ! is_wsl; then
    return 0
  fi

  local install="$HOME/.local/share/wsl-hello-sudo"
  local archive="$install/release.tar.gz"
  local url="https://github.com/nullpo-head/WSL-Hello-sudo/releases/latest/download/release.tar.gz"

  mkdir -p "$install"
  curl -fsSL "$url" -o "$archive"

  tar -xzf "$archive" \
    -C "$install" \
    --strip-components=1

  rm -f "$archive"

  (cd "$install" && ./install.sh)
}

install_zsh() {
  if command -v zsh >/dev/null 2>&1; then
    echo "ZSH is already installed."
    return 0
  fi

  echo "Installing ZSH"
  pm_install zsh

  local zsh_path
  zsh_path="$(command -v zsh)"

  grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$zsh_path"
}

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

  if is_wsl; then
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

# ---- Main ----

case "$(pm)" in
  apt)
    pm update
    pm_install software-properties-common libatomic1
    sudo add-apt-repository -y ppa:git-core/ppa
    pm update
    ;;
  dnf)
    pm_install libatomic
    ;;
  pacman)
    pm -Sy --noconfirm
    pm_install libatomic_ops
    ;;
  zypper)
    pm_install libatomic1
    ;;
  apk)
    pm_install libatomic
    ;;
esac

pm_install gawk openssl
pm_install zip unzip git git-lfs
pm_install curl wget
pm_install tmux zoxide fzf jq

install_wsl_hello_sudo
install_zsh
install_ohmyposh
install_1password