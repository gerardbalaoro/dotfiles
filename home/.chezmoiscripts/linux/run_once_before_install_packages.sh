#!/bin/bash

if command -v oh-my-posh >/dev/null; then
    echo "Oh My Posh is already installed."
else
    curl -s https://ohmyposh.dev/install.sh | bash -s
fi