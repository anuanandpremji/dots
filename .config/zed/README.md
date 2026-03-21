# Zed Config

## Files

| File            | Purpose                                                                     |
|-----------------|-----------------------------------------------------------------------------|
| `settings.json` | Editor settings — font, theme, UI, terminal, telemetry.                     |
| `keymap.json`   | Custom keybindings — pane management, comment toggle, terminal passthrough. |
| `themes/`       | 13 custom color themes.                                                     |

The entire `~/.config/zed/` directory is symlinked.

## Highlights

- **Font** — JetBrains Mono NL Nerd Font (buffer), SF Mono (UI), weight 600
- **Theme** — Auto-switches: Gruvbox Dark Hard (dark) / VSCode Light Modern (light)
- **AI/telemetry** — Disabled (`disable_ai: true`, telemetry off)
- **Vim mode** — Disabled
- **Cursor** — Block style, blinking in terminal
- **Tabs** — Git status shown, no file icons

## Keybindings

| Action              | Shortcut               | Context   |
|---------------------|------------------------|-----------|
| Split vertical      | `Ctrl+Alt+V`           | Workspace |
| Split horizontal    | `Ctrl+Alt+S`           | Workspace |
| Navigate panes      | `Ctrl+Alt+Arrow`       | Workspace |
| Resize dock/sidebar | `Ctrl+Alt+Shift+Arrow` | Workspace |
| Delete line         | `Alt+Delete`           | Editor    |

Note: Resize shortcuts use `workspace::IncreaseActiveDockSize` / `workspace::DecreaseActiveDockSize`, which resize the sidebar and panel docks. Zed does not currently support keyboard-driven editor pane resizing.

### Terminal passthrough

The keymap explicitly passes `Ctrl+S`, `Ctrl+Q`, `Ctrl+T`, `Shift+Home`, and `Shift+End` through to the terminal, preventing Zed from intercepting them.

## Custom Themes

The `themes/` directory contains 13 themes: Day Shift, GitHub Classic, GitHub Theme, macOS Classic, Mnemonic, Modus Themes, Nebula Dawn, Panda, Purr, Vitesse, VSCode Light Modern, Yaka, ZedHacker Light.

## Setup

Installed via the official install script on Linux (uses Flatpak) or Homebrew cask on macOS. Config directory is symlinked by `setup_symlinks.sh`.
