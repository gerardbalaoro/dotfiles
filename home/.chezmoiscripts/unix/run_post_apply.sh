#!/bin/sh

# Install mise packages
if command -v mise >/dev/null 2>&1; then
    mise install
fi
