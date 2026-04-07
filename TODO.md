# TODO

## Zsh plugins

Add zsh-autosuggestions, fast-syntax-highlighting, and fzf-tab plugins. Create an installer/updater script (or integrate into setup_apps_cli.sh) to clone/update them. Wire them into .zshrc.

## Neovim: migrate init.vim to Lua

The nvim config is still VimScript. Migrate to init.lua with lazy.nvim plugin management and native LSP support.

## Expand Brewfile

`scripts/Brewfile` is minimal. Sync it with what `setup_apps_cli.sh` installs via brew on macOS (btop, jq, shellcheck, shfmt, tree, tmux, mise, etc.).

## tmux configuration

Add a tmux config with TPM plugin manager, tmux-resurrect (session persistence), tmux-yank (clipboard integration), and sensible defaults. Add to setup_symlinks.sh.

## GPG agent config

Add `gpg-agent.conf` under `.config/gnupg/` with extended cache TTL (e.g. 7 days) to avoid re-entering the GPG passphrase constantly. Currently `GNUPGHOME` is exported but no agent config exists.

## GitHub API rate limiting in setup_apps_cli.sh

The `gh_latest_url()` function fetches the latest release download URL from the GitHub API using unauthenticated `curl` requests. GitHub's unauthenticated rate limit is 60 requests/hour per IP. On a fresh machine setup, multiple calls to `gh_latest_url()` (fzf, fd, bat, eza, delta, etc.) can exhaust the quota and silently return error JSON instead of a download URL, causing silent installation failures.

**Options to consider:**
- Check for a `GITHUB_TOKEN` env var and pass `-H "Authorization: Bearer $GITHUB_TOKEN"` when present (raises limit to 5000/hour)
- Detect when the API response is not a valid download URL and print a clear error instead of attempting to download garbage
- Add a local cache: store the resolved URL per tool name within a single script run to avoid duplicate requests for the same release
