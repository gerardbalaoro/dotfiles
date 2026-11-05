#!/bin/bash
set -euo pipefail

# Packages and tools are installed before this bootstrap task runs.
configure_zsh() {
  local zsh_path current_shell username
  username="$(id -un)"
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "$username" | cut -d: -f7)"
  if [ "$current_shell" = "$zsh_path" ]; then
    return 0
  fi

  grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  # Use sudo authentication; chsh's separate PAM policy may reject this account.
  sudo chsh -s "$zsh_path" "$username"
}

configure_zsh
