#!/bin/bash

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Miscellaneous shell functions                                                                                       ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Overview                                                                                                            ║
#║ --------                                                                                                            ║
#║ od()              - Run a command in the background and disown it                                                   ║
#║ tre()             - tree with color, hidden files, .git exclusion, piped through less                               ║
#║ update_dnf()      - Update, upgrade, and clean DNF packages                                                         ║
#║ update_apt()      - Update, upgrade, and clean APT packages                                                         ║
#║ update_flatpaks() - Update and clean Flatpak packages                                                               ║
#║ update_snaps()    - Update Snap packages                                                                            ║
#║ do_update()       - Run system updates across all detected package managers                                         ║
#║ sysinfo()         - Show system information (OS, CPU, memory, disk, network)                                        ║
#║ fkill()           - Find and kill a running process with fzf                                                        ║
#║ sshf()            - SSH into a host from ~/.ssh/config with fzf                                                     ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# od() - Run a command, disown the process and then return to prompt without terminating the command

# Usage:
# od meld ~/dotfiles ~/repo

od()
{
    "$@" &
    disown;
    return 0;
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# tre() - Better `tree` with color, shows hidden files, ignores the `.git` directory and lists directories first

# Usage:
# tre dir1 dir2

tre()
{
    # The output gets piped into `less` with options to preserve color and line numbers, unless it fits in one screen
    tree -aC -I ".git" --dirsfirst "$@" | less -FRNX;
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Update, upgrade and clean dnf, apt, flatpak and snap packages in your system

# Dependencies: confirm()

# update_dnf() - Run updates for DNF package manager
update_dnf()
{
    if ! __has dnf; then return 1; fi

    printf "Checking for available DNF updates...\n";

    # dnf check-update exits 100 if updates are available, 0 if none, 1 on error
    local updates rc;
    updates=$(dnf check-update 2>/dev/null);
    rc=$?;

    if [ "$rc" -eq 0 ]; then
        printf "No DNF updates available.\n\n";
        return 0;
    elif [ "$rc" -ne 100 ]; then
        printf "Error checking for DNF updates.\n\n";
        return 1;
    fi

    printf "%s\n\n" "$updates";
    if ! confirm 'Start DNF update? [y/N]'; then printf "DNF update cancelled.\n\n"; return 0; fi

    sudo dnf upgrade -y || { printf "DNF upgrade failed.\n\n"; return 1; };

    printf "Doing DNF clean-up...\n";
    sudo dnf autoremove -y;
    sudo dnf clean all;

    printf "DNF update finished.\n\n";
}

# update_apt() - Run updates for APT package manager
update_apt()
{
    if ! __has apt-get; then return 1; fi

    printf "Checking for available APT updates...\n";
    sudo apt update -qq;

    local updates;
    updates=$(sudo apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }');

    if [ -z "$updates" ]; then
        printf "No APT updates available.\n\n";
        return 0;
    fi

    printf "%s\n\n" "$updates";
    if ! confirm 'Start APT update? [y/N]'; then printf "APT update cancelled.\n\n"; return 0; fi

    sudo apt full-upgrade -y || { printf "APT upgrade failed.\n\n"; return 1; };

    printf "Doing APT clean-up...\n";
    sudo apt install -f -y;
    sudo apt autoremove -y;
    sudo apt clean;

    printf "APT update finished.\n\n";
}

# update_flatpaks() - Run updates for Flatpak package manager
update_flatpaks()
{
    if ! __has flatpak; then return 1; fi

    printf "Checking for available Flatpak updates...\n";

    local updates;
    updates=$(flatpak remote-ls --updates 2>/dev/null);

    if [ -z "$updates" ]; then
        printf "No Flatpak updates available.\n\n";
        return 0;
    fi

    printf "%s\n\n" "$updates";
    if ! confirm 'Start Flatpak update? [y/N]'; then printf "Flatpak update cancelled.\n\n"; return 0; fi

    flatpak update -y || { printf "Flatpak update failed.\n\n"; return 1; };

    printf "Doing Flatpak clean-up...\n";
    flatpak uninstall --unused -y;

    printf "Flatpak update finished.\n\n";
}

# update_snaps() - Run updates for Snap package manager
update_snaps()
{
    if ! __has snap; then return 1; fi

    printf "Checking for available Snap updates...\n";

    local updates;
    if ! updates=$(sudo snap refresh --list 2>/dev/null) || [ -z "$updates" ]; then
        printf "No Snap updates available.\n\n";
        return 0;
    fi

    printf "%s\n\n" "$updates";
    if ! confirm 'Start Snap update? [y/N]'; then printf "Snap update cancelled.\n\n"; return 0; fi

    sudo snap refresh || { printf "Snap update failed.\n\n"; return 1; };

    printf "Snap update finished.\n\n";
}

# do_update() - Identify the distro-specific package manager and run system updates and cleanup
do_update()
{
    printf "\nStarting system update...\n";

    if _has apt-get; then update_apt;      fi
    if _has dnf;     then update_dnf;      fi
    if _has flatpak; then update_flatpaks; fi
    if _has snap;    then update_snaps;    fi

    printf "Done. It's good practice to do a system reboot now.\n"
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# sysinfo() - Show system information using built-in tools (no external dependencies)
sysinfo() {
    if [[ "$(uname)" == "Darwin" ]]; then
        system_profiler SPSoftwareDataType SPHardwareDataType SPDisplaysDataType SPStorageDataType
        return
    fi

    echo "── OS ──"
    grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"'
    uname -r

    echo -e "\n── CPU ──"
    lscpu 2>/dev/null | grep -E "^(Model name|CPU\(s\)|Core|Thread|Architecture)" | sed 's/^[[:space:]]*//'

    echo -e "\n── Memory ──"
    free -h 2>/dev/null | grep -E "^(Mem|Swap)"

    echo -e "\n── Disk ──"
    lsblk -d -o NAME,SIZE,MODEL 2>/dev/null | grep -v "^loop"

    echo -e "\n── Network ──"
    ip -br addr 2>/dev/null | grep -v "^lo"
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# fkill() - Fuzzy find a process and kill it

fkill() {
    local pid

    local -a fzf_opts=(
        -m
        --border-label=" Find and Kill a Process "
        --border-label-pos=2
        --color 'label:yellow:bold'
    )

    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u "$UID" | sed 1d | fzf "${fzf_opts[@]}" | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf "${fzf_opts[@]}" | awk '{print $2}')
    fi

    if [ -n "$pid" ]; then
        printf "%s" "$pid" | xargs kill -"${1:-9}"
    fi
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# sshf() - Fuzzy SSH into the saved SSH configs

sshf()
{
    local host
    host=$(grep '^[[:space:]]*Host[[:space:]]' ~/.ssh/config | grep -v '[*?]' | cut -d ' ' -f 2 | fzf)
    [ $? -eq 0 ] && ssh "$host"
}

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #

# Dependency check

if ! _has tree;    then printf "tree: program not found. Install tree.\n"; fi
if ! _has confirm; then printf "confirm(): function not loaded.\n";        fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
