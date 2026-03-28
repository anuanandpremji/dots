#!/usr/bin/env bash
#
# Installs base system packages, sets up the package manager, and configures Flathub (Linux).
# On macOS, installs Homebrew first if not already present.
#
# Usage:
#   ./setup_system.sh [--dry-run] [--server]
#
#   --server   Install CLI-only packages (no GUI dependencies); skips Flathub

set -u

DRY_RUN=false
SERVER_MODE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --server)  SERVER_MODE=true ;;
        -h|--help)
            printf "Usage: ./setup_system.sh [--dry-run] [--server]\n"
            printf "\n"
            printf "  Installs base system packages, sets up the package manager, and configures\n"
            printf "  Flathub (Linux). On macOS, installs Homebrew first if not already present.\n"
            printf "\n"
            printf "  --server    Install CLI-only packages (no GUI dependencies); skips Flathub\n"
            printf "  --dry-run   Print commands without executing them\n"
            exit 0 ;;
        *)
            printf "Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
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
# Flathub
# ============================================================
setup_flathub() {
    if [[ "$OS" != "linux" ]]; then return; fi
    if [[ "$SERVER_MODE" == true ]]; then return; fi

    log_section "Flathub"
    if ! is_installed flatpak; then log_skip "Flathub (flatpak not installed)"; return; fi

    if ! flatpak remotes | grep -q flathub; then
        log_info "Adding Flathub repository..."
        run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    else
        log_skip "Flathub"
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    try_step install_homebrew
    try_step pkg_update
    try_step install_system_packages
    try_step setup_flathub
}

main "$@"
