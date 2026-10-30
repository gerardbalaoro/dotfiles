#!/usr/bin/env bash
set -euo pipefail

install_wsl_hello_sudo() {
  # Preserve an existing PAM installation on repeated bootstrap runs.
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

install_wsl_hello_sudo

# Keep future mise commands in this checkout on the same WSL layer.
repository="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ ! -e "$repository/.miserc.local.toml" ]]; then
  printf 'env = ["wsl"]\n' > "$repository/.miserc.local.toml"
fi
