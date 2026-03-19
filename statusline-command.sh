#!/usr/bin/env bash
set -Eeuo pipefail
# Claude Code status line script
# Layout:
#   Line 1: [model] project:branch +adds/-dels
#   Line 2: [hash] commit message
#   Line 3: [context bar] pct% | free | duration | cost

input=$(cat)

# --- JSON fields ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
input_tokens=$(echo "$input" | jq -r '
  (.context_window.used_percentage // 0) as $pct |
  (.context_window.context_window_size // 0) as $size |
  if $pct > 0 and $size > 0 then (($pct / 100) * $size | floor | tostring)
  else "0"
  end
')

# --- Colors ---
GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')
WHITE=$(printf '\033[97m')
CYAN=$(printf '\033[36m')
RESET=$(printf '\033[0m')

# --- Asylum environment indicator ---
asylum_indicator=""
if [ "${ASYLUM_DOCKER:-}" = "1" ]; then
    asylum_indicator="${CYAN}🛡${RESET} "
fi

# --- Line 1: model, project:branch, git diff stats ---
project=$(basename "$cwd")
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)

line1="${asylum_indicator}${GREEN}[${model}]${RESET}"

if [ -n "$branch" ]; then
    line1="${line1} ${YELLOW}${project}:${branch}${RESET}"

    # Git diff stats: total added/removed lines vs upstream or HEAD~1
    diff_stat=$(git -C "$cwd" --no-optional-locks diff --shortstat HEAD 2>/dev/null || true)
    if [ -z "$diff_stat" ]; then
        # Nothing in working tree — compare last commit vs its parent
        diff_stat=$(git -C "$cwd" --no-optional-locks diff --shortstat HEAD~1 HEAD 2>/dev/null || true)
    fi

    if [ -n "$diff_stat" ]; then
        adds=$(echo "$diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || true)
        dels=$(echo "$diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || true)
        [ -z "$adds" ] && adds=0
        [ -z "$dels" ] && dels=0
        line1="${line1} ${WHITE}|${RESET} ${GREEN}+${adds}${RESET}/${RED}-${dels}${RESET}"
    fi
fi

# --- Line 2: last commit hash + message ---
commit_hash=$(git -C "$cwd" --no-optional-locks log -1 --format='%h' 2>/dev/null || true)
commit_msg=$(git -C "$cwd" --no-optional-locks log -1 --format='%s' 2>/dev/null || true)

line2=""
if [ -n "$commit_hash" ]; then
    # Truncate commit message to 50 chars
    if [ ${#commit_msg} -gt 50 ]; then
        commit_msg="${commit_msg:0:50}"
    fi
    line2="${YELLOW}[${commit_hash}]${RESET} ${WHITE}${commit_msg}${RESET}"
fi

# --- Line 3: context bar + stats ---
line3=""

if [ -n "$used_pct" ]; then
    # Build 22-char progress bar
    bar_width=22
    filled=$(echo "$used_pct $bar_width" | awk '{printf "%d", ($1/100)*$2}')
    bar=""
    i=0
    while [ $i -lt "$filled" ]; do bar="${bar}█"; i=$((i+1)); done
    while [ $i -lt "$bar_width" ]; do bar="${bar}░"; i=$((i+1)); done

    used_pct_int=$(printf '%.0f' "$used_pct")
    line3="[${bar}] ${used_pct_int}%"

    # Used / total context tokens (e.g. "150k / 200k" or "150k / 1M")
    if [ -n "$ctx_size" ] && [ -n "$input_tokens" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
        used_k=$(echo "$input_tokens" | awk '{
            if ($1 >= 1000000) printf "%.1fM", $1/1000000
            else if ($1 >= 1000) printf "%dk", $1/1000
            else printf "%d", $1
        }')
        total_k=$(echo "$ctx_size" | awk '{
            if ($1 >= 1000000) printf "%.1fM", $1/1000000
            else printf "%dk", $1/1000
        }')
        line3="${line3} ${WHITE}|${RESET} ${GREEN}${used_k} / ${total_k}${RESET}"
    fi
fi

# --- Session duration from cost.total_duration_ms ---
total_duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
if [ -n "$total_duration_ms" ]; then
    elapsed_s=$(( total_duration_ms / 1000 ))
    hrs=$(( elapsed_s / 3600 ))
    mins=$(( (elapsed_s % 3600) / 60 ))
    duration="${hrs}h${mins}m"
    line3="${line3} ${WHITE}|${RESET} ${duration}"
fi

# --- Cost from cost.total_cost_usd ---
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$total_cost" ] && [ "$total_cost" != "0" ]; then
    formatted_cost=$(printf '%.2f' "$total_cost")
    line3="${line3} ${WHITE}|${RESET} ${GREEN}\$${formatted_cost}${RESET}"
fi

# --- Output (blank lines between content lines for spacing) ---
printf '%s\n' "$line1"
[ -n "$line2" ] && printf '%s\n' "$line2"
[ -n "$line3" ] && printf '%s\n' "$line3"
