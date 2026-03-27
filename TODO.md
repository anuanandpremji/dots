# TODO

## GitHub API rate limiting in setup_apps_cli.sh

The `gh_latest_url()` function fetches the latest release download URL from the GitHub API using unauthenticated `curl` requests. GitHub's unauthenticated rate limit is 60 requests/hour per IP. On a fresh machine setup, multiple calls to `gh_latest_url()` (fzf, fd, bat, eza, delta, etc.) can exhaust the quota and silently return error JSON instead of a download URL, causing silent installation failures.

**Options to consider:**
- Check for a `GITHUB_TOKEN` env var and pass `-H "Authorization: Bearer $GITHUB_TOKEN"` when present (raises limit to 5000/hour)
- Detect when the API response is not a valid download URL and print a clear error instead of attempting to download garbage
- Add a local cache: store the resolved URL per tool name within a single script run to avoid duplicate requests for the same release
