#!/bin/bash

install_mise() {
  if command -v mise >/dev/null; then
    echo "Mise is already installed."
    return 0
  else
    echo "Installing Mise"
    curl https://mise.run | sh
  fi
}

install_mise