#!/bin/sh

set -eu

# Remove competing shell profiles
rm -f "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.zprofile"

# Install mise packages
if command -v mise >/dev/null 2>&1; then
  mise install
fi

# Generate shell integrations
. "$HOME/.profile"
install_shell_integrations
