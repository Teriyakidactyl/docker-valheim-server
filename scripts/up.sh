#!/bin/bash
source $SCRIPTS/logging
source $SCRIPTS/server

export APP_LOGS="$LOGS/$APP_NAME"
export ARCH=$(dpkg --print-architecture)
export CONTAINER_START_TIME=$(date -u +%s)

# TODO move $APP_FILES and $WORLD_FILES creation to function, pull from docker.
# FIXME fix permsission in same function: Error saving world! Access to the path "/world/worlds.db.new" is denied

main() {
    tail_pids=()
    trap 'down SIGTERM' SIGTERM
    trap 'down SIGINT' SIGINT
    trap 'down EXIT' EXIT

    check_env
    server_update
    server_start
    log_tails

    # Infinite loop while APP_PID is running
    while kill -0 $APP_PID > /dev/null 2>&1; do
        current_minute=$(date '+%M' | sed 's/^0*//')
        
        if (( current_minute % 10 == 0 )); then
            log "$(uptime)"
        fi

        # TODO user count

        # TODO server update?

        # Sleep for 1 minute before checking again
        sleep 60
    done

    log "ERROR - $APP_EXE @PID $APP_PID appears to have died! $(uptime)"
    down "(main loop exit)"
}

check_mhz() {

    # Check device MHz
    local cpu_mhz=$(awk '/^cpu MHz/ {print $4; exit}' /proc/cpuinfo)

    if [[ "$cpu_mhz" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( ${cpu_mhz%.*} > 0 )); then
        log "Found CPU with $cpu_mhz MHz"
        unset CPU_MHZ
    else
        log "Unable to determine CPU Frequency - setting a default of 1.5 GHz so steamcmd won't complain"
        export CPU_MHZ="1500.000"
    fi

}

check_env() {

    if [[ ${#SERVER_PASS} -lt 5 ]]; then
        log "WARNING - Password should be at least 5 characters long."
    fi

    if [[ "$SERVER_NAME" == *"$SERVER_PASS"* ]]; then
        log "WARNING - Password should not be part of the server name."
    fi

    if [[ "$WORLD_NAME" == *".db"* || "$WORLD_NAME" == *".fwl"* ]]; then
        log "WARNING - World name should not contain extensions like .db or .fwl."
    fi
}

uptime() {

    local now=$(date -u +%s)
    
    local uptime_seconds=$(( now - CONTAINER_START_TIME ))

    local days=$(( uptime_seconds / 86400 ))
    local hours=$(( (uptime_seconds % 86400) / 3600 ))
    local minutes=$(( (uptime_seconds % 3600) / 60 ))
    
    # Print uptime in a readable format
    echo "Container Uptime: ${days}d ${hours}h ${minutes}m"

}

down() {
    local signal_name=$1
    log "Received $signal_name. Performing cleanup..."
    log "Stopping tail processes..."
    kill "${tail_pids[@]}" > /dev/null 2>&1
    wait "${tail_pids[@]}" > /dev/null 2>&1
    log "Stopping application process (PID: $APP_PID)..."
    kill $APP_PID > /dev/null 2>&1
    wait $APP_PID > /dev/null 2>&1
    exit 0
}

main
