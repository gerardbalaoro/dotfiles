#!/bin/bash

is_wsl() {
    if command -v wslinfo >/dev/null; then
        echo "Detected Windows Subsystem Linux."
        return 0
    else
        return 1
    fi
}

install_utilities() {
    sudo apt install -y zip unzip
}

install_zsh() {
    if command -v zsh >/dev/null; then
        echo "ZSH is already installed."
        return 0
    fi

    echo "Installing ZSH"
    sudo apt install -y zsh
    chsh -s $(which zsh)
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
    if command -v op >/dev/null; then
        echo "1Password CLI is already installed."
        return 0
    fi

    if is_wsl; then
        echo "Skipping 1Password CLI installation on WSL."
        return 0
    fi

    echo "Installing 1Password CLI"
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list && \
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
    sudo apt update && sudo apt install -y 1password-cli
}

install_utilities
install_zsh
install_ohmyposh
install_1password