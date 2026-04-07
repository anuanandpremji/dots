#!/bin/sh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Reusable functions — shared by Bash and Zsh                                                                         ║
#║                                                                                                                     ║
#║ Only shell builtins and functions that MUST run in the current process live here.                                   ║
#║ Standalone utilities (clipboard, open, copypath) are scripts in .local/bin/.                                        ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Overview                                                                                                            ║
#║ --------                                                                                                            ║
#║ _has()                  - Check if a command exists                                                                 ║
#║ __has()                 - Check if a command exists, print error if not                                             ║
#║ _detect_color_scheme()  - Return "dark" or "light" based on the system theme (gsettings / darkman / macOS)          ║
#║ confirm()               - Prompt for yes/no confirmation before proceeding                                          ║
#║ cdgr()                  - cd to the outermost Git superproject root directory                                       ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# _has() - Check if a program is installed
# Note: also defined early in exports.sh so it can be used before this file is sourced.
# Keep both definitions identical.

_has()
{
    command -v "$1" >/dev/null 2>&1;
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# __has() - Check if a program is installed and return a message if not found

__has()
{
    if ! _has "$1"; then printf "%s not found.\n" "$1"; return 1; fi
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# _detect_color_scheme() - Returns "dark" or "light" based on the system theme.
# Tries gsettings (GNOME/GTK) first, then macOS defaults, then darkman, then falls back to "dark".

_detect_color_scheme() {
    # GNOME / freedesktop (Linux)
    local scheme
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
    case "$scheme" in
        prefer-dark)          printf dark;  return ;;
        prefer-light|default) printf light; return ;;
    esac
    # macOS
    local mac_style
    mac_style=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
    if [ "$mac_style" = "Dark" ]; then printf dark; return; fi
    if [ -z "$mac_style" ];       then printf light; return; fi
    # darkman
    if command -v darkman >/dev/null 2>&1; then darkman get 2>/dev/null && return; fi
    printf dark
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# confirm() - Confirm user input and based on it, proceed or abort the operation at hand

# Usage (call with a prompt string or use a default):
# - With custom user input:
#        $ if confirm 'Install Software?'; then echo "Installing Software"; else echo "Cancelled"; fi
# - Without user input (uses default message):
#        $ if confirm; then echo "Done"; else echo "Cancelled"; fi

confirm()
{
    printf "%s\n" "${1:-Are you sure you want to continue? Reply with [Y]es or [N]o and then press ENTER.}";

    while true; do
        read -r REPLY;
        case "$REPLY" in
            [yY][eE][sS]|[yY])  return 0; ;;
            [nN][oO]|[nN])      return 1; ;;
            *)                  printf 'Please reply with either [Y]es or [N]o.\n'; ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

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

# Dependency check

# Environment variables
if ! _has "$EDITOR";        then printf "EDITOR: environment variable not set or invalid.\n";     fi
if ! _has "$VISUAL";        then printf "VISUAL: environment variable not set or invalid.\n";     fi

# Standalone scripts (should be in PATH via .local/bin/)
if ! _has clipcopy;         then printf "clipcopy: script not found in PATH.\n";                  fi
if ! _has clippaste;        then printf "clippaste: script not found in PATH.\n";                 fi
if ! _has open-command;     then printf "open-command: script not found in PATH.\n";              fi
if ! _has open-path;        then printf "open-path: script not found in PATH.\n";                 fi
if ! _has copypath;         then printf "copypath: script not found in PATH.\n";                  fi
if ! _has git;              then printf "git: program not found. Install git.\n";                 fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
