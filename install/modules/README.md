````md
# Archbento Installer Modules

Archbento uses a **modular installer design** to keep the core system, GUI stack, and future extensions cleanly separated.

The main entry point is `install.sh`. It **sources** module files, making their functions available in the same shell context.

This avoids a single monolithic installer and keeps responsibilities clear.

---

## How Modules Work

Modules are sourced using Bash `source`, not executed as standalone scripts.

Example from `install.sh`:

```bash
source_module "core.sh"
source_module "gui.sh"
````

This means:

* Functions defined in modules are available to `main()`
* Modules share variables, flags, and helper functions
* No subshells are created
* No arguments need to be passed between modules

Think of modules as **extensions to the main installer**, not separate programs.

---

## Shared Context

All modules have access to:

* Global flags:

  * `NO_PACKAGES`
  * `DRY_RUN`
  * `INCLUDE_GUI`
* Helper functions:

  * `log`
  * `run`
  * `need_cmd`
* Environment state (e.g. `$HOME`, `$REPO_DIR`)

Each module must **honor flags** like `--no-packages` to keep behavior predictable.

---

## Modules Overview

### `core.sh`

Responsible for **non-graphical system setup**.

Includes:

* Core CLI tools
* Networking (NetworkManager)
* AUR helper (`yay`)
* Terminal-only utilities

This module should **never** include GUI-only packages.

Example responsibilities:

* Editors (micro)
* Multiplexers (tmux)
* CLI tools (ripgrep, fzf, etc.)
* Base system services

---

### `gui.sh`

Responsible for the **desktop environment and graphical stack**.

Only runs when `--gui` is passed.

Includes:

* Hyprland
* Waybar
* Ghostty
* PipeWire / WirePlumber
* Portals, notifications, polkit agents
* GUI-only utilities

This module assumes:

* A TTY-based system (no display manager)
* Manual or scripted Hyprland startup

---

## Execution Flow

High-level flow inside `install.sh`:

```text
parse_args
source modules
warm_sudo (if needed)

core_install_packages
core_enable_networking
core_install_yay

if --gui:
  gui_install_packages
  gui_enable_services
  gui_notes

link_dotfiles
set_zsh_shell
```

Each step is intentionally explicit.

---

## Adding New Modules

Future modules can be added without modifying existing ones.

Examples:

* `gaming.sh`
* `workstation.sh`
* `dev.sh`
* `laptop.sh`

Pattern:

1. Create a new module file
2. Add functions with a clear prefix
3. Source it in `install.sh`
4. Gate execution with flags if needed

---

## Design Philosophy

* Small, focused modules
* Explicit execution order
* No hidden side effects
* Safe to re-run
* Easy to debug

This structure is meant to scale **without becoming fragile or confusing**.

```