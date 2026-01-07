#!/usr/bin/env bash
set -euo pipefail

core_install_packages() {
  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping core package install (--no-packages)"; return; }

  # Core packages only (no GUI). git intentionally excluded.
  local pkgs=(
    less man-db man-pages
    base-devel curl wget ripgrep fd unzip zip tar
    tree bat which dnsutils
    htop lsof pciutils usbutils
    networkmanager iperf3
    gnupg openssh rsync ethtool
    dosfstools e2fsprogs ntfs-3g
    fzf zoxide zsh starship fastfetch
    micro tmux
    wl-clipboard
  )

  log "Installing core packages (excluding git)..."
  run "sudo pacman -S --needed --noconfirm ${pkgs[*]}"
}

core_enable_networking() {
  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping enable networking (--no-packages)"; return; }
  log "Enabling NetworkManager..."
  run "sudo systemctl enable --now NetworkManager"
}

core_install_yay() {
  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping yay install (--no-packages)"; return; }

  if command -v yay >/dev/null 2>&1; then
    log "yay already installed"
    return 0
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
