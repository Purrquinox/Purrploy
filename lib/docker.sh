#!/bin/bash

# Install Docker if not present
install_docker() {
    if command_exists docker; then
        log_success "Docker is already installed"
    else
        log_step "Installing Docker..."
        curl -sSL https://get.docker.com | sh
        handle_error $? "Failed to install Docker"
        log_success "Docker installed"
    fi
}

# Initialize Docker Swarm
init_swarm() {
    local advertise_addr="$1"
    log_step "Initializing Docker Swarm..."
    
    if [ -n "$advertise_addr" ]; then
        docker swarm init --advertise-addr "$advertise_addr"
    else
        docker swarm init
    fi
    handle_error $? "Failed to initialize Docker Swarm"
    log_success "Swarm initialized"
}

# Pull Docker images
pull_images() {
    log_step "Pulling Docker images..."
    docker pull traefik:${TRAEFIK_VERSION} && log_success "Pulled traefik:${TRAEFIK_VERSION}"
    docker pull dokploy/dokploy:${RELEASE_TAG} && log_success "Pulled dokploy/dokploy:${RELEASE_TAG}"
}

# Create Docker service
create_service() {
    local name="$1"
    local image="$2"
    shift 2
    local args=("$@")
    
    docker service create \
        --name "$name" \
        "${args[@]}" \
        "$image"
    handle_error $? "Failed to create $name service"
    log_success "$name service created successfully"
}

# Update Docker service
update_service() {
    local name="$1"
    local image="$2"
    
    docker service update --image "$image" "$name"
    handle_error $? "Failed to update $name service"
    log_success "$name service updated successfully"
}

# Scale Docker service
scale_service() {
    local name="$1"
    local replicas="$2"
    
    docker service scale "$name=$replicas"
    handle_error $? "Failed to scale $name service"
    log_success "Scaled $name service to $replicas replicas"
}

# Remove Docker service
remove_service() {
    local name="$1"
    
    docker service rm "$name" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "Removed $name service"
    else
        log_warning "$name service did not exist"
    fi
} 