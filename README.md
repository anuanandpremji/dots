# Dotfiles

Personal dotfiles for a consistent development environment across Ubuntu, Debian, Fedora, and macOS. Cloned from GitHub and applied via symlinks.

## Quick Start

On a fresh machine with nothing installed, run this single command:

```shell
curl -fsSL https://raw.githubusercontent.com/anuanandpremji/dots/main/setup.sh -o /tmp/setup.sh && bash /tmp/setup.sh
```

The script will:

1. **Set up Git & SSH identities** — creates separate `~/.ssh/id_private` and `~/.ssh/id_work` keys with GitHub host aliases, writes `config.private`/`config.work`, and asks which should be the default
2. **Clone the dotfiles repo** — uses SSH via private key if configured, falls back to HTTPS. Can also download as zip for machines without git.
3. **Install all apps** — editors, CLI tools, browsers, fonts, GNOME extensions, etc.
4. **Apply configs** — symlinks and dconf settings via `setup-symlinks`

```shell
# If dotfiles are already present, run directly
./setup.sh

# CLI-only mode for headless servers (dotfiles, SSH, CLI tools — no GUI apps)
./setup.sh --cli

# Just symlink configs and load settings (no app installs)
.config/shell/scripts/setup-symlinks

# Preview what any script would do without making changes
./setup.sh --dry-run
./setup.sh --cli --dry-run
.config/shell/scripts/setup-symlinks --dry-run
```

## What's Included

| Category  | Apps                                                                   | Docs                                                                                                                                  |
|-----------|------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| Shell     | Zsh, Bash (cross-shell config with shared aliases, functions, history) | [README](.config/shell/README.md)                                                                                                     |
| Terminal  | WezTerm (with quake-mode dropdown)                                     | [README](.config/wezterm/README.md)                                                                                                   |
| Editors   | Neovim, Fresh, VS Code, Zed                                            | [Neovim](.config/nvim/README.md), [Fresh](.config/fresh/README.md), [VS Code](.config/vscode/README.md), [Zed](.config/zed/README.md) |
| CLI Tools | fzf, fd, bat, ripgrep, eza, delta, tree                                |                                                                                                                                       |
| Git       | Custom config with delta pager, aliases, multi-identity                | [README](.config/git/README.md)                                                                                                       |
| Browsers  | Firefox, Chrome, Brave                                                 |                                                                                                                                       |
| Markdown  | Obsidian, Typora                                                       |                                                                                                                                       |
| Diff      | Meld, delta (CLI)                                                      |                                                                                                                                       |
| PDF       | PDF Arranger                                                           |                                                                                                                                       |
| Cloud     | Dropbox                                                                |                                                                                                                                       |
| GNOME     | Desktop settings, extensions, Calendar, Tweaks, Extension Manager      | [README](.config/gnome/README.md)                                                                                                     |
| Fonts     | Nerd Font collection                                                   | [README](.local/share/fonts/README.md)                                                                                                |

## Directory Structure

```
dotfiles/
├── setup.sh                          # Full machine setup (apps + configs)
│
├── .config/
│   ├── shell/                        # Shell configuration (Bash, Zsh, fzf, prompts)
│   │   ├── bash/                     # Bash config files
│   │   ├── zsh/                      # Zsh config files
│   │   ├── starship/                 # Starship prompt themes (optional)
│   │   └── scripts/                  # setup-symlinks, setup-identities, utilities
│   │
│   ├── git/                          # Git config (aliases, delta pager, multi-identity)
│   ├── wezterm/                      # WezTerm terminal config (Lua)
│   ├── nvim/                         # Neovim config (Vimscript)
│   ├── fresh/                        # Fresh editor config
│   ├── vscode/                       # VS Code settings and keybindings
│   ├── zed/                          # Zed editor settings, keymap, themes
│   ├── gnome/                        # GNOME desktop and extension settings
│   ├── meld/                         # Meld diff tool settings
│   └── claude/                       # Claude Code settings
│
└── .local/
    ├── bin/                          # Custom scripts (wezterm-dropdown)
    └── share/
        ├── applications/             # Desktop entries
        └── fonts/                    # Nerd Fonts collection
```

## How Configs Are Applied

- **Self-resolving paths** — `.zshenv` and `.bashrc` detect `$DOTFILE_DIR` automatically by resolving their own symlink target. No hardcoded paths to edit per machine.
- **Symlinked apps** — Shell, Git, WezTerm, Neovim, Zed, Fresh, VS Code, Claude Code, fonts, scripts. The dotfiles directory is the source of truth; `~/.config/` contains symlinks pointing here.
- **dconf-loaded apps** — GNOME settings, GNOME extensions, Meld. These use `dconf load` to import settings from `.dconf` backup files, since they don't read plain config files.
- **macOS** — dconf sections are skipped. VS Code symlinks point to `~/Library/Application Support/Code/User/`. Fonts are copied to `~/Library/Fonts/`.
- **setup-symlinks** — Also self-resolving. It derives `$DOTFILES` from its own location in the directory tree, so it works regardless of where the dotfiles live.
