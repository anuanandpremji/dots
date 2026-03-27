#!/usr/bin/env bash
#
# GNOME setup: Flatpak, Extension Manager, GNOME extensions, dconf backup/restore.
# Linux only.
#
# Usage:
#   ./setup_gnome.sh [--dry-run]          Install tools + restore settings
#   ./setup_gnome.sh backup  [--dry-run]  Dump live dconf settings to repo
#   ./setup_gnome.sh restore [--dry-run]  Apply saved dconf settings from repo

set -u

SUBCOMMAND=""
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        backup|restore) SUBCOMMAND="$arg" ;;
        --dry-run)      DRY_RUN=true ;;
    esac
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="${DOTFILES:-$(cd "$SCRIPTS_DIR/.." && pwd)}"
source "$SCRIPTS_DIR/lib/common.sh"

if [[ "$OS" != "linux" ]]; then
    log_warn "setup_gnome.sh is Linux-only. Nothing to do on $OS."
    exit 0
fi

# ============================================================
# dconf helpers
# ============================================================
dconf_dump() {
    local path="$1" dest="$2"
    log_info "Backing up dconf $path → $dest"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$(dirname "$dest")"
        dconf dump "$path" > "$dest"
    fi
}

dconf_load() {
    local src="$1" path="$2"
    if [[ ! -f "$src" ]]; then log_warn "Not found, skipping: $src"; return; fi
    log_info "Restoring dconf $path ← $src"
    run dconf load "$path" < "$src"
}

# ============================================================
# Backup: dump live settings → repo
# ============================================================
gnome_backup() {
    log_section "Backing up GNOME settings"

    dconf_dump "/"                                          "$DOTFILES/.config/gnome/gnome-settings.dconf"
    dconf_dump "/org/gnome/shell/extensions/quake-terminal/" "$DOTFILES/.config/gnome/extensions/quake-terminal.dconf"
    dconf_dump "/org/gnome/shell/extensions/nightthemeswitcher/" "$DOTFILES/.config/gnome/extensions/nightthemeswitcher.dconf"
    dconf_dump "/org/gnome/shell/extensions/tiling-assistant/"   "$DOTFILES/.config/gnome/extensions/tiling-assistant.dconf"
    dconf_dump "/org/gnome/shell/extensions/ding/"               "$DOTFILES/.config/gnome/extensions/ding.dconf"
    dconf_dump "/org/gnome/shell/extensions/unblank/"            "$DOTFILES/.config/gnome/extensions/unblank.dconf"
    dconf_dump "/org/gnome/meld/"                                "$DOTFILES/.config/meld/meld-settings.dconf"

    log_info "Settings backed up to $DOTFILES/.config/gnome/"
    log_info "Review and commit the changes to save them."
}

# ============================================================
# Restore: apply repo settings → live system
# ============================================================
gnome_restore() {
    log_section "Restoring GNOME settings"

    if ! command -v dconf &>/dev/null; then
        log_warn "dconf not found — skipping settings restore"
        return
    fi

    dconf_load "$DOTFILES/.config/gnome/gnome-settings.dconf"                        "/"
    dconf_load "$DOTFILES/.config/gnome/extensions/quake-terminal.dconf"              "/org/gnome/shell/extensions/quake-terminal/"
    dconf_load "$DOTFILES/.config/gnome/extensions/nightthemeswitcher.dconf"          "/org/gnome/shell/extensions/nightthemeswitcher/"
    dconf_load "$DOTFILES/.config/gnome/extensions/tiling-assistant.dconf"            "/org/gnome/shell/extensions/tiling-assistant/"
    dconf_load "$DOTFILES/.config/gnome/extensions/ding.dconf"                        "/org/gnome/shell/extensions/ding/"
    dconf_load "$DOTFILES/.config/gnome/extensions/unblank.dconf"                     "/org/gnome/shell/extensions/unblank/"
    dconf_load "$DOTFILES/.config/meld/meld-settings.dconf"                           "/org/gnome/meld/"
}

# ============================================================
# Install
# ============================================================
setup_flatpak() {
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

install_extension_manager() {
    log_section "Extension Manager"
    if flatpak list 2>/dev/null | grep -q "com.mattjakeman.ExtensionManager"; then
        log_skip "Extension Manager"
        return
    fi
    log_info "Installing Extension Manager via Flatpak..."
    run flatpak install -y flathub com.mattjakeman.ExtensionManager
}

install_gnome_extensions() {
    log_section "GNOME Extensions"

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

    local COMMON_EXTENSIONS=(
        "quake-terminal@diegodario88.github.io"
        "nightthemeswitcher@romainvigier.fr"
        "grand-theft-focus@zalckos.github.com"
        "unblank@sun.wxg@gmail.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
    )

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
            DISTRO_EXTENSIONS=("appindicatorsupport@rgcjonas.gmail.com")
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
# Main
# ============================================================
main() {
    case "$SUBCOMMAND" in
        backup)
            gnome_backup
            ;;
        restore)
            gnome_restore
            ;;
        *)
            try_step setup_flatpak
            try_step install_extension_manager
            try_step install_gnome_extensions
            gnome_restore
            ;;
    esac
}

main "$@"
