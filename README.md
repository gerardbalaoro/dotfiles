# Gerard's Dotfiles

Packages, development tools, and dotfiles managed with [mise bootstrap](https://mise.jdx.dev/bootstrap.html).

## Bootstrap

Before starting, prepare:

- **macOS / Linux:** curl and sudo access.
- **Windows:** WinGet and administrator access when requested.

The installers install Git and mise, then provision packages, tools, and ordinary dotfiles.
Bootstrap does not require access to secrets. Git identity and SSH keys are restored separately.
Windows bootstrap uses the [official mise installer](https://mise.jdx.dev/installing-mise.html#windows-script) when mise is missing or too old.

**macOS / Linux / WSL**

```sh
curl -fsSL https://raw.githubusercontent.com/gerardbalaoro/dotfiles/main/scripts/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/gerardbalaoro/dotfiles/main/scripts/install.ps1 | iex
```

On macOS, complete Xcode Command Line Tools installation when prompted.
Open a new terminal after setup to activate tools and shell integrations.

With mise already installed, select machine roles as described below, then bootstrap directly:

```sh
mise bootstrap --from https://github.com/gerardbalaoro/dotfiles.git
```

From an existing checkout, use its installer:

```sh
./scripts/install.sh
```

```powershell
.\scripts\install.ps1
```

## Identity

After bootstrap, sign in to 1Password and enable CLI integration, or authenticate the CLI on Linux.
The account must contain the `Personal/SSH Key` item referenced in [fnox.toml](fnox.toml).
On WSL, install the Windows 1Password app and CLI, with `op.exe` available on PATH.

From any directory, restore Git identity, signing configuration, and SSH keys:

```sh
mise run dotfiles:identity
```

The task fetches values through fnox before applying only the identity files.
Authentication failures leave those files untouched.
Ordinary bootstrap and updates leave restored identity files and keys in place.
Git settings already present in `~/.gitconfig` take precedence over shared settings; remove obsolete overrides manually when needed.
Existing machines need one identity restore after adopting this split to populate the new Git identity include.
On a new machine, configure identity before committing or using SSH authentication.

## Structure

Configuration lives under `tools/`; platform provisioning lives under `environments/`:

```text
tools/
  git/                Shared Git settings and identity template
  ssh/                SSH configuration and key templates
  mise/               Global mise settings, tools, and dotfiles tasks
  shell/              Bash, Zsh, and shared Unix environment
  powershell/         PowerShell profiles
  clink/              Clink settings
  ghostty/            Ghostty configuration and themes
  windows-terminal/   Windows Terminal settings
  oh-my-posh/         Prompt theme, font archives, and font setup
  skillshare/         Skillshare configuration, skills, and agents
  agents/             Shared agent instructions
environments/
  linux/              Linux packages and setup
  macos/              Homebrew setup
  windows/            Windows packages, preferences, and setup
  wsl/                Windows interoperability and WSL Hello sudo
scripts/              Installers and update commands
```

The root `mise.toml` maps shared files into place.
Root `mise.<os>.toml` entrypoints select platform packages and configuration automatically.
Unix shell configuration loads automatically on Linux and macOS.
All configuration is copied; templates render machine-specific values.
Shared Git settings deploy to `~/.config/git/config`; `~/.gitconfig` remains available for local settings and credential helpers.

## Machine Settings

Base bootstrap installs CLI tools and configuration.
Select `desktop` to add GUI applications, desktop preferences, terminal configuration, and Oh My Posh fonts.
Windows applications and macOS Ghostty, VS Code, and 1Password desktop are included in that role.
Existing Linux package support remains unchanged.

Save the choice in `~/.config/mise/miserc.local.toml` on each workstation:

```toml
env = ["desktop"]
```

This file stays on the machine; bootstrap does not overwrite it.
For one run, select the role explicitly:

```sh
mise -E desktop bootstrap
```

WSL setup saves `wsl` in the checkout's ignored `.miserc.local.toml`.
For direct setup on WSL, select it with `mise -E wsl bootstrap`.
The `identity` environment is selected only by `dotfiles:identity`; do not save it as a default.

## Updates

After bootstrap, update from any directory:

```sh
mise run dotfiles:update
```

The task pulls the checkout it was deployed from and reapplies bootstrap without accessing secrets.
It works with remote bootstrap checkouts and manual clones.

On existing machines, install the task once from the dotfiles checkout:

```sh
git pull --ff-only
mise bootstrap --update
```

Bootstrap installs missing packages and tools.
To upgrade managed tools and native packages, run the checkout command with `--upgrade` added.
On macOS, run `brew upgrade` separately.

## Dotfile Changes

Edit configuration in its tool directory, then apply through mise.
For example, `tools/shell/bashrc` deploys to `~/.bashrc`.
The root mise files declare destinations, templates, permissions, and platform conditions.
The mise and Skillshare bundles deploy ordinary files through [dotfile groups](https://mise.jdx.dev/dotfiles/groups.html).

Dotfiles are copied.
Reapplying replaces direct edits to managed targets and preserves unmanaged files.
From the checkout, open a file's source and apply changes:

```sh
mise dot edit ~/.zshrc
mise dot apply
```

On WSL, mise adds the layer's `op` wrapper to PATH so fnox uses the Windows `op.exe`.

## Preview

From the checkout, preview provisioning or dotfile changes:

```sh
mise bootstrap --dry-run
mise dot apply --dry-run
```

Dry runs print setup commands without executing their contents or reading 1Password values.
The explicit `identity` environment contains secret-backed templates; ordinary previews do not load it.
Fnox supplies identity values to the subprocess; `fnox.toml` contains only references.
