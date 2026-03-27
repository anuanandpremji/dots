#!/usr/bin/env bash
#
# Installs CLI tools suitable for any machine, including headless servers.
# Tools: fzf, fd, bat, ripgrep, eza, delta, fresh, neovim
#
# Usage:
#   ./setup_apps_cli.sh [--dry-run] [--update]
#
#   --update   Force-reinstall all tools from latest release (skips already-installed check)

set -u

DRY_RUN=false
FORCE_UPDATE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --update)  FORCE_UPDATE=true ;;
    esac
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================
# Installers
# ============================================================
install_fzf() {
    log_section "fzf"
    if [[ "$FORCE_UPDATE" == false ]] && is_installed fzf; then log_skip "fzf"; return; fi

    case "$DISTRO" in
        macos)
            pkg_install fzf
            ;;
        *)
            local tmp url
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            url=$(gh_latest_url "junegunn/fzf" "linux_${DEB_ARCH}\\.tar\\.gz")
            if [[ -z "$url" ]]; then log_error "Could not find fzf download URL (GitHub API rate limit?)"; return 1; fi
            log_info "Downloading fzf from $url"
            run curl -fsSL -o "$tmp/fzf.tar.gz" "$url"
            run tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
            run mkdir -p "$HOME/.local/bin"
            run mv "$tmp/fzf" "$HOME/.local/bin/fzf"
            run chmod +x "$HOME/.local/bin/fzf"
            log_info "fzf installed to ~/.local/bin/fzf"
            ;;
    esac
}

install_fd() {
    log_section "fd"

    # On Ubuntu, the .deb installs as 'fdfind' — symlink it
    if is_installed fdfind && ! is_installed fd; then
        log_info "fdfind found — creating fd symlink"
        run mkdir -p "$HOME/.local/bin"
        run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        [[ "$FORCE_UPDATE" == false ]] && return
    fi

    if [[ "$FORCE_UPDATE" == false ]] && is_installed fd; then log_skip "fd"; return; fi

    case "$DISTRO" in
        macos)  pkg_install fd ;;
        ubuntu)
            gh_install_pkg "sharkdp/fd" "${DEB_ARCH}\\.deb" "" "fd"
            if is_installed fdfind && ! is_installed fd; then
                run mkdir -p "$HOME/.local/bin"
                run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            fi
            ;;
        fedora) gh_install_pkg "sharkdp/fd" "" "${RPM_ARCH}\\.rpm" "fd" ;;
    esac
}

install_bat() {
    log_section "bat"

    # On Ubuntu, the .deb installs as 'batcat' — symlink it
    if is_installed batcat && ! is_installed bat; then
        log_info "batcat found — creating bat symlink"
        run mkdir -p "$HOME/.local/bin"
        run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        [[ "$FORCE_UPDATE" == false ]] && return
    fi

    if [[ "$FORCE_UPDATE" == false ]] && is_installed bat; then log_skip "bat"; return; fi

    case "$DISTRO" in
        macos)  pkg_install bat ;;
        ubuntu)
            gh_install_pkg "sharkdp/bat" "bat_[^/]*_${DEB_ARCH}\\.deb" "" "bat"
            if is_installed batcat && ! is_installed bat; then
                run mkdir -p "$HOME/.local/bin"
                run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
            fi
            ;;
        fedora) gh_install_pkg "sharkdp/bat" "" "${RPM_ARCH}\\.rpm" "bat" ;;
    esac
}

install_ripgrep() {
    log_section "ripgrep"
    if [[ "$FORCE_UPDATE" == false ]] && is_installed rg; then log_skip "ripgrep"; return; fi

    case "$DISTRO" in
        macos)  pkg_install ripgrep ;;
        ubuntu) gh_install_pkg "BurntSushi/ripgrep" "${DEB_ARCH}\\.deb" "" "ripgrep" ;;
        fedora) gh_install_pkg "BurntSushi/ripgrep" "" "${RPM_ARCH}\\.rpm" "ripgrep" ;;
    esac
}

install_eza() {
    log_section "eza"
    if [[ "$FORCE_UPDATE" == false ]] && is_installed eza; then log_skip "eza"; return; fi

    case "$DISTRO" in
        macos)  pkg_install eza ;;
        ubuntu)
            if [[ ! -f /etc/apt/keyrings/gierens.gpg ]]; then
                log_info "Adding eza apt repository..."
                run sudo mkdir -p /etc/apt/keyrings
                run bash -c 'wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg'
                run bash -c 'echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list'
                run sudo apt-get update
            fi
            pkg_install eza
            ;;
        fedora) pkg_install eza ;;
    esac
}

install_delta() {
    log_section "delta"
    if [[ "$FORCE_UPDATE" == false ]] && is_installed delta; then log_skip "delta"; return; fi

    case "$DISTRO" in
        macos)  pkg_install git-delta ;;
        ubuntu) gh_install_pkg "dandavison/delta" "${DEB_ARCH}\\.deb" "" "delta" ;;
        fedora) gh_install_pkg "dandavison/delta" "" "${RPM_ARCH}\\.rpm" "delta" ;;
    esac
}

install_fresh() {
    log_section "fresh"
    if [[ "$FORCE_UPDATE" == false ]] && is_installed fresh; then log_skip "fresh"; return; fi

    case "$DISTRO" in
        macos)
            run brew tap sinelaw/fresh
            pkg_install fresh-editor
            ;;
        *)
            log_info "Installing fresh from official installer..."
            run bash -c "curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh"
            ;;
    esac
}

install_neovim() {
    log_section "Neovim"
    if [[ "$FORCE_UPDATE" == false ]] && is_installed nvim; then log_skip "Neovim"; return; fi

    case "$DISTRO" in
        macos)
            pkg_install neovim
            ;;
        *)
            local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage"
            log_info "Downloading Neovim from $url"
            run mkdir -p "$HOME/.local/bin"
            run curl -fsSL -o "$HOME/.local/bin/nvim" "$url"
            run chmod +x "$HOME/.local/bin/nvim"
            ;;
    esac
}

# ============================================================
# Main
# ============================================================
main() {
    if [[ "$FORCE_UPDATE" == true ]]; then
        log_info "Update mode — reinstalling all CLI tools from latest release"
    fi

    try_step install_fzf
    try_step install_fd
    try_step install_bat
    try_step install_ripgrep
    try_step install_eza
    try_step install_delta
    try_step install_fresh
    try_step install_neovim
}

main "$@"
