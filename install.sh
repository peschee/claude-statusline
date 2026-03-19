#!/bin/sh
set -eu

REPO="peschee/claude-statusline"
CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
SCRIPT_NAME="statusline-command.sh"
SCRIPT_PATH="${CLAUDE_DIR}/${SCRIPT_NAME}"

# --- Require jq ---
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    echo "" >&2
    echo "Install jq:" >&2
    echo "  macOS:  brew install jq" >&2
    echo "  Ubuntu: sudo apt-get install jq" >&2
    echo "  Fedora: sudo dnf install jq" >&2
    echo "  Arch:   sudo pacman -S jq" >&2
    exit 1
fi

# --- Determine version ---
if [ -n "${1:-}" ]; then
    VERSION="$1"
else
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
    if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
        echo "Failed to determine latest version" >&2
        exit 1
    fi
fi

URL="https://raw.githubusercontent.com/${REPO}/${VERSION}/${SCRIPT_NAME}"

echo "Installing claude-statusline ${VERSION}..."

# --- Download statusline script ---
mkdir -p "$CLAUDE_DIR"
curl -fsSL -o "$SCRIPT_PATH" "$URL"
chmod +x "$SCRIPT_PATH"

# --- Patch settings.json ---
STATUSLINE_CONFIG="{\"type\":\"command\",\"command\":\"bash ${CLAUDE_DIR}/${SCRIPT_NAME}\"}"

if [ -f "$SETTINGS_FILE" ]; then
    # Update existing settings
    tmp=$(mktemp)
    jq --argjson sl "$STATUSLINE_CONFIG" '.statusLine = $sl' "$SETTINGS_FILE" > "$tmp"
    mv "$tmp" "$SETTINGS_FILE"
else
    # Create new settings file
    echo "$STATUSLINE_CONFIG" | jq '{statusLine: .}' > "$SETTINGS_FILE"
fi

echo "Installed ${SCRIPT_NAME} to ${SCRIPT_PATH}"
echo "Updated ${SETTINGS_FILE} with statusLine config"
echo ""
echo "Restart Claude Code to see the new status line."
