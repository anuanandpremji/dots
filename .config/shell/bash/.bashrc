#!/bin/bash

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ .bashrc is always loaded first and has to live at `$HOME/.bashrc`                                                   ║
#║ So either source this file from `$HOME/.bashrc`                                                                     ║
#║ Or symlink this file using:                                                                                         ║
#║ ln -sf "<path/to/this/file>" "$HOME/.bashrc"                                                                        ║
#║                                                                                                                     ║
#║ Read http://mywiki.wooledge.org/BashFAQ/028 to know why we are doing this                                           ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Set DOTFILE_DIR to point to the on-disk directory containing the .bashrc file

DOTFILE_DIR="$HOME/repo"; # Edit this to reflect your local config location
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

# Guard against system profile scripts (e.g. wezterm.sh, bash-preexec) setting HISTTIMEFORMAT,
# which would cause BASH to write #<timestamp> lines into the shared history file.
unset HISTTIMEFORMAT

# ── Exclude failed commands from the on-disk history ──────────────────────────
#
# ZSH has the `zshaddhistory` hook which lets you intercept a command before it
# is written to the history file (see .zshrc). BASH has no equivalent hook, so
# we emulate it with PROMPT_COMMAND + an EXIT trap:
#
# 1. __bash_save_successful_history() runs as the first entry in PROMPT_COMMAND,
#    BEFORE the prompt's set_prompt(). It captures $? immediately, decides
#    whether to append the command to $HISTFILE, and then `return`s the original
#    exit code so set_prompt() still sees it for the prompt symbol color.
#
# 2. On shell exit, BASH would normally flush the entire in-memory history list
#    (which includes failed commands) to $HISTFILE. The EXIT trap prevents this
#    by unsetting HISTFILE before the flush. No data is lost because successful
#    commands have already been written one-by-one by the function above.
#
# 3. The fzf history widget (Ctrl-R in .bashfzf) must NOT call `history -a`,
#    since that would also flush failed commands. The widget reads $HISTFILE
#    directly via `tac`, so it already sees every successful command written
#    by our handler — no flush needed.
#
# Edge cases handled:
#   - Empty Enter (no command)   → `history 1` returns the same entry as last
#                                   time; the __bash_last_hist guard skips it.
#   - First prompt after startup → __bash_last_hist is pre-initialized below,
#                                   so the last-loaded entry isn't re-written.
#   - Multi-line commands        → `sed` strips only the leading history number;
#                                   subsequent lines pass through intact.
#   - Ctrl-C (exit 130)         → treated as success, matching ZSH behavior.
#   - Whitespace-only input     → filtered out before writing.

__bash_save_successful_history() {
  local last_exit=$?
  local last_hist
  last_hist=$(HISTTIMEFORMAT='' builtin history 1)

  # Skip if same as last processed entry (empty Enter, first prompt)
  [[ "$last_hist" == "$__bash_last_hist" ]] && return $last_exit
  __bash_last_hist=$last_hist

  # Only save successful commands (exit 0) and Ctrl-C (exit 130)
  if [[ $last_exit -eq 0 || $last_exit -eq 130 ]]; then
    local cmd
    cmd=$(sed '1 s/^ *[0-9]\+  *//' <<< "$last_hist")
    # Skip whitespace-only commands
    if [[ -n "${cmd//[[:space:]]/}" ]]; then
      printf '%s\n' "$cmd" >> "$HISTFILE"
    fi
  fi

  # Pass through the original exit code so set_prompt() captures it correctly
  return $last_exit
}

# Pre-seed with the current last entry so the very first prompt doesn't
# re-write an already-persisted command from a previous session.
__bash_last_hist=$(HISTTIMEFORMAT='' builtin history 1)

# Prevent BASH from flushing in-memory history (including failed commands) to
# $HISTFILE on exit. Unsetting HISTFILE inside the EXIT trap means bash's
# internal save_history() finds nothing to write to. All successful commands
# have already been appended one-by-one by the handler above.
trap 'unset HISTFILE' EXIT

# Register the handler in PROMPT_COMMAND. Prompt themes loaded later append to
# this (e.g. set_prompt) rather than overwriting, so the handler always runs first.
PROMPT_COMMAND="__bash_save_successful_history"

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

bind '"\e[1~":beginning-of-line'        # Home key
bind '"\e[7~":beginning-of-line'        # Home key (alternate)
bind '"\eOH":beginning-of-line'         # Home key (alternate)
bind '"\e[H":beginning-of-line'         # Home key (alternate)
bind '"\e[4~":end-of-line'              # End key
bind '"\e[8~":end-of-line'              # End key (alternate)
bind '"\eOF":end-of-line'               # End key (alternate)
bind '"\e[F":end-of-line'               # End key (alternate)

bind '"\e[1;5C":forward-word'           # CTRL-RIGHT goes forward one word
bind '"\e[1;5D":backward-word'          # CTRL-LEFT goes backward one word
bind '"\C-H":backward-kill-word'        # CTRL-BACKSPACE deletes the previous word
bind '"\e[3;5~":kill-word'              # CTRL-DEL deletes the next word
bind -r "\C-s"                           # Disable CTRL-S from triggering forward-i-search

# CTRL-X CTRL-E edits current command in $VISUAL editor
__edit_command_line() {
  local tmpf
  tmpf=$(mktemp) || return 1
  printf '%s' "$READLINE_LINE" > "$tmpf"
  ${VISUAL:-${EDITOR:-vi}} "$tmpf" </dev/tty >/dev/tty
  READLINE_LINE=$(cat "$tmpf")
  READLINE_POINT=${#READLINE_LINE}
  rm -f "$tmpf"
}
bind -x '"\C-x\C-e": __edit_command_line'

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Load custom prompt

source "$DOTFILE_DIR/.bashprompt_theme_cascade"
# source "$DOTFILE_DIR/.bashprompt_theme_pure"
# source "$DOTFILE_DIR/.bashprompt"
# if _has starship; then export STARSHIP_CONFIG="$DOTFILE_DIR/../starship/gaps.toml"; eval "$(starship init bash)"; fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Load utils, fzf features, functions, and aliases

source "$DOTFILE_DIR/.bashutils";
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
