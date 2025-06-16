#!/bin/bash

# Create PostgreSQL service
create_postgres_service() {
    local service_name="$1"
    local image="$2"
    local user="$3"
    local db_name="$4"
    local password="$5"
    local volume="$6"
    local network="$7"
    
    log_info "Creating PostgreSQL service..."
    docker service create \
        --name "${service_name}" \
        --constraint 'node.role==manager' \
        --network "${network}" \
        --env "POSTGRES_USER=${user}" \
        --env "POSTGRES_DB=${db_name}" \
        --env "POSTGRES_PASSWORD=${password}" \
        --mount "type=volume,source=${volume},target=/var/lib/postgresql/data" \
        "${image}"
    
    handle_error $? "Failed to create PostgreSQL service"
    log_success "PostgreSQL service created"
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    local service_name="$1"
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for PostgreSQL to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker service ls | grep -q "${service_name}.*1/1"; then
            log_success "PostgreSQL is ready"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "PostgreSQL failed to start within ${max_attempts} attempts"
    return 1
} 