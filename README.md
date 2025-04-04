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
