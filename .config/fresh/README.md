# Fresh Config

## Files

| File | Purpose |
|------|---------|
| `config.json` | All editor settings — theme, indentation, LSP servers, keybindings. |

## Features

Fresh is the preferred `$EDITOR` (highest priority in the shell config's editor selection). It's a fast, modern terminal IDE written in Rust with LSP support, fuzzy file finder, integrated terminal, and mouse support — all working out of the box with no plugins required.

## Keybindings

| Action | Shortcut |
|--------|----------|
| Toggle comment | `Alt+/` |
| Toggle comment (alt) | `Ctrl+_` |
| Delete previous word | `Ctrl+Backspace` |
| Delete next word | `Ctrl+Delete` |
| Toggle soft wrap | `Alt+Z` |

Standard keybindings (`Ctrl+S` save, `Ctrl+Z` undo, `Ctrl+F` find, `Ctrl+P` command palette) work without any config.

## Setup

Installed from the official install script on Linux, or via `brew tap sinelaw/fresh && brew install fresh-editor` on macOS. The config file is symlinked by `setup-symlinks` (not the entire `~/.config/fresh/` directory, since fresh may write runtime state there).
