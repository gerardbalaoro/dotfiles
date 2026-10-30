#!/bin/sh
set -eu

repository_url="${DOTFILES_REPOSITORY:-https://github.com/gerardbalaoro/dotfiles.git}"
source_directory=
if [ -f "$0" ]; then
  candidate="$(cd "$(dirname "$0")/.." && pwd)"
  if [ -f "$candidate/mise.toml" ] && [ -d "$candidate/layers/common/home" ]; then
    source_directory="$candidate"
  fi
fi
bootstrap_directory="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/bootstrap-repo"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
# Platform configs must be selected even before --from has cloned .miserc.toml.
export MISE_AUTO_ENV=true

if [ "$(uname -s)" = Linux ] && grep -qi microsoft /proc/version; then
  case ",${MISE_ENV:-}," in
    *,wsl,*) ;;
    *) MISE_ENV="${MISE_ENV:+$MISE_ENV,}wsl"; export MISE_ENV ;;
  esac
fi

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

bootstrap() {
  if [ -n "$source_directory" ]; then
    mise -C "$source_directory" bootstrap "$@"
  else
    mise bootstrap --from "$repository_url" --from-dir "$bootstrap_directory" "$@"
  fi
}

# --from needs Git before mise can read the repository's package declarations.
case "$(uname -s)" in
  Darwin)
    if ! xcode-select -p >/dev/null 2>&1; then
      xcode-select --install
      printf 'Finish installing Xcode Command Line Tools, then press Enter: '
      read -r answer </dev/tty
    fi
    ;;
  Linux)
    if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
      if command -v apt-get >/dev/null 2>&1; then
        as_root apt-get update
        as_root apt-get install -y git curl ca-certificates
      elif command -v dnf >/dev/null 2>&1; then
        as_root dnf install -y git curl ca-certificates
      elif command -v pacman >/dev/null 2>&1; then
        as_root pacman -S --needed --noconfirm git curl ca-certificates
      elif command -v zypper >/dev/null 2>&1; then
        as_root zypper --non-interactive install git curl ca-certificates
      elif command -v apk >/dev/null 2>&1; then
        as_root apk add git curl ca-certificates
      else
        echo 'Install Git and curl with your package manager, then rerun this script.' >&2
        exit 1
      fi
    fi
    ;;
  *) echo 'This bootstrap script supports macOS and Linux.' >&2; exit 1 ;;
esac

git --version >/dev/null
if ! command -v mise >/dev/null 2>&1 ||
   ! mise --version | awk '{ split($1, v, "."); exit !(v[1] > 2026 || (v[1] == 2026 && (v[2] > 10 || (v[2] == 10 && v[3] >= 21)))) }'; then
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT HUP INT TERM
  curl -fsSL https://mise.run -o "$installer"
  MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh "$installer"
  hash -r
fi

# Install fnox and 1Password before resolving bootstrap secrets.
if [ -n "$source_directory" ]; then
  mise -C "$source_directory" trust
fi
bootstrap --skip dotfiles,task --update
if [ -z "$source_directory" ]; then
  source_directory="$bootstrap_directory"
  mise -C "$source_directory" trust
fi

if [ "$(uname -s)" = Darwin ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

op_command=op
if [ "$(uname -s)" = Linux ] && grep -qi microsoft /proc/version; then
  op_command=op.exe
fi
if ! command -v "$op_command" >/dev/null 2>&1; then
  echo "$op_command is required; on WSL, install the Windows 1Password CLI and expose it on PATH." >&2
  exit 1
fi
echo 'Grant 1Password access to Personal/SSH Key when prompted.'
mise -C "$source_directory" exec -- fnox exec --only 'DOTFILES_*' -- mise -C "$source_directory" bootstrap
echo 'Setup complete. Open a new terminal to activate your tools.'
