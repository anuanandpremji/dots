#!/bin/sh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Shell aliases — shared by Bash and Zsh                                                                              ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Better defaults with added verbosity

alias cls='clear'
alias cp='cp -v'
alias grep='grep -i --color=auto'
alias ln='ln -v'
alias mkdir='mkdir -v'
alias mv='mv -iv'
alias rm='rm -v'

if [ "$(uname)" = "Linux" ]; then
    alias ip='ip -color=auto'
    alias lsblk='lsblk -e7 -p -o NAME,SIZE,VENDOR,MODEL,SERIAL,LABEL,MOUNTPOINT,TYPE,FSTYPE'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Better cd

alias cd..='cd ..'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias ........='cd ../../../..'
alias ..........='cd ../../../../..'

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Better ls with eza

if _has eza; then
    alias l='eza --oneline --all --group-directories-first --icons --sort=name --long --header --no-user --octal-permissions'
    alias ls='eza --all --group-directories-first --icons --octal-permissions'
elif [ "$(uname)" = "Darwin" ]; then
    alias l='ls -lAFhG'
    alias ls='ls -AFhG'
else
    alias l='ls -lAFh --color=always --group-directories-first'
    alias ls='ls -AFh --color=always --group-directories-first'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Open current folder in the default files app

alias nnn='open_command "$PWD"'

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Reload the current shell

if   [ -n "$ZSH_VERSION"  ]; then alias rerc='exec zsh'
elif [ -n "$BASH_VERSION" ]; then alias rerc='exec bash'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Linux-only aliases

if [ "$(uname)" = "Linux" ]; then
    alias switchpython='sudo update-alternatives --config python'
    alias fixsnap='sudo killall -s KILL snap-store && sudo snap refresh'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Better cat with bat (syntax highlighting, line numbers)

if _has bat; then
    alias cat='bat --paging=never --theme=auto'
elif _has batcat; then
    alias cat='batcat --paging=never --theme=auto'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Git

alias g='git'
alias gfatp='git fetch --all --tags --prune'

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# XDG compliance wrappers
# These redirect tools to use XDG dirs instead of cluttering $HOME.
# Aliases are intentionally here (not exports.sh) — they only apply to interactive shells.

alias kubectl='kubectl --cache-dir "$XDG_CACHE_HOME/kube/http"'
alias svn='svn --config-dir "$XDG_CONFIG_HOME/subversion"'
alias tmux='tmux -f "$XDG_CONFIG_HOME/tmux/conf"'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

if [ "$(uname)" = "Linux" ]; then
    alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Docker

alias dpsl='docker ps --format "{{.Names}}" --filter status=running'

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Files

# Edit the dotfiles repo in $VISUAL
alias edrc='${VISUAL:-${EDITOR:-vi}} "$DOTFILES_PATH"'

# cd into the dotfiles repo
alias cdrc='cd "$DOTFILES_PATH"'

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
