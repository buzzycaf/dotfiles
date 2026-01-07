#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Dotfiles install / bootstrap script
#
# Responsibilities:
# - Install foundation packages (excluding git)
# - Enable NetworkManager
# - Symlink dotfiles into $HOME and ~/.config
# - Backup existing files before replacing them
#
# Safe to re-run. Supports dry runs and partial execution.
# ------------------------------------------------------------

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

NO_PACKAGES=0
DRY_RUN=0

# -----------------------------
# Helper functions
# -----------------------------

log() {
  printf "\n==> %s\n" "$*"
}

# Execute a command, or just print it in dry-run mode
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

# Ensure required commands exist
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing required command: $1" >&2
    exit 1
  }
}

# Backup an existing file/symlink before overwriting
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    run "mkdir -p '$BACKUP_DIR'"
    log "Backing up $target -> $BACKUP_DIR/"
    run "mv '$target' '$BACKUP_DIR/'"
  fi
}

# Create a symlink, backing up existing target if needed
link_file() {
  local src="$1"
  local dst="$2"
  dst="${dst/#\~/$HOME}"

  # Skip if already correctly linked
  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      log "OK: $dst already linked"
      return 0
    fi
  fi

  backup_if_exists "$dst"
  run "mkdir -p '$(dirname "$dst")'"
  run "ln -sf '$src' '$dst'"
  log "Linked: $dst -> $src"
}

# Link all files in a directory into a target directory
link_dir_contents() {
  local src_dir="$1"
  local dst_dir="$2"
  run "mkdir -p '$dst_dir'"

  shopt -s nullglob
  for item in "$src_dir"/*; do
    local base
    base="$(basename "$item")"
    link_file "$item" "$dst_dir/$base"
  done
}

# -----------------------------
# Main tasks
# -----------------------------

warm_sudo() {
  [[ "$DRY_RUN" == "1" ]] && return
  log "Caching sudo credentials..."
  sudo -v
  # keep-alive: refresh every 60s until script exits
  while true; do sudo -n -v; sleep 60; done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT
}

install_packages() {
  [[ "$NO_PACKAGES" == "1" ]] && {
    log "Skipping package installation (--no-packages)"
    return
  }

  # git intentionally excluded (needed to clone this repo)
  local pkgs=(
    micro less man-db man-pages wl-clipboard
    base-devel curl wget ripgrep fd unzip zip tar
    tree bat which dnsutils
    htop lsof pciutils usbutils
    networkmanager iperf3 tmux
    gnupg openssh rsync ethtool
    dosfstools e2fsprogs ntfs-3g
    fzf zoxide zsh starship fastfetch
  )

  log "Installing foundation packages (excluding git)..."
  run "sudo pacman -S --needed --noconfirm ${pkgs[*]}"
}

install_yay() {
  [[ "$NO_PACKAGES" == "1" ]] && {
    log "Skipping yay install (--no-packages)"
    return
  }

  if command -v yay >/dev/null 2>&1; then
    log "yay already installed"
    return
  fi

  need_cmd git

  log "Installing yay (AUR helper)..."

  run "sudo pacman -S --needed --noconfirm base-devel git"
  need_cmd makepkg

  local yay_dir
  yay_dir="$(mktemp -d /tmp/yay.XXXXXX)"
  run "git clone https://aur.archlinux.org/yay.git '$yay_dir'"
  run "cd '$yay_dir' && makepkg -si --noconfirm --needed"
}

enable_networking() {
  [[ "$NO_PACKAGES" == "1" ]] && {
    log "Skipping NetworkManager enable (--no-packages)"
    return
  }

  log "Enabling NetworkManager..."
  run "sudo systemctl enable --now NetworkManager"
}

link_dotfiles() {
  log "Linking dotfiles from $REPO_DIR"

  [[ -f "$REPO_DIR/zsh/zshrc" ]]     && link_file "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
  [[ -f "$REPO_DIR/zsh/zprofile" ]]  && link_file "$REPO_DIR/zsh/zprofile" "$HOME/.zprofile"

  if [[ -f "$REPO_DIR/starship/starship.toml" ]]; then
    run "mkdir -p '$HOME/.config'"
    link_file "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  fi

  # fastfetch
  if [[ -f "$REPO_DIR/fastfetch/config.jsonc" ]]; then
    link_file "$REPO_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  fi

  # micro editor
  if [[ -d "$REPO_DIR/micro" ]]; then
    link_dir_contents "$REPO_DIR/micro" "$HOME/.config/micro"
  fi

  # tmux
  if [[ -f "$REPO_DIR/tmux/tmux.conf" ]]; then
    link_file "$REPO_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  fi

  # zsh extra files
  run "mkdir -p '$HOME/.zsh'"
  [[ -f "$REPO_DIR/zsh/aliases.zsh" ]] && link_file "$REPO_DIR/zsh/aliases.zsh" "$HOME/.zsh/aliases.zsh"

  [[ -d "$REPO_DIR/hypr"    ]] && link_dir_contents "$REPO_DIR/hypr"    "$HOME/.config/hypr"
  [[ -d "$REPO_DIR/waybar"  ]] && link_dir_contents "$REPO_DIR/waybar"  "$HOME/.config/waybar"
  [[ -d "$REPO_DIR/ghostty" ]] && link_dir_contents "$REPO_DIR/ghostty" "$HOME/.config/ghostty"

  [[ -d "$BACKUP_DIR" ]] && log "Backups saved in: $BACKUP_DIR"
}

set_zsh_shell() {
  [[ "${DOTFILES_SET_SHELL:-0}" != "1" ]] && {
    log "Skipping shell change (set DOTFILES_SET_SHELL=1 to enable)"
    return
  }

  need_cmd zsh
  log "Setting default shell to zsh..."
  run "chsh -s '$(command -v zsh)'"
}

# -----------------------------
# Argument parsing / help
# -----------------------------

usage() {
  cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --no-packages    Skip pacman package installation and service enablement
  --dry-run        Print actions without making any changes
  -h, --help       Show this help message

Environment variables:
  DOTFILES_SET_SHELL=1
      Change default login shell to zsh (opt-in)

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --no-packages
  DOTFILES_SET_SHELL=1 ./install.sh
EOF
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --no-packages) NO_PACKAGES=1 ;;
      --dry-run)     DRY_RUN=1 ;;
      -h|--help)     usage; exit 0 ;;
      *)
        echo "Unknown option: $arg"
        usage
        exit 1
        ;;
    esac
  done
}

# -----------------------------
# Entry point
# -----------------------------

main() {
  parse_args "$@"

  need_cmd pacman
  need_cmd ln
  need_cmd mv
  need_cmd mkdir
  need_cmd date
  need_cmd readlink

  if [[ "$NO_PACKAGES" != "1" ]]; then
    warm_sudo
  fi

  install_packages
  enable_networking
  install_yay
  link_dotfiles
  set_zsh_shell

  log "Done."
}

main "$@"
