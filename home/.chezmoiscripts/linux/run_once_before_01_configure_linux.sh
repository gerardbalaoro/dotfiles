#!/bin/bash
set -euo pipefail

# Packages are installed by mise bootstrap before chezmoi runs these steps.
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

install_wsl_hello_sudo() {
  if ! is_wsl; then
    return 0
  fi

  # Script content changes rerun chezmoi run_once entries. Preserve an
  # existing PAM installation instead of invoking its interactive installer.
  if [ -f /etc/pam_wsl_hello/config ] &&
     { [ -f /lib/x86_64-linux-gnu/security/pam_wsl_hello.so ] ||
       [ -f /lib/security/pam_wsl_hello.so ]; }; then
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

configure_zsh() {
  local zsh_path current_shell
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  if [ "$current_shell" = "$zsh_path" ]; then
    return 0
  fi

  grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$zsh_path"
}

install_wsl_hello_sudo
configure_zsh
