# Gerard's Dotfiles

Packages, tools, and dotfiles managed with mise.

## Before Installing

- **macOS / Linux / WSL:** curl and sudo access.
- **Windows:** WinGet and administrator access when requested.

The installers detect desktops automatically; servers, containers, and WSL get CLI-only setup.
Machine defaults are saved once. To override them, set `env = ["desktop"]` or `env = []`
in `~/.config/mise/miserc.local.toml`.

## Installation

**macOS / Linux / WSL**

```sh
curl -fsSL https://raw.githubusercontent.com/gerardbalaoro/dotfiles/main/scripts/install.sh | sh
```

**Windows PowerShell**

```powershell
irm https://raw.githubusercontent.com/gerardbalaoro/dotfiles/main/scripts/install.ps1 | iex
```

The installers install Git and mise, then bootstrap the machine without requiring secrets.
On macOS, finish Xcode Command Line Tools installation when prompted.
After setup, log out and back in so startup apps inherit the updated PATH.

From an existing checkout, run `./scripts/install.sh` or `.\scripts\install.ps1`.

## Git Identity and SSH Keys

Sign in to 1Password and enable CLI integration, or authenticate the CLI directly on Linux.
Your vault must contain the `Personal/SSH Key` item referenced in [fnox.toml](fnox.toml).
On WSL, install the Windows 1Password app and CLI, with `op.exe` available on PATH.

Restore identity before committing or using SSH authentication:

```sh
mise run dotfiles:identity
```

Ordinary updates preserve restored identity files and keys.

## Updates

From any directory:

```sh
mise run dotfiles:update
```

This pulls changes and reapplies setup. To upgrade installed packages and tools, run
`mise bootstrap --upgrade` from the checkout. On macOS, also run `brew upgrade`.
