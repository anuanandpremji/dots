#!/usr/bin/env bash
#
# Installs GUI applications: terminal, editors, browsers, and desktop apps.
# Tools: wezterm, vscode, zed, firefox, chrome, brave, dropbox, obsidian, typora, pdf-arranger
#
# Usage:
#   ./setup_apps_gui.sh [--dry-run] [--update] [tool ...]
#
# Examples:
#   ./setup_apps_gui.sh                          # install all apps
#   ./setup_apps_gui.sh --update                 # update all apps
#   ./setup_apps_gui.sh --update vscode brave    # update only VS Code and Brave
#   ./setup_apps_gui.sh zed obsidian             # install only Zed and Obsidian

set -u

DRY_RUN=false
FORCE_UPDATE=false
SELECTED_TOOLS=()

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --update)  FORCE_UPDATE=true ;;
        -h|--help)
            printf "Usage: ./setup_apps_gui.sh [--dry-run] [--update] [tool ...]\n"
            printf "\n"
            printf "  Installs GUI applications.\n"
            printf "\n"
            printf "  --update    Update installed apps to the latest version if outdated\n"
            printf "  --dry-run   Print commands without executing them\n"
            printf "\n"
            printf "  Available tools:\n"
            printf "    wezterm  vscode  zed  firefox  chrome  brave\n"
            printf "    dropbox  obsidian  typora  pdf-arranger\n"
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
# Terminal
# ============================================================
install_wezterm() {
    log_section "WezTerm"

    if [[ "$FORCE_UPDATE" == false ]]; then
        (is_installed wezterm || [[ -d "/Applications/WezTerm.app" ]]) && { log_skip "WezTerm"; return; }
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask wezterm || run brew install --cask wezterm
            else
                run brew install --cask wezterm
            fi
            ;;
        ubuntu)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed wezterm; then
                apt_up_to_date "WezTerm" "wezterm" && return
            fi
            if [[ ! -f /usr/share/keyrings/wezterm-fury.gpg ]]; then
                log_info "Adding WezTerm apt repository..."
                run bash -c 'curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg'
                run bash -c 'echo "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" | sudo tee /etc/apt/sources.list.d/wezterm.list'
                run sudo apt-get update
            fi
            pkg_install wezterm
            ;;
        fedora)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed wezterm; then
                run sudo dnf upgrade -y wezterm; return
            fi
            if ! dnf repolist --enabled 2>/dev/null | grep -q wezterm; then
                log_info "Adding WezTerm COPR repository..."
                run sudo dnf copr enable -y wezfurlong/wezterm-nightly
            fi
            pkg_install wezterm
            ;;
    esac
}

# ============================================================
# Editors
# ============================================================
install_vscode() {
    log_section "VS Code"

    if [[ "$FORCE_UPDATE" == false ]]; then
        (is_installed code || [[ -d "/Applications/Visual Studio Code.app" ]]) && { log_skip "VS Code"; return; }
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask visual-studio-code || run brew install --cask visual-studio-code
            else
                run brew install --cask visual-studio-code
            fi
            ;;
        ubuntu)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed code; then
                apt_up_to_date "VS Code" "code" && return
            fi
            if [[ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]]; then
                log_info "Adding Microsoft VS Code repository..."
                local tmp_gpg
                tmp_gpg=$(mktemp -d)
                trap "rm -rf '$tmp_gpg'" RETURN
                run bash -c "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --yes --dearmor -o '$tmp_gpg/packages.microsoft.gpg'"
                run sudo install -D -o root -g root -m 644 "$tmp_gpg/packages.microsoft.gpg" /etc/apt/keyrings/packages.microsoft.gpg
                run bash -c 'echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list'
                run sudo apt-get update
            fi
            pkg_install code
            ;;
        fedora)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed code; then
                run sudo dnf upgrade -y code; return
            fi
            if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
                log_info "Adding Microsoft VS Code repository..."
                run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                run bash -c 'cat <<REPO | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO'
                run sudo dnf check-update || true
            fi
            pkg_install code
            ;;
    esac
}

install_zed() {
    log_section "Zed"

    if [[ "$FORCE_UPDATE" == false ]]; then
        (is_installed zed || [[ -d "/Applications/Zed.app" ]]) && { log_skip "Zed"; return; }
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask zed || run brew install --cask zed
            else
                run brew install --cask zed
            fi
            ;;
        *)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed zed; then
                local installed latest
                installed=$(zed --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                latest=$(gh_latest_version "zed-industries/zed")
                up_to_date "Zed" "$installed" "$latest" && return
            fi
            run bash -c 'curl -f https://zed.dev/install.sh | sh'
            ;;
    esac
}

# ============================================================
# Browsers
# ============================================================
install_firefox() {
    log_section "Firefox"

    if [[ "$FORCE_UPDATE" == false ]]; then
        (is_installed firefox || [[ -d "/Applications/Firefox.app" ]]) && { log_skip "Firefox"; return; }
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask firefox || run brew install --cask firefox
            else
                run brew install --cask firefox
            fi
            ;;
        ubuntu)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed firefox; then
                apt_up_to_date "Firefox" "firefox" && return
            fi
            pkg_install firefox
            ;;
        fedora)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed firefox; then
                run sudo dnf upgrade -y firefox; return
            fi
            pkg_install firefox
            ;;
    esac
}

install_chrome() {
    log_section "Google Chrome"

    local _installed=false
    (is_installed google-chrome-stable || is_installed google-chrome || [[ -d "/Applications/Google Chrome.app" ]]) && _installed=true

    if [[ "$FORCE_UPDATE" == false ]] && [[ "$_installed" == true ]]; then
        log_skip "Google Chrome"; return
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask google-chrome || run brew install --cask google-chrome
            else
                run brew install --cask google-chrome
            fi
            ;;
        ubuntu)
            if [[ "$FORCE_UPDATE" == true ]] && [[ "$_installed" == true ]]; then
                # Chrome adds its own apt repo on first install — use it for updates
                apt_up_to_date "Google Chrome" "google-chrome-stable" && return
                pkg_install google-chrome-stable
                return
            fi
            local tmp
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            log_info "Downloading Google Chrome..."
            run curl -fsSL -o "$tmp/chrome.deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
            run sudo dpkg -i "$tmp/chrome.deb" || run sudo apt-get install -f -y
            ;;
        fedora)
            if [[ "$FORCE_UPDATE" == true ]] && [[ "$_installed" == true ]]; then
                run sudo dnf upgrade -y google-chrome-stable; return
            fi
            local tmp
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            log_info "Downloading Google Chrome..."
            run curl -fsSL -o "$tmp/chrome.rpm" "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
            run sudo dnf install -y "$tmp/chrome.rpm"
            ;;
    esac
}

install_brave() {
    log_section "Brave"

    if [[ "$FORCE_UPDATE" == false ]]; then
        (is_installed brave-browser || [[ -d "/Applications/Brave Browser.app" ]]) && { log_skip "Brave"; return; }
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask brave-browser || run brew install --cask brave-browser
            else
                run brew install --cask brave-browser
            fi
            ;;
        ubuntu)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed brave-browser; then
                apt_up_to_date "Brave" "brave-browser" && return
            fi
            if [[ ! -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]]; then
                log_info "Adding Brave repository..."
                run sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
                    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                run bash -c 'echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list'
                run sudo apt-get update
            fi
            pkg_install brave-browser
            ;;
        fedora)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed brave-browser; then
                run sudo dnf upgrade -y brave-browser; return
            fi
            if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
                log_info "Adding Brave repository..."
                run sudo dnf install -y dnf-plugins-core
                run sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                run sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            fi
            pkg_install brave-browser
            ;;
    esac
}

# ============================================================
# Desktop Apps
# ============================================================
install_dropbox() {
    log_section "Dropbox"

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask dropbox || run brew install --cask dropbox
                return
            fi
            if [[ -d "/Applications/Dropbox.app" ]]; then log_skip "Dropbox"; return; fi
            run brew install --cask dropbox
            ;;
        ubuntu)
            local _installed=false
            (is_installed dropbox || dpkg -s nautilus-dropbox &>/dev/null) && _installed=true

            if [[ "$_installed" == true ]]; then
                if [[ "$FORCE_UPDATE" == false ]]; then log_skip "Dropbox"; return; fi
                # Dropbox adds its own apt repo on first install — use it for updates
                apt_up_to_date "Dropbox" "nautilus-dropbox" && return
                pkg_install nautilus-dropbox
                return
            fi
            local tmp
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            log_info "Installing Dropbox (nautilus-dropbox)..."
            run curl -fsSL -o "$tmp/nautilus-dropbox.deb" \
                "https://linux.dropbox.com/packages/ubuntu/nautilus-dropbox_2026.01.15_all.deb"
            run sudo dpkg -i "$tmp/nautilus-dropbox.deb" || run sudo apt-get install -f -y
            ;;
        fedora)
            local _installed=false
            (is_installed dropbox || rpm -q nautilus-dropbox &>/dev/null) && _installed=true

            if [[ "$_installed" == true ]]; then
                if [[ "$FORCE_UPDATE" == false ]]; then log_skip "Dropbox"; return; fi
                run sudo dnf upgrade -y nautilus-dropbox
                return
            fi
            local tmp
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            log_info "Installing Dropbox (nautilus-dropbox)..."
            run curl -fsSL -o "$tmp/nautilus-dropbox.rpm" \
                "https://linux.dropbox.com/packages/fedora/nautilus-dropbox-2026.01.15-1.fc43.x86_64.rpm"
            run sudo dnf install -y "$tmp/nautilus-dropbox.rpm"
            ;;
    esac
}

install_obsidian() {
    log_section "Obsidian"

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask obsidian || run brew install --cask obsidian
                return
            fi
            if [[ -d "/Applications/Obsidian.app" ]]; then log_skip "Obsidian"; return; fi
            run brew install --cask obsidian
            ;;
        *)
            local _installed=false
            (is_installed obsidian || flatpak list 2>/dev/null | grep -q "md.obsidian.Obsidian") && _installed=true

            if [[ "$_installed" == true ]]; then
                if [[ "$FORCE_UPDATE" == false ]]; then log_skip "Obsidian"; return; fi
                flatpak_up_to_date "Obsidian" "md.obsidian.Obsidian" "obsidianmd/obsidian-releases" && return
                run flatpak update -y md.obsidian.Obsidian
                return
            fi
            log_info "Installing Obsidian via Flatpak..."
            run flatpak install -y flathub md.obsidian.Obsidian
            ;;
    esac
}

install_typora() {
    log_section "Typora"

    if [[ "$FORCE_UPDATE" == false ]]; then
        (is_installed typora || [[ -d "/Applications/Typora.app" ]]) && { log_skip "Typora"; return; }
    fi

    case "$DISTRO" in
        macos)
            if [[ "$FORCE_UPDATE" == true ]]; then
                run brew upgrade --cask typora || run brew install --cask typora
            else
                run brew install --cask typora
            fi
            ;;
        ubuntu)
            if [[ "$FORCE_UPDATE" == true ]] && is_installed typora; then
                apt_up_to_date "Typora" "typora" && return
            fi
            if [[ ! -f /etc/apt/keyrings/typora.gpg ]]; then
                log_info "Adding Typora apt repository..."
                run sudo mkdir -p /etc/apt/keyrings
                run bash -c 'curl -fsSL https://downloads.typora.io/typora.gpg | sudo tee /etc/apt/keyrings/typora.gpg > /dev/null'
                run bash -c 'echo "deb [signed-by=/etc/apt/keyrings/typora.gpg] https://downloads.typora.io/linux ./" | sudo tee /etc/apt/sources.list.d/typora.list'
                run sudo apt-get update
            fi
            pkg_install typora
            ;;
        fedora)
            if is_installed snap; then
                log_info "Installing Typora via Snap..."
                run sudo snap install typora
            else
                log_warn "Typora on Fedora requires Snap. Install snapd first, then re-run."
            fi
            ;;
    esac
}

install_pdf_arranger() {
    log_section "PDF Arranger"

    case "$DISTRO" in
        macos)
            log_warn "PDF Arranger is not available on macOS."
            ;;
        *)
            local _installed=false
            (is_installed pdfarranger || flatpak list 2>/dev/null | grep -q "com.github.jeromerobert.pdfarranger") && _installed=true

            if [[ "$_installed" == true ]]; then
                if [[ "$FORCE_UPDATE" == false ]]; then log_skip "PDF Arranger"; return; fi
                flatpak_up_to_date "PDF Arranger" "com.github.jeromerobert.pdfarranger" "pdfarranger/pdfarranger" && return
                run flatpak update -y com.github.jeromerobert.pdfarranger
                return
            fi
            log_info "Installing PDF Arranger via Flatpak..."
            run flatpak install -y flathub com.github.jeromerobert.pdfarranger
            ;;
    esac
}

# ============================================================
# Main
# ============================================================

# Ordered list of "name:function" pairs — defines both the available tool names
# and the order in which they are installed.
TOOLS=(
    "wezterm:install_wezterm"
    "vscode:install_vscode"
    "zed:install_zed"
    "firefox:install_firefox"
    "chrome:install_chrome"
    "brave:install_brave"
    "dropbox:install_dropbox"
    "obsidian:install_obsidian"
    "typora:install_typora"
    "pdf-arranger:install_pdf_arranger"
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
        log_info "Update mode — checking for newer versions of GUI apps"
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
