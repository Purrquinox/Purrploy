#!/bin/bash

# Deploy Traefik
deploy_traefik() {
    log_step "Deploying Traefik..."
    
    # Create necessary directories
    mkdir -p "${TRAEFIK_DYNAMIC_PATH}"
    chmod -R 777 "${TRAEFIK_BASE_PATH}"
    
    # Create Traefik service
    create_service "${TRAEFIK_CONTAINER}" "traefik:${TRAEFIK_VERSION}" \
        --constraint 'node.role == manager' \
        --network "${NETWORK_NAME}" \
        --mount "type=bind,source=${TRAEFIK_CONFIG_PATH},target=/etc/traefik/traefik.yml" \
        --mount "type=bind,source=${TRAEFIK_DYNAMIC_PATH},target=/etc/dokploy/traefik/dynamic" \
        --mount "type=bind,source=${DOCKER_SOCK_PATH},target=/var/run/docker.sock" \
        --publish "mode=host,target=80,published=80,protocol=tcp,listen-address=${ADVERTISE_ADDR}" \
        --publish "mode=host,target=443,published=443,protocol=tcp,listen-address=${ADVERTISE_ADDR}" \
        --publish "mode=host,target=443,published=443,protocol=udp,listen-address=${ADVERTISE_ADDR}"
    
    handle_error $? "Failed to start Traefik service"
    log_success "Traefik service started successfully with IP bindings to ${ADVERTISE_ADDR} for ports 80 and 443"
}

# Stop Traefik
stop_traefik() {
    log_info "Stopping Traefik service..."
    scale_service "${TRAEFIK_CONTAINER}" 0
    log_success "Stopped ${TRAEFIK_CONTAINER}"
}

# Remove Traefik
remove_traefik() {
    log_info "Removing Traefik service..."
    remove_service "${TRAEFIK_CONTAINER}"
    log_success "Removed ${TRAEFIK_CONTAINER}"
}

# Start Traefik
start_traefik() {
    log_info "Starting Traefik service..."
    scale_service "${TRAEFIK_CONTAINER}" 1
    log_success "Started ${TRAEFIK_CONTAINER}"
} 