#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANTS="$ROOT/shaders/variants"
RUNTIME="${XDG_STATE_HOME:-$HOME/.local/state}/ghost-in-the-machine"
SHADER_CONFIG="$RUNTIME/ghostty-state.conf"
STATE_DIR="$RUNTIME/panes"
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"

mkdir -p "$RUNTIME" "$STATE_DIR"

usage() {
    echo "usage: ghost-state {set STATE|clear|focus|apply STATE|status|config-path}" >&2
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
    while read -r pid; do
        [[ -n "$pid" ]] && kill -USR2 "$pid" 2>/dev/null || true
    done < <(pgrep -x ghostty 2>/dev/null || true)
}

apply_state() {
    local state="$1" source config_tmp state_tmp current
    valid_state "$state" || usage
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
    status)
        [[ $# -eq 1 ]] || usage
        printf 'active=%s\n' "$(cat "$RUNTIME/active.state" 2>/dev/null || echo unknown)"
        ;;
    config-path)
        [[ $# -eq 1 ]] || usage
        printf '%s\n' "$SHADER_CONFIG"
        ;;
    *) usage ;;
esac
