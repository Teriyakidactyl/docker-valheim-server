#!/bin/bash

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO_ROOT/scripts/container/hooks/pre-startup/30_valheim.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

log() {
    :
}

export WORLD_FILES="$TMP_ROOT/world"
export SERVER_NAME="My Server"
export SERVER_PASS="secret123"
export SERVER_PUBLIC="0"
export WORLD_NAME="Test World"
export SERVER_PORT="2456"
mkdir -p "$WORLD_FILES"

printf 'Steam_manual\n' > "$WORLD_FILES/permittedlist.txt"
unset SERVER_ALLOW_LIST STEAM_ALLOW_LIST_PATH
export STEAM_ID_ALLOW_LIST=""
export STEAM_ID_ALLOW_LIST_PATH=""
source "$HOOK"
grep -Fqx 'Steam_manual' "$WORLD_FILES/permittedlist.txt"
test ! -e "$WORLD_FILES/.docker-valheim-server/permittedlist.path"

export STEAM_ID_ALLOW_LIST=$'Steam_123, Xbox_456\nPSN_789'
source "$HOOK"
for expected in Steam_123 Xbox_456 PSN_789; do
    grep -Fqx "$expected" "$WORLD_FILES/permittedlist.txt"
done
grep -Fqx "$WORLD_FILES/permittedlist.txt" "$WORLD_FILES/.docker-valheim-server/permittedlist.path"

before="$(sha256sum "$WORLD_FILES/permittedlist.txt" | awk '{print $1}')"
source "$HOOK"
after="$(sha256sum "$WORLD_FILES/permittedlist.txt" | awk '{print $1}')"
test "$before" = "$after"

export STEAM_ID_ALLOW_LIST=""
source "$HOOK"
test ! -e "$WORLD_FILES/permittedlist.txt"
test ! -e "$WORLD_FILES/.docker-valheim-server/permittedlist.path"

unset STEAM_ID_ALLOW_LIST
export SERVER_ALLOW_LIST="Steam_legacy1,Steam_legacy2"
source "$HOOK"
grep -Fqx 'Steam_legacy1' "$WORLD_FILES/permittedlist.txt"
grep -Fqx 'Steam_legacy2' "$WORLD_FILES/permittedlist.txt"

unset SERVER_ALLOW_LIST
export STEAM_ID_ALLOW_LIST="Steam_custom"
export STEAM_ID_ALLOW_LIST_PATH=""
export STEAM_ALLOW_LIST_PATH="$WORLD_FILES/custom-permittedlist.txt"
source "$HOOK"
grep -Fqx 'Steam_custom' "$WORLD_FILES/custom-permittedlist.txt"
test ! -e "$WORLD_FILES/permittedlist.txt"
grep -Fqx "$WORLD_FILES/custom-permittedlist.txt" "$WORLD_FILES/.docker-valheim-server/permittedlist.path"

expect_hook_failure() {
    local description="$1"
    shift
    local status

    set +e
    (
        "$@"
        source "$HOOK"
    )
    status=$?
    set -e

    if [ "$status" -eq 0 ]; then
        echo "$description unexpectedly passed validation" >&2
        exit 1
    fi
}

set_public_invalid() { export SERVER_PUBLIC=2; }
set_port_invalid() { export SERVER_PORT=65535; }
set_name_invalid() { export SERVER_NAME=$'bad\nname'; }

expect_hook_failure "SERVER_PUBLIC=2" set_public_invalid
expect_hook_failure "SERVER_PORT=65535" set_port_invalid
expect_hook_failure "multiline SERVER_NAME" set_name_invalid

echo "Valheim hook contract test passed"
