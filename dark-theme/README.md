```md
# Archbento Dark Theme Defaults

This directory contains **default dark mode configuration** for Archbento.
The goal is to provide a **consistent dark appearance out of the box** for both
GTK and Qt applications, while remaining **fully user-configurable after install**.

Nothing here is enforced permanently — users can change or remove any of these
files at any time.

---

## Design Philosophy

- 🌙 **Dark mode by default**
- 🧠 **Explicit configuration over magic**
- 🧑‍💻 **User always retains control**
- 🔁 **Installer-safe & re-runnable**

Archbento applies dark mode **once at install time**. After that, the system
belongs to the user.

---

## What This Configures

### GTK (GTK3 & GTK4)

Applied via config files, not GNOME services:

```

~/.config/gtk-3.0/settings.ini
~/.config/gtk-4.0/settings.ini

```

These ensure GTK apps (e.g. Thunar, GTK dialogs) prefer dark mode even outside
GNOME environments (Hyprland, Wayland, etc).

---

### Qt (Qt6 via qt6ct)

Qt apps are themed using **qt6ct**, with a shipped dark color scheme.

Files installed on first run:

```

~/.config/qt6ct/qt6ct.conf
~/.config/qt6ct/colors/darker.conf

```

- Style: `Fusion`
- Color scheme: `darker.conf`
- Fully editable via `qt6ct` GUI after install

⚠️ These files are **copied**, not symlinked, so user changes are preserved.

---

## Installer Behavior

- Creates required directories if missing
- Copies theme files **only if they don’t already exist**
- Will **not overwrite user-modified files**
- Safe to re-run installer

This ensures upgrades don’t clobber user customization.

---

## How to Disable or Change Dark Mode

### GTK
- Edit or delete:
```

~/.config/gtk-3.0/settings.ini
~/.config/gtk-4.0/settings.ini

````

### Qt
- Run:
```bash
qt6ct
````

* Or edit:

  ```
  ~/.config/qt6ct/qt6ct.conf
  ```

Log out and back in if changes don’t apply immediately.

---

## Notes

* Chromium does **not** follow Qt theming; it uses its own theming system
* KDE apps will respect qt6ct when launched in Hyprland
* This setup intentionally avoids distro-wide hard dependencies on GNOME or KDE

---
