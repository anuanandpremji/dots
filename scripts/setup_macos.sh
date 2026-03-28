#!/usr/bin/env bash
#
# macOS-specific setup: writes a Brewfile to the dotfiles root listing all managed
# Homebrew packages and casks. No-op on Linux.
#
# Usage: ./setup_macos.sh [--dry-run]

set -u

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            printf "Usage: ./setup_macos.sh [--dry-run]\n"
            printf "\n"
            printf "  Writes a Brewfile to the dotfiles root listing all managed Homebrew\n"
            printf "  packages and casks. macOS only — no-op on Linux.\n"
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

if [[ "$DISTRO" != "macos" ]]; then
    log_warn "setup_macos.sh is macOS-only. Nothing to do on $DISTRO."
    exit 0
fi

generate_brewfile() {
    log_section "Generating Brewfile"
    local brewfile="$DOTFILES/Brewfile"

    run cat > "$brewfile" <<'EOF'
# CLI Tools
brew "git"
brew "curl"
brew "wget"
brew "zsh"
brew "fzf"
brew "fd"
brew "bat"
brew "ripgrep"
brew "eza"
brew "git-delta"
brew "tree"
brew "fresh-editor"
brew "neovim"

# GUI Apps
cask "dropbox"
cask "wezterm"
cask "visual-studio-code"
cask "zed"
cask "firefox"
cask "google-chrome"
cask "brave-browser"
cask "obsidian"
cask "typora"
EOF

    log_info "Brewfile written to $brewfile"
    log_info "Install everything at once with: brew bundle --file=$brewfile"
}

generate_brewfile
