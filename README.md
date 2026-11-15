# Gerard's Dotfiles

Packages, tools, and dotfiles managed with mise.

## Before Installing

- **macOS / Linux / WSL:** curl and sudo access.
- **Windows:** WinGet and administrator access when requested.

Connected installation is the default. The installers fetch published files into mise's consumer checkout, separate from development clones.
Global mise configuration links to that checkout. Updates run only when requested.

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

From a development checkout, run `./scripts/install.sh --connect` or `.\scripts\install.ps1 -Connect`.
These commands install from GitHub, not from the development checkout.

For deployment without an ongoing connection, run `./scripts/install.sh --once` or `.\scripts\install.ps1 -Once`.
For a downloaded Unix installer, use `sh install.sh --once`.
Apply-once installation retains the consumer checkout but copies standalone global tool configuration.
An existing connected installation must be disconnected before apply-once installation.

The consumer checkout is `$MISE_DATA_DIR/bootstrap-repo`, normally `~/.local/share/mise/bootstrap-repo` on Unix or `%LOCALAPPDATA%\mise\bootstrap-repo` on Windows.
Set `DOTFILES_REPOSITORY` to select another published repository or a branch URL with `?ref=<branch>`.

Existing global configuration is backed up beside `~/.config/mise` before connection.
Machine environment selections carry over to the consumer checkout.
Other existing configuration stays in the backup, including local overrides, custom fragments, and lockfiles.
The installer lists those files for review. It does not activate them as overrides of the published configuration.
Transfer custom settings selectively, and adjust relative includes and paths for their new locations.

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
mise bootstrap --update
```

For connected installations, this pulls the consumer checkout and applies setup.
Run it outside development clones to avoid loading project overrides.
For apply-once installations, rerun the apply-once installer to consume published changes.

To try unpublished changes, edit the consumer checkout and run `mise dot apply` for dotfiles or `mise bootstrap` for full setup.
Commit, stash, or discard consumer edits before pulling updates.
Development clones load development tools only; they do not declare machine deployment.

`mise use -g <tool>` writes shared declarations into the connected checkout.
Review, commit, and push those changes to publish them.
Use `config.local.toml` for machine-only configuration.
Use `mise dot add <target>` to capture edits from managed copies; edit template sources directly.

To upgrade installed packages and tools, run `mise bootstrap --upgrade`.
On macOS, also run `brew upgrade`.
