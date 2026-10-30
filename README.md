# Gerard's Dotfiles

Packages, development tools, and dotfiles managed with [mise bootstrap](https://mise.jdx.dev/bootstrap.html).

## Bootstrap

Before starting, prepare:

- **1Password:** an account containing the `Personal/SSH Key` item.
- **macOS / Linux:** curl and sudo access.
- **Windows:** WinGet and administrator access when requested.
- **WSL:** the Windows 1Password app and CLI, with `op.exe` available on WSL's PATH.

The bootstrap scripts install Git and mise, provision packages and tools, and pause for 1Password access before applying dotfiles.
Sign in to 1Password and enable CLI integration, or use an authenticated CLI session on Linux.
Windows bootstrap uses the [official mise installer](https://mise.jdx.dev/installing-mise.html#windows-script) when mise is missing or too old.

**macOS / Linux / WSL**

```sh
curl -fsSL https://raw.githubusercontent.com/gerardbalaoro/dotfiles/main/scripts/bootstrap.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/gerardbalaoro/dotfiles/main/scripts/bootstrap.ps1 | iex
```

On macOS, complete Xcode Command Line Tools installation when prompted.
Open a new terminal after setup to activate tools and shell integrations.

From an existing checkout, use its bootstrap script:

```sh
./scripts/bootstrap.sh
```

```powershell
.\scripts\bootstrap.ps1
```

## Layers

Each layer contains a `home/` tree and any packages or setup scripts it needs:

```text
layers/
  common/   Shared tools, Git/SSH, skills, application settings, and fonts
  unix/     Bash, Zsh, .profile, and shell integrations
  linux/    Linux packages, native integrations, and login shell
  macos/    Homebrew and Ghostty
  windows/  WinGet, PowerShell/Clink, desktop apps, and Windows preferences
  wsl/      Windows 1Password integration and WSL Hello sudo
scripts/
  bootstrap.sh
  bootstrap.ps1
```

| Environment | Selected Layers |
| --- | --- |
| Native Linux | common + unix + linux |
| WSL | common + unix + linux + wsl |
| macOS | common + unix + macos |
| Windows | common + windows |

Shared rules live in [mise.toml](mise.toml); `mise.<layer>.toml` defines layer-specific rules.
Mise selects Unix and OS layers automatically.
WSL bootstrap saves its selection in the checkout's ignored `.miserc.local.toml`.
If that file already exists, add `wsl` to its `env` list.
You can also select WSL explicitly with `mise -E wsl ...`.

Layers are additive, and each target file belongs to one layer.
Keep small platform differences in a shared template to avoid competing copies.

## Updates

To update a checkout created by remote bootstrap, rerun the remote bootstrap command above.

For a manually managed checkout, pull changes before provisioning:

```sh
git pull --ff-only
mise bootstrap --update
```

Bootstrap installs missing packages and tools.
Add `--upgrade` to upgrade managed tools and native packages.
On macOS, run `brew upgrade` separately.

## Dotfile Changes

Edit sources under `layers/<layer>/home/`.
Ordinary files deploy automatically through [dotfile groups](https://mise.jdx.dev/dotfiles/groups.html).
For example, `layers/unix/home/dot-bashrc` becomes `~/.bashrc`.
Declare Tera templates, permission exceptions, and file removals in the corresponding mise config.

Dotfiles are copied.
Reapplying replaces direct edits to managed targets and preserves unmanaged files.
From the checkout, open a file's source and apply changes:

```sh
mise dot edit ~/.zshrc
mise dot apply
```

## Preview

From the checkout, preview provisioning or dotfile changes:

```sh
mise bootstrap --dry-run
mise dot apply --dry-run
```

Dry runs print setup commands without executing their contents or reading 1Password values.
Status and diff commands render templates and can request 1Password access.
Private-key diffs can contain secrets.
