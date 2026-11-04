#!/usr/bin/env bash
set -euo pipefail

CSTCG_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CSTCG_CHECK_RUNTIME="$(mktemp -d "${TMPDIR:-/tmp}/cstcg-check.XXXXXX")"
trap 'rm -rf -- "$CSTCG_CHECK_RUNTIME"' EXIT
export XDG_CACHE_HOME="$CSTCG_CHECK_RUNTIME/cache"
export XDG_CONFIG_HOME="$CSTCG_CHECK_RUNTIME/config"
export XDG_DATA_HOME="$CSTCG_CHECK_RUNTIME/data"
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

run_check() {
    local expected_marker="$1"
    shift
    local check_log="$CSTCG_CHECK_RUNTIME/check.log"
    local marker_found=false
    if [[ -z "$expected_marker" ]]; then marker_found=true; fi
    godot --headless --path "$CSTCG_ROOT" "$@" 2>&1 | tee "$check_log"
    while IFS= read -r output_line; do
        if [[ "$output_line" == ERROR:* || "$output_line" == 'SCRIPT ERROR:'* ]]; then
            printf '%s\n' 'Godot reported an error; check failed.' >&2
            return 1
        fi
        if [[ -n "$expected_marker" && "$output_line" == *"$expected_marker"* ]]; then
            marker_found=true
        fi
    done < "$check_log"
    if [[ "$marker_found" != true ]]; then
        printf 'Check did not finish: missing %s\n' "$expected_marker" >&2
        return 1
    fi
}

run_check "" --editor --import
run_check "CSTCG_TESTS:" --script res://tests/test_game.gd -- --ephemeral
run_check "CSTCG_UI_SMOKE:" --quit-after 900 -- --ephemeral --ui-smoke
run_check "CSTCG_SPATIAL_TESTS:" --script res://tests/test_spatial.gd -- --ephemeral
run_check "CSTCG_SPATIAL_UI:" --quit-after 900 -- --ephemeral --spatial-smoke
run_check "CSTCG_LIVE_TESTS:" --script res://tests/test_live_match.gd -- --ephemeral
run_check "CSTCG_LIVE_UI:" --quit-after 900 -- --ephemeral --live-match-smoke
