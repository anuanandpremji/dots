# Fonts

Nerd Font patched monospace fonts and a few display fonts, symlinked to `~/.local/share/fonts/` on Linux or copied to `~/Library/Fonts/` on macOS.

## Installed Families

| Font                        | Type      | Notes                                                         |
|-----------------------------|-----------|---------------------------------------------------------------|
| JetBrains Mono NL Nerd Font | Monospace | **Primary font** — used in WezTerm, VS Code, Zed, Guake, Meld |
| SF Mono                     | Monospace | Zed UI font                                                   |
| Operator Mono Lig Nerd Font | Monospace | Ligature variant                                              |
| DankMono Nerd Font          | Monospace |                                                               |
| Fantasque Sans Mono         | Monospace | Nerd Font patched                                             |
| Iosevka Term                | Monospace | Nerd Font patched                                             |
| Input                       | Monospace | Nerd Font Complete variants                                   |
| Recursive                   | Variable  | Variable-weight monospace/sans                                |
| iA Writer Quattro V         | Monospace | Proportional writing font                                     |
| Atkinson Hyperlegible       | Sans      | High-legibility font                                          |
| Bitter Pro                  | Serif     |                                                               |
| Helvetica Neue              | Sans      |                                                               |
| Noto Emoji                  | Emoji     | Variable weight                                               |
| Symbols 2048-em Nerd Font   | Symbol    | Standalone Nerd Font symbols                                  |
| Trang Pencil                | Display   |                                                               |

## Setup

On Linux, the entire directory is symlinked by `setup_symlinks.sh` and `fc-cache -f` is run to rebuild the font cache. On macOS, `setup.sh` copies `.ttf` and `.otf` files to `~/Library/Fonts/`.
