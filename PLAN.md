# macOS implementation plan for this chezmoi setup

This plan adds first-class macOS support to your dotfiles while reusing as much of the existing cross‑platform logic as possible. It introduces a clean bootstrap, package management via Homebrew, shell setup (zsh + oh‑my‑posh), Git/SSH credential behavior on macOS, fonts, and optional macOS defaults.

## Goals

- One‑command bootstrap on a fresh macOS machine using chezmoi
- Consistent shell experience: zsh + oh‑my‑posh using `~/.config/oh-my-posh/main.omp.json`
- Package install with Homebrew and `brew bundle` (Brewfile)
- macOS‑appropriate Git credential helper and SSH agent/Keychain integration
- Optional sensible macOS defaults (Dock, Finder, key repeat, etc.)
- Safe to run repeatedly; idempotent, dry‑runnable via chezmoi

## Assumptions

- macOS 12+ (Monterey) or newer with zsh as default shell
- You will use Homebrew (Intel or Apple Silicon). Brew will be installed if missing.
- You want iTerm2 + Nerd Font optional but recommended for oh‑my‑posh glyphs
- Existing cross‑platform files (`.profile.tmpl`, `dot_zshrc`, oh‑my‑posh config) should be reused

## High‑level approach

- Add macOS‑specific run‑once scripts under `.chezmoiscripts/darwin/`
- Keep the current shell/profile layout; add a small `~/.zprofile` to source `~/.profile` for login shells
- Add a Brewfile and wire it to `brew bundle` in the run‑once script
- Tweak `dot_gitconfig.tmpl` and `dot_ssh/config.tmpl` with small macOS conditionals
- Add an optional `.macos` defaults script (run once, opt‑in)

## Files to add/change

1) .chezmoiscripts/darwin

- `home/.chezmoiscripts/darwin/run_once_before_install_homebrew.sh`
  - Purpose: Install Xcode CLT and Homebrew if missing; set basic taps
  - Behavior:
    - Check `xcode-select -p`; run `xcode-select --install` if needed (non-blocking if already installed)
    - Install brew via official script if `brew` is missing
    - Configure `brew analytics off`

- `home/.chezmoiscripts/darwin/run_once_before_brew_bundle.sh`
  - Purpose: Ensure Brew is healthy before bundling
  - Behavior: `brew update`, `brew doctor || true`, `brew tap homebrew/cask-fonts`

- `home/.chezmoiscripts/darwin/run_once_after_brew_bundle.sh`
  - Purpose: Small post‑install fixes
  - Behavior:
    - Ensure `mkdir -p "$HOME/.nvm"` so your `.profile.tmpl` NVM load path is valid
    - Reset font cache if a Nerd Font was installed (optional)

- `home/.chezmoiscripts/darwin/run_once_after_macos_defaults.sh` (optional)
  - Purpose: Apply a curated set of `defaults write` macOS settings
  - Behavior: Dock autohide, fast key repeat, Finder show extensions, etc.; guarded with `read -p` or environment flag so it’s easy to skip

2) Brewfile

- `home/Brewfile`
  - Purpose: Declarative package list for macOS via `brew bundle`
  - Suggested baseline:
    - Taps:
      - `tap "homebrew/cask"`
      - `tap "homebrew/cask-fonts"`
    - CLI:
      - `brew "git"`
      - `brew "coreutils"` (better GNU utils)
      - `brew "gnu-sed"`
      - `brew "gnupg"`
      - `brew "fzf"`, `brew "ripgrep"`, `brew "fd"`
      - `brew "oh-my-posh"`
      - `brew "direnv"` (optional)
      - `brew "jq"`, `brew "yq"`
      - `brew "openssl"` (for crypto libs)
    - Runtimes/tools (optional):
      - `brew "mise"` or `brew "asdf"` (if you prefer runtime managers)
      - or keep your current NVM/Bun pattern (NVM via brew: `brew "nvm"`)
    - GUI apps (casks, optional):
      - `cask "iterm2"`
      - `cask "visual-studio-code"`
      - `cask "rectangle"`
      - `cask "alt-tab"`
      - `cask "1password"` (app; optional but required for SSH agent)
      - `cask "1password-cli"` (CLI; optional for automation)
      - `cask "font-meslo-lg-nerd-font"` (or your preferred Nerd Font for oh‑my‑posh)

3) zsh login profile unification

- `home/dot_zprofile.tmpl`
  - Purpose: Ensure login shells load the same env as interactive shells
  - Content: source `~/.profile` if present

4) Git config tweaks

- Update `home/dot_gitconfig.tmpl` to prefer Keychain on macOS:
  - Add conditional block:
    - When `.chezmoi.os == "darwin"` → `[credential] helper = osxkeychain`
  - Keep existing Linux/WSL conditional for GCM as is

5) SSH config (Keychain integration)

- Update `home/dot_ssh/config.tmpl` to add macOS defaults for agent + keychain:
  - Under a darwin conditional, add:
    - `Host *` → `AddKeysToAgent yes`, `UseKeychain yes`, `IdentityFile ~/.ssh/id_ed25519`

## 1Password integration (optional)

You can integrate 1Password in three complementary ways: SSH agent, Git HTTPS credential helper, and Git commit signing with SSH.

1) Packages (Brewfile)

- Add to your Brewfile (see above):
  - `cask "1password"`
  - `cask "1password-cli"`
  - Optionally add `tap "1password/tap"` if you prefer 1Password’s tap (not usually required for the casks above).

2) Enable SSH agent in 1Password app

- Open 1Password → Settings/Preferences → Developer
- Enable “Use SSH agent” and add your SSH key(s) to 1Password
- Optionally enable “Allow this key to be used for signing” if you’ll sign Git commits with SSH

3) Wire SSH to 1Password’s agent

- 1Password exposes a stable socket symlink at `~/.1password/agent.sock`.
- Extend your SSH config under a darwin block:

```sshconfig
{{- if eq .chezmoi.os "darwin" -}}
Host *
  IdentityAgent ~/.1password/agent.sock
{{- end -}}
```

- Optional (belt‑and‑suspenders): set `SSH_AUTH_SOCK` in your profile on macOS so non‑SSH tools also find the socket:

```bash
{{- if eq .chezmoi.os "darwin" }}
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
{{- end }}
```

4) Git over SSH with 1Password

- No extra Git config is required beyond the SSH agent wiring above. Git will use the SSH agent for auth when pushing/pulling via SSH remotes.

5) Git HTTPS credentials via 1Password (alternative to macOS Keychain)

- Default in this plan for macOS is the native Keychain (`osxkeychain`). If you prefer 1Password to store/retrieve HTTPS credentials:

```toml
{{- if and (eq .chezmoi.os "darwin") (.onepassword.useCredentialHelper) }}
[credential]
	helper = !op-credential-helper --git-credential
{{- else if eq .chezmoi.os "darwin" }}
[credential]
	helper = osxkeychain
{{- end }}
```

- To drive this, add to `home/.chezmoidata.toml`:

```toml
[onepassword]
useCredentialHelper = false
```

6) Git commit signing with SSH keys in 1Password

- Configure Git to use SSH‑based signing and point it to an allowed signers file. Example run‑once script sketch:

```sh
#!/usr/bin/env bash
set -euo pipefail

# Create allowed signers with your email and public key (from 1Password)
mkdir -p "$HOME/.ssh"
if ! grep -q "you@example.com" "$HOME/.ssh/allowed_signers" 2>/dev/null; then
  echo "you@example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..." >> "$HOME/.ssh/allowed_signers"
fi

git config --global gpg.format ssh
git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"
# Set your public signing key string (from 1Password’s public key field)
git config --global user.signingkey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."
git config --global commit.gpgsign true
```

- Upload the same SSH public key to GitHub as a “Signing key” so signatures verify on GitHub.

Notes

- When using 1Password as SSH agent, you generally don’t need `AddKeysToAgent yes` for keys stored in 1Password, but it’s harmless to keep for non‑1Password keys.
- The `op-credential-helper` binary is installed with 1Password CLI; ensure `op` is in PATH.

6) macOS defaults (optional but nice)

- `home/.macos` or fold into `run_once_after_macos_defaults.sh`
  - Examples:
    - `defaults write -g InitialKeyRepeat -int 15`
    - `defaults write -g KeyRepeat -int 2`
    - `defaults write com.apple.finder AppleShowAllExtensions -bool true`
    - `defaults write com.apple.dock autohide -bool true; killall Dock`
  - Gate via prompt or `CHEZMOI_APPLY_MACOS_DEFAULTS=1` env var

## How it wires together

- On first apply, chezmoi will execute darwin run‑once scripts in order. Recommended sequence:
  1. Install Xcode CLT + Homebrew (run_once_before_install_homebrew.sh)
  2. Prepare brew (run_once_before_brew_bundle.sh)
  3. Deploy `home/Brewfile` and run `brew bundle --file "$HOME/Brewfile"`
  4. Post‑bundle fixes (run_once_after_brew_bundle.sh)
  5. Optionally apply macOS defaults (run_once_after_macos_defaults.sh) if enabled
  6. Shell: `~/.zprofile` ensures `~/.profile` is sourced for login shells; `~/.zshrc` already sources `~/.profile`
  7. oh‑my‑posh uses `~/.config/oh-my-posh/main.omp.json` (already present)

## Step‑by‑step bootstrap (macOS)

These commands are for documentation; your scripts will automate them when `chezmoi apply` runs.

1) Install chezmoi and initialize

```sh
brew install chezmoi
chezmoi init https://github.com/gerardbalaoro/dotfiles.git
chezmoi apply --dry-run --verbose
chezmoi apply --verbose
```

2) Validate brew and fonts

```sh
brew --version
brew bundle check --file "$HOME/Brewfile" || brew bundle --file "$HOME/Brewfile"
```

3) Set iTerm2 to use your Nerd Font (if installed) and verify oh‑my‑posh glyphs

## Acceptance criteria

- chezmoi apply completes on macOS without errors on a fresh machine
- `brew bundle` installs declared packages; re‑running is idempotent
- zsh prompt renders with oh‑my‑posh using your existing theme
- `git` uses `osxkeychain` on macOS; WSL/Windows logic remains unchanged
- SSH automatically adds keys to agent and uses Keychain on macOS
- Optional macOS defaults can be applied or skipped safely

## Implementation checklist (repo changes)

- [ ] Add: `home/.chezmoiscripts/darwin/run_once_before_install_homebrew.sh`
- [ ] Add: `home/.chezmoiscripts/darwin/run_once_before_brew_bundle.sh`
- [ ] Add: `home/.chezmoiscripts/darwin/run_once_after_brew_bundle.sh`
- [ ] (Optional) Add: `home/.chezmoiscripts/darwin/run_once_after_macos_defaults.sh` or `home/.macos`
- [ ] Add: `home/Brewfile`
- [ ] Add: `home/dot_zprofile.tmpl` (source `~/.profile`)
- [ ] Update: `home/dot_gitconfig.tmpl` → add darwin `osxkeychain` block
- [ ] Update: `home/dot_ssh/config.tmpl` → add darwin Keychain/agent block
- [ ] README.md → add macOS apply blurb (optional)

## Snippet sketches (for later implementation)

zprofile (minimal)

```zsh
# ~/.zprofile
if [ -f "$HOME/.profile" ]; then
  . "$HOME/.profile"
fi
```

run_once_before_install_homebrew.sh

```sh
#!/usr/bin/env bash
set -euo pipefail

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
fi

if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon and Intel
  BREW_PREFIX="$(/usr/bin/arch -arm64 2>/dev/null && echo "/opt/homebrew" || echo "/usr/local")"
  test -d "$BREW_PREFIX/bin" && eval "\"$BREW_PREFIX/bin/brew\" shellenv" >> "$HOME/.zprofile"
fi

brew analytics off || true
```

run_once_before_brew_bundle.sh

```sh
#!/usr/bin/env bash
set -euo pipefail
brew update
brew doctor || true
brew tap homebrew/cask-fonts || true
```

run_once_after_brew_bundle.sh

```sh
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.nvm"
```

Git config (delta inside `dot_gitconfig.tmpl`)

```toml
{{- if eq .chezmoi.os "darwin" }}
[credential]
	helper = osxkeychain
{{- end }}
```

SSH config (delta inside `dot_ssh/config.tmpl`)

```sshconfig
{{- if eq .chezmoi.os "darwin" -}}
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
{{- end -}}
```

## Notes & future ideas

- Consider `brew bundle dump --file "$HOME/Brewfile" --force` to capture local state
- If you adopt 1Password for SSH/Git Signing, add a darwin block to wire the agent
- If you prefer not to manage GUI apps, keep Brewfile CLI‑only
- You can split Brewfile per host using chezmoi templates (`Brewfile.tmpl`) if needed
