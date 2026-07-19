#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${1:-${TMPDIR:-/tmp}/ghost-sidebar-watch.log}"
INTERVAL="${SIDEBAR_POLL_INTERVAL:-0.05}"
CONTROLLER="${GHOST_CONTROLLER_PATH:-$ROOT/scripts/ghost-state.sh}"

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
last_state=""
failures=0
log "watcher=start herdr=$HERDR_BIN controller=$CONTROLLER interval=$INTERVAL"
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
            failures=0
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
            if [[ "$state" != "$last_state" ]]; then
                if HERDR_BIN_PATH="$HERDR_BIN" bash "$CONTROLLER" sidebar "$state"; then
                    log "action=ghost-$state result=ok"
                else
                    log "action=ghost-$state result=error"
                fi
                last_state="$state"
            fi
        else
            ((failures += 1))
            if [[ "$last" != "unavailable" ]]; then
                log "state=unavailable reason=missing-layout"
                last="unavailable"
                last_state=""
            fi
        fi
    else
        ((failures += 1))
        if [[ "$last" != "unavailable" ]]; then
            log "state=unavailable reason=query-failed"
            last="unavailable"
            last_state=""
        fi
    fi
    if (( failures >= 100 )); then
        log "watcher=stop reason=herdr-unavailable"
        exit 0
    fi
    sleep "$INTERVAL"
done
