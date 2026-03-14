# Git Config

## Files

| File | Tracked | Purpose |
|------|---------|---------|
| `config` | Yes | Main git config — aliases, colors, delta pager, merge settings, `includeIf` rules. Symlinked to `~/.config/git/config`. |
| `config.default` | No | Default identity for repos outside `~/private/` and `~/work/`. Copy of whichever identity was chosen as default during setup. |
| `config.private` | No | Private identity. Created by `setup-identities`, applied automatically in `~/private/`. |
| `config.work` | No | Work identity. Created by `setup-identities`, applied automatically in `~/work/`. |

## Features

- **Delta pager** — Syntax-highlighted diffs with line numbers and hyperlinks. Used as both `core.pager` and `interactive.diffFilter`.
- **Pretty log** — `git lg` shows a compact, colored, one-line-per-commit log with date, author, and branch decorations.
- **Merge** — Uses `diff3` conflict style (shows base, ours, and theirs).
- **Split config** — `config` includes `config.default` (fallback identity) and uses `includeIf` to apply `config.private` in `~/private/` and `config.work` in `~/work/`.

## Multi-Identity Setup

The `setup-identities` script (run automatically by `setup.sh`) creates separate SSH keys, git identities, and project directories:

| Directory | SSH key | Host alias | Git identity |
|-----------|---------|------------|--------------|
| `~/private/` | `~/.ssh/id_private` | `github-private` | `config.private` (default) |
| `~/work/` | `~/.ssh/id_work` | `github-work` | `config.work` (via `includeIf`) |

The correct name, email, and SSH key are applied automatically based on where you clone:

```shell
cd ~/private && git clone git@github-private:user/repo.git    # private identity
cd ~/work    && git clone git@github-work:org/repo.git        # work identity
```

No per-repo `git config` needed — `includeIf` in the main config applies the correct identity based on directory. For repos outside both directories, `config.default` is used (set during `setup-identities` — choose work on work PCs, private on private PCs).

## SSH Host Aliases

Configured in `~/.ssh/config` by `setup-identities`:

```
Host github-private
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_private
    IdentitiesOnly yes

Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_work
    IdentitiesOnly yes
```

## Setup

Handled by `setup-symlinks`:

```
~/.config/git/config → dotfiles/.config/git/config
```

`config.default`, `config.private`, and `config.work` are created by `setup-identities` (not symlinked — they're machine-specific and gitignored).
