#!/bin/bash

set -Eeuo pipefail

HOOK_NAME="30_valheim.sh"

fail() {
    log "ERROR: $*" "$HOOK_NAME"
    return 1
}

warn() {
    log "WARNING: $*" "$HOOK_NAME"
}

validate_integer_range() {
    local name="$1"
    local value="$2"
    local min="$3"
    local max="$4"

    if [[ ! "$value" =~ ^[0-9]+$ ]] || (( value < min || value > max )); then
        fail "$name must be an integer from $min through $max; got '$value'"
        return 1
    fi
}

validate_choice() {
    local name="$1"
    local value="$2"
    shift 2
    local candidate

    for candidate in "$@"; do
        if [ "$value" = "$candidate" ]; then
            return 0
        fi
    done

    fail "$name must be one of: $*; got '$value'"
    return 1
}

validate_single_line() {
    local name="$1"
    local value="$2"

    if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
        fail "$name may not contain newlines"
        return 1
    fi
}

allow_list_path() {
    if [ -n "${STEAM_ID_ALLOW_LIST_PATH:-}" ]; then
        printf '%s\n' "$STEAM_ID_ALLOW_LIST_PATH"
    elif [ -n "${STEAM_ALLOW_LIST_PATH:-}" ]; then
        # Compatibility with the historical Valheim-specific variable.
        printf '%s\n' "$STEAM_ALLOW_LIST_PATH"
    else
        printf '%s/permittedlist.txt\n' "$WORLD_FILES"
    fi
}

reconcile_allow_list() {
    local requested_allow_list="${STEAM_ID_ALLOW_LIST:-${SERVER_ALLOW_LIST:-}}"
    local target_path state_dir state_file previous_target tmp

    target_path="$(allow_list_path)"
    case "$target_path" in
        /*) ;;
        *)
            fail "permitted-list path must be absolute; got '$target_path'"
            return 1
            ;;
    esac

    state_dir="$WORLD_FILES/.docker-valheim-server"
    state_file="$state_dir/permittedlist.path"
    previous_target=""
    if [ -f "$state_file" ]; then
        IFS= read -r previous_target < "$state_file" || true
    fi

    # If a container-managed path changes, remove only the path recorded as
    # container-owned. An untracked operator-created file is never removed.
    if [ -n "$previous_target" ] && [ "$previous_target" != "$target_path" ]; then
        if [ -e "$previous_target" ] || [ -L "$previous_target" ]; then
            if [ -d "$previous_target" ] && [ ! -L "$previous_target" ]; then
                fail "$previous_target is a directory; refusing to remove managed permitted-list state"
                return 1
            fi
            rm -f "$previous_target"
        fi
        previous_target=""
        rm -f "$state_file"
        log "Removed obsolete container-managed Valheim permitted list" "$HOOK_NAME"
    fi

    mkdir -p "$(dirname "$target_path")"
    tmp="$(mktemp "${target_path}.candidate.XXXXXX")"

    if [ -n "$requested_allow_list" ]; then
        printf '%s\n' "$requested_allow_list" \
            | tr ',' '\n' \
            | sed 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
            | awk 'NF' \
            > "$tmp"
    fi

    if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        if [ -n "$previous_target" ]; then
            if [ -e "$previous_target" ] || [ -L "$previous_target" ]; then
                if [ -d "$previous_target" ] && [ ! -L "$previous_target" ]; then
                    fail "$previous_target is a directory; refusing to remove managed permitted-list state"
                    return 1
                fi
                rm -f "$previous_target"
            fi
            rm -f "$state_file"
            log "Removed container-managed Valheim permitted list" "$HOOK_NAME"
        fi
        return 0
    fi

    if [ -e "$target_path" ] && [ ! -f "$target_path" ] && [ ! -L "$target_path" ]; then
        rm -f "$tmp"
        fail "$target_path exists but is not a regular file or symlink"
        return 1
    fi

    if [ ! -f "$target_path" ] || ! cmp -s "$tmp" "$target_path"; then
        cat "$tmp" > "$target_path"
        log "Updated Valheim permitted list at $target_path" "$HOOK_NAME"
    fi

    mkdir -p "$state_dir"
    printf '%s\n' "$target_path" > "$state_file"
    rm -f "$tmp"
}

server_name="${SERVER_NAME:-MyValheimServer}"
server_pass="${SERVER_PASS:-MySecretPassword}"
server_public="${SERVER_PUBLIC:-0}"
world_name="${WORLD_NAME:-Teriyakolypse}"
server_port="${SERVER_PORT:-2456}"

# SERVER_PORT+1 is also consumed by Valheim, so 65535 is not a valid base port.
validate_integer_range SERVER_PORT "$server_port" 1 65534
validate_choice SERVER_PUBLIC "$server_public" 0 1
validate_single_line SERVER_NAME "$server_name"
validate_single_line SERVER_PASS "$server_pass"
validate_single_line WORLD_NAME "$world_name"

if (( ${#server_pass} < 5 )); then
    warn "SERVER_PASS is shorter than five characters"
fi

if [ -n "$server_pass" ] && [[ "$server_name" == *"$server_pass"* ]]; then
    warn "SERVER_NAME contains the configured password"
fi

if [[ "$world_name" == *.db || "$world_name" == *.fwl ]]; then
    warn "WORLD_NAME should not include a .db or .fwl extension"
fi

reconcile_allow_list

log "Valheim configuration is ready" "$HOOK_NAME"
