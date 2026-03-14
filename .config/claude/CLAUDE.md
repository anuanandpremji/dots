# Global Rules

## Git Commits
- NEVER add "Co-Authored-By" or "Co-authored-by" trailers to commit messages.
- NEVER add "Generated with Claude Code" or similar attribution lines to commit messages.

## Code Formatting
- Do NOT aggressively wrap lines to 79 or 80 characters. Prioritize readability over line length.
- Do NOT enforce a strict line length limit. Use good judgment — keep lines readable, but don't break expressions into awkward multi-line pieces just to stay under a number.
- If a line reads naturally on one line, keep it on one line even if it's 100-130+ characters.
- Only break lines when the result is genuinely more readable than the single-line version.

## Markdown Files (README.md, *.md)
- Do NOT break sentences or paragraphs to adhere to line length limits. Write prose as single continuous lines per sentence or paragraph.
- Text editors and markdown viewers use soft wrap — hard line breaks inside sentences are unnecessary and make diffs noisier.
