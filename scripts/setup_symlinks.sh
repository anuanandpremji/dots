#!/usr/bin/env bash
#
# Symlinks dotfiles to their expected locations.
# Run once after cloning or downloading the dotfiles repo, and again after any structural changes.
# dconf settings are handled separately by setup_gnome.sh.
#
# ┌─ What gets linked ────────────────────────────────────────────────────────────────────────────────┐
# │                                                                                                   │
# │  dotfiles/                                  ~/ (target)                                           │
# │  ──────────────────────────────────────     ────────────────────────────────────────────────────  │
# │  .config/shell/bash/.bashrc             󰌷   ~/.bashrc                                             │
# │  .config/shell/zsh/.zshenv              󰌷   ~/.zshenv                     (if zsh installed)      │
# │  .config/git/config                     󰌷   ~/.config/git/config                                  │
# │  .config/wezterm/                       󰌷   ~/.config/wezterm/            (if wezterm found)      │
# │  .config/nvim/                          󰌷   ~/.config/nvim/               (if nvim found)         │
# │  .config/zed/                           󰌷   ~/.config/zed/                (if zed found)          │
# │  .config/fresh/config.json              󰌷   ~/.config/fresh/config.json   (if fresh found)        │
# │  .config/micro/{settings,bindings,...}  󰌷   ~/.config/micro/              (if micro found)        │
# │  .config/vscode/User/                   󰌷   ~/.config/Code/User/          (if code found)         │
# │  .config/claude/CLAUDE.md               󰌷   ~/.claude/CLAUDE.md                                   │
# │  .local/bin/*                           󰌷   ~/.local/bin/*                (shell utilities)       │
# │  .local/share/fonts/*.{ttf,otf}         󰆏   ~/.local/share/fonts/         (copied, not symlinked) │
# │                                                                                                   │
# └───────────────────────────────────────────────────────────────────────────────────────────────────┘
#
# Usage: ./setup_symlinks.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            printf "Usage: ./setup_symlinks.sh [--dry-run]\n"
            printf "\n"
            printf "  Symlinks dotfiles config files to their expected locations in ~/.\n"
            printf "  Run once after cloning the repo, and again after any structural changes.\n"
            printf "  Existing files are backed up with a .bak suffix before being replaced.\n"
            printf "  dconf settings are handled separately by setup_gnome.sh.\n"
            printf "\n"
            printf "  --dry-run   Show what would be linked without making any changes\n"
            exit 0 ;;
        *)
            printf "Unknown argument: %s\n" "$arg" >&2; exit 1 ;;
    esac
done

# This script lives at <dotfiles>/scripts/setup_symlinks.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "$DRY_RUN" == true ]]; then
    echo "=== DRY RUN — no changes will be made ==="
    echo
fi

# ============================================================
# Colors
# ============================================================
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' NC=''
fi

# ============================================================
# Helpers
# ============================================================
link_path() {
    local src="$1" dest="$2"

    if [[ ! -e "$src" ]]; then
        printf "${RED}[SKIP]${NC}   Source does not exist: %s\n" "$src"
        return
    fi

    if [[ -L "$dest" ]]; then
        local current_target
        current_target=$(readlink "$dest")
        if [[ "$current_target" == "$src" ]]; then
            printf "${GREEN}[OK]${NC}     %s\n" "$dest"
            return
        fi
        printf "${YELLOW}[UPDATE]${NC} %s (was -> %s)\n" "$dest" "$current_target"
    elif [[ -e "$dest" ]]; then
        printf "${YELLOW}[BACKUP]${NC} %s -> %s.bak\n" "$dest" "$dest"
        [[ "$DRY_RUN" == false ]] && mv "$dest" "${dest}.bak"
    fi

    local parent
    parent=$(dirname "$dest")
    if [[ ! -d "$parent" ]]; then
        printf "${YELLOW}[MKDIR]${NC}  %s\n" "$parent"
        [[ "$DRY_RUN" == false ]] && mkdir -p "$parent"
    fi

    printf "${GREEN}[LINK]${NC}   %s -> %s\n" "$dest" "$src"
    [[ "$DRY_RUN" == false ]] && ln -sf "$src" "$dest"
}

IS_LINUX=false
IS_MACOS=false
case "$(uname -s)" in
    Linux)  IS_LINUX=true ;;
    Darwin) IS_MACOS=true ;;
esac

echo "========================================"
echo " Dotfiles Symlink Setup"
echo "========================================"
echo

# ── Shell ─────────────────────────────────────────────────────────────────────
echo "── Shell ──"
link_path "$DOTFILES/.config/shell/bash/.bashrc" "$HOME/.bashrc"
if command -v zsh &>/dev/null; then
    link_path "$DOTFILES/.config/shell/zsh/.zshenv" "$HOME/.zshenv"
fi

# ── Git ───────────────────────────────────────────────────────────────────────
echo "── Git ──"
link_path "$DOTFILES/.config/git/config" "$HOME/.config/git/config"
# NOTE: config.default, config.private, config.work are machine-specific.
# They are created by setup_identities.sh, not symlinked.

# ── Terminals ─────────────────────────────────────────────────────────────────
if command -v wezterm &>/dev/null || [[ -d "/Applications/WezTerm.app" ]]; then
    echo "── WezTerm ──"
    link_path "$DOTFILES/.config/wezterm" "$HOME/.config/wezterm"
fi

# ── Editors ───────────────────────────────────────────────────────────────────
if command -v nvim &>/dev/null; then
    echo "── Neovim ──"
    link_path "$DOTFILES/.config/nvim" "$HOME/.config/nvim"
fi

if command -v zed &>/dev/null || [[ -d "/Applications/Zed.app" ]]; then
    echo "── Zed ──"
    link_path "$DOTFILES/.config/zed" "$HOME/.config/zed"
fi

if command -v fresh &>/dev/null; then
    echo "── Fresh ──"
    link_path "$DOTFILES/.config/fresh/config.json" "$HOME/.config/fresh/config.json"
fi

if command -v micro &>/dev/null; then
    echo "── Micro ──"
    link_path "$DOTFILES/.config/micro/settings.json"  "$HOME/.config/micro/settings.json"
    link_path "$DOTFILES/.config/micro/bindings.json"  "$HOME/.config/micro/bindings.json"
    link_path "$DOTFILES/.config/micro/init.lua"       "$HOME/.config/micro/init.lua"
fi

# ── VS Code ───────────────────────────────────────────────────────────────────
if command -v code &>/dev/null; then
    echo "── VS Code ──"
    if [[ "$IS_MACOS" == true ]]; then
        link_path "$DOTFILES/.config/vscode/User/settings.json"    "$HOME/Library/Application Support/Code/User/settings.json"
        link_path "$DOTFILES/.config/vscode/User/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    else
        link_path "$DOTFILES/.config/vscode/User/settings.json"    "$HOME/.config/Code/User/settings.json"
        link_path "$DOTFILES/.config/vscode/User/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
    fi
fi

# ── Claude Code ───────────────────────────────────────────────────────────────
echo "── Claude Code ──"
link_path "$DOTFILES/.config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# ── .local/bin/ → ~/.local/bin/ ───────────────────────────────────────────────
# All files in .local/bin/ are symlinked automatically — add a tool there and it just works.
echo "── Shell scripts ──"
for f in "$DOTFILES/.local/bin/"*; do
    link_path "$f" "$HOME/.local/bin/$(basename "$f")"
done

# ── Linux-only: WezTerm dropdown desktop entry ────────────────────────────────
if [[ "$IS_LINUX" == true ]] && command -v wezterm &>/dev/null; then
    echo "── WezTerm Dropdown ──"
    link_path "$DOTFILES/.local/share/applications/wezterm-dropdown.desktop" "$HOME/.local/share/applications/wezterm-dropdown.desktop"
fi

# ── Fonts (copy, not symlink) ─────────────────────────────────────────────────
echo "── Fonts ──"
if [[ -d "$DOTFILES/.local/share/fonts" ]] && [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$HOME/.local/share/fonts"
    find "$DOTFILES/.local/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec sh -c '
        for f; do
            dest="$HOME/.local/share/fonts/$(basename "$f")"
            [ -f "$dest" ] || cp "$f" "$dest"
        done
    ' _ {} +
    printf "${GREEN}[OK]${NC}     Fonts synced to ~/.local/share/fonts/\n"
elif [[ "$DRY_RUN" == true ]]; then
    printf "${YELLOW}[DRY-RUN]${NC} Would sync fonts to ~/.local/share/fonts/\n"
fi

# ── Post-setup ────────────────────────────────────────────────────────────────
echo
if [[ "$DRY_RUN" == false ]]; then
    if command -v fc-cache &>/dev/null; then
        echo "Rebuilding font cache..."
        fc-cache -f
    fi
    printf "${GREEN}Done!${NC}\n"
    if [[ "$IS_LINUX" == true ]] && command -v dconf &>/dev/null; then
        echo
        echo "  To restore GNOME settings, run:"
        echo "    ./scripts/setup_gnome.sh restore"
    fi
else
    echo "=== DRY RUN complete — re-run without --dry-run to apply ==="
fi
