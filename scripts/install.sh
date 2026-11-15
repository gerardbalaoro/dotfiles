#!/bin/sh
set -eu

repository_url="${DOTFILES_REPOSITORY:-https://github.com/gerardbalaoro/dotfiles.git}"
mode=connect
mode_selected=false
# Inspect every argument while preserving mise arguments and their order.
argument_count=$#
while [ "$argument_count" -gt 0 ]; do
  argument=$1
  shift
  case "$argument" in
    --connect|--once)
      requested_mode=${argument#--}
      if [ "$mode_selected" = true ] && [ "$mode" != "$requested_mode" ]; then
        echo 'Choose either --connect or --once.' >&2
        exit 1
      fi
      mode=$requested_mode
      mode_selected=true
      ;;
    *) set -- "$@" "$argument" ;;
  esac
  argument_count=$((argument_count - 1))
done
consumer_directory="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/bootstrap-repo"
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
   ! mise --version | awk '{ split($1, v, "."); exit !(v[1] > 2026 || (v[1] == 2026 && (v[2] > 11 || (v[2] == 11 && v[3] >= 7)))) }'; then
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT HUP INT TERM
  curl -fsSL https://mise.run -o "$installer"
  MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh "$installer"
  hash -r
  rm -f "$installer"
  trap - EXIT HUP INT TERM
fi

config_directory="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
# Reject foreign and dangling links before loading or updating their configuration.
if [ -L "$config_directory" ]; then
  if [ "$mode" = once ] || [ ! -d "$config_directory" ] || [ ! -d "$consumer_directory" ] ||
     [ "$(cd "$config_directory" && pwd -P)" != "$(cd "$consumer_directory" && pwd -P)" ]; then
    echo 'Global mise config links elsewhere or is unavailable; resolve that connection before installing.' >&2
    exit 1
  fi
fi
# An empty directory prevents the caller's project configuration from loading.
run_directory=$(mktemp -d)
trap 'rm -rf "$run_directory"' EXIT
trap 'exit 1' HUP INT TERM
mise -C "$run_directory" bootstrap --from "$repository_url" --from-dir "$consumer_directory" --only plugins --yes --update
if [ "$mode" = connect ]; then
  if [ -e "$config_directory" ] && [ ! -L "$config_directory" ]; then
    backup="${config_directory}.backup.$(date +%Y%m%d%H%M%S)"
    [ ! -e "$backup" ] || { echo "Backup already exists: $backup" >&2; exit 1; }
    # Only environment selection is portable without interpreting existing TOML.
    selection_source="$config_directory/miserc.local.toml"
    [ -f "$selection_source" ] || selection_source="$config_directory/miserc.toml"
    if [ -f "$selection_source" ]; then
      destination="$consumer_directory/miserc.local.toml"
      if [ -e "$destination" ]; then
        cmp -s "$selection_source" "$destination" || { echo "Environment selection already exists: $destination" >&2; exit 1; }
      else
        cp "$selection_source" "$destination"
      fi
    fi
    mv "$config_directory" "$backup"
    echo "Previous mise configuration saved to $backup"
    echo 'Previous settings are not activated automatically. Review these files before transferring custom settings; adjust relative paths:'
    find "$backup" -type f -print
  fi
  machine_config="$consumer_directory/miserc.local.toml"
else
  machine_config="$config_directory/miserc.local.toml"
fi
# Save machine defaults once, outside shared Git history.
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

if [ "$mode" = connect ]; then
  mise -C "$run_directory" bootstrap --from "$repository_url" --from-dir "$consumer_directory" --config-dir . --yes --update "$@"
else
  cp "$machine_config" "$consumer_directory/miserc.local.toml"
  MISE_CONFIG_DIR="$consumer_directory" mise -C "$consumer_directory" -E once bootstrap --yes "$@"
fi
echo 'Setup complete. Open a new terminal, then run mise run dotfiles:identity to restore Git identity and SSH keys.'
