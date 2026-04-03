# Gerard's dotfiles

My personal configuration files managed by [chezmoi](https://www.chezmoi.io/).

## Installation

**Unix (macOS/Linux)**
```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gerardbalaoro
```

**Windows (PowerShell)**
```powershell
irm https://get.chezmoi.io/ps1 | powershell -c "& { $(iex ($input | Out-String)) } -- init --apply gerardbalaoro"
```
