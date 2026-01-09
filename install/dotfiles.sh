#!/usr/bin/env bash
set -euo pipefail

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
    run "mkdir -p '$target_home/.config/starship'"

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
    run "mkdir -p '$target_home/.config/fastfetch'"

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
  run "mkdir -p '$target_home/.zsh'"
  [[ -f "$REPO_DIR/zsh/aliases.zsh" ]] && \
    link_file "$REPO_DIR/zsh/aliases.zsh" "$target_home/.zsh/aliases.zsh"

  # Hyprland
  run "mkdir -p '$target_home/.config/hypr'"
  [[ -d "$REPO_DIR/hypr"    ]] && link_dir_contents "$REPO_DIR/hypr"    "$target_home/.config/hypr"
  
  # Waybar
  run "mkdir -p '$target_home/.config/waybar'"
  [[ -d "$REPO_DIR/waybar"  ]] && link_dir_contents "$REPO_DIR/waybar"  "$target_home/.config/waybar"
  
  # Ghostty
  run "mkdir -p '$target_home/.config/ghostty'"
  [[ -d "$REPO_DIR/ghostty" ]] && link_dir_contents "$REPO_DIR/ghostty" "$target_home/.config/ghostty"

  # Save Backups
  [[ -d "$BACKUP_DIR" ]] && log "Backups saved in: $BACKUP_DIR"
}
