#!/usr/bin/env bash
#
# Installs CLI tools suitable for any machine, including headless servers.
# Tools: fzf, fd, bat, ripgrep, eza, delta, fresh, neovim, nvim-plugins
#
# Usage:
#   ./setup_apps_cli.sh [--dry-run] [--update] [tool ...]
#
#   --update   Check for newer versions and update any that are outdated
#
# Examples:
#   ./setup_apps_cli.sh                        # install all tools
#   ./setup_apps_cli.sh --update               # update all tools
#   ./setup_apps_cli.sh --update fzf bat       # update only fzf and bat
#   ./setup_apps_cli.sh neovim nvim-plugins    # install only neovim + plugins

set -u

DRY_RUN=false
FORCE_UPDATE=false
SELECTED_TOOLS=()

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --update)  FORCE_UPDATE=true ;;
        -h|--help)
            printf "Usage: ./setup_apps_cli.sh [--dry-run] [--update] [tool ...]\n"
            printf "\n"
            printf "  Installs CLI tools suitable for any machine, including headless servers.\n"
            printf "\n"
            printf "  --update    Update installed tools to the latest version if outdated\n"
            printf "  --dry-run   Print commands without executing them\n"
            printf "\n"
            printf "  Available tools:\n"
            printf "    fzf  fd  bat  ripgrep  eza  delta  fresh  neovim  nvim-plugins\n"
            printf "\n"
            printf "  If no tools are specified, all tools are installed/updated.\n"
            exit 0 ;;
        -*)
            printf "Unknown option: %s\n" "$arg" >&2; exit 1 ;;
        *)
            SELECTED_TOOLS+=("$arg") ;;
    esac
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================
# Installers
# ============================================================
install_fzf() {
    log_section "fzf"

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed fzf && { log_skip "fzf"; return; }
    elif is_installed fzf; then
        local installed latest
        installed=$(fzf --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "junegunn/fzf")
        up_to_date "fzf" "$installed" "$latest" && return
    fi

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

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed fd && { log_skip "fd"; return; }
    elif is_installed fd; then
        local installed latest
        installed=$(fd --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "sharkdp/fd")
        up_to_date "fd" "$installed" "$latest" && return
    fi

    case "$DISTRO" in
        macos)  pkg_install fd ;;
        ubuntu)
            gh_install_pkg "sharkdp/fd" "fd_[^/]*_${DEB_ARCH}\\.deb" "" "fd"
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

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed bat && { log_skip "bat"; return; }
    elif is_installed bat; then
        local installed latest
        installed=$(bat --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "sharkdp/bat")
        up_to_date "bat" "$installed" "$latest" && return
    fi

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

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed rg && { log_skip "ripgrep"; return; }
    elif is_installed rg; then
        local installed latest
        installed=$(rg --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "BurntSushi/ripgrep")
        up_to_date "ripgrep" "$installed" "$latest" && return
    fi

    case "$DISTRO" in
        macos)  pkg_install ripgrep ;;
        ubuntu) gh_install_pkg "BurntSushi/ripgrep" "${DEB_ARCH}\\.deb" "" "ripgrep" ;;
        fedora) gh_install_pkg "BurntSushi/ripgrep" "" "${RPM_ARCH}\\.rpm" "ripgrep" ;;
    esac
}

install_eza() {
    log_section "eza"

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed eza && { log_skip "eza"; return; }
    elif is_installed eza; then
        local installed latest
        installed=$(eza --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "eza-community/eza")
        up_to_date "eza" "$installed" "$latest" && return
    fi

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

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed delta && { log_skip "delta"; return; }
    elif is_installed delta; then
        local installed latest
        installed=$(delta --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "dandavison/delta")
        up_to_date "delta" "$installed" "$latest" && return
    fi

    case "$DISTRO" in
        macos)  pkg_install git-delta ;;
        ubuntu) gh_install_pkg "dandavison/delta" "git-delta_[^/]*_${DEB_ARCH}\\.deb" "" "delta" ;;
        fedora) gh_install_pkg "dandavison/delta" "" "${RPM_ARCH}\\.rpm" "delta" ;;
    esac
}

install_fresh() {
    log_section "fresh"

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed fresh && { log_skip "fresh"; return; }
    elif is_installed fresh; then
        local installed latest
        installed=$(fresh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "sinelaw/fresh")
        up_to_date "fresh" "$installed" "$latest" && return
    fi

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

    if [[ "$FORCE_UPDATE" == false ]]; then
        is_installed nvim && { log_skip "Neovim"; return; }
    elif is_installed nvim; then
        local installed latest
        installed=$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        latest=$(gh_latest_version "neovim/neovim")
        up_to_date "Neovim" "$installed" "$latest" && return
    fi

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

install_nvim_plugins() {
    log_section "Neovim plugins"
    local pack_dir="$HOME/.local/share/nvim/site/pack"

    # Catppuccin: provides both light (latte) and dark (mocha) themes
    local catppuccin_dir="$pack_dir/themes/start/catppuccin"
    if [[ "$FORCE_UPDATE" == false ]] && [[ -d "$catppuccin_dir" ]]; then
        log_skip "catppuccin"
    elif [[ -d "$catppuccin_dir" ]]; then
        local installed latest
        installed=$(git -C "$catppuccin_dir" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
        latest=$(gh_latest_version "catppuccin/nvim")
        if up_to_date "catppuccin" "$installed" "$latest"; then
            return
        fi
        log_info "Updating catppuccin..."
        run git -C "$catppuccin_dir" fetch --tags --depth 1
        run git -C "$catppuccin_dir" checkout "$(git -C "$catppuccin_dir" describe --tags "$(git -C "$catppuccin_dir" rev-list --tags --max-count=1)")"
    else
        log_info "Installing catppuccin..."
        run mkdir -p "$pack_dir/themes/start"
        run git clone --depth 1 https://github.com/catppuccin/nvim.git "$catppuccin_dir"
    fi
}

# ============================================================
# Main
# ============================================================

# Ordered list of "name:function" pairs — defines both the available tool names
# and the order in which they are installed.
TOOLS=(
    "fzf:install_fzf"
    "fd:install_fd"
    "bat:install_bat"
    "ripgrep:install_ripgrep"
    "eza:install_eza"
    "delta:install_delta"
    "fresh:install_fresh"
    "neovim:install_neovim"
    "nvim-plugins:install_nvim_plugins"
)

main() {
    # Validate any tool names given on the command line
    local known_names=()
    for entry in "${TOOLS[@]}"; do known_names+=("${entry%%:*}"); done

    for name in "${SELECTED_TOOLS[@]}"; do
        local found=false
        for known in "${known_names[@]}"; do
            [[ "$name" == "$known" ]] && { found=true; break; }
        done
        if [[ "$found" == false ]]; then
            printf "Unknown tool: %s\nAvailable: %s\n" "$name" "${known_names[*]}" >&2
            exit 1
        fi
    done

    if [[ "$FORCE_UPDATE" == true ]]; then
        log_info "Update mode — checking for newer versions of CLI tools"
    fi

    for entry in "${TOOLS[@]}"; do
        local name="${entry%%:*}"
        local func="${entry##*:}"

        # Skip if a tool filter was given and this tool isn't in it
        if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
            local selected=false
            for s in "${SELECTED_TOOLS[@]}"; do
                [[ "$s" == "$name" ]] && { selected=true; break; }
            done
            [[ "$selected" == false ]] && continue
        fi

        try_step "$func"
    done
}

main "$@"
