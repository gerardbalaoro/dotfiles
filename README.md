# 💻 Gerard's dotfiles

My personal configuration files managed by [chezmoi](https://www.chezmoi.io/).

## Installation

Set up [chezmoi](https://www.chezmoi.io/) to your machine.
Follow the [installation instructions](https://www.chezmoi.io/install/) from the documentation.

- **Windows (via Winget)**: `winget install twpayne.chezmoi`
- **macOS (via Homebrew)**: `brew install chezmoi`
- **Linux**: `sh -c "$(curl -fsLS get.chezmoi.io)"`

## Usage

Initialize the `dotfiles` local repository.
Ensure that your GitHub authentication credentials are properly configured.

```sh
chezmoi init https://github.com/gerardbalaoro/dotfiles.git
```

Apply the dotfiles to your machine

```sh
chezmoi apply -v
```

## macOS setup

On macOS the bootstrap process installs the Xcode Command Line Tools, Homebrew, and then applies `brew bundle` using the bundled `Brewfile`. The first `chezmoi apply` run will:

- Install Homebrew (if missing) and disable analytics.
- Tap `homebrew/cask` and `homebrew/cask-fonts`, then install the packages declared in `~/Brewfile`.
- Create supporting directories like `~/.nvm` so your existing shell profile works out-of-the-box.
- Configure Git to use the native Keychain credential helper and enable SSH keychain integration.

After bootstrap you can reapply packages at any time:

```sh
brew bundle --file "$HOME/Brewfile"
```

To opt into the optional macOS defaults (Dock autohide, faster key repeat, Finder tweaks), set an environment variable before running `chezmoi apply`:

```sh
CHEZMOI_APPLY_MACOS_DEFAULTS=1 chezmoi apply -v
```

The zsh login shell sources `~/.profile` via `~/.zprofile`, so your existing cross-platform shell configuration continues to work without duplication.
