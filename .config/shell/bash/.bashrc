#!/bin/bash

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ .bashrc is always loaded first and has to live at `$HOME/.bashrc`                                                   ║
#║ So either source this file from `$HOME/.bashrc`                                                                     ║
#║ Or symlink this file using:                                                                                         ║
#║ ln -sf "<path/to/this/file>" "$HOME/.bashrc"                                                                            ║
#║                                                                                                                     ║
#║ Read http://mywiki.wooledge.org/BashFAQ/028 to know why we are doing this                                           ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Set DOTFILE_DIR to point to the on-disk directory containing the .bashrc file

# Determine the Dropbox installation path (Linux Home vs Windows User Profile)
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then BASE_DROPBOX_PATH="$(wslpath -a "$(wslvar USERPROFILE)")/Dropbox";
else BASE_DROPBOX_PATH="$HOME/Dropbox"; fi

# Check which subdirectory exists inside that dropbox path
if [ -d "$BASE_DROPBOX_PATH/Docs" ]; then DOTFILE_DIR="$BASE_DROPBOX_PATH/Docs/dotfiles/.config/shell/bash";
elif [ -d "$BASE_DROPBOX_PATH/Shared" ]; then DOTFILE_DIR="$BASE_DROPBOX_PATH/Shared/dotfiles/.config/shell/bash";
else echo "Error: Dotfiles not found at: $BASE_DROPBOX_PATH" >&2; return 1; fi

export DOTFILE_DIR;

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# The global exports should be available to all programs, not just the interactive and login shells

source "$DOTFILE_DIR/.bashexports";

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

case $- in *i*) ;; *) return;; esac # don't do anything more if not an interactive shell

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Make less more friendly for non-text input files, see lesspipe(1)

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# History

# Ignore certain commands from being stored in history
export HIST_IGNORE="ls:cd:cd -:df:ff:cls:reboot:restart:poweroff:pwd:exit:date:* --help:#*"

# Store BASH history at a custom location
export HISTFILE="$DOTFILE_DIR/../history/.history";

HISTSIZE=1000000000      # number of entries from the history file to be kept in memory for the current session
HISTFILESIZE=1000000000  # number of entries that are stored in the history file
HISTCONTROL=ignoreboth:erasedups   # ignore and erase duplicate lines and lines starting with space in the history

shopt -s histappend      # append to the history file, don't overwrite it

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Completion

export BASH_COMPLETION_USER_FILE="$XDG_CONFIG_HOME/bash-completion/bash_completion"

# Case insensitive tab completion in Bash
# Or update ~/.inputrc to include `set completion-ignore-case on`
bind "set completion-ignore-case on"

# enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then . /usr/share/bash-completion/bash_completion;
    elif [ -f /etc/bash_completion ]; then . /etc/bash_completion
    fi
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Flow Control

# https://en.wikipedia.org/wiki/Software_flow_control
# 'CTRL-S' & 'CTRL-Q' keys do flow control by default by the system, not BASH. The shell simply respects these settings.
# Turn off system level control flow with 'stty -ixon' or undefining 'stty start' or 'stty stop'.

stty stop undef       # disable CTRL-S from stopping terminal output
stty start undef      # disable Ctrl-Q from resuming terminal output

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Miscellaneous options

shopt -s autocd       # automatically do cd if the command is a path
shopt -s cdspell      # autocorrect typos in path names when using `cd`
shopt -s checkwinsize # to line wrap, check window size after each command and update the values of LINES and COLUMNS

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Keybindings

bind '"\e[A": history-search-backward'  # Up arrow: backward history search
bind '"\e[B": history-search-forward'   # Down arrow: forward history search

bind '"\e[1;5C":forward-word'           # CTRL-RIGHT goes forward one word
bind '"\e[1;5D":backward-word'          # CTRL-LEFT goes backward one word
bind -r "\C-s"                           # Disable CTRL-S from triggering forward-i-search

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Load custom prompt

source "$DOTFILE_DIR/.bashprompt_theme_cascade"
# source "$DOTFILE_DIR/.bashprompt_theme_pure"
# source "$DOTFILE_DIR/.bashprompt"
# if _has starship; then export STARSHIP_CONFIG="$DOTFILE_DIR/../starship/gaps.toml"; eval "$(starship init bash)"; fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Load aliases, fzf key-binds, and other functions

source "$DOTFILE_DIR/.bashfzf";
source "$DOTFILE_DIR/.bashfunctions";
source "$DOTFILE_DIR/.bashaliases";

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Notes

# Set/Unset bash configuration options
# Run `set -o` or shopt to see all bash config options and their current settings
# https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
# https://unix.stackexchange.com/questions/32409/set-and-shopt-why-two

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
