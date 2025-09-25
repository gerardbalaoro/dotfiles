#!/bin/bash

install_node() {
    if command -v nvm >/dev/null; then
        echo "NVM is already installed."
        return 0
    else
        echo "Installing NVM"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    fi

    if command -v pnpm >/dev/null; then
        echo "PNPM is already installed."
        return 0
    else
        echo "Installing PNPM"
        curl -fsSL https://get.pnpm.io/install.sh | sh -
    fi

    if command -v bun >/dev/null; then
        echo "Bun is already installed."
        return 0
    else
        echo "Installing Bun"
        curl -fsSL https://bun.sh/install | bash
    fi
}

install_node