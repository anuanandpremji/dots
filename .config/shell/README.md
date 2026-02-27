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
| [delta](https://github.com/dandavison/delta) | Pretty git diffs in the interactive staging function |
| [tree](https://github.com/Old-Man-Programmer/tree) | Directory tree viewer used by `tre()` |

---

## Directory Structure

```
.config/shell/
│
├── bash/
│   ├── .bashrc ·························· Entry point — main Bash config — sources everything below
│   ├── .bashexports ····················· Environment variables, XDG paths, PATH
│   ├── .bashutils ······················· Low-level helpers (clipboard, open, confirm)
│   ├── .bashfzf ························· FZF keybindings (Ctrl-R, Ctrl-T) and interactive functions
│   ├── .bashfunctions ··················· Git helpers, system update functions
│   ├── .bashaliases ····················· Shell aliases
│   ├── .bashextra ······················· Optional extras
│   ├── .bashprompt_theme_cascade ········ Default prompt — agnoster-style segments
│   └── .bashprompt_theme_pure ··········· Alternative prompt — minimal style
│
├── zsh/
│   ├── .zshenv ·························· Entry point — sets ZDOTDIR where zshrc lives, sources exports
│   ├── .zshexports ······················ Environment variables, XDG paths, PATH
│   ├── .zshrc ··························· Main Zsh config — sources everything below
│   ├── .zshutils ························ Low-level helpers (clipboard, open, confirm)
│   ├── .zshfzf ·························· FZF keybindings (Ctrl-R, Ctrl-T) and interactive functions
│   ├── .zshfunctions ···················· Git helpers, system update functions
│   ├── .zshaliases ······················ Shell aliases
│   ├── .zshextra ························ Optional extras (syntax highlighting)
│   ├── .zshprompt_theme_cascade ········· Default prompt — agnoster-style segments
│   └── .zshprompt_theme_pure ············ Alternative prompt — minimal style
│
├── history/
│   └── .history ························· Shared command history (both shells)
│
└── starship/
    ├── gaps.toml ························ Starship prompt — agnoster with gaps
    ├── gaps_inverted_arrow.toml ········· Starship prompt — inverted arrow variant
    └── pills.toml ······················· Starship prompt — pill-shaped segments
```

### Load order

```
Zsh                                          │   Bash
───                                          │   ────
~/.zshenv                                    │   ~/.bashrc
 ├─ .zshexports                              │        ├─ .bashexports
 └─ $ZDOTDIR/.zshrc                          │        ├─ .bashprompt_theme_cascade
               ├─ .zshprompt_theme_cascade   │        ├─ .bashutils
               ├─ .zshutils                  │        ├─ .bashfzf
               ├─ .zshfzf                    │        ├─ .bashfunctions
               ├─ .zshfunctions              │        └─ .bashaliases
               ├─ .zshaliases                │
               └─ .zshextra                  │
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

Two custom, plugin-free prompt themes are included for both **Zsh** and **Bash** with full feature parity. The **Cascade** theme is active by default. To switch themes, comment/uncomment the corresponding `source` line in `.zshrc` or `.bashrc`.

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
| Exit status color (green/red)  |  +  |  +   |
| Last command duration          |  +  |  +   |
| Background jobs indicator      |  +  |  +   |

---

## Keybindings

### `Ctrl-R` — Fuzzy history search

Fuzzy search through shell history with multi-select support. Use `TAB` to select multiple entries, then act on them with any key below. After edits or deletions the history reloads and fzf reopens with the same query.

![Ctrl-R history search](screenshots/Ctrl-R.png)

| Key inside fzf | Action |
|-----------------|--------|
| `Enter` | Paste selected command(s) onto the command line (newline-separated) |
| `TAB` | Toggle multi-select on the focused entry |
| `?` | Toggle preview |
| `Ctrl-E` | Edit selected entries in `$VISUAL` — originals are removed and edited content is appended |
| `Ctrl-O` | Open the raw history file in `$VISUAL` |
| `Ctrl-X` | Delete selected entry/entries from history |

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

## History

Both shells share a single history file at `history/.history`. Two behaviors are enforced in both Zsh and Bash to keep it clean:

**No timestamps** — Zsh is configured with `setopt no_extended_history`, and Bash explicitly unsets `HISTTIMEFORMAT`, so `#<timestamp>` lines never appear in the shared file.

**Only successful commands are saved** — commands that fail are kept in the shell's in-memory history (available via arrow keys for the current session) but are never written to the on-disk history file. Ctrl-C (exit 130) is treated as success since the user intentionally interrupted.

- **Zsh** achieves this with the `zshaddhistory` / `precmd` / `zshexit` hooks (see `.zshrc`).
- **Bash** achieves this with a `PROMPT_COMMAND` handler that writes successful commands immediately, an `EXIT` trap that prevents Bash's default flush of in-memory history, and avoidance of `history -a` in the fzf widget (see `.bashrc`).

---

## Zsh-specific features

**Completion** — case-insensitive, auto-menu on second tab press, colored candidates, auto-slash for directories.

**Globbing** — `extended_glob` enabled (`#`, `~`, `^` patterns), `glob_dots` includes dotfiles.

**Auto-cd** — type a directory path without `cd` to navigate to it.

---

## XDG compliance

Both shells redirect config and cache paths for 25+ applications to proper XDG directories, keeping `$HOME` clean:

`Android` `Ansible` `Aspell` `AWS` `Bash (INPUTRC)` `Docker` `Dotnet` `Git` `GnuPG` `Go` `GTK` `Java` `Kubernetes` `LaTeX` `Less` `Nvidia` `Python` `Jupyter` `Ripgrep` `Rust` `Subversion` `Terminfo` `Tmux` `Wget` and more.

---

## Editor detection

The `EDITOR` and `VISUAL` variables are set automatically based on what's installed, in order of preference:

`micro` > `nvim` > `vim` > `vi`
