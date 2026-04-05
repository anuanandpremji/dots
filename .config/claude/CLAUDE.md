# Global Rules

## Git Commits
- NEVER add "Co-Authored-By" or "Co-authored-by" trailers to commit messages.
- NEVER add "Generated with Claude Code" or similar attribution lines to commit messages.

## Git Push — Mandatory Pre-Push Summary
- ALWAYS show a summary table before every `git push`, without exception.
- The summary MUST include: remote name, remote URL, SSH key (resolved via `ssh -G <host> | grep identityfile`), git user name, git user email, and the list of commits being pushed.
- Wait for explicit user confirmation before executing the push.

## Code Formatting
- Do NOT aggressively wrap lines to 79 or 80 characters. Prioritize readability over line length.
- Do NOT enforce a strict line length limit. Use good judgment — keep lines readable, but don't break expressions into awkward multi-line pieces just to stay under a number.
- If a line reads naturally on one line, keep it on one line even if it's 100-130+ characters.
- Only break lines when the result is genuinely more readable than the single-line version.

## Keybindings
- When suggesting or configuring keybindings, always prefer keys that are easy to type on different keyboard layouts (e.g. German, French, etc.).
- Avoid keys that require Shift or a multi-step combination just to produce the character (e.g. `/` on a German keyboard requires Shift+7).
- Prefer plain ctrl+letter combinations (ctrl-t, ctrl-f, etc.) or unmodified letter keys where possible.

## Markdown Files (README.md, *.md)
- Do NOT break sentences or paragraphs to adhere to line length limits. Write prose as single continuous lines per sentence or paragraph.
- Text editors and markdown viewers use soft wrap — hard line breaks inside sentences are unnecessary and make diffs noisier.
- Use ```sh for shell code blocks, NOT ```shell. Most Markdown renderers recognise `sh` but not `shell`.
