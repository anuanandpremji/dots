#!/bin/zsh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ .zshenv is always loaded first and has to live at `$HOME/.zshenv`, and not in $ZDOTDIR                              ║
#║ So either source this file from `$HOME/.zshenv`                                                                     ║
#║ Or symlink this file from your $ZDOTDIR using:                                                                      ║
#║ ln -sf "<path/to/this/file>" "$HOME/.zshenv"                                                                        ║
#║                                                                                                                     ║
#║ Read http://mywiki.wooledge.org/BashFAQ/028 to know why we are doing this                                           ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Resolve DOTFILE_DIR automatically from the symlink target of this file.
# ~/.zshenv is a symlink → dotfiles/.config/shell/zsh/.zshenv
# So resolving the symlink gives us the real directory.

_resolve_dotfile_dir() {
    local link="$HOME/.zshenv"
    if [[ ! -L "$link" ]]; then return 1; fi

    local target
    # Prefer readlink -f (follows entire chain), available on Linux and Homebrew coreutils
    if target="$(readlink -f "$link" 2>/dev/null)"; then
        printf '%s' "$(dirname "$target")"
    # macOS fallback: python3 is always available
    elif target="$(python3 -c "import os; print(os.path.realpath('$link'))" 2>/dev/null)"; then
        printf '%s' "$(dirname "$target")"
    # Last resort: plain readlink + cd to resolve relative paths
    elif target="$(readlink "$link" 2>/dev/null)"; then
        (cd "$(dirname "$link")" && cd "$(dirname "$target")" && pwd)
    else
        return 1
    fi
}

DOTFILE_DIR="$(_resolve_dotfile_dir)" || DOTFILE_DIR="$HOME/.config/shell/zsh"
unset -f _resolve_dotfile_dir
export DOTFILE_DIR

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Once we set $ZDOTDIR, ZSH will automatically source any `.zshrc` file in $ZDOTDIR

ZDOTDIR="${DOTFILE_DIR:-${HOME}}";
export ZDOTDIR;

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Prevent compinit initialization from creating `.zcompdump` in $ZDOTDIR from `/etc/zsh/.zshrc`

skip_global_compinit=1;
export skip_global_compinit;

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# The global exports should be available to all programs, not just the interactive and login shells

source "$ZDOTDIR/.zsh_exports";

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
