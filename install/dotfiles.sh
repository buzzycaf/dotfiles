#!/usr/bin/env bash

[[ "${ARCHBENTO_INSTALL_CONTEXT:-}" == "1" ]] || {
  echo "ERROR: install/dotfiles.sh must be sourced by install.sh" >&2
  exit 1
}

dotfiles_link_all() {
  log "Linking dotfiles from $REPO_DIR"

  # Find target user
  local target_user="${SUDO_USER:-$USER}"
  local target_home
  target_home="$(getent passwd "$target_user" | cut -d: -f6)"

  if [[ -z "$target_home" ]]; then
    echo "ERROR: could not resolve home directory for user '$target_user'" >&2
    return 1
  fi

  # zsh
  [[ -f "$REPO_DIR/zsh/zshrc" ]]     && link_file "$REPO_DIR/zsh/zshrc" "$target_home/.zshrc"
  [[ -f "$REPO_DIR/zsh/zprofile" ]]  && link_file "$REPO_DIR/zsh/zprofile" "$target_home/.zprofile"

  # starship
  if [[ -d "$REPO_DIR/starship" ]]; then
    [[ -f "$REPO_DIR/starship/starship.toml" ]] && \
      link_file "$REPO_DIR/starship/starship.toml" "$target_home/.config/starship/starship.toml"

    [[ -f "$REPO_DIR/starship/starship-linux.toml" ]] && \
      link_file "$REPO_DIR/starship/starship-linux.toml" "$target_home/.config/starship/starship-linux.toml"

    [[ -f "$REPO_DIR/starship/starship-xterm.toml" ]] && \
      link_file "$REPO_DIR/starship/starship-xterm.toml" "$target_home/.config/starship/starship-xterm.toml"

    # Optional: legacy path compatibility (safe to keep)
    [[ -f "$REPO_DIR/starship/starship.toml" ]] && \
      link_file "$REPO_DIR/starship/starship.toml" "$target_home/.config/starship.toml"
  fi

  # fastfetch
  if [[ -d "$REPO_DIR/fastfetch" ]]; then
    # Main config (keep for backward compatibility if you still ship it)
    [[ -f "$REPO_DIR/fastfetch/config.jsonc" ]] && \
      link_file "$REPO_DIR/fastfetch/config.jsonc" "$target_home/.config/fastfetch/config.jsonc"

    # New split configs (TTY vs GUI)
    [[ -f "$REPO_DIR/fastfetch/config-tty.jsonc" ]] && \
      link_file "$REPO_DIR/fastfetch/config-tty.jsonc" "$target_home/.config/fastfetch/config-tty.jsonc"

    [[ -f "$REPO_DIR/fastfetch/config-xterm.jsonc" ]] && \
      link_file "$REPO_DIR/fastfetch/config-xterm.jsonc" "$target_home/.config/fastfetch/config-xterm.jsonc"

    # logo.png should be user-owned (copy once; never overwrite)
    if [[ -f "$REPO_DIR/fastfetch/logo.png" ]]; then
      local user_logo="$target_home/.config/fastfetch/logo.png"
      if [[ ! -e "$user_logo" ]]; then
        log "Copying fastfetch logo (user-editable): $user_logo"
        run "cp '$REPO_DIR/fastfetch/logo.png' '$user_logo'"
      else
        log "OK: fastfetch logo already exists (not overwriting): $user_logo"
      fi
    fi
  fi

  # micro editor
  if [[ -d "$REPO_DIR/micro" ]]; then
    link_dir_contents "$REPO_DIR/micro" "$target_home/.config/micro"
  fi

  # tmux
  if [[ -f "$REPO_DIR/tmux/tmux.conf" ]]; then
    link_file "$REPO_DIR/tmux/tmux.conf" "$target_home/.config/tmux/tmux.conf"
  fi

  # zsh extra files
  [[ -f "$REPO_DIR/zsh/aliases.zsh" ]] && \
    link_file "$REPO_DIR/zsh/aliases.zsh" "$target_home/.zsh/aliases.zsh"

  # Hyprland
  [[ -d "$REPO_DIR/hypr"    ]] && link_dir_contents "$REPO_DIR/hypr"    "$target_home/.config/hypr"
  
  # Waybar
  [[ -d "$REPO_DIR/waybar"  ]] && link_dir_contents "$REPO_DIR/waybar"  "$target_home/.config/waybar"
  
  # Ghostty
  [[ -d "$REPO_DIR/ghostty" ]] && link_dir_contents "$REPO_DIR/ghostty" "$target_home/.config/ghostty"

  # GTK dark preference (fallback for GTK3/GTK4)
  run "mkdir -p '$target_home/.config/gtk-3.0'"
  [[ -f "$REPO_DIR/dark-theme/gtk-3.0/settings.ini" ]] && \
    link_file "$REPO_DIR/dark-theme/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
 
  run "mkdir -p '$target_home/.config/gtk-4.0'"
  [[ -f "$REPO_DIR/dark-theme/gtk-4.0/settings.ini" ]] && \
    link_file "$REPO_DIR/dark-theme/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"

  # QT dark preference (copy once; user-editable)
  run "mkdir -p '$target_home/.config/qt6ct' '$target_home/.config/qt6ct/colors' '$target_home/.config/qt6ct/qss'"
    
  # qt6ct main config
  if [[ -f "$REPO_DIR/dark-theme/qt/qt6ct.conf" ]]; then
    if [[ ! -e "$target_home/.config/qt6ct/qt6ct.conf" ]]; then
      log "Copying qt6ct config (user-editable)"
      run "cp '$REPO_DIR/dark-theme/qt/qt6ct.conf' '$target_home/.config/qt6ct/qt6ct.conf'"
    else
      log "OK: qt6ct config already exists (not overwriting)"
    fi
  fi
  
  # qt6ct color scheme
  if [[ -f "$REPO_DIR/dark-theme/qt/colors/darker.conf" ]]; then
    if [[ ! -e "$target_home/.config/qt6ct/colors/darker.conf" ]]; then
      log "Copying qt6ct color scheme (user-editable)"
      run "cp '$REPO_DIR/dark-theme/qt/colors/darker.conf' '$target_home/.config/qt6ct/colors/darker.conf'"
    else
      log "OK: qt6ct color scheme already exists (not overwriting)"
    fi
  fi

  # fuzzel
  if [[ -f "$REPO_DIR/fuzzel/fuzzel.ini" ]]; then
    link_file "$REPO_DIR/fuzzel/fuzzel.ini" "$target_home/.config/fuzzel/fuzzel.ini"
  fi

  # mako notifications
  if [[ -f "$REPO_DIR/mako/config" ]]; then
    link_file "$REPO_DIR/mako/config" "$target_home/.config/mako/config"
  fi

  # screenshot helper
  if [[ -f "$REPO_DIR/bin/screenshot.sh" ]]; then
    if [[ ! -f "$target_home/.local/bin/screenshot.sh" ]]; then
      log "Installing screenshot helper script"
      run "cp '$REPO_DIR/bin/screenshot.sh' '$target_home/.local/bin/screenshot.sh'"
      run "chmod +x '$target_home/.local/bin/screenshot.sh'"
    else
      log "Screenshot helper script already exists, skipping"
    fi
  fi

  # =====================================================================
  # Archbento Tools Framework
  # 1) Create state directory
  # 2) Copy tools.env into state (copy once; user-editable)
  # 3) Link archbento-tools-sync.sh into ~/.local/bin
  # =====================================================================

  # 1) state directory
  run "mkdir -p '$target_home/.local/state/archbento'"

  # 2) tools.env (copy once; user-editable)
  if [[ -f "$REPO_DIR/tools.env" ]]; then
    local state_tools_env="$target_home/.local/state/archbento/tools.env"
    if [[ ! -e "$state_tools_env" ]]; then
      log "Copying tools.env (user-editable): $state_tools_env"
      run "cp '$REPO_DIR/tools.env' '$state_tools_env'"
    else
      log "OK: tools.env already exists (not overwriting): $state_tools_env"
    fi
  else
    log "WARNING: tools.env not found in repo root: $REPO_DIR/tools.env"
  fi

  # 3) archbento-tools-sync.sh (symlink into ~/.local/bin)
  run "mkdir -p '$target_home/.local/bin'"
  if [[ -f "$REPO_DIR/bin/archbento-tools-sync.sh" ]]; then
    log "Linking archbento-tools-sync.sh into ~/.local/bin"
    run "ln -sf '$REPO_DIR/bin/archbento-tools-sync.sh' '$target_home/.local/bin/archbento-tools-sync.sh'"
  else
    log "WARNING: archbento-tools-sync.sh not found: $REPO_DIR/bin/archbento-tools-sync.sh"
  fi

  # Save Backups
  [[ -n "${BACKUP_DIR:-}" ]] && log "Backups saved in: $BACKUP_DIR"
  
}
