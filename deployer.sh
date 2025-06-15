#!/bin/bash

# Source utility functions
source utils/yaml.sh
source utils/error_handling.sh

# Source library functions
source lib/logging.sh
source lib/docker.sh
source lib/network.sh
source lib/database.sh
source lib/redis.sh
source lib/traefik.sh

# Configuration file
CONFIG_FILE="config.yml"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    eval $(parse_yaml "$CONFIG_FILE")
else
    echo "Configuration file not found. Using default values."
fi

# Default values
PORT="${PORT:-3000}"
TRAEFIK_PORT="${TRAEFIK_PORT:-80}"
TRAEFIK_SSL_PORT="${TRAEFIK_SSL_PORT:-443}"
RELEASE_TAG="${RELEASE_TAG:-latest}"
DATABASE_URL="${DATABASE_URL:-}"
REDIS_HOST="${REDIS_HOST:-}"
ADVERTISE_ADDR="${ADVERTISE_ADDR:-}"

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
NC="\033[0m" # No Color

# Logging function
log() {
    local level="$1"
    local message="$2"
    echo -e "${level}${message}${NC}"
}

log_info() {
    log "${CYAN}[INFO]${NC}" "$1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC}" "$1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC}" "$1"
}

log_error() {
    log "${RED}[ERROR]${NC}" "$1"
}

log_step() {
    log "${PURPLE}[STEP]${NC}" "$1"
}

# Error handling function
handle_error() {
    local exit_code="$1"
    local error_message="$2"
    if [ $exit_code -ne 0 ]; then
        log_error "$error_message"
        exit $exit_code
    fi
}

# Cleanup function
cleanup_existing() {
    log_step "Cleaning up existing Dokploy installation..."
    
    # Stop and remove Traefik
    stop_traefik
    remove_traefik
    
    # Scale down and remove services
    scale_service "dokploy" 0
    scale_service "dokploy-postgres" 0
    scale_service "dokploy-redis" 0
    
    # Wait for replicas to stop
    log_info "Waiting for replicas to stop..."
    sleep 3
    
    # Remove services
    remove_service "dokploy"
    remove_service "dokploy-postgres"
    remove_service "dokploy-redis"
    
    # Force remove any remaining containers
    log_info "Cleaning up any remaining Dokploy containers..."
    docker ps -a --filter "label=com.docker.swarm.service.name=dokploy" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
    docker ps -a --filter "label=com.docker.swarm.service.name=dokploy-postgres" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
    docker ps -a --filter "label=com.docker.swarm.service.name=dokploy-redis" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
    
    # Remove networks
    log_info "Removing Docker networks..."
    docker network rm "${NETWORK_NAME}" 2>/dev/null && log_success "Removed ${NETWORK_NAME}" || log_warning "${NETWORK_NAME} did not exist"
    
    # Wait for cleanup to complete
    log_info "Waiting for cleanup to complete..."
    sleep 5
    
    log_success "Cleanup completed"
}

# Stop Dokploy function
stop_dokploy() {
    log_step "Stopping Dokploy services and containers..."
    
    # Stop Traefik
    stop_traefik
    
    # Stop services
    scale_service "dokploy" 0
    scale_service "dokploy-postgres" 0
    scale_service "dokploy-redis" 0
    
    log_success "All services and containers stopped"
}

# Start Dokploy function
start_dokploy() {
    log_step "Starting Dokploy services and containers..."
    
    # Start services
    scale_service "dokploy-postgres" 1
    scale_service "dokploy-redis" 1
    scale_service "dokploy" 1
    
    # Start Traefik
    start_traefik
    
    log_success "All services and containers started"
}

# Install Dokploy function
install_dokploy() {
    # Validate environment
    validate_root
    validate_linux
    validate_not_container
    
    # Check ports
    check_ports "${TRAEFIK_PORT}" "${TRAEFIK_SSL_PORT}" "${PORT}"
    
    # Install Docker
    install_docker
    
    # Leave existing swarm
    log_step "Preparing Docker Swarm..."
    docker swarm leave --force 2>/dev/null && log_warning "Left existing swarm" || log_info "No existing swarm to leave"
    
    # Clean up existing installation
    cleanup_existing
    
    # Initialize swarm
    init_swarm "${ADVERTISE_ADDR}"
    
    # Create network
    log_step "Creating Docker networks..."
    docker network create --driver overlay --attachable "${NETWORK_NAME}"
    handle_error $? "Failed to create overlay network"
    log_success "Created overlay network: ${NETWORK_NAME}"
    
    # Setup database
    if [ -z "${DATABASE_URL}" ]; then
        create_service "dokploy-postgres" "postgres:${POSTGRES_VERSION}" \
            --constraint 'node.role==manager' \
            --network "${NETWORK_NAME}" \
            --env "POSTGRES_USER=${DB_USER}" \
            --env "POSTGRES_DB=${DB_NAME}" \
            --env "POSTGRES_PASSWORD=${DB_PASSWORD}" \
            --mount "type=volume,source=${POSTGRES_VOLUME},target=/var/lib/postgresql/data"
    else
        log_info "Using external database: ${DATABASE_URL%@*}@***"
    fi
    
    # Setup Redis
    if [ -z "${REDIS_HOST}" ]; then
        create_service "dokploy-redis" "redis:${REDIS_VERSION}" \
            --constraint 'node.role==manager' \
            --network "${NETWORK_NAME}" \
            --mount "type=volume,source=${REDIS_VOLUME},target=/data"
    else
        log_info "Using external Redis: ${REDIS_HOST}"
    fi
    
    # Pull images
    pull_images
    
    # Deploy Dokploy
    create_service "dokploy" "dokploy/dokploy:${RELEASE_TAG}" \
        --network "${NETWORK_NAME}" \
        --mount "type=bind,source=${DOCKER_SOCK_PATH},target=/var/run/docker.sock" \
        --mount "type=bind,source=${TRAEFIK_BASE_PATH},target=/etc/dokploy" \
        --mount "type=volume,source=${DOCKER_CONFIG_VOLUME},target=/root/.docker" \
        --constraint 'node.role == manager' \
        $([ -n "${DATABASE_URL}" ] && echo "--env DATABASE_URL=${DATABASE_URL}") \
        $([ -n "${REDIS_HOST}" ] && echo "--env REDIS_HOST=${REDIS_HOST}") \
        --env "ADVERTISE_ADDR=${ADVERTISE_ADDR}"
    
    # Wait for service to be ready
    log_step "Waiting for Dokploy service to start..."
    sleep 15
    
    # Deploy Traefik
    deploy_traefik
    
    # Display completion message
    echo ""
    log_step "UFW Configuration for external database access:"
    printf "${WHITE}To allow Tailscale access to services:${NC}\n"
    printf "${CYAN}  - sudo ufw allow in on tailscale0 to any port 80${NC}\n"
    printf "${CYAN}  - sudo ufw allow in on tailscale0 to any port 443${NC}\n"
    echo ""
    
    format_ip_for_url() {
        local ip="$1"
        if echo "$ip" | grep -q ':'; then
            echo "[${ip}]"
        else
            echo "${ip}"
        fi
    }
    
    formatted_addr=$(format_ip_for_url "${ADVERTISE_ADDR}")
    echo ""
    printf "${GREEN}🎉 Congratulations, Dokploy is installed! 🎉${NC}\n"
    printf "${BLUE}⏰ Wait 15 seconds for the server to start${NC}\n"
    printf "${YELLOW}🌐 Please go to http://${formatted_addr}:${PORT}${NC}\n\n"
}

# Update Dokploy function
update_dokploy() {
    log_step "Updating Dokploy..."
    
    # Pull the latest image
    docker pull "dokploy/dokploy:${RELEASE_TAG}"
    
    # Update the service
    update_service "dokploy" "dokploy/dokploy:${RELEASE_TAG}"
    
    # Wait for update
    log_info "Waiting for service update..."
    sleep 10
    
    log_success "Dokploy has been updated to version ${RELEASE_TAG}"
}

# Main
case "$1" in
    "update")
        update_dokploy
        ;;
    "cleanup")
        cleanup_existing
        ;;
    "stop")
        stop_dokploy
        ;;
    "start")
        start_dokploy
        ;;
    "restart")
        stop_dokploy
        sleep 3
        start_dokploy
        ;;
    "reinstall")
        cleanup_existing
        install_dokploy
        ;;
    *)
        install_dokploy
        ;;
esac