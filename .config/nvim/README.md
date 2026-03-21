# Neovim Config

## Files

| File            | Purpose                                                                                   |
|-----------------|-------------------------------------------------------------------------------------------|
| `init.vim`      | Main config — settings, keybindings, syntax associations. Symlinked as `~/.config/nvim/`. |
| `syntax/xc.vim` | Custom syntax highlighting for `.xc` files (XMOS C variant).                              |

## Features

- **Plugin-free** — No plugin manager, no external dependencies. Pure Vimscript.
- **Sane defaults** — Line numbers, cursor line highlight, smart indent, spell check, system clipboard, mouse support.
- **Split behavior** — New splits open below (`splitbelow`) and to the right (`splitright`).
- **Display-line navigation** — Arrow keys and `j`/`k` move by display lines when wrapping.
- **Auto syntax** — Files like `.aliases`, `.bash*`, `.zsh*`, `.shell` are recognized as shell script. `.xc` files use the bundled syntax.

## Keybindings

| Action               | Shortcut               | Mode                   |
|----------------------|------------------------|------------------------|
| Move line down       | `Ctrl+J` / `Ctrl+Down` | Normal, Insert, Visual |
| Move line up         | `Ctrl+K` / `Ctrl+Up`   | Normal, Insert, Visual |
| Save                 | `Ctrl+S`               | Normal, Insert         |
| Delete previous word | `Ctrl+Backspace`       | Insert, Command        |
| Toggle soft wrap     | `Alt+Z`                | Normal                 |
| Reload config        | `Space+S`              | Normal                 |
| Open netrw explorer  | `Space+N`              | Normal                 |

Pane splitting, navigation, and resizing are **not** bound — the host terminal emulator (WezTerm, VS Code, etc.) handles pane management, since it intercepts `Ctrl+Alt` shortcuts before they reach Neovim.

## Setup

Installed as a Neovim AppImage on Linux (`~/.local/bin/nvim`) or via Homebrew on macOS. Config directory is symlinked by `setup_symlinks.sh`.
