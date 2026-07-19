#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANTS="$ROOT/shaders/variants"
RUNTIME="${XDG_STATE_HOME:-$HOME/.local/state}/ghost-in-the-machine"
SHADER_CONFIG="$RUNTIME/ghostty-state.conf"
SIDEBAR_STATE="$RUNTIME/sidebar.state"
WATCH_PID="$RUNTIME/sidebar-watch.pid"
WATCH_LOG="$RUNTIME/sidebar-watch.log"
WATCH_LOCK="$RUNTIME/sidebar-watch.lock"
WATCHER="${GHOST_SIDEBAR_WATCHER_PATH:-$ROOT/scripts/watch-sidebar.sh}"
STATE_DIR="$RUNTIME/panes"
if [[ -n "${HERDR_BIN_PATH:-}" ]]; then
    HERDR_BIN="$HERDR_BIN_PATH"
elif command -v herdr >/dev/null 2>&1; then
    HERDR_BIN="$(command -v herdr)"
elif [[ -x "$HOME/.local/bin/herdr" ]]; then
    HERDR_BIN="$HOME/.local/bin/herdr"
else
    HERDR_BIN=herdr
fi

mkdir -p "$RUNTIME" "$STATE_DIR"

usage() {
    echo "usage: ghost-state {set STATE|clear|focus|apply STATE|sidebar collapsed|sidebar expanded|watch-start|watch-stop|status|config-path}" >&2
    echo "states: off idle thinking working done error" >&2
    exit 2
}

valid_state() {
    case "$1" in
        off|idle|thinking|working|done|error) return 0 ;;
        *) return 1 ;;
    esac
}

session_key() {
    printf '%s' "${HERDR_SOCKET_PATH:-direct}" | cksum | awk '{print $1}'
}

pane_state_file() {
    local pane_id="$1" safe
    safe="$(printf '%s' "$pane_id" | tr -c 'A-Za-z0-9._-' '_')"
    printf '%s/%s-%s.state\n' "$STATE_DIR" "$(session_key)" "$safe"
}

current_pane() {
    "$HERDR_BIN" pane current 2>/dev/null
}

reload_ghostty() {
    local pid
    [[ "${GHOSTTY_RELOAD_ENABLED:-1}" == "1" ]] || return 0
    while read -r pid; do
        [[ -n "$pid" ]] && kill -USR2 "$pid" 2>/dev/null || true
    done < <(pgrep -x ghostty 2>/dev/null || true)
}

sidebar_state() {
    cat "$SIDEBAR_STATE" 2>/dev/null || printf 'expanded\n'
}

apply_state() {
    local requested="$1" state source config_tmp state_tmp current
    valid_state "$requested" || usage
    state="$requested"
    if [[ "$state" != "off" && "$(sidebar_state)" == "collapsed" ]]; then
        state=off
    fi
    source="$VARIANTS/$state.glsl"
    if [[ "$state" != "off" && ! -f "$source" ]]; then
        echo "missing bundled shader: $source" >&2
        exit 1
    fi

    config_tmp="$RUNTIME/.ghostty-state.conf.$$"
    if [[ "$state" == "off" ]]; then
        printf '# ghost-in-the-machine: off\n' > "$config_tmp"
    else
        printf 'custom-shader = %s\n' "$source" > "$config_tmp"
    fi

    current="$(cat "$RUNTIME/active.state" 2>/dev/null || true)"
    if [[ "$current" == "$state" && -f "$SHADER_CONFIG" ]] && cmp -s "$config_tmp" "$SHADER_CONFIG"; then
        rm -f "$config_tmp"
        return
    fi

    mv "$config_tmp" "$SHADER_CONFIG"
    state_tmp="$RUNTIME/.active.state.$$"
    printf '%s\n' "$state" > "$state_tmp"
    mv "$state_tmp" "$RUNTIME/active.state"
    reload_ghostty

    # A collapse can race this write. Reconcile after the write so an older Pi
    # lifecycle command cannot leave the ghost visible over a collapsed sidebar.
    if [[ "$requested" != "off" && "$state" != "off" && "$(sidebar_state)" == "collapsed" ]]; then
        apply_state off
    fi
}

focused_state() {
    local pane_json pane_id agent saved
    pane_json="$(current_pane)" || {
        apply_state off
        return
    }
    pane_id="$(jq -r '.result.pane.pane_id // empty' <<<"$pane_json")"
    agent="$(jq -r '.result.pane.agent // empty' <<<"$pane_json")"
    if [[ "$agent" != "pi" || -z "$pane_id" ]]; then
        apply_state off
        return
    fi

    saved="$(cat "$(pane_state_file "$pane_id")" 2>/dev/null || true)"
    valid_state "$saved" || saved=off
    apply_state "$saved"
}

set_state() {
    local state="$1" pane_id="${HERDR_PANE_ID:-}" pane_json focused_id
    valid_state "$state" || usage

    if [[ "${HERDR_ENV:-}" != "1" || -z "$pane_id" ]]; then
        apply_state "$state"
        return
    fi

    printf '%s\n' "$state" > "$(pane_state_file "$pane_id")"
    pane_json="$(current_pane)" || return
    focused_id="$(jq -r '.result.pane.pane_id // empty' <<<"$pane_json")"
    if [[ "$focused_id" == "$pane_id" ]]; then
        apply_state "$state"
        pane_json="$(current_pane)" || return
        focused_id="$(jq -r '.result.pane.pane_id // empty' <<<"$pane_json")"
        [[ "$focused_id" == "$pane_id" ]] || focused_state
    fi
}

watcher_running() {
    local pid command
    pid="$(cat "$WATCH_PID" 2>/dev/null || true)"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [[ "$command" == *"$(basename "$WATCHER")"* ]]
}

start_watcher() {
    local pid tmp
    watcher_running && return

    if ! mkdir "$WATCH_LOCK" 2>/dev/null; then
        sleep 0.2
        watcher_running && return
        rmdir "$WATCH_LOCK" 2>/dev/null || true
        mkdir "$WATCH_LOCK" 2>/dev/null || return
    fi

    if watcher_running; then
        rmdir "$WATCH_LOCK" 2>/dev/null || true
        return
    fi

    rm -f "$WATCH_PID"
    HERDR_BIN_PATH="$HERDR_BIN" SIDEBAR_POLL_INTERVAL="${SIDEBAR_POLL_INTERVAL:-0.05}" \
        nohup bash "$WATCHER" "$WATCH_LOG" </dev/null >/dev/null 2>&1 &
    pid=$!
    tmp="$RUNTIME/.sidebar-watch.pid.$$"
    printf '%s\n' "$pid" > "$tmp"
    mv "$tmp" "$WATCH_PID"
    rmdir "$WATCH_LOCK" 2>/dev/null || true
}

stop_watcher() {
    local pid
    pid="$(cat "$WATCH_PID" 2>/dev/null || true)"
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
    fi
    rm -f "$WATCH_PID"
}

set_sidebar_state() {
    local state="$1" tmp
    case "$state" in
        collapsed|expanded) ;;
        *) usage ;;
    esac

    tmp="$RUNTIME/.sidebar.state.$$"
    printf '%s\n' "$state" > "$tmp"
    mv "$tmp" "$SIDEBAR_STATE"

    if [[ "$state" == "collapsed" ]]; then
        apply_state off
    else
        focused_state
    fi
}

clear_state() {
    local pane_id="${HERDR_PANE_ID:-}" pane_json focused_id
    if [[ -z "$pane_id" ]]; then
        apply_state off
        return
    fi

    rm -f "$(pane_state_file "$pane_id")"
    pane_json="$(current_pane)" || return
    focused_id="$(jq -r '.result.pane.pane_id // empty' <<<"$pane_json")"
    if [[ "$focused_id" == "$pane_id" ]]; then
        apply_state off
        pane_json="$(current_pane)" || return
        focused_id="$(jq -r '.result.pane.pane_id // empty' <<<"$pane_json")"
        [[ "$focused_id" == "$pane_id" ]] || focused_state
    fi
}

case "${1:-}" in
    set)
        [[ $# -eq 2 ]] || usage
        set_state "$2"
        ;;
    clear)
        [[ $# -eq 1 ]] || usage
        clear_state
        ;;
    focus)
        [[ $# -eq 1 ]] || usage
        focused_state
        ;;
    apply)
        [[ $# -eq 2 ]] || usage
        apply_state "$2"
        ;;
    sidebar)
        [[ $# -eq 2 ]] || usage
        set_sidebar_state "$2"
        ;;
    watch-start)
        [[ $# -eq 1 ]] || usage
        start_watcher
        ;;
    watch-stop)
        [[ $# -eq 1 ]] || usage
        stop_watcher
        ;;
    status)
        [[ $# -eq 1 ]] || usage
        if watcher_running; then watcher=running; else watcher=stopped; fi
        printf 'active=%s sidebar=%s watcher=%s\n' \
            "$(cat "$RUNTIME/active.state" 2>/dev/null || echo unknown)" \
            "$(sidebar_state)" \
            "$watcher"
        ;;
    config-path)
        [[ $# -eq 1 ]] || usage
        printf '%s\n' "$SHADER_CONFIG"
        ;;
    *) usage ;;
esac
