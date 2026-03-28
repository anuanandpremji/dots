#!/bin/sh
#
# Migrates APT keys from the deprecated /etc/apt/trusted.gpg to /etc/apt/trusted.gpg.d/.
# Run this if apt warns: "Key is stored in legacy trusted.gpg keyring"
# Ubuntu/Debian only. Requires: apt-key, gpg, sudo.
#
# Usage: ./convert_gpg_key_format.sh [-h | --help]

case "${1:-}" in
    -h|--help)
        printf "Usage: ./convert_gpg_key_format.sh\n"
        printf "\n"
        printf "  Migrates APT keys from /etc/apt/trusted.gpg to /etc/apt/trusted.gpg.d/.\n"
        printf "  Run this if apt warns: \"Key is stored in legacy trusted.gpg keyring\"\n"
        printf "  Ubuntu/Debian only. Requires: apt-key, gpg, sudo.\n"
        exit 0 ;;
    "")  ;;
    *)
        printf "Unknown argument: %s\n" "$1" >&2; exit 1 ;;
esac

# Migrate legacy GPG keys to the new trusted.gpg.d format for APT
convert_gpg_key_format() {
    # Check if the system uses APT package manager
    if ! command -v apt-get &> /dev/null; then
        echo "Error: This script is only applicable to systems using APT package manager."
        return 1
    fi

    # Check if the user has sudo privileges
    if ! sudo -v &> /dev/null; then
        echo "Error: This script requires sudo privileges."
        return 1
    fi

    # Inform the user about the purpose of this function
    echo "Converting legacy GPG keys to the new format..."
    echo "This addresses the 'Key is stored in legacy trusted.gpg keyring' warning."

    # Create the trusted.gpg.d directory if it doesn't exist
    if ! sudo mkdir -p /etc/apt/trusted.gpg.d/; then
        echo "Error: Failed to create /etc/apt/trusted.gpg.d/ directory."
        return 1
    fi

    # Check if the legacy trusted.gpg keyring file exists
    if [ ! -f /etc/apt/trusted.gpg ]; then
        echo "No legacy trusted.gpg keyring found. No keys to convert."
        return 0
    fi

    # List keys from the legacy keyring
    echo "Keys found in /etc/apt/trusted.gpg:"
    KEYS=$(apt-key --keyring /etc/apt/trusted.gpg list | grep -Eo "([0-9A-F]{8})")

    if [ -z "$KEYS" ]; then
        echo "No keys found in /etc/apt/trusted.gpg to convert."
        return 0
    fi

    # Convert and move each key from the legacy keyring to the new format
    while read -r KEY; do
        # Extract the last 8 characters (the key ID)
        K=${KEY: -8}

        # Export the key and convert it to the new GPG format
        if sudo apt-key export "$K" | sudo gpg --dearmour -o "/etc/apt/trusted.gpg.d/imported-from-trusted-gpg-$K.gpg"; then
            echo "Successfully converted key: $K"
        else
            echo "Error: Failed to convert key: $K"
        fi
    done <<< "$KEYS"

    echo "Key conversion complete."

    # Provide instructions to remove the old trusted.gpg keyring, if applicable
    echo "To remove the legacy keyring and prevent warnings:"
    echo "  sudo rm /etc/apt/trusted.gpg"
    echo "However, ensure that all keys have been successfully converted before doing so."
}

# Execute the function
convert_gpg_key_format
