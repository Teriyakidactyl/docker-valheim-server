#!/bin/bash

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS_FILE="$REPO_ROOT/scripts/container/valheim.args"

export SERVER_NAME='My Server $5'
export SERVER_PORT='2456'
export SERVER_PUBLIC='0'
export WORLD_NAME='World With Spaces'
export SERVER_PASS='pass word $HOME !'
export WORLD_FILES='/world'

mapfile -t args < <(envsubst < "$ARGS_FILE")

expected=(
    -nographics
    -batchmode
    -name
    'My Server $5'
    -port
    2456
    -public
    0
    -world
    'World With Spaces'
    -password
    'pass word $HOME !'
    -savedir
    /world
    -saveinterval
    1800
)

if [ "${#args[@]}" -ne "${#expected[@]}" ]; then
    printf 'expected %d arguments, got %d\n' "${#expected[@]}" "${#args[@]}" >&2
    exit 1
fi

for i in "${!expected[@]}"; do
    if [ "${args[$i]}" != "${expected[$i]}" ]; then
        printf 'argument %d mismatch: expected <%s>, got <%s>\n' "$i" "${expected[$i]}" "${args[$i]}" >&2
        exit 1
    fi
done

echo "Valheim argument contract test passed"
