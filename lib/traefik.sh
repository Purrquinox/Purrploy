#!/bin/bash

# Deploy Traefik
deploy_traefik() {
    log_step "Deploying Traefik..."
    
    # Create necessary directories
    mkdir -p "${TRAEFIK_DYNAMIC_PATH}"
    chmod -R 777 "${TRAEFIK_BASE_PATH}"
    
    # Determine network mode based on advertise_addr
    local network_mode=""
    local network_args=()
    
    if [ -z "${ADVERTISE_ADDR}" ] || [ "${ADVERTISE_ADDR}" = "0.0.0.0" ]; then
        log_info "Using overlay network for Traefik (all interfaces)"
        network_args=("--network" "${NETWORK_NAME}")
    else
        log_info "Using host networking for Traefik (specific IP: ${ADVERTISE_ADDR})"
        network_args=("--network" "host")
    fi
    
    # Run Traefik container
    docker run -d \
        --name "${TRAEFIK_CONTAINER}" \
        "${network_args[@]}" \
        --restart unless-stopped \
        -v "${TRAEFIK_CONFIG_PATH}:/etc/traefik/traefik.yml" \
        -v "${TRAEFIK_DYNAMIC_PATH}:/etc/dokploy/traefik/dynamic" \
        -v "${DOCKER_SOCK_PATH}:/var/run/docker.sock" \
        -p "${ADVERTISE_ADDR}:${TRAEFIK_PORT}:80" \
        -p "${ADVERTISE_ADDR}:${TRAEFIK_SSL_PORT}:443" \
        -p "${ADVERTISE_ADDR}:${TRAEFIK_SSL_PORT}:443/udp" \
        "traefik:${TRAEFIK_VERSION}"
    
    handle_error $? "Failed to start Traefik container"
    log_success "Traefik container started successfully with IP bindings to ${ADVERTISE_ADDR} for ports 80 and 443"
}

# Stop Traefik
stop_traefik() {
    log_info "Stopping Traefik container..."
    docker stop "${TRAEFIK_CONTAINER}" 2>/dev/null && log_success "Stopped ${TRAEFIK_CONTAINER}" || log_warning "${TRAEFIK_CONTAINER} was not running"
}

# Remove Traefik
remove_traefik() {
    log_info "Removing Traefik container..."
    docker rm "${TRAEFIK_CONTAINER}" 2>/dev/null && log_success "Removed ${TRAEFIK_CONTAINER}" || log_warning "${TRAEFIK_CONTAINER} container did not exist"
}

# Start Traefik
start_traefik() {
    log_info "Starting Traefik container..."
    docker start "${TRAEFIK_CONTAINER}" 2>/dev/null && log_success "Started ${TRAEFIK_CONTAINER}" || log_warning "${TRAEFIK_CONTAINER} container not found"
} 