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

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "ERROR: Do not run Archbento installer as root. Run: ./install.sh" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

NO_PACKAGES=0
DRY_RUN=0
INCLUDE_GUI=0
INCLUDE_GUI_TOOLS=0

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
    eval -- "$@"
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
  --gui-tools   Install optional desktop tools (file manager, launcher, etc.)
  -h, --help       Show this help message
  --gui            Install Hyprland GUI stack (desktop packages)

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
      --gui)
        INCLUDE_GUI=1
        INCLUDE_GUI_TOOLS=1
        ;;
      -h|--help)     usage; exit 0 ;;
      *)
        echo "Unknown option: $arg"
        usage
        exit 1
        ;;
    esac
  done
}

source_module() {
  local module="$1"
  local path="$REPO_DIR/install/$module"

  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing module: $path" >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$path"
}

# -----------------------------
# Entry point
# -----------------------------

main() {
  parse_args "$@"

  source_module "dotfiles.sh"
  source_module "core.sh"
  source_module "gui.sh"

  need_cmd pacman
  need_cmd ln
  need_cmd mv
  need_cmd mkdir
  need_cmd date
  need_cmd readlink

  if [[ "$NO_PACKAGES" != "1" ]]; then
    warm_sudo
  fi

  # Core system install
  core_install_packages
  core_install_yay
  core_enable_vt_switching "$USER"

  # Optional GUI install
  if [[ "$INCLUDE_GUI" == "1" ]]; then
    gui_install_packages
    gui_enable_services
    [[ "$INCLUDE_GUI_TOOLS" == "1" ]] && gui_install_tools
    gui_notes
  fi

  dotfiles_link_all
  set_zsh_shell

  log "Done."
}

main "$@"
