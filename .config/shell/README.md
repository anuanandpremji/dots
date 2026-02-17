# Shell Dotfiles

A collection of personal dotfiles for bash and zsh
This configuration is designed to be lightweight and fast, avoiding plugins and frameworks that can slow things down

## <u>Screenshots</u>

TODO:

## <u>Prerequisites</u>

Before you begin, ensure you have the following installed:

1. **Nerd Fonts** – Required to render glyphs/icons properly. This setup is tested with `JetBrainsMono NF`, but any [Nerd Font](https://github.com/ryanoasis/nerd-fonts) should work.
2. **fzf** – Provides fuzzy search for history and file navigation.
3. **fd** – Required by the `Ctrl-T` keybinding to find files and directories.

## <u>Directory Structure</u>

```ascii
.
├── bash
│   ├── .bashaliases --------------> Aliases
│   ├── .bashexports --------------> Global exports, XDG path
│   ├── .bashfunctions ------------> Shell functions that work across BASH
│   ├── .bashfzf ------------------> BASH keybindings with FZF dependency
│   ├── .bashprompt ---------------> Custom plugin-free BASH prompt
│   └── .bashrc -------------------> BASH configuration file
│
├── history
│   └── .history ------------------> Log of all shell commands (shared between shells)
│
├── scripts
│   └── convert_gpg_key_format ----> Convert GPG keys to the new format required by the APT package manager
│
├── starship
│   └── gaps.toml -----------------> Starship prompt based on the original agnoster theme with added gaps
│   └── pills.toml ----------------> Starship prompt with pill shaped segments
│
├── zsh
│   ├── .zshaliases ---------------> Aliases
│   ├── .zshenv -------------------> Sets ZDOTDIR and other global ZSH defaults
│   ├── .zshexports ---------------> Global exports, XDG paths
│   ├── .zshfunctions -------------> Shell functions that work across ZSH
│   ├── .zshfzf -------------------> ZSH keybindings with FZF dependency
│   ├── .zshprompt_theme_pure -----> Custom plugin-free ZSH prompt theme
│   ├── .zshprompt_theme_cascade --> Custom plugin-free ZSH prompt theme
│   └── .zshrc --------------------> ZSH configuration file
│
└── README.md ---------------------> This README file
```

## <u>Installation</u>

### 1. Clone the repository to your PC

```shell
$ git clone <URL> "$HOME/repo/"
```
> [!NOTE]
> Replace `$HOME/repo/` with your preferred path if different.

### 2. Install the required fonts and set it as your terminal font

To display all the extra glyphs and icons in the shell prompt properly, you need to install a some patched fonts.
The Nerd Fonts are located at: `$HOME/repo/.config/fonts`.

To install the fonts, run:

  ```shell
  # Copy the fonts from the repo to the fonts directory of the OS
  $ cp -av "$HOME/repo/.config/fonts/." "$HOME/.local/share/fonts/"

  # Refresh the font cache for the OS to pick up the newly copied fonts
  $ sudo fc-cache -f
  ```

After the installation is done, configure your preferred terminal to use one of the fonts installed above.

------

### 3. Configure your shell to use the dotfiles

#### 3.1. Set the dotfile directory

Set the `DOTFILE_DIR`  environment variable to point to the location where the dotfiles live.

**For Zsh:** Edit `$HOME/repo/.config/shell/zsh/.zshenv` and set `DOTFILE_DIR` to the following:

```shell
export DOTFILE_DIR="$HOME/repo/.config/shell/zsh"
```

**For Bash:** Edit `$HOME/repo/.config/shell/bash/.bashrc` and set `DOTFILE_DIR` to the following:

```shell
export DOTFILE_DIR="$HOME/repo/.config/shell/bash"
```

#### 3.2. Link your shell to use the custom dotfile directory

Choose **one** of the following methods to point your system shell to your repository.

##### 3.2.1. Option A: Source the File (appends to existing config)

**For Zsh**: Open your terminal and run

```shell
echo 'source "$HOME/repo/.config/shell/zsh/.zshenv"' >> "$HOME/.zshenv"
```

**For Bash**: Open your terminal and run

```shell
echo 'source "$HOME/repo/.config/shell/bash/.bashrc"' >> "$HOME/.bashrc"
```

##### 3.2.2. Option B: Symlink (Recommended)

This replaces the system file with a direct link to your repo file.

```shell
# For Zsh
ln -sf "$HOME/repo/.config/shell/zsh/.zshenv" "$HOME/.zshenv"

# For Bash
ln -sf "$HOME/repo/.config/shell/bash/.bashrc" "$HOME/.bashrc"
```

#### 3.3. Reload the shell to use the new configuration

Run this command to apply the changes immediately without restarting your terminal:

```shell
exec "$(ps -p $$ -ocomm=)"
```
-----

## <u>Prompt Features</u>

- For Bash, the custom prompt is defined in the file `./bash/.bashprompt`
- For ZSH, 2 different prompt themes are available (cascade theme is default, can be changed in `.zshrc`):
  - `./zsh/.zshprompt_theme_cascade`
  - `./zsh/.zshprompt_theme_pure`

The prompts comes with the following features:

| Feature                       | Zsh  | Bash  |
| ----------------------------- | -----| ----- |
| Username                      | ✅   | ✅    |
| Hostname                      | ✅   | ✅    |
| Working directory name        | ✅   | ✅    |
| Read-only directory indicator | ✅   | ✅    |
| Git branch                    | ✅   | ✅    |
| Git submodule detection       | ✅   | ✅    |
| Git stash count               | ✅   | ✅    |
| Python venv indicator         | ✅   | ✅    |
| Exit status color (green/red) | ✅   | ❌    |
| Last command duration         | ✅   | ❌    |

## <u>Keybindings</u>

These are the keybindings that are currently defined across BASH and ZSH

| Keybinding | Action                                                            | Dependency | ZSH  | BASH  |
|------------|-------------------------------------------------------------------|------------|------|-------|
| `Ctrl-R`   | Fuzzy search history and then paste the selected entry            | `fzf`      |  ✅  |  ✅   |
| `Ctrl-T`   | Fuzzy search files & directories and paste the selected entry     | `fzf`, `fd`|  ✅  |  ✅   |
| `Up`/`Down`| Start typing + `Up`/`Down` to fuzzy find history backward/forward |      —     |  ✅  |  ✅   |

## <u>Extra</u>

ZSH is additionally configured to only save valid commands to its history file.
