#!/bin/bash

if ! command -v claude &> /dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

if ! command -v copilot &> /dev/null; then
    curl -fsSL https://gh.io/copilot-install | bash
fi

if ! command -v opencode &> /dev/null; then
    curl -fsSL https://opencode.ai/install | bash
fi
