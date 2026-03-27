#!/usr/bin/env bash
#
# Workstation Setup — Orchestrator
# Coordinates all setup sub-scripts.
#
# ┌─ Full setup (./setup.sh) ────────────────────────────────────────────────────────────────────────┐
# │                                                                                                   │
# │  1. setup_system.sh        Base packages, package manager bootstrap                              │
# │  2. setup_identities.sh    SSH keys, git identities                                              │
# │  3. [acquire dotfiles]     Clone / download from GitHub if not already present                   │
# │  4. setup_apps_cli.sh      fzf, fd, bat, ripgrep, eza, delta, fresh, nvim                       │
# │  5. setup_apps_gui.sh      WezTerm, Zed, VS Code, browsers, desktop apps                        │
# │     ├─ Linux ──► setup_gnome.sh    GNOME extensions & dconf settings                            │
# │     └─ macOS ──► setup_macos.sh    Homebrew casks                                               │
# │  6. setup_fonts.sh         Nerd Fonts                                                            │
# │  7. setup_zsh.sh           Install zsh, set as default shell                                     │
# │  8. setup_symlinks.sh      Symlink configs to ~/.config/                                         │
# │                                                                                                   │
# └───────────────────────────────────────────────────────────────────────────────────────────────────┘
#
# ┌─ Server preset (./setup.sh server) ─────────────────────────────────────────────────────────────┐
# │  setup_system.sh → setup_identities.sh → setup_apps_cli.sh → setup_zsh.sh → setup_symlinks.sh  │
# │  (no dotfiles acquisition, no GUI apps, no fonts, no GNOME)                                     │
# └─────────────────────────────────────────────────────────────────────────────────────────────────┘
#
# Usage: ./setup.sh [command] [--dry-run] [--help]
#
# Commands:
#   (none)        Full interactive setup (see diagram above)
#   server        Server preset (see diagram above)
#   system        Base packages and package manager
#   identities    SSH keys and git identities
#   cli-apps      CLI tools: fzf, fd, bat, ripgrep, eza, delta, fresh, nvim
#   gui-apps      GUI apps: terminal, editors, browsers, desktop apps
#   gnome         GNOME tools, extensions, and settings [backup|restore]
#   fonts         Install fonts
#   zsh           Install zsh and set as default shell
#   macos         macOS-specific setup (Brewfile)
#   symlinks      Create dotfile symlinks
#   update-cli    Update CLI tools to latest versions
#
# Requires: bash 3.2+, curl — must NOT be run as root.

set -u

print_help() {
    cat <<'EOF'
Usage:
  ./setup.sh [command] [--dry-run]

Commands:
  (none)        Full interactive setup
  server        Preset: system + identities + cli-apps + zsh + symlinks (no GUI)
  system        Base packages and package manager
  identities    SSH keys and git identities
  cli-apps      CLI tools: fzf, fd, bat, ripgrep, eza, delta, fresh, nvim
  gui-apps      GUI apps: terminal, editors, browsers, desktop apps
  gnome         GNOME tools, extensions, and settings restore
  gnome backup  Dump live GNOME/dconf settings to repo
  gnome restore Apply saved GNOME/dconf settings from repo
  fonts         Install fonts
  zsh           Install zsh and set as default shell
  macos         macOS-specific setup (Brewfile)
  symlinks      Create dotfile symlinks
  update-cli    Update CLI tools to latest versions

Flags:
  --dry-run     Preview all actions without making changes
  --help, -h    Show this help

Bootstrap (fresh machine — download repo as zip first, then run):
  unzip dots-main.zip && cd dots-main && bash setup.sh
EOF
}

COMMAND=""
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in --help|-h) print_help; exit 0 ;; esac
done

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        server|system|identities|cli-apps|gui-apps|gnome|fonts|zsh|macos|symlinks|update-cli) COMMAND="$arg" ;;
        backup|restore) GNOME_SUB="$arg" ;;  # sub-command for gnome
    esac
done

GNOME_SUB="${GNOME_SUB:-}"

SCRIPTS_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================
# Preflight
# ============================================================
if [[ "$(id -u)" -eq 0 ]]; then
    log_error "Do not run this script as root. It will use sudo when needed."
    exit 1
fi

if ! command -v curl &>/dev/null; then
    log_error "Required command not found: curl"
    exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    printf "\n${YELLOW}=== DRY RUN — no changes will be made ===${NC}\n\n"
fi

# ============================================================
# Dotfiles acquisition (full setup only)
# ============================================================
GITHUB_REPO="anuanandpremji/dots"

clone_from_github() {
    local parent="$HOME/private"
    printf "  Clone dotfiles repo into which directory? [%s]: " "$parent"
    read -r user_parent
    [[ -n "$user_parent" ]] && parent="$user_parent"

    local dest="$parent/dots"

    if [[ -d "$dest" && -f "$dest/scripts/setup_symlinks.sh" ]]; then
        log_info "Dotfiles already exist at $dest"
    else
        run mkdir -p "$parent"
        local clone_ok=false
        if grep -q "^Host github-private$" "$HOME/.ssh/config" 2>/dev/null; then
            log_info "Cloning via SSH (github-private) into $parent/ ..."
            if run git clone "git@github-private:$GITHUB_REPO.git" "$dest"; then
                clone_ok=true
            else
                log_warn "SSH clone failed — falling back to HTTPS"
                run rm -rf "$dest"
            fi
        fi
        if [[ "$clone_ok" == false ]]; then
            log_info "Cloning via HTTPS into $parent/ ..."
            run git clone "https://github.com/$GITHUB_REPO.git" "$dest" || return 1
        fi
    fi
    DOTFILES="$dest"
}

download_zip() {
    local parent="$HOME/private"
    printf "  Extract dotfiles repo into which directory? [%s]: " "$parent"
    read -r user_parent
    [[ -n "$user_parent" ]] && parent="$user_parent"

    local dest="$parent/dots"

    if [[ -d "$dest" && -f "$dest/scripts/setup_symlinks.sh" ]]; then
        log_info "Dotfiles already exist at $dest"
    else
        log_info "Downloading dotfiles zip from GitHub..."
        local tmp
        tmp=$(mktemp -d)
        trap "rm -rf '$tmp'" RETURN
        run curl -fsSL -o "$tmp/dotfiles.zip" "https://github.com/$GITHUB_REPO/archive/refs/heads/main.zip"
        run unzip -q "$tmp/dotfiles.zip" -d "$tmp"
        run mkdir -p "$dest"
        run cp -a "$tmp"/dots-main/. "$dest"/
        log_info "Extracted to $dest"
    fi
    DOTFILES="$dest"
}

acquire_dotfiles() {
    log_section "Dotfiles source"

    # Running from within the dotfiles directory already
    if [[ -f "$SCRIPTS_DIR/setup_symlinks.sh" ]]; then
        DOTFILES="$(cd "$SCRIPTS_DIR/.." && pwd)"
        log_info "Running from dotfiles directory: $DOTFILES"
        return
    fi

    # Check common locations
    local candidates=("$HOME/dotfiles" "$HOME/private/dotfiles" "$HOME/private/dots")
    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate/scripts/setup_symlinks.sh" ]]; then
            DOTFILES="$candidate"
            log_info "Found existing dotfiles at $DOTFILES"
            return
        fi
    done

    # Not found — ask how to get them
    if ! command -v git &>/dev/null; then
        log_info "git not found — downloading dotfiles as zip"
        download_zip
        return
    fi

    printf "\n"
    printf "  How would you like to get the dotfiles?\n\n"
    printf "    1) Clone from GitHub (SSH if configured, otherwise HTTPS)\n"
    printf "    2) Download as zip from GitHub (no git needed)\n"
    printf "\n"
    printf "  Choice [1/2]: "
    read -r choice

    case "$choice" in
        1) clone_from_github ;;
        2) download_zip ;;
        *)
            log_error "Invalid choice: $choice"
            exit 1
            ;;
    esac
}

# ============================================================
# Sub-script runner
# ============================================================
run_script() {
    local script="$SCRIPTS_DIR/$1"
    shift
    local dry_arg=""
    [[ "$DRY_RUN" == true ]] && dry_arg="--dry-run"
    DOTFILES="${DOTFILES:-}" bash "$script" $dry_arg "$@"
}

# ============================================================
# Presets & Commands
# ============================================================
run_server_preset() {
    log_section "Server preset"
    log_info "Installing: system packages, identities, CLI tools, zsh, symlinks"

    run_script setup_system.sh --server
    run_script setup_identities.sh
    run_script setup_apps_cli.sh
    run_script setup_zsh.sh
    run_script setup_symlinks.sh
}

run_full_setup() {
    printf "\n"
    printf "${BOLD}========================================${NC}\n"
    printf "${BOLD} Workstation Setup${NC}\n"
    printf "${BOLD}========================================${NC}\n"
    printf " OS:   %s (%s)\n" "$OS" "$DISTRO"
    printf " Arch: %s\n" "$ARCH"
    printf "${BOLD}========================================${NC}\n\n"

    run_script setup_system.sh
    run_script setup_identities.sh

    acquire_dotfiles
    export DOTFILES
    log_info "Dotfiles: $DOTFILES"

    run_script setup_apps_cli.sh

    if [[ "$OS" != "linux" ]] || [[ "$DISTRO" == "macos" ]]; then
        run_script setup_apps_gui.sh
        run_script setup_macos.sh
    else
        run_script setup_apps_gui.sh
        run_script setup_gnome.sh
    fi

    run_script setup_fonts.sh
    run_script setup_zsh.sh
    run_script setup_symlinks.sh

    printf "\n"
    log_info "========================================"
    log_info "  Setup completed successfully!"
    log_info "========================================"
    log_info ""
    if [[ "$OS" == "linux" ]]; then
        log_info "Next steps:"
        log_info "  1. Log out and back in for shell and GNOME changes to take effect"
        log_info "  2. Set your terminal font to 'JetBrainsMono NL Nerd Font'"
        log_info "  3. Press Alt+F2, type 'r', Enter to reload GNOME Shell (X11 only)"
    elif [[ "$OS" == "macos" ]]; then
        log_info "Next steps:"
        log_info "  1. Restart your terminal for shell changes to take effect"
        log_info "  2. Set your terminal font to 'JetBrainsMono NL Nerd Font'"
    fi
    printf "\n"
}

# ============================================================
# Main
# ============================================================
main() {
    case "$COMMAND" in
        "")          run_full_setup ;;
        server)      run_server_preset ;;
        system)      run_script setup_system.sh ;;
        identities)  run_script setup_identities.sh ;;
        cli-apps)    run_script setup_apps_cli.sh ;;
        gui-apps)    run_script setup_apps_gui.sh ;;
        gnome)       run_script setup_gnome.sh "$GNOME_SUB" ;;
        fonts)       run_script setup_fonts.sh ;;
        zsh)         run_script setup_zsh.sh ;;
        macos)       run_script setup_macos.sh ;;
        symlinks)    run_script setup_symlinks.sh ;;
        update-cli)  run_script setup_apps_cli.sh --update ;;
    esac
}

main "$@"
