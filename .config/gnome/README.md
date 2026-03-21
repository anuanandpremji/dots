# GNOME Config

Backups of GNOME desktop settings, app settings, and extension configurations, applied via `dconf load`.

## Files

| File                   | Purpose                                                                                                                  |
|------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `gnome-settings.dconf` | Full system dconf dump — desktop settings, custom keybindings, window management, app settings (Calendar, Tweaks, etc.). |
| `extensions/*.dconf`   | Per-extension settings (one file each).                                                                                  |

## Installed GNOME Apps

These are installed by `setup.sh` via the system package manager (apt/dnf):

- **GNOME Calendar** — Calendar app (sometimes missing from minimal OS installs)
- **GNOME Tweaks** — Advanced GNOME settings (fonts, themes, window behavior)
- **Extension Manager** — GUI for managing GNOME Shell extensions (installed via Flatpak)

## Custom Keybindings

| Shortcut     | Action                                                 |
|--------------|--------------------------------------------------------|
| `Ctrl+Alt+T` | Launch WezTerm                                         |
| `Super+X`    | Power Off                                              |
| `Super+R`    | Reboot                                                 |
| `F1`         | Toggle WezTerm dropdown (via Quake Terminal extension) |

Workspace switching uses `Super+Alt+Left/Right` and `Super+PageUp/Down`. The `Ctrl+Alt+Arrow` and `Ctrl+Alt+Shift+Arrow` combos were freed up for pane management in terminal emulators and editors.

## Extensions

| Extension            | Purpose                                   | File                                                          |
|----------------------|-------------------------------------------|---------------------------------------------------------------|
| Quake Terminal       | Dropdown terminal toggle (`F1`)           | `extensions/quake-terminal.dconf`                             |
| Night Theme Switcher | Auto dark/light mode by time of day       | `extensions/nightthemeswitcher.dconf`                         |
| Tiling Assistant     | Window tiling with keyboard (Ubuntu only) | `extensions/tiling-assistant.dconf`                           |
| Desktop Icons (DING) | Desktop icon management                   | `extensions/ding.dconf`                                       |
| Unblank              | Prevent screen blank                      | `extensions/unblank.dconf`                                    |
| Grand Theft Focus    | Focus stealing prevention                 | (defaults, no backup needed)                                  |
| AppIndicators        | System tray indicators                    | Ubuntu: `ubuntu-appindicators`, Fedora: `appindicatorsupport` |

## Restoring

Settings are loaded automatically by `setup-symlinks` (or `setup.sh` which calls it). To manually reload:

```shell
# Full GNOME settings
dconf load / < gnome-settings.dconf

# Individual extension
dconf load /org/gnome/shell/extensions/quake-terminal/ < extensions/quake-terminal.dconf
```

## Re-exporting

After changing GNOME or extension settings, re-export to keep backups current:

```shell
dconf dump / > gnome-settings.dconf
dconf dump /org/gnome/shell/extensions/quake-terminal/ > extensions/quake-terminal.dconf
```
