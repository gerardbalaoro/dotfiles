#!/bin/sh
set -eu

repository_url="${DOTFILES_REPOSITORY:-https://github.com/gerardbalaoro/dotfiles.git}"
source_directory=
if [ -f "$0" ]; then
  candidate="$(cd "$(dirname "$0")/.." && pwd)"
  if [ -f "$candidate/mise.toml" ] && [ -d "$candidate/tools/mise" ]; then
    source_directory="$candidate"
  fi
fi
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
# Platform configs must be selected even before --from has cloned .miserc.toml.
export MISE_AUTO_ENV=true

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
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
  *) echo 'This installer supports macOS and Linux.' >&2; exit 1 ;;
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

# Save defaults once; miserc.local.toml and explicit mise selections override them.
machine_config="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}/miserc.toml"
if [ ! -e "$machine_config" ]; then
  selected='[]'
  case "$(uname -s)" in
    Darwin) selected='["desktop"]' ;;
    Linux)
      if [ -n "${WSL_INTEROP:-}${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version; then
        selected='["wsl"]'
      elif [ -e /.dockerenv ] || [ -e /run/.containerenv ] || [ -n "${container:-}" ]; then
        selected='[]'
      elif [ "${XDG_SESSION_TYPE:-}" = x11 ] || [ "${XDG_SESSION_TYPE:-}" = wayland ] ||
           [ -n "${XDG_CURRENT_DESKTOP:-}" ] || [ -e /etc/systemd/system/display-manager.service ]; then
        selected='["desktop"]'
      else
        # Installed sessions also identify desktops when this runs over SSH.
        for session in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
          if [ -f "$session" ]; then
            selected='["desktop"]'
            break
          fi
        done
      fi
      ;;
  esac
  mkdir -p "$(dirname "$machine_config")"
  printf 'env = %s\n' "$selected" > "$machine_config"
fi

if [ -n "$source_directory" ]; then
  mise -C "$source_directory" bootstrap --yes --update "$@"
else
  mise bootstrap --from "$repository_url" --yes --update "$@"
fi
echo 'Setup complete. Open a new terminal, then run mise run dotfiles:identity to restore Git identity and SSH keys.'
