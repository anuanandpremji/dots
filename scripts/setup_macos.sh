#!/usr/bin/env bash
#
# macOS-specific setup: generates a Brewfile from currently installed apps.
# No-op on Linux.
#
# Usage: ./setup_macos.sh [--dry-run]

set -u

DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
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
