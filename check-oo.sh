#!/bin/bash
# Importa as configurações do onlyoffice que estão no arquivo out-oo.txt para o container em CONTAINER_NAME
# E envia um curl para a URL definida em HEALTH_CHECK_URL

# Log file location
LOG_FILE="/var/log/nextcloud-oo-monitor.log"

# Health check URL
HEALTH_CHECK_URL=""

# Container name
CONTAINER_NAME="nextcloud-docker-app-1"

# OnlyOffice configuration array
configs=(
    "demo"
    "DocumentServerUrl"
    "documentserverInternal"
    "StorageUrl"
    "secret"
    "defFormats"
    "editFormats"
    "sameTab"
    "preview"
    "advanced"
    "cronChecker"
    "versionHistory"
    "protection"
    "customizationChat"
    "customizationCompactHeader"
    "customizationFeedback"
    "customizationForcesave"
    "customizationHelp"
    "customizationToolbarNoTabs"
    "customizationReviewDisplay"
    "customizationTheme"
    "groups"
    "verify_peer_off"
    "jwt_secret"
    "jwt_header"
    "jwt_leeway"
    "settings_error"
    "limit_thumb_size"
    "permissions_modifyFilter"
    "customization_customer"
    "customization_loaderLogo"
    "customization_loaderName"
    "customization_logo"
    "customization_zoom"
    "customization_autosave"
    "customization_goback"
    "customization_macros"
    "customization_plugins"
    "editors_check_interval"
)

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to backup current configuration
backup_config() {
    log_message "Backing up current OnlyOffice configuration..."
    > ./out-oo.txt
    for config in "${configs[@]}"; do
        log_message "Backing up $config..."
        echo "$config=`docker exec -u www-data "$CONTAINER_NAME" php occ config:app:get onlyoffice "$config"`" >> ./out-oo.txt
    done
    log_message "Configuration backup completed"
}

# Function to check if server is available
check_server_available() {
    OUTPUT=$(docker exec -u www-data "$CONTAINER_NAME" php occ onlyoffice:documentserver --check)
    if echo "$OUTPUT" | grep -q "successfully"; then
        return 0
    else
        return 1
    fi
}

# Function to connect OnlyOffice
connect_oo() {
    log_message "Starting OnlyOffice reconnection process..."
    
    # Check if out-oo.txt exists
    if [ ! -f ./out-oo.txt ]; then
        log_message "Configuration file out-oo.txt not found"
        # Check if server is available to backup config
        if check_server_available; then
            log_message "Server is available, backing up current configuration..."
            backup_config
        else
            log_message "Server is not available and no configuration backup exists"
            return 1
        fi
    fi
    
    log_message "Importing configuration from out-oo.txt..."
    while IFS='=' read -r config value; do
        log_message "Setting $config to $value..."
        docker exec -u www-data "$CONTAINER_NAME" php occ config:app:set "onlyoffice" "$config" --value "$value"
    done < ./out-oo.txt
    
    log_message "Configuration import complete. Attempting to reconnect..."
    RECONNECT_OUTPUT=$(docker exec -u www-data "$CONTAINER_NAME" php occ onlyoffice:documentserver --check)
    
    if echo "$RECONNECT_OUTPUT" | grep -q "successfully"; then
        log_message "OnlyOffice reconnection successful"
        return 0
    else
        log_message "OnlyOffice reconnection failed: $RECONNECT_OUTPUT"
        return 1
    fi
}

# Main function to check server status
check_server_status() {
    log_message "Checking OnlyOffice server status..."
    
    # Check server status
    OUTPUT=$(docker exec -u www-data "$CONTAINER_NAME" php occ onlyoffice:documentserver --check)
    
    if echo "$OUTPUT" | grep -q "successfully"; then
        log_message "OnlyOffice server is working properly"
        # Send success ping to health check
        curl -s "$HEALTH_CHECK_URL" > /dev/null
        return 0
    else
        log_message "OnlyOffice server check failed: $OUTPUT"
        
        # Attempt to reconnect
        log_message "Initiating reconnection procedure..."
        if connect_oo; then
            # Verify if reconnection fixed the issue
            VERIFY_OUTPUT=$(docker exec -u www-data "$CONTAINER_NAME" php occ onlyoffice:documentserver --check)
            if echo "$VERIFY_OUTPUT" | grep -q "successfully"; then
                log_message "Server is now working after reconnection"
                curl -s "$HEALTH_CHECK_URL" > /dev/null
                return 0
            fi
        fi
        
        log_message "Server is still not working after reconnection attempt"
        return 1
    fi
}

# Execute the main function
check_server_status

# Exit with appropriate status code
exit $?
