# Gerard's dotfiles

My personal configuration files managed by [chezmoi](https://www.chezmoi.io/),
with packages and tools provisioned by [mise bootstrap](https://mise.jdx.dev/bootstrap.html).

## Installation

Requires Git and mise **2026.10.11 or newer**. Unix setup also needs curl and
sudo access for system packages. On Windows, WinGet must be available; some
installers and Windows settings request administrator access.

**Unix (macOS/Linux)** — install Git first using the system package manager
(Xcode Command Line Tools on macOS), then install mise:

```sh
curl -fsSL https://mise.run | sh
~/.local/bin/mise bootstrap --from https://github.com/gerardbalaoro/dotfiles.git --skip task
```

**Windows (PowerShell)**

```powershell
winget install --id Git.Git --exact
winget install --id jdx.mise --exact
```

Open a new terminal so Git and mise are on PATH, then run:

```powershell
mise bootstrap --from https://github.com/gerardbalaoro/dotfiles.git --skip task
```

This first pass installs packages, development tools, AI CLIs, and the
1Password CLI. Sign in to 1Password and enable CLI integration (or establish
a CLI session on Linux). WSL uses the Windows `op.exe`, which must be installed,
authenticated, and available on PATH. Git and SSH templates need access to the
`Personal/SSH Key` item.

Finish setup from the same repository:

```sh
mise bootstrap --from https://github.com/gerardbalaoro/dotfiles.git
```

On Unix, use `~/.local/bin/mise` if mise is not yet on PATH. The bootstrap task
initializes chezmoi against mise's checkout, applies the dotfiles, and saves
that source location. Open a new terminal afterwards to activate the tools.

## Existing checkout and updates

To use an existing checkout instead of creating mise's default checkout:

```sh
cd /path/to/dotfiles
mise trust
mise bootstrap --update
```

Pull changes before running this command in a manually managed checkout.
For a checkout created with `--from`, use the same URL with `--update` to
fast-forward it and refresh package metadata:

```sh
mise bootstrap --from https://github.com/gerardbalaoro/dotfiles.git --update
```

Bootstrap installs missing packages; add `--upgrade` when you also want to
upgrade installed packages and tools. macOS's Homebrew script only installs
missing packages; use `brew upgrade` explicitly for those packages.
`chezmoi apply` still applies file changes, but does not provision system packages.

## Ownership

- `bootstrap/packages.toml`: apt, dnf, pacman, zypper, apk and WinGet packages.
- `bootstrap/macos.sh`: guarded Homebrew installs on Intel and Apple Silicon.
  mise invokes this before its package phase, without a different-owner wrapper.
- `bootstrap/linux.sh`: the existing native 1Password and Oh My Posh installers,
  invoked after packages and skipped when the commands already exist.
- `home/dot_config/mise/conf.d/`: shared development and AI CLI tools, including
  Codex, OpenCode, Paseo and T3 nightly, for Linux, macOS and Windows. The root config
  includes these files, and chezmoi deploys them as global mise configuration.
- chezmoi scripts: fonts, WSL Hello sudo, Linux login-shell setup, Windows
  preferences, Scoop, the custom Oh My Posh install, and the Codex Store app.
  OpenCode Desktop is a WinGet package; desktop apps are separate from AI CLIs.

AI application settings, custom OpenCode agents/themes, experimental OpenCode
flags and the forced-permission Codex alias are no longer managed here. Shared
skills and repository instructions remain. Removing source files does not delete
previously deployed copies: existing machines should remove unwanted old
OpenCode configuration from `~/.config/opencode` separately, preserving any
locally maintained settings or skills. No Codex or Claude settings files were
tracked in this repository.

## Preview

From the checkout, preview provisioning and then chezmoi's file changes:

```sh
mise bootstrap --dry-run
chezmoi --source . diff
```

The first command prints hooks and tasks without executing them; it cannot show
the changes inside a Homebrew script or `chezmoi apply`. The second needs chezmoi
installed and 1Password access for secret-backed templates. A `--from` dry run
without an existing checkout only previews cloning the repository.
