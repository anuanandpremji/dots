#!/usr/bin/env bash
#
# Interactive Git & SSH identity setup.
# Sets up separate SSH keys and git identities for work and private accounts.
# Configures ~/.ssh/config so each GitHub host alias uses the correct key.
#
# Usage: ./setup_identities.sh [--dry-run]
#
# Result:
#   ~/.ssh/id_private              Private SSH key
#   ~/.ssh/id_work                 Work SSH key (optional)
#   ~/.ssh/config                  Host aliases: github-private, github-work
#   ~/.config/git/config.private   Private git identity
#   ~/.config/git/config.work      Work git identity (optional)
#   ~/.config/git/config.default   Symlink to whichever identity is the default

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Colors ──
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' BOLD='' NC=''
fi

log_info()    { printf "${GREEN}[INFO]${NC}    %s\n" "$1"; }
log_warn()    { printf "${YELLOW}[WARN]${NC}    %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${NC}   %s\n" "$1" >&2; }
log_section() { printf "\n${BOLD}${BLUE}── %s ──${NC}\n" "$1"; }
log_skip()    { printf "${YELLOW}[SKIP]${NC}    %s\n" "$1"; }

run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$*"
    else
        "$@"
    fi
}

if [[ "$DRY_RUN" == true ]]; then
    printf "\n${YELLOW}=== DRY RUN — no changes will be made ===${NC}\n"
fi

# ── Helpers ──

# Prompt for name and email with confirmation loop
# Sets variables: <prefix>_name, <prefix>_email
# Usage: collect_identity <prefix> <label>
collect_identity() {
    local prefix="$1" label="$2"
    local name email

    while true; do
        printf "  %s name: " "$label"
        read -r name
        printf "  %s email: " "$label"
        read -r email
        printf "\n"
        printf "    Name:  %s\n" "$name"
        printf "    Email: %s\n" "$email"
        printf "\n"
        printf "  Is this correct? [Y/n]: "
        read -r confirm
        if [[ "${confirm:-Y}" =~ ^[Yy] ]]; then
            break
        fi
        printf "\n"
    done

    # Export to caller via eval (prefix_name, prefix_email)
    eval "${prefix}_name=\$name"
    eval "${prefix}_email=\$email"
}

# Generate an SSH key and add it to ssh-agent
# Usage: create_ssh_key <key_path> <email> <label>
create_ssh_key() {
    local key_path="$1" email="$2" label="$3"

    if [[ -f "$key_path" ]]; then
        log_warn "$label SSH key already exists at $key_path"
        printf "  Delete and regenerate? [y/N]: "
        read -r regen
        if [[ "${regen:-N}" =~ ^[Yy] ]]; then
            run rm -f "$key_path" "${key_path}.pub"
            log_info "Deleted old $label key"
        else
            log_skip "Keeping existing $label SSH key"
            return
        fi
    fi

    printf "\n"
    log_info "Generating $label SSH key ($key_path)..."
    printf "  Enter a passphrase (or leave empty for none): "
    read -rs passphrase
    printf "\n"

    run mkdir -p "$(dirname "$key_path")"
    run ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N "${passphrase:-}" -q

    log_info "Public key:"
    printf "\n"
    cat "${key_path}.pub"
    printf "\n"
    log_warn "Add this key to your GitHub account: https://github.com/settings/ssh/new"
    printf "  Press ENTER after you have added the key..."
    read -r _
}

# Add a Host block to ~/.ssh/config if it doesn't already exist
# Usage: add_ssh_host <host_alias> <key_path>
add_ssh_host() {
    local host_alias="$1" key_path="$2"
    local ssh_config="$HOME/.ssh/config"

    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"
    [[ -f "$ssh_config" ]] || run touch "$ssh_config"
    run chmod 600 "$ssh_config"

    if grep -q "^Host ${host_alias}$" "$ssh_config" 2>/dev/null; then
        log_skip "SSH config already has Host $host_alias"
        return
    fi

    log_info "Adding Host $host_alias to ~/.ssh/config"
    if [[ "$DRY_RUN" == false ]]; then
        cat >> "$ssh_config" <<EOF

Host $host_alias
    HostName github.com
    User git
    IdentityFile $key_path
    IdentitiesOnly yes
EOF
    fi
}

# Verify SSH authentication against a GitHub host alias
# Usage: verify_github_ssh <host_alias>
verify_github_ssh() {
    local host_alias="$1"

    log_info "Testing SSH connection to $host_alias..."
    local output
    output=$(ssh -T "$host_alias" 2>&1) || true

    if printf '%s' "$output" | grep -qi "successfully authenticated"; then
        log_info "Authenticated successfully via $host_alias"
        return 0
    else
        log_warn "Authentication test did not confirm success."
        log_warn "Output: $output"
        log_warn "You may need to add the public key to GitHub, or the key hasn't propagated yet."
        return 1
    fi
}

# ── Main ──

printf "\n"
printf "${BOLD}========================================${NC}\n"
printf "${BOLD} Git & SSH Identity Setup${NC}\n"
printf "${BOLD}========================================${NC}\n\n"

# ── Private account ──
log_section "Private GitHub account"

printf "  Set up a private GitHub SSH key? [Y/n]: "
read -r setup_private
setup_private="${setup_private:-Y}"

if [[ "$setup_private" =~ ^[Yy] ]]; then
    collect_identity "private" "Private"

    create_ssh_key "$HOME/.ssh/id_private" "$private_email" "Private"
    add_ssh_host "github-private" "$HOME/.ssh/id_private"

    # Start ssh-agent and add key
    if ! ssh-add -l &>/dev/null; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    ssh-add "$HOME/.ssh/id_private" 2>/dev/null || true

    verify_github_ssh "github-private" || true
fi

# ── Work account ──
log_section "Work GitHub account"

printf "  Set up a work GitHub SSH key? [y/N]: "
read -r setup_work
setup_work="${setup_work:-N}"

if [[ "$setup_work" =~ ^[Yy] ]]; then
    collect_identity "work" "Work"

    create_ssh_key "$HOME/.ssh/id_work" "$work_email" "Work"
    add_ssh_host "github-work" "$HOME/.ssh/id_work"

    # Add work key to agent
    ssh-add "$HOME/.ssh/id_work" 2>/dev/null || true

    verify_github_ssh "github-work" || true
fi

# ── Project directories ──
log_section "Project directories"

log_info "Creating ~/private and ~/work directories..."
run mkdir -p "$HOME/private"
run mkdir -p "$HOME/work"

# ── Git identity files ──
GIT_CONFIG_DIR="$HOME/.config/git"
run mkdir -p "$GIT_CONFIG_DIR"

# Helper to write a git identity file if needed
# Usage: write_git_identity <file_path> <name> <email> <label>
write_git_identity() {
    local file="$1" name="$2" email="$3" label="$4"

    if [[ -f "$file" ]]; then
        log_info "Existing $file:"
        cat "$file"
        printf "\n"
        printf "  Overwrite %s identity? [y/N]: " "$label"
        read -r ow
        if [[ ! "${ow:-N}" =~ ^[Yy] ]]; then
            log_skip "Keeping existing $label identity"
            return
        fi
    fi

    log_info "Writing $file"
    if [[ "$DRY_RUN" == false ]]; then
        cat > "$file" <<EOF
[user]
    email    = $email
    name     = $name
EOF
    fi
}

# ── config.private ──
if [[ "${setup_private:-N}" =~ ^[Yy] ]]; then
    log_section "Git identity (config.private — for ~/private/)"
    write_git_identity "$GIT_CONFIG_DIR/config.private" \
        "${private_name}" "${private_email}" "private"
fi

# ── config.work ──
if [[ "${setup_work:-N}" =~ ^[Yy] ]]; then
    log_section "Git identity (config.work — for ~/work/)"
    write_git_identity "$GIT_CONFIG_DIR/config.work" \
        "${work_name}" "${work_email}" "work"
fi

# ── config.default (which identity is the default for repos outside ~/private/ and ~/work/) ──
log_section "Default git identity"

has_private=false; [[ -f "$GIT_CONFIG_DIR/config.private" ]] && has_private=true
has_work=false;    [[ -f "$GIT_CONFIG_DIR/config.work" ]]    && has_work=true

if [[ "$has_private" == true && "$has_work" == true ]]; then
    printf "\n"
    printf "  Which identity should be the default (for repos outside ~/private/ and ~/work/)?\n\n"
    printf "    1) Private  (%s)\n" "$(grep 'email' "$GIT_CONFIG_DIR/config.private" 2>/dev/null | awk '{print $3}')"
    printf "    2) Work     (%s)\n" "$(grep 'email' "$GIT_CONFIG_DIR/config.work" 2>/dev/null | awk '{print $3}')"
    printf "\n"
    printf "  Choice [1/2]: "
    read -r default_choice
    case "$default_choice" in
        2)  default_target="config.work" ;;
        *)  default_target="config.private" ;;
    esac
elif [[ "$has_work" == true ]]; then
    default_target="config.work"
elif [[ "$has_private" == true ]]; then
    default_target="config.private"
else
    log_warn "No git identities configured — skipping config.default"
    default_target=""
fi

if [[ -n "${default_target:-}" ]]; then
    log_info "Setting default identity → $default_target"
    if [[ "$DRY_RUN" == false ]]; then
        cp "$GIT_CONFIG_DIR/$default_target" "$GIT_CONFIG_DIR/config.default"
    fi
fi

# ── Summary ──
printf "\n"
printf "${BOLD}========================================${NC}\n"
printf "${BOLD} Setup complete${NC}\n"
printf "${BOLD}========================================${NC}\n\n"

printf "  SSH keys:\n"
[[ -f "$HOME/.ssh/id_private" ]] && printf "    Private:  ~/.ssh/id_private\n"
[[ -f "$HOME/.ssh/id_work" ]]    && printf "    Work:     ~/.ssh/id_work\n"
printf "\n"

printf "  SSH host aliases (for git remote URLs):\n"
grep -q "^Host github-private$" "$HOME/.ssh/config" 2>/dev/null && \
    printf "    Private:  github-private  →  git@github-private:user/repo.git\n"
grep -q "^Host github-work$" "$HOME/.ssh/config" 2>/dev/null && \
    printf "    Work:     github-work     →  git@github-work:org/repo.git\n"
printf "\n"

printf "  Git identities:\n"
[[ -f "$GIT_CONFIG_DIR/config.private" ]] && printf "    Private (~/private/):  config.private\n"
[[ -f "$GIT_CONFIG_DIR/config.work" ]]    && printf "    Work (~/work/):        config.work\n"
[[ -f "$GIT_CONFIG_DIR/config.default" ]] && printf "    Default:               config.default → %s\n" "${default_target:-}"
printf "\n"

printf "  Project directories:\n"
printf "    ~/private/   →  private git identity + github-private SSH key\n"
printf "    ~/work/      →  work git identity + github-work SSH key\n"
printf "    (elsewhere)  →  default identity (config.default)\n"
printf "\n"

printf "  Usage:\n"
[[ -f "$HOME/.ssh/id_private" ]] && \
    printf "    cd ~/private && git clone git@github-private:user/repo.git\n"
[[ -f "$HOME/.ssh/id_work" ]] && \
    printf "    cd ~/work    && git clone git@github-work:org/repo.git\n"
printf "\n"
printf "  The correct name/email is applied automatically based on the directory.\n"
printf "\n"
