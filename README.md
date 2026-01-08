## Project Status

Archbento is currently in early development and primarily serves as a
learning project.

Pull requests are not being accepted at this time.
Issues may be closed without response.

# Archbento 🍱

**Archbento** is an opinionated, minimal Arch Linux bootstrap focused on a clean,
comfortable **TTY / console-first** workflow.

It provides a reproducible baseline with:
- zsh + starship (TTY-safe, no Nerd Fonts required)
- fzf + zoxide
- fastfetch
- a small, intentional CLI toolset
- yay included by default
- an idempotent install script that can be safely re-run

Archbento is designed to be a **foundation**, not a full desktop.
Machine-specific configuration and higher-level environments belong elsewhere.

---

## Philosophy

- Console-first, GUI-agnostic
- Minimal, but not bare
- Observability over decoration
- Reproducible from a fresh Arch install
- `main` is living, tagged releases are frozen history

---

## Installation (Fresh Arch Linux)

From a freshly installed Arch system (TTY):

```bash
sudo pacman -S git
mkdir -p ~/src
cd ~/src
git clone https://github.com/buzzycaf/archbento
cd archbento
sudo ./install.sh
```
After installation, switch to zsh:
```bash
chsh -s /bin/zsh
```
Log out and log back in (or reboot).
