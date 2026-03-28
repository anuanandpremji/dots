#!/bin/sh
#
# Redacts secrets and credentials from a shell history file in-place.
# Reports which line numbers were changed.
#
# Patterns matched:
#   AWS access key IDs (AKIA*, ASIA*) and AWS_SECRET_ACCESS_KEY=
#   GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)
#   GitLab personal access tokens (glpat-...)
#   Slack tokens (xoxb-, xoxp-, etc.) and webhook URLs
#   Generic variable assignments: KEY=, SECRET=, TOKEN=, PASS=/PASSWORD=
#
# Usage: ./sanitize_history.sh <file>

case "${1:-}" in
    -h|--help)
        printf "Usage: ./sanitize_history.sh <file>\n"
        printf "\n"
        printf "  Redacts secrets and credentials from a shell history file in-place.\n"
        printf "  Reports which line numbers were changed.\n"
        printf "\n"
        printf "  Patterns matched:\n"
        printf "    AWS access key IDs (AKIA*, ASIA*) and AWS_SECRET_ACCESS_KEY=\n"
        printf "    GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)\n"
        printf "    GitLab personal access tokens (glpat-...)\n"
        printf "    Slack tokens (xoxb-, xoxp-, etc.) and webhook URLs\n"
        printf "    Generic assignments: KEY=, SECRET=, TOKEN=, PASS=/PASSWORD=\n"
        exit 0 ;;
esac

if [ $# -eq 0 ]; then
    printf "Usage: %s <file>\n" "$0" >&2
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: $1 is not a file" >&2
    exit 1
fi

tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT

# We use a single sed execution with multiple expressions for efficiency
sed '
    # --- CLOUD & INFRASTRUCTURE ---
    # AWS Access Key ID (20 chars starting with AKIA/ASIA)
    s/AKIA[A-Z0-9]\{16\}/<AWS_KEY_ID>/g
    s/ASIA[A-Z0-9]\{16\}/<AWS_SESSION_ID>/g
    # AWS Secret Access Key (40 chars, no prefix, usually assigned to a variable)
    s/\(AWS_SECRET_ACCESS_KEY=\)[^[:space:]"]*/\1<AWS_SECRET_KEY>/g

    # --- GIT PROVIDERS ---
    # GitHub (ghp, gho, ghu, ghs, ghr)
    s/gh[pousr]_[a-zA-Z0-9]\{36,255\}/<GITHUB_TOKEN>/g
    # GitLab Personal Access Tokens (prefix glpat-)
    s/glpat-[a-zA-Z0-9-]\{20,40\}/<GITLAB_TOKEN>/g

    # --- CI/CD & COLLABORATION ---
    # Jenkins (usually 32 hex chars assigned to a variable)
    s/\(JENKINS_TOKEN=\)[a-f0-9]\{32\}/\1<JENKINS_TOKEN>/g
    # Slack Webhooks and Tokens (xoxb-, xoxp-, etc.)
    s/xox[baprs]-[a-zA-Z0-9-]\{10,255\}/<SLACK_TOKEN>/g
    s/https:\/\/hooks\.slack\.com\/services\/[A-Z0-9\/]*/<SLACK_WEBHOOK_URL>/g

    # --- GENERIC FALLBACKS ---
    # Catch-all for common variable patterns: KEY=, PASS=, SECRET=
    # This matches the key and replaces the value until a space, quote, or semicolon
    s/\([a-zA-Z0-9_]*TOKEN=\)[^[:space:];"]*/\1<TOKEN>/g
    s/\([a-zA-Z0-9_]*KEY=\)[^[:space:];"]*/\1<KEY>/g
    s/\([a-zA-Z0-9_]*SECRET=\)[^[:space:];"]*/\1<SECRET>/g
    s/\([a-zA-Z0-9_]*PASS\(WORD\)\{0,1\}=\)[^[:space:];"]*/\1<PASSWORD>/g
' "$1" > "$tmp"

# Compare line by line to find which lines changed
changed=""
n=0
while IFS= read -r orig <&3 && IFS= read -r new <&4; do
    n=$((n + 1))
    if [ "$orig" != "$new" ]; then
        if [ -n "$changed" ]; then
            changed="$changed, $n"
        else
            changed="$n"
        fi
    fi
done 3<"$1" 4<"$tmp"

if [ -n "$changed" ]; then
    cp "$tmp" "$1"
    echo "Sanitized lines $changed."
else
    echo "No sensitive information found."
fi
