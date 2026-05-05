#!/bin/bash

install_mise() {
  if command -v mise >/dev/null; then
    echo "Mise is already installed."
    return 0
  else
    echo "Installing Mise"
    curl https://mise.run | sudo env MISE_INSTALL_PATH=/usr/local/bin/mise sh
  fi
}

install_vite_plus() {
  if [ -d "$HOME/.vite-plus" ]; then
    echo "Vite+ is already installed."
    return 0
  else
    echo "Installing Vite+"
    curl -fsSL https://vite.plus | VP_NODE_MANAGER=no bash
  fi
}

install_mise
install_vite_plus
