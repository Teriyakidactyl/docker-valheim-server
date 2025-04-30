#!/bin/bash

check_whitelist() {
    if [ -n "$STEAM_ID_ALLOW_LIST" ]; then
        # TODO update_config_element "EnableWhitelist" "True"
        
        # Remove existing whitelist file if it exists
        if [ -f "$STEAM_ID_ALLOW_LIST_PATH" ]; then
            rm "$STEAM_ID_ALLOW_LIST_PATH" || { log "Failed to remove existing whitelist file: $STEAM_ID_ALLOW_LIST_PATH"; return 1; }
        fi
        
        # Create an empty whitelist file
        touch "$STEAM_ID_ALLOW_LIST_PATH" || { log "Failed to create whitelist file: $STEAM_ID_ALLOW_LIST_PATH"; return 1; }
        
        # Populate whitelist file with STEAM_IDs
        # Split STEAM_ID_ALLOW_LIST on commas and iterate over each part
        IFS=", " read -r -a STEAM_IDS <<< "$STEAM_ID_ALLOW_LIST"
        for STEAM_ID in "${STEAM_IDS[@]}"; do
            echo "$STEAM_ID" >> "$STEAM_ID_ALLOW_LIST_PATH" || { log "Failed to write to whitelist file: $STEAM_ID_ALLOW_LIST_PATH"; return 1; }
        done
        
        log "Allow list created:"
        cat "$STEAM_ID_ALLOW_LIST_PATH" | log_stdout
    fi
}