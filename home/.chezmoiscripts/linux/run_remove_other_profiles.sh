#!/bin/sh

# Remove .bash_profile and .bash_login from the home directory if they exist
rm -f "$HOME/.bash_profile" "$HOME/.bash_login"