#!/bin/bash
source $SCRIPTS/valheim_logging_functions
source $SCRIPTS/valheim_server_functions

export APP_LOGS="$LOGS/$APP_NAME"
export ARCH=$(dpkg --print-architecture)
export CONTAINER_START_TIME=$(date -u +%s)

# TODO log rotate

main() {
    tail_pids=()
    trap 'down SIGTERM' SIGTERM
    trap 'down SIGHUP' SIGHUP
    trap 'down SIGINT' SIGINT
    trap 'down EXIT' EXIT

    check_env
    cleanup
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

check_env() {

    if [[ ${#SERVER_PASS} -lt 5 ]]; then
        log "WARNING - Password: '$SERVER_PASS' too short! Password should be at least 5 characters long."
    fi

    if [[ "$SERVER_NAME" == *"$SERVER_PASS"* ]]; then
        log "WARNING - Password '$SERVER_PASS' should not be part of the server name."
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
    log "Received $signal_name. Initiating graceful shutdown..."

    # Stop tail processes immediately
    if [ ${#tail_pids[@]} -gt 0 ]; then
        log "Stopping tail processes..."
        kill -TERM "${tail_pids[@]}" 2>/dev/null
    fi

    # Stop main application process
    if [ -n "$APP_PID" ] && kill -0 "$APP_PID" 2>/dev/null; then
        log "Stopping application process (PID: $APP_PID)..."
        kill -TERM "$APP_PID" 2>/dev/null
        
        # Wait for the process to terminate, with a 9-second timeout
        # This leaves 1 second for final cleanup before Docker's 10-second limit
        local timeout=9
        for ((i=0; i<timeout; i++)); do
            if ! kill -0 "$APP_PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # If process is still running after timeout, log a warning
        # Docker will send SIGKILL after its own timeout
        if kill -0 "$APP_PID" 2>/dev/null; then
            log "WARNING: Application did not stop within the timeout period. Docker may force termination."
        fi
    fi

    # Quick final wait, but don't exceed our adjusted timeout
    wait -n 1 2>/dev/null

    log "Cleanup complete. Exiting."
    exit 0
}

cleanup() {
    log "Starting log cleanup process..."

    # Log rotation
    for logfile in "$LOGS"/*.log; do
        if [ -f "$logfile" ]; then
            base_name=$(basename "$logfile" .log)
            log "Processing log file: $base_name"
           
            # Rotate existing old logs
            for i in {7..1}; do
                j=$((i+1))
                if [ -f "${logfile}.${i}" ]; then
                    log "  Rotating ${base_name}.log.${i} to ${base_name}.log.${j}"
                    mv "${logfile}.${i}" "${logfile}.${j}"
                fi
            done
           
            # Compress logs older than 1 day
            for old_log in "${logfile}".[2-7]; do
                if [ -f "$old_log" ] && [ ! -f "${old_log}.gz" ]; then
                    log "  Compressing $old_log"
                    gzip "$old_log"
                fi
            done
           
            # Rotate current log
            if [ -s "$logfile" ]; then
                log "  Rotating current log $base_name.log to ${base_name}.log.1"
                mv "$logfile" "${logfile}.1"
                touch "$logfile"
                chown $APP_NAME:$APP_NAME "$logfile"
                chmod 644 "$logfile"
                log "  Created new empty log file: $base_name.log"
            else
                log "  Current log $base_name.log is empty, skipping rotation"
            fi
        fi
    done

    log "Cleaning up old rotated logs..."
    old_logs=$(find "$LOGS" -name "*.log.*" -mtime +7)
    if [ -n "$old_logs" ]; then
        log "  Deleting the following old logs:"
        log "$old_logs"
        find "$LOGS" -name "*.log.*" -mtime +7 -delete
    else
        log "  No old logs to delete"
    fi

    log "Log cleanup process completed"
}

main
