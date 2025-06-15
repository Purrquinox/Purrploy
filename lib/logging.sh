#!/bin/bash

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