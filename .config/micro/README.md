# Micro Config

## Files

| File            | Purpose                                                       |
|-----------------|---------------------------------------------------------------|
| `settings.json` | Editor settings (color scheme: `cmc-16`).                     |
| `bindings.json` | Custom keybindings (comment toggle via `Alt+/` and `Ctrl+_`). |
| `init.lua`      | Lua init script (comment plugin).                             |

## Features

Micro is the preferred `$EDITOR` (highest priority in the shell config's editor selection). It's configured minimally — just a color scheme and comment toggle bindings.

## Keybindings

| Action               | Shortcut         |
|----------------------|------------------|
| Toggle comment       | `Alt+/`          |
| Toggle comment (alt) | `Ctrl+_`         |
| Delete previous word | `Ctrl+Backspace` |
| Delete next word     | `Ctrl+Delete`    |
| Toggle soft wrap     | `Alt+Z`          |

Pane management is not bound — handled by the host terminal emulator.

## Setup

Installed from the official GitHub binary (`~/.local/bin/micro`). Individual config files are symlinked by `setup-symlinks` (not the entire `~/.config/micro/` directory, since micro writes runtime state there).
