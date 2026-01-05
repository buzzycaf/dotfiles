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
  run "ln -s '$src' '$dst'"
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

install_packages() {
  [[ "$NO_PACKAGES" == "1" ]] && {
    log "Skipping package installation (--no-packages)"
    return
  }

  # git intentionally excluded (needed to clone this repo)
  local pkgs=(
    neovim less man-db man-pages
    base-devel curl wget r
