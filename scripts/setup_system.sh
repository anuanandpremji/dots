#!/usr/bin/env bash
#
# Installs base system packages and sets up the package manager.
#
# Usage:
#   ./setup_system.sh [--dry-run] [--server]
#
#   --server   Install CLI-only packages (no GUI dependencies)

set -u

DRY_RUN=false
SERVER_MODE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --server)  SERVER_MODE=true ;;
    esac
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================
# Homebrew (macOS only)
# ============================================================
install_homebrew() {
    if [[ "$DISTRO" != "macos" ]]; then return; fi

    log_section "Homebrew"
    if is_installed brew; then
        log_skip "Homebrew"
        return
    fi

    log_info "Installing Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ensure brew is on PATH for the rest of this script
    if ! is_installed brew; then
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

# ============================================================
# System Packages
# ============================================================
install_system_packages() {
    log_section "System packages"

    if [[ "$SERVER_MODE" == true ]]; then
        case "$DISTRO" in
            ubuntu) pkg_install git curl wget build-essential software-properties-common tree unzip ;;
            fedora) pkg_install git curl wget @development-tools tree unzip ;;
            macos)  pkg_install git curl wget tree ;;
        esac
        return
    fi

    case "$DISTRO" in
        ubuntu)
            pkg_install \
                git curl wget \
                build-essential software-properties-common \
                xclip wl-clipboard \
                meld tree unzip \
                flatpak gnome-software-plugin-flatpak \
                gnome-calendar gnome-tweaks
            ;;
        fedora)
            pkg_install \
                git curl wget \
                @development-tools \
                xclip wl-clipboard \
                meld tree unzip \
                flatpak \
                gnome-calendar gnome-tweaks
            ;;
        macos)
            pkg_install git curl wget meld tree
            ;;
    esac
}

# ============================================================
# Main
# ============================================================
main() {
    try_step install_homebrew
    try_step pkg_update
    try_step install_system_packages
}

main "$@"
