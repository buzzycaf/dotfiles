#!/usr/bin/env bash
set -euo pipefail

gui_install_packages() {
  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping gui package install (--no-packages)..."; return; }

  # Hyprland desktop stack (no display manager).
  # This is a conservative starter set that boots cleanly.
  local pkgs=(
    hyprland
    swww
    waybar
    ghostty

    # Clipboard + screenshots
    wl-clipboard
    grim slurp

    # Portals (important for screenshare/file pickers, etc.)
    xdg-desktop-portal
    xdg-desktop-portal-hyprland

    # Audio (PipeWire)
    pipewire wireplumber pipewire-alsa pipewire-pulse

    # Notifications + polkit agent
    mako
    polkit
    polkit-gnome

    # Fonts (basic, no nerd fonts required)
    ttf-dejavu
  )

  log "Installing GUI packages (Hyprland stack)..."
  run "sudo pacman -S --needed --noconfirm ${pkgs[*]}"
}

gui_install_tools() {
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping GUI tools (--no-packages)"; return; }

  # Optional desktop tools (QOL). Keep this tight.
  local pkgs=(
    # File manager
    thunar
    thunar-archive-plugin
    xarchiver
  )

  log "Installing GUI tools (file manager, launcher, utilities)..."
  run "sudo pacman -S --needed --noconfirm ${pkgs[*]}"
}

gui_enable_services() {
  # Honor flags
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping gui enable services (--no-packages)..."; return; }
  # WirePlumber is typically socket/auto-started, but enabling is fine.
  log "Enabling user audio services (WirePlumber)..."
  run "systemctl --user enable --now wireplumber.service || true"
}

gui_notes() {
  log "GUI installed."
  echo "Next: add Hyprland start command (TTY login):"
  echo "  - temporarily run: Hyprland"
  echo "  - later we’ll add a safe autostart in ~/.zprofile"
}