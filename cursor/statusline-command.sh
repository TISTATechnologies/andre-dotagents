#!/bin/sh
# Cursor CLI status line: current dir, git branch, model and effort
# summary, context % with a bar, and Cursor models / API % used.
# Colors are chosen to read well when the terminal dims the status line.
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

# 10-character bar for a percentage: filled blocks, then empty.
pct_bar() {
  awk -v p="$1" 'BEGIN {
    w = 10
    if (p < 0) p = 0
    if (p > 100) p = 100
    n = int(p * w / 100 + 0.5)
    if (n > w) n = w
    bar = ""
    for (i = 0; i < n; i++) bar = bar "━"
    for (i = n; i < w; i++) bar = bar "╌"
    printf "%s", bar
  }'
}

# Cursor models (auto) and API plan usage. Cached so the 2s status-line
# timeout is not spent on the dashboard call every redraw.
cursor_plan_usage() {
  python3 - <<'PY'
import json
import os
import time
import urllib.request
from pathlib import Path

ttl_s = 120
cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "cursor-statusline-usage.json"
auth_path = Path.home() / ".config/cursor/auth.json"


def load_cache():
    try:
        return json.loads(cache.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def emit(data):
    models = data.get("models")
    api = data.get("api")
    if models is None and api is None:
        return
    print(json.dumps({"models": models, "api": api}, separators=(",", ":")))


cached = load_cache()
age = time.time() - cache.stat().st_mtime if cache.exists() else 1e9
if cached is not None and age < ttl_s:
    emit(cached)
    raise SystemExit(0)

result = cached
try:
    token = json.loads(auth_path.read_text(encoding="utf-8"))["accessToken"]
    req = urllib.request.Request(
        "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage",
        data=b"{}",
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
            "Authorization": "Bearer " + token,
        },
    )
    with urllib.request.urlopen(req, timeout=1.2) as resp:
        body = json.loads(resp.read().decode())
    plan = body.get("planUsage") or {}
    result = {"models": plan.get("autoPercentUsed"), "api": plan.get("apiPercentUsed")}
    cache.parent.mkdir(parents=True, exist_ok=True)
    tmp = cache.with_name(cache.name + ".tmp")
    tmp.write_text(json.dumps(result), encoding="utf-8")
    tmp.replace(cache)
except Exception:
    pass

if result:
    emit(result)
PY
}

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
dirname=$(basename "$cwd")

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
# Cursor sends a formatted param summary instead of Claude's effort
# object; max mode is a separate flag with no Claude equivalent.
effort=$(printf '%s' "$input" | jq -r '.model.param_summary // empty')
effort=${effort#(}
effort=${effort%)}
if [ -z "$effort" ] && [ "$(printf '%s' "$input" | jq -r '.model.max_mode // false')" = "true" ]; then
  effort="max"
fi

ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
usage=$(cursor_plan_usage)
models=$(printf '%s' "$usage" | jq -r '.models // empty')
api=$(printf '%s' "$usage" | jq -r '.api // empty')

out="${DIM}[${RESET}${BLUE}${dirname}${RESET}${DIM}]${RESET}"
[ -n "$branch" ] && out="$out ${DIM}(${RESET}${GREEN}${branch}${RESET}${DIM})${RESET}"
if [ -n "$model" ]; then
  out="$out ${DIM}{${RESET}${MAGENTA}${model}${RESET}"
  [ -n "$effort" ] && out="$out ${DIM}· ${RESET}${CYAN}${effort}${RESET}"
  out="$out${DIM}}${RESET}"
fi
if [ -n "$ctx" ]; then
  c=$(pct_color "$ctx")
  out="$out ${DIM}|${RESET} ctx ${c}$(pct_bar "$ctx") $(printf '%.0f' "$ctx")%${RESET}"
fi
if [ -n "$models" ]; then
  c=$(pct_color "$models")
  out="$out ${DIM}|${RESET} models ${c}$(printf '%.0f' "$models")% used${RESET}"
fi
if [ -n "$api" ]; then
  c=$(pct_color "$api")
  out="$out ${DIM}|${RESET} api ${c}$(printf '%.0f' "$api")% used${RESET}"
fi

printf '%s' "$out"
