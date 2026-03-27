#!/bin/sh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Git shell functions — shared by Bash and Zsh                                                                        ║
#║                                                                                                                     ║
#║ Only cdgr() must be sourced (it modifies the shell's working directory via cd).                                     ║
#║ All other git utilities are standalone scripts in scripts/: gl, gc, ga, gho, gr.                                    ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# cdgr() - cd to the outermost Git superproject root directory

cdgr()
{
    local gitroot;
    gitroot="$(command git rev-parse --show-toplevel)";

    [ -z "$gitroot" ] && return 1;

    while [ -n "$gitroot" ]; do
        cd "$gitroot" || return 1;
        gitroot="$(command git rev-parse --show-superproject-working-tree 2>/dev/null)";
    done

    return 0;
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

if ! _has git; then printf "git: program not found. Install git.\n"; fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
