#!/usr/bin/env bash
#
# Common helpers sourced by all setup scripts.
#
# Must be sourced, not executed. Expects DRY_RUN to be set before sourcing
# (defaults to false if unset).
#
# After sourcing, the following are available:
#   Variables: OS, DISTRO, ARCH, DEB_ARCH, RPM_ARCH
#   Colors:    GREEN, YELLOW, RED, BLUE, BOLD, NC
#   Logging:   log_info, log_warn, log_error, log_section, log_skip
#   Control:   run(), try_step()
#   Helpers:   is_installed(), pkg_install(), pkg_update()
#   GitHub:    gh_latest_url(), gh_install_pkg()

: "${DRY_RUN:=false}"

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
log_skip()    { printf "${YELLOW}[SKIP]${NC}    %s\n" "$1"; }

# ============================================================
# Execution
# ============================================================
run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$*"
    else
        "$@"
    fi
}

# Run a named setup step function. On failure, ask the user whether to continue.
try_step() {
    local step="$1"
    if "$step"; then
        return 0
    fi
    printf "\n"
    log_error "$step failed."
    printf "  Continue with remaining steps? [Y/n]: "
    read -r answer
    if [[ "${answer:-Y}" =~ ^[Nn] ]]; then
        log_error "Aborted by user."
        exit 1
    fi
}

# ============================================================
# Package Manager Helpers
# ============================================================
is_installed() {
    command -v "$1" &>/dev/null || [[ -x "$HOME/.local/bin/$1" ]]
}

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

# ============================================================
# GitHub Release Helpers
# ============================================================

# Print the download URL for the latest release asset matching a pattern.
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

# Download and install a .deb or .rpm from a GitHub release.
# Usage: gh_install_pkg <owner/repo> <deb-pattern> <rpm-pattern> <display-name>
gh_install_pkg() {
    local repo="$1"
    local deb_pattern="$2"
    local rpm_pattern="$3"
    local name="$4"
    local tmp url

    tmp=$(mktemp -d)
    trap "rm -rf '$tmp'" RETURN

    case "$DISTRO" in
        ubuntu)
            url=$(gh_latest_url "$repo" "$deb_pattern")
            if [[ -z "$url" ]]; then
                log_error "Could not find $name download URL (GitHub API rate limit?)"
                return 1
            fi
            log_info "Downloading $name from $url"
            run curl -fsSL -o "$tmp/pkg.deb" "$url"
            run sudo dpkg -i "$tmp/pkg.deb" || run sudo apt-get install -f -y
            ;;
        fedora)
            url=$(gh_latest_url "$repo" "$rpm_pattern")
            if [[ -z "$url" ]]; then
                log_error "Could not find $name download URL (GitHub API rate limit?)"
                return 1
            fi
            log_info "Downloading $name from $url"
            run curl -fsSL -o "$tmp/pkg.rpm" "$url"
            run sudo dnf install -y "$tmp/pkg.rpm"
            ;;
    esac
}

# ============================================================
# OS & Architecture Detection (auto-runs on source)
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
                    fedora)            DISTRO="fedora" ;;
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
}

detect_arch() {
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)        DEB_ARCH="amd64"; RPM_ARCH="x86_64" ;;
        aarch64|arm64) DEB_ARCH="arm64"; RPM_ARCH="aarch64" ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

detect_os
detect_arch

export PATH="$HOME/.local/bin:$PATH"
