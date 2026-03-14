# WezTerm Config

## Files

| File | Purpose |
|------|---------|
| `wezterm.lua` | Main config — font, keybindings, splits, theme, window frame. Symlinked as `~/.config/wezterm/`. |

## Features

- **Font** — JetBrains Mono NL Nerd Font, Bold, 12pt
- **Window** — 160x48 initial size, scrollbar enabled, 100k scrollback
- **Auto theme** — Switches between Gruvbox Dark Hard and Alabaster based on system dark/light mode
- **Tab bar** — Hidden when only one tab is open
- **Platform-aware title buttons** — GNOME style on Linux, native on macOS, Windows elsewhere

## Keybindings

| Action | Shortcut |
|--------|----------|
| Split vertical (side-by-side) | `Ctrl+Alt+V` |
| Split horizontal (top-bottom) | `Ctrl+Alt+S` |
| Navigate panes | `Ctrl+Alt+Arrow` |
| Resize panes (5 cells/press) | `Ctrl+Alt+Shift+Arrow` |

## Quake-Mode Dropdown

WezTerm can act as a drop-down terminal (replacing Guake) via the GNOME Quake Terminal extension:

- **Toggle** — `F1`
- **Script** — `.local/bin/wezterm-dropdown` launches WezTerm with no decorations, 90% opacity, and a dedicated window class
- **Desktop entry** — `.local/share/applications/wezterm-dropdown.desktop`
- **Extension settings** — `.config/gnome/extensions/quake-terminal.dconf`

The dropdown occupies 50% screen height, auto-hides on focus loss, stays on top, and appears on whichever monitor has the mouse.
