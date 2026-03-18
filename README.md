# claude-statusline

Custom status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Displays model, git branch, diff stats, last commit, context usage, session duration, and cost.

```
[Opus 4.6] my-project:main | +42/-7
[a1b2c3d] Fix widget rendering in dark mode
[████████░░░░░░░░░░░░░░] 36% | 363k / 1.0M | 1h23m | $4.50
```

## Requirements

- [jq](https://jqlang.github.io/jq/) (`brew install jq` on macOS, `sudo apt-get install jq` on Ubuntu)

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/peschee/claude-statusline/main/install.sh | sh
```

Or install a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/peschee/claude-statusline/main/install.sh | sh -s v1.0.0
```

## What it does

1. Downloads `statusline-command.sh` to `~/.claude/`
2. Adds the `statusLine` config to `~/.claude/settings.json`

## Uninstall

```sh
rm ~/.claude/statusline-command.sh
```

Then remove the `"statusLine"` key from `~/.claude/settings.json`:

```sh
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/settings.json && mv /tmp/settings.json ~/.claude/settings.json
```
