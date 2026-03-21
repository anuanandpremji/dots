# VS Code Config

## Files

| File                    | Purpose                                                               |
|-------------------------|-----------------------------------------------------------------------|
| `User/settings.json`    | Editor settings — font, theme, terminal, language-specific overrides. |
| `User/keybindings.json` | Custom keybindings — pane management, navigation, terminal shortcuts. |

Only these two files are symlinked. VS Code manages extensions and other state in `~/.config/Code/` independently.

## Highlights

- **Font** — JetBrains Mono NL Nerd Font, weight 600, size 16
- **Theme** — Auto-switches: Gruvbox Dark Hard (dark) / GitHub Light Theme Gray (light)
- **Terminal** — Zsh default, 1M scrollback, smooth scrolling, copy-on-select
- **Minimap** — Disabled
- **Tab bar** — Compact height, wrapping tabs, no close buttons, no file icons, highlighted modified tabs
- **Whitespace** — Rendered, trailing spaces trimmed on save, final newline inserted

## Keybindings

| Action                | Shortcut                    | Context            |
|-----------------------|-----------------------------|--------------------|
| Split vertical        | `Ctrl+Alt+V`                | Editor / Terminal  |
| Split horizontal      | `Ctrl+Alt+S`                | Editor / Terminal  |
| Navigate panes        | `Ctrl+Alt+Arrow`            | Editor / Terminal  |
| Resize pane/sidebar   | `Ctrl+Alt+Shift+Left/Right` | Any (width)        |
| Resize pane/sidebar   | `Ctrl+Alt+Shift+Up/Down`    | Any (overall size) |
| Navigate back/forward | `Alt+Left/Right`            | Editor             |
| Open explorer         | `Ctrl+E`                    | Any                |
| Delete line           | `Alt+Delete`                | Editor             |
| Toggle panel          | `` Ctrl+` ``                | Non-terminal       |
| Toggle terminal       | `Ctrl+J`                    | Terminal active    |
| Maximize terminal     | `Ctrl+Shift+J`              | Terminal           |
| Move editor to group  | `Ctrl+K Arrow`              | Any                |

## Setup

On Linux, symlinked to `~/.config/Code/User/`. On macOS, symlinked to `~/Library/Application Support/Code/User/`. VS Code itself is installed from Microsoft's official apt/yum repo (Linux) or Homebrew cask (macOS).
