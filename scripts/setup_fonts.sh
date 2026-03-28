#!/usr/bin/env bash
#
# Copies fonts from the dotfiles repo to the system font directory.
#
# Usage: ./setup_fonts.sh [--dry-run]

set -u

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            printf "Usage: ./setup_fonts.sh [--dry-run]\n"
            printf "\n"
            printf "  Copies fonts from .local/share/fonts/ in the dotfiles repo to the system\n"
            printf "  font directory. Skips fonts that are already installed. Rebuilds the font\n"
            printf "  cache afterward (Linux only).\n"
            printf "\n"
            printf "  --dry-run   Print commands without executing them\n"
            exit 0 ;;
        *)
            printf "Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
    esac
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="${DOTFILES:-$(cd "$SCRIPTS_DIR/.." && pwd)}"
source "$SCRIPTS_DIR/lib/common.sh"

install_fonts() {
    log_section "Fonts"

    if [[ ! -d "$DOTFILES/.local/share/fonts" ]]; then
        log_warn "No fonts directory found at $DOTFILES/.local/share/fonts — skipping"
        return
    fi

    case "$DISTRO" in
        macos)
            log_info "Syncing fonts to ~/Library/Fonts/ (skipping existing)..."
            run mkdir -p "$HOME/Library/Fonts"
            if [[ "$DRY_RUN" == false ]]; then
                find "$DOTFILES/.local/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec sh -c '
                    for f; do
                        dest="$HOME/Library/Fonts/$(basename "$f")"
                        [ -f "$dest" ] || cp "$f" "$dest"
                    done
                ' _ {} +
            fi
            ;;
        *)
            log_info "Syncing fonts to ~/.local/share/fonts/ (skipping existing)..."
            run mkdir -p "$HOME/.local/share/fonts"
            if [[ "$DRY_RUN" == false ]]; then
                find "$DOTFILES/.local/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec sh -c '
                    for f; do
                        dest="$HOME/.local/share/fonts/$(basename "$f")"
                        [ -f "$dest" ] || cp "$f" "$dest"
                    done
                ' _ {} +
                if command -v fc-cache &>/dev/null; then
                    log_info "Rebuilding font cache..."
                    fc-cache -f
                fi
            fi
            ;;
    esac
}

install_fonts
