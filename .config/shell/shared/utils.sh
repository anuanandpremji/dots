#!/bin/sh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Reusable functions and command wrappers — shared by Bash and Zsh                                                    ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Overview                                                                                                            ║
#║ --------                                                                                                            ║
#║ _has()                  - Check if a command exists                                                                 ║
#║ __has()                 - Check if a command exists, print error if not                                             ║
#║ _detect_color_scheme()  - Return "dark" or "light" based on the system theme (gsettings / darkman)                 ║
#║ confirm()               - Prompt for yes/no confirmation before proceeding                                          ║
#║ open_command()          - Open a file, directory, or URL in the default system app (Linux, macOS, WSL)              ║
#║ open_path()             - Open a path in the system file explorer (Linux, macOS, WSL)                               ║
#║ detect_clipboard()      - Define clipcopy() and clippaste() for the detected platform                               ║
#║ copyabsolutepath()      - Copy the absolute path of a file or directory to the clipboard                            ║
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
# Tries gsettings (GNOME/GTK) first, then darkman, then falls back to "dark".

_detect_color_scheme() {
    local scheme
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
    case "$scheme" in
        prefer-dark)          printf dark;  return ;;
        prefer-light|default) printf light; return ;;
    esac
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

# open_command() - Open the given dir/file/link in the default system app across Linux, MacOS or WSL

open_command()
{
    local open_cmd;

    case "$OSTYPE" in
        darwin*)    open_cmd='open' ;;
        linux*)     if [[ "$(uname -r)" == *icrosoft* ]]; then
                        open_cmd='wslview';
                    else
                        open_cmd='nohup xdg-open';
                    fi ;;
        *)          printf "Platform %s not supported.\n" "$OSTYPE"; return 1 ;;
    esac

    # zsh: ${=open_cmd} enables word splitting on the variable (disabled by default in zsh).
    # bash: unquoted $open_cmd also word-splits, but ${=...} is not valid syntax.
    if   [ -n "$ZSH_VERSION"  ]; then ${=open_cmd} "$@" >/dev/null 2>&1
    elif [ -n "$BASH_VERSION" ]; then $open_cmd "$@" >/dev/null 2>&1
    fi
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# open_path() - Open the given dir/file in the default file explorer across Linux, MacOS or WSL

# Dependencies: open_command()

open_path()
{
    if [ -d "$1" ]; then open_command "$1"; else open_command "$(dirname "$1")"; fi
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# detect_clipboard() - Defines two clipboard functions, clipcopy() and clippaste(), based on the detected platform

# clipcopy() - Copy data to clipboard
#    <command> | clipcopy  - copies stdin to clipboard
#    clipcopy <file>       - copies a file's contents to clipboard

# clippaste() - Paste data from clipboard to stdout
#    clippaste             - paste clipboard's contents to stdout
#    clippaste | <command> - pipe clipboard's content to another process
#    clippaste > <file>    - paste contents to a file

detect_clipboard()
{
    if [[ "${OSTYPE}" == darwin* ]] && _has pbcopy && _has pbpaste; then
        clipcopy()  { pbcopy < "${1:-/dev/stdin}"; }
        clippaste() { pbpaste; }

    elif [[ "$(uname -r)" == *icrosoft* ]]; then
        clipcopy()  { clip.exe < "${1:-/dev/stdin}"; }
        clippaste() { powershell.exe -noprofile -command Get-Clipboard; }

    elif [ -n "${WAYLAND_DISPLAY:-}" ] && _has wl-copy && _has wl-paste; then
        clipcopy()  { wl-copy < "${1:-/dev/stdin}"; }
        clippaste() { wl-paste; }

    elif [ -n "${DISPLAY:-}" ] && _has xclip; then
        clipcopy()  { xclip -in -selection clipboard < "${1:-/dev/stdin}"; }
        clippaste() { xclip -out -selection clipboard; }

    elif [ -n "${DISPLAY:-}" ] && _has xsel; then
        clipcopy()  { xsel --clipboard --input < "${1:-/dev/stdin}"; }
        clippaste() { xsel --clipboard --output; }

    elif [ -n "${TMUX:-}" ] && _has tmux; then
        clipcopy()  { tmux load-buffer "${1:--}"; }
        clippaste() { tmux save-buffer -; }

    else
        _retry_clipboard_detection_or_fail()
        {
            local clipcmd="${1}"; shift
            if detect_clipboard; then
                "${clipcmd}" "$@"
            else
                printf '%s: Platform %s not supported. clipcopy() and clippaste() will not be loaded.\n' "$clipcmd" "$OSTYPE" >&2
                return 1
            fi
        }
        clipcopy()  { _retry_clipboard_detection_or_fail clipcopy "$@"; }
        clippaste() { _retry_clipboard_detection_or_fail clippaste "$@"; }
        return 1
    fi
}

# Detect at startup. A non-zero exit here indicates that the dummy clipboards were set,
# which is not really an error. If the user calls them, they will attempt to re-detect
# (for example, perhaps the user has now installed xclip) and then either print an error
# or proceed successfully.
detect_clipboard || true;

# TODO: Refactor this. Make failing more intentional.

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# copyabsolutepath() - Copy the absolute path of a given directory/file ($PWD if no parameter given) to the clipboard

# Dependencies: clipcopy()

copyabsolutepath() {
    # If no argument passed, use current directory
    local file="${1:-$PWD}";

    # If argument is not an absolute path, prepend $PWD
    [[ $file = /* ]] || file="$PWD/$file";

    if [ -n "$ZSH_VERSION" ]; then
        # zsh: ${file:a} resolves the path (follows symlinks); print -n writes without newline
        print -n "${file:a}" | clipcopy || return 1;
        printf ${(%):-"%B\"${file:a}\"%b copied to clipboard.\n"};
    elif [ -n "$BASH_VERSION" ]; then
        # bash: no built-in path resolution; use the path as given (may contain ..)
        printf '%s' "$file" | clipcopy || return 1;
        printf '"%s" copied to clipboard.\n' "$file";
    fi
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Dependency check

# Environment variables
if ! _has "$EDITOR";        then printf "EDITOR: environment variable not set or invalid.\n";     fi
if ! _has "$VISUAL";        then printf "VISUAL: environment variable not set or invalid.\n";     fi

# Local functions (defined in this file)
if ! _has confirm;          then printf "confirm(): function not loaded.\n";                      fi
if ! _has clipcopy;         then printf "clipcopy(): function not loaded.\n";                     fi
if ! _has copyabsolutepath; then printf "copyabsolutepath(): function not loaded.\n";             fi
if ! _has open_command;     then printf "open_command(): function not loaded.\n";                 fi
if ! _has open_path;        then printf "open_path(): function not loaded.\n";                    fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
