#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-${TMPDIR:-/tmp}/ghost-sidebar-watch.log}"
INTERVAL="${SIDEBAR_POLL_INTERVAL:-0.05}"

if [[ -n "${HERDR_BIN_PATH:-}" ]]; then
    HERDR_BIN="$HERDR_BIN_PATH"
elif command -v herdr >/dev/null 2>&1; then
    HERDR_BIN="$(command -v herdr)"
elif [[ -x "$HOME/.local/bin/herdr" ]]; then
    HERDR_BIN="$HOME/.local/bin/herdr"
else
    echo "herdr not found; set HERDR_BIN_PATH" >&2
    exit 127
fi

command -v jq >/dev/null 2>&1 || {
    echo "jq is required" >&2
    exit 127
}

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
    printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"
}

last=""
log "watcher=start herdr=$HERDR_BIN interval=$INTERVAL"
stop() {
    log "watcher=stop"
    exit 0
}
trap stop INT TERM

while true; do
    if layout="$("$HERDR_BIN" pane layout --current 2>/dev/null)"; then
        x="$(jq -r '.result.layout.area.x // empty' <<<"$layout")"
        width="$(jq -r '.result.layout.area.width // empty' <<<"$layout")"
        if [[ "$x" =~ ^[0-9]+$ ]]; then
            if (( x <= 4 )); then
                state="collapsed"
            else
                state="expanded"
            fi
            current="$state:$x:$width"
            if [[ "$current" != "$last" ]]; then
                log "state=$state area_x=$x area_width=$width"
                last="$current"
            fi
        elif [[ "$last" != "unavailable" ]]; then
            log "state=unavailable reason=missing-layout"
            last="unavailable"
        fi
    elif [[ "$last" != "unavailable" ]]; then
        log "state=unavailable reason=query-failed"
        last="unavailable"
    fi
    sleep "$INTERVAL"
done
