#!/bin/sh

#╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ CTRL-R - Fuzzy search history with multi-select, editing, and deletion                                              ║
#║ Shared by Bash and Zsh. Shell-specific differences are guarded with $ZSH_VERSION / $BASH_VERSION.                   ║
#║                                                                                                                     ║
#║ Requires: fzf >= 0.56 (--style=full, --ghost). Install via setup_apps_cli.sh, not the system package manager.       ║
#╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

if ! command -v fzf >/dev/null 2>&1; then printf "fzf not found.\n"; return; fi

# Runs in a loop: after every edit/delete, history reloads and fzf reopens with the same query.
#
# ?        - toggle a preview window for truncated entries
# TAB      - multi-select entries (works with Enter, Ctrl-E, and Ctrl-X)
# ENTER    - paste selected entries onto the command line (newline-separated if multi)
# CTRL-E   - open selected entries in $VISUAL; on save, original lines are removed
#            from $HISTFILE and edited content is appended
# CTRL-O   - open the raw $HISTFILE in $VISUAL for free-form editing
# CTRL-X   - delete selected entries from $HISTFILE

fzf_history_widget()
{
    local output query key hs
    local -a lines selected

    # Initial query: use whatever is already typed on the command line
    local fzf_query
    if   [ -n "$ZSH_VERSION"  ]; then fzf_query="$LBUFFER"
    elif [ -n "$BASH_VERSION" ]; then fzf_query="$READLINE_LINE"
    fi

    local -a fzf_opts=(
        --multi
        --print-query --expect=ctrl-o,ctrl-e,ctrl-x
        --highlight-line
        --style=full
        --preview 'echo {}'
        --preview-window down:3:hidden:wrap-word
        --preview-label=' Full Command '
        --preview-label-pos=2
        --ghost 'Search your shell command history...'
        --header-border=line
        --footer " ↵ Paste │ TAB Multi-select │ ^E Edit │ ^O Open History │ ^X Delete │ ? Preview"
        --footer-border=line
        --color 'label:yellow:bold,header:dim'
        --prompt '▶ '
        --bind '?:toggle-preview'
    );

    while true; do
        # Note (bash): no `history -a` here. The PROMPT_COMMAND handler in .bashrc already writes each
        # successful command to $HISTFILE immediately, so the file is always up to date.
        # Calling `history -a` would flush the entire in-memory list — including failed commands — to
        # the file, bypassing the "only save successful commands" filter.

        # Reverse the history file so newest entries appear first.
        # tac is Linux-only; tail -r is the macOS equivalent.
        output=$({ tac "$HISTFILE" 2>/dev/null || tail -r "$HISTFILE"; } | awk '!seen[$0]++' |
                  fzf "${fzf_opts[@]}" -q "$fzf_query") || break

        if [ -n "$ZSH_VERSION" ]; then
            lines=("${(@f)output}")
            query=${lines[1]}
            key=${lines[2]}
            selected=("${(@)lines[3,-1]}")
        elif [ -n "$BASH_VERSION" ]; then
            mapfile -t lines <<< "$output"
            query="${lines[0]}"
            key="${lines[1]}"
            selected=("${lines[@]:2}")
        fi

        # Helper: is there at least one non-empty selection?
        local _have_selection
        if   [ -n "$ZSH_VERSION"  ]; then _have_selection=$( [[ ${#selected} -gt 0 && -n "${selected[1]}" ]] && echo yes )
        elif [ -n "$BASH_VERSION" ]; then _have_selection=$( [[ ${#selected[@]} -gt 0 && -n "${selected[0]}" ]] && echo yes )
        fi

        # Helper: flush in-memory history and re-read $HISTFILE
        _reload_history() {
            if   [ -n "$ZSH_VERSION"  ]; then hs=$HISTSIZE; HISTSIZE=0; HISTSIZE=$hs; fc -R "$HISTFILE"
            elif [ -n "$BASH_VERSION" ]; then history -c; history -r
            fi
        }

        # ── Ctrl-O: open raw history file ────────────────────────────────
        if [[ "$key" == "ctrl-o" ]]; then
            fzf_query="$query"
            "$VISUAL" "$HISTFILE"
            _reload_history
            continue
        fi

        # ── Ctrl-E: edit selected entries, replace in history ────────────
        # Flow: write selections to two temp files (one to edit, one to
        # remember originals) → open editor → remove originals from
        # HISTFILE → append edits
        if [[ "$key" == "ctrl-e" && -n "$_have_selection" ]]; then
            fzf_query="$query"
            local tmpfile="${TMPDIR:-/tmp}/shell_hist_edit.$$"
            local tmpremove="${TMPDIR:-/tmp}/shell_hist_remove.$$"

            printf '%s\n' "${selected[@]}" > "$tmpremove"
            cp "$tmpremove" "$tmpfile"
            "$VISUAL" "$tmpfile"

            # Remove original lines (fixed-string, whole-line match)
            grep -Fxvf "$tmpremove" "$HISTFILE" > "$HISTFILE.tmp" \
                && mv "$HISTFILE.tmp" "$HISTFILE"
            [[ -s "$tmpfile" ]] && cat "$tmpfile" >> "$HISTFILE"

            rm -f "$tmpfile" "$tmpremove"
            _reload_history
            continue
        fi

        # ── Ctrl-X: delete selected entries ──────────────────────────────
        if [[ "$key" == "ctrl-x" && -n "$_have_selection" ]]; then
            fzf_query="$query"
            local tmpremove="${TMPDIR:-/tmp}/shell_hist_remove.$$"
            printf '%s\n' "${selected[@]}" > "$tmpremove"
            grep -Fxvf "$tmpremove" "$HISTFILE" > "$HISTFILE.tmp" \
                && mv "$HISTFILE.tmp" "$HISTFILE"
            rm -f "$tmpremove"
            _reload_history
            continue
        fi

        # ── Enter: paste onto command line ───────────────────────────────
        if [ -n "$_have_selection" ]; then
            if [ -n "$ZSH_VERSION" ]; then
                LBUFFER=${(F)selected}  # (F) joins array elements with newlines
            elif [ -n "$BASH_VERSION" ]; then
                local IFS=$'\n'
                READLINE_LINE="${selected[*]}"  # join with newlines for multi-select
                READLINE_POINT=${#READLINE_LINE}
            fi
        fi
        break
    done

    [ -n "$ZSH_VERSION" ] && zle redisplay
}

# Bind CTRL-R to fzf_history_widget()
if   [ -n "$ZSH_VERSION"  ]; then
    zle      -N  fzf_history_widget
    bindkey '^R' fzf_history_widget
elif [ -n "$BASH_VERSION" ]; then
    bind -m emacs-standard -x '"\C-r": fzf_history_widget'
fi

# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════ #
