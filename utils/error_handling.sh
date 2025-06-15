#!/bin/bash

# Error handling function
handle_error() {
    local exit_code="$1"
    local error_message="$2"
    if [ $exit_code -ne 0 ]; then
        log_error "$error_message"
        exit $exit_code
    fi
}

# Check if command exists
command_exists() {
    command -v "$@" > /dev/null 2>&1
}

# Validate root user
validate_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Validate Linux OS
validate_linux() {
    if [ "$(uname)" = "Darwin" ]; then
        log_error "This script must be run on Linux"
        exit 1
    fi
}

# Validate not running in container
validate_not_container() {
    if [ -f /.dockerenv ]; then
        log_error "This script must be run on a full Linux system, not inside a container"
        exit 1
    fi
}

# Check if ports are in use
check_ports() {
    local ports=("$@")
    for p in "${ports[@]}"; do
        if ss -tuln | grep -q ":$p "; then
            log_error "Port $p is already in use"
            exit 1
        fi
    done
} 