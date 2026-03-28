#!/usr/bin/env bash
#
# Installs GUI applications: terminal, editors, browsers, and desktop apps.
# Tools: WezTerm, VS Code, Zed, Firefox, Chrome, Brave, Dropbox, Obsidian, Typora, PDF Arranger
#
# Usage: ./setup_apps_gui.sh [--dry-run]

set -u

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            printf "Usage: ./setup_apps_gui.sh [--dry-run]\n"
            printf "\n"
            printf "  Installs GUI applications: WezTerm, VS Code, Zed, Firefox, Chrome, Brave,\n"
            printf "  Dropbox, Obsidian, Typora, and PDF Arranger.\n"
            printf "  Supports Ubuntu, Fedora, and macOS.\n"
            printf "\n"
            printf "  --dry-run   Print commands without executing them\n"
            exit 0 ;;
        *)
            printf "Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
    esac
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================
# Terminal
# ============================================================
install_wezterm() {
    log_section "WezTerm"
    if is_installed wezterm || [[ -d "/Applications/WezTerm.app" ]]; then log_skip "WezTerm"; return; fi

    case "$DISTRO" in
        macos)
            run brew install --cask wezterm
            ;;
        ubuntu)
            if [[ ! -f /usr/share/keyrings/wezterm-fury.gpg ]]; then
                log_info "Adding WezTerm apt repository..."
                run bash -c 'curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg'
                run bash -c 'echo "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" | sudo tee /etc/apt/sources.list.d/wezterm.list'
                run sudo apt-get update
            fi
            pkg_install wezterm
            ;;
        fedora)
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
    if is_installed code || [[ -d "/Applications/Visual Studio Code.app" ]]; then log_skip "VS Code"; return; fi

    case "$DISTRO" in
        macos)
            run brew install --cask visual-studio-code
            ;;
        ubuntu)
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
    if is_installed zed || [[ -d "/Applications/Zed.app" ]]; then log_skip "Zed"; return; fi

    case "$DISTRO" in
        macos) run brew install --cask zed ;;
        *)     run bash -c 'curl -f https://zed.dev/install.sh | sh' ;;
    esac
}

# ============================================================
# Browsers
# ============================================================
install_firefox() {
    log_section "Firefox"
    if is_installed firefox || [[ -d "/Applications/Firefox.app" ]]; then log_skip "Firefox"; return; fi

    case "$DISTRO" in
        macos)  run brew install --cask firefox ;;
        ubuntu) pkg_install firefox ;;
        fedora) pkg_install firefox ;;
    esac
}

install_chrome() {
    log_section "Google Chrome"
    if is_installed google-chrome-stable || is_installed google-chrome || [[ -d "/Applications/Google Chrome.app" ]]; then
        log_skip "Google Chrome"
        return
    fi

    case "$DISTRO" in
        macos)
            run brew install --cask google-chrome
            ;;
        ubuntu)
            local tmp
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            log_info "Downloading Google Chrome..."
            run curl -fsSL -o "$tmp/chrome.deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
            run sudo dpkg -i "$tmp/chrome.deb" || run sudo apt-get install -f -y
            ;;
        fedora)
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
    if is_installed brave-browser || [[ -d "/Applications/Brave Browser.app" ]]; then log_skip "Brave"; return; fi

    case "$DISTRO" in
        macos)
            run brew install --cask brave-browser
            ;;
        ubuntu)
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
            if [[ -d "/Applications/Dropbox.app" ]]; then log_skip "Dropbox"; return; fi
            run brew install --cask dropbox
            ;;
        ubuntu)
            if is_installed dropbox || dpkg -l nautilus-dropbox &>/dev/null; then log_skip "Dropbox"; return; fi
            local tmp
            tmp=$(mktemp -d)
            trap "rm -rf '$tmp'" RETURN
            log_info "Installing Dropbox (nautilus-dropbox)..."
            run curl -fsSL -o "$tmp/nautilus-dropbox.deb" \
                "https://linux.dropbox.com/packages/ubuntu/nautilus-dropbox_2026.01.15_all.deb"
            run sudo dpkg -i "$tmp/nautilus-dropbox.deb" || run sudo apt-get install -f -y
            ;;
        fedora)
            if is_installed dropbox || rpm -q nautilus-dropbox &>/dev/null; then log_skip "Dropbox"; return; fi
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
            if [[ -d "/Applications/Obsidian.app" ]]; then log_skip "Obsidian"; return; fi
            run brew install --cask obsidian
            ;;
        *)
            if is_installed obsidian || flatpak list 2>/dev/null | grep -q "md.obsidian.Obsidian"; then
                log_skip "Obsidian"
                return
            fi
            log_info "Installing Obsidian via Flatpak..."
            run flatpak install -y flathub md.obsidian.Obsidian
            ;;
    esac
}

install_typora() {
    log_section "Typora"
    if is_installed typora || [[ -d "/Applications/Typora.app" ]]; then log_skip "Typora"; return; fi

    case "$DISTRO" in
        macos)
            run brew install --cask typora
            ;;
        ubuntu)
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
            if is_installed pdfarranger || flatpak list 2>/dev/null | grep -q "com.github.jeromerobert.pdfarranger"; then
                log_skip "PDF Arranger"
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
main() {
    try_step install_wezterm

    try_step install_vscode
    try_step install_zed

    try_step install_firefox
    try_step install_chrome
    try_step install_brave

    try_step install_dropbox
    try_step install_obsidian
    try_step install_typora
    try_step install_pdf_arranger
}

main "$@"
