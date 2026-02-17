#!/bin/zsh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ .zshenv is always loaded first and has to live at `$HOME/.zshenv`, and not in $ZDOTDIR                              ║
#║ So either source this file from `$HOME/.zshenv`                                                                     ║
#║ Or symlink this file from your $ZDOTDIR using:                                                                      ║
#║ ln -sf "<path/to/this/file>" "$HOME/.zshenv"                                                                        ║
#║                                                                                                                     ║
#║ Read http://mywiki.wooledge.org/BashFAQ/028 to know why we are doing this                                           ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Set DOTFILE_DIR to point to the on-disk directory containing the .zshrc file

# Determine the Dropbox installation  path (Linux Home vs Windows User Profile)
if grep -qEi "(Microsoft|WSL)" /proc/version >/dev/null 2>&1; then
    BASE_DROPBOX_PATH="$(wslpath -a "$(wslvar USERPROFILE)")/Dropbox";
else BASE_DROPBOX_PATH="$HOME/Dropbox"; fi

# Check which subdirectory exists inside that dropbox path
if [ -d "$BASE_DROPBOX_PATH/Docs" ]; then DOTFILE_DIR="$BASE_DROPBOX_PATH/Docs/dotfiles/.config/shell/zsh";
elif [ -d "$BASE_DROPBOX_PATH/Shared" ]; then DOTFILE_DIR="$BASE_DROPBOX_PATH/Shared/dotfiles/.config/shell/zsh";
else echo "Error: Dotfiles not found at: $BASE_DROPBOX_PATH" >&2; return 1; fi

export DOTFILE_DIR;

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

source "$ZDOTDIR/.zshexports";

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
