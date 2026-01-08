#!/usr/bin/env bash
set -euo pipefail

core_install_packages() {
  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping core package install "; return; }

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

core_enable_vt_switching() {
  # Enables passwordless VT switching via `sudo chvt` for a dedicated group.
  # Intended for Wayland compositors (Hyprland) where Ctrl+Alt+Fn VT switching may not work.

  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping VT switching setup (--no-packages)"; return; }

  local user="${1:-${SUDO_USER:-}}"
  local group="vt-switch"
  local chvt_bin="/usr/bin/chvt"
  local sudoers_file="/etc/sudoers.d/archbento-chvt"

  if [[ -z "$user" ]]; then
    log "ERROR: core_enable_vt_switching: no user provided and SUDO_USER is empty"
    return 1
  fi

  if ! id -u "$user" >/dev/null 2>&1; then
    log "ERROR: core_enable_vt_switching: user '$user' does not exist"
    return 1
  fi

  if [[ ! -x "$chvt_bin" ]]; then
    log "ERROR: core_enable_vt_switching: '$chvt_bin' not found/executable (is 'kbd' installed?)"
    return 1
  fi

  need_cmd sudo

  # Create group if missing
  if ! getent group "$group" >/dev/null 2>&1; then
    log "Creating group '$group'..."
    run "sudo groupadd -r '$group'"
  else
    log "Group '$group' already exists"
  fi

  # Add user to group if needed
  if ! id -nG "$user" | tr ' ' '\n' | grep -qx "$group"; then
    log "Adding user '$user' to group '$group'..."
    run "sudo usermod -aG '$group' '$user'"
  else
    log "User '$user' already in group '$group'"
  fi

  # Install sudoers drop-in (atomic write)
  log "Installing sudoers rule '$sudoers_file'..."
  run "sudo sh -c 'umask 077; tmp=\$(mktemp); cat >\"\$tmp\" <<EOF
%${group} ALL=(root) NOPASSWD: ${chvt_bin}
EOF
chown root:root \"\$tmp\"
chmod 0440 \"\$tmp\"
mv -f \"\$tmp\" \"${sudoers_file}\"
'"

  # Validate sudoers if visudo exists
  if command -v visudo >/dev/null 2>&1; then
    if ! sudo visudo -cf "$sudoers_file" >/dev/null; then
      log "ERROR: sudoers validation failed for '$sudoers_file' (rolling back)"
      run "sudo rm -f '$sudoers_file'"
      return 1
    fi
  else
    log "WARN: 'visudo' not found; skipped sudoers validation"
  fi

  log "VT switching enabled: members of '$group' can run 'sudo $chvt_bin <N>' without a password"
}
