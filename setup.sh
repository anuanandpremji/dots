#!/usr/bin/env bash
#
# Workstation Setup Script
# Sets up a fresh Ubuntu, Fedora, or macOS installation with preferred apps and configs.
#
# Usage:
#   ./setup.sh              Run full setup interactively
#   ./setup.sh --cli        CLI-only mode (dotfiles, SSH, CLI tools — no GUI apps)
#   ./setup.sh --dry-run    Preview all actions without making changes
#
# Flags can be combined: ./setup.sh --cli --dry-run
#
# Bootstrap (fresh machine, nothing installed):
#   curl -fsSL https://raw.githubusercontent.com/anuanandpremji/dots/main/setup.sh \
#        -o /tmp/setup.sh && bash /tmp/setup.sh
#
# Requires: bash 3.2+, curl
# Must NOT be run as root — uses sudo when needed.
#
# ╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                         >> SYSTEM SETUP FLOW                                                ║
# ╠═════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
# ║                                                                                                             ║
# ║  1. [>] PREFLIGHT                                                                                           ║
# ║     • Detect OS (Ubuntu / Fedora / macOS)                                                                   ║
# ║     • Detect Architecture (x86_64 / ARM64)                                                                  ║
# ║     • macOS only: Install Homebrew                                                                          ║
# ║                                                                                                             ║
# ╟─────────────────────────────────────────────────────────────────────────────────────────────────────────────╢
# ║                                                                                                             ║
# ║  2. [@] IDENTITIES (via `setup-identities`)                                                                 ║
# ║                                                                                                             ║
# ║     ┌──────────────────────────────────────────┐          ┌──────────────────────────────────────────┐      ║
# ║     │          [#] PRIVATE IDENTITY            │          │            [%] WORK IDENTITY             │      ║
# ║     ├──────────────────────────────────────────┤          ├──────────────────────────────────────────┤      ║
# ║     │ SSH: ~/.ssh/id_private                   │          │ SSH: ~/.ssh/id_work                      │      ║
# ║     │ Host: github-private                     │          │ Host: github-work                        │      ║
# ║     │ Git:  ~/.config/git/config.private       │          │ Git:  ~/.config/git/config.work          │      ║
# ║     │ Dir:  ~/private/                         │          │ Dir:  ~/work/                            │      ║
# ║     └────────────────────┬─────────────────────┘          └────────────────────┬─────────────────────┘      ║
# ║                          │                                                     │                            ║
# ║                          └───────────────────────────┬─────────────────────────┘                            ║
# ║                                                      ▼                                                      ║
# ║                                         [ Select Default Identity ]                                         ║
# ║                                    (Copied to ~/.config/git/config.default)                                 ║
# ║                                                                                                             ║
# ╟─────────────────────────────────────────────────────────────────────────────────────────────────────────────╢
# ║                                                                                                             ║
# ║  3. [/] DOTFILES                                                                                            ║
# ║                                                                                                             ║
# ║                         YES                                                                                 ║
# ║     Already present? ─────────▶  Use existing directory                                                     ║
# ║            │                                                                                                ║
# ║            │ NO                                                                                             ║
# ║            ▼                                                                                                ║
# ║     ┌───────────────────────────────────────────────────────────────────────────────────────────────────┐   ║
# ║     │  A) Clone via SSH (if key found)   OR   B) Clone via HTTPS   OR   C) Download ZIP (no git)        │   ║
# ║     └───────────────────────────────────────────────────────────────────────────────────────────────────┘   ║
# ║                                                                                                             ║
# ╟─────────────────────────────────────────────────────────────────────────────────────────────────────────────╢
# ║                                                                                                             ║
# ║  4. [!] INSTALL APPLICATIONS                                                                                ║
# ║                                                                                                             ║
# ║     Category     │ Linux (apt/dnf/flatpak)           │ macOS (brew/cask)                                    ║
# ║     ─────────────┼───────────────────────────────────┼──────────────────────────────────                    ║
# ║     System       │ git, curl, wget, zsh, tree        │ git, curl, wget, zsh, tree                           ║
# ║                  │ meld, xclip, wl-clipboard         │ meld                                                 ║
# ║                  │ flatpak                           │                                                      ║
# ║                  │                                   │                                                      ║
# ║     CLI Tools    │ fzf, fd, bat, ripgrep, eza, delta │ fzf, fd, bat, ripgrep, eza, delta                    ║
# ║                  │                                   │                                                      ║
# ║     Editors      │ Micro, Neovim, VS Code, Zed       │ Micro, Neovim, VS Code, Zed                          ║
# ║                  │                                   │                                                      ║
# ║     Terminal     │ WezTerm                           │ WezTerm                                              ║
# ║                  │                                   │                                                      ║
# ║     Browsers     │ Firefox, Chrome, Brave            │ Firefox, Chrome, Brave                               ║
# ║                  │                                   │                                                      ║
# ║     Desktop      │ Dropbox, Obsidian, Typora         │ Dropbox, Obsidian, Typora                            ║
# ║                  │ PDF Arranger                      │ (PDF Arranger N/A on macOS)                          ║
# ║                                                                                                             ║
# ╟─────────────────────────────────────────────────────────────────────────────────────────────────────────────╢
# ║                                                                                                             ║
# ║  5. [*] GNOME CUSTOMIZATION (Linux Only)                                                                    ║
# ║     • Core: Tweaks, Extension Manager, Calendar                                                             ║
# ║     • Extensions: Quake Terminal, Night Theme Switcher, Tiling Assistant, Grand Theft Focus, ...            ║
# ║                                                                                                             ║
# ╟─────────────────────────────────────────────────────────────────────────────────────────────────────────────╢
# ║                                                                                                             ║
# ║  6. [#] FINALIZE                                                                                            ║
# ║     • Fonts: Install Nerd Fonts (Symlink on Linux | Copy on macOS)                                          ║
# ║     • Shell: Set ZSH as default (`chsh`)                                                                    ║
# ║     • macOS: Generate updated Brewfile                                                                      ║
# ║     • Symlinks: Run `setup-symlinks` (Maps configs & triggers `dconf load` for settings)                    ║
# ║                                                                                                             ║
# ╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ============================================================
# Configuration
# ============================================================
DRY_RUN=false
CLI_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --cli)     CLI_ONLY=true ;;
    esac
done

# DOTFILES is resolved from the script location, or via clone/download.
DOTFILES=""

# ============================================================
# Colors
# ============================================================
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' BOLD='' NC=''
fi

# ============================================================
# Logging
# ============================================================
log_info()    { printf "${GREEN}[INFO]${NC}    %s\n" "$1"; }
log_warn()    { printf "${YELLOW}[WARN]${NC}    %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${NC}   %s\n" "$1" >&2; }
log_section() { printf "\n${BOLD}${BLUE}── %s ──${NC}\n" "$1"; }
log_skip()    { printf "${YELLOW}[SKIP]${NC}    %s (already installed)\n" "$1"; }

run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$*"
    else
        "$@"
    fi
}

# ============================================================
# Preflight
# ============================================================
if [[ "$(id -u)" -eq 0 ]]; then
    log_error "Do not run this script as root. It will use sudo when needed."
    exit 1
fi

for cmd in curl git; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

if [[ "$DRY_RUN" == true ]]; then
    printf "\n${YELLOW}=== DRY RUN — no changes will be made ===${NC}\n\n"
fi

# ============================================================
# OS Detection
# ============================================================
detect_os() {
    OS=""
    DISTRO=""

    case "$(uname -s)" in
        Linux)
            OS="linux"
            if [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                source /etc/os-release
                case "$ID" in
                    ubuntu|pop|debian) DISTRO="ubuntu" ;;
                    fedora)     DISTRO="fedora" ;;
                    *)
                        log_error "Unsupported Linux distribution: $ID"
                        exit 1
                        ;;
                esac
            else
                log_error "Cannot detect Linux distribution (no /etc/os-release)"
                exit 1
            fi
            ;;
        Darwin)
            OS="macos"
            DISTRO="macos"
            ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac

    log_info "Detected: OS=$OS, Distro=$DISTRO"
}

detect_os

# ============================================================
# Architecture Detection (for GitHub release downloads)
# ============================================================
detect_arch() {
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)  DEB_ARCH="amd64"; RPM_ARCH="x86_64" ;;
        aarch64) DEB_ARCH="arm64"; RPM_ARCH="aarch64" ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

detect_arch

# ============================================================
# Dotfiles Source (Git clone or Zip download)
# ============================================================
GITHUB_REPO="anuanandpremji/dots"

clone_from_github() {
    local dest="$HOME/dotfiles"
    printf "  Where should the dotfiles repo be cloned to? [%s]: " "$dest"
    read -r user_dest
    [[ -n "$user_dest" ]] && dest="$user_dest"

    if [[ -d "$dest" && -f "$dest/.config/shell/scripts/setup-symlinks" ]]; then
        log_info "Dotfiles already exist at $dest"
    else
        # Prefer SSH via private key if configured, fall back to HTTPS
        if grep -q "^Host github-private$" "$HOME/.ssh/config" 2>/dev/null; then
            log_info "Cloning via SSH (github-private)..."
            run git clone "git@github-private:$GITHUB_REPO.git" "$dest"
        else
            log_info "Cloning via HTTPS..."
            run git clone "https://github.com/$GITHUB_REPO.git" "$dest"
        fi
    fi
    DOTFILES="$dest"
}

download_zip() {
    local dest="$HOME/dotfiles"
    printf "  Where should the dotfiles be extracted to? [%s]: " "$dest"
    read -r user_dest
    [[ -n "$user_dest" ]] && dest="$user_dest"

    if [[ -d "$dest" && -f "$dest/.config/shell/scripts/setup-symlinks" ]]; then
        log_info "Dotfiles already exist at $dest"
    else
        log_info "Downloading dotfiles zip from GitHub..."
        local tmp_zip
        tmp_zip=$(mktemp -d)
        run curl -fsSL -o "$tmp_zip/dotfiles.zip" \
            "https://github.com/$GITHUB_REPO/archive/refs/heads/main.zip"
        run unzip -q "$tmp_zip/dotfiles.zip" -d "$tmp_zip"
        run mkdir -p "$dest"
        # The zip extracts to a subdirectory named <repo>-main
        run cp -a "$tmp_zip"/dots-main/. "$dest"/
        rm -rf "$tmp_zip"
        log_info "Extracted to $dest"
    fi
    DOTFILES="$dest"
}

acquire_dotfiles() {
    log_section "Dotfiles source"

    # If running from within the dotfiles directory, use that directly
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$script_dir/.config/shell/scripts/setup-symlinks" ]]; then
        DOTFILES="$script_dir"
        log_info "Running from dotfiles directory: $DOTFILES"
        return
    fi

    # Check common locations
    local CANDIDATES=("$HOME/dotfiles" "$HOME/private/dotfiles" "$HOME/private/dots")
    for candidate in "${CANDIDATES[@]}"; do
        if [[ -f "$candidate/.config/shell/scripts/setup-symlinks" ]]; then
            DOTFILES="$candidate"
            log_info "Found existing dotfiles at $DOTFILES"
            return
        fi
    done

    # Not found — ask how to get them
    printf "\n"
    printf "  How would you like to get the dotfiles?\n\n"
    printf "    1) Clone from GitHub (uses SSH if configured, otherwise HTTPS)\n"
    printf "    2) Download as zip from GitHub (no git needed)\n"
    printf "\n"
    printf "  Choice [1/2]: "
    read -r choice

    case "$choice" in
        1)  clone_from_github ;;
        2)  download_zip ;;
        *)
            log_error "Invalid choice: $choice"
            exit 1
            ;;
    esac
}

# ============================================================
# Git & SSH Identity Setup
# ============================================================
setup_git_identities() {
    log_section "Git & SSH identities"

    # If keys already exist, offer to skip
    if [[ -f "$HOME/.ssh/id_private" || -f "$HOME/.ssh/id_work" ]]; then
        printf "  SSH keys already exist:\n"
        [[ -f "$HOME/.ssh/id_private" ]] && printf "    Personal: ~/.ssh/id_private\n"
        [[ -f "$HOME/.ssh/id_work" ]]     && printf "    Work:     ~/.ssh/id_work\n"
        printf "\n"
        printf "  Re-run git identity setup? [y/N]: "
        read -r rerun
        if [[ ! "${rerun:-N}" =~ ^[Yy] ]]; then
            log_skip "Git identity setup"
            return
        fi
    fi

    # Find or fetch the setup-identities script
    local setup_git_script=""

    # Check if running from within dotfiles
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$script_dir/.config/shell/scripts/setup-identities" ]]; then
        setup_git_script="$script_dir/.config/shell/scripts/setup-identities"
    fi

    # Check known dotfiles locations
    if [[ -z "$setup_git_script" ]]; then
        local CANDIDATES=(
            "$HOME/dotfiles"
            "$HOME/private/dotfiles"
            "$HOME/private/dots"
        )
        for candidate in "${CANDIDATES[@]}"; do
            if [[ -f "$candidate/.config/shell/scripts/setup-identities" ]]; then
                setup_git_script="$candidate/.config/shell/scripts/setup-identities"
                break
            fi
        done
    fi

    # Fetch from GitHub as last resort
    if [[ -z "$setup_git_script" ]]; then
        log_info "Downloading setup-identities from GitHub..."
        setup_git_script="/tmp/setup-identities"
        curl -fsSL -o "$setup_git_script" \
            "https://raw.githubusercontent.com/$GITHUB_REPO/main/.config/shell/scripts/setup-identities"
        chmod +x "$setup_git_script"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        run bash "$setup_git_script" --dry-run
    else
        bash "$setup_git_script"
    fi
}

# ============================================================
# Package Manager Helpers
# ============================================================
pkg_install() {
    case "$DISTRO" in
        ubuntu) run sudo apt-get install -y "$@" ;;
        fedora) run sudo dnf install -y "$@" ;;
        macos)  run brew install "$@" ;;
    esac
}

pkg_update() {
    log_section "Updating package manager"
    case "$DISTRO" in
        ubuntu) run sudo apt-get update ;;
        fedora) run sudo dnf check-update || true ;;
        macos)  run brew update ;;
    esac
}

is_installed() {
    command -v "$1" &>/dev/null
}

# Fetch the latest release download URL from a GitHub repo
# Usage: gh_latest_url <owner/repo> <filename-pattern>
gh_latest_url() {
    local repo="$1"
    local pattern="$2"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep "browser_download_url" \
        | grep -E "$pattern" \
        | head -1 \
        | sed 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/'
}

# Install a .deb or .rpm from a GitHub release
# Usage: gh_install_pkg <owner/repo> <deb-pattern> <rpm-pattern> <display-name>
gh_install_pkg() {
    local repo="$1"
    local deb_pattern="$2"
    local rpm_pattern="$3"
    local name="$4"
    local tmp

    tmp=$(mktemp -d)
    trap "rm -rf '$tmp'" RETURN

    case "$DISTRO" in
        ubuntu)
            local url
            url=$(gh_latest_url "$repo" "$deb_pattern")
            log_info "Downloading $name from $url"
            run curl -fsSL -o "$tmp/pkg.deb" "$url"
            run sudo dpkg -i "$tmp/pkg.deb" || run sudo apt-get install -f -y
            ;;
        fedora)
            local url
            url=$(gh_latest_url "$repo" "$rpm_pattern")
            log_info "Downloading $name from $url"
            run curl -fsSL -o "$tmp/pkg.rpm" "$url"
            run sudo dnf install -y "$tmp/pkg.rpm"
            ;;
    esac
}

# ============================================================
# Homebrew (macOS)
# ============================================================
install_homebrew() {
    if [[ "$DISTRO" != "macos" ]]; then return; fi

    log_section "Homebrew"
    if is_installed brew; then
        log_skip "Homebrew"
    else
        log_info "Installing Homebrew..."
        run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# ============================================================
# System Packages
# ============================================================
install_system_packages() {
    log_section "System packages"

    if [[ "$CLI_ONLY" == true ]]; then
        case "$DISTRO" in
            ubuntu)
                pkg_install git curl wget zsh build-essential software-properties-common tree unzip
                ;;
            fedora)
                pkg_install git curl wget zsh @development-tools tree unzip
                ;;
            macos)
                pkg_install git curl wget zsh tree
                ;;
        esac
        return
    fi

    case "$DISTRO" in
        ubuntu)
            pkg_install \
                git curl wget zsh \
                build-essential software-properties-common \
                xclip wl-clipboard \
                meld tree unzip \
                flatpak gnome-software-plugin-flatpak \
                gnome-calendar gnome-tweaks
            # Extension Manager is a Flatpak on Ubuntu
            ;;
        fedora)
            pkg_install \
                git curl wget zsh \
                @development-tools \
                xclip wl-clipboard \
                meld tree unzip \
                flatpak \
                gnome-calendar gnome-tweaks
            ;;
        macos)
            pkg_install \
                git curl wget zsh \
                meld tree
            ;;
    esac
}

# ============================================================
# CLI Tools (latest versions)
# ============================================================
install_fzf() {
    log_section "fzf"
    if is_installed fzf; then
        log_skip "fzf"
        return
    fi

    case "$DISTRO" in
        macos)
            pkg_install fzf
            ;;
        *)
            log_info "Installing fzf from GitHub release..."
            local tmp url
            tmp=$(mktemp -d)
            url=$(gh_latest_url "junegunn/fzf" "linux_${DEB_ARCH}\\.tar\\.gz")
            run curl -fsSL -o "$tmp/fzf.tar.gz" "$url"
            run tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
            run mkdir -p "$HOME/.local/bin"
            run mv "$tmp/fzf" "$HOME/.local/bin/fzf"
            run chmod +x "$HOME/.local/bin/fzf"
            rm -rf "$tmp"
            ;;
    esac
}

install_fd() {
    log_section "fd"
    if is_installed fd; then
        log_skip "fd"
        return
    fi

    # On Ubuntu, the .deb installs as 'fdfind' due to a name conflict.
    # We always create a symlink so 'fd' works everywhere.
    if is_installed fdfind && ! is_installed fd; then
        log_info "fdfind found — creating fd symlink"
        run mkdir -p "$HOME/.local/bin"
        run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        return
    fi

    case "$DISTRO" in
        macos)  pkg_install fd ;;
        ubuntu)
            gh_install_pkg "sharkdp/fd" "${DEB_ARCH}\\.deb" "" "fd"
            # The .deb installs as fdfind — symlink to fd
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
    if is_installed bat; then
        log_skip "bat"
        return
    fi

    # On Ubuntu, the .deb installs as 'batcat' due to a name conflict.
    if is_installed batcat && ! is_installed bat; then
        log_info "batcat found — creating bat symlink"
        run mkdir -p "$HOME/.local/bin"
        run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        return
    fi

    case "$DISTRO" in
        macos)  pkg_install bat ;;
        ubuntu)
            gh_install_pkg "sharkdp/bat" "${DEB_ARCH}\\.deb" "" "bat"
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
    if is_installed rg; then
        log_skip "ripgrep"
        return
    fi

    case "$DISTRO" in
        macos)  pkg_install ripgrep ;;
        ubuntu) gh_install_pkg "BurntSushi/ripgrep" "${DEB_ARCH}\\.deb" "" "ripgrep" ;;
        fedora) gh_install_pkg "BurntSushi/ripgrep" "" "${RPM_ARCH}\\.rpm" "ripgrep" ;;
    esac
}

install_eza() {
    log_section "eza"
    if is_installed eza; then
        log_skip "eza"
        return
    fi

    case "$DISTRO" in
        macos)
            pkg_install eza
            ;;
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
        fedora)
            pkg_install eza
            ;;
    esac
}

install_delta() {
    log_section "delta"
    if is_installed delta; then
        log_skip "delta"
        return
    fi

    case "$DISTRO" in
        macos)  pkg_install git-delta ;;
        ubuntu) gh_install_pkg "dandavison/delta" "${DEB_ARCH}\\.deb" "" "delta" ;;
        fedora) gh_install_pkg "dandavison/delta" "" "${RPM_ARCH}\\.rpm" "delta" ;;
    esac
}

install_micro() {
    log_section "micro"
    if is_installed micro; then
        log_skip "micro"
        return
    fi

    case "$DISTRO" in
        macos)
            pkg_install micro
            ;;
        *)
            log_info "Installing micro from official installer..."
            local micro_tmp
            micro_tmp=$(mktemp -d)
            run bash -c "cd '$micro_tmp' && curl https://getmic.ro | bash"
            run mkdir -p "$HOME/.local/bin"
            run mv "$micro_tmp/micro" "$HOME/.local/bin/micro"
            run chmod +x "$HOME/.local/bin/micro"
            rm -rf "$micro_tmp"
            ;;
    esac
}

install_neovim() {
    log_section "Neovim"
    if is_installed nvim; then
        log_skip "Neovim"
        return
    fi

    case "$DISTRO" in
        macos)
            pkg_install neovim
            ;;
        *)
            log_info "Installing Neovim AppImage..."
            local url
            url=$(gh_latest_url "neovim/neovim" "nvim-linux-${ARCH}\\.appimage$")
            run mkdir -p "$HOME/.local/bin"
            run curl -fsSL -o "$HOME/.local/bin/nvim" "$url"
            run chmod +x "$HOME/.local/bin/nvim"
            ;;
    esac
}

# ============================================================
# Terminal Emulators
# ============================================================
install_wezterm() {
    log_section "WezTerm"
    if is_installed wezterm; then
        log_skip "WezTerm"
        return
    fi

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
    if is_installed code; then
        log_skip "VS Code"
        return
    fi

    case "$DISTRO" in
        macos)
            run brew install --cask visual-studio-code
            ;;
        ubuntu)
            if [[ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]]; then
                log_info "Adding Microsoft VS Code repository..."
                run bash -c 'wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --yes --dearmor -o /tmp/packages.microsoft.gpg'
                run sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
                run bash -c 'echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list'
                run sudo apt-get update
                rm -f /tmp/packages.microsoft.gpg
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
    if is_installed zed; then
        log_skip "Zed"
        return
    fi

    case "$DISTRO" in
        macos)
            run brew install --cask zed
            ;;
        *)
            log_info "Installing Zed via official installer..."
            run bash -c 'curl -f https://zed.dev/install.sh | sh'
            ;;
    esac
}

# ============================================================
# Browsers
# ============================================================
install_firefox() {
    log_section "Firefox"
    if is_installed firefox; then
        log_skip "Firefox"
        return
    fi

    case "$DISTRO" in
        macos)  run brew install --cask firefox ;;
        ubuntu) pkg_install firefox ;;
        fedora) pkg_install firefox ;;
    esac
}

install_chrome() {
    log_section "Google Chrome"
    if is_installed google-chrome-stable || is_installed google-chrome; then
        log_skip "Google Chrome"
        return
    fi

    case "$DISTRO" in
        macos)
            run brew install --cask google-chrome
            ;;
        ubuntu)
            log_info "Downloading Google Chrome..."
            local tmp_chrome
            tmp_chrome=$(mktemp -d)
            run curl -fsSL -o "$tmp_chrome/chrome.deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
            run sudo dpkg -i "$tmp_chrome/chrome.deb" || run sudo apt-get install -f -y
            rm -rf "$tmp_chrome"
            ;;
        fedora)
            log_info "Downloading Google Chrome..."
            local tmp_chrome
            tmp_chrome=$(mktemp -d)
            run curl -fsSL -o "$tmp_chrome/chrome.rpm" "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
            run sudo dnf install -y "$tmp_chrome/chrome.rpm"
            rm -rf "$tmp_chrome"
            ;;
    esac
}

install_brave() {
    log_section "Brave"
    if is_installed brave-browser; then
        log_skip "Brave"
        return
    fi

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
            if [[ -d "/Applications/Dropbox.app" ]]; then
                log_skip "Dropbox"
                return
            fi
            run brew install --cask dropbox
            ;;
        ubuntu)
            if is_installed dropbox || dpkg -l nautilus-dropbox &>/dev/null; then
                log_skip "Dropbox"
                return
            fi
            log_info "Installing Dropbox (nautilus-dropbox)..."
            local tmp_db
            tmp_db=$(mktemp -d)
            run curl -fsSL -o "$tmp_db/nautilus-dropbox.deb" \
                "https://linux.dropbox.com/packages/ubuntu/nautilus-dropbox_2026.01.15_all.deb"
            run sudo dpkg -i "$tmp_db/nautilus-dropbox.deb" || run sudo apt-get install -f -y
            rm -rf "$tmp_db"
            ;;
        fedora)
            if is_installed dropbox || rpm -q nautilus-dropbox &>/dev/null; then
                log_skip "Dropbox"
                return
            fi
            log_info "Installing Dropbox (nautilus-dropbox)..."
            local tmp_db
            tmp_db=$(mktemp -d)
            run curl -fsSL -o "$tmp_db/nautilus-dropbox.rpm" \
                "https://linux.dropbox.com/packages/fedora/nautilus-dropbox-2026.01.15-1.fc43.x86_64.rpm"
            run sudo dnf install -y "$tmp_db/nautilus-dropbox.rpm"
            rm -rf "$tmp_db"
            ;;
    esac
}

install_obsidian() {
    log_section "Obsidian"

    case "$DISTRO" in
        macos)
            if [[ -d "/Applications/Obsidian.app" ]]; then
                log_skip "Obsidian"
                return
            fi
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

install_pdf_arranger() {
    log_section "PDF Arranger"

    case "$DISTRO" in
        macos)
            log_warn "PDF Arranger is not available on macOS. Consider using 'PDF Toolkit' or 'Coherent PDF' instead."
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

install_typora() {
    log_section "Typora"
    if is_installed typora; then
        log_skip "Typora"
        return
    fi

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

# ============================================================
# GNOME Extensions (Linux only)
# ============================================================
install_gnome_extensions() {
    if [[ "$OS" != "linux" ]]; then return; fi

    log_section "GNOME Extensions"

    # Install gext CLI if needed
    if ! is_installed gext; then
        log_info "Installing gnome-extensions-cli..."
        if is_installed pipx; then
            run pipx install gnome-extensions-cli
        elif is_installed pip; then
            run pip install --user gnome-extensions-cli
        elif is_installed pip3; then
            run pip3 install --user gnome-extensions-cli
        else
            log_warn "Neither pipx nor pip found — cannot install gext. Skipping GNOME extensions."
            return
        fi
    fi

    # Common extensions (both Ubuntu and Fedora)
    local COMMON_EXTENSIONS=(
        "quake-terminal@diegodario88.github.io"
        "nightthemeswitcher@romainvigier.fr"
        "grand-theft-focus@zalckos.github.com"
        "unblank@sun.wxg@gmail.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
    )

    # Distro-specific extensions
    local DISTRO_EXTENSIONS=()
    case "$DISTRO" in
        ubuntu)
            DISTRO_EXTENSIONS=(
                "ding@rastersoft.com"
                "tiling-assistant@ubuntu.com"
                "ubuntu-appindicators@ubuntu.com"
                "ubuntu-dock@ubuntu.com"
            )
            ;;
        fedora)
            DISTRO_EXTENSIONS=(
                "appindicatorsupport@rgcjonas.gmail.com"
            )
            ;;
    esac

    local ALL_EXTENSIONS=("${COMMON_EXTENSIONS[@]}" "${DISTRO_EXTENSIONS[@]}")

    for ext in "${ALL_EXTENSIONS[@]}"; do
        if gnome-extensions list 2>/dev/null | grep -q "$ext"; then
            log_skip "$ext"
        else
            log_info "Installing extension: $ext"
            run gext install "$ext"
        fi
    done
}

# ============================================================
# Flatpak Setup
# ============================================================
setup_flatpak() {
    if [[ "$OS" != "linux" ]]; then return; fi

    log_section "Flatpak"
    if is_installed flatpak; then
        if ! flatpak remotes | grep -q flathub; then
            log_info "Adding Flathub repository..."
            run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        else
            log_skip "Flathub"
        fi
    fi
}

# ============================================================
# Extension Manager (Flatpak, Linux only)
# ============================================================
install_extension_manager() {
    if [[ "$OS" != "linux" ]]; then return; fi

    log_section "Extension Manager"
    if flatpak list 2>/dev/null | grep -q "com.mattjakeman.ExtensionManager"; then
        log_skip "Extension Manager"
        return
    fi

    log_info "Installing Extension Manager via Flatpak..."
    run flatpak install -y flathub com.mattjakeman.ExtensionManager
}

# ============================================================
# Fonts
# ============================================================
install_fonts() {
    log_section "Fonts"

    case "$DISTRO" in
        macos)
            if [[ -d "$DOTFILES/.local/share/fonts" ]]; then
                log_info "Syncing fonts to ~/Library/Fonts/ (skipping existing)..."
                run mkdir -p "$HOME/Library/Fonts"
                run find "$DOTFILES/.local/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec sh -c '
                    for f; do
                        dest="$HOME/Library/Fonts/$(basename "$f")"
                        [ -f "$dest" ] || cp "$f" "$dest"
                    done
                ' _ {} +
            fi
            ;;
        *)
            if [[ -d "$DOTFILES/.local/share/fonts" ]]; then
                log_info "Syncing fonts to ~/.local/share/fonts/ (skipping existing)..."
                run mkdir -p "$HOME/.local/share/fonts"
                run find "$DOTFILES/.local/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec sh -c '
                    for f; do
                        dest="$HOME/.local/share/fonts/$(basename "$f")"
                        [ -f "$dest" ] || cp "$f" "$dest"
                    done
                ' _ {} +
            fi
            ;;
    esac
}

# ============================================================
# Zsh as Default Shell
# ============================================================
set_default_shell() {
    log_section "Default shell"

    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ "$(basename "$SHELL")" == "zsh" ]]; then
        log_skip "zsh (already default)"
        return
    fi

    if [[ -n "$zsh_path" ]]; then
        log_info "Setting zsh as default shell..."
        run chsh -s "$zsh_path"
    else
        log_warn "zsh not found, skipping default shell change"
    fi
}

# ============================================================
# Symlinks & Settings
# ============================================================
apply_dotfiles() {
    log_section "Dotfiles (symlinks & settings)"

    local symlink_script="$DOTFILES/.config/shell/scripts/setup-symlinks"
    if [[ -f "$symlink_script" ]]; then
        log_info "Running setup-symlinks..."
        if [[ "$DRY_RUN" == true ]]; then
            run bash "$symlink_script" --dry-run
        else
            run bash "$symlink_script"
        fi
    else
        log_error "setup-symlinks not found at $symlink_script"
    fi
}

# ============================================================
# macOS Brewfile
# ============================================================
generate_brewfile() {
    if [[ "$DISTRO" != "macos" ]]; then return; fi

    log_section "Generating Brewfile"
    local brewfile="$DOTFILES/Brewfile"

    cat > "$brewfile" <<'EOF'
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
brew "micro"
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
    log_info "You can also install everything at once with: brew bundle --file=$brewfile"
}

# ============================================================
# Main
# ============================================================
main() {
    printf "\n"
    printf "${BOLD}========================================${NC}\n"
    printf "${BOLD} Workstation Setup${NC}\n"
    printf "${BOLD}========================================${NC}\n"
    printf " OS:       %s (%s)\n" "$OS" "$DISTRO"
    printf " Arch:     %s\n" "$ARCH"
    if [[ "$CLI_ONLY" == true ]]; then
        printf " Mode:     CLI only\n"
    fi
    printf "${BOLD}========================================${NC}\n\n"

    # ── macOS: Homebrew first (needed for everything) ──
    install_homebrew

    # ── Git & SSH identities (needed before cloning) ──
    setup_git_identities

    # ── Dotfiles source (git clone or zip) ──
    acquire_dotfiles

    log_info "Dotfiles: $DOTFILES"
    printf "\n"

    # ── Package manager update ──
    pkg_update

    # ── System packages ──
    install_system_packages

    # ── CLI tools (latest versions) ──
    install_fzf
    install_fd
    install_bat
    install_ripgrep
    install_eza
    install_delta
    install_micro
    install_neovim

    if [[ "$CLI_ONLY" != true ]]; then
        # ── Flatpak (Linux) ──
        setup_flatpak

        # ── Terminal emulators ──
        install_wezterm

        # ── Editors ──
        install_vscode
        install_zed

        # ── Browsers ──
        install_firefox
        install_chrome
        install_brave

        # ── Desktop apps ──
        install_dropbox
        install_obsidian
        install_typora
        install_pdf_arranger

        # ── GNOME tools & extensions (Linux) ──
        install_extension_manager
        install_gnome_extensions
    fi

    # ── Fonts ──
    install_fonts

    # ── Default shell ──
    set_default_shell

    # ── Brewfile (macOS) ──
    if [[ "$CLI_ONLY" != true ]]; then
        generate_brewfile
    fi

    # ── Symlinks & settings (always last) ──
    apply_dotfiles

    # ── Done ──
    printf "\n"
    log_info "========================================"
    log_info "  Setup completed successfully!"
    log_info "========================================"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Log out and back in for shell and GNOME changes to take effect"
    log_info "  2. Set your terminal font to 'JetBrainsMono NL Nerd Font'"
    if [[ "$OS" == "linux" ]]; then
        log_info "  3. Press Alt+F2, type 'r', Enter to reload GNOME Shell (X11)"
        log_info "     or log out/in to activate GNOME extensions (Wayland)"
    fi
    printf "\n"
}

main "$@"
