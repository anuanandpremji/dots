#!/bin/zsh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ .zshenv is always loaded first and has to live at `$HOME/.zshenv`, and not in $ZDOTDIR                              ║
#║ So either source this file from `$HOME/.zshenv`                                                                     ║
#║ Or symlink this file from your $ZDOTDIR using:                                                                      ║
#║ ln -sf "<path/to/this/file>" "$HOME/.zshenv"                                                                        ║
#║                                                                                                                     ║
#║ Read http://mywiki.wooledge.org/BashFAQ/028 to know why we are doing this                                           ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Resolve the repo root from this file's real path (handles ~/.zshenv → dotfiles symlink).
# ${(%):-%x} gives the current filename; :A resolves symlinks to the absolute path;
# four :h modifiers strip the last component four times:
#   .zshenv → shell/zsh/ → shell/ → .config/ → repo root
DOTFILES_PATH="${${(%):-%x}:A:h:h:h:h}"
export DOTFILES_PATH

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Setting $ZDOTDIR causes ZSH to load .zshrc from that directory instead of $HOME.

ZDOTDIR="$DOTFILES_PATH/.config/shell/zsh"
export ZDOTDIR;

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Prevent compinit initialization from creating `.zcompdump` in $ZDOTDIR from `/etc/zsh/.zshrc`

skip_global_compinit=1;
export skip_global_compinit;

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# The global exports should be available to all programs, not just the interactive and login shells

source "$DOTFILES_PATH/.config/shell/shared/exports.sh";

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
