#!/bin/bash

# Create Redis service
create_redis_service() {
    local service_name="$1"
    local image="$2"
    local volume="$3"
    local network="$4"
    
    log_info "Creating Redis service..."
    docker service create \
        --name "${service_name}" \
        --constraint 'node.role==manager' \
        --network "${network}" \
        --mount "type=volume,source=${volume},target=/data" \
        "${image}"
    
    handle_error $? "Failed to create Redis service"
    log_success "Redis service created"
}

# Wait for Redis to be ready
wait_for_redis() {
    local service_name="$1"
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for Redis to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker service ls | grep -q "${service_name}.*1/1"; then
            log_success "Redis is ready"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "Redis failed to start within ${max_attempts} attempts"
    return 1
} 