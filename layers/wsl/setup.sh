#!/usr/bin/env bash
set -euo pipefail

install_wsl_hello_sudo() {
  # Preserve an existing PAM installation on repeated bootstrap runs.
  if [ -f /etc/pam_wsl_hello/config ] &&
     { [ -f /lib/x86_64-linux-gnu/security/pam_wsl_hello.so ] ||
       [ -f /lib/security/pam_wsl_hello.so ] ||
       [ -f /lib64/security/pam_wsl_hello.so ] ||
       [ -f /usr/lib64/security/pam_wsl_hello.so ]; }; then
    return 0
  fi

  if ! { : </dev/tty; } 2>/dev/null; then
    echo 'Run bootstrap from an interactive terminal to enroll WSL Hello sudo.' >&2
    return 1
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

  # A curl | sh bootstrap supplies script text on stdin, not prompt answers.
  (cd "$install" && ./install.sh </dev/tty)
}

install_wsl_hello_sudo

# Keep future mise commands in this checkout on the same WSL layer.
repository="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ ! -e "$repository/.miserc.local.toml" ]]; then
  printf 'env = ["wsl"]\n' > "$repository/.miserc.local.toml"
fi
