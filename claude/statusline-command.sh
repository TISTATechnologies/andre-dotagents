#!/bin/sh
# Claude Code status line: current dir, git branch, model and thinking
# effort, context %, and rate limit % used. Colors are chosen to read well
# when the terminal dims the status line.
#
# NOTE TO AGENTS: this file is user-managed configuration. Do not edit it
# unless the user has explicitly directed you to change the status line.

RESET=$(printf '\033[0m')
DIM=$(printf '\033[2m')
BLUE=$(printf '\033[1;34m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
RED=$(printf '\033[31m')
MAGENTA=$(printf '\033[35m')
CYAN=$(printf '\033[36m')

# Pick a color for a percentage: green < 70, yellow < 90, red otherwise.
pct_color() {
  awk -v p="$1" 'BEGIN {
    if (p < 70) print "'"$GREEN"'";
    else if (p < 90) print "'"$YELLOW"'";
    else print "'"$RED"'";
  }'
}

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
dirname=$(basename "$cwd")

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
# .effort is present only for models that support reasoning effort; when
# thinking is off the level is irrelevant, so say so instead.
if [ "$(printf '%s' "$input" | jq -r '.thinking.enabled')" = "false" ]; then
  effort="off"
else
  effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
fi

ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
five=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

out="${DIM}[${RESET}${BLUE}${dirname}${RESET}${DIM}]${RESET}"
[ -n "$branch" ] && out="$out ${DIM}(${RESET}${GREEN}${branch}${RESET}${DIM})${RESET}"
if [ -n "$model" ]; then
  out="$out ${DIM}{${RESET}${MAGENTA}${model}${RESET}"
  [ -n "$effort" ] && out="$out ${DIM}· ${RESET}${CYAN}${effort}${RESET}"
  out="$out${DIM}}${RESET}"
fi
if [ -n "$ctx" ]; then
  c=$(pct_color "$ctx")
  out="$out ${DIM}|${RESET} ctx ${c}$(printf '%.0f' "$ctx")%${RESET}"
fi
if [ -n "$five" ]; then
  c=$(pct_color "$five")
  out="$out ${DIM}|${RESET} 5h ${c}$(printf '%.0f' "$five")%${RESET}"
fi
if [ -n "$week" ]; then
  c=$(pct_color "$week")
  out="$out ${DIM}|${RESET} 7d ${c}$(printf '%.0f' "$week")%${RESET}"
fi

printf '%s' "$out"
