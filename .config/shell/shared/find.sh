#!/bin/sh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ File & text search — shared by Bash and Zsh                                                                         ║
#║ --------                                                                                                            ║
#║ fzf_file_widget() - Fuzzy search files & directories system-wide (CTRL-T)                                           ║
#║                                                                                                                     ║
#║ Requires: fzf >= 0.56 (--style=full, --ghost). Install via setup_apps_cli.sh, not the system package manager.       ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

if ! command -v fzf >/dev/null 2>&1; then printf "fzf not found.\n"; return; fi

# Fuzzy search files & directories and then press:
# ?        - toggle a preview window for truncated entries
# CTRL-S   - cycle between Directories/Files
# ENTER    - paste the selected entry
# ALT  + C - cd to directory (or parent directory of file)
# CTRL + V - open the selected entry in zed editor
# CTRL + N - open the selected entry in $VISUAL
# CTRL + O - open the selected entry in the default system app
# CTRL + E - open the selected entry in the default file explorer
# CTRL + Y - yank the absolute path to the clipboard

fzf_file_widget()
{
    local output key sel
    local -a lines
    local find_cmd="fd -I --full-path --hidden --exclude .git"
    local search_path="/"

    local -a fzf_opts=(
        --exit-0
        --expect=ctrl-o,ctrl-v,ctrl-n,ctrl-y,ctrl-e,alt-c
        --highlight-line
        --style=full
        --preview 'echo {}'
        --preview-window down:3:hidden:wrap-word
        --preview-label=' Full Path '
        --preview-label-pos=2
        --ghost 'Search directories system-wide...'
        --header-border=line
        --footer " ↵ Paste │ ^S Switch View │ Alt-C cd │ ^V Zed │ ^N \$VISUAL │ ^E Explorer │ ^O Open │ ^Y Copy │ ? Preview"
        --footer-border=line
        --color 'label:yellow:bold,header:dim'
        --prompt 'Directories ▶ '
        --scheme=path
        --bind '?:toggle-preview'
        --bind "ctrl-s:transform:
            if [[ \$FZF_PROMPT =~ Directories ]]; then
                echo 'change-prompt(Files ▶ )+reload($find_cmd --type f . $search_path)+change-ghost(Search files system-wide...)';
            else
                echo 'change-prompt(Directories ▶ )+reload($find_cmd --type d . $search_path)+change-ghost(Search directories system-wide...)';
            fi"
    );

    # Run the initial fd command. In zsh, word-splitting is off by default so we use ${=find_cmd};
    # in bash, unquoted $find_cmd word-splits naturally.
    if [ -n "$ZSH_VERSION" ]; then
        output=$($=find_cmd --type d . "$search_path" | fzf "${fzf_opts[@]}") || { zle redisplay; return 0; }
    elif [ -n "$BASH_VERSION" ]; then
        output=$($find_cmd --type d . "$search_path" | fzf "${fzf_opts[@]}") || return 0
    fi

    if [ -n "$ZSH_VERSION" ]; then
        lines=("${(@f)output}")
        key=${lines[1]}
        sel=${lines[2]}
    elif [ -n "$BASH_VERSION" ]; then
        mapfile -t lines <<< "$output"
        key="${lines[0]}"
        sel="${lines[1]}"
    fi

    if [ -z "$sel" ]; then
        [ -n "$ZSH_VERSION" ] && zle redisplay
        return 0
    fi

    if   [[ "$key" == ctrl-o ]]; then open-command "$sel"
    elif [[ "$key" == ctrl-v ]]; then zed "$sel"
    elif [[ "$key" == ctrl-n ]]; then "$VISUAL" "$sel"
    elif [[ "$key" == ctrl-e ]]; then open-path "$sel"
    elif [[ "$key" == ctrl-y ]]; then copypath "$sel"
    elif [[ "$key" == alt-c  ]]; then
        if [[ -d "$sel" ]]; then cd "$sel"; else cd "$(dirname "$sel")"; fi
        if [ -n "$ZSH_VERSION" ]; then zle reset-prompt; return 0; fi
    else
        # Insert selection at cursor position
        if [ -n "$ZSH_VERSION" ]; then
            LBUFFER="${LBUFFER}${sel}"
        elif [ -n "$BASH_VERSION" ]; then
            READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${sel}${READLINE_LINE:$READLINE_POINT}"
            READLINE_POINT=$(( READLINE_POINT + ${#sel} ))
        fi
    fi

    [ -n "$ZSH_VERSION" ] && zle redisplay
}

# Bind CTRL-T to fzf_file_widget()
if   [ -n "$ZSH_VERSION"  ]; then
    zle      -N  fzf_file_widget
    bindkey '^T' fzf_file_widget
elif [ -n "$BASH_VERSION" ]; then
    bind -m emacs-standard -x '"\C-t": fzf_file_widget'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Dependency check

if ! _has fd;           then printf "fd: program not found. Install fd-find.\n";   fi
if ! _has clipcopy;     then printf "clipcopy: script not found in PATH.\n";    fi
if ! _has copypath;     then printf "copypath: script not found in PATH.\n";    fi
if ! _has open-command; then printf "open-command: script not found in PATH.\n"; fi
if ! _has open-path;    then printf "open-path: script not found in PATH.\n";   fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
