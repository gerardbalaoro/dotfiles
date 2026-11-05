# Gerard's Dotfiles

Packages, development tools, and dotfiles managed with [mise bootstrap](https://mise.jdx.dev/bootstrap.html).

## Bootstrap

Before starting, prepare:

- **macOS / Linux:** curl and sudo access.
- **Windows:** WinGet and administrator access when requested.

The bootstrap scripts install Git and mise, then provision packages, tools, and ordinary dotfiles.
Bootstrap does not require access to secrets. Git identity and SSH keys are restored separately.
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

With mise already installed, bootstrap directly:

```sh
mise bootstrap --from https://github.com/gerardbalaoro/dotfiles.git
```

From an existing checkout, use its bootstrap script:

```sh
./scripts/bootstrap.sh
```

```powershell
.\scripts\bootstrap.ps1
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
Existing machines need one identity restore after adopting this split to populate the new Git identity include.
On a new machine, configure identity before committing or using SSH authentication.

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
