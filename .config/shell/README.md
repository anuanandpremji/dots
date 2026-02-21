# Shell Dotfiles

A lightweight, plugin-free shell configuration for **Zsh** and **Bash**.
No frameworks, no bloat, just clean shell scripting with powerful fuzzy-finding and git integrations.

---

## Highlights

- **Zero frameworks** — no oh-my-zsh, no oh-my-bash, no slow plugin managers
- **Cross-shell** — functions, aliases, and history shared between Bash and Zsh
- **XDG compliant** — keeps `$HOME` clean by redirecting 25+ app configs to proper XDG directories
- **Platform aware** — works on Linux, macOS, and WSL with auto-detection
- **Git-first workflow** — interactive staging, log browsing, branch switching, all powered by fzf

---

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [Nerd Font](https://github.com/ryanoasis/nerd-fonts) | Renders glyphs and icons in the prompt | Any Nerd Font works (tested with `JetBrainsMono NF`) |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy search for history, files, git | `apt install fzf` / `brew install fzf` |
| [fd](https://github.com/sharkdp/fd) | Fast file finder used by `Ctrl-T` | `apt install fd-find` / `brew install fd` |

**Optional but recommended:**

| Tool | Purpose |
|------|---------|
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement with color and icons |
| [delta](https://github.com/dandavella/delta) | Pretty git diffs in the interactive staging function |
| [tree](https://github.com/Old-Man-Programmer/tree) | Directory tree viewer used by `tre()` |

---

## Directory Structure

```
.config/shell/
│
├── bash/
│   ├── .bashrc ················ Main Bash config — sources everything below
│   ├── .bashexports ··········· Environment variables, XDG paths, PATH
│   ├── .bashaliases ··········· Shell aliases
│   ├── .bashfunctions ········· Utility and git functions
│   ├── .bashfzf ··············· Ctrl-R and Ctrl-T keybindings (fzf)
│   └── .bashprompt ············ Custom Bash prompt
│
├── zsh/
│   ├── .zshenv ················ Entry point — sets ZDOTDIR, sources exports
│   ├── .zshrc ················· Main Zsh config — sources everything below
│   ├── .zshexports ············ Environment variables, XDG paths, PATH
│   ├── .zshaliases ············ Shell aliases
│   ├── .zshfunctions ·········· Utility and git functions
│   ├── .zshfzf ················ Ctrl-R and Ctrl-T keybindings (fzf)
│   ├── .zshprompt_theme_cascade  Default prompt — agnoster-style segments
│   ├── .zshprompt_theme_pure ·· Alternative prompt — minimal style
│   └── .zshextra ·············· Optional extras (syntax highlighting)
│
├── history/
│   └── .history ··············· Shared command history (both shells)
│
├── starship/
│   ├── gaps.toml ·············· Starship prompt — agnoster with gaps
│   └── pills.toml ············· Starship prompt — pill-shaped segments
│
└── scripts/
    └── convert_gpg_key_format · Convert GPG keys for APT
```

### Load order

```
Zsh                                 Bash
───                                 ────
~/.zshenv                           ~/.bashrc
 └─ .zshexports                      └─ .bashexports
     └─ $ZDOTDIR/.zshrc                  ├─ .bashaliases
         ├─ .zshprompt_theme_cascade      ├─ .bashfunctions
         ├─ .zshaliases                   ├─ .bashfzf
         ├─ .zshfunctions                 └─ .bashprompt
         ├─ .zshfzf
         └─ .zshextra
```

---

## Installation

### 1. Clone the repository

```shell
git clone <URL> "$HOME/repo/"
```

> Replace `$HOME/repo/` with your preferred path.

### 2. Install a Nerd Font

Copy the bundled fonts and refresh the font cache:

```shell
cp -av "$HOME/repo/.config/fonts/." "$HOME/.local/share/fonts/"
sudo fc-cache -f
```

Then set your terminal emulator to use one of the installed Nerd Fonts.

### 3. Set the dotfile directory

**Zsh** — edit `$HOME/repo/.config/shell/zsh/.zshenv`:

```shell
export DOTFILE_DIR="$HOME/repo/.config/shell/zsh"
```

**Bash** — edit `$HOME/repo/.config/shell/bash/.bashrc`:

```shell
export DOTFILE_DIR="$HOME/repo/.config/shell/bash"
```

### 4. Link your shell config

Choose one method:

**Symlink (recommended)** — replaces the system file with a direct link:

```shell
# Zsh
ln -sf "$HOME/repo/.config/shell/zsh/.zshenv" "$HOME/.zshenv"

# Bash
ln -sf "$HOME/repo/.config/shell/bash/.bashrc" "$HOME/.bashrc"
```

**Source** — appends to your existing config:

```shell
# Zsh
echo 'source "$HOME/repo/.config/shell/zsh/.zshenv"' >> "$HOME/.zshenv"

# Bash
echo 'source "$HOME/repo/.config/shell/bash/.bashrc"' >> "$HOME/.bashrc"
```

### 5. Reload

```shell
exec "$(ps -p $$ -ocomm=)"
```

---

## Prompt

Two custom, plugin-free Zsh prompt themes are included. The **Cascade** theme is active by default. To switch themes, comment/uncomment the corresponding `source` line in `.zshrc`.

### Cascade theme

Like the agnoster theme, but with gaps.

![Cascade theme](screenshots/ZSH_theme_cascade.png)

### Pure theme

A minimal variant with the same feature set but a cleaner separator style.

![Pure theme](screenshots/ZSH_theme_pure.png)

### Starship (alternative)

Starship-based equivalents of the custom themes are available in `starship/`. However, in my experience Starship is noticeably slower than the native plugin-free prompts above.

### Feature matrix

| Feature                        | Zsh | Bash |
|--------------------------------|:---:|:----:|
| Username and hostname          |  +  |  +   |
| Working directory              |  +  |  +   |
| Read-only directory indicator  |  +  |  +   |
| Git branch                     |  +  |  +   |
| Git submodule detection        |  +  |  +   |
| Git stash count                |  +  |  +   |
| Python venv indicator          |  +  |  +   |
| Exit status color (green/red)  |  +  |  -   |
| Last command duration          |  +  |  -   |

---

## Keybindings

### `Ctrl-R` — Fuzzy history search

Fuzzy search through shell history. Select an entry to paste it onto the command line.

![Ctrl-R history search](screenshots/Ctrl-R.png)

| Key inside fzf | Action |
|-----------------|--------|
| `Enter` | Paste selected command |
| `?` | Toggle preview |
| `Ctrl-E` | Open history file in `$VISUAL` |
| `Ctrl-X` | Delete selected entry |

### `Ctrl-T` — Fuzzy file and directory search

System-wide fuzzy search for files and directories (searches from `/` using `fd`).

![Ctrl-T file search](screenshots/Ctrl-T.png)

| Key inside fzf | Action |
|-----------------|--------|
| `Enter` | Paste selected path onto command line |
| `Ctrl-D` | Cycle filter: All / Files only / Directories only |
| `?` | Toggle preview |
| `Ctrl-E` | Open in file explorer |
| `Ctrl-V` | Open in `$VISUAL` |
| `Ctrl-N` | Open in `$EDITOR` |
| `Ctrl-O` | Open with system default app |
| `Ctrl-Y` | Copy path to clipboard |

### Other keybindings

| Key | Action |
|-----|--------|
| `Up` / `Down` | Prefix history search — type a prefix, then arrow to filter |
| `Home` / `End` | Jump to start / end of line |
| `Ctrl-Left` / `Ctrl-Right` | Jump word backward / forward |
| `Ctrl-Backspace` | Delete previous word |
| `Shift-Tab` | Reverse-cycle completion menu |

---

### Utility functions

| Function | Description |
|----------|-------------|
| `open_command <file>` | Open a file or URL in the system default app (Linux / macOS / WSL aware) |
| `open_path <file>` | Open the containing directory in a file manager |
| `detect_clipboard` | Auto-detect the clipboard command (Wayland / X11 / macOS / WSL / tmux) |
| `copyabsolutepath <file>` | Copy the absolute path of a file to the clipboard |
| `confirm <prompt>` | Show a Y/N confirmation prompt |

---

## Zsh-specific features

**History** — only saves commands that exit successfully. Commands that fail are kept in memory for the session but never written to the history file.

**Completion** — case-insensitive, auto-menu on second tab press, colored candidates, auto-slash for directories.

**Globbing** — `extended_glob` enabled (`#`, `~`, `^` patterns), `glob_dots` includes dotfiles.

**Auto-cd** — type a directory path without `cd` to navigate to it.

---

## XDG compliance

Both shells redirect config and cache paths for 25+ applications to proper XDG directories, keeping `$HOME` clean:

`Docker` `Dotnet` `Go` `Java` `Kubernetes` `Rust` `Python` `Jupyter` `Git` `GnuPG` `Ripgrep` `AWS` `Ansible` `Android SDK` `LaTeX` `Tmux` `Wget` `GTK` `Subversion` `Aspell` and more.

---

## Editor detection

The `EDITOR` and `VISUAL` variables are set automatically based on what's installed, in order of preference:

`micro` > `nvim` > `vim` > `vi`
