#!/bin/bash

# Deploy Traefik
deploy_traefik() {
    log_step "Deploying Traefik..."
    
    # Stop and remove existing Traefik container if it exists
    stop_traefik
    remove_traefik
    
    # Create Traefik configuration directory
    mkdir -p "${TRAEFIK_BASE_PATH}"
    
    # Create Traefik configuration
    cat > "${TRAEFIK_BASE_PATH}/traefik.yml" << EOF
entryPoints:
  web:
    address: "${ADVERTISE_ADDR}:${TRAEFIK_PORT}"
  websecure:
    address: "${ADVERTISE_ADDR}:${TRAEFIK_SSL_PORT}"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: "${ACME_EMAIL}"
      storage: /etc/dokploy/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: host
    watch: true

api:
  dashboard: true
  insecure: true

log:
  level: INFO
EOF
    
    # Deploy Traefik container
    docker run -d \
        --name "${CONFIG_containers_traefik}" \
        --network host \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v "${TRAEFIK_BASE_PATH}":/etc/dokploy \
        "traefik:${CONFIG_docker_traefik_version}" \
        --configFile=/etc/dokploy/traefik.yml
    
    handle_error $? "Failed to deploy Traefik"
    log_success "Traefik deployed successfully"
}

# Stop Traefik
stop_traefik() {
    log_info "Stopping Traefik container..."
    docker stop "${CONFIG_containers_traefik}" 2>/dev/null && log_success "Stopped ${CONFIG_containers_traefik}" || log_warning "${CONFIG_containers_traefik} was not running"
}

# Remove Traefik
remove_traefik() {
    log_info "Removing Traefik container..."
    docker rm "${CONFIG_containers_traefik}" 2>/dev/null && log_success "Removed ${CONFIG_containers_traefik}" || log_warning "${CONFIG_containers_traefik} container did not exist"
}

# Start Traefik
start_traefik() {
    log_info "Starting Traefik container..."
    docker start "${CONFIG_containers_traefik}" 2>/dev/null && log_success "Started ${CONFIG_containers_traefik}" || log_warning "${CONFIG_containers_traefik} container not found"
} 