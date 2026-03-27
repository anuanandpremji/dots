#!/usr/bin/env bash
#
# Installs zsh (with user confirmation) and sets it as the default shell.
#
# Usage: ./setup_zsh.sh [--dry-run]

set -u

DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

INSTALL_ZSH=false

install_zsh() {
    log_section "Zsh"

    if is_installed zsh; then
        log_skip "zsh (already installed)"
        INSTALL_ZSH=true
        return
    fi

    printf "  Install zsh? [Y/n]: "
    read -r answer
    if [[ "${answer:-Y}" =~ ^[Nn] ]]; then
        log_skip "zsh (declined)"
        return
    fi

    INSTALL_ZSH=true
    pkg_install zsh
}

set_default_shell() {
    if [[ "$INSTALL_ZSH" != true ]]; then return; fi

    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ "$(basename "$SHELL")" == "zsh" ]]; then
        log_skip "zsh (already default shell)"
        return
    fi

    log_info "Setting zsh as default shell..."
    if ! run chsh -s "$zsh_path" 2>/dev/null; then
        log_warn "chsh failed — add 'exec zsh' to your .bashrc to use zsh manually"
    fi
}

try_step install_zsh
try_step set_default_shell
