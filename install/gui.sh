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
    swayimg    
    # Clipboard + screenshots
    wl-clipboard
    grim slurp wev

    # Portals (important for screenshare/file pickers, etc.)
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    
    # Audio (PipeWire)
    pipewire wireplumber pipewire-alsa pipewire-pulse

    # Notifications + polkit agent
    mako
    polkit
    polkit-gnome

    # Fonts (basic, no nerd fonts required)
    ttf-dejavu
    fuzzel
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
    gvfs
    gvfs-smb
    gvfs-mtp
    gvfs-afc
    xarchiver
    chromium
    imagemagick
  )

  log "Installing GUI tools (file manager, launcher, utilities)..."
  run "sudo pacman -S --needed --noconfirm ${pkgs[*]}"
}

gui_enable_services() {
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping gui enable services (--no-packages)..."; return; }

  log "Enabling user audio services (WirePlumber)..."
  run "systemctl --user enable --now wireplumber.service || true"

  log "Starting user XDG Desktop Portal services (best effort)..."
  run "systemctl --user daemon-reload >/dev/null 2>&1 || true"
  run "systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1 || true"
  run "systemctl --user restart xdg-desktop-portal-hyprland.service >/dev/null 2>&1 || true"
}

gui_install_post_login_fixes() {
  [[ "$NO_PACKAGES" == "1" ]] && { log "Skipping post-login fixes (--no-packages)..."; return; }

  log "Installing post-login fixes (portals)..."

  run "mkdir -p '$HOME/.local/bin' '$HOME/.local/state/archbento' '$HOME/.config/systemd/user' '$HOME/.config/hypr'"

  # 1) Script: one-time portal enable/restart with a stamp file
  write_file "$HOME/.local/bin/archbento-portal-fix.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

STAMP="$HOME/.local/state/archbento/portal-fixed"
[[ -f "$STAMP" ]] && exit 0

mkdir -p "$(dirname "$STAMP")"

systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1 || true
systemctl --user restart xdg-desktop-portal-hyprland.service >/dev/null 2>&1 || true

touch "$STAMP"
EOF

  run "chmod +x '$HOME/.local/bin/archbento-portal-fix.sh'"

  # 2) User systemd unit: run once after login
  write_file "$HOME/.config/systemd/user/archbento-portal-fix.service" <<'EOF'
[Unit]
Description=Archbento one-time XDG portal sanity check

[Service]
Type=oneshot
ExecStart=%h/.local/bin/archbento-portal-fix.sh

[Install]
WantedBy=default.target
EOF

  # 3) Enable it if possible (best effort)
  log "Enabling archbento-portal-fix user service (best effort)..."
  run "systemctl --user daemon-reload >/dev/null 2>&1 || true"
  run "systemctl --user enable --now archbento-portal-fix.service >/dev/null 2>&1 || true"

  # 4) Hyprland fallback via dedicated include file (won't be clobbered by dotfiles)
  write_file "$HOME/.config/hypr/archbento-postlogin.conf" <<'EOF'
# Archbento: post-login one-time fixups
exec-once = ~/.local/bin/archbento-portal-fix.sh
EOF
}

gui_notes() {
  log "GUI installed."
  echo "Next: add Hyprland start command (TTY login):"
  echo "  - temporarily run: Hyprland"
  echo "  - later we’ll add a safe autostart in ~/.zprofile"
}

gui_set_gtk_dark_mode() {
  log "Setting GTK dark mode preference (prefer-dark)..."

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
  else
    log "WARN: gsettings not found; GTK dark mode not applied"
  fi
}
