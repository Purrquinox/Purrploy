#!/bin/bash

# Initialize Docker Swarm
init_swarm() {
    local advertise_addr="$1"
    log_step "Initializing Docker Swarm..."
    docker swarm init --advertise-addr "${advertise_addr}"
    handle_error $? "Failed to initialize Docker Swarm"
    log_success "Docker Swarm initialized"
}

# Create Docker service
create_service() {
    local service_name="$1"
    local image="$2"
    shift 2
    local args=("$@")
    
    log_info "Creating service: ${service_name}"
    docker service create --name "${service_name}" "${args[@]}" "${image}"
    handle_error $? "Failed to create service ${service_name}"
    log_success "Created service: ${service_name}"
}

# Update Docker service
update_service() {
    local service_name="$1"
    local image="$2"
    
    log_info "Updating service: ${service_name}"
    docker service update --image "${image}" "${service_name}"
    handle_error $? "Failed to update service ${service_name}"
    log_success "Updated service: ${service_name}"
} 